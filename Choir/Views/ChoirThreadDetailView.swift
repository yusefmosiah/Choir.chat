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
   @State private var userId = UserDefaults.standard.string(forKey: "userUUID") ?? UUID().uuidString

   // Helper for date parsing
   let isoDateFormatter: ISO8601DateFormatter = {
       let formatter = ISO8601DateFormatter()
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
                       ForEach(thread.messages) { message in
                           MessageRow(
                               message: message,
                               isProcessing: message.id == viewModel.coordinator.activeMessageId && viewModel.isProcessing,
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
               TextField("Message", text: $input, axis: .vertical)
                   .textFieldStyle(.roundedBorder)
                   .lineLimit(1...5)
                   .disabled(viewModel.isProcessing || isLoadingMessages)

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
                            .font(.title2)
                   }
                   .buttonStyle(.plain)
                   .disabled(input.isEmpty || viewModel.isProcessing || isLoadingMessages)
                   .keyboardShortcut(.return, modifiers: .command)
               }
           }
           .padding()
       }
       .navigationTitle(thread.title)
       .toolbar {
           ToolbarItem(placement: .topBarTrailing) {
               Button(action: { showModelConfig = true }) {
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
       .task(id: thread.id) {
            await loadMessages()
       }
   }

   private func loadMessages() async {
       guard !isLoadingMessages else {
           print("ℹ️ Already loading messages for \(thread.id), skipping.")
           return
       }

       let currentThreadId = self.thread.id
       print("🔄 Loading messages for thread \(currentThreadId)...")
       isLoadingMessages = true
       errorMessage = nil

       do {
           // Fetch turn records using the updated API client which returns [TurnResponse]
           let fetchedTurns: [TurnResponse] = try await ChoirAPIClient.shared.fetchMessages(threadId: currentThreadId.uuidString)
           print("✅ Fetched \(fetchedTurns.count) turns for thread \(currentThreadId)")

           var reconstructedMessages: [Message] = [] // This will store the reconstructed User/AI messages for UI
           for turn in fetchedTurns {
               // Attempt to parse the timestamp for the turn
               let turnTimestamp = isoDateFormatter.date(from: turn.timestamp ?? "") ?? Date()

               // 1. Create User Message from turn.userQuery (if present)
               if let userQuery = turn.userQuery, !userQuery.isEmpty {
                   let userMessageId = UUID(uuidString: turn.id + "-user") ?? UUID()
                   let userTimestamp = turnTimestamp.addingTimeInterval(-0.001) // Offset user msg slightly earlier

                   let userMessage = Message(
                       id: userMessageId,
                       content: userQuery,
                       isUser: true,
                       timestamp: userTimestamp
                   )
                   reconstructedMessages.append(userMessage)
               }

               // 2. Create AI Message from turn.content and turn.phaseOutputs
               let aiMessageId = UUID(uuidString: turn.id) ?? UUID()
               let aiContent = turn.content ?? ""
               var aiPhaseResults: [Phase: PhaseResult] = [:]

               // Pre-initialize all phases
               for phase in Phase.allCases {
                   aiPhaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
               }

               // Map phaseOutputs
               if let phaseOutputs = turn.phaseOutputs {
                   for (phaseString, phaseContent) in phaseOutputs {
                       if let phase = Phase.from(phaseString) {
                           aiPhaseResults[phase] = PhaseResult(content: phaseContent, provider: nil, modelName: nil)
                       } else {
                           print("   ⚠️ Could not map phase string '\(phaseString)' to Phase enum for turn \(turn.id)")
                       }
                   }
               } else {
                    print("   ℹ️ No phaseOutputs dictionary found for turn \(turn.id), attempting yield fallback.")
               }

                // Yield Fallback
                if aiPhaseResults[.yield]?.content.isEmpty ?? true {
                    if !aiContent.isEmpty {
                        aiPhaseResults[.yield] = PhaseResult(content: aiContent, provider: nil, modelName: nil)
                    } else if turn.phaseOutputs == nil {
                        print("   ⚠️ Both phaseOutputs and main content are empty/null for turn \(turn.id). Yield phase will be empty.")
                    }
                }

               let aiMessage = Message(
                   id: aiMessageId,
                   content: aiContent,
                   isUser: false,
                   timestamp: turnTimestamp, // Use original turn timestamp
                   phaseResults: aiPhaseResults
               )
               reconstructedMessages.append(aiMessage)
           }

           // Sort the combined user/AI messages strictly by timestamp
           reconstructedMessages.sort { $0.timestamp < $1.timestamp }

           // --- Mapped Messages Check ---
           print("--- Reconstructed Messages Check (Thread: \(currentThreadId)) ---")
           for msg in reconstructedMessages {
                print("  - ID: \(msg.id), User: \(msg.isUser), Timestamp: \(msg.timestamp), Content: \(msg.content.prefix(30))...")
           }
           print("-------------------------------------")


           // Update UI on main thread, ensuring the thread context hasn't changed
           await MainActor.run {
               if currentThreadId == self.thread.id {
                   self.thread.messages = reconstructedMessages // Assign the reconstructed list
                   self.isLoadingMessages = false
                   print("✅ Updated thread.messages count: \(self.thread.messages.count) for thread \(currentThreadId)")
               } else {
                   print("⚠️ Thread changed (\(self.thread.id)) while loading messages for \(currentThreadId). Discarding results.")
                   self.isLoadingMessages = false
               }
           }

       } catch {
           print("❌ Error loading messages for thread \(currentThreadId): \(error)")
           // Handle decoding errors specifically if needed
           if let decodingError = error as? DecodingError {
                print("   Decoding Error Details: \(decodingError)")
           }

           // Check specifically for cancellation errors
           if (error as? URLError)?.code == .cancelled {
                print("ℹ️ Message loading cancelled for thread \(currentThreadId).")
                await MainActor.run {
                    if currentThreadId == self.thread.id {
                        self.isLoadingMessages = false
                        self.errorMessage = nil
                    } else {
                        print("⚠️ Thread changed during cancellation handling for \(currentThreadId).")
                    }
                }
           } else {
               // Show other errors in the UI
               await MainActor.run {
                    if currentThreadId == self.thread.id {
                       self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                       self.isLoadingMessages = false
                    } else {
                        print("⚠️ Thread changed before error could be displayed for \(currentThreadId).")
                        self.isLoadingMessages = false
                    }
               }
           }
       }
   }


   private func sendMessage(_ content: String) async {
       guard !isLoadingMessages else {
           print("⚠️ Attempted to send while loading messages. Aborting.")
           return
       }

       do {
           if userId.isEmpty {
               userId = UUID().uuidString
               UserDefaults.standard.set(userId, forKey: "userUUID")
           }

           if let restCoordinator = viewModel.coordinator as? RESTPostchainCoordinator {
               restCoordinator.currentChoirThread = thread
           }

           // Create and append user message locally (UI update)
           let userMessage = Message(
               content: content,
               isUser: true
           )
            await MainActor.run {
                thread.messages.append(userMessage)
            }


           // Create and append placeholder AI message locally (UI update)
           var placeholderMessage = Message(
               content: "...",
               isUser: false,
               isStreaming: true
           )
            await MainActor.run {
                thread.messages.append(placeholderMessage)
            }


           // Call backend processing
           try await viewModel.process(content) // This should trigger the backend workflow

           // Update placeholder message with results from viewModel
            await MainActor.run {
                if let lastIndex = thread.messages.indices.last, thread.messages[lastIndex].id == placeholderMessage.id {
                    let message = thread.messages[lastIndex]
                    let allPhases = viewModel.responses // Get final phase results from ViewModel

                    message.isStreaming = false
                    message.phases = allPhases // Update using the public setter

                    // Update main content based on priority
                    if let yieldContent = allPhases[.yield], !yieldContent.isEmpty {
                        message.content = yieldContent
                    } else if let experienceContent = allPhases[.experience], !experienceContent.isEmpty {
                       message.content = experienceContent
                   } else if let actionContent = allPhases[.action], !actionContent.isEmpty {
                       message.content = actionContent
                   } else {
                       message.content = allPhases.values.first(where: { !$0.isEmpty }) ?? "..."
                   }
                    print("Updated placeholder message \(message.id) with final content.")
                } else {
                    print("⚠️ Could not find placeholder message to update after processing.")
                }
            }

       } catch {
           print("❌ Error processing message: \(error)")
            await MainActor.run {
                if let lastMessage = thread.messages.last, !lastMessage.isUser, lastMessage.isStreaming {
                    thread.messages.removeLast()
                }
                // Optionally display error to user
                // self.errorMessage = "Error sending message: \(error.localizedDescription)"
            }
       }
   }

   private func cleanup() {
       // No-op for now
   }
}

#Preview {
   ChoirThreadDetailView(
       thread: ChoirThread(title: "Preview Thread"),
       viewModel: PostchainViewModel(coordinator: RESTPostchainCoordinator())
   )
}
