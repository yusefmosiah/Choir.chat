# API Client Message Handling

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Blocks: [Coordinator Message Flow](issue_3.md)
- Related to: [Thread State Management](issue_5.md)

## Description
Update ChorusAPIClient to handle the new unified message types while maintaining compatibility with existing endpoints and response structures.

## Current State
- Have working API client with phase-specific endpoints
- Using existing response types from ChorusModels.swift
- Need to add message point handling
- Need to integrate with Qdrant collections

## Tasks
- [ ] Add message point endpoints
  - [ ] getMessage by ID
  - [ ] storeMessage with vector
  - [ ] getThreadMessages with pagination
- [ ] Update phase endpoints
  - [ ] Modify request/response types
  - [ ] Add message context
  - [ ] Handle errors gracefully
- [ ] Add thread operations
  - [ ] Create/get thread
  - [ ] Update thread state
  - [ ] Handle message lists
- [ ] Implement error handling
  - [ ] Type-specific errors
  - [ ] Retry logic
  - [ ] Error reporting

## Code Examples
```swift
extension ChorusAPIClient {
    // Message operations
    func getMessage(_ id: String) async throws -> MessagePoint {
        return try await post(endpoint: "messages/\(id)", body: EmptyBody())
    }

    func storeMessage(_ message: MessagePoint) async throws {
        try await post(endpoint: "messages", body: message)
    }

    func getThreadMessages(
        _ threadId: String,
        limit: Int = 50,
        before: String? = nil
    ) async throws -> [MessagePoint] {
        return try await post(
            endpoint: "threads/\(threadId)/messages",
            body: GetMessagesRequest(
                limit: limit,
                before: before
            )
        )
    }

    // Phase operations with message context
    func processAction(_ input: String, context: [MessagePoint]) async throws -> ActionResponse {
        return try await post(
            endpoint: "chorus/action",
            body: ActionRequestBody(
                content: input,
                threadID: currentThreadId,
                context: context
            )
        )
    }
}

// Error handling
enum APIError: Error {
    case messageNotFound(String)
    case invalidMessageData(String)
    case threadOperationFailed(String)
    case networkError(Error)
    case decodingError(Error)
}
```

## Testing Requirements
- Test message operations
  - Get/store messages
  - Thread message retrieval
  - Pagination handling
- Verify phase operations
  - Context handling
  - Response processing
  - Error cases
- Test error handling
  - Network errors
  - Invalid data
  - Missing resources

## Success Criteria
- Reliable message operations
- Clean error handling
- Type-safe API interface
- Proper context handling
