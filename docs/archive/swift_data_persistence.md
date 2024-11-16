# SwiftData Persistence Implementation Plan

## Overview
Switch to SwiftData for client-side persistence, storing threads and messages locally while maintaining the existing vector database for search functionality.

## 1. Data Models
- [ ] Convert existing models to SwiftData:
  ```swift
  @Model
  class ChoirThread {
      @Attribute(.unique) let id: UUID
      let title: String
      let createdAt: Date
      @Relationship(deleteRule: .cascade) var messages: [Message]

      init(id: UUID = UUID(), title: String, createdAt: Date = Date()) {
          self.id = id
          self.title = title
          self.createdAt = createdAt
      }
  }

  @Model
  class Message {
      @Attribute(.unique) let id: UUID
      let content: String
      let isUser: Bool
      let timestamp: Date
      var chorusResult: MessageChorusResult?

      @Relationship(inverse: \ChoirThread.messages)
      var thread: ChoirThread?
  }
  ```

## 2. ModelContainer Setup
- [ ] Add ModelContainer to ChoirApp:
  ```swift
  @main
  struct ChoirApp: App {
      let container: ModelContainer

      init() {
          do {
              container = try ModelContainer(
                  for: ChoirThread.self, Message.self,
                  configurations: ModelConfiguration(isStoredInMemoryOnly: false)
              )
          } catch {
              fatalError("Failed to initialize ModelContainer")
          }
      }

      var body: some Scene {
          WindowGroup {
              ContentView()
          }
          .modelContainer(container)
      }
  }
  ```

## 3. Update Views
- [ ] Modify ContentView to use SwiftData:
  ```swift
  struct ContentView: View {
      @Query private var threads: [ChoirThread]
      @Environment(\.modelContext) private var modelContext

      private func createNewChoirThread() {
          let thread = ChoirThread(title: "New Thread")
          modelContext.insert(thread)
      }
  }
  ```

- [ ] Update ChoirThreadDetailView:
  ```swift
  struct ChoirThreadDetailView: View {
      @ObservedObject var thread: ChoirThread
      @Environment(\.modelContext) private var modelContext

      private func addMessage(_ content: String, isUser: Bool) {
          let message = Message(
              content: content,
              isUser: isUser,
              timestamp: Date()
          )
          message.thread = thread
          modelContext.insert(message)
      }
  }
  ```

## 4. Coordinator Updates
- [ ] Update RESTChorusCoordinator to work with SwiftData:
  - [ ] Keep vector database integration for search
  - [ ] Store messages locally in SwiftData
  - [ ] Maintain existing chorus cycle functionality

## 5. Migration
- [ ] Create migration plan for existing data:
  ```swift
  enum VersionedSchemaV1: VersionedSchema {
      static var models: [any PersistentModel.Type] {
          [ChoirThread.self, Message.self]
      }

      @Model
      final class ChoirThread {
          // ... schema definition
      }

      @Model
      final class Message {
          // ... schema definition
      }
  }
  ```

## 6. Testing
- [ ] Add SwiftData-specific tests:
  ```swift
  class SwiftDataTests: XCTestCase {
      var container: ModelContainer!

      override func setUp() {
          container = try! ModelContainer(
              for: ChoirThread.self,
              configurations: ModelConfiguration(isStoredInMemoryOnly: true)
          )
      }

      func testThreadCreation() throws {
          let context = container.mainContext
          let thread = ChoirThread(title: "Test Thread")
          context.insert(thread)
          try context.save()

          let fetchDescriptor = FetchDescriptor<ChoirThread>()
          let threads = try context.fetch(fetchDescriptor)
          XCTAssertEqual(threads.count, 1)
      }
  }
  ```

## 7. Error Handling
- [ ] Implement robust error handling:
  ```swift
  enum PersistenceError: Error {
      case failedToSave
      case failedToLoad
      case modelNotFound
  }
  ```

## 8. Backup Strategy (Post-MVP)
- [ ] Plan for iCloud backup integration:
  - [ ] Add CloudKit capability
  - [ ] Configure sync settings
  - [ ] Handle merge conflicts

## Implementation Order
1. Create SwiftData models
2. Set up ModelContainer
3. Update views to use SwiftData
4. Update coordinator
5. Add tests
6. Implement error handling
7. Test migration
8. Document changes

## Success Criteria
- [ ] All threads and messages persist between app launches
- [ ] Smooth integration with existing chorus cycle
- [ ] Efficient querying and filtering
- [ ] Proper error handling
- [ ] Comprehensive test coverage

## Notes
- Keep vector database for search functionality only
- Maintain existing chorus cycle implementation
- Focus on local persistence first, add iCloud sync later
- Ensure proper error handling and data validation
