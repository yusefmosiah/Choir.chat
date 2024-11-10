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
# Direct vs Proxied Service Access

## Option 1: Direct Service Access

```swift
// Each user has their own API keys
class ServiceManager {
    private let qdrantKey: String  // Per-user Qdrant key
    private let openAIKey: String  // Per-user OpenAI key

    func searchVectors(_ query: Vector) async throws -> [Prior] {
        // Direct Qdrant API call
        let client = QdrantClient(apiKey: qdrantKey)
        return try await client.search(query)
    }

    func generateResponse(_ prompt: String) async throws -> String {
        // Direct OpenAI API call
        let client = OpenAI(apiKey: openAIKey)
        return try await client.complete(prompt)
    }
}

Pros:
- Lower latency (direct calls)
- Simpler architecture
- Less infrastructure

Cons:
- API key management complexity
- No usage monitoring
- Harder to implement rate limiting
- Security concerns
```

## Option 2: Managed Proxy Service

```swift
// Use a service like LiteLLM
class ProxyManager {
    private let liteLLMKey: String  // One proxy key per user

    func generateResponse(_ prompt: String) async throws -> String {
        // LiteLLM handles:
        // - API key management
        // - Rate limiting
        // - Cost tracking
        // - Fallback models
        return try await liteLLM.complete(prompt)
    }
}

Pros:
- Professional key management
- Built-in monitoring
- Automatic fallbacks
- Usage analytics

Cons:
- Monthly service cost
- Additional latency
- Vendor lock-in
```

## Option 3: Custom Proxy (Recommended)

```swift
// Light FastAPI service
class APIManager {
    private let apiKey: String  // Single user key for our service

    func searchVectors(_ query: Vector) async throws -> [Prior] {
        // Our proxy handles:
        // - API key rotation
        // - Usage tracking
        // - Rate limiting
        // - Cost allocation
        return try await api.post("/search", query)
    }
}

Pros:
- Full control over key management
- Custom usage tracking
- Per-user rate limiting
- Cost monitoring
- Security control

Cons:
- Must maintain proxy service
- Initial setup complexity
```

## Recommendation

Keep a minimal FastAPI proxy for:

1. API key management
2. Usage tracking
3. Rate limiting
4. Cost monitoring

But make it much simpler than current version:

```python
# Simple FastAPI proxy
@app.post("/search")
async def search_vectors(query: Vector, user: User):
    # Rate limiting
    await check_rate_limit(user)

    # Key management
    api_key = get_rotating_key(service="qdrant")

    # Usage tracking
    await track_usage(user, service="qdrant")

    # Actual call
    return await qdrant.search(query, api_key)
```

This gives us:

- Security control
- Usage monitoring
- Simple maintenance
- Future flexibility

We can always switch to direct calls or managed proxy later if needed.
