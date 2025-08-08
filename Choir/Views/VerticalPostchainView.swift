import SwiftUI

/// Enum representing the grouped pages in the vertical layout
enum PhasePage: String, CaseIterable, Identifiable {
    case action
    case experience
    case iou
    case yield

    var id: String { rawValue }

    var title: String {
        switch self {
        case .action: return "Initial Response"
        case .experience: return "Research & Analysis"
        case .iou: return "Understanding"
        case .yield: return "Final Response"
        }
    }

    var symbol: String {
        switch self {
        case .action: return "bolt.fill"
        case .experience: return "magnifyingglass"
        case .iou: return "lightbulb.fill"
        case .yield: return "arrow.down.circle.fill"
        }
    }

    /// Maps individual phases to their corresponding page
    static func pageFor(phase: Phase) -> PhasePage? {
        switch phase {
        case .action:
            return .action
        case .experienceVectors, .experienceWeb:
            return .experience
        case .intention, .observation, .understanding:
            return .iou
        case .yield:
            return .yield
        }
    }

    /// Returns the phases that contribute to this page
    var contributingPhases: [Phase] {
        switch self {
        case .action:
            return [.action]
        case .experience:
            return [.experienceVectors, .experienceWeb]
        case .iou:
            return [.intention, .observation, .understanding]
        case .yield:
            return [.yield]
        }
    }
}

/// Vertical replacement for PostchainView using book-style page navigation
struct VerticalPostchainView: View {
    @ObservedObject var message: Message
    let isProcessing: Bool
    @ObservedObject var viewModel: PostchainViewModel
    let localThreadIDs: Set<UUID>
    let forceShowAllPhases: Bool
    let coordinator: PostchainCoordinatorImpl?
    let viewId: String

    // State for page navigation
    @State private var currentPageIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    // Computed property for available pages
    private var availablePages: [PhasePage] {
        PhasePage.allCases.filter { page in
            hasContent(for: page) || isStreaming(for: page)
        }
    }

    // Current page binding for external control
    private var currentPage: PhasePage? {
        guard currentPageIndex < availablePages.count else { return nil }
        return availablePages[currentPageIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Page content area
                ZStack {
                    ForEach(availablePages.indices, id: \.self) { index in
                        let page = availablePages[index]

                        pageView(for: page)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
                            .offset(x: calculatePageOffset(for: index, containerWidth: geometry.size.width))
                            .opacity(calculatePageOpacity(for: index))
                            .allowsHitTesting(index == currentPageIndex)
                    }
                }
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { (dragValue: DragGesture.Value) in
                            if !isAnimating {
                                dragOffset = dragValue.translation.width
                            }
                        }
                        .onEnded { (dragValue: DragGesture.Value) in
                            handleSwipeGesture(translation: dragValue.translation.width, containerWidth: geometry.size.width)
                        }
                )

                Spacer()

                // Page indicator
                if availablePages.count > 1 {
                    pageIndicator
                        .frame(height: geometry.size.height * 0.15)
                }
            }
        }
        .onReceive(message.objectWillChange) {
            // Update available pages when message content changes
            updateAvailablePages()
        }
        .onChange(of: message.isStreaming) { _, _ in
            // Update available pages when streaming status changes
            updateAvailablePages()
        }
        .onChange(of: message.phaseResults) { _, _ in
            // Update available pages when phase results change
            updateAvailablePages()
        }
        .onAppear {
            // Initialize to first available page
            if currentPageIndex >= availablePages.count {
                currentPageIndex = 0
            }
        }
    }

    // MARK: - Page Views

    @ViewBuilder
    private func pageView(for page: PhasePage) -> some View {
        switch page {
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

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 12) {
            ForEach(availablePages.indices, id: \.self) { index in
                let page = availablePages[index]

                Button(action: {
                    navigateToPage(index)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: page.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(index == currentPageIndex ? .accentColor : .secondary)

                        Text(page.title)
                            .font(.caption2)
                            .foregroundColor(index == currentPageIndex ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .frame(minWidth: 60)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(index == currentPageIndex ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func hasContent(for page: PhasePage) -> Bool {
        return page.contributingPhases.contains { phase in
            let content = message.getPhaseContent(phase)
            return !content.isEmpty
        }
    }

    private func isStreaming(for page: PhasePage) -> Bool {
        return message.isStreaming && page.contributingPhases.contains { phase in
            // Check if this specific phase is currently being streamed
            return message.phaseResults[phase] != nil
        }
    }

    private func calculatePageOffset(for index: Int, containerWidth: CGFloat) -> CGFloat {
        let baseOffset = CGFloat(index - currentPageIndex) * containerWidth
        return baseOffset + dragOffset
    }

    private func calculatePageOpacity(for index: Int) -> Double {
        let distance = abs(index - currentPageIndex)
        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            return 0.3
        } else {
            return 0.0
        }
    }

    private func handleSwipeGesture(translation: CGFloat, containerWidth: CGFloat) {
        let threshold = containerWidth * 0.25

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isAnimating = true

            if translation > threshold && currentPageIndex > 0 {
                // Swipe right - go to previous page
                currentPageIndex -= 1
            } else if translation < -threshold && currentPageIndex < availablePages.count - 1 {
                // Swipe left - go to next page
                currentPageIndex += 1
            }

            dragOffset = 0
        }

        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }

    private func navigateToPage(_ index: Int) {
        guard index != currentPageIndex && index >= 0 && index < availablePages.count else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentPageIndex = index
        }
    }

    private func updateAvailablePages() {
        // Ensure current page index is still valid after content changes
        let newAvailablePages = PhasePage.allCases.filter { page in
            hasContent(for: page) || isStreaming(for: page)
        }

        if currentPageIndex >= newAvailablePages.count {
            currentPageIndex = max(0, newAvailablePages.count - 1)
        }
    }
}

#Preview {
    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())
    let previewMessage = Message(content: "Test message", isUser: false)

    VerticalPostchainView(
        message: previewMessage,
        isProcessing: false,
        viewModel: previewViewModel,
        localThreadIDs: [],
        forceShowAllPhases: true,
        coordinator: nil,
        viewId: "preview"
    )
}

