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
# PDA-Based Key Derivation

## Derivation Pattern
```swift
struct PDASeed {
    // PDA seeds for different purposes
    static func threadSeed(threadId: String) -> [Buffer] {
        [
            Buffer("thread"),     // Discriminator
            Buffer(threadId),     // Thread identifier
            Buffer("encryption")  // Purpose
        ]
    }

    static func messageSeed(messageId: String) -> [Buffer] {
        [
            Buffer("message"),    // Discriminator
            Buffer(messageId),    // Message identifier
            Buffer("encryption")  // Purpose
        ]
    }

    static func sharedSeed(
        threadId: String,
        participants: [PublicKey]
    ) -> [Buffer] {
        [
            Buffer("shared"),     // Discriminator
            Buffer(threadId),     // Thread identifier
            Buffer(participants   // Sorted participants
                .sorted()
                .map { $0.toBase58() }
                .joined(separator: ":")
            ),
            Buffer("encryption")  // Purpose
        ]
    }
}
```

## Key Generation
```swift
class PDAKeyManager {
    private let programId: PublicKey  // Thread program

    // Thread encryption key
    func deriveThreadKey(threadId: String) -> (PublicKey, UInt8) {
        PublicKey.findProgramAddress(
            seeds: PDASeed.threadSeed(threadId: threadId),
            programId: programId
        )
    }

    // Message encryption key
    func deriveMessageKey(messageId: String) -> (PublicKey, UInt8) {
        PublicKey.findProgramAddress(
            seeds: PDASeed.messageSeed(messageId: messageId),
            programId: programId
        )
    }

    // Shared encryption key
    func deriveSharedKey(
        threadId: String,
        participants: [PublicKey]
    ) -> (PublicKey, UInt8) {
        PublicKey.findProgramAddress(
            seeds: PDASeed.sharedSeed(
                threadId: threadId,
                participants: participants
            ),
            programId: programId
        )
    }
}
```

## Benefits

1. **Solana Native**
```swift
let benefits = [
    "Deterministic",         // Same inputs -> Same key
    "Program controlled",    // Only program can sign
    "On-chain verifiable",   // Part of program state
    "Zero storage",         // Derived on demand
    "Cross-client"          // Works everywhere
]
```

2. **Security Properties**
```swift
let security = [
    "Program scoped",        // Tied to program ID
    "Purpose bound",         // Discriminator prefixed
    "Collision resistant",   // Bump seed ensures
    "Identity linked",       // Thread/user bound
    "Audit friendly"        // Clear derivation
]
```

3. **Implementation**
```swift
// Usage in encryption
class ThreadEncryption {
    private let pdaKeys: PDAKeyManager

    func encryptMessage(
        content: String,
        threadId: String
    ) async throws -> EncryptedMessage {
        // Get encryption key from PDA
        let (key, _) = pdaKeys.deriveThreadKey(threadId)

        // Use for encryption
        return try await encrypt(
            content: content,
            key: key.toBytes()
        )
    }

    func encryptShared(
        content: String,
        threadId: String,
        participants: [PublicKey]
    ) async throws -> EncryptedMessage {
        // Get shared key from PDA
        let (key, _) = pdaKeys.deriveSharedKey(
            threadId: threadId,
            participants: participants
        )

        // Use for encryption
        return try await encrypt(
            content: content,
            key: key.toBytes()
        )
    }
}
```

The key insight is:
1. PDAs are perfect for key derivation
2. Program controls access
3. Zero key storage needed
4. Native to Solana
5. Cross-client compatible
