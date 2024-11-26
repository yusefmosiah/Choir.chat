import SwiftUI

struct ChorusCycleView: View {
    let phases: [Phase: String]
    let isProcessing: Bool
    @State private var selectedPhase: Phase = .action
    @State private var showingMetadata: Bool = false
    @State private var longPressPhase: Phase?
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let phaseWidth: CGFloat = 60
    private let spacing: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // Phase carousel
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let centerX = totalWidth / 2

                HStack(spacing: spacing) {
                    ForEach(Phase.allCases) { phase in
                        PhaseTabButton(
                            phase: phase,
                            isSelected: phase == selectedPhase,
                            isEnabled: phases[phase] != nil,
                            width: phaseWidth
                        )
                        .id(phase)
                    }
                }
                .offset(x: centerX - phaseWidth/2 + calculateOffset())
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let predictedEndOffset = value.predictedEndTranslation.width
                            let phaseStep = phaseWidth + spacing

                            // Calculate the number of phases to move
                            let stepCount = (predictedEndOffset / phaseStep).rounded()
                            let currentIndex = Phase.allCases.firstIndex(of: selectedPhase) ?? 0
                            let targetIndex = max(0, min(Phase.allCases.count - 1, currentIndex - Int(stepCount)))

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if let newPhase = Phase.allCases[safe: targetIndex], phases[newPhase] != nil {
                                    selectedPhase = newPhase
                                }
                                offset = 0
                            }
                        }
                )
            }
            .frame(height: 60)

            Divider()

            // Content area
            if let content = phases[selectedPhase] {
                Text(content)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if isProcessing {
                HStack {
                    ProgressView()
                    Text("Processing...")
                }
                .padding()
            }
        }
        .onChange(of: phases) { _, newPhases in
            if newPhases[.yield] != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPhase = .yield
                }
            }
        }
    }

    private func calculateOffset() -> CGFloat {
        let phaseStep = phaseWidth + spacing
        let currentIndex = Phase.allCases.firstIndex(of: selectedPhase) ?? 0
        return -CGFloat(currentIndex) * phaseStep + dragOffset
    }
}

struct PhaseTabButton: View {
    let phase: Phase
    let isSelected: Bool
    let isEnabled: Bool
    let width: CGFloat

    var body: some View {
        Image(systemName: phase.symbol)
            .imageScale(.small)
            .frame(width: width, height: 32)
            .foregroundColor(isEnabled ? (isSelected ? .accentColor : .primary) : .gray.opacity(0.5))
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(Circle())
            .opacity(isEnabled ? 1 : 0.5)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ChorusCycleView(
        phases: [
            .action: "I understand you said...",
            .experience: "Based on my experience...",
            .yield: "Here's my response..."
        ],
        isProcessing: false
    )
}
