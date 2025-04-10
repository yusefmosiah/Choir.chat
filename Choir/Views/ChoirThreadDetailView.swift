import SwiftUI

struct ChoirThreadDetailView: View {
    let thread: ChoirThread
    @ObservedObject var viewModel: PostchainViewModel
    @State private var input = ""
    @Namespace private var scrollSpace
    @State private var lastMessageId: String? = nil
    @State private var scrollToBottom = false
    @State private var showModelConfig = false
    @State private var showingTitleAlert = false
    @State private var newTitle = ""

    var messageList: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(thread.messages) { message in
                MessageRow(
                    message: message,
                    isProcessing: message == thread.messages.last && viewModel.isProcessing,
                    viewModel: viewModel
                )
                .id(message.id)
                .onChange(of: message.content) { _, _ in
                    saveThread()
                }
            }
            Color.clear
                .frame(height: 1)
                .id("bottomScrollAnchor")
        }
        .padding()
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    messageList
                }
                .onChange(of: thread.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollProxy.scrollTo("bottomScrollAnchor", anchor: .bottom)
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
        .onDisappear {
            saveThread()
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
            saveThread()

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
            saveThread()

            try await viewModel.process(content)

            if let lastIndex = thread.messages.indices.last {
                let message = thread.messages[lastIndex]
                let allPhases = viewModel.responses
                message.isStreaming = false
                message.phases = allPhases

                if let experienceContent = allPhases[Phase.experienceWeb], !experienceContent.isEmpty {
                    message.content = experienceContent
                } else if let vectorContent = allPhases[Phase.experienceVectors], !vectorContent.isEmpty {
                    message.content = vectorContent
                } else if let actionContent = allPhases[Phase.action], !actionContent.isEmpty {
                    message.content = actionContent
                }
                saveThread()
            }
        } catch {
            print("Error processing message: \(error)")
        }
    }

    private func saveThread() {
        Task {
            await Task.detached {
                await ThreadPersistenceService.shared.saveThread(thread)
            }.value
        }
    }

    private func cleanup() {
        // Cleanup resources if needed
    }

    private func showEditTitleAlert() {
        newTitle = thread.title
        showingTitleAlert = true
    }
}

#Preview {
    ChoirThreadDetailView(
        thread: ChoirThread(title: "Preview Thread"),
        viewModel: PostchainViewModel(coordinator: RESTPostchainCoordinator())
    )
}
