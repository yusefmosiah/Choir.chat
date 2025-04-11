import SwiftUI
import Foundation

struct PhaseGestureHandlerView<Content: View>: View {
    // Content to wrap
    private let contentBuilder: (CGFloat) -> Content
    
    // Input properties
    @ObservedObject var message: Message
    let availablePhases: [Phase]
    @ObservedObject var viewModel: PostchainViewModel
    let cardWidth: CGFloat
    
    // Internal state
    @State private var dragOffset: CGFloat = 0
    
    init(content: @escaping (CGFloat) -> Content, message: Message, availablePhases: [Phase], viewModel: PostchainViewModel, cardWidth: CGFloat) {
        self.contentBuilder = content
        self.message = message
        self.availablePhases = availablePhases
        self.viewModel = viewModel
        self.cardWidth = cardWidth
    }
    
    // Convenience initializer for PhaseCardStackView
    init(content: PhaseCardStackView, message: Message, availablePhases: [Phase], viewModel: PostchainViewModel, cardWidth: CGFloat) {
        self.init(
            content: { dragOffset in
                // Create a new PhaseCardStackView with the current dragOffset
                PhaseCardStackView(
                    availablePhases: content.availablePhases,
                    message: content.message,
                    selectedPhase: content.selectedPhase,
                    dragOffset: dragOffset,
                    viewModel: content.viewModel,
                    localThreadIDs: content.localThreadIDs,
                    coordinator: content.coordinator,
                    viewId: content.viewId,
                    cardWidth: content.cardWidth,
                    totalWidth: content.totalWidth
                )
            },
            message: message,
            availablePhases: availablePhases,
            viewModel: viewModel,
            cardWidth: cardWidth
        )
    }
    
    var body: some View {
        contentBuilder(dragOffset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.interactiveSpring()) {
                            handleDragEnd(value: value)
                        }
                    }
            )
    }
    
    // MARK: - Helper Functions
    
    private func handleDragEnd(value: DragGesture.Value) {
        let predictedEndOffset = value.predictedEndTranslation.width
        let threshold = cardWidth / 3
        
        guard let currentIndex = availablePhases.firstIndex(of: message.selectedPhase) else { return }
        
        var targetIndex = currentIndex
        if predictedEndOffset < -threshold { // Swiped left
            targetIndex = min(currentIndex + 1, availablePhases.count - 1)
        } else if predictedEndOffset > threshold { // Swiped right
            targetIndex = max(currentIndex - 1, 0)
        }
        
        if targetIndex != currentIndex {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.updateSelectedPhase(for: message, phase: availablePhases[targetIndex])
            }
        }
        // Always reset drag offset
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = 0
        }
    }
    
    // Expose dragOffset for use by parent views
    func getDragOffset() -> CGFloat {
        return dragOffset
    }
}

#Preview {
    // Mock data for preview
    let previewViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    let testMessage = Message(content: "Test message content", isUser: false)
    
    return PhaseGestureHandlerView(
        content: { dragOffset in
            Text("Content with drag offset: \(Int(dragOffset))")
        },
        message: testMessage,
        availablePhases: Phase.allCases,
        viewModel: previewViewModel,
        cardWidth: 300
    )
    .frame(height: 300)
    .padding()
}