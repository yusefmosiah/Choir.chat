import Foundation
import CoreData

class PersistenceManager {

    static let shared = PersistenceManager() // Singleton for easy access

    private let viewContext: NSManagedObjectContext

    // Private initializer for singleton pattern
    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }

    // MARK: - Thread Operations

    /// Fetches all CDThread objects, sorted by last activity date descending.
    func fetchThreads() -> [CDThread] {
        let request: NSFetchRequest<CDThread> = CDThread.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDThread.lastActivity, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching threads: \(error)")
            return []
        }
    }

    /// Creates a new CDThread with the given title.
    @discardableResult
    func createThread(title: String) -> CDThread? {
        let newThread = CDThread(context: viewContext)
        newThread.id = UUID()
        newThread.title = title
        newThread.createdAt = Date()
        newThread.lastActivity = Date() // Initially set last activity to creation time

        saveContext()
        if viewContext.hasChanges { // Check if save failed
             print("Failed to save new thread.")
             return nil
        }
        print("Successfully created thread: \(newThread.id?.uuidString ?? "N/A")")
        return newThread
    }

    /// Updates the lastActivity timestamp for a given thread.
    func updateThreadLastActivity(thread: CDThread) {
        thread.lastActivity = Date()
        saveContext()
    }

    // MARK: - Turn Operations

    /// Fetches all CDTurn objects for a specific CDThread, sorted by timestamp ascending.
    func fetchTurns(for thread: CDThread) -> [CDTurn] {
        let request: NSFetchRequest<CDTurn> = CDTurn.fetchRequest()
        request.predicate = NSPredicate(format: "thread == %@", thread)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTurn.timestamp, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching turns for thread \(thread.id?.uuidString ?? "N/A"): \(error)")
            return []
        }
    }

    /// Creates a new CDTurn associated with the given CDThread.
    @discardableResult
    func createTurn(
        userQuery: String,
        aiResponseContent: String,
        phaseOutputsJSON: String?,
        metadataJSON: String?,
        for thread: CDThread
    ) -> CDTurn? {
        let newTurn = CDTurn(context: viewContext)
        newTurn.id = UUID()
        newTurn.timestamp = Date()
        newTurn.userQuery = userQuery
        newTurn.aiResponseContent = aiResponseContent
        newTurn.phaseOutputsJSON = phaseOutputsJSON
        newTurn.metadataJSON = metadataJSON
        newTurn.thread = thread // Associate with the thread

        // Update thread's last activity
        thread.lastActivity = newTurn.timestamp

        saveContext()
        if viewContext.hasChanges { // Check if save failed
            print("Failed to save new turn for thread \(thread.id?.uuidString ?? "N/A").")
            return nil
        }
         print("Successfully created turn \(newTurn.id?.uuidString ?? "N/A") for thread \(thread.id?.uuidString ?? "N/A")")
        return newTurn
    }

    // MARK: - Saving

    /// Saves changes to the Core Data context if any exist.
    func saveContext() {
        guard viewContext.hasChanges else { return }

        do {
            try viewContext.save()
            print("Context saved successfully.")
        } catch {
            let nserror = error as NSError
            // In a real app, handle this error more gracefully (e.g., logging, user alert)
            print("Error saving context: \(nserror), \(nserror.userInfo)")
            // Consider rolling back changes if save fails critically
            // viewContext.rollback()
        }
    }
}
