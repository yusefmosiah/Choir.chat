import SwiftUI
import Foundation
import Combine // Needed for Publishers

struct PostchainView: View {
    // --- State Variables ---
    @State private var initialSelectionDone = false
    let viewId: UUID // Unique identifier for this view instance

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

    // Use this state variable to trigger UI refreshes when phases/pages change
    @State private var phaseRefreshCounter = 0

    // --- Pagination Cache ---
    // Conforms to Hashable (and Equatable automatically)
    struct PageCacheKey: Hashable {
        let messageId: UUID
        let phase: Phase
        let width: CGFloat
        let height: CGFloat
        let contentHash: Int // Hash of the combined markdown content
    }
    @State private var pageCache: [PageCacheKey: [String]] = [:]
    @State private var paginator = MarkdownPaginator() // Instance of the new paginator

    // --- Debouncer for Size Changes ---
    // Use a PassthroughSubject to publish size changes
    private let sizeChangePublisher = PassthroughSubject<CGSize, Never>()
    // Store the debounced size
    @State private var debouncedSize: CGSize? = nil


    // Phase content checker - for watching changes (used for cache invalidation)
    var phaseContentHashes: [Phase: Int] {
        var result: [Phase: Int] = [:]
        for phase in availablePhases { // Only check available phases
            let combinedMarkdown = getCombinedMarkdown(for: phase)
            result[phase] = combinedMarkdown.hashValue
        }
        return result
    }

    // --- Constants ---
    let paginationDebounceInterval: TimeInterval = 0.15 // Debounce interval in seconds

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.98 // Adjust card width slightly
            let totalWidth = geometry.size.width

            // Use derived state to force UI refresh when message changes
            // Get a string representation of available phases to force updates
            // Use debounced size for pagination calculations, fallback to geometry.size
            let currentSize = debouncedSize ?? geometry.size

            // Trigger UI refresh based on relevant state changes
            // Ensure selectedPhase is valid before using rawValue
            let selectedPhaseRaw = availablePhases.contains(selectedPhase) ? selectedPhase.rawValue : "none"
            let _ = "\(selectedPhaseRaw)_\(message.id)_\(phaseRefreshCounter)_\(currentSize.width)_\(currentSize.height)"

            // Calculate pages for the *selected* phase using the cache
            let pagesForSelectedPhase = getPaginatedContent(for: selectedPhase, size: currentSize)
            let totalPagesForSelectedPhase = max(1, pagesForSelectedPhase.count)
            let currentPageForSelectedPhase = message.phaseCurrentPage[selectedPhase] ?? 0
            let currentPageContent = pagesForSelectedPhase.indices.contains(currentPageForSelectedPhase) ? pagesForSelectedPhase[currentPageForSelectedPhase] : ""


            VStack(spacing: 8) { // Main VStack containing card stack and page control
                // --- Card Stack ---
                ZStack {
                    ForEach(availablePhases) { phase in
                        // Determine content for this specific card's page
                        let pagesForThisPhase = getPaginatedContent(for: phase, size: currentSize)
                        let currentPageIndex = message.phaseCurrentPage[phase] ?? 0
                        let pageContentForThisCard = pagesForThisPhase.indices.contains(currentPageIndex) ? pagesForThisPhase[currentPageIndex] : ""

                        // Apply common modifiers first
                        let cardView = PhaseCard(
                            phase: phase,
                            message: message,
                            isSelected: phase == selectedPhase,
                            isLoading: isLoadingPhase(phase),
                            viewModel: viewModel,
                            messageId: message.id.uuidString,
                            localThreadIDs: localThreadIDs,
                            // Pass the specific page content
                            pageContent: pageContentForThisCard
                        )
                        .frame(width: cardWidth)
                        .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                        .zIndex(phase == selectedPhase ? 1 : 0)
                        .opacity(calculateOpacity(for: phase))
                        .id("\(viewId)_\(phase.rawValue)_\(message.id)") // Keep stable ID
                        .allowsHitTesting(phase == selectedPhase)

                        // Conditionally apply drawingGroup
                        if phase == selectedPhase {
                            cardView.drawingGroup() // Apply drawingGroup only to the selected card
                        } else {
                            cardView
                        }
                    } // End ForEach
                }
                .frame(maxWidth: .infinity)
                .frame(height: currentSize.height - 20) // Use currentSize
                // --- Gestures ---
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            // Directly update drag offset without animation
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

                // --- Page Control ---
                GlassPageControl(
                    currentPhase: selectedPhase,
                    availablePhases: availablePhases,
                    currentPage: pageBinding(for: selectedPhase), // Binding to message state
                    totalPages: totalPagesForSelectedPhase, // Use calculated total pages
                    onPhaseChange: { newPhase in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            // Reset page to 0 when phase changes
                            message.phaseCurrentPage[newPhase] = 0
                            viewModel.updateSelectedPhase(for: message, phase: newPhase)
                            phaseRefreshCounter += 1 // Trigger refresh
                        }
                    },
                    onPageChange: { direction in
                        // Pass the calculated total pages to navigation handler
                        handlePageNavigation(direction: direction, totalPages: totalPagesForSelectedPhase)
                    }
                )
                .padding(.bottom, 5)

            } // End Main VStack
            // --- Size Handling & Debouncing ---
            .onChange(of: geometry.size) { _, newSize in
                 // Publish size changes immediately if size is valid
                 if newSize.width > 0 && newSize.height > 0 {
                    sizeChangePublisher.send(newSize)
                 }
            }
            // Use DispatchTimeInterval for debounce
            .onReceive(sizeChangePublisher.debounce(for: .seconds(paginationDebounceInterval), scheduler: DispatchQueue.main)) { debouncedValue in
                 // Update the state with the debounced size
                 if debouncedSize != debouncedValue {
                     print("[PostchainView] Debounced size changed: \(debouncedValue)")
                     debouncedSize = debouncedValue
                     // No need to manually trigger pagination here,
                     // getPaginatedContent will be called automatically on next render
                     // due to state change.
                     phaseRefreshCounter += 1 // Ensure view redraws with new size
                 }
            }
            // --- Other Event Handlers ---
            .onChange(of: availablePhases.count) { _, _ in phaseRefreshCounter += 1 }
            .onChange(of: message.isStreaming) { _, _ in phaseRefreshCounter += 1 }
            .onChange(of: message.phaseResults) { _, _ in phaseRefreshCounter += 1 }
            .onReceive(message.objectWillChange) { phaseRefreshCounter += 1 }


        } // End GeometryReader
        .onAppear {
            // Set initial debounced size
            if debouncedSize == nil {
                // Use a placeholder or initial geometry if available immediately
                // For simplicity, let's assume it gets set quickly by onChange
            }
            handleOnAppear()
        }
        .id("postchain_view_\(message.id)_\(viewId)") // Stable ID for the view itself
        .frame(maxHeight: .infinity)
    }

    // --- Helper Functions ---

    // Function to get combined markdown content for a phase
    private func getCombinedMarkdown(for phase: Phase) -> String {
        let baseContent = message.getPhaseContent(phase)
        var combinedMarkdown = baseContent
        if phase == .experienceVectors && !message.vectorSearchResults.isEmpty {
            combinedMarkdown += message.formatVectorResultsToMarkdown()
        } else if phase == .experienceWeb && !message.webSearchResults.isEmpty {
            combinedMarkdown += message.formatWebResultsToMarkdown()
        }
        return combinedMarkdown
    }

    // Centralized function for pagination and caching
    private func getPaginatedContent(for phase: Phase, size: CGSize) -> [String] {
        guard size.width > 0, size.height > 0 else {
            print("[PostchainView] Size invalid (\(size)), returning single page.")
            return [getCombinedMarkdown(for: phase)] // Return unprocessed content if size invalid
        }

        // 1. Get combined and pre-processed content
        let combinedMarkdown = getCombinedMarkdown(for: phase)
        // Ensure deep links are converted *before* pagination
        let textToPaginate = combinedMarkdown.convertVectorReferencesToDeepLinks()
        // Note: optimizeForPagination was likely specific to the old estimation method and is removed.
        let contentHash = textToPaginate.hashValue // Hash the final text being paginated

        // 2. Create cache key
        // Use rounded dimensions to reduce cache misses from minor floating point differences
        let roundedWidth = (size.width * 10).rounded() / 10
        let roundedHeight = (size.height * 10).rounded() / 10
        let cacheKey = PageCacheKey(
            messageId: message.id,
            phase: phase,
            width: roundedWidth,
            height: roundedHeight,
            contentHash: contentHash
        )

        // 3. Check cache
        if let cachedPages = pageCache[cacheKey] {
            print("[PostchainView] Cache hit for \(phase) size \(size)")
            return cachedPages
        }

        // 4. Cache miss - Paginate
        print("[PostchainView] Cache miss for \(phase) size \(size). Paginating...")
        // Use appropriate padding adjustments if needed by PaginatedMarkdownView's internal padding
        let verticalPadding: CGFloat = 4 // Match PaginatedMarkdownView's expected padding
        let horizontalPadding: CGFloat = 4 // Match PaginatedMarkdownView's expected padding
        let availableTextHeight = max(20, size.height - verticalPadding) // Ensure minimum height
        let availableTextWidth = max(8, size.width - horizontalPadding) // Ensure minimum width

        let newPages = paginator.paginateMarkdown(
            textToPaginate,
            width: availableTextWidth,
            height: availableTextHeight
        )

        // 5. Update cache
        pageCache[cacheKey] = newPages
        print("[PostchainView] Cached \(newPages.count) pages for \(phase) size \(size)")

        // Clean up old cache entries occasionally (optional)
        // if pageCache.count > 100 { cleanupCache() }

        return newPages
    }

    // Optional: Cache cleanup logic
    // private func cleanupCache() {
    //     // Example: Remove entries not related to the current message
    //     pageCache = pageCache.filter { $0.key.messageId == message.id }
    // }

    private func isLoadingPhase(_ phase: Phase) -> Bool {
        // If coordinator exists, ask it if the phase is processing
        if let coordinator = coordinator {
            return coordinator.isProcessingPhase(phase)
        }
        // Fallback: If processing globally and this phase has no content/results yet
        if isProcessing {
            let combinedMarkdown = getCombinedMarkdown(for: phase) // Use helper
            let hasTextContent = !combinedMarkdown.isEmpty
            // Results check remains the same - use fully qualified enum names
            let hasVectorResults = (phase == Phase.experienceVectors && !message.vectorSearchResults.isEmpty)
            let hasWebResults = (phase == Phase.experienceWeb && !message.webSearchResults.isEmpty)
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

        // Handle carousel wrap-around for action and yield phases - use Phase.caseName
        if selectedPhase == Phase.action && predictedEndOffset > threshold {
            // Swiped right from action - check if yield is available
            if availablePhases.contains(Phase.yield) {
                if let yieldIndex = availablePhases.firstIndex(of: Phase.yield) {
                    targetIndex = yieldIndex
                    isWrapping = true
                }
            }
        } else if selectedPhase == Phase.yield && predictedEndOffset < -threshold {
            // Swiped left from yield - check if action is available
            if availablePhases.contains(Phase.action) {
                if let actionIndex = availablePhases.firstIndex(of: Phase.action) {
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
                // Prioritize action > vectors > web > yield (reversed priority) - use Phase.caseName
                if availablePhases.contains(Phase.action) {
                    viewModel.updateSelectedPhase(for: message, phase: Phase.action)
                } else if availablePhases.contains(Phase.experienceVectors) {
                    viewModel.updateSelectedPhase(for: message, phase: Phase.experienceVectors)
                } else if availablePhases.contains(Phase.experienceWeb) {
                    viewModel.updateSelectedPhase(for: message, phase: Phase.experienceWeb)
                } else if availablePhases.contains(Phase.yield) {
                    viewModel.updateSelectedPhase(for: message, phase: Phase.yield)
                } else {
                    viewModel.updateSelectedPhase(for: message, phase: availablePhases.first ?? Phase.action) // Default to Phase.action
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

        // Implement carousel wrap-around logic - use Phase.caseName
        // Special handling for action and yield phases
        if isWrappingAround {
            // During wrap-around animation
            if (selectedPhase == Phase.action && phase == Phase.yield) ||
               (selectedPhase == Phase.yield && phase == Phase.action) {
                // Apply special animation for crossing sides
                let direction = selectedPhase == Phase.action ? -1.0 : 1.0
                return direction * cardWidth * 0.5 + dragOffset
            }
        } else {
            // Normal carousel behavior
            if selectedPhase == Phase.action && phase == Phase.yield && availablePhases.contains(Phase.yield) {
                // Yield is to the right of action
                return cardWidth + dragOffset
            } else if selectedPhase == Phase.yield && phase == Phase.action && availablePhases.contains(Phase.action) {
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

        // Special handling for carousel wrap-around - use Phase.caseName
        if isWrappingAround {
            // During wrap-around animation, keep both action and yield visible
            if (selectedPhase == Phase.action && phase == Phase.yield) ||
               (selectedPhase == Phase.yield && phase == Phase.action) ||
               phase == selectedPhase {
                return 1.0
            }
        } else {
            // Special case for action and yield in carousel
            if (selectedPhase == Phase.action && phase == Phase.yield) ||
               (selectedPhase == Phase.yield && phase == Phase.action) {
                return 0.7 // Keep the other end of carousel somewhat visible
            }
        }

        // Standard opacity calculation
        let indexDifference = abs(phaseIndex - currentIndex)
        // Make selected card fully opaque, fade out others more quickly
        return indexDifference == 0 ? 1.0 : max(0, 0.6 - Double(indexDifference) * 0.3)
    } // Closing brace for calculateOpacity
    private enum SwipeDirection { case next, previous } // Keep SwipeDirection for switchToPhase

    // Helper function to create a binding for the current page of a phase
    private func pageBinding(for phase: Phase) -> Binding<Int> {
        Binding<Int>(
            get: { message.phaseCurrentPage[phase] ?? 0 },
            set: { newValue in
                // Ensure the new value is within valid bounds if possible
                // Note: totalPages might not be calculated yet when this is set initially.
                // We rely on getPaginatedContent to clamp later if needed.
                message.phaseCurrentPage[phase] = newValue
                phaseRefreshCounter += 1 // Trigger refresh when page changes via binding
            }
        )
    }

    // calculateTotalPages is removed, use getPaginatedContent(for:size:).count instead

    // Unified function to handle page navigation using cached total pages
    // Use the top-level PageDirection enum
    private func handlePageNavigation(direction: PageDirection, totalPages: Int) {
        let phase = selectedPhase
        let currentPage = message.phaseCurrentPage[phase] ?? 0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            // Compare with top-level enum cases
            if direction == .previous {
                if currentPage > 0 {
                    // Navigate to previous page within the current phase
                    message.phaseCurrentPage[phase] = currentPage - 1
                    phaseRefreshCounter += 1 // Trigger refresh
                } else {
                    // Already on the first page, switch to the previous phase
                    // Still use the local SwipeDirection enum for switching phases
                    // Still use the local SwipeDirection enum for switching phases
                    switchToPhase(direction: .previous)
                }
            } else if direction == .next { // Compare with top-level enum cases
                if currentPage < totalPages - 1 {
                    // Navigate to next page within the current phase
                    message.phaseCurrentPage[phase] = currentPage + 1
                    phaseRefreshCounter += 1 // Trigger refresh
                } else {
                    // Already on the last page, switch to the next phase
                    switchToPhase(direction: .next)
                }
            }
        }
    }

    // splitMarkdownIntoPages helper is removed, logic moved to getPaginatedContent

    // Updated switchToPhase function with carousel support
    private func switchToPhase(direction: SwipeDirection) {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase) else { return }

        var targetIndex = currentIndex
        var isWrapping = false

        // --- Carousel Wrap-around Logic --- use Phase.caseName
        if direction == .next && selectedPhase == Phase.yield && availablePhases.contains(Phase.action) {
            if let actionIndex = availablePhases.firstIndex(of: Phase.action) {
                targetIndex = actionIndex
                isWrapping = true
            } else { // Fallback if action somehow not found despite contains check
                targetIndex = min(currentIndex + 1, availablePhases.count - 1)
            }
        } else if direction == .previous && selectedPhase == Phase.action && availablePhases.contains(Phase.yield) {
             if let yieldIndex = availablePhases.firstIndex(of: Phase.yield) {
                targetIndex = yieldIndex
                isWrapping = true
            } else { // Fallback
                targetIndex = max(currentIndex - 1, 0)
            }
        }
        // --- Standard Phase Switching ---
        else if direction == .next {
            targetIndex = min(currentIndex + 1, availablePhases.count - 1)
        } else { // direction == .previous
            targetIndex = max(currentIndex - 1, 0)
        }

        // --- Apply Phase Change ---
        if targetIndex != currentIndex {
            let newPhase = availablePhases[targetIndex]

            // Reset the current page for the NEW phase to 0
            message.phaseCurrentPage[newPhase] = 0

            // Set wrapping state for special animation
            isWrappingAround = isWrapping

            // Use different animation for wrap-around
            let animation = isWrapping ?
                Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3) :
                Animation.spring(response: 0.3, dampingFraction: 0.8)

            withAnimation(animation) {
                viewModel.updateSelectedPhase(for: message, phase: newPhase)
                phaseRefreshCounter += 1 // Ensure refresh after phase change
            }

            // Reset wrapping state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isWrappingAround = false
            }
        }
    }

    // calculateAccurateTotalPages is removed.

}
