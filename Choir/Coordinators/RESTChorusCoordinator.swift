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

    required init() {
        self.api = ChorusAPIClient()
    }

    convenience init(api: ChorusAPIClient) {
        self.init()
    }

    func process(_ input: String) async throws {
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
            let actionBody = ActionRequestBody(content: input)
            let actionResult: APIResponse<ActionResponse> = try await api.post(
                endpoint: "action",
                body: actionBody
            )
            actionResponse = actionResult.data
            responses[.action] = actionResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Experience phase
            currentPhase = .experience
            phaseContinuation?.yield(.experience)
            let experienceBody = ExperienceRequestBody(
                content: input,
                action_response: actionResponse?.content ?? "",
                thread_id: actionResponse?.metadata.next_action
            )
            let experienceResult: APIResponse<ExperienceResponse> = try await api.post(
                endpoint: "experience",
                body: experienceBody
            )
            experienceResponse = experienceResult.data
            responses[.experience] = experienceResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Intention phase
            currentPhase = .intention
            phaseContinuation?.yield(.intention)
            let intentionBody = IntentionRequestBody(
                content: input,
                action_response: actionResponse?.content ?? "",
                experience_response: experienceResponse?.content ?? "",
                priors: experienceResponse?.priors
            )
            let intentionResult: APIResponse<IntentionResponse> = try await api.post(
                endpoint: "intention",
                body: intentionBody
            )
            intentionResponse = intentionResult.data
            responses[.intention] = intentionResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Observation phase
            currentPhase = .observation
            phaseContinuation?.yield(.observation)
            let observationBody = ObservationRequestBody(
                content: input,
                action_response: actionResponse?.content ?? "",
                experience_response: experienceResponse?.content ?? "",
                intention_response: intentionResponse?.content ?? "",
                selected_priors: intentionResponse?.selected_priors ?? [],
                priors: experienceResponse?.priors,
                thread_id: nil
            )
            let observationResult: APIResponse<ObservationResponse> = try await api.post(
                endpoint: "observation",
                body: observationBody
            )
            observationResponse = observationResult.data
            responses[.observation] = observationResponse?.content
            responsesContinuation?.yield(responses)

            try Task.checkCancellation()

            // Understanding phase
            currentPhase = .understanding
            phaseContinuation?.yield(.understanding)
            let understandingBody = UnderstandingRequestBody(
                content: input,
                action_response: actionResponse?.content ?? "",
                experience_response: experienceResponse?.content ?? "",
                intention_response: intentionResponse?.content ?? "",
                observation_response: observationResponse?.content ?? "",
                patterns: observationResponse?.patterns ?? [],
                selected_priors: intentionResponse?.selected_priors ?? [],
                thread_id: nil
            )
            let understandingResult: APIResponse<UnderstandingResponse> = try await api.post(
                endpoint: "understanding",
                body: understandingBody
            )
            understandingResponse = understandingResult.data
            responses[.understanding] = understandingResponse?.content
            responsesContinuation?.yield(responses)

            // Check if we should loop
            if let understanding = understandingResponse,
               !understanding.should_yield,
               let nextPrompt = understanding.metadata.next_prompt {
                try await process(nextPrompt)
                return
            }

            try Task.checkCancellation()

            // Yield phase
            currentPhase = .yield
            phaseContinuation?.yield(.yield)
            let yieldBody = YieldRequestBody(
                content: input,
                action_response: actionResponse?.content ?? "",
                experience_response: experienceResponse?.content ?? "",
                intention_response: intentionResponse?.content ?? "",
                observation_response: observationResponse?.content ?? "",
                understanding_response: understandingResponse?.content ?? "",
                selected_priors: intentionResponse?.selected_priors ?? [],
                priors: experienceResponse?.priors,
                thread_id: nil
            )
            let yieldResult: APIResponse<YieldResponse> = try await api.post(
                endpoint: "yield",
                body: yieldBody
            )
            yieldResponse = yieldResult.data
            responses[.yield] = yieldResponse?.content
            responsesContinuation?.yield(responses)

        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            responsesContinuation?.yield(responses)
            throw APIError.cancelled
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
