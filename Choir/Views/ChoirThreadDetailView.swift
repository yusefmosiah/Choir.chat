import SwiftUI

struct ChoirThreadDetailView: View {
   let thread: ChoirThread
   @ObservedObject var viewModel: PostchainViewModel
   @State private var input = ""

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
                       // Let SwiftUI handle the updates naturally
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
       .onDisappear {
           cleanup()
       }
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

           // Add placeholder AI message with pre-initialized phases
           // This ensures all phase cards are properly rendered from the start
           var emptyPhases: [Phase: String] = [:]
           
           // Initialize all possible phases to ensure cards render properly
           for phase in Phase.allCases {
               emptyPhases[phase] = ""
           }
           
           // Create the message with pre-initialized phases
           var placeholderMessage = Message(
               content: "...",
               isUser: false,
               phases: emptyPhases,
               isStreaming: true
           )
           
           // Add it to the thread
           thread.messages.append(placeholderMessage)
           
           // Add a proper observer using @ObservedObject to automatically update when viewModel changes
           // The @ObservedObject on the viewModel parameter ensures this happens automatically now

           // Process the input and keep track of responses
           try await viewModel.process(content)
           
           // Update the placeholder message with the final response
           if let lastIndex = thread.messages.indices.last {
               // First notify that we're about to change the thread's messages
               // This needs to happen BEFORE the change to ensure SwiftUI updates properly
               thread.objectWillChange.send()
               
               // Make sure to preserve all phases in the message
               var updatedMessage = thread.messages[lastIndex]
               
               // Copy all phases from the viewModel to ensure they're properly stored
               let allPhases = viewModel.responses
               
               // Update phases directly
               updatedMessage.phases = allPhases
               updatedMessage.isStreaming = false
               
               // Select the most appropriate content for display
               if let experienceContent = allPhases[.experience], !experienceContent.isEmpty {
                   updatedMessage.content = experienceContent
               } else if let actionContent = allPhases[.action], !actionContent.isEmpty {
                   updatedMessage.content = actionContent
               }
               
               // Update the message with all phase content preserved
               thread.messages[lastIndex] = updatedMessage
           }
       } catch {
           // Handle errors appropriately
           print("Error processing message: \(error)")
       }
   }
   
   // Clean up when the view disappears
   private func cleanup() {
       // No more timers to cleanup
   }
}

#Preview {
   ChoirThreadDetailView(
       thread: ChoirThread(title: "Preview Thread"),
       viewModel: PostchainViewModel(coordinator: RESTPostchainCoordinator())
   )
}
