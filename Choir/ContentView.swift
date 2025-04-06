//
//  ContentView.swift
//  Choir
//
//  Created by Yusef Mosiah Nathanson on 11/9/24.
//
import SwiftUI
import CoreData
struct ContentView: View {
    // Core Data Fetch Request for Threads, sorted by last activity descending
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDThread.lastActivity, ascending: false)],
        animation: .default)
    private var threads: FetchedResults<CDThread>

    @Environment(\.managedObjectContext) private var viewContext // Get context from environment
    @EnvironmentObject var walletManager: WalletManager
    // @StateObject private var viewModel: PostchainViewModel // Commented out for now
    @State private var selectedChoirThreadID: CDThread.ID? // Use ID for selection
    @State private var showingWallet = false

@State private var userUUID: String? = nil
@AppStorage("userUUID") private var storedUserUUID: String = ""

    // init() { // Commented out viewModel initialization
    //     _viewModel = StateObject(wrappedValue: PostchainViewModel(coordinator: RESTPostchainCoordinator()))
    // }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedChoirThreadID) { // Use ID for selection binding
                ForEach(threads) { thread in
                    // Use thread.id as the value for navigation
                    NavigationLink(value: thread.id) {
                        ChoirThreadRow(thread: thread) // Pass CDThread to the row view
                    }
                }
                // Optional: Add onDelete modifier if needed later
                // .onDelete(perform: deleteThreads)
            }
            .navigationTitle("ChoirThreads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Explicit placement for the primary action
                    Button { // Change to async task execution
                        // No longer async
                        createNewChoirThread()
                    } label: {
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
            // --- Detail View Refactoring Needed ---
            // Find the selected thread using the ID
            if let selectedThread = findSelectedThread() {
                 // TODO: Refactor ChoirThreadDetailView to accept CDThread
                 // For now, show a placeholder
                 Text("Detail View for Thread: \(selectedThread.title ?? "Untitled")")
                 // ChoirThreadDetailView(thread: selectedThread, viewModel: viewModel) // Needs refactoring
            } else {
                // Placeholder view when no thread is selected
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

                    Button { // Change to async task execution
                        // No longer async
                        createNewChoirThread()
                    } label: {
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
             // Removed API fetching logic. Core Data handles loading via @FetchRequest.
             // Wallet loading and authentication might need to be handled differently,
             // perhaps triggered explicitly or moved elsewhere if still needed.
             Task {
                 if walletManager.wallet == nil {
                     try? await walletManager.createOrLoadWallet()
                     print("Wallet loaded on appear (if needed)")
                 }
                 // Authentication logic (fetching userUUID) is removed from here.
                 // It's no longer directly tied to fetching threads.
                 // If userUUID is needed for *other* purposes, that logic needs a new home.
             }
             print("ContentView appeared. Threads loaded by @FetchRequest: \(threads.count)")
             // Select the first thread if none is selected and list is not empty
             if selectedChoirThreadID == nil, let firstThread = threads.first {
                 selectedChoirThreadID = firstThread.id
             }
         }
         // Add onChange listener to auto-select first thread if selection becomes nil
         // and the list is not empty (e.g., after deleting the selected thread)
         .onChange(of: selectedChoirThreadID) { _, newValue in
             if newValue == nil, let firstThread = threads.first {
                 selectedChoirThreadID = firstThread.id
             }
         }
         // Also handle the case where the threads array changes (e.g., first load, deletion)
         .onChange(of: threads) { _, newThreads in
              if selectedChoirThreadID == nil, let firstThread = newThreads.first {
                 selectedChoirThreadID = firstThread.id
             }
             // Ensure selection is still valid
             if let currentSelection = selectedChoirThreadID, !newThreads.contains(where: { $0.id == currentSelection }) {
                 selectedChoirThreadID = newThreads.first?.id // Select first or nil
             }
         }
    }

    // Updated to use PersistenceManager
    private func createNewChoirThread() {
        print("🚀 Creating new thread locally...")
        let defaultName = defaultThreadTitle()

        // Use PersistenceManager to create the thread
        if let newThread = PersistenceManager.shared.createThread(title: defaultName) {
            // Select the newly created thread
            // Needs to run on main actor if PersistenceManager save happens on background
            // (though our current implementation saves synchronously)
            DispatchQueue.main.async {
                 selectedChoirThreadID = newThread.id
                 print("✅ Local thread object created and selected: \(newThread.id?.uuidString ?? "N/A")")
            }
        } else {
             print("❌ Error creating thread locally.")
             // Optionally show an error alert
        }
    }

    // Helper function to find the selected thread
    private func findSelectedThread() -> CDThread? {
        guard let selectedID = selectedChoirThreadID else { return nil }
        // Access threads directly from the @FetchRequest result
        return threads.first { $0.id == selectedID }
    }

     // Helper function for creating default thread title
    private func defaultThreadTitle() -> String {
        "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
    }

    // Optional: Add delete functionality
    // private func deleteThreads(offsets: IndexSet) {
    //     withAnimation {
    //         offsets.map { threads[$0] }.forEach(viewContext.delete)
    //         PersistenceManager.shared.saveContext() // Save after deletion
    //     }
    // }
}

// Updated to use CDThread
struct ChoirThreadRow: View {
    @ObservedObject var thread: CDThread // Changed to CDThread

    var body: some View {
        VStack(alignment: .leading) {
            Text(thread.title ?? "Untitled Thread") // Use CDThread property
                .font(.headline)
            // Access turns relationship count
            Text("\(thread.turns?.count ?? 0) turns")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) // Add preview context
}
