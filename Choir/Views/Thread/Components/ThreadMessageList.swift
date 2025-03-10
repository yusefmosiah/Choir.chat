import SwiftUI

struct ThreadMessageList: View {
    let messages: [Message]
    let isProcessing: Bool
    let viewModel: PostchainViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(messages) { message in
                    MessageRow(
                        message: message,
                        isProcessing: message == messages.last && isProcessing,
                        viewModel: viewModel
                    )
                }
            }
            .padding()
        }
    }
}
