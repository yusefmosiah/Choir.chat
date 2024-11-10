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

# MVP Simplification Strategy

## Real-time Updates: Simple First

```swift
struct RealTimeOptions {
    // Phase 1: Simple Polling
    let polling = [
        "Pros": [
            "Dead simple to implement",
            "No connection management",
            "Works everywhere",
            "Easy to debug",
            "No state to maintain"
        ],
        "Cons": [
            "Higher latency (1-3s)",
            "More server requests",
            "Less efficient"
        ]
    ]

    // Phase 2: Server-Sent Events
    let sse = [
        "Pros": [
            "One-way streaming",
            "Native browser support",
            "Simple server impl",
            "Auto-reconnect",
            "HTTP compatible"
        ],
        "Cons": [
            "One-way only",
            "No binary support"
        ]
    ]

    // Phase 3: WebSockets (Future)
    let websockets = [
        "When needed": [
            "Real-time collaboration",
            "Binary data (voice)",
            "Complex state sync",
            "P2P coordination",
            "High frequency updates"
        ]
    ]
}
```

## Implementation

```swift
// Phase 1: Simple Polling
class ThreadPoller {
    private let interval: TimeInterval = 2.0  // 2 second poll

    func startPolling() async {
        while true {
            do {
                let updates = try await fetchUpdates()
                handleUpdates(updates)
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                // Simple error handling
                continue
            }
        }
    }
}

// Phase 2: SSE When Ready
class EventSource {
    func connect() {
        let url = URL(string: "https://api.choir.chat/events")!
        let source = URLSession.shared.streamTask(with: url)
        source.resume()
        // Handle events...
    }
}
```

## Benefits

1. **Development Speed**

```swift
let simplificationBenefits = [
    "Faster MVP",              // Simpler architecture
    "Less infrastructure",     // HTTP only
    "Easier debugging",        // Clear request/response
    "Lower complexity",        // No connection state
    "Focus on core features"   // Chat/threads/priors
]
```

2. **User Experience**

```swift
let userImpact = [
    "2s latency acceptable",   // Chat is async anyway
    "Reliable updates",        // Simple retry logic
    "Clear loading states",    // Request/response model
    "Predictable behavior",    // HTTP semantics
    "Battery friendly"         // Controlled polling
]
```

3. **Future Evolution**

```swift
let evolutionPath = [
    "Start": "HTTP Polling",
    "Next": "Server-Sent Events",
    "Later": "WebSockets",
    "When": "Real-time features needed"
]
```

The key insight:

1. Chat is naturally async
2. 2s latency is fine for MVP
3. Simple HTTP is reliable
4. Easy to implement/debug
5. Can evolve when needed
