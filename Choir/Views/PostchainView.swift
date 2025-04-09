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
    init(message: Message, isProcessing: Bool, viewModel: PostchainViewModel, forceShowAllPhases: Bool = false, coordinator: RESTPostchainCoordinator? = nil, viewId: UUID = UUID()) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
        self.forceShowAllPhases = forceShowAllPhases
        self.coordinator = coordinator
        self.viewId = viewId
        // print("PostchainView initialized for message \(message.id)") // Reduced logging
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
                        messageId: message.id.uuidString
                    )
                    .frame(width: cardWidth)
                    .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                    .zIndex(phase == selectedPhase ? 1 : 0) // Bring selected card to front
                    .opacity(calculateOpacity(for: phase))
                    .id("\(viewId)_\(phase.rawValue)_\(message.content.count)_\(message.vectorSearchResults.count)_\(message.webSearchResults.count)") // Dynamic ID
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.updateSelectedPhase(for: message, phase: phase)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
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
    }
}

#Preview {
    let previewCoordinator = RESTPostchainCoordinator()
    let previewViewModel = PostchainViewModel(coordinator: previewCoordinator)

    let testMessage = Message(
        content: "This is the action phase content.",
        isUser: false,
        phaseResults: [
            .action: PhaseResult(content: "Action content here", provider: "google", modelName: "gemini-flash"),
            .experienceVectors: PhaseResult(content: "Synthesized vector docs", provider: "openai", modelName: "gpt-4"),
            .experienceWeb: PhaseResult(content: "Synthesized web results", provider: "anthropic", modelName: "claude-3"),
            .yield: PhaseResult(content: "Final yield response", provider: "google", modelName: "gemini-pro")
        ]
    )
    testMessage.vectorSearchResults = [
        VectorSearchResult(content: "Relevant content from vector DB.", score: 0.85, provider: "qdrant", metadata: nil),
        VectorSearchResult(content: "Another piece of info.", score: 0.81, provider: "qdrant", metadata: nil)
    ]
    testMessage.webSearchResults = [
        SearchResult(title: "Web Result 1", url: "https://example.com/1", content: "Snippet from web result 1...", provider: "brave_search"),
        SearchResult(title: "Web Result 2", url: "https://example.com/2", content: "Snippet from web result 2...", provider: "brave_search")
    ]

    return PostchainView(
        message: testMessage,
        isProcessing: false,
        viewModel: previewViewModel,
        forceShowAllPhases: true,
        coordinator: previewCoordinator,
        viewId: UUID()
    )
    .frame(height: 400)
    .padding()
}
