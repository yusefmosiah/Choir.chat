import SwiftUI

@MainActor
class RESTChorusCoordinator: ChorusCoordinator {
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

    // Async sequences
    var currentPhaseSequence: AsyncStream<Phase> {
        AsyncStream { continuation in
            // Implementation
        }
    }

    var responsesSequence: AsyncStream<[Phase: String]> {
        AsyncStream { continuation in
            // Implementation
        }
    }

    var isProcessingSequence: AsyncStream<Bool> {
        AsyncStream { continuation in
            // Implementation
        }
    }

    init(api: ChorusAPIClient = ChorusAPIClient()) {
        self.api = api
    }

    func process(_ input: String) async throws {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Action phase
            currentPhase = .action
            let actionResult: APIResponse<ActionResponse> = try await api.post(
                endpoint: "action",
                body: ["content": input]
            )
            actionResponse = actionResult.data
            responses[.action] = actionResponse?.content

            try Task.checkCancellation()

            // Experience phase
            currentPhase = .experience
            let experienceResult: APIResponse<ExperienceResponse> = try await api.post(
                endpoint: "experience",
                body: [
                    "content": input,
                    "action_response": actionResponse?.content ?? "",
                    "thread_id": nil
                ]
            )
            experienceResponse = experienceResult.data
            responses[.experience] = experienceResponse?.content

            try Task.checkCancellation()

            // Intention phase
            currentPhase = .intention
            let intentionResult: APIResponse<IntentionResponse> = try await api.post(
                endpoint: "intention",
                body: [
                    "content": input,
                    "action_response": actionResponse?.content ?? "",
                    "experience_response": experienceResponse?.content ?? "",
                    "priors": experienceResponse?.priors ?? [:],
                    "thread_id": nil
                ]
            )
            intentionResponse = intentionResult.data
            responses[.intention] = intentionResponse?.content

            try Task.checkCancellation()

            // Observation phase
            currentPhase = .observation
            let observationResult: APIResponse<ObservationResponse> = try await api.post(
                endpoint: "observation",
                body: [
                    "content": input,
                    "action_response": actionResponse?.content ?? "",
                    "experience_response": experienceResponse?.content ?? "",
                    "intention_response": intentionResponse?.content ?? "",
                    "selected_priors": intentionResponse?.selected_priors ?? [],
                    "priors": experienceResponse?.priors ?? [:],
                    "thread_id": nil
                ]
            )
            observationResponse = observationResult.data
            responses[.observation] = observationResponse?.content

            try Task.checkCancellation()

            // Understanding phase
            currentPhase = .understanding
            let understandingResult: APIResponse<UnderstandingResponse> = try await api.post(
                endpoint: "understanding",
                body: [
                    "content": input,
                    "action_response": actionResponse?.content ?? "",
                    "experience_response": experienceResponse?.content ?? "",
                    "intention_response": intentionResponse?.content ?? "",
                    "observation_response": observationResponse?.content ?? "",
                    "patterns": observationResponse?.patterns ?? [],
                    "selected_priors": intentionResponse?.selected_priors ?? [],
                    "thread_id": nil
                ]
            )
            understandingResponse = understandingResult.data
            responses[.understanding] = understandingResponse?.content

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
            let yieldResult: APIResponse<YieldResponse> = try await api.post(
                endpoint: "yield",
                body: [
                    "content": input,
                    "action_response": actionResponse?.content ?? "",
                    "experience_response": experienceResponse?.content ?? "",
                    "intention_response": intentionResponse?.content ?? "",
                    "observation_response": observationResponse?.content ?? "",
                    "understanding_response": understandingResponse?.content ?? "",
                    "selected_priors": intentionResponse?.selected_priors ?? [],
                    "priors": experienceResponse?.priors ?? [:],
                    "thread_id": nil
                ]
            )
            yieldResponse = yieldResult.data
            responses[.yield] = yieldResponse?.content

        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            throw APIError.cancelled
        }
    }

    func cancel() {
        isProcessing = false
    }
}
