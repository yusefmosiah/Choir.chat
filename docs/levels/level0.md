# Level 0 Documentation



=== File: docs/issues/issue_0.md ===



==
issue_0
==


# Core Client-Side Implementation

## Overview
Implement the foundational client-side system with a focus on getting a working version to TestFlight. Initially use Anthropic and OpenAI APIs through a secure proxy, while preparing for future local AI model integration.

## Current Issues
1. Issue 1: Local Data Management and Persistence
2. Issue 2: SUI Blockchain Smart Contracts (basic wallet integration)
3. Issue 5: Enhanced UI/UX with Carousel
4. Issue 7: Testing and Quality Assurance
5. Issue 8: Deploy to TestFlight and Render
6. Issue 9: Message Rewards Implementation
7. Issue 10: Thread Sheet Implementation
8. Issue 11: Thread Contract Implementation 
9. Issue 12: Citation Visualization and Handling
10. Issue 13: LanceDB Migration & Multimodal Support

## Immediate Tasks

### 1. Core Data Layer
```swift
// SwiftData models for local persistence
@Model
class User {
    @Attribute(.unique) let id: UUID
    let publicKey: String
    let createdAt: Date

    @Relationship(deleteRule: .cascade) var ownedThreads: [Thread]
    @Relationship var coAuthoredThreads: [Thread]
}

@Model
class Thread {
    @Attribute(.unique) let id: UUID
    let title: String
    let createdAt: Date

    @Relationship var owner: User
    @Relationship var coAuthors: [User]
    @Relationship(deleteRule: .cascade) var messages: [Message]
}
```

### 2. Basic SUI Integration
```swift
// Wallet management
class WalletManager {
    private let keychain = KeychainService()

    func createOrLoadWallet() async throws -> Wallet {
        if let existingKey = try? keychain.load("sui_private_key") {
            return try Wallet(privateKey: existingKey)
        }
        let wallet = try await SUIKit.createWallet()
        try keychain.save(wallet.privateKey, forKey: "sui_private_key")
        return wallet
    }
}
```

### 3. Proxy Server Setup
```python
# FastAPI proxy for AI services
@app.post("/api/proxy/ai")
async def proxy_ai_request(
    request: AIRequest,
    auth: Auth = Depends(verify_sui_signature)
):
    # Route to appropriate AI service
    if request.model.startswith("claude"):
        return await route_to_anthropic(request)
    return await route_to_openai(request)
```

## Success Criteria
- App runs smoothly on TestFlight
- Users can create and join threads
- Messages process through Chorus Cycle
- Basic SUI wallet integration works
- Citations work properly

## Postponed Features
- Token mechanics and rewards
- Thread contracts
- Advanced blockchain features
- Multimodal support
- LanceDB migration

## Notes
- Focus on core functionality first
- Keep UI simple but polished
- Test thoroughly before submission
- Document setup process

---

=== File: docs/issues/issue_1.md ===



==
issue_1
==


# Local Data Management and Persistence

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Depends on: None
- Blocks: [SUI Blockchain Smart Contracts](issue_2.md)
- Related to: [Deploy to TestFlight and Render](issue_8.md)

## Description

Implement local data storage using SwiftData to manage users, threads, and messages effectively. Focus on establishing a solid foundation for the client-side architecture while preparing for future blockchain integration.

## Tasks

### 1. Core Data Models

```swift
@Model
class User {
    @Attribute(.unique) let id: UUID
    let publicKey: String
    let createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var ownedThreads: [Thread]
    @Relationship var coAuthoredThreads: [Thread]
    @Relationship(deleteRule: .cascade) var messages: [Message]

    // Future blockchain fields
    var onChainAddress: String?
    var lastSyncTimestamp: Date?
}

@Model
class Thread {
    @Attribute(.unique) let id: UUID
    let title: String
    let createdAt: Date

    // Ownership
    @Relationship var owner: User
    @Relationship var coAuthors: [User]

    // Content
    @Relationship(deleteRule: .cascade) var messages: [Message]

    // Thread state
    var lastMessageAt: Date
    var messageCount: Int

    // Future blockchain fields
    var onChainId: String?
    var lastSyncTimestamp: Date?
}

@Model
class Message {
    @Attribute(.unique) let id: UUID
    let content: String
    let timestamp: Date
    let isUser: Bool

    // Relationships
    @Relationship var author: User
    @Relationship(inverse: \Thread.messages) var thread: Thread?

    // Citations
    @Relationship var citesPriors: [Message]
    @Relationship(inverse: \Message.citesPriors) var citedByMessages: [Message]

    // Chorus result
    var chorusResult: ChorusResult?

    // Future blockchain fields
    var onChainHash: String?
    var lastSyncTimestamp: Date?
}
```

### 2. Data Operations

```swift
actor DataManager {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // CRUD operations
    func createThread(title: String, owner: User) async throws -> Thread {
        let thread = Thread(
            id: UUID(),
            title: title,
            createdAt: Date(),
            owner: owner,
            lastMessageAt: Date(),
            messageCount: 0
        )
        modelContext.insert(thread)
        try await modelContext.save()
        return thread
    }

    func addMessage(_ content: String, to thread: Thread, by user: User) async throws -> Message {
        let message = Message(
            id: UUID(),
            content: content,
            timestamp: Date(),
            isUser: true,
            author: user,
            thread: thread
        )
        modelContext.insert(message)

        // Update thread
        thread.lastMessageAt = message.timestamp
        thread.messageCount += 1

        try await modelContext.save()
        return message
    }
}
```

### 3. Query Support

```swift
extension DataManager {
    func fetchThreads(for user: User) async throws -> [Thread] {
        let descriptor = FetchDescriptor<Thread>(
            predicate: #Predicate<Thread> { thread in
                thread.owner.id == user.id ||
                thread.coAuthors.contains { $0.id == user.id }
            },
            sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func searchMessages(containing text: String) async throws -> [Message] {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.content.localizedStandardContains(text)
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
```

## Success Criteria

- **Reliable local data persistence**

  - Users can create and manage threads and messages locally.
  - Data persists across app launches and device restarts.

- **Efficient CRUD operations**

  - CRUD operations perform smoothly without lag.
  - Data relationships are maintained accurately.

- **Clean relationship management**

  - One-to-many and many-to-many relationships are defined correctly.
  - Models align with blockchain ownership data.

- **Ready for blockchain integration**

  - Architecture supports future data synchronization.
  - Initial sync tests are successful, laying the groundwork for full integration.

- **Comprehensive test coverage**

  - All CRUD operations are tested thoroughly.
  - Relationship management is thoroughly tested.

## Future Considerations

- **Blockchain state synchronization**

  - Implement full data synchronization with the SUI blockchain.
  - Ensure real-time updates and consistency between local and on-chain data.

- **Multi-device data sync**

  - Develop mechanisms to synchronize data across multiple devices.
  - Ensure data consistency and conflict resolution across devices.

- **Advanced search capabilities**

  - Develop sophisticated search capabilities to search for messages and threads.
  - Implement user prompts or automated resolutions where appropriate.

- **Performance optimization for large datasets**

  - Optimize data handling and query performance for large datasets.
  - Ensure smooth user interactions and data consistency.

---

=== File: docs/issues/issue_10.md ===



==
issue_10
==


# Thread Sheet Implementation

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Design and implement the thread sheet UI with a focus on human experience, incorporating the carousel UI pattern for phase navigation and ensuring smooth interaction flows.

## Tasks

### 1. Core UI Components
```swift
struct ThreadSheet: View {
    @ObservedObject var thread: ChoirThread
    @StateObject var viewModel: ThreadViewModel

    var body: some View {
        VStack {
            // Header with thread info
            ThreadHeaderView(thread: thread)

            // Carousel for phase navigation
            ChorusCarouselView(viewModel: viewModel)
                .frame(maxHeight: .infinity)

            // Message input
            MessageInputView(onSend: { message in
                Task { await viewModel.send(message) }
            })
        }
    }
}
```

### 2. Phase Navigation
```swift
struct PhaseView: View {
    let phase: Phase
    @ObservedObject var viewModel: ThreadViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Current phase content
            PhaseContentView(phase: phase, content: viewModel.currentContent)

            // Peek at adjacent phases
            if let nextContent = viewModel.nextPhasePreview {
                Text(nextContent)
                    .font(.caption)
                    .opacity(0.6)
            }
        }
        .transition(.slide)
    }
}
```

### 3. Loading States
- Implement progressive loading indicators
- Show phase transitions smoothly
- Handle network delays gracefully

## Success Criteria
- Intuitive navigation between phases
- Clear visibility of process flow
- Smooth animations and transitions
- Responsive user feedback

=== File: docs/issues/issue_11.md ===



==
issue_11
==


# Thread Contract Implementation

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Implement the SUI smart contract for thread management, handling ownership, co-authoring, and message verification using the Move programming language.

## Tasks

### 1. Core Contract Structure
```move
module choir::thread {
    struct Thread has key {
        id: ID,
        owner: address,
        co_authors: vector<address>,
        message_count: u64,
        temperature: u64,
        frequency: u64,
    }

    public fun create_thread(ctx: &mut TxContext) {
        let thread = Thread {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            co_authors: vector::empty(),
            message_count: 0,
            temperature: INITIAL_TEMP,
            frequency: INITIAL_FREQ,
        };
        transfer::share_object(thread)
    }

    public fun add_message(
        thread: &mut Thread,
        _ctx: &mut TxContext
    ) {
        assert!(is_co_author(thread, tx_context::sender(ctx)), ENotCoAuthor);
        thread.message_count = thread.message_count + 1;
        // Update temperature and frequency
    }
}
```

### 2. State Management
```move
public fun update_temperature(thread: &mut Thread, delta: u64) {
    thread.temperature = thread.temperature + delta;
}

public fun evolve_frequency(thread: &mut Thread) {
    // Implement quantum harmonic oscillator model
    let n = vector::length(&thread.co_authors);
    thread.frequency = calculate_frequency(n, thread.temperature);
}
```

### 3. Access Control
- Implement co-author management
- Handle permissions and roles
- Verify message authenticity

## Success Criteria
- Secure thread ownership
- Reliable state transitions
- Efficient gas usage
- Clean error handling

=== File: docs/issues/issue_12.md ===



==
issue_12
==


# Citation Visualization and Handling

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Implement citation visualization and handling in the carousel UI, allowing users to see and interact with prior references while maintaining the quantum harmonic model of knowledge coupling.

## Tasks

### 1. Citation Data Model
```swift
struct Citation: Identifiable {
    let id: UUID
    let sourceMessageId: String
    let targetMessageId: String
    let content: String
    let similarity: Double
    let context: String

    // Link format: choir://choir.chat/<message_id>
    var link: URL {
        URL(string: "choir://choir.chat/\(targetMessageId)")!
    }
}

extension ThreadMessage {
    var citations: [Citation] {
        // Parse markdown links from content
        // Format: [cited text](choir://choir.chat/<message_id>)
        // Return array of Citations
    }
}
```

### 2. Citation UI Components
```swift
struct CitationView: View {
    let citation: Citation
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading) {
            // Citation preview with similarity score
            HStack {
                Text(citation.content)
                    .lineLimit(isExpanded ? nil : 2)
                Spacer()
                Text("\(Int(citation.similarity * 100))%")
                    .foregroundColor(.secondary)
            }

            // Expanded context
            if isExpanded {
                Text(citation.context)
                    .padding(.top, 4)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            withAnimation { isExpanded.toggle() }
        }
    }
}
```

### 3. Citation Navigation
- Implement deep linking to cited messages
- Handle citation preview in carousel
- Support citation search and filtering

## Success Criteria
- Clear citation visualization
- Smooth navigation between citations
- Accurate similarity scores
- Efficient context display

=== File: docs/issues/issue_13.md ===



==
issue_13
==


# LanceDB Migration & Multimodal Support

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Migrate from Qdrant to LanceDB for vector storage and add support for multimodal embeddings (text, images, audio), preparing for future content types.

## Tasks

### 1. LanceDB Setup
```python
# Database setup
import lancedb

db = lancedb.connect("choir.lance")
messages = db.create_table(
    "messages",
    schema={
        "id": "string",
        "content": "string",
        "thread_id": "string",
        "created_at": "string",
        "embedding": "vector[1536]",  # OpenAI embedding size
        "modality": "string",         # text/image/audio
        "media_url": "string",        # for non-text content
        "chorus_result": "json"
    }
)
```

### 2. Migration Pipeline
```python
class MigrationPipeline:
    def __init__(self):
        self.qdrant = QdrantClient(...)
        self.lancedb = lancedb.connect("choir.lance")
        self.rate_limiter = asyncio.Semaphore(50)

    async def migrate_points(self):
        async for batch in self.scroll_points():
            await self.process_batch(batch)

    async def process_batch(self, points):
        results = []
        for point in points:
            try:
                # Convert point format
                new_point = self.convert_point(point)
                results.append(new_point)
            except Exception as e:
                self.failed_points.append((point.id, str(e)))

        # Batch insert to LanceDB
        if results:
            await self.lancedb.messages.add(results)
```

### 3. Multimodal Support
- Add image embedding generation
- Support audio content processing
- Implement cross-modal search

## Success Criteria
- Successful data migration
- Support for multiple content types
- Maintained search performance
- Clean error handling

=== File: docs/issues/issue_2.md ===



==
issue_2
==


# SUI Blockchain Smart Contracts

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Depends on: [Local Data Management and Persistence](issue_1.md)


## Description

Implement SUI blockchain integration using SUIKit for secure user authentication, thread ownership, and message verification. Focus on establishing the foundational blockchain interactions while maintaining secure key management.

## Tasks

### 1. SUIKit Integration

- **Add SUIKit Package**
  ```swift
  // Package.swift
  dependencies: [
      .package(url: "https://github.com/OpenDive/SuiKit.git", .upToNextMajor(from: "1.2.2"))
  ]
  ```
- Configure providers for testnet/mainnet
- Implement basic wallet operations

### 2. Key Management

- **Implement Secure Key Storage**

  ```swift
  class KeyManager {
      private let keychain = KeychainService()

      func storeKeys(_ wallet: Wallet) throws {
          try keychain.save(wallet.privateKey, forKey: "sui_private_key")
          try keychain.save(wallet.publicKey, forKey: "sui_public_key")
      }
  }
  ```

- Use Keychain for private key storage
- Handle key import/export securely

### 3. User Authentication

- Implement wallet-based authentication
- Create user profiles linked to SUI addresses
- Handle session management

### 4. Thread Ownership

- Design thread ownership smart contract
- Implement thread creation/transfer
- Handle co-author permissions

## Success Criteria

- Secure key management
- Reliable blockchain interactions
- Clean integration with SwiftData
- Comprehensive test coverage

## Future Considerations

- Advanced smart contract features
- Multi-device key sync
- Enhanced permission models

=== File: docs/issues/issue_5.md ===



==
issue_5
==


# Enhanced UI/UX with Carousel and Interaction Patterns

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Related to: [Testing and Quality Assurance](issue_7.md)

## Description

Implement the carousel-based UI pattern for navigating through Chorus Cycle phases, with a focus on typographic design and fluid interactions. The interface should show previews of adjacent phases while maintaining clarity and usability.

## Tasks

### 1. Carousel Implementation

- **Basic TabView Setup**

  ```swift
  struct ChorusCarouselView: View {
      @State private var currentPhase: Phase = .action
      @ObservedObject var viewModel: ChorusViewModel

      var body: some View {
          TabView(selection: $currentPhase) {
              ForEach(Phase.allCases) { phase in
                  PhaseView(phase: phase, viewModel: viewModel)
                      .tag(phase)
              }
          }
          .tabViewStyle(.page)
      }
  }
  ```

### 2. Phase Views

- **Individual Phase Display**

  ```swift
  struct PhaseView: View {
      let phase: Phase
      @ObservedObject var viewModel: ChorusViewModel

      var body: some View {
          VStack {
              // Phase content with typographic styling
              // Adjacent phase previews
              // Loading states
          }
      }
  }
  ```

### 3. Animations and Transitions

- Implement smooth phase transitions
- Add loading state animations
- Handle gesture-based navigation

### 4. Accessibility

- Support VoiceOver
- Implement Dynamic Type
- Add accessibility labels and hints

## Success Criteria

- Smooth navigation between phases
- Clear visibility of current and adjacent phases
- Responsive animations and transitions
- Full accessibility support

## Future Considerations

- Advanced gesture controls
- Custom transition animations
- Enhanced typographic treatments

=== File: docs/issues/issue_7.md ===



==
issue_7
==


# Testing and Quality Assurance

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Related to: [Documentation and Developer Onboarding](issue_8.md)

## Description

Establish comprehensive testing protocols for the client-side architecture, focusing on SUI blockchain integration, AI API interactions through the proxy, and the carousel UI. Ensure reliability and performance across all components.

## Tasks

### 1. Unit Testing

- **SwiftData Models**

  ```swift
  class ModelTests: XCTestCase {
      var container: ModelContainer!

      override func setUp() {
          container = try! ModelContainer(
              for: User.self, Thread.self, Message.self,
              configurations: ModelConfiguration(isStoredInMemoryOnly: true)
          )
      }

      func testThreadCreation() async throws {
          let user = User(id: UUID(), publicKey: "test_key")
          let thread = Thread(title: "Test Thread", owner: user)
          container.mainContext.insert(thread)
          try container.mainContext.save()

          XCTAssertEqual(thread.owner.id, user.id)
      }
  }
  ```

### 2. Integration Testing

- **SUI Integration Tests**

  ```swift
  class SUIntegrationTests: XCTestCase {
      func testWalletCreation() async throws {
          let wallet = try await SUIWallet.create()
          XCTAssertNotNil(wallet.publicKey)
          XCTAssertNotNil(wallet.privateKey)
      }

      func testMessageSigning() async throws {
          let message = "Test message"
          let signature = try await wallet.sign(message)
          let isValid = try await wallet.verify(signature, for: message)
          XCTAssertTrue(isValid)
      }
  }
  ```

### 3. UI Testing

- **Carousel Navigation Tests**

  ```swift
  class CarouselUITests: XCTestCase {
      func testPhaseNavigation() {
          let app = XCUIApplication()
          app.launch()

          // Test swipe gestures
          let carousel = app.otherElements["phase_carousel"]
          carousel.swipeLeft()
          XCTAssertTrue(app.staticTexts["Experience"].exists)
      }
  }
  ```

### 4. Performance Testing

- Measure AI API response times
- Monitor memory usage
- Test under different network conditions

## Success Criteria

- High test coverage (>80%)
- Stable CI/CD pipeline
- Reliable blockchain interactions
- Smooth UI performance

## Future Considerations

- Automated UI testing
- Load testing for proxy server
- Enhanced blockchain testing

=== File: docs/issues/issue_8.md ===



==
issue_8
==


# Deploy to TestFlight and Render

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Deploy the iOS app to TestFlight and the proxy server to Render, ensuring secure configuration and proper monitoring.

## Tasks

### 1. Proxy Server Deployment
```python
# app/config.py
class Settings:
    ANTHROPIC_API_KEY: str
    OPENAI_API_KEY: str
    QDRANT_URL: str
    QDRANT_API_KEY: str

    class Config:
        env_file = ".env"
```

- [ ] Configure Render service
  - [ ] Set environment variables
  - [ ] Configure logging
  - [ ] Set up monitoring
  - [ ] Deploy API

### 2. TestFlight Submission
- [ ] App Store Connect setup
  - [ ] Configure app details
  - [ ] Add test information
  - [ ] Set up TestFlight users
- [ ] Build preparation
  - [ ] Update bundle ID
  - [ ] Configure signing
  - [ ] Set version/build numbers
- [ ] Submit build
  - [ ] Run archive
  - [ ] Upload to App Store Connect
  - [ ] Submit for review

## Success Criteria
- Proxy server running reliably on Render
- App approved on TestFlight
- Monitoring in place
- Error tracking functional

=== File: docs/issues/issue_9.md ===



==
issue_9
==


# Message Rewards Implementation

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Implement message rewards using vector similarity for uniqueness calculation and prior citation value, distributed through a Python-controlled SUI wallet. This provides a foundation for testing token economics before implementing smart contracts.

## Tasks

### 1. SUI Wallet Controller
```python
class ChoirWallet:
    def __init__(self, network: str = "devnet"):
        self.client = SuiClient(network=network)
        self.base_reward = 100  # Base SUI reward amount
        self.base_prior_reward = 50  # Base citation reward

    async def calculate_uniqueness_reward(
        self,
        content: str,
        vector_db: QdrantClient
    ) -> float:
        # Get embedding
        embedding = await get_embedding(content)

        # Search for similar content
        similar = await vector_db.search(
            collection_name="messages",
            query_vector=embedding,
            limit=10
        )

        # 1.0 = unique, 0.0 = duplicate
        max_similarity = max(r.score for r in similar) if similar else 0.0
        uniqueness = 1.0 - max_similarity

        return self.base_reward * uniqueness

    async def distribute_rewards(
        self,
        message_content: str,
        author_address: str,
        cited_priors: List[Prior],
        vector_db: QdrantClient
    ):
        # Calculate and send new message reward
        reward = await self.calculate_uniqueness_reward(
            message_content,
            vector_db
        )
        await self.send_sui(author_address, reward)

        # Handle prior citation rewards
        for prior in cited_priors:
            if prior.quality_score > QUALITY_THRESHOLD:
                citation_reward = self.base_prior_reward * prior.quality_score
                await self.send_sui(prior.author_address, citation_reward)
```

### 2. Yield Phase Integration
```python
@router.post("/yield")
async def yield_phase(
    request: YieldRequest,
    choir_wallet: ChoirWallet = Depends(get_choir_wallet),
    vector_db: QdrantClient = Depends(get_vector_db)
):
    # Process yield response
    response = await process_yield(request)

    # Only distribute rewards if message is approved
    if response.approved:
        await choir_wallet.distribute_rewards(
            message_content=request.content,
            author_address=request.author_address,
            cited_priors=response.citations,
            vector_db=vector_db
        )

    return response
```

### 3. Monitoring & Analytics
```python
class RewardMetrics:
    async def log_distribution(
        self,
        message_id: str,
        author_reward: float,
        prior_rewards: Dict[str, float],
        uniqueness_score: float
    ):
        # Log reward distribution for analysis
        # This data will inform smart contract design
        pass

    async def analyze_distribution_patterns(self):
        # Analyze reward patterns to tune parameters
        # Track semantic clustering effects
        # Monitor economic effects
        pass
```

## Success Criteria
- Rewards scale properly with semantic uniqueness
- Prior citations receive appropriate value
- Distribution transactions complete reliably
- System maintains economic stability
- Clear metrics for tuning parameters

## Future Evolution
- Migration path to smart contracts
- Enhanced economic models
- Community governance of parameters
- Integration with thread contracts
- Advanced citation value calculations

## Notes
- Start with conservative base reward values
- Monitor distribution patterns closely
- Gather data for smart contract design
- Focus on semantic value creation
- Build community through fair distribution
