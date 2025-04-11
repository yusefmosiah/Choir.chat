import SwiftUI
import Foundation

struct PhaseCardStackView: View {
    // Input properties
    let availablePhases: [Phase]
    @ObservedObject var message: Message
    let selectedPhase: Phase
    let dragOffset: CGFloat
    @ObservedObject var viewModel: PostchainViewModel
    let localThreadIDs: Set<UUID>
    let coordinator: RESTPostchainCoordinator?
    let viewId: UUID
    let cardWidth: CGFloat
    let totalWidth: CGFloat
    
    var body: some View {
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
                .offset(x: calculateOffset(for: phase))
                .zIndex(phase == selectedPhase ? 1 : 0)
                .opacity(calculateOpacity(for: phase))
                .id("\(viewId)_\(phase.rawValue)")
                .allowsHitTesting(phase == selectedPhase) // Disable taps on non-selected cards
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure card stack uses space
    }
    
    // MARK: - Helper Functions
    
    private func isLoadingPhase(_ phase: Phase) -> Bool {
        // If coordinator exists, ask it if the phase is processing
        if let coordinator = coordinator {
            return coordinator.isProcessingPhase(phase)
        }
        // Fallback: If processing globally and this phase has no content/results yet
        if viewModel.isProcessing {
            let phaseContent = message.getPhaseContent(phase)
            let hasTextContent = !phaseContent.isEmpty
            let hasVectorResults = (phase == .experienceVectors && !message.vectorSearchResults.isEmpty)
            let hasWebResults = (phase == .experienceWeb && !message.webSearchResults.isEmpty)
            return !(hasTextContent || hasVectorResults || hasWebResults)
        }
        return false
    }
    
    private func calculateOffset(for phase: Phase) -> CGFloat {
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
    // Mock data for preview
    let previewViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    let testMessage = Message(content: "Test message content", isUser: false)
    
    return PhaseCardStackView(
        availablePhases: Phase.allCases,
        message: testMessage,
        selectedPhase: .action,
        dragOffset: 0,
        viewModel: previewViewModel,
        localThreadIDs: [],
        coordinator: nil,
        viewId: UUID(),
        cardWidth: 300,
        totalWidth: 350
    )
    .frame(height: 300)
    .padding()
}