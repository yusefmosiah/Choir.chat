# Thread State Management

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md), [User Identity Implementation](issue_4.md)
- Blocks: None
- Related to: [Coordinator Message Flow](issue_3.md)

## Description
Implement thread state management that maintains local state while synchronizing with Qdrant storage, handling message history and thread metadata.

## Tasks
- [ ] Implement Thread model with message history
- [ ] Add thread state synchronization
- [ ] Handle message addition/removal
- [ ] Implement thread metadata updates

## Code Examples
```swift
class Thread: ObservableObject, Identifiable {
    let id: UUID
    let authorId: String  // public key
    @Published private(set) var messages: [ThreadMessage]

    func addMessage(_ content: String) async throws {
        let message = ThreadMessage(content: content)
        messages.append(message)

        // Sync with Qdrant
        try await vectorStorage.storeMessage(message)
    }

    func loadHistory() async throws {
        messages = try await api.getThreadMessages(id.uuidString)
            .map(ThreadMessage.init)
    }
}
```

## Testing Requirements
- Test thread creation/loading
- Verify message synchronization
- Test state management
- Validate error handling

## Success Criteria
- Reliable state management
- Clean synchronization
- Proper error handling
