# Core System Architecture

VERSION core_architecture:
invariants: {
"Event integrity",
"Network coherence",
"Distributed consensus"
}
assumptions: {
"Swift concurrency",
"Actor isolation",
"Distributed intelligence"
}
docs_version: "0.4.2"

## Domain Events

Core event types that drive the distributed system:

```swift
// Base event protocol
protocol DomainEvent: Sendable {
    var id: UUID { get }
    var timestamp: Date { get }
    var metadata: EventMetadata { get }
}

// Chorus cycle events
enum ChorusEvent: DomainEvent {
    case cycleStarted(input: String)
    case actionGenerated(response: String, confidence: Float)
    case priorsFound(count: Int, relevance: Float)
    case intentionIdentified(goal: String)
    case linksRecorded(count: Int)
    case cycleCompleted(Response)

    var id: UUID
    var timestamp: Date
    var metadata: EventMetadata
}

// Economic events
enum EconomicEvent: DomainEvent {
    case stakeDeposited(amount: TokenAmount)
    case temperatureChanged(delta: Float)
    case equityDistributed(shares: [Address: Float])
    case rewardsIssued(amount: TokenAmount)

    var id: UUID
    var timestamp: Date
    var metadata: EventMetadata
}

// Chain service updated for EVM
actor ChainService {
    private let web3: Web3  // Using web3.swift
    private let eventStore: EventStore

    // Update chain interactions for EVM
    func submitTransaction(_ tx: Transaction) async throws -> TxHash {
        // Submit to EVM chain
        let hash = try await web3.eth.sendRawTransaction(tx)

        // Emit local event
        try await eventStore.append(.chainStateChanged(hash))

        return hash
    }

    func getThreadState(_ id: ThreadID) async throws -> ThreadState {
        // Get state from EVM smart contract
        let contract = try await web3.contract(at: threadContractAddress)
        let state = try await contract.method("getThread", parameters: [id]).call()

        return ThreadState(
            id: id,
            coAuthors: state.coAuthors,
            tokenBalance: state.balance,
            messageHashes: state.messageHashes
        )
    }
}
```

## Event Store

SwiftData event logging with network synchronization:

```swift
// Event store with distributed coordination
actor EventStore {
    // Local event log
    @Model private var events: [DomainEvent] = []
    private var subscribers: [EventSubscriber] = []

    // Network coordination
    private let networkSync: NetworkSyncService
    private let vectorStore: VectorStoreService
    private let chain: ChainService

    // Store and distribute events
    func append(_ event: DomainEvent) async throws {
        // Log locally
        events.append(event)

        // Distribute to network
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Sync with distributed services
            group.addTask { try await self.networkSync.broadcast(event) }
            group.addTask { try await self.vectorStore.process(event) }
            group.addTask { try await self.chain.verify(event) }

            // Notify local subscribers
            for subscriber in subscribers {
                group.addTask {
                    try await subscriber.handle(event)
                }
            }
            try await group.waitForAll()
        }
    }

    // Event replay with network verification
    func replay(from: Date) async throws {
        let localEvents = events.filter { $0.timestamp >= from }
        let networkEvents = try await networkSync.getEvents(from: from)

        // Reconcile local and network events
        let reconciledEvents = try await reconcileEvents(local: localEvents, network: networkEvents)

        for event in reconciledEvents {
            try await broadcast(event)
        }
    }
}
```

## Event Handlers

Domain-specific event processing with network coordination:

```swift
// Event handling protocol
protocol EventHandler: Actor {
    func handle(_ event: DomainEvent) async throws
}

// Chorus cycle handler
actor ChorusHandler: EventHandler {
    private let cycle: ChorusCycleManager
    private let ai: AIService
    private let vectors: VectorStoreService

    func handle(_ event: DomainEvent) async throws {
        guard let chorusEvent = event as? ChorusEvent else { return }

        switch chorusEvent {
        case .cycleStarted(let input):
            // Coordinate with AI service
            try await ai.beginProcessing(input)
            try await cycle.beginCycle(input)

        case .priorsFound(let count, let relevance):
            // Coordinate with vector store
            try await vectors.processPriors(count, relevance)
            try await cycle.processPriors(count, relevance)

        case .cycleCompleted(let response):
            // Finalize across services
            try await ai.completeProcessing(response)
            try await vectors.updateIndices(for: response)
            try await cycle.finalizeCycle(response)
        }
    }
}

// Economic handler with chain coordination
actor EconomicHandler: EventHandler {
    private let engine: EconomicEngine
    private let chain: ChainService

    func handle(_ event: DomainEvent) async throws {
        guard let economicEvent = event as? EconomicEvent else { return }

        switch economicEvent {
        case .stakeDeposited(let amount):
            try await chain.verifyStake(amount)
            try await engine.processStake(amount)

        case .temperatureChanged(let delta):
            try await chain.recordTemperature(delta)
            try await engine.updateTemperature(delta)
        }
    }
}
```

## System Coordination

Distributed system integration:

```swift
// Central coordinator
actor SystemCoordinator {
    private let eventStore: EventStore
    private let handlers: [EventHandler]
    private let networkSync: NetworkSyncService
    private let ai: AIService
    private let vectors: VectorStoreService
    private let chain: ChainService

    // Process input through distributed system
    func processInput(_ input: String) async throws {
        // Generate initial event
        let startEvent = ChorusEvent.cycleStarted(input: input)
        try await eventStore.append(startEvent)

        // System evolves through distributed processing
        try await withTaskCancellationHandler {
            // Coordinate event flow across services
            for try await event in eventStream(for: input) {
                try await processDistributedEvent(event)
            }
        } onCancel: {
            Task {
                try? await cleanupDistributedResources(input)
            }
        }
    }

    // Distributed event stream
    private func eventStream(for input: String) -> AsyncStream<DomainEvent> {
        AsyncStream { continuation in
            Task {
                // Coordinate across services
                async let aiEvents = ai.streamEvents(for: input)
                async let vectorEvents = vectors.streamEvents(for: input)
                async let chainEvents = chain.streamEvents(for: input)

                // Merge event streams
                try await for event in merge(aiEvents, vectorEvents, chainEvents) {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }
}
```

## Analytics & Monitoring

Distributed system insights:

```swift
// Analytics handler
actor AnalyticsHandler: EventHandler {
    private let metrics: MetricsService

    func handle(_ event: DomainEvent) async throws {
        switch event {
        case let e as ChorusEvent:
            try await metrics.trackAIMetrics(e)
        case let e as EconomicEvent:
            try await metrics.trackChainMetrics(e)
        case let e as KnowledgeEvent:
            try await metrics.trackVectorMetrics(e)
        default:
            break
        }
    }
}

// Monitoring handler
actor MonitoringHandler: EventHandler {
    private let monitor: SystemMonitor

    func handle(_ event: DomainEvent) async throws {
        // Track distributed system health
        try await monitor.recordLatency(event)
        try await monitor.checkServiceHealth(event)
        try await monitor.updateNetworkStatus(event)
    }
}
```

This architecture provides:

1. Distributed event processing
2. Network coordination
3. Service integration
4. System monitoring
5. Scalable evolution

The system ensures:

- Event integrity
- Network coherence
- Service boundaries
- Analytics insights
- System evolution
