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
# Key Derivation Path System

## Path Structure

```swift
struct DerivationPath {
    // BIP-44 style paths for Solana
    let paths = [
        "m/44'/501'/0'/0'",           // Base Solana path
        "m/44'/501'/0'/1'",           // Thread encryption
        "m/44'/501'/0'/2'",           // Message encryption
        "m/44'/501'/0'/3'"            // Shared secrets
    ]

    // Purpose-specific paths
    enum Purpose: UInt32 {
        case wallet = 0        // Standard wallet
        case threads = 1       // Thread keys
        case messages = 2      // Message keys
        case shared = 3        // Shared secrets

        var path: String {
            "m/44'/501'/0'/\(rawValue)'"
        }
    }
}
```

## Key Management

```swift
class KeyManager {
    private let masterKey: Ed25519HDKey  // From wallet

    // Thread-specific key
    func deriveThreadKey(threadId: UUID) -> Ed25519Key {
        let path = DerivationPath.Purpose.threads.path
        let seed = "\(path)/\(threadId)"
        return masterKey.derive(path: seed)
    }

    // Message-specific key
    func deriveMessageKey(messageId: UUID) -> Ed25519Key {
        let path = DerivationPath.Purpose.messages.path
        let seed = "\(path)/\(messageId)"
        return masterKey.derive(path: seed)
    }

    // Shared secret derivation
    func deriveSharedKey(
        threadId: UUID,
        participants: [PublicKey]
    ) -> Ed25519Key {
        let path = DerivationPath.Purpose.shared.path
        let participantString = participants
            .sorted()
            .map { $0.toBase58() }
            .joined(separator: ":")

        let seed = "\(path)/\(threadId)/\(participantString)"
        return masterKey.derive(path: seed)
    }
}
```

## Key Recovery

```swift
struct KeyRecovery {
    // All keys are recoverable from:
    let requirements = [
        "Wallet seed phrase",     // Master key source
        "Thread ID",              // Thread context
        "Participant list",       // For shared keys
        "Derivation path"         // Key purpose
    ]

    // Recovery process
    func recoverKeys(wallet: HDWallet) -> KeySet {
        KeySet(
            threadKeys: recoverThreadKeys(wallet),
            messageKeys: recoverMessageKeys(wallet),
            sharedKeys: recoverSharedKeys(wallet)
        )
    }
}
```

## Security Properties

```swift
struct SecurityProperties {
    let properties = [
        "Deterministic": [
            "Same inputs → Same keys",
            "No state to store",
            "Full recoverability",
            "Cross-device sync"
        ],

        "Isolated": [
            "Different purposes → Different paths",
            "Thread isolation",
            "Message isolation",
            "Forward secrecy"
        ],

        "Hierarchical": [
            "Master key controls all",
            "Sub-keys can't derive up",
            "Clean key rotation",
            "Selective disclosure"
        ]
    ]
}
```

## Implementation

```swift
// Usage example
class SecureThread {
    private let keyManager: KeyManager

    func encryptMessage(_ content: String) async throws -> EncryptedMessage {
        // For single-author thread
        let key = keyManager.deriveThreadKey(threadId)
        return try await encrypt(content, with: key)
    }

    func encryptSharedMessage(
        _ content: String,
        participants: [PublicKey]
    ) async throws -> EncryptedMessage {
        // For multi-author thread
        let key = keyManager.deriveSharedKey(
            threadId,
            participants: participants
        )
        return try await encrypt(content, with: key)
    }
}
```

Benefits:

1. No key storage needed
2. Deterministic recovery
3. Clean key isolation
4. Forward secrecy
5. Cross-device sync
