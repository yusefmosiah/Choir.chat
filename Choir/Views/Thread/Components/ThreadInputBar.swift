import SwiftUI

struct ThreadInputBar: View {
    @Binding var input: String
    let isProcessing: Bool
    let onSend: (String) async -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack {
            TextField("Message", text: $input)
                .textFieldStyle(.roundedBorder)
                .disabled(isProcessing)

            if isProcessing {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            } else {
                Button("Send") {
                    guard !input.isEmpty else { return }
                    let messageContent = input
                    input = "" // Clear input immediately

                    Task {
                        await onSend(messageContent)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
    
