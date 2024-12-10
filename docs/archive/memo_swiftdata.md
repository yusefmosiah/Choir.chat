# Memo: SwiftData Integration with Choir's Chorus Cycle

## Overview

This memo explores the integration of SwiftData with Choir's chorus cycle, examining how our data types interact, persist, and evolve through the system. The goal is to understand both the static structure and dynamic behavior of our data model, with a focus on testing strategies to validate our assumptions.

## I. Core Data Model Philosophy

Our data model reflects three key insights:

1. **User Messages vs AI Responses**
   - User messages are primary entities
   - AI responses are always tied to a user message
   - The chorus cycle is a process, not a message

2. **Thread as a Quantum System**
   - Threads maintain coherent state
   - Messages act as quantum events
   - The chorus cycle represents state transitions

3. **Prior References as Time-Like Curves**
   - Prior messages can influence future responses
   - Citations create a semantic graph
   - Knowledge accumulates through references

## II. SwiftData Model Interactions

### A. Primary Flow

```swift
User → Thread → Message → ChorusResult → ChorusPhase
```

Each user message triggers a cascade:
1. Message creation
2. Chorus cycle processing
3. Result attachment
4. Phase recording

### B. Critical Relationships

```
Message ←→ ChorusResult (1:1)
ChorusResult ←→ ChorusPhase (1:many)
Message ←→ Message (many:many through priors)
```

These relationships create a semantic network that grows with usage.

## III. Testing Strategy

### A. Unit Tests

1. **Model Creation Tests**
```swift
func testMessageCreation() throws {
    let context = try ModelContext(for: Message.self)
    let message = Message(content: "Test")
    context.insert(message)
    try context.save()

    XCTAssertNotNil(message.id)
}
```

2. **Relationship Tests**
```swift
func testChorusResultAttachment() throws {
    let message = Message(content: "Test")
    let result = ChorusResult(aiResponse: "Response")
    message.chorusResult = result

    XCTAssertEqual(message.chorusResult?.aiResponse, "Response")
    XCTAssertEqual(result.message, message)
}
```

3. **Cascade Deletion Tests**
```swift
func testMessageDeletion() throws {
    let message = Message(content: "Test")
    let result = ChorusResult(aiResponse: "Response")
    message.chorusResult = result

    context.delete(message)
    try context.save()

    // Result should be deleted
    XCTAssertNil(result.message)
}
```

### B. Integration Tests

1. **Chorus Cycle Flow**
```swift
func testChorusCycleFlow() async throws {
    let message = Message(content: "Test input")
    let coordinator = MockChorusCoordinator()

    let result = try await coordinator.process(message.content)
    message.chorusResult = result

    XCTAssertEqual(result.phases.count, 6)  // All phases present
    XCTAssertNotNil(result.phases.first { $0.type == .yield })
}
```

2. **Prior Reference Tests**
```swift
func testPriorReferences() async throws {
    let message1 = Message(content: "First")
    let message2 = Message(content: "Second")

    let result = try await coordinator.process(message2.content)
    let experiencePhase = result.phases.first { $0.type == .experience }

    experiencePhase?.priors = [message1]
    XCTAssertTrue(experiencePhase?.priors?.contains(message1) ?? false)
}
```

## IV. SwiftData Considerations

### A. Fetch Descriptors

Efficient querying requires careful descriptor design:

```swift
// Thread messages with results
let descriptor = FetchDescriptor<Message>(
    sortBy: [SortDescriptor(\.timestamp)],
    predicate: #Predicate<Message> {
        $0.thread?.id == threadId
    },
    relationship: \.chorusResult
)
```

### B. Performance Patterns

1. **Lazy Loading**
   - Load phases on demand
   - Cache frequently accessed results
   - Prefetch related messages

2. **Batch Operations**
   - Group phase creations
   - Combine prior references
   - Optimize saves

## V. Chorus Cycle Integration

The chorus cycle interacts with SwiftData at key points:

1. **Action Phase**
   - Creates initial phase record
   - No prior references

2. **Experience Phase**
   - Loads prior messages
   - Creates semantic links

3. **Intention Phase**
   - References selected priors
   - Updates phase state

4. **Observation Phase**
   - Records semantic patterns
   - Links to referenced messages

5. **Understanding Phase**
   - Decides continuation
   - Updates phase state

6. **Yield Phase**
   - Finalizes result
   - Commits all relationships

## VI. Critical Implementation Considerations

### A. Atomic Operations

```swift
// Example atomic update
try await context.perform {
    let message = Message(content: input)
    let result = try await coordinator.process(input)
    message.chorusResult = result
    try context.save()
}
```

### B. Error Handling

```swift
enum DataError: Error {
    case relationshipViolation
    case inconsistentState
    case orphanedResult
}

// Validation
func validateState() throws {
    guard message.chorusResult?.message == message else {
        throw DataError.relationshipViolation
    }
}
```

## VII. Future Considerations

1. **Migration Paths**
   - Version models explicitly
   - Preserve semantic relationships
   - Handle schema evolution

2. **Scale Considerations**
   - Implement pagination
   - Optimize fetch strategies
   - Cache effectively

3. **Extended Features**
   - Multi-user synchronization
   - Offline capabilities
   - Cross-device consistency

## VIII. Conclusion

The integration of SwiftData with Choir's chorus cycle creates a robust foundation for persistent, semantically rich conversations. The key is maintaining the integrity of relationships while allowing natural evolution of the knowledge graph.

Success metrics include:
- Clean, predictable data flow
- Efficient query performance
- Reliable state management
- Maintainable test coverage

Next steps:
1. Implement core data models
2. Write comprehensive tests
3. Build migration strategy
4. Deploy incrementally

## Appendices

### A. Test Coverage Matrix
[Test coverage matrix showing which tests cover which relationships and operations]

### B. Performance Benchmarks
[Initial performance targets and measurement methodology]

### C. Sample Queries
[Common query patterns and their optimized implementations]
