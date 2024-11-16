# Implementation Checklist: Issues 1-10

## Phase 1: SwiftData Models & Relationships
- [ ] 1.1 Core Models
  ```swift
  @Model
  class User {
      @Attribute(.unique) let id: UUID
      let publicKey: String
      let createdAt: Date

      // Relationships
      @Relationship(deleteRule: .cascade) var ownedThreads: [ChoirThread]
      @Relationship var coAuthoredThreads: [ChoirThread]
      @Relationship(deleteRule: .cascade) var messages: [Message]
  }

  @Model
  class ChoirThread {
      @Attribute(.unique) let id: UUID
      let title: String
      let createdAt: Date

      // Ownership & Permissions
      @Relationship var owner: User
      @Relationship var coAuthors: [User]

      // Content
      @Relationship(deleteRule: .cascade) var messages: [Message]

      // Thread state
      var lastMessageAt: Date
      var messageCount: Int
  }

  @Model
  class Message {
      @Attribute(.unique) let id: UUID
      let content: String
      let timestamp: Date
      let isUser: Bool

      // Relationships
      @Relationship var author: User
      @Relationship(inverse: \ChoirThread.messages) var thread: ChoirThread?

      // Citations
      @Relationship var citesPriors: [Message]
      @Relationship(inverse: \Message.citesPriors) var citedByMessages: [Message]

      var chorusResult: MessageChorusResult?
  }
  ```

- [ ] 1.2 Identity Management
  - [ ] Implement KeychainManager
  - [ ] Create IdentityManager
  - [ ] Add key generation
  - [ ] Test persistence

## Phase 2: ViewModels & Views
- [ ] 2.1 Thread List
  ```swift
  @MainActor
  class ThreadListViewModel: ObservableObject {
      @Published private(set) var threads: [ChoirThread] = []
      private let modelContext: ModelContext

      func loadThreads(for user: User) async throws {
          let descriptor = FetchDescriptor<ChoirThread>(
              predicate: #Predicate<ChoirThread> { thread in
                  thread.owner.id == user.id ||
                  thread.coAuthors.contains { $0.id == user.id }
              },
              sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
          )
          threads = try modelContext.fetch(descriptor)
      }
  }
  ```

- [ ] 2.2 Thread Detail
  ```swift
  @MainActor
  class ThreadDetailViewModel: ObservableObject {
      @Published private(set) var messages: [Message] = []
      @Published var isProcessing = false

      private let thread: ChoirThread
      private let modelContext: ModelContext
      private let coordinator: ChorusCoordinator

      func sendMessage(_ content: String, from user: User) async throws {
          // Create user message
          let message = Message(content: content, author: user)
          message.thread = thread
          modelContext.insert(message)

          // Process through chorus cycle
          try await coordinator.process(content)

          // Update with result
          if let response = coordinator.yieldResponse {
              message.chorusResult = MessageChorusResult(
                  phases: coordinator.responses
              )
          }
      }
  }
  ```

## Phase 3: Coordinator Integration
- [ ] 3.1 Update RESTChorusCoordinator
  - [ ] Add SwiftData context
  - [ ] Handle message persistence
  - [ ] Maintain message IDs
  - [ ] Test flow

- [ ] 3.2 API Client Updates
  - [ ] Use client-generated IDs
  - [ ] Add user context
  - [ ] Update endpoints
  - [ ] Test integration

## Phase 4: Testing Infrastructure
- [ ] 4.1 Model Tests
  ```swift
  class ModelTests: XCTestCase {
      var container: ModelContainer!

      func testMessageCitations() async throws {
          let user = User(id: UUID(), publicKey: "test")
          let thread = ChoirThread(title: "Test", owner: user)
          let message1 = Message(content: "First", author: user)
          let message2 = Message(content: "Cites first", author: user)

          message2.citesPriors = [message1]
          XCTAssertEqual(message1.citedByMessages.count, 1)
      }
  }
  ```

- [ ] 4.2 ViewModel Tests
  ```swift
  class ViewModelTests: XCTestCase {
      func testThreadLoading() async throws {
          let vm = ThreadListViewModel(modelContext: context)
          try await vm.loadThreads(for: testUser)
          XCTAssertFalse(vm.threads.isEmpty)
      }
  }
  ```

## Phase 5: Error Handling
- [ ] 5.1 Define Errors
  ```swift
  enum PersistenceError: Error {
      case modelNotFound
      case invalidRelationship
      case saveFailed
  }
  ```

- [ ] 5.2 Recovery
  - [ ] Handle model errors
  - [ ] Add retry logic
  - [ ] Test scenarios

## Success Criteria
- [ ] Models properly relate data
- [ ] ViewModels manage state
- [ ] Views stay simple
- [ ] IDs remain consistent
- [ ] Tests verify behavior

## Testing Checkpoints
After each phase:
1. Run model tests
2. Test relationships
3. Verify ViewModels
4. Check UI flow

## Notes
- Keep Views simple, logic in ViewModels
- Use client-generated UUIDs
- Maintain clean relationships
- Plan for citations
- Test thoroughly

## Postponed
- iCloud sync
- Advanced security
- Blockchain integration
- Complex queries
- Event Driven Architecture
