# User Identity Implementation

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Blocks: [Thread State Management](issue_5.md)
- Related to: [API Client Message Handling](issue_2.md)

## Description
Implement basic user identity management using public/private key pairs stored in UserDefaults, integrating with the existing users collection in Qdrant.

## Current State
- Have users collection in Qdrant
- Need local key management
- Need user creation/retrieval
- Need API integration

## Tasks
- [ ] Implement key management
  - [ ] Generate key pairs
  - [ ] Store in UserDefaults
  - [ ] Handle key retrieval
  - [ ] Add basic validation
- [ ] Create User type
  - [ ] Match Qdrant schema
  - [ ] Add local state
  - [ ] Handle serialization
- [ ] Add API integration
  - [ ] User creation
  - [ ] User retrieval
  - [ ] Error handling
- [ ] Implement UserManager
  - [ ] Key lifecycle
  - [ ] User state
  - [ ] API coordination

## Code Examples
```swift
// User types
struct User: Codable, Identifiable {
    let id: String          // UUID
    let publicKey: String   // Base64 encoded public key
    let createdAt: String   // ISO8601 date
    let threadIds: [String] // Associated thread IDs

    enum CodingKeys: String, CodingKey {
        case id
        case publicKey = "public_key"
        case createdAt = "created_at"
        case threadIds = "thread_ids"
    }
}

struct UserCreate: Codable {
    let publicKey: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
    }
}

// User management
actor UserManager {
    private let userDefaults = UserDefaults.standard
    private let api: ChorusAPIClient

    // Key constants
    private let privateKeyKey = "com.choir.privateKey"
    private let publicKeyKey = "com.choir.publicKey"

    // Key management
    private func generateKeyPair() throws -> (privateKey: SecKey, publicKey: SecKey) {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw error?.takeRetainedValue() ?? KeyError.generationFailed
        }

        return (privateKey, publicKey)
    }

    // User operations
    func getCurrentUser() async throws -> User {
        if let publicKey = userDefaults.string(forKey: publicKeyKey),
           let user = try await api.getUser(publicKey) {
            return user
        }

        // Create new user if none exists
        return try await createUser()
    }

    private func createUser() async throws -> User {
        // Generate new keys
        let (privateKey, publicKey) = try generateKeyPair()

        // Store keys
        userDefaults.set(privateKey.base64String, forKey: privateKeyKey)
        userDefaults.set(publicKey.base64String, forKey: publicKeyKey)

        // Create user in Qdrant
        return try await api.createUser(UserCreate(
            publicKey: publicKey.base64String
        ))
    }
}

// Error types
enum KeyError: Error {
    case generationFailed
    case invalidKey
    case storageError
    case notFound
}
```

## Testing Requirements
- Test key management
  - Key generation
  - Storage/retrieval
  - Validation
- Test user operations
  - User creation
  - User retrieval
  - Error cases
- Test API integration
  - Network operations
  - Error handling
  - State management

## Success Criteria
- Reliable key management
- Clean user operations
- Proper error handling
- Type-safe implementation
