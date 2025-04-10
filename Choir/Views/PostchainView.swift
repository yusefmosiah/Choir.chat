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
    // Removed @State private var latestAvailableSize

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

            ZStack { // Main ZStack containing only the card stack

                // --- Card Stack ---
                ZStack {
                    ForEach(availablePhases) { phase in
                        PhaseCard(
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
                        .id("\(viewId)_\(phase.rawValue)")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure card stack uses space
                .simultaneousGesture( // Drag gesture remains on the card stack
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

            } // End Main ZStack (containing only cards)
            .overlay(alignment: .leading) { // Left Tap Area Overlay
                // Calculate the width for the tap area (space outside the central non-tappable zone)
                let tapAreaWidth = max(0, (geometry.size.width - (cardWidth * 0.33)) / 2)
                Color.red // Use clear for production, Color.red for debugging
                    .frame(width: tapAreaWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("LEFT TAP AREA TAPPED")
                        handlePageTap(direction: .previous, size: geometry.size)
                    }
            }
            .overlay(alignment: .trailing) { // Right Tap Area Overlay
                // Calculate the width for the tap area
                let tapAreaWidth = max(0, (geometry.size.width - (cardWidth * 0.33)) / 2)
                Color.red // Use clear for production, Color.red for debugging
                    .frame(width: tapAreaWidth)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("RIGHT TAP AREA TAPPED")
                        handlePageTap(direction: .next, size: geometry.size)
                    }
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
    // Removed handleTap and calculateTotalPages functions

    private enum PageTapDirection { case previous, next }
    private enum SwipeDirection { case next, previous } // Keep SwipeDirection for switchToPhase

    private func handlePageTap(direction: PageTapDirection, size: CGSize) {
        guard size != .zero else {
            print("Error: Size is zero, cannot calculate pages.")
            return
        }
        let phase = selectedPhase // Get currently selected phase
        let currentPage = message.phaseCurrentPage[phase] ?? 0

        // Calculate totalPages accurately using PaginatedMarkdownView's logic
        let content = message.getPhaseContent(phase)
        // Note: Accessing search results directly here. Ensure Message model provides these.
        // If errors occur, check ConversationModels.swift for VectorSearchResult/SearchResult definitions.
        let vectorResults = message.vectorSearchResults.map { UnifiedSearchResult.vector($0) }
        let webResults = message.webSearchResults.map { UnifiedSearchResult.web($0) }
        let searchResults = vectorResults + webResults
        let totalPages = calculateAccurateTotalPages(markdownText: content, searchResults: searchResults, size: size)

        print("handlePageTap: Phase=\(phase), CurrentPage=\(currentPage + 1), TotalPages=\(totalPages), Direction=\(direction)") // Debug

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if direction == .previous {
                if currentPage > 0 {
                    message.phaseCurrentPage[phase] = currentPage - 1
                    print("Tapped Left: Now Page \(currentPage)") // Debug
                } else {
                    print("Tapped Left: Switching Phase Previous") // Debug
                    switchToPhase(direction: .previous) // Existing function
                }
            } else { // .next
                if currentPage < totalPages - 1 {
                    message.phaseCurrentPage[phase] = currentPage + 1
                    print("Tapped Right: Now Page \(currentPage + 2)") // Debug
                } else {
                    print("Tapped Right: Switching Phase Next") // Debug
                    switchToPhase(direction: .next) // Existing function
                }
            }
        }
    }

    // Keep existing switchToPhase function, it's still needed for phase boundary logic
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
                message.phaseCurrentPage[newPhase] = 0 // Reset to first page
                print("switchToPhase: Reset page for \(newPhase) to 0")
            } else { // direction == .previous
                // Reset to last page - Requires calculating total pages for the *new* phase
                // We need the size here too! This might be tricky.
                // Simplification: Always reset to 0 when switching phases? Or pass size?
                // Let's try resetting to 0 for now for simplicity, can refine later if needed.
                // TODO: Revisit resetting to last page if required.
                message.phaseCurrentPage[newPhase] = 0 // Simplified: Reset to first page
                print("switchToPhase: Reset page for \(newPhase) to 0 (Simplified)")

                // --- Original logic requiring size ---
                // let phaseContent = message.getPhaseContent(newPhase)
                // let vectorResults = message.vectorSearchResults.map { UnifiedSearchResult.vector($0) }
                // let webResults = message.webSearchResults.map { UnifiedSearchResult.web($0) }
                // let searchResults = vectorResults + webResults
                // let totalPagesForNewPhase = calculateAccurateTotalPages(markdownText: phaseContent, searchResults: searchResults, size: latestAvailableSize) // Needs size!
                // message.phaseCurrentPage[newPhase] = max(0, totalPagesForNewPhase - 1)
                // print("switchToPhase: Reset page for \(newPhase) to \(message.phaseCurrentPage[newPhase] ?? -1)")
                // --- End Original logic ---
            }
            // --- END CRITICAL RESET LOGIC ---

            viewModel.updateSelectedPhase(for: message, phase: newPhase)
        }
    }


    // Helper function to calculate total pages accurately (adapting PaginatedMarkdownView logic)
    private func calculateAccurateTotalPages(markdownText: String, searchResults: [UnifiedSearchResult], size: CGSize) -> Int {
        guard size.height > 0, size.width > 0 else {
            print("Warning: calculateAccurateTotalPages called with zero size.")
            return 1
        }

        // Logic adapted from PaginatedMarkdownView
        // Note: Ensure TextMeasurer is accessible or reimplement its logic if needed.
        // Assuming TextMeasurer is available globally or via import.
        let measurer = TextMeasurer(sizeCategory: .medium) // Adjust sizeCategory if needed
        let textHeight = size.height - 40 // Matches PaginatedMarkdownView padding estimate
        var textPagesCount = 0
        var remainingText = markdownText

        if !markdownText.isEmpty {
            while !remainingText.isEmpty {
                let pageText = measurer.fitTextToHeight(
                    text: remainingText,
                    width: size.width - 8, // Matches PaginatedMarkdownView padding estimate
                    height: textHeight
                )
                // Handle potential infinite loop if fitTextToHeight returns empty string for non-empty input
                if pageText.isEmpty && !remainingText.isEmpty {
                    print("Warning: TextMeasurer returned empty page for non-empty text. Breaking loop.")
                    textPagesCount += 1 // Count the remaining text as one page
                    break
                }
                textPagesCount += 1
                if pageText.count < remainingText.count {
                    let index = remainingText.index(remainingText.startIndex, offsetBy: pageText.count)
                    remainingText = String(remainingText[index...])
                } else {
                    remainingText = ""
                }
            }
        } else {
            textPagesCount = 0 // No text pages if markdown is empty
        }


        // Chunk results (Matches PaginatedMarkdownView logic)
        let itemsPerPage = 5 // Assuming 5 results per page, match PaginatedMarkdownView
        // Use ceil division to potentially fix type inference error
        let resultPagesCount = searchResults.isEmpty ? 0 : Int(ceil(Double(searchResults.count) / Double(itemsPerPage)))

        let total = textPagesCount + resultPagesCount
        return max(1, total) // Ensure at least 1 page
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
