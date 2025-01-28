# Local Data Management and Persistence

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Depends on: None
- Blocks: [SUI Blockchain Smart Contracts](issue_2.md)
- Related to: [Deploy to TestFlight and Render](issue_8.md)

## Description

Implement local data storage using SwiftData to manage users, threads, and messages effectively. Focus on establishing a solid foundation for the client-side architecture while preparing for future blockchain integration.

## Tasks

### 1. Core Data Models

```swift
@Model
class User {
    @Attribute(.unique) let id: UUID
    let publicKey: String
    let createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var ownedThreads: [Thread]
    @Relationship var coAuthoredThreads: [Thread]
    @Relationship(deleteRule: .cascade) var messages: [Message]

    // Future blockchain fields
    var onChainAddress: String?
    var lastSyncTimestamp: Date?
}

@Model
class Thread {
    @Attribute(.unique) let id: UUID
    let title: String
    let createdAt: Date

    // Ownership
    @Relationship var owner: User
    @Relationship var coAuthors: [User]

    // Content
    @Relationship(deleteRule: .cascade) var messages: [Message]

    // Thread state
    var lastMessageAt: Date
    var messageCount: Int

    // Future blockchain fields
    var onChainId: String?
    var lastSyncTimestamp: Date?
}

@Model
class Message {
    @Attribute(.unique) let id: UUID
    let content: String
    let timestamp: Date
    let isUser: Bool

    // Relationships
    @Relationship var author: User
    @Relationship(inverse: \Thread.messages) var thread: Thread?

    // Citations
    @Relationship var citesPriors: [Message]
    @Relationship(inverse: \Message.citesPriors) var citedByMessages: [Message]

    // Chorus result
    var chorusResult: ChorusResult?

    // Future blockchain fields
    var onChainHash: String?
    var lastSyncTimestamp: Date?
}
```

### 2. Data Operations

```swift
actor DataManager {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // CRUD operations
    func createThread(title: String, owner: User) async throws -> Thread {
        let thread = Thread(
            id: UUID(),
            title: title,
            createdAt: Date(),
            owner: owner,
            lastMessageAt: Date(),
            messageCount: 0
        )
        modelContext.insert(thread)
        try await modelContext.save()
        return thread
    }

    func addMessage(_ content: String, to thread: Thread, by user: User) async throws -> Message {
        let message = Message(
            id: UUID(),
            content: content,
            timestamp: Date(),
            isUser: true,
            author: user,
            thread: thread
        )
        modelContext.insert(message)

        // Update thread
        thread.lastMessageAt = message.timestamp
        thread.messageCount += 1

        try await modelContext.save()
        return message
    }
}
```

### 3. Query Support

```swift
extension DataManager {
    func fetchThreads(for user: User) async throws -> [Thread] {
        let descriptor = FetchDescriptor<Thread>(
            predicate: #Predicate<Thread> { thread in
                thread.owner.id == user.id ||
                thread.coAuthors.contains { $0.id == user.id }
            },
            sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func searchMessages(containing text: String) async throws -> [Message] {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.content.localizedStandardContains(text)
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
```

## Success Criteria

- **Reliable local data persistence**

  - Users can create and manage threads and messages locally.
  - Data persists across app launches and device restarts.

- **Efficient CRUD operations**

  - CRUD operations perform smoothly without lag.
  - Data relationships are maintained accurately.

- **Clean relationship management**

  - One-to-many and many-to-many relationships are defined correctly.
  - Models align with blockchain ownership data.

- **Ready for blockchain integration**

  - Architecture supports future data synchronization.
  - Initial sync tests are successful, laying the groundwork for full integration.

- **Comprehensive test coverage**

  - All CRUD operations are tested thoroughly.
  - Relationship management is thoroughly tested.

## Future Considerations

- **Blockchain state synchronization**

  - Implement full data synchronization with the SUI blockchain.
  - Ensure real-time updates and consistency between local and on-chain data.

- **Multi-device data sync**

  - Develop mechanisms to synchronize data across multiple devices.
  - Ensure data consistency and conflict resolution across devices.

- **Advanced search capabilities**

  - Develop sophisticated search capabilities to search for messages and threads.
  - Implement user prompts or automated resolutions where appropriate.

- **Performance optimization for large datasets**

  - Optimize data handling and query performance for large datasets.
  - Ensure smooth user interactions and data consistency.

---
