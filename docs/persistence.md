# Persistence Implementation

## Tasks

1. **Client-Side: Generate and Use UUIDs for Threads**
   - [ ] Update ChoirThread to use client-generated UUIDs
   - [ ] Modify ContentView thread creation
   - [ ] Ensure UUID consistency across app

2. **Server-Side: Thread Creation API**
   - [ ] Update POST /threads/{thread_id} endpoint
   - [ ] Add thread_id validation
   - [ ] Handle duplicate thread_ids

3. **Client-Side: Thread Creation API Integration**
   - [ ] Add createThread to ChorusAPIClient
   - [ ] Implement background thread creation
   - [ ] Add error handling for failed creation

4. **Client-Side: Chorus Coordinator Updates**
   - [ ] Add thread_id to all chorus requests
   - [ ] Update coordinator to track current thread
   - [ ] Ensure thread context persistence

5. **Server-Side: Chorus Cycle Updates**
   - [ ] Add thread_id to all chorus endpoints
   - [ ] Implement message storage in chorus cycle
   - [ ] Add thread validation to endpoints

6. **Server-Side: Message Storage**
   - [ ] Store messages with thread_id
   - [ ] Implement message retrieval by thread
   - [ ] Add message pagination support

7. **Client-Side: Message Fetching**
   - [ ] Add getThreadMessages to ChorusAPIClient
   - [ ] Implement message loading in ChoirThreadDetailView
   - [ ] Handle message pagination

8. **Error Handling**
   - [ ] Add client-side error states
   - [ ] Implement server-side validation
   - [ ] Add retry mechanisms

9. **Data Model Updates**
   - [ ] Update ChoirThread model
   - [ ] Update Message model
   - [ ] Ensure model consistency

10. **Testing**
    - [ ] Add thread persistence tests
    - [ ] Add message persistence tests
    - [ ] Test error scenarios

11. **Documentation**
    - [ ] Document API endpoints
    - [ ] Document data models
    - [ ] Add implementation notes

## API Endpoints

### Threads
```
POST /threads/{thread_id}
GET /threads/{thread_id}
GET /threads/{thread_id}/messages
```

### Messages (via Chorus Cycle)
```
POST /chorus/action   (includes thread_id)
POST /chorus/experience
POST /chorus/intention
POST /chorus/observation
POST /chorus/understanding
POST /chorus/yield
```

## Data Models

### Thread
```swift
class ChoirThread: ObservableObject, Identifiable {
    let id: UUID
    let title: String
    @Published var messages: [Message]
}
```

### Message
```swift
struct Message: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let threadId: UUID
    let timestamp: Date
    var chorusResult: MessageChorusResult?
}
```

## Implementation Flow

1. **Thread Creation**
   ```
   Client generates UUID
   -> Creates local thread
   -> POST /threads/{uuid} in background
   -> Starts using thread immediately
   ```

2. **Message Processing**
   ```
   Send message through chorus cycle
   -> Server stores message with thread_id
   -> Response includes stored message
   -> Client updates thread state
   ```

3. **Thread Loading**
   ```
   Open thread
   -> Fetch messages from server
   -> Display in UI
   -> Load more as needed
   ```

## Error Handling

### Client-Side
- Network errors during thread creation
- Failed message persistence
- Message fetch failures

### Server-Side
- Invalid thread_ids
- Missing thread context
- Storage failures

## Testing Strategy

### Client Tests
- Thread creation and persistence
- Message sending and retrieval
- Error handling and recovery

### Server Tests
- Thread endpoint validation
- Message storage integrity
- Chorus cycle persistence

## Notes

- All UUIDs generated on client
- Messages stored during chorus cycle
- Thread state managed optimistically
- Background sync for reliability
