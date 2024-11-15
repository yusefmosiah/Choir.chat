import SwiftUI

struct ChoirThreadDetailView: View {
    let thread: ChoirThread
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
                        let userMessage = Message(
                            content: messageContent,
                            isUser: true
                        )
                        thread.messages.append(userMessage)

                        // Add placeholder AI message immediately
                        let placeholderMessage = Message(
                            content: "...",
                            isUser: false
                        )
                        thread.messages.append(placeholderMessage)

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
            // Set the current thread in the coordinator before processing
            (viewModel.coordinator as? RESTChorusCoordinator)?.currentChoirThread = thread

            try await viewModel.process(content)

            if let yieldResponse = viewModel.yieldResponse,
               var lastMessage = thread.messages.last {
                // Update the placeholder message with the actual response
                lastMessage.content = yieldResponse.content
                lastMessage.chorusResult = MessageChorusResult(
                    phases: viewModel.responses
                )
                // Since messages is an array, we need to update the last element
                thread.messages[thread.messages.count - 1] = lastMessage
            }
        } catch {
            print("Error processing message: \(error)")
        }
    }
}

#Preview {
    ChoirThreadDetailView(
        thread: ChoirThread(title: "Preview Thread"),
        viewModel: ChorusViewModel(coordinator: MockChorusCoordinator())
    )
}
