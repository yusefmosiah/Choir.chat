import SwiftUI

struct ChorusCycleView: View {
    let phases: [Phase: String]
    let isProcessing: Bool
    @State private var selectedPhase: Phase = .action
    @State private var showingMetadata: Bool = false
    @State private var longPressPhase: Phase?

    private let tabWidth: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            // Phase tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(Phase.allCases) { phase in
                        PhaseTabButton(
                            phase: phase,
                            isSelected: phase == selectedPhase,
                            isEnabled: phases[phase] != nil,
                            width: tabWidth
                        ) {
                            if phases[phase] != nil {
                                selectedPhase = phase
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)

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
                selectedPhase = .yield
            }
        }
    }
}

struct PhaseTabButton: View {
    let phase: Phase
    let isSelected: Bool
    let isEnabled: Bool
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: phase.symbol)
                .imageScale(.small)
                .frame(width: width, height: 32)
        }
        .foregroundColor(isEnabled ? (isSelected ? .accentColor : .primary) : .gray.opacity(0.5))
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(Circle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
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
