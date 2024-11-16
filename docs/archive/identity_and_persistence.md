# Identity and Persistence Implementation Plan

## Overview
Implement user identity and persistence with a path toward blockchain integration, using SwiftData for local storage and preparing for future decentralized features.

## 1. User Identity Models
```swift
// Current implementation (pre-blockchain)
@Model
class User {
    @Attribute(.unique) let id: UUID  // Client-generated
    let publicKey: String  // Base64 encoded public key
    let createdAt: Date
    @Relationship(deleteRule: .cascade) var threads: [ChoirThread]

    // Future blockchain fields (commented until implemented)
    // var address: String?  // Ethereum address
    // var nonce: Int?      // For transaction signing
}

// Keychain wrapper for private key management
class KeychainManager {
    enum KeychainError: Error {
        case duplicateKey
        case keyNotFound
        case invalidKey
        case unhandledError(status: OSStatus)
    }

    func generateKeyPair() throws -> (privateKey: SecKey, publicKey: SecKey) {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw error?.takeRetainedValue() ?? KeychainError.unhandledError(status: errSecDecode)
        }

        return (privateKey, publicKey)
    }
}
```

## 2. Updated Data Models
```swift
@Model
class ChoirThread {
    @Attribute(.unique) let id: UUID  // Client-generated
    let title: String
    let createdAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message]
    @Relationship var owner: User  // Thread owner
    @Relationship var coAuthors: [User]  // Thread co-authors

    // Future blockchain fields
    // var contractAddress: String?
    // var tokenBalance: Double?
    // var temperature: Double?

    init(id: UUID = UUID(), title: String, owner: User) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.owner = owner
        self.coAuthors = [owner]  // Owner is automatically a co-author
    }
}

@Model
class Message {
    @Attribute(.unique) let id: UUID  // Client-generated, same ID used in Qdrant
    let content: String
    let timestamp: Date
    @Relationship var author: User
    var chorusResult: MessageChorusResult?

    @Relationship(inverse: \ChoirThread.messages)
    var thread: ChoirThread?

    init(id: UUID = UUID(), content: String, author: User) {
        self.id = id
        self.content = content
        self.timestamp = Date()
        self.author = author
    }
}
```

## 3. Identity Management
```swift
@MainActor
class IdentityManager: ObservableObject {
    @Published private(set) var currentUser: User?
    private let keychain = KeychainManager()
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getCurrentUser() async throws -> User {
        // Check for existing user
        if let user = currentUser { return user }

        // Try to load from SwiftData
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.createdAt)])
        if let existingUser = try modelContext.fetch(descriptor).first {
            currentUser = existingUser
            return existingUser
        }

        // Create new user with keypair
        let (privateKey, publicKey) = try keychain.generateKeyPair()
        let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data
        let publicKeyString = publicKeyData.base64EncodedString()

        let newUser = User(
            id: UUID(),  // Client-generated UUID
            publicKey: publicKeyString,
            createdAt: Date()
        )

        modelContext.insert(newUser)
        currentUser = newUser
        return newUser
    }
}
```

## 4. Implementation Phases

### Phase 1: Local Identity & Storage
- [x] SwiftData models
- [ ] Basic key generation
- [ ] Local user management
- [ ] Thread & message persistence

### Phase 2: Enhanced Security
- [ ] Biometric protection
- [ ] Secure key storage
- [ ] Key backup warnings
- [ ] Recovery phrases

### Phase 3: Blockchain Preparation
- [ ] Ethereum address generation
- [ ] Transaction signing
- [ ] Contract interaction stubs
- [ ] Token balance tracking

## 5. Testing Strategy
```swift
class IdentityTests: XCTestCase {
    var container: ModelContainer!
    var identityManager: IdentityManager!

    override func setUp() async throws {
        container = try ModelContainer(
            for: [User.self, ChoirThread.self, Message.self],
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        identityManager = IdentityManager(modelContext: container.mainContext)
    }

    func testUserCreation() async throws {
        let user = try await identityManager.getCurrentUser()
        XCTAssertNotNil(user.publicKey)

        // Verify key persistence
        let sameUser = try await identityManager.getCurrentUser()
        XCTAssertEqual(user.id, sameUser.id)
    }

    func testMessageIdConsistency() async throws {
        let user = try await identityManager.getCurrentUser()
        let thread = ChoirThread(title: "Test Thread", owner: user)

        // Create message with specific ID
        let messageId = UUID()
        let message = Message(id: messageId, content: "Test", author: user)
        message.thread = thread

        // Verify ID consistency
        XCTAssertEqual(message.id, messageId)
        // This ID would be used both in SwiftData and Qdrant
    }
}
```

## Success Criteria
- [ ] Secure key generation and storage
- [ ] Persistent user identity across launches
- [ ] Proper thread ownership and co-authorship
- [ ] Clear path to blockchain integration

## Notes
- Start with simple key storage, enhance security later
- Keep blockchain-specific fields commented until needed
- Maintain clean separation between local and network data
- Plan for future contract integration
- Ensure consistent message IDs between SwiftData and Qdrant

## Next Steps
1. Implement basic key generation and storage
2. Set up SwiftData models and relationships
3. Create comprehensive test suite
4. Document security considerations
</rewritten_file>
