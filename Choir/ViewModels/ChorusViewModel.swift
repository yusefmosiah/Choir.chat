import SwiftUI

@MainActor
class ChorusViewModel: ObservableObject {
    @Published private(set) var currentPhase: Phase
    @Published private(set) var responses: [Phase: String]
    @Published private(set) var isProcessing: Bool
    @Published private(set) var error: Error?

    // Track the latest phase that has been processed
    @Published private(set) var latestProcessedPhase: Phase?

    let coordinator: any ChorusCoordinator

    init(coordinator: any ChorusCoordinator) {
        self.coordinator = coordinator
        self.currentPhase = coordinator.currentPhase
        self.responses = coordinator.responses
        self.isProcessing = coordinator.isProcessing
        self.latestProcessedPhase = nil

        if let restCoordinator = coordinator as? RESTChorusCoordinator {
            restCoordinator.viewModel = self
        }
    }

    func process(_ input: String) async throws {
        error = nil

        // Clear state before starting new process
        currentPhase = .action
        responses = [:]
        isProcessing = true
        latestProcessedPhase = nil

        do {
            try await coordinator.process(input)
        } catch {
            self.error = error
            isProcessing = false
            throw error
        }
    }

    // Update state from coordinator
    func updateState() {
        withAnimation {
            currentPhase = coordinator.currentPhase

            // Create a new responses dictionary to trigger UI updates
            var newResponses = [Phase: String]()

            // Add responses in phase order to ensure proper UI updates
            for phase in Phase.allCases {
                if let response = coordinator.responses[phase] {
                    newResponses[phase] = response
                    latestProcessedPhase = phase
                }
            }

            self.responses = newResponses
            isProcessing = coordinator.isProcessing
        }
    }

    func cancel() {
        coordinator.cancel()
        isProcessing = false
        responses = [:]
        latestProcessedPhase = nil
    }

    // Helper method to update message with final response
    func updateMessage(_ message: Message) -> Message {
        var updatedMessage = message
        if let yieldResponse = coordinator.yieldResponse {
            // Store the yield content as the message content for compatibility
            updatedMessage.content = yieldResponse.content

            // Store all phase responses in the chorus result
            updatedMessage.chorusResult = MessageChorusResult(phases: responses)
        }
        return updatedMessage
    }

    // Helper to get the next phase that should be processed
    var nextPhaseToProcess: Phase? {
        if let latest = latestProcessedPhase {
            let allPhases = Phase.allCases
            if let currentIndex = allPhases.firstIndex(of: latest),
               currentIndex + 1 < allPhases.count {
                return allPhases[currentIndex + 1]
            }
            return nil
        } else {
            return .action
        }
    }
}
