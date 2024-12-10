# Development Goals for Wednesday, November 13, 2024

VERSION goal_nov_13:
invariants: {
"Type safety",
"Data integrity",
"Message coherence"
}
assumptions: {
"Existing Qdrant setup",
"~20k message points",
"Existing ChorusModels"
}
docs_version: "0.1.4"

## Core Implementation Goals

### 1. Message Type Reconciliation

- [ ] Create unified message types

  ```swift
  // Base message structure matching Qdrant
  struct MessagePoint: Codable {
      let id: String
      let content: String
      let threadId: String
      let createdAt: String
      let role: String?
      let step: String?

      // Existing chorus cycle results
      let chorusResult: ChorusCycleResult?

      struct ChorusCycleResult: Codable {
          let action: ActionResponse?
          let experience: ExperienceResponseData?
          let intention: IntentionResponseData?
          let observation: ObservationResponseData?
          let understanding: UnderstandingResponseData?
          let yield: YieldResponseData?
      }
  }

  // Thread message combining MessagePoint with UI state
  struct ThreadMessage: Identifiable {
      let id: String
      let content: String
      let isUser: Bool
      let timestamp: Date
      var chorusResult: ChorusCycleResult?

      init(from point: MessagePoint) {
          self.id = point.id
          self.content = point.content
          self.isUser = point.role == "user"
          self.timestamp = DateFormatter.iso8601.date(from: point.createdAt) ?? Date()
          self.chorusResult = point.chorusResult
      }
  }
  ```

### 2. API Client Updates

- [ ] Update request/response handling

  ```swift
  extension ChorusAPIClient {
      // Get message with fallback for legacy points
      func getMessage(_ id: String) async throws -> MessagePoint {
          return try await post(endpoint: "messages/\(id)", body: EmptyBody())
      }

      // Store message with full metadata
      func storeMessage(_ message: MessagePoint) async throws {
          try await post(endpoint: "messages", body: message)
      }

      // Get thread messages with pagination
      func getThreadMessages(_ threadId: String, limit: Int = 50) async throws -> [MessagePoint] {
          return try await post(
              endpoint: "threads/\(threadId)/messages",
              body: GetMessagesRequest(limit: limit)
          )
      }
  }
  ```

### 3. Coordinator Updates

- [ ] Modify RESTChorusCoordinator to handle message types

  ```swift
  @MainActor
  class RESTChorusCoordinator: ChorusCoordinator {
      private(set) var currentMessage: ThreadMessage?

      func process(_ input: String) async throws {
          // Create initial message point
          let messagePoint = MessagePoint(
              id: UUID().uuidString,
              content: input,
              threadId: threadId,
              createdAt: ISO8601DateFormatter().string(from: Date()),
              role: "user",
              step: "input"
          )

          // Process through chorus cycle
          let result = try await processCycle(messagePoint)

          // Update with final result
          currentMessage = ThreadMessage(from: messagePoint)
          currentMessage?.chorusResult = result
      }
  }
  ```

### 4. Testing Suite

- [ ] Test message type handling

  ```swift
  class MessageTypeTests: XCTestCase {
      // Test legacy message point decoding
      func testLegacyMessageDecoding() async throws {
          let json = """
          {
              "id": "123",
              "content": "test",
              "thread_id": "thread1",
              "created_at": "2024-01-01"
          }
          """
          let message = try JSONDecoder().decode(MessagePoint.self, from: json.data(using: .utf8)!)
          XCTAssertNotNil(message)
      }

      // Test full message point with chorus results
      func testFullMessageDecoding() async throws {
          let message = try await api.getMessage(knownMessageId)
          XCTAssertNotNil(message.chorusResult)
      }

      // Test thread message conversion
      func testThreadMessageConversion() async throws {
          let point = try await api.getMessage(knownMessageId)
          let message = ThreadMessage(from: point)
          XCTAssertEqual(message.id, point.id)
      }
  }
  ```

### 5. Database Integration

- [ ] Ensure compatibility with existing Qdrant points
  - [ ] Test vector search with existing points
  - [ ] Verify payload structure matches
  - [ ] Handle missing fields gracefully

### 6. User Identity

- [ ] Implement `UserManager` to work with existing user collection

  ```swift
  actor UserManager {
      func createUser() async throws -> User {
          let keyPair = try generateKeyPair()
          let publicKey = try publicKeyToString(keyPair.publicKey)

          // Create user in existing USERS_COLLECTION
          let user = try await api.createUser(UserCreate(publicKey: publicKey))
          return user
      }

      func getUser() async throws -> User {
          // Get from existing collection
          guard let publicKey = try await getCurrentPublicKey(),
                let user = try await api.getUser(publicKey) else {
              return try await createUser()
          }
          return user
      }
  }
  ```

### 7. Thread Management

- [ ] Integrate with existing thread functionality

  ```swift
  class ThreadManager: ObservableObject {
      @Published private(set) var threads: [Thread] = []

      func loadThreads() async throws {
          // Use existing get_user_threads endpoint
          let userId = try await userManager.getCurrentUserId()
          threads = try await api.getUserThreads(userId)
      }

      func createThread(_ name: String) async throws {
          let userId = try await userManager.getCurrentUserId()
          let thread = try await api.createThread(
              ThreadCreate(name: name, userId: userId)
          )
          threads.append(thread)
      }
  }
  ```

## Testing Strategy

1. Message Types

   - [ ] Legacy point handling
   - [ ] Full message decoding
   - [ ] Chorus result integration
   - [ ] Thread message conversion

2. Database Integration

   - [ ] Vector search
   - [ ] Point storage
   - [ ] Payload compatibility
   - [ ] Error handling

3. End-to-End Flow
   - [ ] Message creation
   - [ ] Chorus cycle processing
   - [ ] Thread integration
   - [ ] UI updates

## Success Criteria

1. Type Safety:

   - Clean message type hierarchy
   - Graceful legacy handling
   - Consistent serialization

2. Data Integrity:

   - Works with existing points
   - Maintains metadata
   - Preserves relationships

3. User Experience:
   - Smooth message flow
   - Proper UI updates
   - Error resilience

## Next Steps

1. Morning

   - Message type implementation
   - Basic testing setup
   - Legacy compatibility

2. Afternoon

   - Coordinator updates
   - Database integration
   - Extended testing

3. Evening
   - UI integration
   - Final testing
   - Documentation

## Notes

- Focus on quality over speed
- Build for long-term success
- Maintain stealth advantage
- Test thoroughly with real data
- Document architectural decisions

## Today's Scope

- Focus on core message handling
- Ensure robust type system
- Build clean foundation
- No artificial deadlines

## Development Principles

1. Quality First

   - Type safety as creative foundation
   - Tests that enable exploration
   - Architecture that invites play

2. Thoughtful Testing

   - Tests as design documentation
   - Coverage that builds confidence
   - Performance as creative constraint

3. Documentation
   - Document design decisions
   - Leave notes for future creativity
   - Keep options open

## Creative Space

- Build foundation for rewards system
- Enable thread contract exploration
- Leave room for UI innovation
- Maintain architectural flexibility

Remember: Today's work creates the space for tomorrow's creativity.

## Current State

- Have existing `ChorusModels.swift` with response types
- Have working Qdrant setup with messages, users, threads collections
- Need to reconcile Swift types with Qdrant schema

## Tomorrow's Preview

- Enhanced error handling
- Advanced user features
- More comprehensive testing
- UI polish
- Analytics integration

## Development Rhythm

1. Start with type safety and basic tests
2. Build up to working message flow
3. Add user and thread management
4. Test with existing data
5. Deploy to TestFlight

Remember: Today's goal is a working foundation that we can build upon, not a complete feature set.
