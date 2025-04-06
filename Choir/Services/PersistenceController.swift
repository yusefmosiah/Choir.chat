import CoreData
import SwiftUI // Needed for preview setup

struct PersistenceController {
    static let shared = PersistenceController()

    // Storage for Core Data in memory, useful for previews and testing
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        let sampleThread = CDThread(context: viewContext)
        sampleThread.id = UUID()
        sampleThread.title = "Preview Thread"
        sampleThread.createdAt = Date()
        sampleThread.lastActivity = Date()

        let sampleTurn1 = CDTurn(context: viewContext)
        sampleTurn1.id = UUID()
        sampleTurn1.timestamp = Date().addingTimeInterval(-60) // 1 minute ago
        sampleTurn1.userQuery = "Hello, Choir!"
        sampleTurn1.aiResponseContent = "Hello there! This is a preview response."
        sampleTurn1.thread = sampleThread

        let sampleTurn2 = CDTurn(context: viewContext)
        sampleTurn2.id = UUID()
        sampleTurn2.timestamp = Date()
        sampleTurn2.userQuery = "How are previews?"
        sampleTurn2.aiResponseContent = "They look good!"
        sampleTurn2.thread = sampleThread

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return controller
    }()

    let container: NSPersistentContainer

    // Standard initializer
    init(inMemory: Bool = false) {
        // Use the name of your .xcdatamodeld file here
        container = NSPersistentContainer(name: "ChoirModel") // <<< MAKE SURE THIS MATCHES YOUR MODEL FILE NAME

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Core Data store loaded successfully: \(storeDescription.url?.absoluteString ?? "Unknown URL")")
            }
        })
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Convenience function to save the context
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                // Consider logging the error instead of fatalError in production
                print("Error saving context: \(nserror), \(nserror.userInfo)")
                // fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
