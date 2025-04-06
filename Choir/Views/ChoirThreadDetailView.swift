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
   // @State private var isFirstMessage = true // Removed as per instructions
   @State private var userId = UserDefaults.standard.string(forKey: "userUUID") ?? UUID().uuidString // Keep for sending for now

   // Helper for date parsing
   let isoDateFormatter: ISO8601DateFormatter = {
       let formatter = ISO8601DateFormatter()
       // Allow for optional fractional seconds
       formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
       return formatter
   }()
   var body: some View {
       VStack {
           // Display loading indicator or error message
           if isLoadingMessages {
               ProgressView("Loading Messages...")
                   .padding()
           } else if let errorMsg = errorMessage {
               Text(errorMsg)
                   .foregroundColor(.red)
                   .padding()
           }

           ScrollViewReader { scrollProxy in
               ScrollView {
                   LazyVStack(alignment: .leading, spacing: 12) {
                       // Only show messages if not loading and no error prevented loading
                       // Or show messages even if there was an error but some were loaded before?
                       // Current approach: Show messages unless actively loading. Error text is separate.
                       ForEach(thread.messages) { message in
                           MessageRow(
                               message: message,
                               isProcessing: message.id == viewModel.coordinator.activeMessageId && viewModel.isProcessing, // Check activeMessageId
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
               TextField("Message", text: $input, axis: .vertical) // Allow vertical expansion
                   .textFieldStyle(.roundedBorder)
                   .lineLimit(1...5) // Allow up to 5 lines
                   .disabled(viewModel.isProcessing || isLoadingMessages) // Disable during message loading too

               if viewModel.isProcessing {
                   Button("Cancel") {
                       viewModel.cancel()
                   }
                   .buttonStyle(.borderedProminent)
                   .tint(.red)
               } else {
                   Button {
                       guard !input.isEmpty else { return }
                       let messageContent = input
                       input = ""

                       Task {
                           await sendMessage(messageContent)
                       }
                   } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2) // Make icon slightly larger
                   }
                   .buttonStyle(.plain) // Use plain style for icon button
                   .disabled(input.isEmpty || viewModel.isProcessing || isLoadingMessages) // Disable during message loading too
                   .keyboardShortcut(.return, modifiers: .command) // Cmd+Enter shortcut
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
       .task(id: thread.id) { // Rerun task when thread.id changes
            await loadMessages()
       }
   }

   private func loadMessages() async {
       guard !isLoadingMessages else {
           print("ℹ️ Already loading messages for \(thread.id), skipping.")
           return
       }

       let currentThreadId = self.thread.id // Capture the ID at the start

       print("🔄 Loading messages for thread \(currentThreadId)...")
       isLoadingMessages = true
       errorMessage = nil
       // isFirstMessage = thread.messages.isEmpty // Removed as per instructions

       do {
           // Fetch messages using the updated API client which returns [MessageResponse]
           let fetchedMessages: [MessageResponse] = try await ChoirAPIClient.shared.fetchMessages(threadId: currentThreadId.uuidString)
           print("✅ Fetched \(fetchedMessages.count) messages for thread \(currentThreadId)")

           // Map results carefully
           var newMessages: [Message] = []
           for response in fetchedMessages {
                // Directly access properties from the MessageResponse struct
                let respId = response.id
                let respContent = response.content
                let respRole = response.role
                let respTimestamp = response.timestamp
                let respPhaseOutputs = response.phaseOutputs

               let messageId = UUID(uuidString: respId ?? "") ?? UUID() // Default UUID if parsing fails
               let messageContent = respContent ?? ""
               let messageIsUser = respRole == "user" // Default to false if role is nil or different
               let messageTimestamp = isoDateFormatter.date(from: respTimestamp ?? "") ?? Date() // Default to now if parsing fails

               var messagePhaseResults: [Phase: PhaseResult] = [:]

               // Pre-initialize all phases with empty PhaseResult
               for phase in Phase.allCases {
                   messagePhaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
               }

               // Map phaseOutputs for AI messages
               if !messageIsUser {
                   if let phaseOutputs = respPhaseOutputs { // Check if phaseOutputs exists and is not nil
                       for (phaseString, phaseContent) in phaseOutputs {
                           if let phase = Phase.from(phaseString) {
                               messagePhaseResults[phase] = PhaseResult(content: phaseContent, provider: nil, modelName: nil)
                               // print("   Mapped phase '\(phaseString)' to \(phase.rawValue) for message \(messageId)")
                           } else {
                               print("   ⚠️ Could not map phase string '\(phaseString)' to Phase enum for message \(messageId)")
                           }
                       }
                   } else {
                        print("   ℹ️ No phaseOutputs found for AI message \(messageId)")
                   }

                   // Yield Fallback: If .yield is still empty, use main content
                   if messagePhaseResults[.yield]?.content.isEmpty ?? true {
                       messagePhaseResults[.yield] = PhaseResult(content: messageContent, provider: nil, modelName: nil)
                       // print("   Applied yield fallback using main content for message \(messageId)")
                   }
               }


               let message = Message(
                   id: messageId,
                   content: messageContent, // Keep original content here, MessageRow/PostchainView handles display logic
                   isUser: messageIsUser,
                   timestamp: messageTimestamp,
                   phaseResults: messagePhaseResults // Pass the mapped results
               )
               newMessages.append(message)
           }

           // --- Mapped Messages Check ---
           print("--- Mapped Messages Check (Thread: \(currentThreadId)) ---")
           for msg in newMessages {
               let phaseYieldContent = msg.getPhaseResult(.yield)?.content ?? "nil"
               print("  - ID: \(msg.id), User: \(msg.isUser), Content: \(msg.content.prefix(30))..., Yield: \(phaseYieldContent.prefix(30))...")
           }
           print("-------------------------------------")


           // Update UI on main thread, ensuring the thread context hasn't changed
           await MainActor.run {
               if currentThreadId == self.thread.id {
                   self.thread.messages = newMessages.sorted { $0.timestamp < $1.timestamp }
                   self.isLoadingMessages = false
                   // self.isFirstMessage = self.thread.messages.isEmpty // Update based on fetched - REMOVED as per instructions
                   print("✅ Updated thread.messages count: \(self.thread.messages.count) for thread \(currentThreadId)")
               } else {
                   print("⚠️ Thread changed (\(self.thread.id)) while loading messages for \(currentThreadId). Discarding results.")
                   self.isLoadingMessages = false // Still need to reset loading state
               }
           }

       } catch {
           print("❌ Error loading messages for thread \(currentThreadId): \(error)")
           // Check specifically for cancellation errors
           if (error as? URLError)?.code == .cancelled {
                print("ℹ️ Message loading cancelled for thread \(currentThreadId).")
                // Don't show cancellation error in the UI
                await MainActor.run {
                    // Only reset loading state if the thread context is still the same
                    if currentThreadId == self.thread.id {
                        self.isLoadingMessages = false
                        self.errorMessage = nil // Ensure no error message is shown for cancellation
                    } else {
                        print("⚠️ Thread changed during cancellation handling for \(currentThreadId). State already reset potentially.")
                    }
                }
           } else {
               // Show other errors in the UI
               await MainActor.run {
                    // Only update UI if the thread context is still the same
                    if currentThreadId == self.thread.id {
                       self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                       self.isLoadingMessages = false
                    } else {
                        print("⚠️ Thread changed before error could be displayed for \(currentThreadId).")
                        // We might still want to reset the loading state if it somehow wasn't reset
                        self.isLoadingMessages = false
                    }
               }
           }
       }
   }


   private func sendMessage(_ content: String) async {
       guard !isLoadingMessages else {
           print("⚠️ Attempted to send while loading messages. Aborting.")
           return // Prevent sending if messages are loading
       }
       // isFirstMessage logic removed entirely

       do {
           // User ID handling remains, assuming it's needed for sending
           if userId.isEmpty {
               userId = UUID().uuidString
               UserDefaults.standard.set(userId, forKey: "userUUID")
           }

           // Update coordinator reference
           if let restCoordinator = viewModel.coordinator as? RESTPostchainCoordinator {
               restCoordinator.currentChoirThread = thread
           }

           // Create and append user message locally
           let userMessage = Message(
               content: content,
               isUser: true
           )
            await MainActor.run {
                thread.messages.append(userMessage)
            }


           // Create and append placeholder AI message locally
           var placeholderMessage = Message(
               content: "...",
               isUser: false,
               isStreaming: true
           )
            await MainActor.run {
                thread.messages.append(placeholderMessage)
            }


           // Call backend processing (this now handles thread creation implicitly if needed)
           try await viewModel.process(content) // Assumes viewModel.process sends the message

           // Update placeholder message with results (existing logic seems okay)
            await MainActor.run {
                if let lastIndex = thread.messages.indices.last, thread.messages[lastIndex].id == placeholderMessage.id {
                    let message = thread.messages[lastIndex]

                    let allPhases = viewModel.responses // Assuming this holds the final results after process()

                    message.isStreaming = false
                    message.phases = allPhases // Update using the public setter

                    // Update main content based on priority (Yield > Experience > Action) - Keep this logic
                    if let yieldContent = allPhases[.yield], !yieldContent.isEmpty {
                        message.content = yieldContent
                    } else if let experienceContent = allPhases[.experience], !experienceContent.isEmpty {
                       message.content = experienceContent
                   } else if let actionContent = allPhases[.action], !actionContent.isEmpty {
                       message.content = actionContent
                   } else {
                       // Fallback if no prioritized phase has content
                       message.content = allPhases.values.first(where: { !$0.isEmpty }) ?? "..."
                   }

                    print("Updated placeholder message \(message.id) with final content.")

                } else {
                    print("⚠️ Could not find placeholder message to update after processing.")
                }
            }

       } catch {
           print("❌ Error processing message: \(error)")
           // Optionally remove the placeholder on error or display an error message
            await MainActor.run {
                if let lastMessage = thread.messages.last, !lastMessage.isUser, lastMessage.isStreaming {
                    thread.messages.removeLast()
                    // You could add a specific error message object here instead
                    // let errorMessage = Message(content: "Error: \(error.localizedDescription)", isUser: false)
                    // thread.messages.append(errorMessage)
                }
                // Display error to user?
                // self.errorMessage = "Error sending message: \(error.localizedDescription)"
            }
       }
   }

// Removed dummy MessageResponse struct placeholder

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
