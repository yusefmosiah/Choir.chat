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
# User Data Privacy & Access Control

## Data Classification

```swift
struct DataPrivacy {
    // Public Data
    let public = [
        "Thread titles",          // Visible to all
        "Message counts",         // Basic stats
        "Public citations",       // Referenced priors
        "Token balances",         // On-chain anyway
        "Approval history"        // Public actions
    ]

    // Protected Data
    let protected = [
        "Message content",        // Private by default
        "Thread messages",        // Access controlled
        "User profiles",          // Basic info
        "Vector embeddings",      // Semantic data
        "Prior relationships"     // Citation graph
    ]

    // Private Data
    let private = [
        "Draft messages",         // Unsent content
        "Personal notes",         // User annotations
        "Search history",         // Query patterns
        "Reading patterns",       // Usage data
        "Device info"            // Technical data
    ]
}
```

## Access Control

```swift
// Qdrant collection access rules
struct AccessControl {
    // Thread Access
    func canAccessThread(_ threadId: UUID, user: PublicKey) async -> Bool {
        let thread = await getThread(threadId)
        return thread.isPublic ||                  // Public thread
               thread.creator == user ||           // Thread creator
               thread.coAuthors.contains(user) ||  // Co-author
               thread.hasApprovedAccess(user)      // Granted access
    }

    // Message Access
    func canAccessMessage(_ messageId: UUID, user: PublicKey) async -> Bool {
        let message = await getMessage(messageId)
        return await canAccessThread(message.threadId, user: user)
    }

    // Search Scope
    func searchFilter(user: PublicKey) -> Filter {
        Filter {
            Should {
                // Public threads
                FieldCondition("isPublic", .equals, true)

                // User's own threads
                FieldCondition("creator", .equals, user)

                // Co-authored threads
                FieldCondition("coAuthors", .contains, user)

                // Granted access
                FieldCondition("accessList", .contains, user)
            }
        }
    }
}
```

## Implementation

```swift
// API Layer protection
class APIService {
    // Protected search
    func searchVectors(_ query: Vector, user: PublicKey) async throws -> [Prior] {
        // Apply access filter
        let filter = AccessControl.searchFilter(user: user)

        // Search only accessible content
        return try await qdrant.search(
            vector: query,
            filter: filter,
            limit: 80
        )
    }

    // Protected thread access
    func getThread(_ id: UUID, user: PublicKey) async throws -> Thread {
        guard await AccessControl.canAccessThread(id, user: user) else {
            throw AccessError.unauthorized
        }
        return try await qdrant.get(collection: "threads", id: id)
    }
}
```

## Security Patterns

```swift
struct SecurityPatterns {
    // Request Validation
    let validation = [
        "Signature verification",  // Wallet signed request
        "Access scope check",      // Permission validation
        "Rate limiting",          // Request throttling
        "Input sanitization",     // Query validation
        "Audit logging"           // Access tracking
    ]

    // Data Protection
    let protection = [
        "Collection isolation",    // Separate storage
        "Query filtering",        // Access scoping
        "Result sanitization",    // Data cleaning
        "Error masking",         // Safe errors
        "Access logging"         // Audit trail
    ]
}
```

Key principles:

1. Default to private
2. Explicit access grants
3. Verify every request
4. Filter all queries
5. Log access patterns
