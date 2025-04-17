import Foundation
import SwiftUI

/// Implementation of PostchainCoordinator using the PostchainAPIClient
@MainActor
class PostchainCoordinatorImpl: PostchainCoordinator, ObservableObject {
    // MARK: - Properties

    // API client for making requests
    private let apiClient: PostchainAPIClient

    // Task for managing the current streaming operation
    private var streamTask: Task<Void, Error>?

    // Published state for SwiftUI binding
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false
    @Published private(set) var processingPhases: Set<Phase> = []

    // Progress tracking for large inputs
    @Published var processingStatus: String = ""
    @Published var isProcessingLargeInput: Bool = false

    // Search results
    @Published private(set) var webResults: [SearchResult] = []
    @Published private(set) var vectorResults: [VectorSearchResult] = []

    // Always use streaming - could be made configurable
    var isStreaming = true

    // Thread state
    var currentChoirThread: ChoirThread?

    // Active message identifier to track which message is being processed
    var activeMessageId: UUID?

    // ViewModel reference for updates
    weak var viewModel: PostchainViewModel?

    // MARK: - Initialization

    required init() {
        self.apiClient = PostchainAPIClient()

        // Pre-initialize all phases with empty content to ensure cards are always displayed
        for phase in Phase.allCases {
            self.responses[phase] = ""
        }
    }

    // MARK: - PostchainCoordinator Protocol

    func process(_ input: String, modelConfigs: [Phase: ModelConfig]) async throws {
        // Reset state
        processingStatus = ""
        isProcessingLargeInput = input.count > 10000

        // Process the request
        try await processPost(input, modelConfigs: modelConfigs)
    }

    func cancel() {
        // Cancel the streaming task
        streamTask?.cancel()
        streamTask = nil

        // Reset state
        isProcessing = false
        isStreaming = false
        processingPhases.removeAll()
        processingStatus = ""
        isProcessingLargeInput = false

        // Clear active message ID
        activeMessageId = nil

        // Notify view model
        viewModel?.updateState()
    }

    // MARK: - Implementation

    /// Process a post through the postchain with progress updates
    /// - Parameters:
    ///   - input: User input text
    ///   - modelConfigs: Optional model configurations
    ///   - onProgress: Optional callback for progress updates
    /// - Throws: Error if processing fails
    func processWithProgress(
        _ input: String,
        modelConfigs: [Phase: ModelConfig],
        onProgress: ((String) -> Void)? = nil
    ) async throws {
        processingStatus = "Preparing request..."
        onProgress?("Preparing request...")

        try await processPost(input, modelConfigs: modelConfigs)
    }

    /// Processes a post through the postchain
    /// - Parameters:
    ///   - input: User input text
    ///   - modelConfigs: Optional model configurations
    private func processPost(_ input: String, modelConfigs: [Phase: ModelConfig]) async throws {
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

        // Pre-initialize phases with empty content
        for phase in Phase.allCases {
            self.responses[phase] = ""
        }

        // Notify view model of initial state
        viewModel?.updateState()

        // Use a continuation to bridge the asynchronous streaming with async/await
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Create a task for streaming
            streamTask = Task {
                do {
                    if isProcessingLargeInput {
                        processingStatus = "Processing large input..."
                    }

                    // Get a thread ID - either from the existing thread or create a new one
                    let threadId = thread?.id.uuidString ?? UUID().uuidString

                    // Stream the postchain process
                    let eventStream = try await apiClient.streamPostchain(
                        query: input,
                        threadId: threadId,
                        modelConfigs: modelConfigs
                    )

                    if isProcessingLargeInput {
                        processingStatus = "Receiving responses..."
                    }

                    // Process the events as they arrive
                    print("🚀 STREAMING: Beginning to process events from stream")

                    // Add this flag to track if we've received any events
                    var receivedEvents = false

                    for await event in eventStream {
                        // Set flag since we received at least one event
                        receivedEvents = true

                        // Handle cancellation
                        if Task.isCancelled {
                            print("🚫 STREAMING: Task cancelled")
                            break
                        }

                        // Process the event immediately
                        print("🚀 STREAMING: Received event for phase: \(event.phase), status: \(event.status), content length: \(event.content?.count ?? 0)")

                        if let content = event.content, !content.isEmpty {
                            print("🚀 STREAMING: Content sample: \(content.prefix(50))...")
                        }

                        // Process the event and update UI immediately
                        await handlePostchainEvent(event)

                        // Force UI updates on the main thread after each event
                        await MainActor.run {
                            // Update the view model first
                            viewModel?.objectWillChange.send()

                            // Then update the message and thread
                            if let thread = currentChoirThread {
                                thread.objectWillChange.send()

                                // Explicitly update the message
                                if let messageId = activeMessageId,
                                   let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }) {
                                    let message = thread.messages[messageIndex]
                                    message.objectWillChange.send()
                                }
                            }

                            // Save thread to persist changes
                            if let thread = currentChoirThread {
                                Task {
                                    ThreadPersistenceService.shared.saveThread(thread)
                                }
                            }
                        }
                    }

                    if !receivedEvents {
                        print("⚠️ STREAMING: No events were received from the stream")
                    }

                    print("🏁 STREAMING: Event stream completed")

                    // Streaming completed successfully
                    isProcessing = false
                    processingPhases.removeAll()
                    activeMessageId = nil
                    isProcessingLargeInput = false
                    processingStatus = ""

                    // Notify view model
                    viewModel?.updateState()

                    // Resume the continuation with success
                    continuation.resume()
                } catch {
                    // Handle errors
                    isProcessing = false
                    processingPhases.removeAll()
                    activeMessageId = nil
                    isProcessingLargeInput = false
                    processingStatus = ""

                    // Notify view model
                    viewModel?.updateState()

                    // Resume the continuation with error
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Handles an event from the postchain API
    /// - Parameter event: The event to process
    private func handlePostchainEvent(_ event: PostchainEvent) async {
        // Map the phase string to our Phase enum
        let phaseEnum = mapStringToPhase(event.phase)

        // Debug output
        print("📲 Received event for phase: \(event.phase), status: \(event.status), content length: \(event.content?.count ?? 0)")

        // Enhanced model information logging for all phases
        print("📲 MODEL INFO: Phase: \(event.phase), Provider: \(event.provider ?? "nil"), ModelName: \(event.modelName ?? "nil")")

        // Special diagnostic for yield phase - log structure of entire event
        if event.phase == "yield" {
            print("📊 YIELD DIAGNOSIS - START")
            print("📊 YIELD EVENT: Phase: \(event.phase)")
            print("📊 YIELD EVENT: Status: \(event.status)")
            print("📊 YIELD EVENT: Has content: \(event.content != nil)")
            print("📊 YIELD EVENT: Content empty: \(event.content?.isEmpty ?? true)")
            print("📊 YIELD EVENT: Content length: \(event.content?.count ?? 0)")
            if let content = event.content, !content.isEmpty {
                print("📊 YIELD EVENT: Content first chars: \(content.prefix(50))")
                print("📊 YIELD EVENT: Content last chars: \(content.suffix(50))")
            }
            print("📊 YIELD EVENT: Has provider: \(event.provider != nil)")
            print("📊 YIELD EVENT: Has modelName: \(event.modelName != nil)")
            if let provider = event.provider, let modelName = event.modelName {
                print("📊 YIELD EVENT: Provider/ModelName values: \(provider)/\(modelName)")
            }
            print("📊 YIELD DIAGNOSIS - END")
        }

        // Update the current phase
        currentPhase = phaseEnum

        // --- BEGIN VECTOR RESULTS DEBUG ---
        if phaseEnum == .experienceVectors {
            print("🩺 COORD DEBUG: Handling experience_vectors phase event.")
            print("🩺 COORD DEBUG: event.vectorResults is nil? \(event.vectorResults == nil)")
            if let results = event.vectorResults {
                print("🩺 COORD DEBUG: event.vectorResults count: \(results.count)")
                print("🩺 COORD DEBUG: event.vectorResults is empty? \(results.isEmpty)")
            }
        }
        // --- END VECTOR RESULTS DEBUG ---

        // Store search results if available
        if let webResults = event.webResults {
            print("📲 Received web results: \(webResults.count) items")
            self.webResults = webResults
        }

        if let vectorResults = event.vectorResults {
            print("📲 Received vector results: \(vectorResults.count) items")

            // Enhanced logging for vector results inspection
            for (i, vector) in vectorResults.enumerated() {
                print("📲 VECTOR #\(i+1): Score: \(vector.score), Content length: \(vector.content.count)")
                print("📲 VECTOR #\(i+1): Content sample: \(vector.content.prefix(50))...")
                print("📲 VECTOR #\(i+1): Has content_preview: \(vector.content_preview != nil)")
            }

            self.vectorResults = vectorResults
        }

        // Get content (could be empty for some events)
        let content = event.content ?? ""

        // Debug log content
        if event.phase == "yield" {
            print("🟡 COORD: Handling Yield Event with content: \(content.prefix(50))...")
        }

        // Log model info for debugging
        print("📘 MODEL DEBUG: Phase \(phaseEnum.rawValue) - Provider: \(event.provider ?? "nil"), ModelName: \(event.modelName ?? "nil")")

        // Find the message being updated
        if let messageId = activeMessageId,
           let thread = currentChoirThread,
           let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }) {

            let message = thread.messages[messageIndex]

            // Update the message with all the information (without finalContent)
            let streamEvent = PostchainStreamEvent(
                phase: event.phase,
                status: event.status,
                content: content,
                provider: event.provider,
                modelName: event.modelName,
                webResults: self.webResults,
                vectorResults: self.vectorResults
            )

            // Add extra debugging specifically for model name issue
            print("🔧 MODEL DEBUG: About to update Message for phase \(phaseEnum.rawValue)")
            print("🔧 MODEL DEBUG: - Raw provider from event: \"\(event.provider ?? "nil")\"")
            print("🔧 MODEL DEBUG: - Raw modelName from event: \"\(event.modelName ?? "nil")\"")

            // Check if the event.modelName is defined but empty
            if let modelName = event.modelName {
                print("🔧 MODEL DEBUG: - modelName is empty: \(modelName.isEmpty), length: \(modelName.count)")
            }

            // Update the message with the streaming content, even if it's incomplete
            // Note: We want to update even partial content for streaming appearance
            message.updatePhase(
                phaseEnum,
                content: content,
                provider: event.provider,
                modelName: event.modelName,
                event: streamEvent,
                status: event.status
            )

            // Force UI update for this message
            DispatchQueue.main.async { [weak self] in
                message.objectWillChange.send()
                thread.objectWillChange.send()
                self?.viewModel?.objectWillChange.send()
            }

            // Ensure observers are notified
            message.objectWillChange.send()
            thread.objectWillChange.send()

            // Save the thread to preserve changes
            Task {
                await Task.detached {
                    ThreadPersistenceService.shared.saveThread(thread)
                }.value
            }
        } else {
            print("⚠️ Could not find message for event. Active ID: \(activeMessageId?.uuidString ?? "nil"), Thread: \(currentChoirThread?.id.uuidString ?? "nil")")
        }

        // Update the view model (always update even if content is empty to handle status changes)
        viewModel?.updatePhaseData(
            phase: phaseEnum,
            status: event.status,
            content: content,
            provider: event.provider,
            modelName: event.modelName,
            webResults: self.webResults,
            vectorResults: self.vectorResults,
            messageId: activeMessageId?.uuidString
        )

        // Update local responses (even if empty, to ensure we track all phases)
        responses[phaseEnum] = content

        // Update processing state
        processingPhases.insert(phaseEnum)

        // If phase is complete, remove it from processing phases
        if event.status == "complete" {
            print("📲 Phase \(phaseEnum.rawValue) completed")
            processingPhases.remove(phaseEnum)

            // Handle automatic thread title generation
            if phaseEnum == .action,
               let thread = currentChoirThread,
               let messageId = activeMessageId,
               let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }),
               thread.messages.count == 2, // User msg (0) + AI msg (1)
               messageIndex == 1, // Ensure we're updating the AI message
               thread.title.hasPrefix("ChoirThread ") // Check if title is still default
            {
                let message = thread.messages[messageIndex]
                let actionContent = message.getPhaseContent(.action)
                let generatedTitle = actionContent.prefixWords(10)
                let finalTitle = generatedTitle.isEmpty ? "New Thread" : generatedTitle

                // Update thread title
                thread.updateTitle(finalTitle)
            }
        }
    }

    // MARK: - Helper Methods

    /// Maps a string phase name to the Phase enum
    /// - Parameter phaseString: The phase name as a string
    /// - Returns: The corresponding Phase enum value
    func mapStringToPhase(_ phaseString: String) -> Phase {
        switch phaseString {
        case "action":
            return .action
        case "experience":
            // Legacy case - defaulting to vectors
            return .experienceVectors
        case "experience_vectors":
            return .experienceVectors
        case "experience_web":
            return .experienceWeb
        case "intention":
            return .intention
        case "observation":
            return .observation
        case "understanding":
            return .understanding
        case "yield":
            return .yield
        default:
            return .action // Default fallback
        }
    }

    /// Checks if a specific phase is currently processing
    /// - Parameter phase: The phase to check
    /// - Returns: True if the phase is currently processing
    func isProcessingPhase(_ phase: Phase) -> Bool {
        return processingPhases.contains(phase)
    }

    /// Recovers a thread state from the server
    /// - Parameter threadId: ID of the thread to recover
    /// - Returns: Thread recovery information
    /// - Throws: Error if recovery fails
    func recoverThread(threadId: String) async throws -> ThreadRecoveryResponse {
        return try await apiClient.recoverThread(threadId: threadId)
    }

    /// Checks the health of the API service
    /// - Returns: Health status information
    /// - Throws: Error if the health check fails
    func checkHealth() async throws -> HealthCheckResponse {
        return try await apiClient.checkHealth()
    }
}
