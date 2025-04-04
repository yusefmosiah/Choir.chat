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
                    modelConfigs: thread?.modelConfigs, // Pass the thread's model configs
                    // Update closure signature to accept provider and modelName
                    onPhaseUpdate: { [weak self] phase, status, content, provider, modelName, webResults, vectorResults in
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

                                // Find the message being updated
                                if let messageId = self.activeMessageId,
                                   let thread = self.currentChoirThread,
                                   let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }) {

                                    let message = thread.messages[messageIndex]
                                    // Update the message object directly with all info
                                    message.updatePhase(phaseEnum, content: content, provider: provider, modelName: modelName)

                                    // Explicitly notify observers for the message and thread
                                    message.objectWillChange.send()
                                    thread.objectWillChange.send()
                                } else {
                                     print("⚠️ Coordinator could not find message \(String(describing: self.activeMessageId)) to update phase \(phase)")
                                }

                                // Update the view model's state (which triggers UI updates)
                                // Pass all received data, including model info
                                self.viewModel?.updatePhaseData(
                                    phase: phaseEnum,
                                    status: status,
                                    content: content,
                                    provider: provider, // Pass provider
                                    modelName: modelName, // Pass modelName
                                    webResults: self.webResults, // Pass stored results
                                    vectorResults: self.vectorResults // Pass stored results
                                )

                                // Update our local coordinator responses dictionary (only text content for now)
                                self.responses[phaseEnum] = content

                                // Update processing state
                                self.processingPhases.insert(phaseEnum)

                                // Removed call to self.updateMessageInThread as update is done above
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
    // Deprecated: updatePhase now requires provider and modelName, so this is obsolete.
    // Calls to this function have been removed.

    // Helper to recover thread state
    func recoverThread(threadId: String) async throws -> ThreadRecoveryResponse {
        return try await api.recoverThread(threadId: threadId)
    }

    // Helper to check API health
    func checkHealth() async throws -> HealthCheckResponse {
        return try await api.healthCheck()
    }
}
