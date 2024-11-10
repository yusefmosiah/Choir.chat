# Core State Management

VERSION core_state:
invariants: {
"Chain state authority",
"Vector content authority",
"Local coordination"
}
assumptions: {
"Swift concurrency",
"Actor isolation",
"Event-driven sync"
}
docs_version: "0.4.2"

## Chain State (Source of Truth)

Blockchain program state:

```swift
// Core chain state
actor ChainState {
    private let web3: Web3
    private let eventStore: LocalEventStore

    // Thread state from chain
    func getThreadState(_ id: ThreadID) async throws -> ThreadState {
        // Get authoritative state from chain
        let contract = try await web3.contract(at: threadContractAddress)
        let state = try await contract.method("getThread", parameters: [id]).call()

        return ThreadState(
            id: id,
            coAuthors: state.coAuthors,
            tokenBalance: state.balance,
            temperature: state.temperature,
            frequency: state.frequency,
            messageHashes: state.messageHashes
        )
    }

    // Submit state changes to chain
    func submitStateChange(_ transaction: Transaction) async throws {
        // Submit to chain first
        let hash = try await web3.eth.sendRawTransaction(transaction)

        // Then emit local event for UI updates
        try await eventStore.append(.chainStateChanged(hash))
    }
}
```

## Vector State (Source of Truth)

Qdrant content storage:

```swift
// Vector content state
actor VectorState {
    private let qdrant: Qdrant
    private let eventStore: LocalEventStore

    // Get content and embeddings
    func getMessage(_ hash: MessageHash) async throws -> Message {
        // Get authoritative content from Qdrant
        let content = try await qdrant.getMessage(hash)

        // Emit local event for UI
        try await eventStore.append(.contentLoaded(hash))

        return content
    }

    // Store new content
    func storeMessage(_ message: Message) async throws {
        // Store in Qdrant first
        try await qdrant.store(message)

        // Then emit local event
        try await eventStore.append(.contentStored(message.hash))
    }
}
```

## Local Events (Coordination Only)

Temporary state for UI and sync:

```swift
// Local event coordination
actor LocalEventStore {
    // Event types for local coordination
    enum LocalEvent: Codable {
        // UI updates
        case contentLoaded(MessageHash)
        case chainStateChanged(TxHash)

        // Sync status
        case syncStarted
        case syncCompleted
        case syncFailed(Error)

        // Offline queue
        case transactionQueued(Transaction)
        case transactionSent(TxHash)
    }

    private var events: [LocalEvent] = []
    private var subscribers: [LocalEventSubscriber] = []

    // Emit coordination events
    func append(_ event: LocalEvent) async throws {
        events.append(event)

        // Notify UI subscribers
        for subscriber in subscribers {
            try await subscriber.handle(event)
        }

        // Cleanup old events
        try await pruneOldEvents()
    }
}
```

## UI State Management

React to authoritative state changes:

```swift
@MainActor
class ThreadViewModel: ObservableObject {
    @Published private(set) var thread: ThreadState?
    @Published private(set) var messages: [Message] = []

    private let chainState: ChainState
    private let vectorState: VectorState
    private let eventStore: LocalEventStore

    // Load thread state
    func loadThread(_ id: ThreadID) async throws {
        // Get authoritative state
        thread = try await chainState.getThreadState(id)

        // Load messages from vector DB
        messages = try await loadMessages(thread.messageHashes)

        // Subscribe to local events for updates
        subscribeToEvents()
    }

    // Handle local events
    private func handleEvent(_ event: LocalEvent) async {
        switch event {
        case .chainStateChanged:
            // Refresh chain state
            if let id = thread?.id {
                thread = try? await chainState.getThreadState(id)
            }
        case .contentLoaded:
            // Refresh messages if needed
            if let hashes = thread?.messageHashes {
                messages = try? await loadMessages(hashes)
            }
        }
    }
}
```

## State Verification

```swift
// State verification
actor StateVerifier {
    private let chain: ChainState
    private let vectors: VectorState

    func verifyStateConsistency() async throws {
        // Verify chain state integrity
        let threads = try await chain.getAllThreads()
        for thread in threads {
            try await verifyThreadState(thread)
        }

        // Verify vector state integrity
        let messages = try await vectors.getAllMessages()
        for message in messages {
            try await verifyMessageState(message)
        }

        // Verify cross-state consistency
        try await verifyStateAlignment()
    }

    private func verifyThreadState(_ thread: ThreadState) async throws {
        // Verify thermodynamic properties
        guard thread.temperature > 0 else {
            throw StateError.invalidTemperature
        }
        guard thread.frequency > 0 else {
            throw StateError.invalidFrequency
        }

        // Verify energy conservation
        let energy = thread.tokenBalance + thread.coAuthors.map { $0.balance }.sum()
        guard energy == thread.initialEnergy else {
            throw StateError.energyConservationViolated
        }
    }
}
```

This implementation ensures:

1. Clear authority hierarchy
2. Clean state transitions
3. Local coordination
4. UI responsiveness
5. State verification

The system maintains:

- Source of truth clarity
- Event-driven updates
- Actor isolation
- State consistency
- System coherence
