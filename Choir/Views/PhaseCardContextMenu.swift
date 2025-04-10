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
        VStack(alignment: .leading) {
            let modelName = message.getPhaseResult(phase)?.modelName
            Text("Model: \(modelName?.isEmpty == false ? modelName! : phase.description)")
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
    }
}
