# Core Chorus Cycle

VERSION core_chorus:
invariants: {
"Event sequence integrity",
"Network synchronization",
"Distributed effects"
}
assumptions: {
"Swift concurrency",
"Service coordination",
"Collective intelligence"
}
docs_version: "0.4.1"

## Cycle Events

Detailed events for distributed cycle coordination:

```swift
// Distributed chorus cycle events
enum ChorusEvent: DomainEvent {
    // ACTION events
    case actionStarted(input: String)
    case actionGenerated(response: String, confidence: Float)
    case actionCompleted(Effect)

    // EXPERIENCE events
    case priorSearchStarted(query: String)
    case priorsFound(count: Int, relevance: Float)
    case priorSynthesisCompleted(Effect)

    // INTENTION events
    case intentionAnalysisStarted
    case goalIdentified(goal: String, alignment: Float)
    case intentionEffectGenerated(Effect)

    // OBSERVATION events
    case linkRecordingStarted(priors: [Prior])
    case linksRecorded(count: Int)
    case observationEffectGenerated(Effect)

    // UNDERSTANDING events
    case cycleUnderstandingStarted
    case loopDecided(shouldLoop: Bool, reason: String)
    case understandingEffectGenerated(Effect)

    // YIELD events
    case yieldStarted(effects: [Effect])
    case citationsGenerated(count: Int)
    case cycleCompleted(Response)

    var id: UUID
    var timestamp: Date
    var metadata: EventMetadata
}
```

## Cycle Manager

Distributed cycle coordination:

```swift
// Core cycle manager
actor ChorusCycleManager {
    // Event logging
    private let eventStore: EventStore

    // Distributed services
    private let llm: FoundationModelActor
    private let vectors: VectorStoreActor
    private let embeddings: EmbeddingActor
    private let chain: ChainActor

    // Run cycle through distributed system
    func runCycle(_ input: String) async throws -> Response {
        // Start cycle
        try await eventStore.append(.actionStarted(input: input))

        // Process through distributed steps
        try await withTaskCancellationHandler {
            // ACTION - Foundation model processing
            let actionEffect = try await processAction(input)
            try await eventStore.append(.actionCompleted(actionEffect))

            // EXPERIENCE - Vector search and embedding
            let priorEffect = try await processExperience(input)
            try await eventStore.append(.priorSynthesisCompleted(priorEffect))

            // INTENTION - Goal analysis
            let intentionEffect = try await processIntention(input)
            try await eventStore.append(.intentionEffectGenerated(intentionEffect))

            // OBSERVATION - Network knowledge update
            let observationEffect = try await processObservation(input)
            try await eventStore.append(.observationEffectGenerated(observationEffect))

            // UNDERSTANDING - System state evaluation
            let understandingEffect = try await processUnderstanding()
            try await eventStore.append(.understandingEffectGenerated(understandingEffect))

            // Check for continuation
            if try await shouldContinue(understandingEffect) {
                try await eventStore.append(.loopDecided(shouldLoop: true, reason: "understanding indicates continuation"))
                return try await runCycle(input)
            }

            // YIELD - Finalize across network
            let response = try await processYield()
            try await eventStore.append(.cycleCompleted(response))
            return response

        } onCancel: {
            Task {
                try? await cleanupDistributedResources()
            }
        }
    }
}

// Step implementations
extension ChorusCycleManager {
    private func processAction(_ input: String) async throws -> Effect {
        try await eventStore.append(.actionStarted(input: input))

        // Coordinate with AI service
        let response = try await llm.complete(input)
        let confidence = try await llm.getConfidence(response)

        try await eventStore.append(.actionGenerated(
            response: response,
            confidence: confidence
        ))

        return Effect(type: .action, content: response)
    }

    private func processExperience(_ input: String) async throws -> Effect {
        try await eventStore.append(.priorSearchStarted(query: input))

        // Coordinate vector search
        let embedding = try await embeddings.embed(input)
        let priors = try await vectors.search(embedding, limit: 80)

        try await eventStore.append(.priorsFound(
            count: priors.count,
            relevance: calculateRelevance(priors)
        ))

        let synthesis = try await synthesizePriors(input, priors)
        return Effect(type: .experience, content: synthesis)
    }

    // Similar implementations for other steps...
}
```

## Effect Generation

Distributed effect coordination:

```swift
// Effect generation with network coordination
actor EffectManager {
    private let eventStore: EventStore
    private let ai: FoundationModelActor
    private let vectors: VectorStoreActor

    func generateEffect(
        type: EffectType,
        content: String
    ) async throws -> Effect {
        let effect = Effect(type: type, content: content)

        // Generate embedding
        let embedding = try await ai.embed(content)

        // Store in vector database
        try await vectors.store(embedding, metadata: effect.metadata)

        // Record effect generation
        try await eventStore.append(.effectGenerated(
            type: type,
            content: content
        ))

        return effect
    }
}
```

## Prior Flow

Network knowledge coordination:

```swift
// Prior management with distributed coordination
actor PriorManager {
    private let eventStore: EventStore
    private let vectors: VectorStoreActor
    private let embeddings: EmbeddingActor
    private var activePriors: [UUID: Prior] = [:]

    func recordPriors(_ priors: [Prior], in message: Message) async throws {
        try await eventStore.append(.priorRecordingStarted(
            count: priors.count,
            messageId: message.id
        ))

        // Generate and store embeddings
        for prior in priors {
            let embedding = try await embeddings.embed(prior.content)
            try await vectors.store(embedding, metadata: prior.metadata)

            try await eventStore.append(.citationRecorded(
                source: prior,
                target: message
            ))
        }

        try await eventStore.append(.priorsRecorded(
            count: priors.count,
            messageId: message.id
        ))
    }
}
```

This implementation provides:

1. Distributed cycle processing
2. Network service coordination
3. Knowledge synchronization
4. Effect propagation
5. System resilience

The system ensures:

- Event sequence integrity
- Network coherence
- Effect distribution
- Knowledge growth
- Resource management
