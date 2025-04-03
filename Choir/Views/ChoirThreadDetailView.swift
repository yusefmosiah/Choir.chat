import SwiftUI

struct ChoirThreadDetailView: View {
   let thread: ChoirThread
   @ObservedObject var viewModel: PostchainViewModel
   @State private var input = ""
   @Namespace private var scrollSpace
   @State private var lastMessageId: String? = nil
   @State private var scrollToBottom = false
   @State private var showModelConfig = false

   var body: some View {
       VStack {
           ScrollViewReader { scrollProxy in
               ScrollView {
                   LazyVStack(alignment: .leading, spacing: 12) {
                       ForEach(thread.messages) { message in
                           MessageRow(
                               message: message,
                               thread: thread, // Pass the thread down
                               isProcessing: message == thread.messages.last && viewModel.isProcessing,
                               viewModel: viewModel
                           )
                           .id(message.id)
                       }
                       Color.clear
                           .frame(height: 1)
                           .id("bottomScrollAnchor")
                   }
                   .padding()
               }
               .onChange(of: thread.messages.count) { _, _ in
                   withAnimation(.easeOut(duration: 0.3)) {
                       scrollProxy.scrollTo("bottomScrollAnchor", anchor: .bottom)
                   }
               }
               .onChange(of: viewModel.responses) { _, _ in
                   if let lastMessage = thread.messages.last, !lastMessage.isUser {
                       withAnimation(.easeOut(duration: 0.3)) {
                           scrollProxy.scrollTo("bottomScrollAnchor", anchor: .bottom)
                       }
                   }
               }
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
                       input = ""

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
       .toolbar {
           ToolbarItem(placement: .topBarTrailing) {
               Button(action: {
                   showModelConfig = true
               }) {
                   Label("Configure Models", systemImage: "gear")
               }
           }
       }
       .sheet(isPresented: $showModelConfig) {
           ModelConfigView(thread: thread)
       }
       .onDisappear {
           cleanup()
       }
   }

   private func sendMessage(_ content: String) async {
       do {
           if let restCoordinator = viewModel.coordinator as? RESTPostchainCoordinator {
               restCoordinator.currentChoirThread = thread
           }

           let userMessage = Message(
               content: content,
               isUser: true
           )
           thread.messages.append(userMessage)

           var emptyPhases: [Phase: String] = [:]

           for phase in Phase.allCases {
               emptyPhases[phase] = ""
           }

           var placeholderMessage = Message(
               content: "...",
               isUser: false,
               phases: emptyPhases,
               isStreaming: true
           )

           thread.messages.append(placeholderMessage)

           try await viewModel.process(content)

           if let lastIndex = thread.messages.indices.last {
               let message = thread.messages[lastIndex]

               let allPhases = viewModel.responses

               message.isStreaming = false

               message.phases = allPhases

               if let experienceContent = allPhases[.experience], !experienceContent.isEmpty {
                   message.content = experienceContent
               } else if let actionContent = allPhases[.action], !actionContent.isEmpty {
                   message.content = actionContent
               }
           }
       } catch {
           print("Error processing message: \(error)")
       }
   }

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
