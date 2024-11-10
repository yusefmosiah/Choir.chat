# Core Implementation Patterns

VERSION core_patterns:
invariants: {
"Source of truth clarity",
"Event-driven coordination",
"Actor isolation"
}
assumptions: {
"Swift concurrency",
"Proper data hierarchy",
"Event-based sync"
}
docs_version: "0.4.1"

## Source of Truth Pattern

Respect data authority hierarchy:

```swift
// Chain state authority pattern
protocol ChainStateProvider {
    // Authoritative state
    func getThreadState(_ id: ThreadID) async throws -> ThreadState
    func getTokenBalance(_ owner: PublicKey) async throws -> UInt64

    // State transitions
    func submitTransaction(_ tx: Transaction) async throws -> Signature
}

// Vector state authority pattern
protocol VectorStateProvider {
    // Authoritative content
    func getMessage(_ hash: MessageHash) async throws -> Message
    func searchPriors(_ query: String) async throws -> [Prior]

    // Content storage
    func storeMessage(_ message: Message) async throws
    func recordCitation(_ source: Prior, _ target: Message) async throws
}

// Example implementation
actor StateManager {
    private let chain: ChainStateProvider
    private let vectors: VectorStateProvider

    func processMessage(_ content: String) async throws {
        // Store content first
        let message = Message(content: content)
        try await vectors.storeMessage(message)

        // Then record on chain
        let tx = Transaction.recordMessage(message.hash)
        try await chain.submitTransaction(tx)
    }
}
```

## Event Coordination Pattern

Events for state synchronization:

```swift
// Event types by purpose
enum SystemEvent {
    // State sync events
    case chainStateChanged(ThreadID)
    case contentStored(MessageHash)

    // UI coordination events
    case uiStateChanged(ViewState)
    case loadingStateChanged(Bool)

    // Error events
    case errorOccurred(Error)
    case syncFailed(reason: String)
}

// Event handling pattern
protocol EventHandler: Actor {
    // Handle specific event types
    func handle(_ event: SystemEvent) async throws
}

// Example implementation
actor UICoordinator: EventHandler {
    func handle(_ event: SystemEvent) async throws {
        switch event {
        case .chainStateChanged(let threadId):
            try await refreshThread(threadId)
        case .contentStored(let hash):
            try await refreshContent(hash)
        }
    }
}
```

## Actor Isolation Pattern

Clean actor boundaries:

```swift
// Domain-specific actors
actor ThreadActor {
    private let chain: ChainStateProvider
    private let events: EventEmitter

    func getThread(_ id: ThreadID) async throws -> Thread {
        // Get authoritative state
        let state = try await chain.getThreadState(id)

        // Emit UI event
        try await events.emit(.threadStateLoaded(id))

        return state
    }
}

// Resource management pattern
actor ResourcePool {
    private var resources: Set<Resource> = []

    func withResource<T>(_ work: (Resource) async throws -> T) async throws -> T {
        let resource = try await acquireResource()
        defer { releaseResource(resource) }
        return try await work(resource)
    }
}
```

## Error Recovery Pattern

Clean error handling with events:

```swift
// Error types by source
enum SystemError: Error {
    // Chain errors
    case chainUnavailable
    case transactionFailed(reason: String)

    // Vector errors
    case contentNotFound(MessageHash)
    case storageError(reason: String)

    // Sync errors
    case syncFailed(reason: String)
    case stateInconsistent
}

// Recovery pattern
actor ErrorRecovery {
    func recover(from error: SystemError) async throws {
        switch error {
        case .chainUnavailable:
            try await queueForRetry()
        case .syncFailed:
            try await resyncState()
        }
    }
}
```

## Testing Pattern

Protocol-based testing:

```swift
// Test implementations
class MockChainProvider: ChainStateProvider {
    var mockState: [ThreadID: ThreadState] = [:]

    func getThreadState(_ id: ThreadID) async throws -> ThreadState {
        guard let state = mockState[id] else {
            throw SystemError.chainUnavailable
        }
        return state
    }
}

// Test scenarios
class SystemTests: XCTestCase {
    var sut: StateManager!
    var mockChain: MockChainProvider!

    override func setUp() {
        mockChain = MockChainProvider()
        sut = StateManager(chain: mockChain)
    }

    func testStateSync() async throws {
        // Given
        let threadId = ThreadID()
        let state = ThreadState(id: threadId)
        mockChain.mockState[threadId] = state

        // When
        let result = try await sut.getThread(threadId)

        // Then
        XCTAssertEqual(result, state)
    }
}
```

These patterns ensure:
1. Clear data authority
2. Clean event flow
3. Safe state sync
4. Error resilience
5. Testability

The system maintains:
- Source of truth clarity
- Event-driven coordination
- Actor isolation
- Error recovery
- Testing simplicity
