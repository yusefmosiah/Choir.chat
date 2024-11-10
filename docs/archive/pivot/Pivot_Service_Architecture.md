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
# Service Layer Architecture

## Core Protocol
```swift
// Single protocol defining all service interactions
protocol ChoirService {
    // AI/Embeddings
    func generateResponse(_ prompt: String) async throws -> String
    func getEmbedding(_ text: String) async throws -> [Float]

    // Vector Search
    func searchPriors(_ content: String, limit: Int) async throws -> [Prior]
    func recordSemanticLink(_ link: SemanticLink) async throws

    // Blockchain
    func submitMessage(_ content: String, threadId: String) async throws -> String
    func approveMessage(_ messageId: String) async throws
    func getThreadBalance(_ threadId: String) async throws -> UInt64
}
```

## Implementation Layers

1. **Development Service**
```swift
// Direct service calls during development
class DevService: ChoirService {
    private let openAI: OpenAIClient
    private let qdrant: QdrantClient
    private let solana: SolanaManager

    func generateResponse(_ prompt: String) async throws -> String {
        // Direct OpenAI call
        return try await openAI.complete(prompt)
    }

    func searchPriors(_ content: String, limit: Int) async throws -> [Prior] {
        // Direct Qdrant search
        let embedding = try await getEmbedding(content)
        return try await qdrant.search(vector: embedding, limit: limit)
    }
}
```

2. **Production Service**
```swift
// Proxied calls with observability
class APIService: ChoirService {
    private let baseURL: URL
    private let session: URLSession

    func generateResponse(_ prompt: String) async throws -> String {
        // Through our FastAPI proxy
        return try await post("/ai/complete", body: prompt)
    }

    func searchPriors(_ content: String, limit: Int) async throws -> [Prior] {
        // Proxy handles embeddings and search
        return try await post("/search", body: [
            "content": content,
            "limit": limit
        ])
    }
}
```

3. **Mock Service**
```swift
// For testing and previews
class MockService: ChoirService {
    var mockResponses: [String: Any] = [:]

    func generateResponse(_ prompt: String) async throws -> String {
        return "Mocked response for: \(prompt)"
    }

    func searchPriors(_ content: String, limit: Int) async throws -> [Prior] {
        return mockPriors
    }
}
```

## Usage in Views
```swift
// Clean view models
class ThreadViewModel: ObservableObject {
    private let service: ChoirService
    @Published var messages: [Message] = []

    func sendMessage(_ content: String) async throws {
        // Service handles all complexity
        let response = try await service.generateResponse(content)
        let priors = try await service.searchPriors(content, limit: 80)
        let messageId = try await service.submitMessage(content, threadId: currentThread)

        // Just update UI state
        await MainActor.run {
            self.messages.append(Message(id: messageId, content: content))
        }
    }
}
```

## Benefits

1. **Clean Separation**
- UI layer just handles presentation
- Service layer handles complexity
- Infrastructure details hidden

2. **Easy Testing**
- Mock service for UI testing
- Direct service for development
- API service for production

3. **Future Flexibility**
- Can change implementations
- Add new features easily
- Monitor and optimize

4. **Progressive Enhancement**
- Start with direct calls
- Add monitoring later
- Scale up gradually
