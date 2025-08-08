import SwiftUI

/// Controller for handling vertical page navigation with gestures and animations
struct PageNavigationController<Content: View>: View {
    let pages: [AnyView]
    @Binding var currentPageIndex: Int
    let content: (Int, AnyView) -> Content

    // Navigation state
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    // Configuration
    var swipeThreshold: CGFloat = 50
    var elasticLimit: CGFloat = 100
    var animationDuration: Double = 0.3
    var enableHapticFeedback: Bool = true

    init(
        pages: [AnyView],
        currentPageIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Int, AnyView) -> Content
    ) {
        self.pages = pages
        self._currentPageIndex = currentPageIndex
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pages.indices, id: \.self) { index in
                    let page = pages[index]

                    content(index, page)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: calculatePageOffset(for: index, containerHeight: geometry.size.height))
                        .opacity(calculatePageOpacity(for: index))
                        .allowsHitTesting(index == currentPageIndex)
                        .clipped()
                }
            }
            .clipped()
            // Remove simultaneousGesture - let PageAwareScrollView handle page navigation
            // This prevents gesture conflicts with content scrolling
        }
        .onChange(of: currentPageIndex) { _, newIndex in
            // Ensure the index is within bounds
            if newIndex < 0 {
                currentPageIndex = 0
            } else if newIndex >= pages.count {
                currentPageIndex = max(0, pages.count - 1)
            }
        }
    }

    // MARK: - Page Navigation

    /// Handle page navigation request from PageAwareScrollView
    func handlePageNavigationRequest(_ direction: PageAwareScrollView<AnyView>.PageNavigationDirection) {
        guard !isAnimating else { return }

        withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) {
            isAnimating = true

            switch direction {
            case .previous:
                if currentPageIndex > 0 {
                    currentPageIndex -= 1
                    triggerHapticFeedback()
                }
            case .next:
                if currentPageIndex < pages.count - 1 {
                    currentPageIndex += 1
                    triggerHapticFeedback()
                }
            }

            // Reset drag offset
            dragOffset = 0
        }

        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isAnimating = false
        }
    }

    // MARK: - Layout Calculations

    private func calculatePageOffset(for index: Int, containerHeight: CGFloat) -> CGFloat {
        let pageSpacing: CGFloat = 20 // Add spacing between pages
        let baseOffset = CGFloat(index - currentPageIndex) * (containerHeight + pageSpacing)
        return baseOffset + dragOffset
    }

    private func calculatePageOpacity(for index: Int) -> Double {
        let distance = abs(index - currentPageIndex)

        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            // Show adjacent pages with reduced opacity
            return 0.1
        } else {
            return 0.0
        }
    }

    // MARK: - Helper Methods

    private func triggerHapticFeedback() {
        guard enableHapticFeedback else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - Public Methods

    /// Navigate to a specific page with animation
    func navigateToPage(_ index: Int) {
        guard index != currentPageIndex && index >= 0 && index < pages.count else { return }

        withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) {
            currentPageIndex = index
        }

        triggerHapticFeedback()
    }
}

// MARK: - Configuration Modifiers

extension PageNavigationController {
    /// Set the swipe threshold for page changes
    func swipeThreshold(_ threshold: CGFloat) -> PageNavigationController {
        var controller = self
        controller.swipeThreshold = threshold
        return controller
    }

    /// Set the elastic limit for boundary scrolling
    func elasticLimit(_ limit: CGFloat) -> PageNavigationController {
        var controller = self
        controller.elasticLimit = limit
        return controller
    }

    /// Set the animation duration
    func animationDuration(_ duration: Double) -> PageNavigationController {
        var controller = self
        controller.animationDuration = duration
        return controller
    }

    /// Enable or disable haptic feedback
    func hapticFeedback(_ enabled: Bool) -> PageNavigationController {
        var controller = self
        controller.enableHapticFeedback = enabled
        return controller
    }
}

// MARK: - Convenience Initializers

extension PageNavigationController where Content == AnyView {
    /// Convenience initializer for simple page display
    init(
        pages: [AnyView],
        currentPageIndex: Binding<Int>
    ) {
        self.init(pages: pages, currentPageIndex: currentPageIndex) { _, page in
            page
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var currentPage = 0

    let samplePages = [
        AnyView(
            VStack {
                Text("Page 1")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.1))
        ),
        AnyView(
            VStack {
                Text("Page 2")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green.opacity(0.1))
        ),
        AnyView(
            VStack {
                Text("Page 3")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.orange.opacity(0.1))
        )
    ]

    return PageNavigationController(
        pages: samplePages,
        currentPageIndex: $currentPage
    )
}
