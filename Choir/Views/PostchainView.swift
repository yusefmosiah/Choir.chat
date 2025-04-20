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

    // Animation state for carousel effect
    @State private var isWrappingAround: Bool = false

    // ViewModel (passed down for potential subviews, though PhaseCard now handles its own logic)
    @ObservedObject var viewModel: PostchainViewModel

    let localThreadIDs: Set<UUID>
    // Removed @State private var latestAvailableSize

    // Computed property to get the selected phase from the message
    private var selectedPhase: Phase {
        get { message.selectedPhase }
        set { viewModel.updateSelectedPhase(for: message, phase: newValue) }
    }

    // Force showing all phases even when not processing (e.g., for debugging)
    var forceShowAllPhases: Bool = false

    // Optional coordinator to check processing status (passed from parent)
    var coordinator: PostchainCoordinatorImpl?

    // Computed property to get available phases based on content or processing status
    private var availablePhases: [Phase] {
        // If forced, show all defined phases
        if forceShowAllPhases {
            return Phase.allCases
        }

        // Get all phases that have any content or are processing
        let filtered = Phase.allCases.filter { phase in
            // Check if the phase has any text content
            let phaseContent = message.getPhaseContent(phase)
            let hasTextContent = !phaseContent.isEmpty

            // Check if the phase is one of the experience phases and has results
            let hasVectorResults = (phase == .experienceVectors && !message.vectorSearchResults.isEmpty)
            let hasWebResults = (phase == .experienceWeb && !message.webSearchResults.isEmpty)

            // Check if the coordinator indicates this phase is currently processing
            let isProcessingPhase = coordinator?.isProcessingPhase(phase) ?? false

            let shouldShow = hasTextContent || hasVectorResults || hasWebResults || isProcessingPhase || message.isStreaming

            if shouldShow {
            }

            return shouldShow
        }

        return filtered
    }

    // Initializer
    init(message: Message, isProcessing: Bool, viewModel: PostchainViewModel, localThreadIDs: Set<UUID>, forceShowAllPhases: Bool = false, coordinator: PostchainCoordinatorImpl? = nil, viewId: UUID = UUID()) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
        self.localThreadIDs = localThreadIDs
        self.forceShowAllPhases = forceShowAllPhases
        self.coordinator = coordinator
        self.viewId = viewId
    }

    // Use this state variable to trigger UI refreshes when phases change
    @State private var phaseRefreshCounter = 0

    // Phase content checker - for watching changes
    var phaseContentChanges: [String: Int] {
        var result: [String: Int] = [:]
        for phase in Phase.allCases {
            let content = message.getPhaseContent(phase)
            result[phase.rawValue] = content.count
        }
        return result
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.98 // Adjust card width slightly
            let totalWidth = geometry.size.width

            // Use derived state to force UI refresh when message changes
            // Get a string representation of available phases to force updates
            let _ = availablePhases.map { $0.rawValue }.joined() + String(phaseRefreshCounter)

            // Also track content changes for each phase
            let _ = phaseContentChanges.map { "\($0):\($1)" }.joined()

            ZStack { // Main ZStack containing only the card stack

                // --- Carousel Indicators ---
                if availablePhases.contains(.action) && availablePhases.contains(.yield) {
                    VStack {
                        Spacer()

                        HStack(spacing: 20) {
                            // Action indicator
                            Image(systemName: "arrow.left")
                                .foregroundColor(selectedPhase == .action ? .gray : .accentColor)
                                .opacity(selectedPhase == .action ? 0.3 : 0.7)
                                .scaleEffect(selectedPhase == .yield ? 1.2 : 1.0)
                                .animation(.easeInOut, value: selectedPhase)

                            Spacer()

                            // Yield indicator
                            Image(systemName: "arrow.right")
                                .foregroundColor(selectedPhase == .yield ? .gray : .accentColor)
                                .opacity(selectedPhase == .yield ? 0.3 : 0.7)
                                .scaleEffect(selectedPhase == .action ? 1.2 : 1.0)
                                .animation(.easeInOut, value: selectedPhase)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)
                    }
                    .zIndex(2)
                }

                // --- Card Stack ---
                ZStack {
                    ForEach(availablePhases) { phase in
                        // Apply common modifiers first
                        let cardView = PhaseCard(
                            phase: phase,
                            message: message,
                            isSelected: phase == selectedPhase,
                            isLoading: isLoadingPhase(phase),
                            viewModel: viewModel,
                            messageId: message.id.uuidString,
                            localThreadIDs: localThreadIDs
                        )
                        .frame(width: cardWidth)
                        .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                        .zIndex(phase == selectedPhase ? 1 : 0)
                        .opacity(calculateOpacity(for: phase))
                        .id("\(viewId)_\(phase.rawValue)_\(message.id)")
                        .allowsHitTesting(phase == selectedPhase)

                        // Conditionally apply drawingGroup
                        if phase == selectedPhase {
                            cardView.drawingGroup()
                        } else {
                            cardView
                        }
                    } // End ForEach
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure card stack uses space
                .onChange(of: availablePhases.count) { _, newCount in
                    // Increment the counter to force UI refresh when available phases change
                    phaseRefreshCounter += 1
                }
                .onChange(of: message.isStreaming) { _, newValue in
                    // Also refresh when streaming state changes
                    phaseRefreshCounter += 1
                }
                .onChange(of: message.phaseResults) { _, _ in
                    // Force a refresh when phase results change
                    phaseRefreshCounter += 1
                }
                .onReceive(message.objectWillChange) {
                    // Also listen for any changes in the message
                    phaseRefreshCounter += 1
                }
                .simultaneousGesture( // Drag gesture remains on the card stack
                    DragGesture()
                        .onChanged { value in
                            // Directly update drag offset without animation
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            // Only animate the final position after drag ends
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                handleDragEnd(value: value, cardWidth: cardWidth)
                            }
                        }
                )

            } // End Main ZStack (containing only cards)
            .overlay(alignment: .leading) { // Left Tap Area Overlay
                let tapAreaWidth = max(0, (geometry.size.width - (cardWidth * 0.8)) / 2)
                Color.clear
                    .frame(width: tapAreaWidth)
                    .padding(.leading, -20) // Expand overlay outward beyond parent bounds
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handlePageTap(direction: .previous, size: geometry.size)
                    }
                    .zIndex(2) // Ensure overlay is above phase cards
            }
            .overlay(alignment: .trailing) { // Right Tap Area Overlay
                let tapAreaWidth = max(0, geometry.size.width - (cardWidth * 0.7))
                Color.clear
                    .frame(width: tapAreaWidth)
                    .padding(.trailing, -60) // Expand overlay outward beyond parent bounds
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handlePageTap(direction: .next, size: geometry.size)
                    }
                    .zIndex(2) // Ensure overlay is above phase cards
            }
        } // End GeometryReader
        .onAppear(perform: handleOnAppear) // Apply .onAppear to GeometryReader's content
        // Removed onChange(of: geometry.size)
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
        var isWrapping = false

        // Handle carousel wrap-around for action and yield phases
        if selectedPhase == .action && predictedEndOffset > threshold {
            // Swiped right from action - check if yield is available
            if availablePhases.contains(.yield) {
                if let yieldIndex = availablePhases.firstIndex(of: .yield) {
                    targetIndex = yieldIndex
                    isWrapping = true
                }
            }
        } else if selectedPhase == .yield && predictedEndOffset < -threshold {
            // Swiped left from yield - check if action is available
            if availablePhases.contains(.action) {
                if let actionIndex = availablePhases.firstIndex(of: .action) {
                    targetIndex = actionIndex
                    isWrapping = true
                }
            }
        } else if predictedEndOffset < -threshold { // Standard swipe left
            targetIndex = min(currentIndex + 1, availablePhases.count - 1)
        } else if predictedEndOffset > threshold { // Standard swipe right
            targetIndex = max(currentIndex - 1, 0)
        }

        if targetIndex != currentIndex {
            // Set wrapping state for special animation
            isWrappingAround = isWrapping

            // Use different animation for wrap-around
            let animation = isWrapping ?
                Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3) :
                Animation.spring(response: 0.3, dampingFraction: 0.8)

            withAnimation(animation) {
                viewModel.updateSelectedPhase(for: message, phase: availablePhases[targetIndex])
                dragOffset = 0
            }

            // Reset wrapping state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isWrappingAround = false
            }
        } else {
            // Always reset drag offset
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = 0
            }
        }
    }

    private func handleOnAppear() {
        if !initialSelectionDone {
            initialSelectionDone = true
            // Set initial selection only if current selection is not valid within available phases
            if !availablePhases.contains(message.selectedPhase) && !availablePhases.isEmpty {
                // Prioritize action > vectors > web > yield (reversed priority)
                if availablePhases.contains(.action) {
                    viewModel.updateSelectedPhase(for: message, phase: .action)
                } else if availablePhases.contains(.experienceVectors) {
                    viewModel.updateSelectedPhase(for: message, phase: .experienceVectors)
                } else if availablePhases.contains(.experienceWeb) {
                    viewModel.updateSelectedPhase(for: message, phase: .experienceWeb)
                } else if availablePhases.contains(.yield) {
                    viewModel.updateSelectedPhase(for: message, phase: .yield)
                } else {
                    viewModel.updateSelectedPhase(for: message, phase: availablePhases.first ?? .action)
                }
            } else {
            }
        } else {
        }
    }

    private func calculateOffset(for phase: Phase, cardWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase),
              let phaseIndex = availablePhases.firstIndex(of: phase) else {
            // If phase isn't available or selected phase isn't found
            // Place it off-screen
            return totalWidth
        }

        // Implement carousel wrap-around logic
        // Special handling for action and yield phases
        if isWrappingAround {
            // During wrap-around animation
            if (selectedPhase == .action && phase == .yield) ||
               (selectedPhase == .yield && phase == .action) {
                // Apply special animation for crossing sides
                let direction = selectedPhase == .action ? -1.0 : 1.0
                return direction * cardWidth * 0.5 + dragOffset
            }
        } else {
            // Normal carousel behavior
            if selectedPhase == .action && phase == .yield && availablePhases.contains(.yield) {
                // Yield is to the right of action
                return cardWidth + dragOffset
            } else if selectedPhase == .yield && phase == .action && availablePhases.contains(.action) {
                // Action is to the left of yield
                return -cardWidth + dragOffset
            }
        }

        // Standard offset calculation for other phases
        let indexDifference = phaseIndex - currentIndex
        return CGFloat(indexDifference) * cardWidth + dragOffset
    }

    private func calculateOpacity(for phase: Phase) -> Double {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase),
              let phaseIndex = availablePhases.firstIndex(of: phase) else {
            return 0 // Not visible if not in available phases
        }

        // Special handling for carousel wrap-around
        if isWrappingAround {
            // During wrap-around animation, keep both action and yield visible
            if (selectedPhase == .action && phase == .yield) ||
               (selectedPhase == .yield && phase == .action) ||
               phase == selectedPhase {
                return 1.0
            }
        } else {
            // Special case for action and yield in carousel
            if (selectedPhase == .action && phase == .yield) ||
               (selectedPhase == .yield && phase == .action) {
                return 0.7 // Keep the other end of carousel somewhat visible
            }
        }

        // Standard opacity calculation
        let indexDifference = abs(phaseIndex - currentIndex)
        // Make selected card fully opaque, fade out others more quickly
        return indexDifference == 0 ? 1.0 : max(0, 0.6 - Double(indexDifference) * 0.3)
    } // Closing brace for calculateOpacity
    // Removed handleTap and calculateTotalPages functions

    private enum PageTapDirection { case previous, next }
    private enum SwipeDirection { case next, previous } // Keep SwipeDirection for switchToPhase

    private func handlePageTap(direction: PageTapDirection, size: CGSize) {
        // Recalculate combined markdown for the current phase
        let phase = selectedPhase
        let baseContent = message.getPhaseContent(phase)
        var combinedMarkdown = baseContent
        if phase == .experienceVectors && !message.vectorSearchResults.isEmpty {
            combinedMarkdown += message.formatVectorResultsToMarkdown()
        } else if phase == .experienceWeb && !message.webSearchResults.isEmpty {
            combinedMarkdown += message.formatWebResultsToMarkdown()
        }
        let pages = splitMarkdownIntoPages(combinedMarkdown, size: size)
        let totalPages = max(1, pages.count)
        let currentPage = message.phaseCurrentPage[phase] ?? 0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if direction == .previous {
                if currentPage > 0 {
                    message.phaseCurrentPage[phase] = currentPage - 1
                } else {
                    switchToPhase(direction: .previous)
                }
            } else { // .next
                if currentPage < totalPages - 1 {
                    message.phaseCurrentPage[phase] = currentPage + 1
                } else {
                    switchToPhase(direction: .next)
                }
            }
        }
    }

    // Helper to match PaginatedMarkdownView pagination logic
    private func splitMarkdownIntoPages(_ text: String, size: CGSize) -> [String] {
        guard !text.isEmpty else { return [""] }
        guard size.width > 8, size.height > 40 else {
            return [text]
        }

        let measurer = TextMeasurer(sizeCategory: .medium)
        let paginationControlsHeight: CGFloat = 35
        let verticalPadding: CGFloat = 8
        let availableTextHeight = size.height - verticalPadding - paginationControlsHeight

        guard availableTextHeight > 20 else {
            return [text]
        }

        let availableTextWidth = size.width - 8

        var pagesResult: [String] = []
        var remainingText = Substring(text)

        while !remainingText.isEmpty {
            let pageText = measurer.fitTextToHeight(
                text: String(remainingText),
                width: availableTextWidth,
                height: availableTextHeight
            )

            guard !pageText.isEmpty else {
                if !remainingText.isEmpty {
                    pagesResult.append(String(remainingText))
                }
                remainingText = ""
                break
            }

            pagesResult.append(pageText)

            if pageText.count < remainingText.count {
                let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                remainingText = remainingText[index...]
            } else {
                remainingText = ""
            }
        }

        if pagesResult.isEmpty && !text.isEmpty {
            return [text]
        }
        if pagesResult.isEmpty && text.isEmpty {
            return [""]
        }

        return pagesResult
    }

    // Updated switchToPhase function with carousel support
    private func switchToPhase(direction: SwipeDirection) {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase) else { return }

        var targetIndex = currentIndex
        var isWrapping = false

        // Handle carousel wrap-around for action and yield phases
        if direction == .next && selectedPhase == .yield {
            // Going next from yield - check if action is available for wrap-around
            if availablePhases.contains(.action) {
                if let actionIndex = availablePhases.firstIndex(of: .action) {
                    targetIndex = actionIndex
                    isWrapping = true
                } else {
                    targetIndex = min(currentIndex + 1, availablePhases.count - 1)
                }
            } else {
                targetIndex = min(currentIndex + 1, availablePhases.count - 1)
            }
        } else if direction == .previous && selectedPhase == .action {
            // Going previous from action - check if yield is available for wrap-around
            if availablePhases.contains(.yield) {
                if let yieldIndex = availablePhases.firstIndex(of: .yield) {
                    targetIndex = yieldIndex
                    isWrapping = true
                } else {
                    targetIndex = max(currentIndex - 1, 0)
                }
            } else {
                targetIndex = max(currentIndex - 1, 0)
            }
        } else if direction == .next {
            targetIndex = min(currentIndex + 1, availablePhases.count - 1)
        } else { // direction == .previous
            targetIndex = max(currentIndex - 1, 0)
        }

        if targetIndex != currentIndex {
            let newPhase = availablePhases[targetIndex]

            // Reset the current page for the NEW phase
            message.phaseCurrentPage[newPhase] = 0 // Always reset to first page for simplicity

            // Set wrapping state for special animation
            isWrappingAround = isWrapping

            // Use different animation for wrap-around
            let animation = isWrapping ?
                Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3) :
                Animation.spring(response: 0.3, dampingFraction: 0.8)

            withAnimation(animation) {
                viewModel.updateSelectedPhase(for: message, phase: newPhase)
            }

            // Reset wrapping state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isWrappingAround = false
            }
        }
    }


    // calculateAccurateTotalPages is no longer needed and has been removed.
    #Preview {
        PostchainView(
            message: Message(content: "Preview", isUser: false),
            isProcessing: false,
            viewModel: PostchainViewModel(coordinator: PostchainCoordinatorImpl()),
            localThreadIDs: []
        )
        .frame(height: 400)
        .padding()
    }
}
