import Foundation
import SwiftUI

@MainActor
class RESTPostchainCoordinator: PostchainCoordinator, ObservableObject {
    private let api: PostchainAPIClient
    private var streamTask: Task<Void, Error>?

    // Use @Published to ensure SwiftUI updates
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false
    @Published private(set) var processingPhases: Set<Phase> = []
    
    // Always use streaming
    var isStreaming = true

    // Thread state
    var currentChoirThread: ChoirThread?

    // Active message identifier to track which message is currently being processed
    var activeMessageId: UUID?

    // ViewModel reference for updates
    weak var viewModel: PostchainViewModel?

    required init() {
        self.api = PostchainAPIClient()
        
        // Pre-initialize all phases with empty content to ensure cards are always displayed
        // This is critical for proper SwiftUI rendering
        for phase in Phase.allCases {
            self.responses[phase] = ""
        }
    }

    func process(_ input: String) async throws {
        // Remove thread parameter to match protocol
        try await processPost(input)
    }

    private func processPost(_ input: String) async throws {
        // Set active thread
        let thread = currentChoirThread
        
        // Set the active message ID to the latest message in the thread
        activeMessageId = thread?.messages.last?.id
        
        // Reset all state
        responses = [:]
        isProcessing = true
        currentPhase = .action
        processingPhases = []
        
        // Pre-initialize phases with empty content to ensure cards are always displayed
        for phase in Phase.allCases {
            self.responses[phase] = ""
        }
        
        // Notify view model of initial state
        viewModel?.updateState()

        // Get context at the start
        let messages = thread?.messages.dropLast(2) ?? []
        // Create contexts from messages (commenting out for now since MessageContext isn't found)
        // let contexts = messages.map { MessageContext(from: $0) }
        
        // Create a streaming task
        isStreaming = true
        
        // Use a continuation to bridge the callback-based API with async/await
        var didResume = false
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Store a reference to the task to enable cancellation
            self.streamTask = Task {
                // Create a simple request body for the streaming API
                let simpleBody = SimplePostchainRequestBody(
                    userQuery: input,
                    threadID: thread?.id.uuidString
                )
                
                // Set up streaming
                self.api.streamPost(
                    endpoint: "simple",
                    body: simpleBody,
                    onPhaseUpdate: { [weak self] phase, outputs in
                        guard let self = self else { return }
                        
                        Task { @MainActor in
                            // Map the phase string to our Phase enum consistently 
                            let phaseEnum: Phase
                            switch phase {
                            case "action":
                                phaseEnum = .action
                            case "experience":
                                phaseEnum = .experience
                                print("🔄 RESTCoordinator received experience phase update")
                            case "intention":
                                phaseEnum = .intention
                            case "observation":
                                phaseEnum = .observation
                            case "understanding":
                                phaseEnum = .understanding
                            case "yield":
                                phaseEnum = .yield
                            default:
                                phaseEnum = .action // Default fallback
                            }
                            
                            // Always update the current phase
                            self.currentPhase = phaseEnum
                            
                            // Process all outputs with a consistent approach
                            for (phaseKey, content) in outputs {
                                print("🔄 Processing output for phase key: \(phaseKey) with content length: \(content.count)")
                                
                                // Use our smart Phase mapping to determine the phase
                                guard let targetPhase = Phase.from(phaseKey) else {
                                    print("⚠️ Unknown phase key: \(phaseKey)")
                                    continue
                                }
                                
                                // Special logging for experience phase
                                if targetPhase == .experience && !content.isEmpty {
                                    print("🔍 Experience phase content: \(content.prefix(30))...")
                                }
                                
                                // Only update if we have actual content
                                if !content.isEmpty {
                                    // Update the view model directly with this phase 
                                    // SwiftUI reactivity will handle the rest
                                    self.viewModel?.updatePhase(targetPhase, state: "streaming", content: content)
                                    
                                    // Update our local responses dictionary
                                    self.responses[targetPhase] = content
                                }
                                
                                // Update processing state
                                self.processingPhases.insert(targetPhase)
                                
                                // Update the message in the thread directly
                                self.updateMessageInThread(targetPhase, content: content)
                            }
                        }
                    },
                    onComplete: {
                        Task { @MainActor in
                            
                            // Log the final state of responses
                            
                            // Log what's in action and experience phases
                            if let actionContent = self.responses[.action] {
                            }
                            
                            if let experienceContent = self.responses[.experience] {
                            } else {
                            }
                            
                            // Mark processing as complete
                            self.processingPhases.removeAll()
                            self.isProcessing = false
                            self.activeMessageId = nil
                            self.isStreaming = false
                            
                            // Force UI refresh
                            self.viewModel?.updateState()
                            
                            // Only resume the continuation once
                            if !didResume {
                                didResume = true
                                continuation.resume()
                            }
                        }
                    },
                    onError: { error in
                        Task { @MainActor in
                            self.processingPhases.removeAll()
                            self.isProcessing = false
                            self.activeMessageId = nil
                            self.viewModel?.updateState()
                            
                            // Only resume the continuation once
                            if !didResume {
                                didResume = true
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                )
            }
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isProcessing = false
        isStreaming = false
        processingPhases.removeAll()
        
        // Clear active message ID when cancelling
        activeMessageId = nil
        
        // Notify view model of the canceled state
        viewModel?.updateState()
    }

    // Helper to check if a specific phase is currently processing
    func isProcessingPhase(_ phase: Phase) -> Bool {
        return processingPhases.contains(phase)
    }
    
    // Helper to update the current message in the thread
    private func updateMessageInThread(_ phase: Phase, content: String) {
        Task { @MainActor in
            guard !content.isEmpty,
                  let messageId = self.activeMessageId,
                  let thread = self.currentChoirThread,
                  let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }) else {
                return
            }
            
            // Get reference to the message (now an ObservableObject)
            let message = thread.messages[messageIndex]
            
            // Set streaming flag
            message.isStreaming = true
            
            // Use the new helper method to update the phase
            // This will automatically trigger SwiftUI updates through @Published
            message.updatePhase(phase, content: content)
            
            // No need to update the array since we're working with a reference type
            
            // Log update for debugging
            if phase == .experience {
                print("✅ Updated experience phase in message: \(content.prefix(20))...")
            }
        }
    }
}
