import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct PhaseCardContextMenu: View {
    let phase: Phase
    @ObservedObject var message: Message
    @Binding var currentPage: Int
    let availableSize: CGSize

    var body: some View {
        // Get phase result data
        let phaseResult = message.getPhaseResult(phase)
        let modelName = phaseResult?.modelName
        let provider = phaseResult?.provider

        VStack(alignment: .leading) {
            // Display model name with provider if both are available, otherwise fallback to phase description
            if let provider = provider, !provider.isEmpty {
                if let modelName = modelName, !modelName.isEmpty {
                    Text("Model: \(provider), \(modelName)")
                } else {
                    Text("Model: \(provider)")
                }
            } else if let modelName = modelName, !modelName.isEmpty {
                Text("Model: \(modelName)")
            } else {
                Text("Model: \(phase.description)")
            }

            Text("Page: \(currentPage + 1)")

            Button {
                let content = message.getPhaseContent(phase)
                UIPasteboard.general.string = content
            } label: {
                Label("Copy Entire Phase Content", systemImage: "doc.on.doc")
            }

            Button {
                let content = message.getPhaseContent(phase)
                TextSelectionManager.shared.showSheet(withText: content)
            } label: {
                Label("Select Entire Phase Content", systemImage: "text.cursor")
            }
        }
        .onAppear {
            // Detailed debugging for model name issues
            print("PhaseCardContextMenu - Phase: \(phase.rawValue)")

            if let result = phaseResult {
                print("  PhaseResult found")

                if let provider = result.provider {
                    print("  Provider: \(provider)")
                } else {
                    print("  Provider: nil")
                }

                if let modelName = result.modelName {
                    print("  ModelName: \(modelName)")
                } else {
                    print("  ModelName: nil")
                }

                // Which display condition was used
                if let provider = provider, !provider.isEmpty, let modelName = modelName, !modelName.isEmpty {
                    print("  Display condition: provider and modelName")
                } else if let modelName = modelName, !modelName.isEmpty {
                    print("  Display condition: modelName only")
                } else if let provider = provider, !provider.isEmpty {
                    print("  Display condition: provider only")
                } else {
                    print("  Display condition: fallback to phase description")
                }
            } else {
                print("  No PhaseResult found")
            }
        }
    }
}
