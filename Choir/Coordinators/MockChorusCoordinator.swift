import Foundation
import SwiftUI
import Combine

@MainActor
class MockChorusCoordinator: ChorusCoordinator, ObservableObject {
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

    private var mockDelay: TimeInterval = 1.0

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

    required init() {}

    func process(_ input: String) async throws {
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
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let metadata = ResponseMetadata(
                reasoning: "Mock reasoning",
                synthesis: nil,
                next_action: nil,
                next_prompt: nil
            )

            actionResponse = ActionResponse(
                step: "action",
                content: "I understand you said: \(input)",
                confidence: 0.9,
                metadata: metadata
            )
            responses[.action] = actionResponse?.content
            responsesContinuation?.yield(responses)

            // Experience phase
            currentPhase = .experience
            phaseContinuation?.yield(.experience)
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            experienceResponse = ExperienceResponse(
                step: "experience",
                content: "Based on my experience...",
                confidence: 0.8,
                priors: [:],
                metadata: metadata
            )
            responses[.experience] = experienceResponse?.content
            responsesContinuation?.yield(responses)

            // Intention phase
            currentPhase = .intention
            phaseContinuation?.yield(.intention)
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            intentionResponse = IntentionResponse(
                step: "intention",
                content: "Your intention seems to be...",
                confidence: 0.85,
                selected_priors: [],
                metadata: metadata
            )
            responses[.intention] = intentionResponse?.content
            responsesContinuation?.yield(responses)

            // Observation phase
            currentPhase = .observation
            phaseContinuation?.yield(.observation)
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            observationResponse = ObservationResponse(
                step: "observation",
                id: UUID().uuidString,
                content: "I observe that...",
                confidence: 0.87,
                patterns: [],
                metadata: metadata
            )
            responses[.observation] = observationResponse?.content
            responsesContinuation?.yield(responses)

            // Understanding phase
            currentPhase = .understanding
            phaseContinuation?.yield(.understanding)
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            understandingResponse = UnderstandingResponse(
                step: "understanding",
                content: "I now understand that...",
                confidence: 0.9,
                should_yield: true,
                metadata: metadata
            )
            responses[.understanding] = understandingResponse?.content
            responsesContinuation?.yield(responses)

            // Yield phase
            currentPhase = .yield
            phaseContinuation?.yield(.yield)
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            yieldResponse = YieldResponse(
                step: "yield",
                content: "Here's my response to: \(input)",
                confidence: 0.95,
                citations: [],
                metadata: metadata
            )
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
