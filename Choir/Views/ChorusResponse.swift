import SwiftUI

struct ChorusResponse: View {
    @StateObject private var viewModel: ChorusViewModel
    @State private var input = ""

    init() {
        // Create a mock coordinator for preview/testing
        #if DEBUG
        _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: MockChorusCoordinator()))
        #else
        // Create REST coordinator for production
        let coordinator = RESTChorusCoordinator()
        _viewModel = StateObject(wrappedValue: ChorusViewModel(coordinator: coordinator))
        #endif
    }

    var body: some View {
        VStack {
            // Phase tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Phase.allCases) { phase in
                        PhaseTab(phase: phase,
                                isActive: phase == viewModel.currentPhase,
                                hasResponse: viewModel.responses[phase] != nil)
                    }
                }
                .padding(.horizontal)
            }

            // Response area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Phase.allCases) { phase in
                        if let response = viewModel.responses[phase] {
                            ResponseCard(phase: phase, content: response)
                        }
                    }
                }
                .padding()
            }

            // Input area
            HStack {
                TextField("Enter message", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isProcessing)

                if viewModel.isProcessing {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("Send") {
                        guard !input.isEmpty else { return }
                        let content = input
                        input = ""

                        Task {
                            do {
                                try await viewModel.process(content)
                            } catch {
                                print("Error processing message: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

struct PhaseTab: View {
    let phase: Phase
    let isActive: Bool
    let hasResponse: Bool

    var body: some View {
        VStack {
            Image(systemName: phase.symbol)
                .foregroundColor(isActive ? .accentColor : .gray)

            Text(phase.description)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .opacity(hasResponse || isActive ? 1 : 0.5)
    }
}

struct ResponseCard: View {
    let phase: Phase
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: phase.symbol)
                Text(phase.description)
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.accentColor)

            Text(content)
                .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ChorusResponse()
}
