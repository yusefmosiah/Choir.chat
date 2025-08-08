import SwiftUI

/// Container for one complete conversation turn with 5 vertical pages
/// Handles vertical navigation within the turn: User → Action → Experience → IOU → Yield
struct TurnContainerView: View {
    let userMessage: Message
    let aiMessage: Message
    @ObservedObject var viewModel: PostchainViewModel

    // Page navigation state
    @State private var currentPageIndex: Int = 0
    @State private var turnPages: [TurnPage] = []

    // Auto-advance manager
    @StateObject private var autoAdvanceManager = TurnAutoAdvanceManager()

    var body: some View {
        VStack(spacing: 0) {
            if !turnPages.isEmpty {
                PageNavigationController(
                    pages: turnPages.map { $0.view },
                    currentPageIndex: $currentPageIndex
                ) { index, pageView in
                    pageView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .swipeThreshold(60)
                .elasticLimit(80)
                .animationDuration(0.35)
                .hapticFeedback(true)
            } else {
                // Loading state
                loadingStateView
            }
        }
        .onAppear {
            setupTurnPages()
            autoAdvanceManager.currentPageIndex = currentPageIndex
            autoAdvanceManager.startMonitoring(for: aiMessage, viewModel: viewModel)
        }
        .onDisappear {
            autoAdvanceManager.stopMonitoring()
        }
        .onChange(of: autoAdvanceManager.currentPageIndex) { _, newIndex in
            currentPageIndex = newIndex
        }
        .onChange(of: currentPageIndex) { _, newIndex in
            if newIndex != autoAdvanceManager.currentPageIndex {
                autoAdvanceManager.markManualNavigation()
                autoAdvanceManager.currentPageIndex = newIndex
            }
        }
        .onChange(of: aiMessage.phaseResults) { _, _ in
            updateTurnPages()
        }
        .onChange(of: viewModel.isProcessing) { _, _ in
            updateTurnPages()
        }
    }

    // MARK: - Loading State

    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Preparing conversation turn...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Turn Page Management

    private func setupTurnPages() {
        var pages: [TurnPage] = []

        // Create page navigation handler
        let pageNavigationHandler: (PageAwareScrollView<AnyView>.PageNavigationDirection) -> Void = { direction in
            switch direction {
            case .previous:
                if currentPageIndex > 0 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentPageIndex -= 1
                    }
                    // Mark manual navigation to disable auto-advance temporarily
                    autoAdvanceManager.markManualNavigation()
                }
            case .next:
                if currentPageIndex < turnPages.count - 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentPageIndex += 1
                    }
                    // Mark manual navigation to disable auto-advance temporarily
                    autoAdvanceManager.markManualNavigation()
                }
            }
        }

        // Page 1: User Message
        pages.append(TurnPage(
            id: "user_\(userMessage.id)",
            type: .userMessage,
            view: AnyView(UserMessagePageView(
                message: userMessage,
                onPageNavigationRequest: pageNavigationHandler
            ))
        ))

        // Page 2: Action (always create during streaming, or if has content)
        if aiMessage.isStreaming || hasContent(for: .action) {
            pages.append(TurnPage(
                id: "action_\(aiMessage.id)",
                type: .action,
                view: AnyView(ActionPageView(
                    message: aiMessage,
                    viewModel: viewModel,
                    onPageNavigationRequest: pageNavigationHandler
                ))
            ))
        }

        // Page 3: Experience (always create during streaming, or if has content)
        if aiMessage.isStreaming || hasExperienceContent() {
            pages.append(TurnPage(
                id: "experience_\(aiMessage.id)",
                type: .experience,
                view: AnyView(ExperiencePageView(
                    message: aiMessage,
                    viewModel: viewModel,
                    onPageNavigationRequest: pageNavigationHandler
                ))
            ))
        }

        // Page 4: IOU (always create during streaming, or if has content)
        if aiMessage.isStreaming || hasIOUContent() {
            pages.append(TurnPage(
                id: "iou_\(aiMessage.id)",
                type: .iou,
                view: AnyView(IOUPageView(
                    message: aiMessage,
                    viewModel: viewModel,
                    onPageNavigationRequest: pageNavigationHandler
                ))
            ))
        }

        // Page 5: Yield (always create during streaming, or if has content)
        if aiMessage.isStreaming || hasContent(for: .yield) {
            pages.append(TurnPage(
                id: "yield_\(aiMessage.id)",
                type: .yield,
                view: AnyView(YieldPageView(
                    message: aiMessage,
                    viewModel: viewModel,
                    onPageNavigationRequest: pageNavigationHandler
                ))
            ))
        }

        turnPages = pages
    }

    private func updateTurnPages() {
        setupTurnPages()
    }

    // MARK: - Auto-Advance Logic (handled by TurnAutoAdvanceManager)

    // MARK: - Content Checking Helpers

    private func hasContent(for phase: Phase) -> Bool {
        return !aiMessage.getPhaseContent(phase).isEmpty
    }

    private func isStreaming(for phase: Phase) -> Bool {
        return aiMessage.isStreaming && viewModel.processingPhases.contains(phase)
    }

    private func hasExperienceContent() -> Bool {
        return !aiMessage.getPhaseContent(.experienceVectors).isEmpty ||
               !aiMessage.getPhaseContent(.experienceWeb).isEmpty
    }

    private func isStreamingExperience() -> Bool {
        return aiMessage.isStreaming && (
            viewModel.processingPhases.contains(.experienceVectors) ||
            viewModel.processingPhases.contains(.experienceWeb)
        )
    }

    private func hasIOUContent() -> Bool {
        return !aiMessage.getPhaseContent(.intention).isEmpty ||
               !aiMessage.getPhaseContent(.observation).isEmpty ||
               !aiMessage.getPhaseContent(.understanding).isEmpty
    }

    private func isStreamingIOU() -> Bool {
        return aiMessage.isStreaming && (
            viewModel.processingPhases.contains(.intention) ||
            viewModel.processingPhases.contains(.observation) ||
            viewModel.processingPhases.contains(.understanding)
        )
    }
}

// MARK: - Supporting Types

struct TurnPage: Identifiable {
    let id: String
    let type: TurnPageType
    let view: AnyView
}

enum TurnPageType {
    case userMessage
    case action
    case experience
    case iou
    case yield
}

// MARK: - Public Interface

extension TurnContainerView {
    /// Navigate to a specific page within the turn
    func navigateToPage(_ pageType: TurnPageType) {
        if let index = turnPages.firstIndex(where: { $0.type == pageType }) {
            autoAdvanceManager.markManualNavigation()
            withAnimation(.easeInOut(duration: 0.35)) {
                currentPageIndex = index
            }
        }
    }

    /// Reset auto-advance behavior (useful when user manually navigates)
    func resetAutoAdvance() {
        autoAdvanceManager.resetAutoAdvance()
    }
}

// MARK: - Preview

#Preview {
    let userMessage = Message(content: "What is the meaning of life?", isUser: true)
    let aiMessage = Message(content: "", isUser: false)

    // Add some sample phase results
    aiMessage.phaseResults[.action] = PhaseResult(
        content: "I'll help you explore this profound question.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )

    aiMessage.phaseResults[.yield] = PhaseResult(
        content: "The meaning of life is a deeply personal question that has been pondered by philosophers, theologians, and thinkers throughout history.",
        provider: "OpenAI",
        modelName: "gpt-4"
    )

    let viewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return TurnContainerView(
        userMessage: userMessage,
        aiMessage: aiMessage,
        viewModel: viewModel
    )
}
