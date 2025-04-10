import SwiftUI
import Foundation

struct PostchainView: View {
    @State private var initialSelectionDone = false
    // Unique identifier for this view instance to prevent state sharing
    let viewId: UUID

    // Reference to the specific message this view is displaying
    @ObservedObject var message: Message

    // Processing state (passed from parent, ChoirThreadDetailView)
    let isProcessing: Bool

    // Drag state
    @State private var dragOffset: CGFloat = 0

    // ViewModel (passed down for potential subviews, though PhaseCard now handles its own logic)
    @ObservedObject var viewModel: PostchainViewModel

    let localThreadIDs: Set<UUID>

    // Computed property to get the selected phase from the message
    private var selectedPhase: Phase {
        get { message.selectedPhase }
        set { viewModel.updateSelectedPhase(for: message, phase: newValue) }
    }

    // Force showing all phases even when not processing (e.g., for debugging)
    var forceShowAllPhases: Bool = false

    // Optional coordinator to check processing status (passed from parent)
    var coordinator: RESTPostchainCoordinator?

    // Computed property to get available phases based on content or processing status
    private var availablePhases: [Phase] {
        // If forced, show all defined phases
        if forceShowAllPhases {
            return Phase.allCases
        }

        // Otherwise, determine available phases based on message content and coordinator status
        return Phase.allCases.filter { phase in
            // Check if the phase has text content
            let phaseContent = message.getPhaseContent(phase)
            let hasTextContent = !phaseContent.isEmpty

            // Check if the phase is one of the experience phases and has results
            let hasVectorResults = (phase == .experienceVectors && !message.vectorSearchResults.isEmpty)
            let hasWebResults = (phase == .experienceWeb && !message.webSearchResults.isEmpty)

            // Check if the coordinator indicates this phase is currently processing
            let isProcessingPhase = coordinator?.isProcessingPhase(phase) ?? false

            return hasTextContent || hasVectorResults || hasWebResults || isProcessingPhase
        }
    }

    // Initializer
    init(message: Message, isProcessing: Bool, viewModel: PostchainViewModel, localThreadIDs: Set<UUID>, forceShowAllPhases: Bool = false, coordinator: RESTPostchainCoordinator? = nil, viewId: UUID = UUID()) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
        self.localThreadIDs = localThreadIDs
        self.forceShowAllPhases = forceShowAllPhases
        self.coordinator = coordinator
        self.viewId = viewId
        // print("PostchainView initialized for message \(message.id)") // Reduced logging
        // print("PostchainView localThreadIDs: \(localThreadIDs)") // Removed excessive logging
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.98 // Adjust card width slightly
            let totalWidth = geometry.size.width

            ZStack {
                ForEach(availablePhases) { phase in
                    PhaseCard(
                        phase: phase,
                        message: message,
                        isSelected: phase == selectedPhase,
                        // Determine loading state based on coordinator or if content/results are missing while processing
                        isLoading: isLoadingPhase(phase),
                        viewModel: viewModel,
                        messageId: message.id.uuidString,
                        localThreadIDs: localThreadIDs
                    )
                    .frame(width: cardWidth)
                    .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                    .zIndex(phase == selectedPhase ? 1 : 0) // Bring selected card to front
                    .opacity(calculateOpacity(for: phase))
                    .id("\(viewId)_\(phase.rawValue)") // More stable ID
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        handleDragEnd(value: value, cardWidth: cardWidth)
                    }
            )
        }
        .onAppear(perform: handleOnAppear)
        .id("postchain_view_\(message.id)_\(viewId)") // Stable ID for the view itself
        .frame(maxHeight: .infinity)
    }

    // --- Helper Functions ---

    private func isLoadingPhase(_ phase: Phase) -> Bool {
        // If coordinator exists, ask it if the phase is processing
        if let coordinator = coordinator {
            return coordinator.isProcessingPhase(phase)
        }
        // Fallback: If processing globally and this phase has no content/results yet
        if isProcessing {
             let phaseContent = message.getPhaseContent(phase)
             let hasTextContent = !phaseContent.isEmpty
             let hasVectorResults = (phase == .experienceVectors && !message.vectorSearchResults.isEmpty)
             let hasWebResults = (phase == .experienceWeb && !message.webSearchResults.isEmpty)
             return !(hasTextContent || hasVectorResults || hasWebResults)
        }
        return false
    }

    private func handleDragEnd(value: DragGesture.Value, cardWidth: CGFloat) {
        let predictedEndOffset = value.predictedEndTranslation.width
        let threshold = cardWidth / 3

        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase) else { return }

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

    private func handleOnAppear() {
        if !initialSelectionDone {
            initialSelectionDone = true
            // Set initial selection only if current selection is not valid within available phases
            if !availablePhases.contains(message.selectedPhase) && !availablePhases.isEmpty {
                // Prioritize yield > web > vectors > action
                if availablePhases.contains(.yield) {
                    viewModel.updateSelectedPhase(for: message, phase: .yield)
                } else if availablePhases.contains(.experienceWeb) {
                    viewModel.updateSelectedPhase(for: message, phase: .experienceWeb)
                } else if availablePhases.contains(.experienceVectors) {
                    viewModel.updateSelectedPhase(for: message, phase: .experienceVectors)
                } else if availablePhases.contains(.action) {
                    viewModel.updateSelectedPhase(for: message, phase: .action)
                } else {
                    viewModel.updateSelectedPhase(for: message, phase: availablePhases.first ?? .action)
                }
               // print("PostchainView: Initially selected phase: \(selectedPhase)") // Reduced logging
             } else {
                // print("PostchainView: Keeping current selection on appear: \(selectedPhase)") // Reduced logging
             }
         } else {
            // print("PostchainView: Reappeared, keeping selection: \(selectedPhase)") // Reduced logging
         }
    }

    private func calculateOffset(for phase: Phase, cardWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase),
              let phaseIndex = availablePhases.firstIndex(of: phase) else {
            // If phase isn't available or selected phase isn't found
            // Place it off-screen
            return totalWidth
        }

        // Wrap-around logic: treat yield as immediately left of action
        if selectedPhase == .action && phase == .yield {
            return -cardWidth + dragOffset
        }
        if selectedPhase == .yield && phase == .action {
            return cardWidth + dragOffset
        }

        let indexDifference = phaseIndex - currentIndex
        return CGFloat(indexDifference) * cardWidth + dragOffset
    }

    private func calculateOpacity(for phase: Phase) -> Double {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase),
              let phaseIndex = availablePhases.firstIndex(of: phase) else {
            return 0 // Not visible if not in available phases
        }

        let indexDifference = abs(phaseIndex - currentIndex)
        // Make selected card fully opaque, fade out others more quickly
        return indexDifference == 0 ? 1.0 : max(0, 0.6 - Double(indexDifference) * 0.3)
    } // Closing brace for calculateOpacity
private func handleTap(isRightTap: Bool) {
    guard let currentPhase = availablePhases.first(where: { $0 == selectedPhase }) else {
        print("handleTap: No selected phase")
        return
    }

    // Access current page from the message
    let currentPage = message.phaseCurrentPage[currentPhase] ?? 0

    // Calculate total pages based on content
    let phaseContent = message.getPhaseContent(currentPhase)
    let totalPages = calculateTotalPages(for: phaseContent, phase: currentPhase)

    print("handleTap: Phase=\(currentPhase), CurrentPage=\(currentPage), TotalPages=\(totalPages), RightTap=\(isRightTap)")

    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        if isRightTap {
            // Tapped Right: Go to next page or next phase
            if currentPage < totalPages - 1 {
                message.phaseCurrentPage[currentPhase] = currentPage + 1
                print("handleTap: Incremented page to \(currentPage + 1)")
            } else {
                // Already on the last page, switch to the next phase
                print("handleTap: Switching to next phase")
                switchToPhase(direction: .next)
            }
        } else {
            // Tapped Left: Go to previous page or previous phase
            if currentPage > 0 {
                message.phaseCurrentPage[currentPhase] = currentPage - 1
                print("handleTap: Decremented page to \(currentPage - 1)")
            } else {
                // Already on the first page, switch to the previous phase
                print("handleTap: Switching to previous phase")
                switchToPhase(direction: .previous)
            }
        }
    }
}

private enum SwipeDirection { case next, previous }

private func switchToPhase(direction: SwipeDirection) {
    guard let currentIndex = availablePhases.firstIndex(of: selectedPhase) else { return }

    var targetIndex = currentIndex
    if direction == .next {
        targetIndex = min(currentIndex + 1, availablePhases.count - 1)
    } else { // .previous
        targetIndex = max(currentIndex - 1, 0)
    }

    if targetIndex != currentIndex {
        let newPhase = availablePhases[targetIndex]
        print("switchToPhase: Moving from \(selectedPhase) to \(newPhase)")

        // --- START CRITICAL RESET LOGIC ---
        // Reset the current page for the NEW phase
        if direction == .next {
            // When moving to the next phase, reset its page to the beginning (0)
            message.phaseCurrentPage[newPhase] = 0
            print("switchToPhase: Reset page for \(newPhase) to 0")
        } else { // direction == .previous
            // When moving to the previous phase, reset its page to the end
            // Calculate total pages for the new phase
            let phaseContent = message.getPhaseContent(newPhase)
            let totalPagesForNewPhase = calculateTotalPages(for: phaseContent, phase: newPhase)
            message.phaseCurrentPage[newPhase] = max(0, totalPagesForNewPhase - 1) // Ensure not negative
             print("switchToPhase: Reset page for \(newPhase) to \(message.phaseCurrentPage[newPhase] ?? -1)")
        }
        // --- END CRITICAL RESET LOGIC ---

        // Update the selected phase
        // Let the viewModel handle the update which triggers UI changes via @Published
        viewModel.updateSelectedPhase(for: message, phase: newPhase)
    }
}

// Helper method to calculate total pages for a phase
private func calculateTotalPages(for content: String, phase: Phase) -> Int {
    if content.isEmpty {
        return 1
    }

    // For vector and web search results, use a different calculation
    if phase == .experienceVectors && !message.vectorSearchResults.isEmpty {
        return max(1, (message.vectorSearchResults.count + 4) / 5)
    } else if phase == .experienceWeb && !message.webSearchResults.isEmpty {
        return max(1, (message.webSearchResults.count + 4) / 5)
    }

    // For text content, estimate based on content length
    // This is a simple estimation - in a real app, you might want to use
    // the TextMeasurer from PaginatedMarkdownView for more accuracy
    let averageCharsPerPage = 1000
    return max(1, (content.count + averageCharsPerPage - 1) / averageCharsPerPage)
}
#Preview {
    PostchainView(
        message: Message(content: "Preview", isUser: false),
        isProcessing: false,
        viewModel: PostchainViewModel(coordinator: RESTPostchainCoordinator()),
        localThreadIDs: []
    )
    .frame(height: 400)
    .padding()
}
}
