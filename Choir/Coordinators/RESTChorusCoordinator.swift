import SwiftUI

@MainActor
class RESTChorusCoordinator: ChorusCoordinator, ObservableObject {
    private let api: ChorusAPIClient

    // Use @Published to ensure SwiftUI updates
    @Published private(set) var currentPhase: Phase = .action {
        didSet {
            objectWillChange.send()
        }
    }
    @Published private(set) var responses: [Phase: String] = [:] {
        didSet {
            objectWillChange.send()
        }
    }
    @Published private(set) var isProcessing = false {
        didSet {
            objectWillChange.send()
        }
    }

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
            viewModel?.updateState()
        }

        // Get context at the start
        let messages = thread?.messages.dropLast(2) ?? []
        let contexts = messages.map { MessageContext(from: $0) }

        do {
            // Action phase
            currentPhase = .action
            let actionBody = ActionRequestBody(
                content: input,
                threadID: thread?.id.uuidString,
                context: contexts
            )
            actionResponse = try await api.post(endpoint: "action", body: actionBody)
            responses[.action] = actionResponse?.content
            viewModel?.updateState()

            try Task.checkCancellation()

            // Experience phase
            currentPhase = .experience
            let experienceBody = ExperienceRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                threadID: thread?.id.uuidString,
                context: contexts
            )
            experienceResponse = try await api.post(endpoint: "experience", body: experienceBody)
            responses[.experience] = experienceResponse?.content
            viewModel?.updateState()

            try Task.checkCancellation()

            // Intention phase
            currentPhase = .intention
            let intentionBody = IntentionRequestBody(
                content: input,
                actionResponse: actionResponse?.content ?? "",
                experienceResponse: experienceResponse?.content ?? "",
                priors: experienceResponse?.priors ?? [:],
                threadID: thread?.id.uuidString,
                context: contexts
            )
            intentionResponse = try await api.post(endpoint: "intention", body: intentionBody) as IntentionResponse
            responses[.intention] = intentionResponse?.content
            viewModel?.updateState()

            try Task.checkCancellation()

            // Observation phase
            currentPhase = .observation
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
            responses[.observation] = observationResponse?.content
            viewModel?.updateState()

            try Task.checkCancellation()

            // Understanding phase
            currentPhase = .understanding
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
            responses[.understanding] = understandingResponse?.content
            viewModel?.updateState()

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
            responses[.yield] = yieldResponse?.content
            viewModel?.updateState()

        } catch let error as URLError {
            print("Network error: \(error.localizedDescription)")
            responses[currentPhase] = "Network error: Could not connect to server"
            throw APIError.networkError(error)
        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            throw APIError.cancelled
        } catch {
            print("Error during \(currentPhase): \(error.localizedDescription)")
            responses[currentPhase] = "Error: \(error.localizedDescription)"
            throw error
        }
    }

    func cancel() {
        isProcessing = false
    }
}
