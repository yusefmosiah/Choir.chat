//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: PostchainViewModel
    @State private var threads: [ChoirThread] = []
    @State private var selectedChoirThread: ChoirThread?
    @State private var showingWallet = false

    init() {
        _viewModel = StateObject(wrappedValue: PostchainViewModel(coordinator: RESTPostchainCoordinator()))
    }

    var body: some View {
        NavigationSplitView {
            List(threads, selection: $selectedChoirThread) { thread in
                NavigationLink(value: thread) {
                    ChoirThreadRow(thread: thread)
                }
                .contextMenu {
                    Button(role: .destructive, action: {
                        deleteThread(thread)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("ChoirThreads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Explicit placement for the primary action
                    Button(action: createNewChoirThread) {
                        Label("New ChoirThread", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) { // Keep explicit placement for leading item
                    Button(action: { showingWallet = true }) {
                        Label("Wallet", systemImage: "wallet.pass")
                    }
                }
            }
        } detail: {
            if let thread = selectedChoirThread {
                ChoirThreadDetailView(thread: thread, viewModel: viewModel)
            } else {
                VStack(spacing: 20) {
                    Text("Choir")
                        .font(.largeTitle)
                        .bold()

                    Image("Icon-App-1024x1024")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .opacity(0.7)

                    Text("Select a thread or create a new one")
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)

                    Button(action: createNewChoirThread) {
                        Label("Create New Thread", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
            }
        }
        .sheet(isPresented: $showingWallet) {
            WalletView()
        }
        .onAppear {
            // Load saved threads
            loadThreads()

            // Create a default thread if none exists
            if threads.isEmpty {
                createNewChoirThread()
            }
        }
        .onChange(of: selectedChoirThread) { _, newThread in
            guard let thread = newThread else { return }
            thread.lastOpened = Date()
            threads.sort { $0.lastOpened > $1.lastOpened }
        }
    }

    /// Load all threads from persistent storage
    private func loadThreads() {
        let loadedThreads = ThreadPersistenceService.shared.loadAllThreads()
        if !loadedThreads.isEmpty {
            threads = loadedThreads
            selectedChoirThread = threads.first
        }
    }

    /// Create a new thread and save it
    private func createNewChoirThread() {
        let thread = ChoirThread() // Uses auto-generated title
        threads.append(thread)
        selectedChoirThread = thread

        // Save the new thread
        ThreadPersistenceService.shared.saveThread(thread)
    }

    /// Delete a thread
    private func deleteThread(_ thread: ChoirThread) {
        // Remove from UI
        if selectedChoirThread?.id == thread.id {
            selectedChoirThread = threads.first(where: { $0.id != thread.id })
        }
        threads.removeAll(where: { $0.id == thread.id })

        // Delete from storage
        ThreadPersistenceService.shared.deleteThread(threadId: thread.id)
    }
}

struct ChoirThreadRow: View {
    @ObservedObject var thread: ChoirThread
    @State private var isEditingTitle = false
    @State private var editedTitle = ""

    var body: some View {
        VStack(alignment: .leading) {
            if isEditingTitle {
                TextField("Thread Title", text: $editedTitle, onCommit: {
                    if !editedTitle.isEmpty {
                        thread.updateTitle(editedTitle)
                    }
                    isEditingTitle = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 2)
                .onAppear {
                    editedTitle = thread.title
                }
            } else {
                Text(thread.title)
                    .font(.headline)
                    .onTapGesture(count: 2) {
                        isEditingTitle = true
                    }
            }

            Text("\(thread.messages.count) messages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contextMenu {
            Button(action: {
                isEditingTitle = true
            }) {
                Label("Rename", systemImage: "pencil")
            }
        }
    }
}

#Preview {
    ContentView()
}
