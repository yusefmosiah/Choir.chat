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
    var currentChoirThread: ChoirThread?

    required init() {
        self.api = ChorusAPIClient()
    }

    func process(_ input: String) async throws {
        try await process(input, thread: currentChoirThread)
    }

    private func process(_ input: String, thread: ChoirThread?) async throws {
        currentChoirThread = thread

        // Get context at the start
        let messages = thread?.messages.dropLast(2) ?? []
        let contexts = messages.map { MessageContext(from: $0) }

        // Add detailed logging
        print("ChoirThread ID: \(thread?.id.uuidString ?? "nil")")
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
            let actionResponse: APIResponse<ActionResponse> = try await api.post(endpoint: "action", body: actionBody)
            self.actionResponse = actionResponse.data
            responses[.action] = actionResponse.data?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Experience phase
            currentPhase = .experience
            phaseContinuation?.yield(.experience)
            let experienceBody = ExperienceRequestBody(
                content: input,
                actionResponse: actionResponse.data?.content ?? "",
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            let experienceResponse: APIResponse<ExperienceResponse> = try await api.post(endpoint: "experience", body: experienceBody)
            self.experienceResponse = experienceResponse.data
            responses[.experience] = experienceResponse.data?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Intention phase
            currentPhase = .intention
            phaseContinuation?.yield(.intention)
            let intentionBody = IntentionRequestBody(
                content: input,
                actionResponse: actionResponse.data?.content ?? "",
                experienceResponse: experienceResponse.data?.content ?? "",
                priors: experienceResponse.data?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts  // Pass full message history
            )
            let intentionResponse: APIResponse<IntentionResponse> = try await api.post(endpoint: "intention", body: intentionBody)
            self.intentionResponse = intentionResponse.data
            responses[.intention] = intentionResponse.data?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Observation phase
            currentPhase = .observation
            phaseContinuation?.yield(.observation)
            let observationBody = ObservationRequestBody(
                content: input,
                actionResponse: actionResponse.data?.content ?? "",
                experienceResponse: experienceResponse.data?.content ?? "",
                intentionResponse: intentionResponse.data?.content ?? "",
                selectedPriors: intentionResponse.data?.selectedPriors ?? [],
                priors: experienceResponse.data?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            let observationResponse: APIResponse<ObservationResponse> = try await api.post(endpoint: "observation", body: observationBody)
            self.observationResponse = observationResponse.data
            responses[.observation] = observationResponse.data?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Understanding phase
            currentPhase = .understanding
            phaseContinuation?.yield(.understanding)
            let understandingBody = UnderstandingRequestBody(
                content: input,
                actionResponse: actionResponse.data?.content ?? "",
                experienceResponse: experienceResponse.data?.content ?? "",
                intentionResponse: intentionResponse.data?.content ?? "",
                observationResponse: observationResponse.data?.content ?? "",
                patterns: [],
                selectedPriors: intentionResponse.data?.selectedPriors ?? [],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            let understandingResponse: APIResponse<UnderstandingResponse> = try await api.post(endpoint: "understanding", body: understandingBody)
            self.understandingResponse = understandingResponse.data
            responses[.understanding] = understandingResponse.data?.content
            responsesContinuation?.yield(responses)

            // Check if we should loop
            if let understanding = understandingResponse.data,
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
                actionResponse: actionResponse.data?.content ?? "",
                experienceResponse: experienceResponse.data?.content ?? "",
                intentionResponse: intentionResponse.data?.content ?? "",
                observationResponse: observationResponse.data?.content ?? "",
                understandingResponse: understandingResponse.data?.content ?? "",
                selectedPriors: intentionResponse.data?.selectedPriors ?? [],
                priors: experienceResponse.data?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            let yieldResponse: APIResponse<YieldResponse> = try await api.post(endpoint: "yield", body: yieldBody)
            self.yieldResponse = yieldResponse.data
            responses[.yield] = yieldResponse.data?.content
            responsesContinuation?.yield(responses)

        } catch let error as URLError {
            await handleError(APIError.networkError(error), phase: currentPhase)
            throw APIError.networkError(error)
        } catch is CancellationError {
            await handleError(APIError.cancelled, phase: currentPhase)
            throw APIError.cancelled
        } catch {
            await handleError(error, phase: currentPhase)
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

    private func handleError(_ error: Error, phase: Phase) async {
        let errorMessage: String

        switch error {
        case let apiError as APIError:
            errorMessage = apiError.localizedDescription
        case is CancellationError:
            errorMessage = "Cancelled"
        default:
            errorMessage = "Error: \(error.localizedDescription)"
        }

        // Update responses with error
        responses[phase] = errorMessage
        responsesContinuation?.yield(responses)

        // Log error for debugging
        print("Error during \(phase): \(errorMessage)")
    }
}
