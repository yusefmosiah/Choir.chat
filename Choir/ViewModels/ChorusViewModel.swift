import SwiftUI

@MainActor
class ChorusViewModel: ObservableObject {
    // Published state
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false
    @Published private(set) var error: Error?

    // Coordinator handles the actual processing
    let coordinator: any ChorusCoordinator
    private var bindingTasks: Set<Task<Void, Never>> = []

    init(coordinator: any ChorusCoordinator) {
        self.coordinator = coordinator
        setupBindings()
    }

    private func setupBindings() {
        let phaseTask = Task {
            for await phase in coordinator.currentPhaseSequence {
                self.currentPhase = phase
            }
        }

        let responsesTask = Task {
            for await responses in coordinator.responsesSequence {
                if self.isProcessing {
                    self.responses = responses
                }
            }
        }

        let processingTask = Task {
            for await isProcessing in coordinator.isProcessingSequence {
                self.isProcessing = isProcessing
                if !isProcessing {
                    self.responses.removeAll()
                }
            }
        }

        bindingTasks = [phaseTask, responsesTask, processingTask]
    }

    deinit {
        bindingTasks.forEach { $0.cancel() }
    }

    func process(_ input: String) async throws {
        // Clear previous state
        responses.removeAll()
        error = nil

        do {
            try await coordinator.process(input)
        } catch {
            self.error = error
            throw error
        }
    }

    func cancel() {
        coordinator.cancel()
    }

    // Convenience accessors for responses
    var actionResponse: ActionResponse? { coordinator.actionResponse }
    var experienceResponse: ExperienceResponse? { coordinator.experienceResponse }
    var intentionResponse: IntentionResponse? { coordinator.intentionResponse }
    var observationResponse: ObservationResponse? { coordinator.observationResponse }
    var understandingResponse: UnderstandingResponse? { coordinator.understandingResponse }
    var yieldResponse: YieldResponse? { coordinator.yieldResponse }
}
