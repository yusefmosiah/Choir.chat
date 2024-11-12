import Foundation
import SwiftUI
import Combine

@MainActor
class MockChorusCoordinator: ChorusCoordinator {
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false

    // Async sequences for state changes
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

    private var mockDelay: TimeInterval = 1.0
    private var cancellationTask: Task<Void, Error>?

    // Response state
    private(set) var actionResponse: ActionResponse?
    private(set) var experienceResponse: ExperienceResponse?
    private(set) var intentionResponse: IntentionResponse?
    private(set) var observationResponse: ObservationResponse?
    private(set) var understandingResponse: UnderstandingResponse?
    private(set) var yieldResponse: YieldResponse?

    func process(_ input: String) async throws {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Action phase
            currentPhase = .action
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()
            actionResponse = ActionResponse(
                step: "action",
                content: "Mock action response for: \(input)",
                confidence: 0.9,
                metadata: ResponseMetadata(
                    reasoning: "Mock reasoning",
                    synthesis: nil,
                    next_action: nil,
                    next_prompt: nil
                )
            )
            responses[.action] = actionResponse?.content

            // Continue with other phases...

        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            throw APIError.cancelled
        }
    }

    func cancel() {
        cancellationTask?.cancel()
        cancellationTask = nil
        isProcessing = false
    }
}
