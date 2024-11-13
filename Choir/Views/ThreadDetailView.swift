import SwiftUI

struct ThreadDetailView: View {
    let thread: Thread
    @ObservedObject var viewModel: ChorusViewModel
    @State private var input = ""
    @State private var processingMessage: String = ""

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(thread.messages) { message in
                        MessageRow(
                            message: message,
                            isProcessing: message == thread.messages.last && viewModel.isProcessing,
                            viewModel: viewModel
                        )
                    }
                }
                .padding()
            }

            HStack {
                TextField("Message", text: $input)
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
                        let messageContent = input
                        processingMessage = "Processing: \(messageContent)"

                        // Add user message
                        thread.addMessage(messageContent)

                        // Add placeholder AI message immediately
                        thread.addMessage("...", isUser: false)

                        Task {
                            await sendMessage(messageContent)
                            processingMessage = ""
                        }
                        input = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle(thread.title)
    }

    private func sendMessage(_ content: String) async {
        do {
            try await viewModel.process(content)

            if let yieldResponse = viewModel.yieldResponse,
               var lastMessage = thread.messages.last {
                lastMessage.content = yieldResponse.content
                lastMessage.chorusResult = MessageChorusResult(
                    phases: viewModel.responses
                )
                thread.messages[thread.messages.count - 1] = lastMessage
            }
        } catch {
            print("Error processing message: \(error)")
        }
    }
}

#Preview {
    ThreadDetailView(
        thread: Thread(title: "Preview Thread"),
        viewModel: ChorusViewModel(coordinator: MockChorusCoordinator())
    )
}
