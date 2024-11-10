# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Account System Evolution

## Phase 1: Qdrant Collections

```swift
// Initial data model in Qdrant
struct Collections {
    // Users collection
    let users = Collection(
        name: "users",
        schema: [
            "id": "PublicKey",           // Solana address
            "display_name": "String",     // User name
            "avatar_url": "String?",      // Profile image
            "created_at": "Date",         // Join date
            "embedding": "[Float]"        // User embedding
        ]
    )

    // Threads collection
    let threads = Collection(
        name: "threads",
        schema: [
            "id": "UUID",                // Thread ID
            "creator": "PublicKey",      // Thread creator
            "title": "String",           // Thread title
            "created_at": "Date",        // Creation date
            "embedding": "[Float]",      // Thread embedding
            "state": "ThreadState"       // Current state
        ]
    )

    // Messages collection
    let messages = Collection(
        name: "messages",
        schema: [
            "id": "UUID",               // Message ID
            "thread_id": "UUID",        // Parent thread
            "author": "PublicKey",      // Message author
            "content": "String",        // Message text
            "embedding": "[Float]",     // Message embedding
            "created_at": "Date",       // Timestamp
            "priors": "[UUID]"         // Prior citations
        ]
    )
}
```

## Phase 2: Hybrid State

```swift
// Bridge between Qdrant and Solana
struct HybridState {
    // Thread program state
    let onChain = [
        "thread_id": "UUID",          // Thread identifier
        "creator": "PublicKey",       // Thread creator
        "co_authors": "[PublicKey]",  // Approved authors
        "stake": "u64",              // Token stake
        "state": "ThreadState"       // Program state
    ]

    // Rich content in Qdrant
    let offChain = [
        "messages": "[Message]",      // Full messages
        "embeddings": "[Float]",      // Vector data
        "metadata": "JSON",          // Extra data
        "priors": "[Citation]"      // Prior links
    ]
}
```

## Implementation

1. **User Management**

```swift
class UserManager {
    private let qdrant: QdrantClient
    private let solana: SolanaSwift

    // Phase 1: Qdrant only
    func createUser(wallet: PublicKey) async throws {
        let user = User(
            id: wallet,
            created_at: Date()
        )
        try await qdrant.upsert("users", points: [user])
    }

    // Phase 2: Hybrid
    func getUser(wallet: PublicKey) async throws -> User {
        let onChain = try await solana.getBalance(wallet)
        let offChain = try await qdrant.get("users", id: wallet)
        return User(onChain: onChain, offChain: offChain)
    }
}
```

2. **Thread Management**

```swift
class ThreadManager {
    // Phase 1: Qdrant storage
    func createThread(creator: PublicKey) async throws -> UUID {
        let thread = Thread(
            id: UUID(),
            creator: creator,
            created_at: Date()
        )
        try await qdrant.upsert("threads", points: [thread])
        return thread.id
    }

    // Phase 2: Program creation
    func createThreadProgram(creator: PublicKey) async throws -> UUID {
        let threadId = UUID()
        // Create Solana program instance
        let program = try await solana.createThread(
            creator: creator,
            threadId: threadId
        )
        // Store rich data
        try await qdrant.upsert("threads", points: [
            Thread(id: threadId, program: program)
        ])
        return threadId
    }
}
```

## Migration Path

```swift
struct Migration {
    // Phase 1: Simple storage
    let initial = [
        "User profiles in Qdrant",
        "Thread metadata in Qdrant",
        "Messages in Qdrant",
        "Simple wallet auth"
    ]

    // Phase 2: Program integration
    let evolution = [
        "Thread programs on Solana",
        "Token staking/rewards",
        "On-chain governance",
        "Distributed ownership"
    ]
}
```

The key benefits:

1. Start simple with Qdrant
2. Add Solana features gradually
3. Keep rich data searchable
4. Enable token mechanics
5. Natural evolution path
