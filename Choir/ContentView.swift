//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    // Use environment objects instead of creating new instances
    @StateObject private var postchainViewModel = PostchainViewModel(coordinator: PostchainCoordinatorImpl())
    @EnvironmentObject var threadManager: ThreadManager
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedChoirThread: ChoirThread?
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var isLoadingThreads = false

    // View model for controlling thread selection from MainTabView
    @ObservedObject var viewModel: ContentViewModel

    // For notification handling
    @State private var notificationCancellable: AnyCancellable?

    // Initialize with default ContentViewModel if none provided
    init(viewModel: ContentViewModel = ContentViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationSplitView {
            ZStack {
                List(selection: $selectedChoirThread) {
                    ForEach(threadManager.threads, id: \.id) { thread in
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
                    .onDelete(perform: deleteThreads)
                }

                if isLoadingThreads {
                    ProgressView("Loading threads...")
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }

                if threadManager.threads.isEmpty && !isLoadingThreads {
                    VStack {
                        Text("No threads found")
                            .font(.headline)
                            .padding(.bottom, 4)

                        if threadManager.currentWalletAddress != nil {
                            Text("Create a new thread or import existing ones")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: createNewChoirThread) {
                                Label("New Thread", systemImage: "plus.circle")
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top)
                        } else {
                            Text("Select a wallet to see its threads")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { // Keep explicit placement for leading item
                    EditButton()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingExportSheet = true }) {
                            Label("Export Threads", systemImage: "square.and.arrow.up")
                        }

                        Button(action: { showingImportSheet = true }) {
                            Label("Import Threads", systemImage: "square.and.arrow.down")
                        }

                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) { // Explicit placement for the primary action
                    Button(action: createNewChoirThread) {
                        Label("New Chat", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let thread = selectedChoirThread {
                // If we have a thread ID, load the full thread content before displaying
                if let fullThread = threadManager.loadFullThread(threadId: thread.id) {
                    ChoirThreadDetailView(thread: fullThread, viewModel: postchainViewModel)
                        .modifier(HideTabBarModifier(onlyOnIPhone: true))
                } else {
                    // Fallback to using the metadata-only thread if full content can't be loaded
                    ChoirThreadDetailView(thread: thread, viewModel: postchainViewModel)
                        .modifier(HideTabBarModifier(onlyOnIPhone: true))
                }
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
        .sheet(isPresented: $showingExportSheet) {
            ThreadExportView()
                .environmentObject(threadManager)
                .environmentObject(walletManager)
        }
        .sheet(isPresented: $showingImportSheet) {
            ThreadImportView(onImportSuccess: { count in
                // Force a reload of threads after successful import
                print("Import successful, reloading threads...")

                // First, force a reload of the current wallet's threads (metadata only)
                threadManager.loadThreads(metadataOnly: true)

                // Then, after a delay, reload again and update the UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Reload threads after successful import (metadata only)
                    threadManager.loadThreads(metadataOnly: true)

                    // Force UI update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Do not auto-select a thread after import
                        print("Threads imported successfully, showing thread list")
                    }
                }
            })
            .environmentObject(threadManager)
        }


        .onAppear {
            // Always reset thread selection to show the thread list
            selectedChoirThread = nil
            // Load saved threads
            loadThreads()

            // Set up notification observer for thread metadata changes
            notificationCancellable = NotificationCenter.default.publisher(for: NSNotification.Name("ThreadMetadataDidChange"))
                .receive(on: DispatchQueue.main)
                .sink { [weak threadManager] notification in
                    guard let thread = notification.object as? ChoirThread else { return }

                    // Update the thread in the UI
                    threadManager?.updateThreadInUI(thread)
                }
        }
        .onDisappear {
            // Clean up notification observer
            notificationCancellable?.cancel()
            notificationCancellable = nil
        }
        .onChange(of: viewModel.shouldResetThreadSelection) { _, shouldReset in
            if shouldReset {
                // Reset thread selection when signaled from tab change
                selectedChoirThread = nil
            }
        }
        .onChange(of: selectedChoirThread) { _, newThread in
            guard let thread = newThread else { return }
            // No need to update lastModified since we're sorting by createdAt
            // We still need to reload threads to ensure proper sorting
            // Use metadata-only loading to keep it fast
            threadManager.loadThreads(metadataOnly: true)
        }
    }

    /// Load all threads from the thread manager
    private func loadThreads() {
        isLoadingThreads = true

        // Use a slight delay to ensure the UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Load only metadata for better performance
            threadManager.loadThreads(metadataOnly: true)
            // Do not auto-select a thread
            isLoadingThreads = false
        }
    }

    /// Create a new thread and save it
    private func createNewChoirThread() {
        // Create a new thread with the current wallet address
        let thread = threadManager.createThread()
        selectedChoirThread = thread
    }

    /// Delete a thread
    private func deleteThread(_ thread: ChoirThread) {
        // Remove from UI
        if selectedChoirThread?.id == thread.id {
            selectedChoirThread = threadManager.threads.first(where: { $0.id != thread.id })
        }

        // Delete using thread manager
        threadManager.deleteThread(thread)
    }

    /// Delete threads at offsets (for swipe-to-delete)
    private func deleteThreads(at offsets: IndexSet) {
        for index in offsets {
            let thread = threadManager.threads[index]
            deleteThread(thread)
        }
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

            HStack {
                Text("\(thread.messageCount) messages")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Show the creation date
                Text(thread.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button(action: {
                isEditingTitle = true
            }) {
                Label("Rename", systemImage: "pencil")
            }
        }
        // Force view to update when thread changes
        .id(thread.id.uuidString + thread.title + String(thread.messageCount))
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}

// MARK: - Hide Tab Bar Modifier
struct HideTabBarModifier: ViewModifier {
    let onlyOnIPhone: Bool

    func body(content: Content) -> some View {
        if !onlyOnIPhone || UIDevice.current.userInterfaceIdiom == .phone {
            // Only hide the tab bar on iPhone, or if onlyOnIPhone is false
            content.toolbar(.hidden, for: .tabBar)
        } else {
            // On iPad, don't hide the tab bar
            content
        }
    }
}
