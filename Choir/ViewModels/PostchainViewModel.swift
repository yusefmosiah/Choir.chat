import SwiftUI
import UIKit

@MainActor
class PostchainViewModel: ObservableObject {
    func findMessage(by uuidString: String) -> Message? {
        guard let coordinator = coordinator as? PostchainCoordinatorImpl,
              let thread = coordinator.currentChoirThread else { return nil }
        return thread.messages.first(where: { $0.id.uuidString == uuidString })
    }
    @Published private(set) var currentPhase: Phase
    @Published private(set) var responses: [Phase: String]
    @Published private(set) var isProcessing: Bool
    @Published private(set) var error: Error?
    private var updateWorkItem: DispatchWorkItem?

    // Progress tracking for large inputs
    @Published var processingStatus: String = ""
    @Published var isProcessingLargeInput: Bool = false

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
        if let coordinator = coordinator as? PostchainCoordinatorImpl,
           let activeId = coordinator.activeMessageId?.uuidString {
            self.activeMessageId = activeId

            // Update structured results for this message if they exist in coordinator
            if !coordinator.vectorResults.isEmpty {
                self.vectorResultsByMessage[activeId] = coordinator.vectorResults
            }

            if !coordinator.webResults.isEmpty {
                self.webResultsByMessage[activeId] = coordinator.webResults
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
        if let coordinator = coordinator as? PostchainCoordinatorImpl {
            // Store initial results in the dictionary for the current message
            self.vectorResultsByMessage[activeMessageId] = coordinator.vectorResults
            self.webResultsByMessage[activeMessageId] = coordinator.webResults
            // Set viewModel reference for callbacks
            coordinator.viewModel = self
        } else {
             // Legacy coordinator handling is removed
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

        // Reset progress state
        processingStatus = ""
        isProcessingLargeInput = input.count > 10000

        isProcessing = true

        // Inject global saved model configs before starting
        let savedConfigs = ModelConfigManager.shared.loadModelConfigs()
        for (phase, config) in savedConfigs {
        }

        do {
            if let coordinator = coordinator as? PostchainCoordinatorImpl {
                // Pass progress callback for large inputs
                try await coordinator.processWithProgress(
                    input,
                    modelConfigs: savedConfigs,
                    onProgress: { [weak self] (status: String) in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.processingStatus = status
                        }
                    }
                )
            } else {
                // Fallback to standard processing
                try await coordinator.process(input, modelConfigs: savedConfigs)
            }
        } catch {
            self.error = error
            isProcessing = false
            isProcessingLargeInput = false
            processingStatus = ""
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
    // Updated signature to include provider and modelName - removed finalContent parameter
    func updatePhaseData(phase: Phase, status: String, content: String?, provider: String?, modelName: String?, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil, messageId: String? = nil) {
        // Cancel any pending update
        updateWorkItem?.cancel()

        // Use provided messageId or fall back to activeMessageId
        let targetMessageId = messageId ?? self.activeMessageId


        // Crucial to invoke UI updates on main thread
        DispatchQueue.main.async {
            // DEBUG LOG: Add specific logging for ViewModel update

            // First update the viewModel state to reflect the latest data
            self.currentPhase = phase

            // Update text content - now handled consistently for all phases including yield
            let contentToUpdate = content ?? ""

            if !contentToUpdate.isEmpty {
                self.responses[phase] = contentToUpdate

                // Signal UI to update with this change
                self.objectWillChange.send()
            }

            // DEBUG LOG: Log final contentToUpdate

            // Update the message object directly (needed for streaming UI)
            if let msg = self.findMessage(by: targetMessageId) {
                // Make sure we always trigger an update for streaming content
                msg.objectWillChange.send()

                if let newVectorResults = vectorResults {
                    msg.vectorSearchResults = newVectorResults
                }
                if let newWebResults = webResults {
                    msg.webSearchResults = newWebResults
                }

                // Create phase event with all information (without finalContent)
                let phaseEvent = PostchainStreamEvent(
                    phase: phase.rawValue,
                    status: status,
                    content: contentToUpdate,
                    provider: provider,
                    modelName: modelName,
                    webResults: webResults,
                    vectorResults: vectorResults
                )

                // Enhanced debug logging for all phases

                // This is the key call that updates the message content
                // We always update the phase, even if content is empty
                msg.updatePhase(phase, content: contentToUpdate, provider: provider, modelName: modelName, event: phaseEvent, status: status)

            } else {
            }

            // Update structured results based on phase with enhanced logging
            if phase == .experienceVectors {
                if let newVectorResults = vectorResults {
                    self.vectorResultsByMessage[targetMessageId] = newVectorResults

                    // Debug the structure of what we received
                    for (i, result) in newVectorResults.enumerated() {

                        // If we have a content_preview but no content, use the preview
                        if result.content.isEmpty && result.content_preview != nil {
                        }
                    }
                }
            } else if phase == .experienceWeb {
                if let newWebResults = webResults {
                    self.webResultsByMessage[targetMessageId] = newWebResults

                    // Debug the structure of what we received
                    for (i, result) in newWebResults.enumerated() {
                    }
                }
            }

            // Update processing state
            // Consider processing finished only when the final yield phase is complete
            let isLastPhaseComplete = (phase == Phase.allCases.last && status == "complete")
            if isLastPhaseComplete {
                self.isProcessing = false

                // Explicitly dismiss keyboard when processing completes
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                // Don't auto-select yield phase anymore
                // Let the user manually select the phase they want to view
            } else if status == "error" {
                self.isProcessing = false // Also stop on error

                // Also dismiss keyboard on error
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }

            // Force one last UI update to make sure changes are reflected
            self.objectWillChange.send()
        }

        // We've moved all the logic inside the DispatchQueue.main.async block
        // because all UI updates should happen on the main thread

        // Clear any pending work items since we're handling updates immediately now
        updateWorkItem = nil

        // Add a debug note showing we're done processing this event
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
