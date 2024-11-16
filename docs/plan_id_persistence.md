# Identity and Persistence Implementation Plan

## Overview
Implement SwiftData persistence and identity management, focusing on client-side data consistency and preparing for future blockchain integration.

## 1. Core Models
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

    init(id: UUID = UUID(), publicKey: String) {
        self.id = id
        self.publicKey = publicKey
        self.createdAt = Date()
    }
}

@Model
class ChoirThread {
    @Attribute(.unique) let id: UUID
    let title: String
    let createdAt: Date

    // Ownership
    @Relationship var owner: User
    @Relationship var coAuthors: [User]

    // Content
    @Relationship(deleteRule: .cascade) var messages: [Message]

    init(id: UUID = UUID(), title: String, owner: User) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.owner = owner
        self.coAuthors = [owner]  // Owner is automatically a co-author
    }
}

@Model
class Message {
    @Attribute(.unique) let id: UUID  // Same ID used in Qdrant
    let content: String
    let timestamp: Date
    let isUser: Bool

    // Relationships
    @Relationship var author: User
    @Relationship(inverse: \ChoirThread.messages) var thread: ChoirThread?

    // AI processing results
    var chorusResult: MessageChorusResult?

    init(id: UUID = UUID(), content: String, isUser: Bool, author: User) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.author = author
    }
}
```

## 2. ViewModels
```swift
@MainActor
class ThreadListViewModel: ObservableObject {
    @Published private(set) var threads: [ChoirThread] = []
    private let modelContext: ModelContext
    private let identityManager: IdentityManager

    init(modelContext: ModelContext, identityManager: IdentityManager) {
        self.modelContext = modelContext
        self.identityManager = identityManager
    }

    func loadThreads() async throws {
        let user = try await identityManager.getCurrentUser()
        let descriptor = FetchDescriptor<ChoirThread>(
            predicate: #Predicate<ChoirThread> { thread in
                thread.owner.id == user.id ||
                thread.coAuthors.contains { $0.id == user.id }
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        threads = try modelContext.fetch(descriptor)
    }

    func createThread(title: String) async throws {
        let user = try await identityManager.getCurrentUser()
        let thread = ChoirThread(title: title, owner: user)
        modelContext.insert(thread)
        threads.append(thread)
    }
}

@MainActor
class ThreadDetailViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published var isProcessing = false

    private let thread: ChoirThread
    private let modelContext: ModelContext
    private let coordinator: ChorusCoordinator
    private let identityManager: IdentityManager

    func sendMessage(_ content: String) async throws {
        isProcessing = true
        defer { isProcessing = false }

        let user = try await identityManager.getCurrentUser()

        // Create and save user message
        let userMessage = Message(
            content: content,
            isUser: true,
            author: user
        )
        userMessage.thread = thread
        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Process through chorus cycle
        try await coordinator.process(content)

        // Create AI message with same ID as in Qdrant
        if let response = coordinator.yieldResponse {
            let aiMessage = Message(
                content: response.content,
                isUser: false,
                author: user  // For now, AI messages are "authored" by the user
            )
            aiMessage.thread = thread
            aiMessage.chorusResult = MessageChorusResult(
                phases: coordinator.responses
            )
            modelContext.insert(aiMessage)
            messages.append(aiMessage)
        }
    }
}
```

## Implementation Order

1. Model Setup
   - [ ] Configure ModelContainer in ChoirApp
   - [ ] Create core models
   - [ ] Test basic persistence

2. Identity Management
   - [ ] Basic key generation
   - [ ] User creation/loading
   - [ ] Test user persistence

3. Thread Management
   - [ ] ThreadListViewModel implementation
   - [ ] Thread creation/loading
   - [ ] Test thread ownership

4. Message Flow
   - [ ] ThreadDetailViewModel implementation
   - [ ] Message persistence
   - [ ] Chorus cycle integration
   - [ ] Test message flow

5. Testing
   - [ ] Model relationship tests
   - [ ] ViewModel behavior tests
   - [ ] End-to-end flow tests

## Success Criteria
- [ ] Users persist between launches
- [ ] Threads maintain ownership
- [ ] Messages save properly
- [ ] IDs remain consistent with Qdrant
- [ ] Chorus cycle works with persistence

## Notes
- Keep ViewModels focused and testable
- Maintain ID consistency with Qdrant
- Test relationships thoroughly
- Keep security simple initially
- Plan for future enhancements

## Next Steps
1. Set up ModelContainer
2. Implement basic models
3. Create ViewModels
4. Add comprehensive tests
