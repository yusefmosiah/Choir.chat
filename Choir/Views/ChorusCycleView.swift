import SwiftUI

struct ChorusCycleView: View {
    let phases: [Phase: String]
    let metadata: [Phase: ResponseMetadata]
    let isProcessing: Bool
    @State private var selectedPhase: Phase = .action
    @State private var showingMetadata: Bool = false
    @State private var longPressPhase: Phase?

    private let tabWidth: CGFloat = UIScreen.main.bounds.width * 0.85 / CGFloat(Phase.allCases.count)

    var body: some View {
        VStack(spacing: 0) {
            // Phase tabs
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
            .padding(.vertical, 4)

            Divider()

            // Content area
            if let content = phases[selectedPhase] {
                Text(content)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onLongPressGesture {
                        longPressPhase = selectedPhase
                        showingMetadata = true
                    }
            } else if isProcessing {
                HStack {
                    ProgressView()
                    Text("Processing...")
                }
                .padding()
            }
        }
        .onChange(of: phases) { newPhases in
            if newPhases[.yield] != nil {
                selectedPhase = .yield
            }
        }
        .sheet(isPresented: $showingMetadata) {
            if let phase = longPressPhase,
               let metadata = metadata[phase] {
                MetadataView(phase: phase, metadata: metadata)
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

struct MetadataView: View {
    let phase: Phase
    let metadata: ResponseMetadata
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let reasoning = metadata.reasoning {
                        MetadataSection(title: "Reasoning", content: reasoning)
                    }
                    if let synthesis = metadata.synthesis {
                        MetadataSection(title: "Synthesis", content: synthesis)
                    }
                    if let nextAction = metadata.next_action {
                        MetadataSection(title: "Next Action", content: nextAction)
                    }
                    if let nextPrompt = metadata.next_prompt {
                        MetadataSection(title: "Next Prompt", content: nextPrompt)
                    }
                }
                .padding()
            }
            .navigationTitle("\(phase.description) Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MetadataSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
    }
}

#Preview {
    ChorusCycleView(
        phases: [
            .action: "I understand you said...",
            .experience: "Based on my experience...",
            .yield: "Here's my response..."
        ],
        metadata: [
            .action: ResponseMetadata(
                reasoning: "Some reasoning...",
                synthesis: "Some synthesis...",
                next_action: nil,
                next_prompt: nil
            )
        ],
        isProcessing: false
    )
}
