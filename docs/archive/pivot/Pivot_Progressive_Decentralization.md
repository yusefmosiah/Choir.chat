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
# Progressive Decentralization Strategy

## Phase 1: Centralized Service Layer (Current)
```swift
class APIService: ChoirService {
    // Centralized services
    func searchPriors(_ content: String) async throws -> [Prior] {
        // Call our Qdrant instance
        return try await post("/search", body: content)
    }
}
```

## Phase 2: Hybrid Model (Mid-term)
```swift
class HybridService: ChoirService {
    private let localVectors: LocalVectorDB  // On-device search
    private let cloudService: APIService     // Cloud fallback

    func searchPriors(_ content: String) async throws -> [Prior] {
        // Try local first
        let localResults = try await localVectors.search(content)

        if localResults.count >= 80 {
            return localResults
        }

        // Fallback to cloud for more results
        let cloudResults = try await cloudService.searchPriors(content)
        return merge(localResults, cloudResults)
    }
}
```

## Phase 3: Decentralized (Long-term)
```swift
class P2PService: ChoirService {
    private let localVectors: LocalVectorDB
    private let peerNetwork: PeerNetwork

    func searchPriors(_ content: String) async throws -> [Prior] {
        // Search strategies
        try await withThrowingTaskGroup(of: [Prior].self) { group in
            // Local search
            group.addTask {
                try await localVectors.search(content)
            }

            // Peer searches
            let peers = await peerNetwork.getNearestPeers(10)
            for peer in peers {
                group.addTask {
                    try await peer.search(content)
                }
            }

            // Combine results
            return try await group.reduce(into: []) { $0 += $1 }
        }
    }

    func recordSemanticLink(_ link: SemanticLink) async throws {
        // Store locally
        try await localVectors.store(link)

        // Share with peers
        try await peerNetwork.broadcast(link)
    }
}
```

## Progressive Features

1. **Vector Search**
```swift
// Phase 1: Central Qdrant
let results = try await qdrant.search(vector)

// Phase 2: Local + Cloud
let local = try await localDB.search(vector)
let cloud = try await cloudDB.search(vector)

// Phase 3: P2P Network
let results = try await peerNetwork.searchAcrossPeers(vector)
```

2. **State Management**
```swift
// Phase 1: WebSocket to server
socket.send(message)

// Phase 2: Local-first with sync
await localStore.save(message)
await cloudSync.push(message)

// Phase 3: P2P sync
await peerNetwork.broadcast(message)
```

3. **AI Processing**
```swift
// Phase 1: OpenAI API
let response = try await openai.complete(prompt)

// Phase 2: On-device for simple tasks
if canProcessLocally(prompt) {
    return try await localAI.process(prompt)
} else {
    return try await openai.complete(prompt)
}

// Phase 3: Distributed inference
let results = try await peerNetwork.distributedInference(prompt)
```

## Benefits

1. **Progressive Independence**
- Start centralized for MVP
- Add local capabilities
- Transition to P2P
- Users gain autonomy

2. **Economic Efficiency**
- Lower server costs
- Shared resources
- Network effects
- User incentives

3. **Technical Resilience**
- No single point of failure
- Graceful degradation
- Network redundancy
- Local-first data
