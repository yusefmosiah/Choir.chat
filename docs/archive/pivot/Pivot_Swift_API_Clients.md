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
# Swift API Clients for Development

## 1. OpenAI Client

```swift
actor OpenAIClient {
    private let apiKey: String
    private let urlSession = URLSession.shared

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func complete(_ prompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: "gpt-4-turbo-preview",
            messages: [
                .init(role: "user", content: prompt)
            ]
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await urlSession.data(for: request)
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }
}
```

## 2. Qdrant Client

```swift
actor QdrantClient {
    private let apiKey: String
    private let urlSession = URLSession.shared
    private let baseURL: URL

    init(apiKey: String, url: URL) {
        self.apiKey = apiKey
        self.baseURL = url
    }

    func search(vector: [Float], limit: Int = 80) async throws -> [Prior] {
        var request = URLRequest(url: baseURL.appendingPathComponent("/search"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = SearchRequest(
            vector: vector,
            limit: limit
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode([Prior].self, from: data)
    }
}
```

## 3. Service Manager

```swift
// Central manager for development
class ServiceManager: ObservableObject {
    private let openAI: OpenAIClient
    private let qdrant: QdrantClient

    init() {
        // Development keys
        self.openAI = OpenAIClient(apiKey: ProcessInfo.processInfo.environment["OPENAI_KEY"]!)
        self.qdrant = QdrantClient(
            apiKey: ProcessInfo.processInfo.environment["QDRANT_KEY"]!,
            url: URL(string: "https://your-qdrant-instance.com")!
        )
    }

    // Chorus Cycle steps
    func runAction(_ content: String) async throws -> String {
        return try await openAI.complete(content)
    }

    func findPriors(_ content: String) async throws -> [Prior] {
        let embedding = try await getEmbedding(content)
        return try await qdrant.search(vector: embedding)
    }
}
```

## 4. Environment Setup

```swift
// Development configuration
extension ProcessInfo {
    var developmentKeys: [String: String] {
        // Load from environment or config file
        [
            "OPENAI_KEY": "sk-...",
            "QDRANT_KEY": "..."
        ]
    }
}
```

## Migration to Proxy

When ready to switch to the proxy:

```swift
// Just change the base URLs and auth
class ServiceManager {
    private let baseURL = URL(string: "https://api.choir.chat")!
    private let authToken: String

    func runAction(_ content: String) async throws -> String {
        // Same interface, different endpoint
        return try await post("/ai/complete", body: content)
    }

    func findPriors(_ content: String) async throws -> [Prior] {
        // Same interface, different endpoint
        return try await post("/search", body: content)
    }
}
```

## Benefits

1. **Development Speed**

- Direct API access
- Quick iteration
- Easy debugging

2. **Clean Migration**

- Same interfaces
- Just change endpoints
- No client code changes

3. **Type Safety**

- Swift types throughout
- Compile-time checking
- Clear error handling
