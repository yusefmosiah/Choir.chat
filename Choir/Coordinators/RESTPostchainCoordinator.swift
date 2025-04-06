import Foundation
import SwiftUI
import CoreData // Import CoreData
@MainActor
class RESTPostchainCoordinator: PostchainCoordinator, ObservableObject {
    var activeMessageId: UUID?
    
    func process(_ input: String) async throws {
    }
    
    var currentChoirThread: ChoirThread?
    
    private let api: RESTPostchainAPIClient
    private var streamTask: Task<Void, Error>?

    // Use @Published to ensure SwiftUI updates
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false
    @Published private(set) var processingPhases: Set<Phase> = []

    // Removed webResults, vectorResults properties

    // Always use streaming
    var isStreaming = true

    // Thread state
    // Removed currentChoirThread and activeMessageId

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

    // Updated process signature to accept CDThread
    func process(_ input: String, thread: CDThread) async throws {
        try await processPost(input: input, thread: thread)
    }

    // Updated processPost signature
    private func processPost(input: String, thread: CDThread) async throws {
        // Removed active thread/message ID setting logic

        // Reset all state
        responses = [:]
        isProcessing = true
        currentPhase = .action
        processingPhases = []
        // Removed webResults/vectorResults reset

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
                // --- Fetch and Format History ---
                let recentTurns = PersistenceManager.shared.fetchTurns(for: thread).suffix(10) // Example: Fetch last 10 turns
                let recentHistory: [MessageHistoryItem] = recentTurns.flatMap { turn -> [MessageHistoryItem] in
                    var items: [MessageHistoryItem] = []
                    if let userQuery = turn.userQuery {
                        items.append(MessageHistoryItem(role: "user", content: userQuery))
                    }
                    if let aiResponse = turn.aiResponseContent {
                         items.append(MessageHistoryItem(role: "assistant", content: aiResponse))
                    }
                    return items
                }
                print("📚 Sending \(recentHistory.count) history items to API.")

                // --- Call API Client ---
                self.api.streamLangchain(
                    query: input,
                    threadId: thread.id?.uuidString ?? UUID().uuidString, // Use passed thread's ID
                    recentHistory: recentHistory, // Pass formatted history
                    modelConfigs: nil, // TODO: Adapt model config logic if needed (e.g., fetch from thread?)
                    // Updated onPhaseUpdate signature (no search results)
                    onPhaseUpdate: { [weak self] phase, status, content, provider, modelName in
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

                            // Removed search result handling from onPhaseUpdate

                            // Only update if we have actual content
                            if !content.isEmpty {
                                print("🔄 Processing output for phase: \(phase) with content length: \(content.count)")

                                // Removed logic updating activeMessage - UI updates via Core Data changes

                                // Update the view model's state (which triggers UI updates)
                                // Pass all received data, including model info
                                self.viewModel?.updatePhaseData(
                                    phase: phaseEnum,
                                    status: status,
                                    content: content,
                                    provider: provider, // Pass provider
                                    modelName: modelName, // Pass modelName
                                    // Removed webResults/vectorResults from viewModel update call
                                )

                                // Update our local coordinator responses dictionary (only text content for now)
                                self.responses[phaseEnum] = content

                                // Update processing state
                                self.processingPhases.insert(phaseEnum)

                                // Removed call to self.updateMessageInThread
                            }

                            // If phase is complete, remove it from processing phases
                            if status == "complete" {
                                self.processingPhases.remove(phaseEnum)
                            }
                        }
                    },
                    // NEW: Handle final turn data
                    onTurnComplete: { [weak self] turnData in
                         guard let self = self else { return }
                         print("✅ Coordinator received final turn data: \(turnData.turnId)")
                         Task { @MainActor in
                             // Save the completed turn to Core Data
                             let phaseOutputsJSON = self.encodeToJSON(turnData.phaseOutputs)
                             let metadataJSON = self.encodeToJSON(turnData.metadata) // Encode the metadata struct

                             PersistenceManager.shared.createTurn(
                                 userQuery: turnData.userQuery,
                                 aiResponseContent: turnData.aiResponseContent,
                                 phaseOutputsJSON: phaseOutputsJSON,
                                 metadataJSON: metadataJSON,
                                 for: thread // Use the thread passed to processPost
                             )
                             // UI should update automatically via @FetchRequest
                         }
                    },
                    onComplete: { [weak self] in // Add weak self capture list
                        Task { @MainActor in
                            // Remove invalid conditional binding
                            guard let self = self else { return } // This properly unwraps optional self from capture
                            // Mark processing as complete AFTER stream ends
                            self.processingPhases.removeAll()
                            self.isProcessing = false
                            // self.activeMessageId = nil // Removed
                            self.isStreaming = false

                            // Force UI refresh if needed (though Core Data should handle it)
                            self.viewModel?.updateState()

                            // Only resume the continuation once
                            if !didResume {
                                didResume = true
                                continuation.resume() // Resume the original async call
                            }
                        }
                    },
                    onError: { error in
                        Task { @MainActor in
                            self.processingPhases.removeAll()
                            self.isProcessing = false
                            // self.activeMessageId = nil // Removed
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

        // Removed activeMessageId reset

        // Notify view model of the canceled state
        viewModel?.updateState()
    }

    // Helper to check if a specific phase is currently processing
    func isProcessingPhase(_ phase: Phase) -> Bool {
        return processingPhases.contains(phase)
    }

    // Helper to update the current message in the thread
    // Removed deprecated updateMessageInThread helper

    // Helper to encode Encodable types to JSON String
    private func encodeToJSON<T: Encodable>(_ data: T) -> String? {
        let encoder = JSONEncoder()
        // encoder.outputFormatting = .prettyPrinted // Optional
        guard let jsonData = try? encoder.encode(data) else {
            print("Error encoding data to JSON: \(T.self)")
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
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
