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

=== File: docs/tree.md ===



==
tree.md
==


# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__|iOS_Example' | pbcopy

.
├── Choir
│   ├── App
│   │   └── ChoirApp.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── Choir.entitlements
│   ├── ContentView.swift
│   ├── Coordinators
│   │   ├── MockChorusCoordinator.swift
│   │   └── RESTChorusCoordinator.swift
│   ├── Info.plist
│   ├── Models
│   │   ├── ChoirThread.swift
│   │   ├── ChorusModels.swift
│   │   └── Phase.swift
│   ├── Networking
│   │   └── ChorusAPIClient.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Protocols
│   │   └── ChorusCoordinator.swift
│   ├── Services
│   │   ├── KeychainService.swift
│   │   └── WalletManager.swift
│   ├── ViewModels
│   │   └── ChorusViewModel.swift
│   └── Views
│       ├── ChoirThreadDetailView.swift
│       ├── ChorusCycleView.swift
│       ├── ChorusResponse.swift
│       ├── MessageRow.swift
│       └── WalletView.swift
├── Choir.xcodeproj
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── swiftpm
│   │   │       ├── Package.resolved
│   │   │       └── configuration
│   │   └── xcuserdata
│   │       └── wiz.xcuserdatad
│   │           ├── IDEFindNavigatorScopes.plist
│   │           └── UserInterfaceState.xcuserstate
│   └── xcuserdata
│       └── wiz.xcuserdatad
│           └── xcschemes
│               └── xcschememanagement.plist
├── ChoirTests
│   ├── APIResponseTests.swift
│   ├── ChoirTests.swift
│   ├── ChoirThreadTests.swift
│   └── ChorusAPIClientTests.swift
├── ChoirUITests
│   ├── ChoirUITests.swift
│   └── ChoirUITestsLaunchTests.swift
├── api
│   ├── Dockerfile
│   ├── __init__.py
│   ├── app
│   │   ├── __init__.py
│   │   ├── chorus_cycle.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   └── api.py
│   │   ├── routers
│   │   │   ├── balance.py
│   │   │   ├── chorus.py
│   │   │   ├── embeddings.py
│   │   │   ├── threads.py
│   │   │   ├── users.py
│   │   │   ├── vectors.py
│   │   │   └── wallet.py
│   │   ├── services
│   │   │   ├── __init__.py
│   │   │   ├── chorus.py
│   │   │   ├── sui_service.py
│   │   │   └── wallet_manager.py
│   │   └── utils.py
│   ├── main.py
│   ├── pyproject.toml
│   ├── pytest.ini
│   ├── requirements.txt
│   ├── run_tests.sh
│   └── tests
│       ├── __init__.py
│       ├── conftest.py
│       ├── test_chorus_endpoints.py
│       ├── test_core_endpoints.py
│       ├── test_main.py
│       ├── test_response_schemas.py
│       ├── test_structured_outputs.py
│       ├── test_sui_service.py
│       └── test_user_thread_endpoints.py
├── choir_coin
│   └── choir_coin
│       ├── Move.lock
│       ├── Move.toml
│       ├── build
│       │   ├── choir
│       │   │   ├── BuildInfo.yaml
│       │   │   ├── bytecode_modules
│       │   │   │   ├── choir.mv
│       │   │   │   └── dependencies
│       │   │   │       ├── MoveStdlib
│       │   │   │       │   ├── address.mv
│       │   │   │       │   ├── ascii.mv
│       │   │   │       │   ├── bcs.mv
│       │   │   │       │   ├── bit_vector.mv
│       │   │   │       │   ├── debug.mv
│       │   │   │       │   ├── fixed_point32.mv
│       │   │   │       │   ├── hash.mv
│       │   │   │       │   ├── macros.mv
│       │   │   │       │   ├── option.mv
│       │   │   │       │   ├── string.mv
│       │   │   │       │   ├── type_name.mv
│       │   │   │       │   ├── u128.mv
│       │   │   │       │   ├── u16.mv
│       │   │   │       │   ├── u256.mv
│       │   │   │       │   ├── u32.mv
│       │   │   │       │   ├── u64.mv
│       │   │   │       │   ├── u8.mv
│       │   │   │       │   ├── uq32_32.mv
│       │   │   │       │   └── vector.mv
│       │   │   │       └── Sui
│       │   │   │           ├── address.mv
│       │   │   │           ├── authenticator_state.mv
│       │   │   │           ├── bag.mv
│       │   │   │           ├── balance.mv
│       │   │   │           ├── bcs.mv
│       │   │   │           ├── bls12381.mv
│       │   │   │           ├── borrow.mv
│       │   │   │           ├── clock.mv
│       │   │   │           ├── coin.mv
│       │   │   │           ├── config.mv
│       │   │   │           ├── deny_list.mv
│       │   │   │           ├── display.mv
│       │   │   │           ├── dynamic_field.mv
│       │   │   │           ├── dynamic_object_field.mv
│       │   │   │           ├── ecdsa_k1.mv
│       │   │   │           ├── ecdsa_r1.mv
│       │   │   │           ├── ecvrf.mv
│       │   │   │           ├── ed25519.mv
│       │   │   │           ├── event.mv
│       │   │   │           ├── groth16.mv
│       │   │   │           ├── group_ops.mv
│       │   │   │           ├── hash.mv
│       │   │   │           ├── hex.mv
│       │   │   │           ├── hmac.mv
│       │   │   │           ├── kiosk.mv
│       │   │   │           ├── kiosk_extension.mv
│       │   │   │           ├── linked_table.mv
│       │   │   │           ├── math.mv
│       │   │   │           ├── object.mv
│       │   │   │           ├── object_bag.mv
│       │   │   │           ├── object_table.mv
│       │   │   │           ├── package.mv
│       │   │   │           ├── pay.mv
│       │   │   │           ├── poseidon.mv
│       │   │   │           ├── priority_queue.mv
│       │   │   │           ├── prover.mv
│       │   │   │           ├── random.mv
│       │   │   │           ├── sui.mv
│       │   │   │           ├── table.mv
│       │   │   │           ├── table_vec.mv
│       │   │   │           ├── token.mv
│       │   │   │           ├── transfer.mv
│       │   │   │           ├── transfer_policy.mv
│       │   │   │           ├── tx_context.mv
│       │   │   │           ├── types.mv
│       │   │   │           ├── url.mv
│       │   │   │           ├── vdf.mv
│       │   │   │           ├── vec_map.mv
│       │   │   │           ├── vec_set.mv
│       │   │   │           ├── versioned.mv
│       │   │   │           ├── zklogin_verified_id.mv
│       │   │   │           └── zklogin_verified_issuer.mv
│       │   │   ├── source_maps
│       │   │   │   ├── choir.json
│       │   │   │   ├── choir.mvsm
│       │   │   │   └── dependencies
│       │   │   │       ├── MoveStdlib
│       │   │   │       │   ├── address.json
│       │   │   │       │   ├── address.mvsm
│       │   │   │       │   ├── ascii.json
│       │   │   │       │   ├── ascii.mvsm
│       │   │   │       │   ├── bcs.json
│       │   │   │       │   ├── bcs.mvsm
│       │   │   │       │   ├── bit_vector.json
│       │   │   │       │   ├── bit_vector.mvsm
│       │   │   │       │   ├── debug.json
│       │   │   │       │   ├── debug.mvsm
│       │   │   │       │   ├── fixed_point32.json
│       │   │   │       │   ├── fixed_point32.mvsm
│       │   │   │       │   ├── hash.json
│       │   │   │       │   ├── hash.mvsm
│       │   │   │       │   ├── macros.json
│       │   │   │       │   ├── macros.mvsm
│       │   │   │       │   ├── option.json
│       │   │   │       │   ├── option.mvsm
│       │   │   │       │   ├── string.json
│       │   │   │       │   ├── string.mvsm
│       │   │   │       │   ├── type_name.json
│       │   │   │       │   ├── type_name.mvsm
│       │   │   │       │   ├── u128.json
│       │   │   │       │   ├── u128.mvsm
│       │   │   │       │   ├── u16.json
│       │   │   │       │   ├── u16.mvsm
│       │   │   │       │   ├── u256.json
│       │   │   │       │   ├── u256.mvsm
│       │   │   │       │   ├── u32.json
│       │   │   │       │   ├── u32.mvsm
│       │   │   │       │   ├── u64.json
│       │   │   │       │   ├── u64.mvsm
│       │   │   │       │   ├── u8.json
│       │   │   │       │   ├── u8.mvsm
│       │   │   │       │   ├── uq32_32.json
│       │   │   │       │   ├── uq32_32.mvsm
│       │   │   │       │   ├── vector.json
│       │   │   │       │   └── vector.mvsm
│       │   │   │       └── Sui
│       │   │   │           ├── address.json
│       │   │   │           ├── address.mvsm
│       │   │   │           ├── authenticator_state.json
│       │   │   │           ├── authenticator_state.mvsm
│       │   │   │           ├── bag.json
│       │   │   │           ├── bag.mvsm
│       │   │   │           ├── balance.json
│       │   │   │           ├── balance.mvsm
│       │   │   │           ├── bcs.json
│       │   │   │           ├── bcs.mvsm
│       │   │   │           ├── bls12381.json
│       │   │   │           ├── bls12381.mvsm
│       │   │   │           ├── borrow.json
│       │   │   │           ├── borrow.mvsm
│       │   │   │           ├── clock.json
│       │   │   │           ├── clock.mvsm
│       │   │   │           ├── coin.json
│       │   │   │           ├── coin.mvsm
│       │   │   │           ├── config.json
│       │   │   │           ├── config.mvsm
│       │   │   │           ├── deny_list.json
│       │   │   │           ├── deny_list.mvsm
│       │   │   │           ├── display.json
│       │   │   │           ├── display.mvsm
│       │   │   │           ├── dynamic_field.json
│       │   │   │           ├── dynamic_field.mvsm
│       │   │   │           ├── dynamic_object_field.json
│       │   │   │           ├── dynamic_object_field.mvsm
│       │   │   │           ├── ecdsa_k1.json
│       │   │   │           ├── ecdsa_k1.mvsm
│       │   │   │           ├── ecdsa_r1.json
│       │   │   │           ├── ecdsa_r1.mvsm
│       │   │   │           ├── ecvrf.json
│       │   │   │           ├── ecvrf.mvsm
│       │   │   │           ├── ed25519.json
│       │   │   │           ├── ed25519.mvsm
│       │   │   │           ├── event.json
│       │   │   │           ├── event.mvsm
│       │   │   │           ├── groth16.json
│       │   │   │           ├── groth16.mvsm
│       │   │   │           ├── group_ops.json
│       │   │   │           ├── group_ops.mvsm
│       │   │   │           ├── hash.json
│       │   │   │           ├── hash.mvsm
│       │   │   │           ├── hex.json
│       │   │   │           ├── hex.mvsm
│       │   │   │           ├── hmac.json
│       │   │   │           ├── hmac.mvsm
│       │   │   │           ├── kiosk.json
│       │   │   │           ├── kiosk.mvsm
│       │   │   │           ├── kiosk_extension.json
│       │   │   │           ├── kiosk_extension.mvsm
│       │   │   │           ├── linked_table.json
│       │   │   │           ├── linked_table.mvsm
│       │   │   │           ├── math.json
│       │   │   │           ├── math.mvsm
│       │   │   │           ├── object.json
│       │   │   │           ├── object.mvsm
│       │   │   │           ├── object_bag.json
│       │   │   │           ├── object_bag.mvsm
│       │   │   │           ├── object_table.json
│       │   │   │           ├── object_table.mvsm
│       │   │   │           ├── package.json
│       │   │   │           ├── package.mvsm
│       │   │   │           ├── pay.json
│       │   │   │           ├── pay.mvsm
│       │   │   │           ├── poseidon.json
│       │   │   │           ├── poseidon.mvsm
│       │   │   │           ├── priority_queue.json
│       │   │   │           ├── priority_queue.mvsm
│       │   │   │           ├── prover.json
│       │   │   │           ├── prover.mvsm
│       │   │   │           ├── random.json
│       │   │   │           ├── random.mvsm
│       │   │   │           ├── sui.json
│       │   │   │           ├── sui.mvsm
│       │   │   │           ├── table.json
│       │   │   │           ├── table.mvsm
│       │   │   │           ├── table_vec.json
│       │   │   │           ├── table_vec.mvsm
│       │   │   │           ├── token.json
│       │   │   │           ├── token.mvsm
│       │   │   │           ├── transfer.json
│       │   │   │           ├── transfer.mvsm
│       │   │   │           ├── transfer_policy.json
│       │   │   │           ├── transfer_policy.mvsm
│       │   │   │           ├── tx_context.json
│       │   │   │           ├── tx_context.mvsm
│       │   │   │           ├── types.json
│       │   │   │           ├── types.mvsm
│       │   │   │           ├── url.json
│       │   │   │           ├── url.mvsm
│       │   │   │           ├── vdf.json
│       │   │   │           ├── vdf.mvsm
│       │   │   │           ├── vec_map.json
│       │   │   │           ├── vec_map.mvsm
│       │   │   │           ├── vec_set.json
│       │   │   │           ├── vec_set.mvsm
│       │   │   │           ├── versioned.json
│       │   │   │           ├── versioned.mvsm
│       │   │   │           ├── zklogin_verified_id.json
│       │   │   │           ├── zklogin_verified_id.mvsm
│       │   │   │           ├── zklogin_verified_issuer.json
│       │   │   │           └── zklogin_verified_issuer.mvsm
│       │   │   └── sources
│       │   │       ├── choir.move
│       │   │       └── dependencies
│       │   │           ├── MoveStdlib
│       │   │           │   ├── address.move
│       │   │           │   ├── ascii.move
│       │   │           │   ├── bcs.move
│       │   │           │   ├── bit_vector.move
│       │   │           │   ├── debug.move
│       │   │           │   ├── fixed_point32.move
│       │   │           │   ├── hash.move
│       │   │           │   ├── macros.move
│       │   │           │   ├── option.move
│       │   │           │   ├── string.move
│       │   │           │   ├── type_name.move
│       │   │           │   ├── u128.move
│       │   │           │   ├── u16.move
│       │   │           │   ├── u256.move
│       │   │           │   ├── u32.move
│       │   │           │   ├── u64.move
│       │   │           │   ├── u8.move
│       │   │           │   ├── uq32_32.move
│       │   │           │   └── vector.move
│       │   │           └── Sui
│       │   │               ├── address.move
│       │   │               ├── authenticator_state.move
│       │   │               ├── bag.move
│       │   │               ├── balance.move
│       │   │               ├── bcs.move
│       │   │               ├── bls12381.move
│       │   │               ├── borrow.move
│       │   │               ├── clock.move
│       │   │               ├── coin.move
│       │   │               ├── config.move
│       │   │               ├── deny_list.move
│       │   │               ├── display.move
│       │   │               ├── dynamic_field.move
│       │   │               ├── dynamic_object_field.move
│       │   │               ├── ecdsa_k1.move
│       │   │               ├── ecdsa_r1.move
│       │   │               ├── ecvrf.move
│       │   │               ├── ed25519.move
│       │   │               ├── event.move
│       │   │               ├── groth16.move
│       │   │               ├── group_ops.move
│       │   │               ├── hash.move
│       │   │               ├── hex.move
│       │   │               ├── hmac.move
│       │   │               ├── kiosk.move
│       │   │               ├── kiosk_extension.move
│       │   │               ├── linked_table.move
│       │   │               ├── math.move
│       │   │               ├── object.move
│       │   │               ├── object_bag.move
│       │   │               ├── object_table.move
│       │   │               ├── package.move
│       │   │               ├── pay.move
│       │   │               ├── poseidon.move
│       │   │               ├── priority_queue.move
│       │   │               ├── prover.move
│       │   │               ├── random.move
│       │   │               ├── sui.move
│       │   │               ├── table.move
│       │   │               ├── table_vec.move
│       │   │               ├── token.move
│       │   │               ├── transfer.move
│       │   │               ├── transfer_policy.move
│       │   │               ├── tx_context.move
│       │   │               ├── types.move
│       │   │               ├── url.move
│       │   │               ├── vdf.move
│       │   │               ├── vec_map.move
│       │   │               ├── vec_set.move
│       │   │               ├── versioned.move
│       │   │               ├── zklogin_verified_id.move
│       │   │               └── zklogin_verified_issuer.move
│       │   └── locks
│       ├── sources
│       │   └── choir_coin.move
│       └── tests
│           └── choir_coin_tests.move
└── docs
    ├── CHANGELOG.md
    ├── Impl_Security.md
    ├── Meta_Evolution.md
    ├── Model_Foundation_Evolution.md
    ├── Model_Metastability.md
    ├── core_architecture.md
    ├── core_chorus.md
    ├── core_core.md
    ├── core_economics.md
    ├── core_knowledge.md
    ├── core_patterns.md
    ├── core_state.md
    ├── core_state_transitions.md
    ├── data_engine_model.md
    ├── docs_dev_principles.md
    ├── docs_operators.md
    ├── e_business.md
    ├── e_concept.md
    ├── e_questions.md
    ├── e_reference.md
    ├── goal_architecture.md
    ├── goal_evolution.md
    ├── goal_implementation.md
    ├── goal_wed_nov_13_2024.md
    ├── harmonic_intelligence.md
    ├── issues
    │   ├── issue_0.md
    │   ├── issue_1.md
    │   ├── issue_10.md
    │   ├── issue_11.md
    │   ├── issue_12.md
    │   ├── issue_13.md
    │   ├── issue_2.md
    │   ├── issue_5.md
    │   ├── issue_7.md
    │   ├── issue_8.md
    │   └── issue_9.md
    ├── levels
    │   ├── level-1.md
    │   ├── level0.md
    │   ├── level1.md
    │   ├── level2.md
    │   ├── level3.md
    │   ├── level4.md
    │   ├── level5.md
    │   └── level_organization.md
    ├── plan_carousel_ui_pattern.md
    ├── plan_chuser_chthread_chmessage.md
    ├── plan_client_architecture.md
    ├── plan_id_persistence.md
    ├── plan_post-training.md
    ├── plan_proxy_authentication.md
    ├── plan_proxy_security_model.md
    ├── plan_save_users_and_threads.md
    ├── plan_sui_blockchain_integration.md
    ├── plan_swiftdata_required_changes.md
    ├── plan_swiftui_chorus_integration.md
    ├── plan_thoughtspace.md
    ├── plan_tokenomics.md
    ├── prompt_chorus_cycle.md
    ├── prompt_getting_started.md
    ├── prompt_reentry.md
    ├── prompt_summary_prompt.md
    ├── prompt_wake_up.md
    ├── reward_model.md
    ├── scripts
    │   ├── combiner.sh
    │   └── update_tree.sh
    ├── self_creation_process.md
    ├── theory_choir_harmonics.md
    ├── theory_dynamics.md
    ├── theory_economics.md
    ├── theory_foundation.md
    ├── theory_harmonic_intelligence.md
    ├── theory_oscillator_cooling.md
    ├── theory_theory.md
    └── tree.md

56 directories, 436 files

=== File: docs/CHANGELOG.md ===



==
CHANGELOG.md
==


# Changelog

## [Unreleased]

### Added
- Initial Chorus cycle working in iOS simulator
  - Basic message flow through phases
  - Response handling
  - State management

### Documented
- Created 15 comprehensive issues covering:
  - Core message system implementation
  - Type reconciliation with Qdrant
  - API client updates
  - Coordinator message flow
  - User identity management
  - Thread state management
  - Integration testing
  - Error handling strategy
  - Performance monitoring
  - State recovery
  - Thread sheet implementation
  - Thread contract implementation
  - Message rewards system
  - LanceDB migration
  - Citation visualization

### Architecture
- Defined clear type system for messages
- Planned migration to LanceDB
- Structured multimodal support strategy
- Documented quantum harmonic oscillator model implementation

### Technical Debt
- Identified areas needing more specification:
  - Thread Sheet UI (marked as "AI SLOP")
  - Reward formulas need verification
  - Migration pipeline needs careful implementation

## [0.4.2] - 2024-11-09

### Added
- Development principles with focus on groundedness
- Basic chat interface implementation
- SwiftData message persistence
- Initial Action step foundation

### Changed
- Shifted to iterative, ground-up development approach
- Simplified initial implementation scope
- Focused on working software over theoretical architecture
- Adopted step-by-step Chorus Cycle implementation strategy

### Principles
- Established groundedness as core development principle
- Emphasized iterative growth and natural evolution
- Prioritized practical progress over theoretical completeness
- Introduced flexible, evidence-based development flow

## [0.4.1] - 2024-11-08

### Added
- Self-creation process
- Post-training concepts
- Concurrent processing ideas
- Democratic framing
- Thoughtspace visualization

### Changed
- Renamed Update to Understanding
- Enhanced step descriptions
- Refined documentation focus
- Improved pattern recognition

## [0.4.0] - 2024-10-30

### Added
- Swift architecture plans
- Frontend-driven design
- Service layer concepts
- Chorus cycle definition

### Changed
- Enhanced system architecture
- Refined core patterns

## [0.3.5] - 2024-09-01
- Choir.chat as a web3 dapp
- messed around with solana
- used a lot of time messing with next.js/react/typescript/javascript
- recognized that browser extension wallet is terrible ux

## [0.3.0] - 2024-03-01
### Added
- ChoirGPT development from winter 2023 to spring 2024

- First developed as a ChatGPT plugin, then a Custom GPT
- The first global RAG system / collective intelligence as a GPT

## [0.2.10] - 2023-04-01

### Added
- Ahpta development from winter 2022 to spring 2023

## [0.2.9] - 2022-04-01

### Added
- V10 development from fall 2021 to winter 2022


## [0.2.8] - 2021-04-01

### Added
- Elevisio development from spring 2020 to spring 2021

## [0.2.7] - 2020-04-01

### Added
- Bluem development from spring 2019 to spring 2020

## [0.2.6] - 2019-04-01

### Added
- Blocstar development from fall 2018 to spring 2019


## [0.2.5] - 2018-04-01

### Added
- Phase4word development from summer 2017 to spring 2018

### Changed
- Showed Phase4word to ~50 people in spring 2018, received critical feedback
- Codebase remains in 2018 vintage

## [0.2.0] - 2016-06-20

### Added
- Phase4 party concept
- Early democracy technology
- Initial value systems

### Changed
- Moved beyond truth measurement framing
- Refined core concepts

## [0.1.0] - 2015-07-15

### Added
- Initial simulation hypothesis insight
- "Kandor"
- Quantum information concepts
- Planetary coherence vision
- Core system ideas
