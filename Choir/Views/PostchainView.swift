import SwiftUI
import Foundation

struct PostchainView: View {
    // MARK: - Properties
    
    // State
    @State private var initialSelectionDone = false
    
    // Unique identifier for this view instance to prevent state sharing
    let viewId: UUID

    // Reference to the specific message this view is displaying
    @ObservedObject var message: Message

    // Processing state (passed from parent, ChoirThreadDetailView)
    let isProcessing: Bool

    // ViewModel (passed down for potential subviews)
    @ObservedObject var viewModel: PostchainViewModel

    // Thread IDs
    let localThreadIDs: Set<UUID>
    
    // Force showing all phases even when not processing (e.g., for debugging)
    var forceShowAllPhases: Bool = false

    // Optional coordinator to check processing status (passed from parent)
    var coordinator: RESTPostchainCoordinator?

    // MARK: - Computed Properties
    
    // Computed property to get the selected phase from the message
    private var selectedPhase: Phase {
        get { message.selectedPhase }
        set { viewModel.updateSelectedPhase(for: message, phase: newValue) }
    }

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

    // MARK: - Initializer
    
    init(message: Message, isProcessing: Bool, viewModel: PostchainViewModel, localThreadIDs: Set<UUID>, forceShowAllPhases: Bool = false, coordinator: RESTPostchainCoordinator? = nil, viewId: UUID = UUID()) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
        self.localThreadIDs = localThreadIDs
        self.forceShowAllPhases = forceShowAllPhases
        self.coordinator = coordinator
        self.viewId = viewId
    }

    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.98 // Adjust card width slightly
            let totalWidth = geometry.size.width
            
            // Main container
            ZStack {
                // Create the card stack view with gesture handling
                PhaseGestureHandlerView(
                    content: { dragOffset in
                        PhaseCardStackView(
                            availablePhases: availablePhases,
                            message: message,
                            selectedPhase: selectedPhase,
                            dragOffset: dragOffset, // Pass the current drag offset
                            viewModel: viewModel,
                            localThreadIDs: localThreadIDs,
                            coordinator: coordinator,
                            viewId: viewId,
                            cardWidth: cardWidth,
                            totalWidth: totalWidth
                        )
                    },
                    message: message,
                    availablePhases: availablePhases,
                    viewModel: viewModel,
                    cardWidth: cardWidth
                )
            }
            .overlay {
                // Add pagination controls
                PhasePaginationControlView(
                    message: message,
                    availablePhases: availablePhases,
                    size: geometry.size,
                    onSwitchPhase: { direction in
                        switchToPhase(direction: direction)
                    }
                )
            }
        }
        .onAppear(perform: handleOnAppear)
        .id("postchain_view_\(message.id)_\(viewId)") // Stable ID for the view itself
        .frame(maxHeight: .infinity)
    }

    // MARK: - Helper Functions
    
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
            }
        }
    }

    // Define SwipeDirection enum
    enum SwipeDirection { case next, previous }
    
    // Phase switching logic
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

            // Reset the current page for the NEW phase
            message.phaseCurrentPage[newPhase] = 0
            
            viewModel.updateSelectedPhase(for: message, phase: newPhase)
        }
    }
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
