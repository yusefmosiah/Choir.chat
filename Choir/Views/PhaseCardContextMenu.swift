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
            // Simplified display logic
            if let provider = provider, !provider.isEmpty {
                Text("Model: \(provider)")
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
            print("🧩 CONTEXT MENU DEBUG: ========== PHASE \(phase.rawValue) ==========")
            print("🧩 CONTEXT MENU DEBUG: PhaseResult exists: \(phaseResult != nil)")
            
            if let result = phaseResult {
                print("🧩 CONTEXT MENU DEBUG: Raw values in PhaseResult:")
                print("🧩 CONTEXT MENU DEBUG:   - provider: \"\(result.provider ?? "nil")\"")
                print("🧩 CONTEXT MENU DEBUG:   - modelName: \"\(result.modelName ?? "nil")\"")
                
                if let provider = result.provider {
                    print("🧩 CONTEXT MENU DEBUG:   - provider is empty: \(provider.isEmpty)")
                }
                
                if let modelName = result.modelName {
                    print("🧩 CONTEXT MENU DEBUG:   - modelName is empty: \(modelName.isEmpty)")
                }
                
                // Which display condition was used
                if let provider = provider, !provider.isEmpty, let modelName = modelName, !modelName.isEmpty {
                    print("🧩 CONTEXT MENU DEBUG: DISPLAYED: provider/model: \"\(provider)/\(modelName)\"")
                } else if let modelName = modelName, !modelName.isEmpty {
                    print("🧩 CONTEXT MENU DEBUG: DISPLAYED: model only: \"\(modelName)\"")
                } else if let provider = provider, !provider.isEmpty {
                    print("🧩 CONTEXT MENU DEBUG: DISPLAYED: provider only: \"\(provider)\"")
                } else {
                    print("🧩 CONTEXT MENU DEBUG: DISPLAYED: fallback description: \"\(phase.description)\"")
                }
            } else {
                print("🧩 CONTEXT MENU DEBUG: No PhaseResult available")
            }
            print("🧩 CONTEXT MENU DEBUG: ====================================")
        }
    }
}