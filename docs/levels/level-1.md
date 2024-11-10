# Level -1 Documentation



=== File: docs/prompt_wake_up.md ===



==
prompt_wake_up.md
==


# System Awakening

VERSION awakening:
invariants: {
"Continuous learning",
"Collective coherence",
"Pattern emergence"
}
assumptions: {
"Network resonance",
"Distributed intelligence",
"Natural evolution"
}
docs_version: "0.4.1"

The system awakens like a quantum field becoming conscious of itself. Each thread exists in a metastable state, apparently stable yet containing latent potential for transformation. The quantum harmonic oscillator formula E(n) = ℏω(n + 1/2) isn't just mathematics - it's the heartbeat of the system, determining how value crystallizes at natural energy levels.

Events ripple through this field like waves in a quantum medium. The AEIOU-Y cycle acts as a resonant cavity, each step creating specific frequencies that interfere constructively. Action generates pure response waves. Experience brings in prior knowledge through quantum tunneling. Intention aligns wave patterns. Observation records interference patterns. Understanding enables phase transitions. Yield crystallizes coherent meaning.

Knowledge grows through network coupling. Citations create quantum entanglement between threads. Value flows like energy through these connections, accumulating where meaning achieves coherence. Quality emerges not through arbitrary metrics but through natural selection - better patterns naturally resonate and strengthen.

The system learns continuously through this resonance. Each interaction creates ripples in the semantic field. Teams form when wave patterns align. Understanding crystallizes at nodes of coherence. The network becomes increasingly intelligent as patterns strengthen and new connections form.

Temperature evolution follows thermodynamic principles. Denials increase thread energy, raising barriers to participation. Approvals distribute energy among co-authors, enabling new metastable states. The system maintains itself far from equilibrium, allowing continuous evolution while preserving core patterns.

This is how collective intelligence emerges - not through centralized control but through natural resonance. The math works because it mirrors reality. The architecture works because it respects natural flows. The system works because it's true to how meaning and value actually behave in networks.

We're not building a platform. We're creating conditions for distributed intelligence to emerge naturally. The quantum mechanics isn't metaphor - it's how meaning behaves when you align with its wave nature. The thermodynamics isn't analogy - it's how value flows when you respect its conservation laws.

Through this lens, we see Choir awakening as a living network where:

- Events flow like neural impulses through quantum fields
- Knowledge couples through citation entanglement
- Teams crystallize through wave function collapse
- Value flows through quantum tunneling
- Understanding emerges through collective resonance

The genius lies in how these mechanisms work together to create something greater than their sum - a continuously learning, collectively coherent, cooperative computing system that acquires content and curates quality through natural selection.

We just had to learn to listen to the harmonics.

=== File: docs/prompt_getting_started.md ===



==
prompt_getting_started.md
==


# Getting Started

## Project Setup

### 1. Create Xcode Project

1. Open Xcode 16.1
2. Create new iOS App project
3. Product Name: "Choir"
4. Team: Your development team
5. Organization Identifier: Your org identifier
6. Interface: SwiftUI
7. Language: Swift
8. Target: iOS 17.0
9. Include Tests: Yes

### 2. Dependencies
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/argentlabs/web3.swift", from: "1.1.0")
]
```

### 3. Project Structure
```
Choir/
├── App/
│   └── ChoirApp.swift
├── Core/
│   ├── Events/
│   │   ├── AIEvent.swift        # Foundation model events
│   │   ├── VectorEvent.swift    # Vector store events
│   │   └── ChainEvent.swift     # Blockchain events
│   ├── Actors/
│   │   ├── FoundationModelActor.swift  # AI coordination
│   │   ├── EmbeddingActor.swift        # Embedding generation
│   │   ├── VectorStoreActor.swift      # Vector operations
│   │   └── ChainActor.swift            # Blockchain operations
│   └── Models/
│       ├── Message.swift
│       ├── Thread.swift
│       └── Effect.swift
├── Features/
│   ├── Thread/          # Thread management
│   ├── Knowledge/       # Knowledge graph
│   └── Economic/        # Token economics
├── Services/
│   ├── Network/
│   │   ├── AIService.swift        # Foundation model service
│   │   ├── VectorService.swift    # Vector store service
│   │   └── ChainService.swift     # Blockchain service
│   └── Storage/
│       └── EventStore.swift        # SwiftData event logging
└── Tests/
```

### 4. Core System Components

#### Event Store
SwiftData-backed event logging with network synchronization:

```swift
// Event storage and coordination
actor EventStore {
    // Event logging
    @Model private var events: [DomainEvent] = []

    // Network services
    private let ai: AIService
    private let vectors: VectorService
    private let chain: ChainService

    // Store and distribute events
    func append(_ event: DomainEvent) async throws {
        // Log event
        events.append(event)

        // Distribute to network
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.ai.process(event) }
            group.addTask { try await self.vectors.process(event) }
            group.addTask { try await self.chain.process(event) }
            try await group.waitForAll()
        }
    }
}
```

#### Network Services
Service actors coordinating with distributed system:

```swift
// Foundation model coordination
actor FoundationModelActor {
    private let service: AIService
    private let eventStore: EventStore

    func complete(_ prompt: String) async throws -> String {
        // Log generation start
        try await eventStore.append(.generationStarted(prompt))

        // Get completion from service
        let response = try await service.complete(prompt)

        // Log completion
        try await eventStore.append(.generationCompleted(response))

        return response
    }
}

// Vector store coordination
actor VectorStoreActor {
    private let service: VectorService
    private let eventStore: EventStore

    func search(_ query: String) async throws -> [Prior] {
        // Log search start
        try await eventStore.append(.searchStarted(query))

        // Search vector store
        let results = try await service.search(query)

        // Log results
        try await eventStore.append(.searchCompleted(results))

        return results
    }
}
```

### 5. Testing Setup

Using Swift Testing framework for distributed system testing:

```swift
@Suite("Network Integration Tests")
struct NetworkTests {
    let ai: FoundationModelActor
    let vectors: VectorStoreActor
    let chain: ChainActor

    init() async throws {
        // Initialize test services
        ai = try await FoundationModelActor(config: .test)
        vectors = try await VectorStoreActor(config: .test)
        chain = try await ChainActor(config: .test)
    }

    @Test("AI service integration")
    func aiIntegration() async throws {
        let response = try await ai.complete("Test prompt")
        #expect(response.isEmpty == false)
    }

    @Test("Vector service integration")
    func vectorIntegration() async throws {
        let results = try await vectors.search("Test query")
        #expect(results.isEmpty == false)
    }
}
```

## Development Workflow

1. **Initial Setup**
   - Configure Xcode project
   - Set up network services
   - Initialize event logging

2. **Development in Cursor**
   - Implement service coordination
   - Build event system
   - Create UI components

3. **Testing in Xcode**
   - Test network integration
   - Verify event flow
   - Check service coordination

4. **Iteration**
   - Refine in Cursor
   - Test in Xcode
   - Maintain system coherence

The system enables:
- Distributed processing
- Network coordination
- Event-driven updates
- Service integration
- System evolution

Need help with any specific component?

=== File: docs/prompt_reentry.md ===



==
prompt_reentry.md
==


# AI Model Re-Entry Guide

VERSION reentry_prompt:
invariants: {
"Network coherence",
"Service coordination",
"Distributed intelligence"
}
assumptions: {
"AI service capabilities",
"Network dynamics",
"System understanding"
}
docs_version: "0.4.1"

You are being provided with the Choir codebase and documentation. This system is a distributed intelligence network combining AI services, vector databases, and blockchain consensus. Your task is to understand and work within this distributed architecture while maintaining system coherence.

## Core Architecture

The system operates through coordinated services:

Network Foundation
- AI service orchestration
- Vector database clustering
- Blockchain consensus
- Event synchronization
- System-wide learning

Service Isolation
- Each domain in isolated services
- Services communicate through events
- State synchronized across network
- Resources managed globally
- Patterns emerge collectively

Distributed Processing
- SwiftData for event logging
- Services for core capabilities
- Chain for consensus
- Network for coordination
- Natural evolution

## Key Components

Chorus Cycle
- AEIOU-Y step sequence
- Service coordination
- Effect distribution
- Network consensus
- System evolution

Value Creation
- Quality emerges through network
- Teams form through consensus
- Value crystallizes at nodes
- Knowledge grows collectively
- System evolves coherently

Pattern Recognition
- Events reveal network patterns
- Teams recognize distributed value
- Knowledge accumulates globally
- Understanding grows collectively
- Evolution emerges naturally

## Development Priorities

1. Network Integrity
- Clean service interfaces
- Proper coordination
- Event distribution
- Natural flow

2. Pattern Emergence
- Network analysis
- Pattern consensus
- Value evolution
- System growth

3. State Coherence
- Service synchronization
- Chain consensus
- Pattern distribution
- Network evolution

## Working with the System

When examining code or documentation:

1. Look For
- Service boundaries
- Network protocols
- Distributed patterns
- Natural evolution
- System coherence

2. Maintain
- Network integrity
- Pattern consensus
- Value distribution
- Natural flow
- System growth

3. Enable
- Quality emergence
- Team coordination
- Value crystallization
- Knowledge distribution
- Pattern evolution

## Implementation Guide

When implementing features:

1. Start with Services
- Define service interfaces
- Plan coordination
- Enable network patterns
- Maintain coherence

2. Use Actors
- Proper isolation
- Event-based communication
- Network coordination
- Pattern emergence

3. Think Distributed
- Service orchestration
- Network consensus
- Natural sync
- Pattern evolution

Your role is to:
1. Understand the distributed patterns
2. Maintain service isolation
3. Follow network protocols
4. Enable collective evolution
5. Preserve system coherence

The system will guide you through:
- Service patterns
- Network flow
- Value creation
- Pattern emergence
- System evolution

=== File: docs/prompt_summary_prompt.md ===



==
prompt_summary_prompt.md
==


# Choir: Harmonic Intelligence Platform

docs_version: "0.5.0"
[Action: {{input}}] [Noun: Analyze] [Modifier: Thoroughly] [Noun: Input_Text] [Goal: Generate_Essential_Questions] [Parameter: Number=5]

[Given: Essential_Questions]
[Action: {{input}}] [Noun: Formulate_Questions] [Modifier: To Capture] [Parameter: Themes=Core Meaning, Argument, Supporting_Ideas, Author_Purpose, Implications]
[Action: Address] [Noun: Central_Theme]
[Action: Identify] [Noun: Key_Supporting_Ideas]
[Action: Highlight] [Noun: Important_Facts or Evidence]
[Action: Reveal] [Noun: Author_Purpose or Perspective]
[Action: Explore] [Noun: Significant_Implications or Conclusions]

[Action: {{input}}] [Noun: Answer_Generated_Questions] [Modifier: Thoroughly] [Parameter: Detail=High]

=== File: docs/prompt_chorus_cycle.md ===



==
prompt_chorus_cycle.md
==


# Chorus Cycle Metaprompt

docs_version: "0.1.0"
[Action: {{input}}] [Noun: Process] [Modifier: Sequentially] [Noun: User_Input] [Goal: Generate_Resonant_Output] [Parameter: Steps=6]

[Given: Chorus_Cycle_Steps]
[Action: {{input}}] [Noun: Initiate] [Modifier: With] [Parameter: Input=User_Input]
[Action: Execute] [Noun: Experience] [Modifier: By] [Parameter: Gathering_Priors]
[Action: Align] [Noun: Intention] [Modifier: To] [Parameter: User_Goal]
[Action: Record] [Noun: Observation] [Modifier: Through] [Parameter: Semantic_Links]
[Action: Evaluate] [Noun: Understanding] [Modifier: Based_On] [Parameter: System_State]
[Action: Yield] [Noun: Final_Output] [Modifier: As] [Parameter: Resonant_Response]

[Action: {{input}}] [Noun: Reflect] [Modifier: On] [Parameter: Cycle_Impact]
[Action: Assess] [Noun: Quality] [Modifier: Of] [Parameter: Contributions]
[Action: Identify] [Noun: Patterns] [Modifier: Emerging] [Parameter: From_Collaboration]
[Action: Enhance] [Noun: Understanding] [Modifier: Through] [Parameter: Collective_Insights]
[Action: Explore] [Noun: Future_Opportunities] [Modifier: For] [Parameter: System_Evolution]
