import SwiftUI

/// Enum representing the grouped pages in the vertical layout
enum PhasePage: String, CaseIterable, Identifiable {
    case action
    case experience
    case iou
    case yield

    var id: String { rawValue }

    var title: String {
        switch self {
        case .action: return "Initial Response"
        case .experience: return "Research & Analysis"
        case .iou: return "Understanding"
        case .yield: return "Final Response"
        }
    }

    var symbol: String {
        switch self {
        case .action: return "bolt.fill"
        case .experience: return "magnifyingglass"
        case .iou: return "lightbulb.fill"
        case .yield: return "arrow.down.circle.fill"
        }
    }
}

/// Main conversation view with turn-based horizontal navigation
struct ConversationPageView: View {
    let thread: ChoirThread
    @ObservedObject var viewModel: PostchainViewModel

    // UI state
    @State private var input = ""
    @State private var showModelConfig = false
    @State private var showingTitleAlert = false
    @State private var newTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            // Main turn navigation area
            if !thread.messages.isEmpty {
                HorizontalTurnController(
                    thread: thread,
                    viewModel: viewModel
                )
            } else {
                // Empty state when no messages
                emptyConversationView
            }

            // Input bar at bottom
            ThreadInputBar(
                input: $input,
                isProcessing: viewModel.isProcessing,
                onSend: { messageContent in
                    Task {
                        await sendMessage(messageContent)
                    }
                },
                onCancel: {
                    viewModel.cancel()
                },
                processingStatus: viewModel.processingStatus,
                isProcessingLargeInput: viewModel.isProcessingLargeInput,
                allowFocus: false
            )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showEditTitleAlert()
                }) {
                    Label("Edit Title", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showModelConfig = true
                }) {
                    Label("Configure Models", systemImage: "gear")
                }
            }
        }
        .alert("Edit Thread Title", isPresented: $showingTitleAlert) {
            TextField("Thread Title", text: $newTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !newTitle.isEmpty {
                    thread.updateTitle(newTitle)
                }
            }
        } message: {
            Text("Enter a new title for this thread")
        }
        .sheet(isPresented: $showModelConfig) {
            ModelConfigView()
        }
        .onAppear {
            // Turn controller handles navigation automatically
        }
        .onChange(of: thread.messages) { _, _ in
            // Turn controller handles message updates automatically
        }
        .onChange(of: viewModel.isProcessing) { _, _ in
            // Turn controller handles processing updates automatically
        }
        .onDisappear {
            saveThread()
            cleanup()
        }
    }

    // MARK: - Empty State

    private var emptyConversationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("Start a Conversation")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Send a message to begin your conversation with Choir.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Turn Management (handled by HorizontalTurnController)

    // MARK: - Actions

    private func sendMessage(_ content: String) async {
        // Explicitly dismiss keyboard when sending a message
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        do {
            if let coordinator = viewModel.coordinator as? PostchainCoordinatorImpl {
                coordinator.currentChoirThread = thread
            }

            let userMessage = Message(
                content: content,
                isUser: true
            )
            thread.messages.append(userMessage)

            // Create an AI message for the response
            let aiMessage = Message(
                content: "",
                isUser: false,
                isStreaming: true
            )
            thread.messages.append(aiMessage)

            // Save thread after adding both messages
            saveThread()

            // Clear input
            input = ""

            // Start processing the message with the AI message ID
            try await viewModel.process(content, aiMessageId: aiMessage.id)

        } catch {
            print("Error sending message: \(error)")
        }
    }

    private func showEditTitleAlert() {
        newTitle = thread.title
        showingTitleAlert = true
    }

    private func saveThread() {
        let threadToSave = thread
        Task {
            await Task.detached {
                ThreadPersistenceService.shared.saveThread(threadToSave)
            }.value
        }
    }

    private func cleanup() {
        // Clean up any resources if needed
        viewModel.cancel()
    }
}

// MARK: - Supporting Types (moved to HorizontalTurnController and TurnContainerView)

// MARK: - Preview

#Preview {
    let previewThread = ChoirThread(title: "Sample Conversation")
    let previewViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())

    return NavigationView {
        ConversationPageView(thread: previewThread, viewModel: previewViewModel)
    }
}
