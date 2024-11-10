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
# End-to-End Payload Encryption

## Key Derivation

```swift
struct KeyDerivation {
    // Single-author threads
    func deriveThreadKey(wallet: Keypair, threadId: UUID) -> SecretKey {
        // Derive unique key for each thread
        let seed = hmacSHA256(
            key: wallet.privateKey,
            message: "thread:\(threadId)"
        )
        return SecretKey(seed: seed)
    }

    // Multi-author threads
    func deriveSharedSecret(
        myKey: Keypair,
        theirPublicKey: PublicKey,
        threadId: UUID
    ) -> SecretKey {
        // ECDH key agreement
        let sharedPoint = ed25519.multiply(
            myKey.privateKey,
            theirPublicKey
        )

        // Derive thread-specific key
        return hmacSHA256(
            key: sharedPoint.bytes,
            message: "thread:\(threadId)"
        )
    }
}
```

## Payload Encryption

```swift
struct EncryptedPayload: Codable {
    let ciphertext: Data      // Encrypted content
    let nonce: Data          // Unique IV
    let authors: [PublicKey] // For key recovery
}

class PayloadEncryption {
    // Encrypt for single author
    func encrypt(
        payload: Payload,
        wallet: Keypair,
        threadId: UUID
    ) async throws -> EncryptedPayload {
        let key = deriveThreadKey(wallet: wallet, threadId: threadId)
        let nonce = generateNonce()

        let ciphertext = try await encrypt(
            payload: payload,
            key: key,
            nonce: nonce
        )

        return EncryptedPayload(
            ciphertext: ciphertext,
            nonce: nonce,
            authors: [wallet.publicKey]
        )
    }

    // Encrypt for multiple authors
    func encryptShared(
        payload: Payload,
        authors: [PublicKey],
        wallet: Keypair,
        threadId: UUID
    ) async throws -> EncryptedPayload {
        // Generate shared secrets with each co-author
        let sharedKeys = try await authors.map { author in
            deriveSharedSecret(
                myKey: wallet,
                theirPublicKey: author,
                threadId: threadId
            )
        }

        // Combine keys
        let threadKey = combineKeys(sharedKeys)
        let nonce = generateNonce()

        let ciphertext = try await encrypt(
            payload: payload,
            key: threadKey,
            nonce: nonce
        )

        return EncryptedPayload(
            ciphertext: ciphertext,
            nonce: nonce,
            authors: authors
        )
    }
}
```

## Qdrant Integration

```swift
// Store encrypted payloads
class SecureQdrantClient {
    func upsertMessage(
        content: String,
        threadId: UUID,
        wallet: Keypair
    ) async throws {
        // Get thread authors
        let thread = try await getThread(threadId)

        // Create payload
        let payload = MessagePayload(
            content: content,
            timestamp: Date()
        )

        // Encrypt based on authors
        let encrypted = if thread.authors.count > 1 {
            try await PayloadEncryption.encryptShared(
                payload: payload,
                authors: thread.authors,
                wallet: wallet,
                threadId: threadId
            )
        } else {
            try await PayloadEncryption.encrypt(
                payload: payload,
                wallet: wallet,
                threadId: threadId
            )
        }

        // Store in Qdrant
        try await qdrant.upsert(
            collection: "messages",
            points: [
                Point(
                    id: UUID(),
                    vector: embeddings,
                    payload: encrypted
                )
            ]
        )
    }
}
```

## Security Properties

1. **Thread Isolation**

```swift
let security = [
    "Per-thread keys",      // Unique key per thread
    "Forward secrecy",      // New keys can't decrypt old
    "Key separation",       // Thread keys independent
    "Access control",       // Only authors can decrypt
    "Audit trail"          // Author list preserved
]
```

2. **Key Management**

```swift
let keyManagement = [
    "Deterministic",       // Keys derived from wallet
    "No key storage",      // Keys generated on demand
    "No key exchange",     // ECDH for shared secrets
    "No central trust",    // End-to-end encryption
    "Key recovery"         // Via any thread author
]
```

The benefits:

1. End-to-end encryption
2. No additional key management
3. Natural access control
4. Thread isolation
5. Co-author support
