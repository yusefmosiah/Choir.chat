import Foundation
import Combine

@MainActor
protocol ChorusCoordinator {
    // Published state
    var currentPhase: Phase { get }
    var responses: [Phase: String] { get }
    var isProcessing: Bool { get }

    // Async sequences for state changes
    var currentPhaseSequence: AsyncStream<Phase> { get }
    var responsesSequence: AsyncStream<[Phase: String]> { get }
    var isProcessingSequence: AsyncStream<Bool> { get }

    // Core processing
    func process(_ input: String) async throws
    func cancel()

    // Optional phase-specific responses
    var actionResponse: ActionResponse? { get }
    var experienceResponse: ExperienceResponse? { get }
    var intentionResponse: IntentionResponse? { get }
    var observationResponse: ObservationResponse? { get }
    var understandingResponse: UnderstandingResponse? { get }
    var yieldResponse: YieldResponse? { get }

    // Required initializer
    init()
}
