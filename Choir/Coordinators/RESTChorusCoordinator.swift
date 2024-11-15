import SwiftUI

@MainActor
class RESTChorusCoordinator: ChorusCoordinator, ObservableObject {
    private let api: ChorusAPIClient
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false

    // Response state
    private(set) var actionResponse: ActionResponse?
    private(set) var experienceResponse: ExperienceResponse?
    private(set) var intentionResponse: IntentionResponse?
    private(set) var observationResponse: ObservationResponse?
    private(set) var understandingResponse: UnderstandingResponse?
    private(set) var yieldResponse: YieldResponse?

    // Continuations to manage the streams
    private var phaseContinuation: AsyncStream<Phase>.Continuation?
    private var responsesContinuation: AsyncStream<[Phase: String]>.Continuation?
    private var processingContinuation: AsyncStream<Bool>.Continuation?

    // Async sequences
    var currentPhaseSequence: AsyncStream<Phase> {
        AsyncStream { continuation in
            phaseContinuation = continuation
            continuation.yield(currentPhase)
        }
    }

    var responsesSequence: AsyncStream<[Phase: String]> {
        AsyncStream { continuation in
            responsesContinuation = continuation
            continuation.yield(responses)
        }
    }

    var isProcessingSequence: AsyncStream<Bool> {
        AsyncStream { continuation in
            processingContinuation = continuation
            continuation.yield(isProcessing)
        }
    }

    // Add context handling
    var currentThread: Thread?

    required init() {
        self.api = ChorusAPIClient()
    }

    func process(_ input: String) async throws {
        try await process(input, thread: currentThread)
    }

    private func process(_ input: String, thread: Thread?) async throws {
        currentThread = thread

        // Get context at the start
        let messages = thread?.messages ?? []
        let contexts = messages.map { MessageContext(from: $0) }

        // Add detailed logging
        print("Thread ID: \(thread?.id.uuidString ?? "nil")")
        print("Message count: \(messages.count)")
        print("Messages:")
        for (i, msg) in messages.enumerated() {
            print("[\(i)] \(msg.isUser ? "User" : "AI"): \(msg.content.prefix(50))...")
        }
        print("Context count: \(contexts.count)")
        print("Contexts:")
        for (i, ctx) in contexts.enumerated() {
            print("[\(i)] \(ctx.isUser ? "User" : "AI"): \(ctx.content.prefix(50))...")
        }

        // Clear state at start
        responses.removeAll()
        responsesContinuation?.yield(responses)

        isProcessing = true
        processingContinuation?.yield(true)

        defer {
            isProcessing = false
            processingContinuation?.yield(false)
        }

        do {
            // Action phase
            currentPhase = .action
            phaseContinuation?.yield(.action)
            let actionBody = ActionRequestBody(
                content: input,
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            print("Action request body: \(String(describing: actionBody))")
            actionResponse = try await api.post(endpoint: "action", body: actionBody)
            responses[.action] = actionResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Experience phase
            currentPhase = .experience
            phaseContinuation?.yield(.experience)
            let experienceBody = ExperienceRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            experienceResponse = try await api.post(endpoint: "experience", body: experienceBody)
            responses[.experience] = experienceResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Intention phase
            currentPhase = .intention
            phaseContinuation?.yield(.intention)
            let intentionBody = IntentionRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                priors: experienceResponse?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            intentionResponse = try await api.post(endpoint: "intention", body: intentionBody) as IntentionResponse
            responses[.intention] = intentionResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Observation phase
            currentPhase = .observation
            phaseContinuation?.yield(.observation)
            let observationBody = ObservationRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                intentionResponse: intentionResponse?.content ?? "",
                selectedPriors: intentionResponse?.selectedPriors ?? [],
                priors: experienceResponse?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            observationResponse = try await api.post(endpoint: "observation", body: observationBody)
            responses[.observation] = observationResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Understanding phase
            currentPhase = .understanding
            phaseContinuation?.yield(.understanding)
            let understandingBody = UnderstandingRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                intentionResponse: intentionResponse?.content ?? "",
                observationResponse: observationResponse?.content ?? "",
                patterns: [],
                selectedPriors: intentionResponse?.selectedPriors ?? [],
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            understandingResponse = try await api.post(endpoint: "understanding", body: understandingBody)
            responses[.understanding] = understandingResponse?.content
            responsesContinuation?.yield(responses)

            // Check if we should loop
            if let understanding = understandingResponse,
               understanding.shouldYield ?? true,
               let nextPrompt = understanding.nextPrompt {
                try await process(nextPrompt, thread: thread)
                return
            }

            try Task.checkCancellation()

            // Yield phase
            currentPhase = .yield
            phaseContinuation?.yield(.yield)
            let yieldBody = YieldRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                intentionResponse: intentionResponse?.content ?? "",
                observationResponse: observationResponse?.content ?? "",
                understandingResponse: understandingResponse?.content ?? "",
                selectedPriors: intentionResponse?.selectedPriors ?? [],
                priors: experienceResponse?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            yieldResponse = try await api.post(endpoint: "yield", body: yieldBody)
            responses[.yield] = yieldResponse?.content
            responsesContinuation?.yield(responses)

        } catch let error as URLError {
            print("Network error: \(error.localizedDescription)")
            responses[currentPhase] = "Network error: Could not connect to server"
            responsesContinuation?.yield(responses)
            throw APIError.networkError(error)
        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            responsesContinuation?.yield(responses)
            throw APIError.cancelled
        } catch {
            print("Error during \(currentPhase): \(error.localizedDescription)")
            responses[currentPhase] = "Error: \(error.localizedDescription)"
            responsesContinuation?.yield(responses)
            throw error
        }
    }

    func cancel() {
        isProcessing = false
        processingContinuation?.yield(false)
    }

    deinit {
        phaseContinuation?.finish()
        responsesContinuation?.finish()
        processingContinuation?.finish()
    }
}
