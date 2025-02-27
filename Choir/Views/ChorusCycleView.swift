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
            let cardWidth = geometry.size.width * 0.98
            let sideCardWidth = geometry.size.width * 0.1
            let totalWidth = geometry.size.width

            // Simplified to just the carousel without indicators
            ZStack {
                ForEach(Phase.allCases) { phase in
                    if let content = phases[phase] {
                        // Phase has content
                        PhaseCard(
                            phase: phase,
                            content: content,
                            isSelected: phase == selectedPhase,
                            isLoading: false,
                            priors: phase == .experience ? coordinator?.experienceResponse?.priors : nil
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
            .frame(height: geometry.size.height * 0.99) // Back to using full height
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
            .padding(.bottom, 16) // Add padding at the bottom of the carousel
        }
        // Remove the onChange handler completely since we want the user to control phase selection
        // If you want to only auto-select when starting from zero phases, you could modify it like this:
        .onChange(of: phases) { _, newPhases in
            // Only auto-select if this is the first phase being added
            if availablePhases.count == 1 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPhase = availablePhases[0]
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
    var priors: [String: Prior]? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: phase.symbol)
                    .imageScale(.large)
                    .foregroundColor(phase == .yield ? .white : .accentColor)

                Text(phase.description)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(phase == .yield ? .white : .primary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.bottom, 8)

            if let content = content {
                ScrollView {
                    Text(content)
                        .font(.body)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(phase == .yield ? .white : .primary)
                        .padding(.bottom, 4)

                    // Display priors if this is the experience phase and we have priors
                    if phase == .experience, let priors = priors, !priors.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Available Priors:")
                                .font(.headline)
                                .padding(.top, 12)
                                .foregroundColor(phase == .yield ? .white : .primary)

                            ForEach(Array(priors.keys.sorted()), id: \.self) { key in
                                if let prior = priors[key] {
                                    PriorCard(prior: prior, priorKey: key)
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 400)
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
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(phase == .yield
                      ? Color.accentColor
                      : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.1),
                        radius: isSelected ? 10 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected
                        ? (phase == .yield ? Color.white : Color.accentColor)
                        : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2.5 : 1)
        )
        .padding(.horizontal, 4)
        .padding(.bottom, 0)
    }
}

struct PriorCard: View {
    let prior: Prior
    let priorKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prior ID: \(priorKey)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Similarity: \(Int(prior.similarity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(prior.content)
                .font(.body)
                .lineLimit(3)

            HStack {
                if let threadID = prior.threadID {
                    Text("Thread: \(threadID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let step = prior.step {
                    Text("Phase: \(step)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let createdAt = prior.createdAt {
                    Text("Created: \(formattedDate(createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
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
