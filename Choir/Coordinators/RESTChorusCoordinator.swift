import SwiftUI

@MainActor
class RESTChorusCoordinator: ChorusCoordinator, ObservableObject {
    private let api: ChorusAPIClient

    // Use @Published to ensure SwiftUI updates
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false

    // Track phase processing status
    @Published private(set) var processingPhases: Set<Phase> = []

    // Response state
    private(set) var actionResponse: ActionResponse?
    private(set) var experienceResponse: ExperienceResponse?
    private(set) var intentionResponse: IntentionResponse?
    private(set) var observationResponse: ObservationResponse?
    private(set) var understandingResponse: UnderstandingResponse?
    private(set) var yieldResponse: YieldResponse?

    // Add context handling
    var currentChoirThread: ChoirThread?

    weak var viewModel: ChorusViewModel?

    required init() {
        self.api = ChorusAPIClient()
    }

    func process(_ input: String) async throws {
        try await process(input, thread: currentChoirThread)
    }

    private func process(_ input: String, thread: ChoirThread?) async throws {
        currentChoirThread = thread

        // Reset all state
        responses = [:]
        isProcessing = true
        currentPhase = .action
        processingPhases = []

        // Reset all responses
        actionResponse = nil
        experienceResponse = nil
        intentionResponse = nil
        observationResponse = nil
        understandingResponse = nil
        yieldResponse = nil

        // Notify view model of initial state
        viewModel?.updateState()

        defer {
            isProcessing = false
            processingPhases = []
            viewModel?.updateState()
        }

        // Get context at the start
        let messages = thread?.messages.dropLast(2) ?? []
        let contexts = messages.map { MessageContext(from: $0) }

        do {
            // Action phase
            await startProcessingPhase(.action)
            let actionBody = ActionRequestBody(
                content: input,
                threadID: thread?.id.uuidString,
                context: contexts
            )
            actionResponse = try await api.post(endpoint: "action", body: actionBody)
            await completePhase(.action, content: actionResponse?.content)

            try Task.checkCancellation()

            // Experience phase
            await startProcessingPhase(.experience)
            let experienceBody = ExperienceRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                threadID: thread?.id.uuidString,
                context: contexts
            )
            experienceResponse = try await api.post(endpoint: "experience", body: experienceBody)
            await completePhase(.experience, content: experienceResponse?.content)

            try Task.checkCancellation()

            // Intention phase
            await startProcessingPhase(.intention)
            let intentionBody = IntentionRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                priors: experienceResponse?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            intentionResponse = try await api.post(endpoint: "intention", body: intentionBody) as IntentionResponse
            await completePhase(.intention, content: intentionResponse?.content)

            try Task.checkCancellation()

            // Observation phase
            await startProcessingPhase(.observation)
            let observationBody = ObservationRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                intentionResponse: intentionResponse?.content ?? "",
                selectedPriors: intentionResponse?.selectedPriors ?? [],
                priors: experienceResponse?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            observationResponse = try await api.post(endpoint: "observation", body: observationBody)
            await completePhase(.observation, content: observationResponse?.content)

            try Task.checkCancellation()

            // Understanding phase
            await startProcessingPhase(.understanding)
            let understandingBody = UnderstandingRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                intentionResponse: intentionResponse?.content ?? "",
                observationResponse: observationResponse?.content ?? "",
                patterns: [],
                selectedPriors: intentionResponse?.selectedPriors ?? [],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            understandingResponse = try await api.post(endpoint: "understanding", body: understandingBody)
            await completePhase(.understanding, content: understandingResponse?.content)

            // Check if we should loop
            if let understanding = understandingResponse,
               understanding.shouldYield ?? true,
               let nextPrompt = understanding.nextPrompt {
                try await process(nextPrompt, thread: thread)
                return
            }

            try Task.checkCancellation()

            // Yield phase
            await startProcessingPhase(.yield)
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
                context: contexts
            )
            yieldResponse = try await api.post(endpoint: "yield", body: yieldBody)
            await completePhase(.yield, content: yieldResponse?.content)

        } catch let error as URLError {
            print("Network error: \(error.localizedDescription)")
            responses[currentPhase] = "Network error: Could not connect to server"
            processingPhases.remove(currentPhase)
            viewModel?.updateState()
            throw APIError.networkError(error)
        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            processingPhases.remove(currentPhase)
            viewModel?.updateState()
            throw APIError.cancelled
        } catch {
            print("Error during \(currentPhase): \(error.localizedDescription)")
            responses[currentPhase] = "Error: \(error.localizedDescription)"
            processingPhases.remove(currentPhase)
            viewModel?.updateState()
            throw error
        }
    }

    private func startProcessingPhase(_ phase: Phase) async {
        currentPhase = phase
        processingPhases.insert(phase)
        viewModel?.updateState()

        // Add a small delay to allow UI to update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    private func completePhase(_ phase: Phase, content: String?) async {
        if let content = content {
            responses[phase] = content
        }
        processingPhases.remove(phase)
        viewModel?.updateState()

        // Add a small delay to allow UI to update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    func cancel() {
        isProcessing = false
        processingPhases = []
    }

    // Helper to check if a specific phase is currently processing
    func isProcessingPhase(_ phase: Phase) -> Bool {
        return processingPhases.contains(phase)
    }
}
