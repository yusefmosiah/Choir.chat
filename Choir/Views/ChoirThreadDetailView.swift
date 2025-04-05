import SwiftUI

struct ChoirThreadDetailView: View {
   @ObservedObject var thread: ChoirThread
   @ObservedObject var viewModel: PostchainViewModel
   @State private var input = ""
   @Namespace private var scrollSpace
   @State private var lastMessageId: String? = nil
   @State private var scrollToBottom = false
   @State private var showModelConfig = false
   @State private var isLoadingMessages = false
   @State private var errorMessage: String? = nil
   @State private var isFirstMessage = true
   @State private var userId = UserDefaults.standard.string(forKey: "userUUID") ?? UUID().uuidString

   var body: some View {
       VStack {
           ScrollViewReader { scrollProxy in
               ScrollView {
                   LazyVStack(alignment: .leading, spacing: 12) {
                       ForEach(thread.messages) { message in
                           MessageRow(
                               message: message,
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
       .task {
           isLoadingMessages = true
           errorMessage = nil
           isFirstMessage = thread.messages.isEmpty
           
           do {
               let fetchedMessages = try await ChoirAPIClient.shared.fetchMessages(threadId: thread.id.uuidString)
               let newMessages = fetchedMessages.map { response in
                   Message(
                       id: UUID(uuidString: response.id) ?? UUID(),
                       content: response.content,
                       isUser: response.role == "user",
                       timestamp: ISO8601DateFormatter().date(from: response.timestamp) ?? Date()
                   )
               }
               await MainActor.run {
                   thread.messages = newMessages
                   isLoadingMessages = false
                   isFirstMessage = thread.messages.isEmpty
               }
           } catch {
               await MainActor.run {
                   errorMessage = error.localizedDescription
                   isLoadingMessages = false
               }
           }
       }
   }

   private func sendMessage(_ content: String) async {
       do {
           // Check if this is the first message in a thread and ensure the thread exists in Qdrant
           if isFirstMessage {
               // Ensure we have a user ID
               if userId.isEmpty {
                   userId = UUID().uuidString
                   UserDefaults.standard.set(userId, forKey: "userUUID")
               }
               
               // Create the thread in Qdrant via API
               do {
                   let threadResponse = try await ChoirAPIClient.shared.createThread(
                       name: thread.title,
                       userId: userId,
                       initialMessage: content
                   )
                   
                   // Update the thread ID with the one from the server
                   if let threadId = UUID(uuidString: threadResponse.id) {
                       print("Thread created in Qdrant with ID: \(threadId)")
                       // Note: ideally we'd update the thread.id here, but it's a let property
                       // Instead, we'll make sure to use the same ID in future requests
                   }
                   
                   isFirstMessage = false
               } catch {
                   print("Error creating thread in Qdrant: \(error)")
                   // Continue with local processing even if thread creation fails
               }
           }
           
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
