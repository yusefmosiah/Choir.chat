import SwiftUI

struct ChorusCycleView: View {
    let phases: [Phase: String]
    let isProcessing: Bool
    @State private var selectedPhase: Phase = .action
    @State private var dragOffset: CGFloat = 0

    // Optional coordinator to check processing status
    var coordinator: RESTChorusCoordinator?

    // Computed property to get available phases in order
    private var availablePhases: [Phase] {
        Phase.allCases.filter { phases[$0] != nil }
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.9
            let sideCardWidth = geometry.size.width * 0.1
            let totalWidth = geometry.size.width

            VStack(spacing: 0) {
                // Phase carousel
                ZStack {
                    ForEach(Phase.allCases) { phase in
                        if let content = phases[phase] {
                            // Phase has content
                            PhaseCard(
                                phase: phase,
                                content: content,
                                isSelected: phase == selectedPhase,
                                isLoading: false
                            )
                            .frame(width: cardWidth)
                            .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                            .zIndex(phase == selectedPhase ? 1 : 0)
                            .opacity(calculateOpacity(for: phase))
                        } else if isProcessing {
                            // Check if this is the next phase being processed
                            let isCurrentlyProcessing = coordinator?.isProcessingPhase(phase) ?? false
                            let isNextPhase = isNextPhaseToProcess(phase)

                            if isCurrentlyProcessing || isNextPhase {
                                PhaseCard(
                                    phase: phase,
                                    content: nil,
                                    isSelected: false,
                                    isLoading: true
                                )
                                .frame(width: cardWidth)
                                .offset(x: calculateOffset(for: phase, cardWidth: cardWidth, totalWidth: totalWidth))
                                .zIndex(0)
                                .opacity(0.7)
                            }
                        }
                    }
                }
                .frame(height: geometry.size.height * 0.8)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let predictedEndOffset = value.predictedEndTranslation.width
                            let threshold = cardWidth / 3

                            if abs(predictedEndOffset) > threshold {
                                let direction = predictedEndOffset > 0 ? -1 : 1
                                let currentIndex = availablePhases.firstIndex(of: selectedPhase) ?? 0
                                let targetIndex = currentIndex + direction

                                if targetIndex >= 0 && targetIndex < availablePhases.count {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedPhase = availablePhases[targetIndex]
                                        dragOffset = 0
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

                // Phase indicator
                HStack(spacing: 8) {
                    ForEach(Phase.allCases) { phase in
                        Circle()
                            .fill(phase == selectedPhase ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .opacity(phases[phase] != nil ? 1 : 0.3)
                    }
                }
                .padding(.top, 16)
            }
        }
        .onChange(of: phases) { _, newPhases in
            // Auto-select the latest phase when new content arrives
            if let latestPhase = availablePhases.last, latestPhase != selectedPhase {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPhase = latestPhase
                }
            }
        }
    }

    private func calculateOffset(for phase: Phase, cardWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase) else {
            // If no phase is selected yet, use the first available phase
            if let firstPhase = availablePhases.first,
               let firstIndex = availablePhases.firstIndex(of: firstPhase),
               let phaseIndex = availablePhases.firstIndex(of: phase) {
                let indexDifference = phaseIndex - firstIndex
                return CGFloat(indexDifference) * cardWidth + dragOffset
            }
            return totalWidth // Off-screen if not available
        }

        // If the phase is not in available phases but is being processed
        if !availablePhases.contains(phase) && isProcessing {
            if let lastPhase = availablePhases.last,
               let lastIndex = availablePhases.firstIndex(of: lastPhase) {
                // Position it after the last available phase
                let phaseIndex = Phase.allCases.firstIndex(of: phase) ?? 0
                let lastPhaseIndex = Phase.allCases.firstIndex(of: lastPhase) ?? 0

                if phaseIndex > lastPhaseIndex {
                    let indexDifference = (currentIndex - lastIndex) + (phaseIndex - lastPhaseIndex)
                    return CGFloat(indexDifference) * cardWidth + dragOffset
                }
            }
            return totalWidth // Off-screen if not available
        }

        // Normal case - phase is in available phases
        if let phaseIndex = availablePhases.firstIndex(of: phase) {
            let indexDifference = phaseIndex - currentIndex
            return CGFloat(indexDifference) * cardWidth + dragOffset
        }

        return totalWidth // Off-screen if not available
    }

    private func calculateOpacity(for phase: Phase) -> Double {
        guard let currentIndex = availablePhases.firstIndex(of: selectedPhase),
              let phaseIndex = availablePhases.firstIndex(of: phase) else {
            // If phase is being processed but not yet available
            if isProcessing && isNextPhaseToProcess(phase) {
                return 0.5
            }
            return 0
        }

        let indexDifference = abs(phaseIndex - currentIndex)

        if indexDifference == 0 {
            return 1
        } else if indexDifference == 1 {
            return 0.7
        } else {
            return 0.3
        }
    }

    private func isNextPhaseToProcess(_ phase: Phase) -> Bool {
        // If coordinator is available, use it to check
        if let coordinator = coordinator {
            return coordinator.isProcessingPhase(phase)
        }

        // Otherwise, guess based on available phases
        if let lastPhase = availablePhases.last,
           let lastIndex = Phase.allCases.firstIndex(of: lastPhase),
           let phaseIndex = Phase.allCases.firstIndex(of: phase) {
            return phaseIndex == lastIndex + 1
        }

        return false
    }
}

struct PhaseCard: View {
    let phase: Phase
    let content: String?
    let isSelected: Bool
    var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: phase.symbol)
                    .imageScale(.medium)
                    .foregroundColor(phase == .yield ? .white : .accentColor)

                Text(phase.description)
                    .font(.headline)
                    .foregroundColor(phase == .yield ? .white : .primary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.bottom, 4)

            if let content = content {
                ScrollView {
                    Text(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(phase == .yield ? .white : .primary)
                }
            } else if isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Text("Processing \(phase.description)...")
                            .foregroundColor(phase == .yield ? .white.opacity(0.8) : .secondary)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(phase == .yield
                      ? Color.accentColor
                      : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 8 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected
                        ? (phase == .yield ? Color.white : Color.accentColor)
                        : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1)
        )
        .padding(.horizontal, 8)
    }
}

extension Phase {
    var next: Phase? {
        guard let currentIndex = Phase.allCases.firstIndex(of: self),
              currentIndex + 1 < Phase.allCases.count else {
            return nil
        }
        return Phase.allCases[currentIndex + 1]
    }
}

#Preview {
    ChorusCycleView(
        phases: [
            .action: "I understand you said...",
            .experience: "Based on my experience...",
            .intention: "Your intention seems to be...",
            .yield: "Here's my response..."
        ],
        isProcessing: true
    )
    .frame(height: 500)
    .padding()
}
