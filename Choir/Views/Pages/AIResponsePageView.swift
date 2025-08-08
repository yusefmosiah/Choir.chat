import SwiftUI

/// Full-screen page view for AI responses with horizontal phase navigation
struct AIResponsePageView: View {
    @ObservedObject var message: Message
    @ObservedObject var viewModel: PostchainViewModel

    // Phase navigation state
    @State private var currentPhaseIndex: Int = 0
    @State private var availablePhases: [PhasePage] = []

    var body: some View {
        VStack(spacing: 0) {
            // Main content area with horizontal phase navigation
            if !availablePhases.isEmpty {
                TabView(selection: $currentPhaseIndex) {
                    ForEach(availablePhases.indices, id: \.self) { index in
                        let phase = availablePhases[index]

                        phaseContentView(for: phase)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Empty state when no phases are available
                emptyStateView
            }

            // Phase indicators removed - no tab bars wanted
        }
        .onAppear {
            updateAvailablePhases()
            // Start with the first available phase
            currentPhaseIndex = 0
        }
        .onChange(of: message.phaseResults) { _, _ in
            updateAvailablePhases()
        }
        .onChange(of: viewModel.isProcessing) { _, _ in
            updateAvailablePhases()
        }
    }

    // MARK: - Phase Content Views

    @ViewBuilder
    private func phaseContentView(for phase: PhasePage) -> some View {
        switch phase {
        case .action:
            ActionPageView(message: message, viewModel: viewModel)
        case .experience:
            ExperiencePageView(message: message, viewModel: viewModel)
        case .iou:
            IOUPageView(message: message, viewModel: viewModel)
        case .yield:
            YieldPageView(message: message, viewModel: viewModel)
        }
    }

    // MARK: - Phase Indicators (removed - no tab bars wanted)

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("AI Response")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Waiting for AI response...")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Methods

    private func updateAvailablePhases() {
        var phases: [PhasePage] = []

        // Check each phase for content or streaming status
        if hasContent(for: .action) || isStreaming(for: .action) {
            phases.append(.action)
        }

        if hasExperienceContent() || isStreamingExperience() {
            phases.append(.experience)
        }

        if hasIOUContent() || isStreamingIOU() {
            phases.append(.iou)
        }

        if hasContent(for: .yield) || isStreaming(for: .yield) {
            phases.append(.yield)
        }

        availablePhases = phases

        // Ensure current index is valid
        if currentPhaseIndex >= availablePhases.count {
            currentPhaseIndex = max(0, availablePhases.count - 1)
        }
    }

    private func hasContent(for phase: Phase) -> Bool {
        return !message.getPhaseContent(phase).isEmpty
    }

    private func isStreaming(for phase: Phase) -> Bool {
        return message.isStreaming && viewModel.processingStatus.contains(phase.rawValue)
    }

    private func hasExperienceContent() -> Bool {
        return !message.getPhaseContent(.experienceVectors).isEmpty ||
               !message.getPhaseContent(.experienceWeb).isEmpty
    }

    private func isStreamingExperience() -> Bool {
        return message.isStreaming && (
            viewModel.processingStatus.contains(Phase.experienceVectors.rawValue) ||
            viewModel.processingStatus.contains(Phase.experienceWeb.rawValue)
        )
    }

    private func hasIOUContent() -> Bool {
        return !message.getPhaseContent(.intention).isEmpty ||
               !message.getPhaseContent(.observation).isEmpty ||
               !message.getPhaseContent(.understanding).isEmpty
    }

    private func isStreamingIOU() -> Bool {
        return message.isStreaming && (
            viewModel.processingStatus.contains(Phase.intention.rawValue) ||
            viewModel.processingStatus.contains(Phase.observation.rawValue) ||
            viewModel.processingStatus.contains(Phase.understanding.rawValue)
        )
    }
}

#Preview {
    let previewMessage = Message(content: "Test message", isUser: false)
    previewMessage.phaseResults[.action] = PhaseResult(
        content: "This is a sample action response.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )

    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return AIResponsePageView(message: previewMessage, viewModel: previewViewModel)
}
