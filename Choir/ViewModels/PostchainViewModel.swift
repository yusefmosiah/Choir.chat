import SwiftUI

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
        print("🚀 Model configs being sent to backend:")
        let savedConfigs = ModelConfigManager.shared.loadModelConfigs()
        for (phase, config) in savedConfigs {
            print("Phase: \(phase.rawValue), Provider: \(config.provider), Model: \(config.model)")
            print("API Keys: google=\(config.googleApiKey?.prefix(5) ?? "nil"), openrouter=\(config.openrouterApiKey?.prefix(5) ?? "nil")")
        }

        do {
            if let coordinator = coordinator as? PostchainCoordinatorImpl {
                // Pass progress callback for large inputs
                try await coordinator.processWithProgress(
                    input, 
                    modelConfigs: savedConfigs,
                    onProgress: { [weak self] status in
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
    // Updated signature to include provider and modelName
    func updatePhaseData(phase: Phase, status: String, content: String?, provider: String?, modelName: String?, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil, messageId: String? = nil, finalContent: String? = nil) {
        // Cancel any pending update
        updateWorkItem?.cancel()
        
        // Use provided messageId or fall back to activeMessageId
        let targetMessageId = messageId ?? self.activeMessageId
        
        print("📊 STREAMING UI: Updating phase \(phase.rawValue) (status: \(status)) for message \(targetMessageId)")
        print("📊 STREAMING UI: Content length: \(content?.count ?? 0), Provider: \(provider ?? "none")")
        
        // Crucial to invoke UI updates on main thread
        DispatchQueue.main.async {
            // First update the viewModel state to reflect the latest data
            self.currentPhase = phase
            
            // Update text content immediately
            var contentToUpdate = ""
            
            // For yield phase, the content is ONLY in finalContent field from backend
            if phase == .yield && finalContent != nil {
                contentToUpdate = finalContent!
                print("📊 VIEWMODEL: Yield phase using finalContent: \(finalContent!.prefix(50))")
            } else {
                contentToUpdate = content ?? ""
                if !contentToUpdate.isEmpty {
                    print("📊 VIEWMODEL: \(phase.rawValue) phase using content: \(contentToUpdate.prefix(50))")
                }
            }
            
            if !contentToUpdate.isEmpty {
                self.responses[phase] = contentToUpdate
                
                // Signal UI to update with this change
                self.objectWillChange.send()
            }
        
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
                
                // Set or update phase content directly in the message
                // This ensures any streaming updates are reflected immediately
                // Use finalContent if available (critical for yield phase)
                let updatedContent = finalContent ?? content ?? ""
                
                // Create phase event with all information including finalContent
                let phaseEvent = PostchainStreamEvent(
                    phase: phase.rawValue,
                    status: status,
                    content: updatedContent,
                    provider: provider,
                    modelName: modelName,
                    webResults: webResults,
                    vectorResults: vectorResults,
                    finalContent: finalContent
                )
                
                // Enhanced debug logging for all phases
                print("📊 PHASE UPDATE (\(phase.rawValue)): Status: \(status)")
                print("📊 PHASE UPDATE (\(phase.rawValue)): Content length: \(updatedContent.count)")
                print("📊 PHASE UPDATE (\(phase.rawValue)): Content empty: \(updatedContent.isEmpty)")
                print("📊 PHASE UPDATE (\(phase.rawValue)): Has finalContent: \(finalContent != nil)")
                print("📊 PHASE UPDATE (\(phase.rawValue)): Provider: \(provider ?? "nil")")
                
                // This is the key call that updates the message content
                // We always update the phase, even if content is empty
                msg.updatePhase(phase, content: updatedContent, provider: provider, modelName: modelName, event: phaseEvent, status: status)
                
                print("📊 STREAMING UI: Updated message phase content for \(phase.rawValue)")
            } else {
                print("⚠️ STREAMING UI: Could not find message with ID \(targetMessageId)")
            }
            
            // Update structured results based on phase
            if phase == .experienceVectors {
                if let newVectorResults = vectorResults {
                    self.vectorResultsByMessage[targetMessageId] = newVectorResults
                    print("📊 STREAMING UI: Updated vector results: \(newVectorResults.count) items")
                }
            } else if phase == .experienceWeb {
                if let newWebResults = webResults {
                    self.webResultsByMessage[targetMessageId] = newWebResults
                    print("📊 STREAMING UI: Updated web results: \(newWebResults.count) items")
                }
            }
            
            // Update processing state
            // Consider processing finished only when the final yield phase is complete
            let isLastPhaseComplete = (phase == Phase.allCases.last && status == "complete")
            if isLastPhaseComplete {
                self.isProcessing = false
                print("🏁 STREAMING UI: Processing finished with yield phase completion")
                
                // Close the loop: auto-select yield if user is on action phase
                if let message = self.findMessage(by: targetMessageId), message.selectedPhase == .action {
                    withAnimation(.spring()) {
                        self.updateSelectedPhase(for: message, phase: .yield)
                    }
                }
            } else if status == "error" {
                self.isProcessing = false // Also stop on error
                print("🛑 STREAMING UI: Processing stopped due to error in phase \(phase.rawValue)")
            }
            
            // Force one last UI update to make sure changes are reflected
            self.objectWillChange.send()
        }
        
        // We've moved all the logic inside the DispatchQueue.main.async block
        // because all UI updates should happen on the main thread
        
        // Clear any pending work items since we're handling updates immediately now
        updateWorkItem = nil
        
        // Add a debug note showing we're done processing this event
        print("📊 STREAMING UI: Finished processing event for phase \(phase.rawValue)")
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
