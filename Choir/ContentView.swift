//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var selectedThread: Thread?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationSplitView {
            List(viewModel.threads, selection: $selectedThread) { thread in
                NavigationLink(value: thread) {
                    ThreadPreview(thread: thread)
                }
            }
            .navigationTitle("Threads")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNewThread) {
                        Label("New Thread", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let thread = selectedThread {
                ChatView(thread: thread, viewModel: viewModel, isTextFieldFocused: isTextFieldFocused)
            } else {
                Text("Select a thread")
            }
        }
    }

    private func createNewThread() {
        let thread = Thread()
        viewModel.threads.append(thread)
        selectedThread = thread
        isTextFieldFocused = true
    }
}

class ViewModel: ObservableObject {
    @Published var threads: [Thread] = []

    func createNewThread() {
        let thread = Thread()
        threads.append(thread)
    }

    func addMessage(_ message: Message, to thread: Thread) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].messages.append(message)
        }
    }
}

struct ThreadPreview: View {
    let thread: Thread

    var body: some View {
        if let lastMessage = thread.messages.last {
            VStack(alignment: .leading) {
                Text(lastMessage.content)
                    .lineLimit(1)
                Text(thread.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            Text("New Thread")
                .foregroundColor(.secondary)
        }
    }
}

struct ChatView: View {
    let thread: Thread
    let viewModel: ViewModel
    let isTextFieldFocused: Bool
    @State private var newMessage: String = ""
    @FocusState private var isFocused: Bool
    @StateObject private var chorus = ChorusCoordinator()

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(thread.messages) { message in
                        if message.isUser {
                            MessageView(message: message)
                        } else {
                            ChorusResponse(responses: chorus.responses)
                        }
                    }
                }
                .padding()
            }

            HStack {
                TextField("Message", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)

                Button(action: sendMessage) {
                    Text("Send")
                }
            }
            .padding()
        }
        .onChange(of: isTextFieldFocused) { newValue in
            isFocused = newValue
        }
    }

    private func sendMessage() {
        guard !newMessage.isEmpty else { return }

        // Store user message
        let userMessage = Message(content: newMessage, isUser: true)
        viewModel.addMessage(userMessage, to: thread)

        // Clear input
        newMessage = ""

        // Add AI message immediately and start processing
        let aiMessage = Message(content: "AI Response", isUser: false)
        viewModel.addMessage(aiMessage, to: thread)

        // Process through chorus cycle
        Task {
            await chorus.process(userMessage.content)
        }
    }
}

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            Text(message.content)
                .padding()
                .background(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(12)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
