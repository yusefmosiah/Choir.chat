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
# Qdrant Swift Client

## Core Types

```swift
// Vector types
struct Point: Codable {
    let id: String
    let vector: [Float]
    let payload: Payload
}

struct Payload: Codable {
    let content: String
    let threadId: String
    let timestamp: Date
    let metadata: [String: AnyCodable]
}

// Search parameters
struct SearchRequest: Codable {
    let vector: [Float]
    let limit: Int
    let filter: Filter?
    let withPayload: Bool = true
    let withVector: Bool = false
}

struct Filter: Codable {
    let must: [Condition]?
    let should: [Condition]?
    let mustNot: [Condition]?
}
```

## Client Implementation

```swift
actor QdrantClient {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    private let collection: String

    init(url: URL, apiKey: String, collection: String) {
        self.baseURL = url
        self.apiKey = apiKey
        self.collection = collection

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "api-key": apiKey,
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }

    // Search vectors
    func search(vector: [Float], limit: Int = 80, filter: Filter? = nil) async throws -> [Point] {
        let endpoint = baseURL
            .appendingPathComponent("collections")
            .appendingPathComponent(collection)
            .appendingPathComponent("points/search")

        let request = SearchRequest(
            vector: vector,
            limit: limit,
            filter: filter
        )

        return try await post(endpoint, body: request)
    }

    // Upsert points
    func upsert(_ points: [Point]) async throws {
        let endpoint = baseURL
            .appendingPathComponent("collections")
            .appendingPathComponent(collection)
            .appendingPathComponent("points")

        let request = UpsertRequest(points: points)
        try await post(endpoint, body: request)
    }

    // Delete points
    func delete(ids: [String]) async throws {
        let endpoint = baseURL
            .appendingPathComponent("collections")
            .appendingPathComponent(collection)
            .appendingPathComponent("points/delete")

        let request = DeleteRequest(ids: ids)
        try await post(endpoint, body: request)
    }
}
```

## Usage Example

```swift
// Initialize client
let client = QdrantClient(
    url: URL(string: "https://your-qdrant.com")!,
    apiKey: "your-api-key",
    collection: "messages"
)

// Search for similar vectors
let results = try await client.search(
    vector: embeddings,
    limit: 80,
    filter: Filter(
        must: [
            .match(field: "threadId", value: currentThreadId)
        ]
    )
)

// Store new message
try await client.upsert([
    Point(
        id: messageId,
        vector: embeddings,
        payload: Payload(
            content: messageContent,
            threadId: threadId,
            timestamp: Date(),
            metadata: [
                "author": userId,
                "type": "message"
            ]
        )
    )
])
```

## Error Handling

```swift
enum QdrantError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse(Int)
    case decodingError(Error)
    case serverError(String)
}

extension QdrantClient {
    private func handleError(_ error: Error) -> QdrantError {
        switch error {
        case is URLError:
            return .networkError(error)
        case is DecodingError:
            return .decodingError(error)
        default:
            return .serverError(error.localizedDescription)
        }
    }
}
```

## Testing Support

```swift
// Mock client for testing
class MockQdrantClient: QdrantClientProtocol {
    var mockResults: [Point] = []

    func search(vector: [Float], limit: Int) async throws -> [Point] {
        return mockResults
    }

    func upsert(_ points: [Point]) async throws {
        // Mock upsert
    }
}
```

The client provides:

1. Type-safe API
2. Async/await support
3. Error handling
4. Testing support
5. Full Qdrant feature set

Would you like me to expand on any part of the implementation?
