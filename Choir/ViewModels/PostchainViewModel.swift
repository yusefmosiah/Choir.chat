import SwiftUI

@MainActor
class PostchainViewModel: ObservableObject {
    @Published private(set) var currentPhase: Phase
    @Published private(set) var responses: [Phase: String]
    @Published private(set) var isProcessing: Bool
    @Published private(set) var error: Error?

    let coordinator: any PostchainCoordinator

    init(coordinator: any PostchainCoordinator) {
        self.coordinator = coordinator
        self.currentPhase = coordinator.currentPhase
        self.responses = coordinator.responses
        self.isProcessing = coordinator.isProcessing

        if let restCoordinator = coordinator as? RESTPostchainCoordinator {
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
        // Get the latest state from the coordinator
        let newResponses = coordinator.responses
        let newIsProcessing = coordinator.isProcessing

        // DEBUG: Check for experience content
        if let experienceContent = newResponses[.experience], !experienceContent.isEmpty {
            print("✅ updateState: Found experience content with length: \(experienceContent.count)")
        }

        // Update state properties - SwiftUI will automatically react to these changes
        // because they are @Published properties in an ObservableObject
        // Do NOT update the currentPhase to allow users to stay on their selected card
        responses = newResponses
        isProcessing = newIsProcessing
    }

    func cancel() {
        coordinator.cancel()
        isProcessing = false
        responses = [:]
    }

    // Called by the coordinator to update the view model with new phase content
    func updatePhase(_ phase: Phase, state: String, content: String) {
        // Add explicit main thread execution
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Update with animation to force UI refresh
            withAnimation {
                self.responses[phase] = content
                self.objectWillChange.send()
            }
        }
    }

    // Helper method to update message with final response
    func updateMessage(_ message: Message) -> Message {
        var updatedMessage = message

        // Create a combined phases dictionary that merges existing phases with viewModel responses
        var combinedPhases = message.phases

        // Add all phases from responses, overwriting any existing content
        for (phase, content) in responses {
            if !content.isEmpty {
                combinedPhases[phase] = content
            }
        }

        // Update the message content for display
        if let experienceContent = combinedPhases[.experience], !experienceContent.isEmpty {
            // Experience is the final phase, so show its content
            updatedMessage.content = experienceContent
        } else if let actionContent = combinedPhases[.action], !actionContent.isEmpty {
            // Action phase is present
            updatedMessage.content = actionContent
        }

        // Update the phases property
        updatedMessage.phases = combinedPhases
        updatedMessage.isStreaming = false

        return updatedMessage
    }
}
