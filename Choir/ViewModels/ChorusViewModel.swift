import SwiftUI

@MainActor
class ChorusViewModel: ObservableObject {
    @Published private(set) var currentPhase: Phase
    @Published private(set) var responses: [Phase: String]
    @Published private(set) var isProcessing: Bool
    @Published private(set) var error: Error?

    let coordinator: any ChorusCoordinator

    init(coordinator: any ChorusCoordinator) {
        self.coordinator = coordinator
        self.currentPhase = coordinator.currentPhase
        self.responses = coordinator.responses
        self.isProcessing = coordinator.isProcessing

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
            responses = coordinator.responses
            isProcessing = coordinator.isProcessing
        }
    }

    func cancel() {
        coordinator.cancel()
        isProcessing = false
        responses = [:]
    }

    // Helper method to update message with final response
    func updateMessage(_ message: Message) -> Message {
        var updatedMessage = message
        if let yieldResponse = coordinator.yieldResponse {
            updatedMessage.content = yieldResponse.content
            updatedMessage.chorusResult = MessageChorusResult(phases: responses)
        }
        return updatedMessage
    }
}
