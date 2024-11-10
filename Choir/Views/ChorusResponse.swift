import SwiftUI

struct ChorusResponse: View {
    enum Phase: CaseIterable {
        case action
        case experience
        case intention
        case observation
        case understanding
        case yield

        var symbol: String {
            switch self {
            case .action: "bolt.fill"         // Immediate response
            case .experience: "book.fill"      // Prior knowledge
            case .intention: "target"          // Goal analysis
            case .observation: "eye.fill"      // Pattern recognition
            case .understanding: "brain"       // Deep thinking
            case .yield: "checkmark.circle"    // Final synthesis
            }
        }
    }

    @State private var selectedPhase: Phase = .action
    let responses: [Phase: String]

    var body: some View {
        VStack(alignment: .leading) {
            // Phase selector - only show phases with content
            HStack(spacing: 0) {
                ForEach(Phase.allCases.filter { responses[$0] != nil }, id: \.self) { phase in
                    PhaseTab(phase: phase,
                            isSelected: phase == selectedPhase,
                            action: { selectedPhase = phase })
                    if phase != Phase.allCases.last {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Phase content
            if let content = responses[selectedPhase] {
                Text(content)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut, value: selectedPhase)
            }
        }
        .onChange(of: responses) { newResponses in
            // Only auto-select yield when it becomes available
            if newResponses[.yield] != nil {
                selectedPhase = .yield
            } else if selectedPhase == .yield {
                // Reset to action if yield is no longer available
                selectedPhase = .action
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PhaseTab: View {
    let phase: ChorusResponse.Phase
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: phase.symbol)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? Color.blue : Color.clear)
        }
    }
}

#Preview {
    ChorusResponse(responses: [
        .action: "Direct response to query",
        .experience: "Related prior knowledge",
        .intention: "Goal analysis",
        .observation: "Pattern recognition",
        .understanding: "Deeper implications",
        .yield: "Final synthesized response"
    ])
    .padding()
}
