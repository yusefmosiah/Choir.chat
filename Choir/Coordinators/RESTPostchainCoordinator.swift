import Foundation
import SwiftUI

@MainActor
class RESTPostchainCoordinator: PostchainCoordinator, ObservableObject {
    private let api: RESTPostchainAPIClient
    private var streamTask: Task<Void, Error>?

    // Use @Published to ensure SwiftUI updates
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false
    @Published private(set) var processingPhases: Set<Phase> = []

    // Search results
    @Published private(set) var webResults: [SearchResult] = []
    @Published private(set) var vectorResults: [VectorSearchResult] = []

    // Always use streaming
    var isStreaming = true

    // Thread state
    var currentChoirThread: ChoirThread?

    // Active message identifier to track which message is currently being processed
    var activeMessageId: UUID?
    
    // Implementation of the messages property
    var messages: [Message] {
        return currentChoirThread?.messages ?? []
    }

    // ViewModel reference for updates
    weak var viewModel: PostchainViewModel?

    required init() {
        self.api = RESTPostchainAPIClient()

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
        webResults = []
        vectorResults = []

        // Pre-initialize phases with empty content to ensure cards are always displayed
        for phase in Phase.allCases {
            self.responses[phase] = ""
        }

        // Notify view model of initial state
        viewModel?.updateState()

        // Create a streaming task
        isStreaming = true

        // Use a continuation to bridge the callback-based API with async/await
        var didResume = false

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Store a reference to the task to enable cancellation
            self.streamTask = Task {
                // Set up streaming with the langchain endpoint
                self.api.streamLangchain(
                    query: input,
                    threadId: thread?.id.uuidString ?? UUID().uuidString,
                    onPhaseUpdate: { [weak self] phase, status, content, webResults, vectorResults in
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

                            // Store search results if available
                            if let webResults = webResults {
                                self.webResults = webResults
                            }

                            if let vectorResults = vectorResults {
                                self.vectorResults = vectorResults
                            }

                            // Only update if we have actual content
                            if !content.isEmpty {
                                print("🔄 Processing output for phase: \(phase) with content length: \(content.count)")

                                // Update the view model directly with phase content AND results
                                // SwiftUI reactivity will handle the rest
                                self.viewModel?.updatePhaseData(
                                    phase: phaseEnum,
                                    status: status,
                                    content: content,
                                    webResults: self.webResults, // Pass stored results
                                    vectorResults: self.vectorResults // Pass stored results
                                )

                                // Update our local responses dictionary (only text content)
                                self.responses[phaseEnum] = content

                                // Update processing state
                                self.processingPhases.insert(phaseEnum)

                                // Update the message in the thread directly
                                self.updateMessageInThread(phaseEnum, content: content)
                            }

                            // If phase is complete, remove it from processing phases
                            if status == "complete" {
                                self.processingPhases.remove(phaseEnum)
                            }
                        }
                    },
                    onComplete: {
                        Task { @MainActor in
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

            // IMPORTANT: Only update the message that's currently being processed
            // This ensures each message maintains its own independent phases
            if message.id == activeMessageId {
                // Set streaming flag
                message.isStreaming = true

                // Use the helper method to update the phase
                // This will automatically trigger SwiftUI updates through @Published
                message.updatePhase(phase, content: content)

                // Log update for debugging
                if phase == .experience {
                    print("✅ Updated experience phase in message \(message.id): \(content.prefix(20))...")
                }

                // Add explicit notification
                message.objectWillChange.send()

                // Force SwiftUI to recognize changes in parent thread
                self.currentChoirThread?.objectWillChange.send()
            } else {
                print("⚠️ Attempted to update message \(message.id) but active message is \(String(describing: activeMessageId))")
            }
        }
    }

    // Helper to recover thread state
    func recoverThread(threadId: String) async throws -> ThreadRecoveryResponse {
        return try await api.recoverThread(threadId: threadId)
    }

    // Helper to check API health
    func checkHealth() async throws -> HealthCheckResponse {
        return try await api.healthCheck()
    }
}
