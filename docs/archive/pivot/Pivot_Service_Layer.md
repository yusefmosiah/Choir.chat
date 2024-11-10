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
# Service Layer Design

## iOS Client Abstraction

```swift
// Clean protocol for service interactions
protocol ChoirService {
    func generateResponse(_ prompt: String) async throws -> String
    func searchPriors(_ content: String) async throws -> [Prior]
    func recordSemanticLink(_ link: SemanticLink) async throws
}

// Concrete implementation that talks to our API
class APIService: ChoirService {
    private let baseURL: URL
    private let session: URLSession

    // Service endpoints with observability
    func generateResponse(_ prompt: String) async throws -> String {
        // Calls our Python API which:
        // 1. Logs the request
        // 2. Tracks token usage
        // 3. Monitors latency
        // 4. Handles rate limiting
        return try await post("/ai/complete", body: prompt)
    }

    func searchPriors(_ content: String) async throws -> [Prior] {
        // API handles:
        // 1. Vector computation
        // 2. Qdrant interaction
        // 3. Result processing
        // 4. Usage tracking
        return try await post("/search", body: content)
    }
}
```

## Python API Enhancement

```python
# Enhanced FastAPI endpoints
@app.post("/ai/complete")
async def generate_response(
    prompt: str,
    user: User = Depends(get_current_user)
):
    # Observability
    with track_operation("ai_completion", user=user.id) as op:
        # Rate limiting
        await check_rate_limit(user, "ai")

        # Cost tracking
        tokens = count_tokens(prompt)
        await track_usage(user, "ai", tokens)

        # Actual call
        response = await openai.complete(prompt)

        # Record metrics
        op.record_tokens(tokens)
        op.record_latency()

        return response

@app.post("/search")
async def search_vectors(
    content: str,
    user: User = Depends(get_current_user)
):
    with track_operation("vector_search", user=user.id) as op:
        # Vector computation
        embedding = await get_embedding(content)

        # Search and track
        results = await qdrant.search(embedding)
        op.record_vectors_searched(len(results))

        return results
```

## Benefits

1. **Clean iOS Code**

```swift
// Usage in view models
class MessageViewModel: ObservableObject {
    private let service: ChoirService

    func sendMessage(_ content: String) async throws {
        // Clean business logic
        let response = try await service.generateResponse(content)
        let priors = try await service.searchPriors(content)
        // Process results...
    }
}
```

2. **Rich Observability**

```python
# Python API provides:
- Request logging
- Token usage tracking
- Vector operation metrics
- User quotas/limits
- Cost allocation
- Performance monitoring
- Error tracking
```

3. **Future Flexibility**

```swift
// Easy to add new service implementations
class MockService: ChoirService {
    // For testing
}

class DirectService: ChoirService {
    // Direct API calls if needed
}

class ProxyService: ChoirService {
    // Production proxy version
}
```

This gives us:

1. Clean iOS abstractions
2. Rich service metrics
3. Centralized rate limiting
4. Usage tracking
5. Future flexibility
