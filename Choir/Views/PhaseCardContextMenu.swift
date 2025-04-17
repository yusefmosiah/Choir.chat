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
            
            if let result = phaseResult {
                
                if let provider = result.provider {
                }
                
                if let modelName = result.modelName {
                }
                
                // Which display condition was used
                if let provider = provider, !provider.isEmpty, let modelName = modelName, !modelName.isEmpty {
                } else if let modelName = modelName, !modelName.isEmpty {
                } else if let provider = provider, !provider.isEmpty {
                } else {
                }
            } else {
            }
        }
    }
}