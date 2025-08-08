import SwiftUI

/// A scroll view that coordinates with page navigation
/// Only triggers page navigation when at scroll boundaries
struct PageAwareScrollView<Content: View>: View {
    let content: Content
    let onPageNavigationRequest: (PageNavigationDirection) -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var isAtTop: Bool = true
    @State private var isAtBottom: Bool = false

    enum PageNavigationDirection {
        case previous, next
    }

    init(@ViewBuilder content: () -> Content, onPageNavigationRequest: @escaping (PageNavigationDirection) -> Void) {
        self.content = content()
        self.onPageNavigationRequest = onPageNavigationRequest
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .onAppear {
                                    contentHeight = contentGeometry.size.height
                                    scrollViewHeight = geometry.size.height
                                    updateScrollPosition()
                                }
                                .onChange(of: contentGeometry.size.height) { _, newHeight in
                                    contentHeight = newHeight
                                    updateScrollPosition()
                                }
                        }
                    )
            }
            .coordinateSpace(name: "scroll")
            .background(
                GeometryReader { scrollGeometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
                updateScrollPosition()
            }
            .onChange(of: geometry.size.height) { _, newHeight in
                scrollViewHeight = newHeight
                updateScrollPosition()
            }
            .simultaneousGesture(
                DragGesture()
                    .onEnded { value in
                        handleDragEnded(value)
                    }
            )
        }
    }

    private func updateScrollPosition() {
        // Calculate if we're at top or bottom
        let threshold: CGFloat = 10

        isAtTop = scrollOffset >= -threshold

        // Only consider at bottom if content is actually scrollable
        if contentHeight > scrollViewHeight {
            let maxScrollOffset = -(contentHeight - scrollViewHeight)
            isAtBottom = scrollOffset <= maxScrollOffset + threshold
        } else {
            // If content fits in view, we're always at both top and bottom
            isAtBottom = true
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation.height
        let velocity = value.velocity.height

        // Only trigger page navigation if we're at scroll boundaries
        // and the gesture is significant enough
        let threshold: CGFloat = 80  // Increased threshold to reduce sensitivity
        let velocityThreshold: CGFloat = 800  // Increased velocity threshold

        // More strict conditions for page navigation
        let isSignificantGesture = abs(translation) > threshold && abs(velocity) > velocityThreshold

        if isSignificantGesture {
            if translation > 0 && velocity > 0 && isAtTop {
                // Swipe down at top - go to previous page
                onPageNavigationRequest(.previous)
            } else if translation < 0 && velocity < 0 && isAtBottom {
                // Swipe up at bottom - go to next page
                onPageNavigationRequest(.next)
            }
        }
    }
}

// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    PageAwareScrollView(
        content: {
            VStack(spacing: 20) {
                ForEach(0..<20, id: \.self) { index in
                    Text("Item \(index)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        },
        onPageNavigationRequest: { direction in
            print("Page navigation requested: \(direction)")
        }
    )
}
