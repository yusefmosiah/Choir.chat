import Foundation
import SwiftUI

/// Implementation of PostchainCoordinator using the PostchainAPIClient
@MainActor
class PostchainCoordinatorImpl: PostchainCoordinator, ObservableObject {
    // MARK: - Properties

    // Auth service for authentication
    private let authService: AuthService

    // API client for making requests
    private let apiClient: PostchainAPIClient

    // Task for managing the current streaming operation
    private var streamTask: Task<Void, Error>?

    // Background task identifier for this coordinator
    private let backgroundTaskIdentifier = "com.choir.postchain.processing"

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
        // Get the auth service from the environment
        self.authService = AuthService.shared

        // Initialize API client with auth service
        self.apiClient = PostchainAPIClient(authService: self.authService)

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

        // End the background task
        BackgroundTaskManager.shared.endTask(identifier: backgroundTaskIdentifier)

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

        // Start a background task to ensure processing continues in the background
        BackgroundTaskManager.shared.beginTask(identifier: backgroundTaskIdentifier) {
            // This is called if the background task is about to expire
            print("PostChain background task is about to expire")
            self.cancel() // Cancel the current processing
        }

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

                    // Add this flag to track if we've received any events
                    var receivedEvents = false

                    for await event in eventStream {
                        // Set flag since we received at least one event
                        receivedEvents = true

                        // Handle cancellation
                        if Task.isCancelled {
                            break
                        }

                        // Process the event immediately

                        if let content = event.content, !content.isEmpty {
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
                    }


                    // Streaming completed successfully
                    isProcessing = false
                    processingPhases.removeAll()
                    activeMessageId = nil
                    isProcessingLargeInput = false
                    processingStatus = ""

                    // Notify view model
                    viewModel?.updateState()

                    // End the background task since processing is complete
                    BackgroundTaskManager.shared.endTask(identifier: backgroundTaskIdentifier)

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

                    // End the background task since processing encountered an error
                    BackgroundTaskManager.shared.endTask(identifier: backgroundTaskIdentifier)

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

        // Enhanced model information logging for all phases
        print("PostchainEvent - Phase: \(event.phase), Status: \(event.status)")
        print("  Provider: \(event.provider ?? "nil")")
        print("  ModelName: \(event.modelName ?? "nil")")

        // Special diagnostic for yield phase - log structure of entire event
        if event.phase == "yield" {
            if let content = event.content, !content.isEmpty {
                print("  Yield content length: \(content.count)")
            }
            if let provider = event.provider {
                print("  Yield provider: \(provider)")
            }
            if let modelName = event.modelName {
                print("  Yield modelName: \(modelName)")
            }
        }

        // Update the current phase
        currentPhase = phaseEnum

        // --- BEGIN VECTOR RESULTS DEBUG ---
        if phaseEnum == .experienceVectors {
            if let results = event.vectorResults {
            }
        }
        // --- END VECTOR RESULTS DEBUG ---

        // Store search results if available
        if let webResults = event.webResults {
            self.webResults = webResults
        }

        if let vectorResults = event.vectorResults {

            // Enhanced logging for vector results inspection
            for (i, vector) in vectorResults.enumerated() {
            }

            self.vectorResults = vectorResults
        }

        // Get content (could be empty for some events)
        let content = event.content ?? ""

        // Debug log content
        if event.phase == "yield" {
        }

        // Log model info for debugging

        // Find the message being updated
        if let messageId = activeMessageId,
           let thread = currentChoirThread,
           let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }) {

            let message = thread.messages[messageIndex]

            // Update the message with all the information (without finalContent)
            // Use the extension to create a PostchainStreamEvent from a PostchainEvent
            let streamEvent = PostchainStreamEvent(from: event)

            // Add extra debugging specifically for model name issue

            // Check if the event.modelName is defined but empty
            if let modelName = event.modelName {
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
        }

        // Create a PostchainStreamEvent from the event
        let streamEvent = PostchainStreamEvent(from: event)

        // Update the view model (always update even if content is empty to handle status changes)
        viewModel?.updatePhaseData(
            phase: phaseEnum,
            status: streamEvent.status,
            content: content,
            provider: streamEvent.provider,
            modelName: streamEvent.modelName,
            webResults: self.webResults,
            vectorResults: self.vectorResults,
            noveltyReward: streamEvent.noveltyReward,
            maxSimilarity: streamEvent.maxSimilarity,
            citationReward: streamEvent.citationReward,
            citationExplanations: streamEvent.citationExplanations,
            messageId: activeMessageId?.uuidString
        )

        // Update local responses (even if empty, to ensure we track all phases)
        responses[phaseEnum] = content

        // Update processing state
        processingPhases.insert(phaseEnum)

        // If phase is complete, remove it from processing phases
        if event.status == "complete" {
            processingPhases.remove(phaseEnum)

            // Handle automatic thread title generation
            if phaseEnum == .action,
               let thread = currentChoirThread,
               let messageId = activeMessageId,
               let messageIndex = thread.messages.firstIndex(where: { $0.id == messageId }),
               thread.messages.count == 2, // User msg (0) + AI msg (1)
               messageIndex == 1, // Ensure we're updating the AI message
               thread.title.hasPrefix("✎ ") // Check if title is still default
            {
                // Get the user prompt from the first message (index 0)
                if thread.messages.count > 0 && thread.messages[0].isUser {
                    let userMessage = thread.messages[0]
                    let userPrompt = userMessage.content
                    var generatedTitle = userPrompt.prefixWords(10)
                    let finalTitle = generatedTitle.isEmpty ? "New Thread" : generatedTitle

                    // Check for duplicate titles and append an incrementing number if needed
                    var uniqueTitle = finalTitle
                    var counter = 1

                    // Get all existing threads to check for duplicates
                    Task {
                        let allThreads = await ThreadPersistenceService.shared.loadAllThreads()

                        // Check if the title already exists
                        while allThreads.contains(where: {
                            $0.id != thread.id && // Don't compare with self
                            $0.title == uniqueTitle
                        }) {
                            // Append incrementing number for duplicates
                            counter += 1
                            uniqueTitle = "\(finalTitle) (\(counter))"
                        }

                        // Update thread title with the unique title
                        await MainActor.run {
                            thread.updateTitle(uniqueTitle)

                            // Force UI update for this thread
                            // Explicitly notify observers that the thread has changed
                            thread.objectWillChange.send()

                            // Also notify the ThreadManager to update its UI
                            NotificationCenter.default.post(name: NSNotification.Name("ThreadMetadataDidChange"), object: thread)
                        }
                    }
                } else {
                    // Fallback to the old behavior if user message is not found
                    let message = thread.messages[messageIndex]
                    let actionContent = message.getPhaseContent(.action)
                    let generatedTitle = actionContent.prefixWords(10)
                    let finalTitle = generatedTitle.isEmpty ? "New Thread" : generatedTitle

                    // Update thread title
                    thread.updateTitle(finalTitle)

                    // Force UI update for this thread
                    DispatchQueue.main.async {
                        // Explicitly notify observers that the thread has changed
                        thread.objectWillChange.send()

                        // Also notify the ThreadManager to update its UI
                        NotificationCenter.default.post(name: NSNotification.Name("ThreadMetadataDidChange"), object: thread)
                    }
                }
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
