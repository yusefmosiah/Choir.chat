import SwiftUI

@MainActor
class PostchainViewModel: ObservableObject {
    func findMessage(by uuidString: String) -> Message? {
        guard let coordinator = coordinator as? RESTPostchainCoordinator,
              let thread = coordinator.currentChoirThread else { return nil }
        return thread.messages.first(where: { $0.id.uuidString == uuidString })
    }
    @Published private(set) var currentPhase: Phase
    @Published private(set) var responses: [Phase: String]
    @Published private(set) var isProcessing: Bool
    @Published private(set) var error: Error?
    private var updateWorkItem: DispatchWorkItem?

    // Track current active message ID
    @Published private(set) var activeMessageId: String = UUID().uuidString

    // Store structured search results per message
    @Published private(set) var vectorResultsByMessage: [String: [VectorSearchResult]] = [:]
    @Published private(set) var webResultsByMessage: [String: [SearchResult]] = [:]

    // Computed properties for the current message's sources (for backwards compatibility or specific views)
    var vectorResults: [VectorSearchResult] {
        return vectorResultsByMessage[activeMessageId] ?? []
    }

    var webResults: [SearchResult] {
        return webResultsByMessage[activeMessageId] ?? []
    }

    var vectorSources: [String] {
        return vectorResultsByMessage[activeMessageId]?.map { $0.content } ?? []
    }

    var webSearchSources: [String] {
        return webResultsByMessage[activeMessageId]?.map { $0.content } ?? []
    }

    let coordinator: any PostchainCoordinator

    // Method to update a message's selected phase
    func updateSelectedPhase(for message: Message, phase: Phase) {
        // Only proceed if the phase is different from the current one
        if message.selectedPhase != phase {
            // Trigger ObjectWillChange notification
            objectWillChange.send()

            // Directly update the message's property
            message.objectWillChange.send()
            message.selectedPhase = phase
        }
    }

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
            // updateSourceStrings() // REMOVE: No longer using string arrays
            restCoordinator.viewModel = self
        } else {
             // updateSourcesFromExperienceContent() // REMOVE: Parsing from string is obsolete
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

        isProcessing = true

        // Inject global saved model configs before starting
        let savedConfigs = ModelConfigManager.shared.loadModelConfigs()

        do {
            try await coordinator.process(input, modelConfigs: savedConfigs)
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
    // Updated signature to include provider and modelName
    func updatePhaseData(phase: Phase, status: String, content: String?, provider: String?, modelName: String?, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil, messageId: String? = nil, finalContent: String? = nil) {
        // Cancel any pending update
        updateWorkItem?.cancel()

        // Create a new work item
        let workItem = DispatchWorkItem { [weak self] in
             guard let self else { return }

             // Use provided messageId or fall back to activeMessageId
             let targetMessageId = messageId ?? self.activeMessageId

            if let msg = self.findMessage(by: targetMessageId) {
                if let newVectorResults = vectorResults {
                    msg.vectorSearchResults = newVectorResults
                }
                if let newWebResults = webResults {
                    msg.webSearchResults = newWebResults
                }
            }

             print("📊 Updating phase data for message: \(targetMessageId), phase: \(phase.rawValue), status: \(status)")

             // Update text content (use finalContent if available, otherwise regular content)
             let contentToUpdate = finalContent ?? content ?? ""
             if self.responses[phase] != contentToUpdate {
                 self.responses[phase] = contentToUpdate
             }

             // Update structured results based on phase
             if phase == .experienceVectors {
                 if let newVectorResults = vectorResults {
                     let currentResults = self.vectorResultsByMessage[targetMessageId] ?? []
                     // Only update if results actually changed
                     if currentResults != newVectorResults {
                         self.vectorResultsByMessage[targetMessageId] = newVectorResults
                         print("📊 Updated vector results for message \(targetMessageId): \(newVectorResults.count) items")
                     }
                 }
             } else if phase == .experienceWeb {
                 if let newWebResults = webResults {
                     let currentResults = self.webResultsByMessage[targetMessageId] ?? []
                     // Only update if results actually changed
                     if currentResults != newWebResults {
                         self.webResultsByMessage[targetMessageId] = newWebResults
                         print("📊 Updated web results for message \(targetMessageId): \(newWebResults.count) items")
                     }
                 }
             }

            // Update the overall current phase being processed
            if self.currentPhase != phase && status == "running" { // Update only when a new phase starts
                self.currentPhase = phase
            }

            // Update processing state
            // Consider processing finished only when the final yield phase is complete
            let isLastPhaseComplete = (phase == Phase.allCases.last && status == "complete")
            if isLastPhaseComplete {
                self.isProcessing = false
                print("🏁 Processing finished.")

                // Close the loop: auto-select yield if user is on action phase
                if let message = self.findMessage(by: targetMessageId), message.selectedPhase == .action {
                    DispatchQueue.main.async {
                        withAnimation(.spring()) {
                            self.updateSelectedPhase(for: message, phase: .yield)
                        }
                    }
                }
            } else if status == "error" {
                 self.isProcessing = false // Also stop on error
                 print("🛑 Processing stopped due to error in phase \(phase.rawValue).")
             }
             // Otherwise, isProcessing remains true while phases are running or completing before yield

             // Explicitly notify observers if needed, though @Published should handle it
             self.objectWillChange.send()
        }

        // Store the work item
        updateWorkItem = workItem

        // Execute the work item on the main queue
        DispatchQueue.main.async(execute: workItem)
    }

    func setCurrentPhase(_ phase: Phase) {
        currentPhase = phase
    }

    // REMOVE: Helper to get sources for a specific message - Views should access computed properties
//    func getSourcesForMessage(messageId: String) -> (vectorSources: [String], webSources: [String], vectorResults: [VectorSearchResult], webResults: [SearchResult]) {
//        return (
//            vectorSourcesByMessage[messageId] ?? [],
//            webSearchSourcesByMessage[messageId] ?? [],
//            vectorResultsByMessage[messageId] ?? [],
//            webResultsByMessage[messageId] ?? []
//        )
//    }
}
