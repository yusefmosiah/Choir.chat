import SwiftUI

@MainActor
class PostchainViewModel: ObservableObject {
    @Published private(set) var currentPhase: Phase
    @Published private(set) var responses: [Phase: String]
    @Published private(set) var isProcessing: Bool
    @Published private(set) var error: Error?

    // Track current active message ID
    @Published private(set) var activeMessageId: String = UUID().uuidString

    // Store structured search results per message
    @Published private(set) var vectorResultsByMessage: [String: [VectorSearchResult]] = [:]
    @Published private(set) var webResultsByMessage: [String: [SearchResult]] = [:]

    // Keep string arrays for compatibility, but also per message
    @Published private(set) var vectorSourcesByMessage: [String: [String]] = [:]
    @Published private(set) var webSearchSourcesByMessage: [String: [String]] = [:]

    // Computed properties for the current message's sources (for backwards compatibility)
    var vectorResults: [VectorSearchResult] {
        return vectorResultsByMessage[activeMessageId] ?? []
    }

    var webResults: [SearchResult] {
        return webResultsByMessage[activeMessageId] ?? []
    }

    var vectorSources: [String] {
        return vectorSourcesByMessage[activeMessageId] ?? []
    }

    var webSearchSources: [String] {
        return webSearchSourcesByMessage[activeMessageId] ?? []
    }

    let coordinator: any PostchainCoordinator

    // Method to update the view model's state based on the coordinator's state
    func updateState() {
        // Update core state properties
        self.currentPhase = coordinator.currentPhase
        self.responses = coordinator.responses
        self.isProcessing = coordinator.isProcessing

        // Update active message ID if changed in coordinator
        if let restCoordinator = coordinator as? RESTPostchainCoordinator,
           let activeId = restCoordinator.activeMessageId?.uuidString {
            self.activeMessageId = activeId

            // Update structured results for this message if they exist in coordinator
            if !restCoordinator.vectorResults.isEmpty {
                self.vectorResultsByMessage[activeId] = restCoordinator.vectorResults
            }

            if !restCoordinator.webResults.isEmpty {
                self.webResultsByMessage[activeId] = restCoordinator.webResults
            }

            // Update string arrays as well
            updateSourceStrings()
        }

        // Manually trigger objectWillChange to ensure SwiftUI views update
        self.objectWillChange.send()
    }

    init(coordinator: any PostchainCoordinator) {
        self.coordinator = coordinator
        self.currentPhase = coordinator.currentPhase
        self.responses = coordinator.responses
        self.isProcessing = coordinator.isProcessing

        // Initialize sources from coordinator if needed
        if let restCoordinator = coordinator as? RESTPostchainCoordinator {
            // Store initial results in the dictionary for the current message
            self.vectorResultsByMessage[activeMessageId] = restCoordinator.vectorResults
            self.webResultsByMessage[activeMessageId] = restCoordinator.webResults
            updateSourceStrings() // Update string arrays for the current message
            restCoordinator.viewModel = self
        } else {
             updateSourcesFromExperienceContent() // Fallback for non-REST coordinators
        }
    }

    func process(_ input: String) async throws {
        error = nil

        // Set a new active message ID for this process
        activeMessageId = UUID().uuidString

        // Clear state before starting new process
        currentPhase = .action
        responses = [:]

        // Clear sources only for the new message
        vectorResultsByMessage[activeMessageId] = []
        webResultsByMessage[activeMessageId] = []
        vectorSourcesByMessage[activeMessageId] = []
        webSearchSourcesByMessage[activeMessageId] = []

        isProcessing = true

        do {
            try await coordinator.process(input)
        } catch {
            self.error = error
            isProcessing = false
        }
    }

    func cancel() {
        coordinator.cancel()
        isProcessing = false

        // Optionally clear responses/sources for the current message
        // responses = [:]
        // vectorResultsByMessage[activeMessageId] = []
        // webResultsByMessage[activeMessageId] = []
        // vectorSourcesByMessage[activeMessageId] = []
        // webSearchSourcesByMessage[activeMessageId] = []
    }

    // Called by the coordinator to update the view model with new phase content AND results
    func updatePhaseData(phase: Phase, status: String, content: String, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil, messageId: String? = nil) {
        DispatchQueue.main.async { [weak self] in
             guard let self else { return }

             // Use provided messageId or fall back to activeMessageId
             let targetMessageId = messageId ?? self.activeMessageId

             print("📊 Updating phase data for message: \(targetMessageId), phase: \(phase)")

             // Update text content
             if self.responses[phase] != content {
                 self.responses[phase] = content
             }

             // Update structured results specifically for experience phase
             if phase == .experience {
                 var sourcesUpdated = false

                 if let newWebResults = webResults {
                     let currentResults = self.webResultsByMessage[targetMessageId] ?? []
                     if currentResults != newWebResults {
                         self.webResultsByMessage[targetMessageId] = newWebResults
                         sourcesUpdated = true
                         print("📊 Updated web results for message \(targetMessageId): \(newWebResults.count) items")
                     }
                 }

                 if let newVectorResults = vectorResults {
                     let currentResults = self.vectorResultsByMessage[targetMessageId] ?? []
                     if currentResults != newVectorResults {
                         self.vectorResultsByMessage[targetMessageId] = newVectorResults
                         sourcesUpdated = true
                         print("📊 Updated vector results for message \(targetMessageId): \(newVectorResults.count) items")
                     }
                 }

                 // If structured sources were updated, also update the string versions
                 if sourcesUpdated {
                     self.updateSourceStrings(for: targetMessageId)
                 }
             }

             // Explicitly notify observers if needed, though @Published should handle it
             self.objectWillChange.send()
        }
    }

    // Helper to update the string-based source arrays (for compatibility)
    private func updateSourceStrings(for messageId: String? = nil) {
        let targetMessageId = messageId ?? self.activeMessageId

        let vectorResultsForMessage = vectorResultsByMessage[targetMessageId] ?? []
        let webResultsForMessage = webResultsByMessage[targetMessageId] ?? []

        let newVectorStrings = vectorResultsForMessage.map { $0.content } // Or format as needed
        let newWebStrings = webResultsForMessage.map { $0.url } // Or format as needed

        if vectorSourcesByMessage[targetMessageId] != newVectorStrings {
            vectorSourcesByMessage[targetMessageId] = newVectorStrings
        }
        if webSearchSourcesByMessage[targetMessageId] != newWebStrings {
            webSearchSourcesByMessage[targetMessageId] = newWebStrings
        }
    }

    // Fallback: Placeholder function to parse sources from experience content string
    // This should ideally be replaced by using structured data
    private func updateSourcesFromExperienceContent(for messageId: String? = nil) {
        let targetMessageId = messageId ?? self.activeMessageId

        guard let experienceContent = responses[.experience], !experienceContent.isEmpty else {
            if !(vectorSourcesByMessage[targetMessageId]?.isEmpty ?? true) {
                vectorSourcesByMessage[targetMessageId] = []
            }
            if !(webSearchSourcesByMessage[targetMessageId]?.isEmpty ?? true) {
                webSearchSourcesByMessage[targetMessageId] = []
            }
            return
        }

        // Example extraction logic (would need to be customized based on content format)
        let lines = experienceContent.split(separator: "\n")
        var webSources: [String] = []
        var vectorSources: [String] = []

        var inWebSourcesSection = false
        var inVectorSourcesSection = false

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespacesAndNewlines)

            if lineStr.contains("Web Search Results:") {
                inWebSourcesSection = true
                inVectorSourcesSection = false
                continue
            } else if lineStr.contains("Vector Database Sources:") {
                inVectorSourcesSection = true
                inWebSourcesSection = false
                continue
            } else if lineStr.isEmpty {
                inWebSourcesSection = false
                inVectorSourcesSection = false
                continue
            }

            if inWebSourcesSection, lineStr.starts(with: "http") {
                webSources.append(lineStr)
            } else if inVectorSourcesSection, !lineStr.isEmpty {
                vectorSources.append(lineStr)
            }
        }

        if !webSources.isEmpty {
            webSearchSourcesByMessage[targetMessageId] = webSources
        }

        if !vectorSources.isEmpty {
            vectorSourcesByMessage[targetMessageId] = vectorSources
        }
    }

    func setCurrentPhase(_ phase: Phase) {
        currentPhase = phase
    }

    // Helper to get sources for a specific message
    func getSourcesForMessage(messageId: String) -> (vectorSources: [String], webSources: [String], vectorResults: [VectorSearchResult], webResults: [SearchResult]) {
        return (
            vectorSourcesByMessage[messageId] ?? [],
            webSearchSourcesByMessage[messageId] ?? [],
            vectorResultsByMessage[messageId] ?? [],
            webResultsByMessage[messageId] ?? []
        )
    }
}
