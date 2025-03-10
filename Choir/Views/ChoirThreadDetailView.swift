import SwiftUI

struct ChoirThreadDetailView: View {
   let thread: ChoirThread
   @ObservedObject var viewModel: PostchainViewModel
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
                       input = "" // Clear input immediately

                       Task {
                           await sendMessage(messageContent)
                       }
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
           // Set the current thread in the coordinator
           if let restCoordinator = viewModel.coordinator as? RESTPostchainCoordinator {
               restCoordinator.currentChoirThread = thread
           }

           // Add user message
           let userMessage = Message(
               content: content,
               isUser: true
           )
           thread.messages.append(userMessage)

           // Add placeholder AI message
           var placeholderMessage = Message(
               content: "...",
               isUser: false
           )
           thread.messages.append(placeholderMessage)

           try await viewModel.process(content)

           // Update the placeholder message with the final response
           if let lastIndex = thread.messages.indices.last {
               thread.messages[lastIndex] = viewModel.updateMessage(thread.messages[lastIndex])
           }
       } catch {
           print("Error processing message: \(error)")
       }
   }
}

#Preview {
   ChoirThreadDetailView(
       thread: ChoirThread(title: "Preview Thread"),
       viewModel: PostchainViewModel(coordinator: MockPostchainCoordinator())
   )
}
