import SwiftUI
import CoreData // Import CoreData

struct ChoirThreadDetailView: View {
    // Input: The selected CDThread
    let thread: CDThread

    // Fetch Turns for the given thread, sorted by timestamp
    @FetchRequest private var turns: FetchedResults<CDTurn>

    // Keep ViewModel for processing logic (will be adapted later)
    @ObservedObject var viewModel: PostchainViewModel

    @Environment(\.managedObjectContext) private var viewContext // Get context

    @State private var input = ""
    @Namespace private var scrollSpace
    // @State private var lastMessageId: String? = nil // Less relevant with CoreData FetchRequest
    // @State private var scrollToBottom = false // ScrollViewReader handles this
    @State private var showModelConfig = false
    // @State private var isLoadingMessages = false // Loading handled by @FetchRequest
    @State private var errorMessage: String? = nil // Keep for processing errors
    // @State private var userId = UserDefaults.standard.string(forKey: "userUUID") ?? UUID().uuidString // User ID might be handled differently

    // Initializer to set up the FetchRequest predicate
    init(thread: CDThread, viewModel: PostchainViewModel) {
        self.thread = thread
        self._viewModel = ObservedObject(wrappedValue: viewModel) // Initialize StateObject/ObservedObject correctly
        self._turns = FetchRequest<CDTurn>(
            sortDescriptors: [NSSortDescriptor(keyPath: \CDTurn.timestamp, ascending: true)],
            predicate: NSPredicate(format: "thread == %@", thread), // Filter by the passed thread
            animation: .default
        )
    }

   // Helper for date parsing
   let isoDateFormatter: ISO8601DateFormatter = {
       let formatter = ISO8601DateFormatter()
       formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
       return formatter
   }()

   var body: some View {
       VStack {
           // Display processing error message (loading is handled by FetchRequest)
           if let errorMsg = self.errorMessage {
               Text("Error: \(errorMsg)")
                   .foregroundColor(.red)
                   .padding(.horizontal)
           }

           ScrollViewReader { scrollProxy in
               ScrollView {
                   LazyVStack(alignment: .leading, spacing: 12) {
                       // Iterate over fetched turns
                       ForEach(self.turns) { turn in
                           // Display User Query part of the turn
                           UserQueryRow(
                               query: turn.userQuery ?? "...",
                               timestamp: turn.timestamp ?? Date()
                           )
                           .id("user-\(turn.id?.uuidString ?? UUID().uuidString)") // Unique ID for user part

                           // Display AI Response part of the turn
                           // TODO: Refactor MessageRow to accept CDTurn and display phases etc.
                           AIResponseRow(
                               response: turn.aiResponseContent ?? "...",
                               timestamp: turn.timestamp ?? Date()
                           )
                            .id("ai-\(turn.id?.uuidString ?? UUID().uuidString)") // Unique ID for AI part

                           // --- Placeholder for future MessageRow refactor ---
                           // MessageRow(
                           //     turn: turn, // Pass CDTurn
                           //     isProcessing: turn.id == viewModel.coordinator.activeMessageId && viewModel.isProcessing, // Adapt processing logic
                           //     viewModel: viewModel
                           // )
                           // .id(turn.id)
                       }
                       Color.clear
                           .frame(height: 1)
                           .id("bottomScrollAnchor")
                   }
                   .padding()
               }
               // Scroll to bottom when turns count changes or view appears
               .onChange(of: self.turns.count) { _, _ in
                   self.scrollToBottom(proxy: scrollProxy)
               }
               .onAppear {
                   self.scrollToBottom(proxy: scrollProxy)
               }
               // Optional: Scroll when keyboard appears/disappears if needed
           }

           HStack {
               TextField("Message", text: self.$input, axis: .vertical)
                   .textFieldStyle(.roundedBorder)
                   .lineLimit(1...5)
                   .disabled(self.viewModel.isProcessing) // Remove isLoadingMessages check

               if self.viewModel.isProcessing {
                   Button("Cancel") {
                       self.viewModel.cancel()
                   }
                   .buttonStyle(.borderedProminent)
                   .tint(.red)
               } else {
                   Button {
                       guard !self.input.isEmpty else { return }
                       let messageContent = self.input
                       self.input = ""
                       Task {
                           await self.sendMessage(messageContent)
                       }
                   } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                   }
                   .buttonStyle(.plain)
                   .disabled(self.input.isEmpty || self.viewModel.isProcessing) // Remove isLoadingMessages check
                   .keyboardShortcut(.return, modifiers: .command)
               }
           }
           .padding()
       }
       .navigationTitle(self.thread.title ?? "Thread") // Use CDThread property
       .toolbar {
           ToolbarItem(placement: .topBarTrailing) {
               Button(action: { self.showModelConfig = true }) {
                   Label("Configure Models", systemImage: "gear")
               }
           }
       }
       .sheet(isPresented: self.$showModelConfig) {
           // TODO: Refactor ModelConfigView if it relies on ChoirThread properties
           // For now, just show a placeholder or pass necessary IDs
            Text("Model Config Placeholder")
           // ModelConfigView(thread: thread)
       }
       // .onDisappear { // Keep if cleanup logic is needed
       //     cleanup()
       // }
       // Removed .task(id: thread.id) { await loadMessages() }
   }
// Removed loadMessages() - @FetchRequest handles loading
   }


   // Updated sendMessage to save turn via PersistenceManager *after* processing
   private func sendMessage(_ content: String) async {
       // Removed isLoadingMessages check

       do {
           // User ID logic might need revisiting depending on auth flow
           // if userId.isEmpty {
           //     userId = UUID().uuidString
           //     UserDefaults.standard.set(userId, forKey: "userUUID")
           // }

           // Removed coordinator update - needs rethinking with CDThread
           // if let restCoordinator = viewModel.coordinator as? RESTPostchainCoordinator {
           //     restCoordinator.currentChoirThread = thread // This won't work directly
           // }

           // --- Remove Optimistic UI Updates ---
           // User message and placeholder AI message are no longer added here.
           // The UI will update automatically when the CDTurn is saved to Core Data.


           // Call backend processing
           // Call backend processing via ViewModel
           // **IMPORTANT**: viewModel.process needs refactoring (Phase 5)
           // to eventually return the full TurnData received from the API.
           // For now, we assume it runs and we *somehow* get the data needed.
           try await self.viewModel.process(content, threadId: self.thread.id?.uuidString) // Pass thread ID if needed

           // --- Save the Turn to Core Data ---
           // This part assumes the viewModel or coordinator makes the necessary
           // turn data available after the API call completes.
           // This needs proper implementation in Phase 5 (Networking).

           // **Placeholder:** Get data needed for saving the turn.
           // Use self.viewModel and self.thread to access properties
           // Replace these with actual data retrieved after viewModel.process completes.
           // Access viewModel properties using self
           // Access viewModel properties using self. Ensure Phase enum is available or adjust key access.
           let finalAIResponseContent = self.viewModel.responses[.yield] ?? "Processed Response Placeholder" // Example - Assumes Phase enum exists
           let phaseOutputsDict = self.viewModel.responses // Example: Assuming viewModel holds this
           let metadataDict: [String: String] = ["model": "placeholder_model"] // Example

           // Convert phaseOutputs and metadata to JSON strings for Core Data
           let phaseOutputsJSON = self.encodeToJSON(phaseOutputsDict)
           let metadataJSON = self.encodeToJSON(metadataDict)

           // Use PersistenceManager to create the turn
           PersistenceManager.shared.createTurn(
               userQuery: content, // The original user input
               aiResponseContent: finalAIResponseContent,
               phaseOutputsJSON: phaseOutputsJSON,
               metadataJSON: metadataJSON,
               for: self.thread // Associate with the current CDThread using self.
           )
           // Core Data saving triggers @FetchRequest update, refreshing the UI.

       } catch { // Only one catch block needed
           print("❌ Error processing message: \(error)")
           // Removed UI cleanup for optimistic updates
           // Display error to user using self
           self.errorMessage = "Error sending message: \(error.localizedDescription)"
       }
   }

   // Removed cleanup() if not needed

   // Helper to scroll to bottom
   private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async { // Ensure it runs after view updates
             proxy.scrollTo("bottomScrollAnchor", anchor: .bottom)
        }
   }

    // Helper to encode Dictionaries to JSON String
    private func encodeToJSON<T: Encodable>(_ data: T) -> String? {
        let encoder = JSONEncoder()
        // encoder.outputFormatting = .prettyPrinted // Optional: for readability
        guard let jsonData = try? encoder.encode(data) else {
            print("Error encoding data to JSON")
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }


// --- Preview ---

#Preview {
    // Use the preview PersistenceController context
    let previewContext = PersistenceController.preview.container.viewContext

    // Create a dummy ViewModel for the preview
    let dummyViewModel = PostchainViewModel(coordinator: RESTPostchainCoordinator())
    
    // Function to create a sample thread
    let sampleThread: CDThread = {
        // Fetch or create a sample CDThread from the preview context
        let fetchRequest: NSFetchRequest<CDThread> = CDThread.fetchRequest()
        fetchRequest.fetchLimit = 1 // Get just one for the preview
        
        if let existingThread = try? previewContext.fetch(fetchRequest).first {
            return existingThread
        } else {
            // Create one if fetch fails or returns empty
            let newThread = CDThread(context: previewContext)
            newThread.id = UUID()
            newThread.title = "Preview Thread (Created)"
            newThread.createdAt = Date()
            newThread.lastActivity = Date()
            
            // Add a sample turn for the preview detail view
            let sampleTurn = CDTurn(context: previewContext)
            sampleTurn.id = UUID()
            sampleTurn.timestamp = Date()
            sampleTurn.userQuery = "Preview User Query"
            sampleTurn.aiResponseContent = "Preview AI Response"
            sampleTurn.thread = newThread
            
            // Save context if changes were made
            if previewContext.hasChanges {
                try? previewContext.save()
            }
            
            return newThread
        }
    }()

    // Return the NavigationView with our detail view
    return NavigationView { // Embed in NavigationView for title
        ChoirThreadDetailView(
            thread: sampleThread,
            viewModel: dummyViewModel
        )
        .environment(\.managedObjectContext, previewContext)
    }
}


// Example Row for User Query
struct UserQueryRow: View {
    let query: String
    let timestamp: Date

    var body: some View {
        HStack {
            Spacer() // Align to the right
            VStack(alignment: .trailing) {
                Text(query)
                    .padding(10)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                Text(timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// Example Row for AI Response (Simplified - Needs MessageRow refactor later)
struct AIResponseRow: View {
    let response: String
    let timestamp: Date
    // TODO: Add phase data, processing state etc. later by refactoring MessageRow

    var body: some View {
         HStack {
             VStack(alignment: .leading) {
                 Text(response)
                     .padding(10)
                     .background(Color.gray.opacity(0.2))
                     .cornerRadius(10)
                 Text(timestamp, style: .time)
                     .font(.caption2)
                     .foregroundColor(.gray)
             }
             Spacer() // Align to the left
         }
    }
}
