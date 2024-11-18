# Level 0 Documentation



=== File: docs/issues/issue_-1.md ===



==
issue_-1
==


# Development Environment Setup

## Description
Set up and configure development environment for efficient implementation of core message system.

## Tasks
- [x] Configure test environment
  - [x] Set up test database # the database we have is the test database. when ready to launch we will make new database
  - [x] Configure test vectors
  - [x] Add test users/threads
- [ ] Set up monitoring
  - [ ] Logging configuration
  - [ ] Performance metrics
  - [ ] Error tracking
- [ ] Development tools
  - [ ] SwiftFormat configuration
  - [ ] SwiftLint rules
  - [ ] Git hooks

## Success Criteria
- Clean development environment
- Efficient testing setup
- Consistent code style
- Proper monitoring

=== File: docs/issues/issue_0.md ===



==
issue_0
==


# Core Client-Side Implementation

## Overview

Implement the foundational client-side system that enables AI processing via Anthropic and OpenAI APIs, SUI blockchain integration, and the carousel UI for the Chorus Cycle. Focus on creating a functional Minimum Viable Product (MVP) that demonstrates key features while preparing for future integration with Liquid AI's Liquid Foundation Models (LFMs).

## Sub-Issues

1. [Local Data Management and Persistence](issue_1.md)
2. [SUI Blockchain Smart Contracts](issue_2.md)
3. [Tokenomics and CHOIR Token Integration](issue_3.md)
4. [Proxy Security and Backend Services](issue_4.md)
5. [Enhanced UI/UX with Carousel and Interaction Patterns](issue_5.md)
6. [Client-Side Intelligence and Personalization](issue_6.md)
7. [Testing and Quality Assurance](issue_7.md)
8. [Documentation and Developer Onboarding](issue_8.md)

## Tasks

### 1. AI Processing via APIs

- **Integrate Anthropic and OpenAI APIs**

  - Set up API clients for Anthropic and OpenAI.
  - Implement functions to send prompts and receive responses.
  - Handle API rate limits and errors gracefully.

- **Prepare for Future LFM Integration**
  - Design the architecture to allow easy switching from API-based models to local LFMs.
  - Abstract AI processing logic to accommodate different model sources.

### 2. SUI Wallet Integration

- **Integrate SUIKit for Blockchain Interactions**
  - Implement wallet creation, import, and transaction signing within the app.
  - Facilitate user authentication via SUI wallet.

### 3. Carousel UI Implementation

- **Develop Carousel UI Pattern**
  - Create a carousel interface for navigating through Chorus Cycle phases.
  - Ensure adjacent phase previews are visible for a typographic, newspaper-like design.

### 4. Proxy Authentication Setup

- **Set Up Secure API Proxy**
  - Deploy a server-side proxy to handle AI API requests securely.
  - Implement SUI-signed token authentication for proxy access.

### 5. Initial Testing

- **Conduct Initial Integration Tests**
  - Verify AI API integrations.
  - Test SUI wallet functionalities.
  - Ensure carousel UI navigates smoothly between phases.

## Success Criteria

- **Functional MVP**

  - Users can authenticate with their SUI wallet.
  - Users can input messages and navigate through the Chorus Cycle using the carousel UI.
  - AI responses are fetched and displayed correctly via Anthropic and OpenAI APIs.

- **Secure Operations**

  - Proxy server securely handles API requests and authentication.
  - API keys remain protected on the server side.

- **Scalable Architecture**
  - The system is designed to switch to Liquid AI's LFMs with minimal changes.
  - Codebase follows best practices for scalability and maintainability.

## Future Considerations

- **Liquid AI LFMs Integration**
  - Once access is granted, integrate LFMs for on-device AI processing.
  - Optimize the architecture to transition from API-based to local model-based processing seamlessly.

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
- Related to: [API Client Message Handling](issue_2.md)

## Description

Implement local data storage and synchronization using SwiftData, managing users, threads, and messages effectively. This ensures data persistence and offline access while preparing for future synchronization with the SUI blockchain.

## Tasks

### 1. Define SwiftData Models

- **Create Models for `User`, `Thread`, and `Message`**

  - Ensure appropriate relationships and data integrity.
  - Support offline access and local data persistence.

- **Implement Data Relationships**
  - Define one-to-many and many-to-many relationships as needed.
  - Ensure models align with blockchain ownership data.

### 2. Implement Data Operations

- **CRUD Operations for Threads and Messages**

  - Implement create, read, update, and delete functionalities.
  - Ensure smooth user interactions and data consistency.

- **Handle Data Consistency and Conflict Resolution**
  - Develop mechanisms to resolve data conflicts between local and blockchain data.
  - Implement versioning or timestamps to manage updates.

### 3. Prepare for Future Synchronization

- **Design Synchronization Logic**

  - Outline how local data will sync with on-chain data.
  - Plan for data reconciliation and conflict handling.

- **Implement Initial Sync Mechanism**
  - Develop basic synchronization between local data and blockchain state.
  - Test synchronization with sample data.

## Success Criteria

- **Reliable Local Storage**

  - Users can create and manage threads and messages locally.
  - Data persists across app launches and device restarts.

- **Efficient Data Handling**

  - CRUD operations perform smoothly without lag.
  - Data relationships are maintained accurately.

- **Preparation for Blockchain Synchronization**
  - Architecture supports future data synchronization.
  - Initial sync tests are successful, laying the groundwork for full integration.

## Future Considerations

- **SUI Blockchain Synchronization**

  - Implement full data synchronization with the SUI blockchain.
  - Ensure real-time updates and consistency between local and on-chain data.

- **Advanced Conflict Resolution**
  - Develop sophisticated methods to handle complex data conflicts.
  - Implement user prompts or automated resolutions where appropriate.

---

=== File: docs/issues/issue_10.md ===



==
issue_10
==


# Deploy to Render and TestFlight

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: All implementation issues
- Related to: [Development Environment Setup](issue_-1.md)

## Description
Deploy the Python API service to Render and submit the iOS app to TestFlight for testing, ensuring proper configuration and monitoring.

## Tasks
1. Render Deployment
   - [ ] Configure Render service
     - [ ] Set environment variables
     - [ ] Configure Qdrant connection
     - [ ] Set up logging
   - [ ] Deploy API
     - [ ] Test endpoints
     - [ ] Monitor performance
     - [ ] Check error reporting

2. TestFlight Submission
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

## Code Examples
```yaml
# render.yaml
services:
  - type: web
    name: choir-api
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: QDRANT_URL
        sync: false
      - key: QDRANT_API_KEY
        sync: false
      - key: OPENAI_API_KEY
        sync: false
```

```swift
// Configuration.swift
enum Configuration {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000"
    #else
    static let apiBaseURL = "https://choir-api.onrender.com"
    #endif
}
```

## Testing Requirements
1. API Deployment
   - Endpoint accessibility
   - Error handling
   - Performance metrics
   - Security headers

2. TestFlight Build
   - App functionality
   - Network connectivity
   - Error reporting
   - Analytics integration

## Success Criteria
1. API Service
   - Successfully deployed
   - All endpoints working
   - Proper error handling
   - Good performance

2. iOS App
   - Approved for TestFlight
   - Working with deployed API
   - Clean error handling
   - Analytics reporting

## Notes
- Keep development database for now
- Monitor API performance
- Track error rates
- Collect usage metrics

=== File: docs/issues/issue_11.md ===



==
issue_11
==


# Thread Sheet Implementation

## THIS IS AI SLOP BECAUSE IVE UNDERSPECIFIED IT

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread State Management](issue_5.md)
- Related to: [User Identity Implementation](issue_4.md)

## Description
Implement the thread sheet UI component that displays thread messages, handles user input, and shows chorus cycle results.

## Tasks
- [ ] Create thread sheet view
  - [ ] Message list display
  - [ ] Input handling
  - [ ] Chorus result visualization
- [ ] Add state management
  - [ ] Thread loading
  - [ ] Message updates
  - [ ] UI state handling
- [ ] Implement interactions
  - [ ] Message submission
  - [ ] Loading states
  - [ ] Error handling

## Code Examples
```swift
struct ThreadSheet: View {
    @ObservedObject var thread: Thread
    @StateObject private var viewModel: ThreadViewModel
    @State private var inputText = ""

    var body: some View {
        VStack {
            MessageList(messages: thread.messages)

            InputField(
                text: $inputText,
                onSubmit: {
                    Task {
                        try await viewModel.submitMessage(inputText)
                    }
                }
            )
        }
    }
}

class ThreadViewModel: ObservableObject {
    @Published private(set) var isProcessing = false
    private let coordinator: ChorusCoordinator

    func submitMessage(_ content: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        try await coordinator.process(content)
    }
}
```

## Testing Requirements
- UI state management
- User interactions
- Error presentation
- Performance with large threads

## Success Criteria
- Smooth user experience
- Clear state feedback
- Proper error handling
- Responsive interface

=== File: docs/issues/issue_12.md ===



==
issue_12
==


# Message Rewards Implementation
## THE FORMULAS LOOK DIFFERENT THAN THE ONES IN THE DOCS. THE MATH BETTER BE MATHING.


## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Related to: [Thread State Management](issue_5.md)
- Blocks: None

## Description
Implement the message rewards system using the quantum harmonic oscillator model for new messages and prior citations.

## Current State
- Have formulas defined:
  ```
  New Message Rewards:
  R(t) = R_total × k/(1 + kt)ln(1 + kT)

  Prior Value:
  V(p) = B_t × Q(p)/∑Q(i)
  ```
- Need implementation in Swift
- Need integration with thread state

## Tasks
- [ ] Implement reward calculations
  - [ ] New message rewards
  - [ ] Prior citation rewards
  - [ ] Quality scoring
- [ ] Add reward distribution
  - [ ] Treasury management
  - [ ] User balance updates
  - [ ] Transaction logging
- [ ] Integrate with thread state
  - [ ] Track rewards per message
  - [ ] Update thread temperature
  - [ ] Handle stake requirements

## Code Examples
```swift
struct RewardCalculator {
    // Constants
    static let TOTAL_SUPPLY: Double = 2.5e9  // 2.5B total
    static let DECAY_CONSTANT: Double = 2.04
    static let TOTAL_PERIOD: TimeInterval = 4 * 365 * 24 * 3600  // 4 years

    // New message rewards
    func calculateMessageReward(at timestamp: Date) -> Double {
        let t = timestamp.timeIntervalSince(LAUNCH_DATE)
        let k = DECAY_CONSTANT
        let T = TOTAL_PERIOD

        return TOTAL_SUPPLY * (k / (1 + k * t)) * log(1 + k * T)
    }

    // Prior citation rewards
    func calculatePriorValue(
        quality: Double,
        totalQuality: Double,
        treasuryBalance: Double
    ) -> Double {
        return treasuryBalance * (quality / totalQuality)
    }
}

actor RewardManager {
    private let calculator: RewardCalculator
    private var treasuryBalance: Double

    func processNewMessage(_ message: MessagePoint) async throws -> Double {
        let reward = calculator.calculateMessageReward(at: message.createdAt)
        try await distributeReward(reward, to: message.authorId)
        return reward
    }

    func processPriorCitation(
        _ prior: Prior,
        quality: Double,
        totalQuality: Double
    ) async throws -> Double {
        let value = calculator.calculatePriorValue(
            quality: quality,
            totalQuality: totalQuality,
            treasuryBalance: treasuryBalance
        )
        try await distributePriorReward(value, to: prior.authorId)
        return value
    }
}
```

## Testing Requirements
- Test reward calculations
  - Verify formula implementation
  - Test edge cases
  - Check decay over time
- Test distribution
  - Treasury management
  - Balance updates
  - Transaction integrity
- Test integration
  - Thread state updates
  - User balance changes
  - System coherence

## Success Criteria
- Accurate calculations
- Reliable distribution
- Clean integration
- Type-safe implementation

=== File: docs/issues/issue_13.md ===



==
issue_13
==


# Thread Contract Implementation

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread State Management](issue_5.md)
- Related to: [Message Rewards Implementation](issue_12.md)

## Description
Implement the thread contract that manages thread state evolution, stake requirements, and co-author relationships using the quantum harmonic oscillator model.

## Current State
- Have thread state in Qdrant
- Need stake mechanics
- Need temperature evolution
- Need co-author management

## Tasks
- [ ] Implement thread state
  ```swift
  struct ThreadState {
      let id: UUID
      let coAuthors: Set<PublicKey>
      let tokenBalance: TokenAmount
      let temperature: Float
      let frequency: Float
      let messageHashes: [Hash]
      let createdAt: Date

      // E(n) = ℏω(n + 1/2)
      var stakeRequirement: TokenAmount {
          let n = coAuthors.count
          let ω = frequency
          return TokenAmount(ℏ * ω * (Float(n) + 0.5))
      }
  }
  ```

- [ ] Add temperature evolution
  ```swift
  extension ThreadState {
      // T = T0/√(1 + t/τ)
      mutating func evolveTemperature(timeDelta: TimeInterval) {
          let coolingFactor = sqrt(1000 + timeDelta / 86400)
          temperature = (temperature * 1000) / coolingFactor
      }

      // Update after message approval/denial
      mutating func processApproval(_ approved: Bool) {
          if approved {
              // Distribute energy to co-authors
              temperature = tokenBalance / Float(coAuthors.count)
          } else {
              // Increase thread energy
              temperature += stakeRequirement.amount
          }
      }
  }
  ```

- [ ] Implement co-author management
  ```swift
  extension ThreadState {
      mutating func addCoAuthor(_ publicKey: PublicKey) throws {
          guard tokenBalance >= stakeRequirement else {
              throw ThreadError.insufficientStake
          }
          coAuthors.insert(publicKey)
      }

      func validateMessage(_ message: Message) -> Bool {
          coAuthors.contains(message.authorId)
      }
  }
  ```

## Testing Requirements
- Test state evolution
  - Temperature cooling
  - Stake requirements
  - Co-author management
- Test message validation
  - Author verification
  - Stake verification
  - Temperature effects
- Test error handling
  - Invalid stakes
  - Unauthorized authors
  - State transitions

## Success Criteria
- Clean state management
- Proper stake mechanics
- Reliable temperature evolution
- Type-safe operations

=== File: docs/issues/issue_14.md ===



==
issue_14
==


# LanceDB Migration & Multimodal Support


## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Related to: [Thread State Management](issue_5.md)

## Description
Migrate from Qdrant to LanceDB for vector storage and add support for multimodal embeddings (text, images, audio).

## Current State
- Have ~20k message points in Qdrant
- Text-only embeddings
- Need multimodal support
- Need migration strategy

## Tasks
1. LanceDB Setup
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

2. Re-Embedding Pipeline
   ```python
   from typing import AsyncIterator
   import asyncio
   from tenacity import retry, stop_after_attempt, wait_exponential

   class MigrationPipeline:
       def __init__(self):
           self.qdrant = QdrantClient(...)
           self.lancedb = lancedb.connect("choir.lance")
           self.openai = OpenAI()
           self.rate_limiter = asyncio.Semaphore(50)  # Control concurrent requests

       async def scroll_points(self, batch_size=100) -> AsyncIterator[List[Point]]:
           """Scroll through Qdrant points with batching."""
           offset = None
           while True:
               points, offset = await self.qdrant.scroll(
                   collection_name="messages",
                   limit=batch_size,
                   offset=offset,
                   with_payload=True,
                   with_vectors=True
               )
               if not points:
                   break
               yield points

       @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=60))
       async def get_embedding(self, content: str) -> List[float]:
           """Rate-limited embedding generation."""
           async with self.rate_limiter:
               response = await self.openai.embeddings.create(
                   model="text-embedding-3-large",
                   input=content
               )
               return response.data[0].embedding

       async def process_batch(self, points: List[Point]):
           """Process a batch of points with error handling."""
           results = []
           for point in points:
               try:
                   # Generate new embedding
                   new_embedding = await self.get_embedding(point.payload["content"])

                   # Compare with original
                   similarity = cosine_similarity(new_embedding, point.vector)
                   if similarity < 0.98:  # Significant difference
                       logger.warning(f"Embedding divergence for {point.id}: {similarity}")

                   results.append({
                       "id": str(point.id),
                       "content": point.payload["content"],
                       "thread_id": point.payload["thread_id"],
                       "created_at": point.payload["created_at"],
                       "embedding": new_embedding,
                       "modality": "text",
                       "original_similarity": similarity,
                       "chorus_result": point.payload.get("chorus_result")
                   })
               except Exception as e:
                   logger.error(f"Error processing point {point.id}: {e}")
                   # Store error for retry
                   self.failed_points.append((point.id, str(e)))

           # Batch insert to LanceDB
           if results:
               await self.lancedb.messages.add(results)

       async def run_migration(self):
           """Run the full migration with progress tracking."""
           total_points = await self.qdrant.count("messages")
           processed = 0

           async for batch in self.scroll_points():
               await self.process_batch(batch)
               processed += len(batch)

               # Progress update
               logger.info(f"Processed {processed}/{total_points} points")

           # Handle failed points
           if self.failed_points:
               logger.warning(f"Failed points: {len(self.failed_points)}")
               # Write failures to file for manual review
               with open("failed_migrations.json", "w") as f:
                   json.dump(self.failed_points, f)
   ```

3. Migration Monitoring
   ```python
   class MigrationMonitor:
       async def check_embedding_quality(self):
           """Compare embeddings between systems."""
           divergent = []
           async for point in self.pipeline.scroll_points():
               lance_point = self.lancedb.messages.get(point.id)
               similarity = cosine_similarity(
                   point.vector,
                   lance_point["embedding"]
               )
               if similarity < 0.98:
                   divergent.append((point.id, similarity))
           return divergent

       async def verify_data_integrity(self):
           """Verify all data migrated correctly."""
           qdrant_count = await self.qdrant.count("messages")
           lance_count = len(self.lancedb.messages)

           assert lance_count >= qdrant_count, "Missing points in LanceDB"

           # Check random samples for payload equality
           for _ in range(100):
               point_id = random.choice(await self.get_all_ids())
               qdrant_point = await self.qdrant.retrieve(point_id)
               lance_point = self.lancedb.messages.get(point_id)

               assert self.payloads_equal(
                   qdrant_point.payload,
                   lance_point
               ), f"Payload mismatch for {point_id}"
   ```

## Testing Requirements
- Migration validation
  - Data integrity
  - Embedding preservation
  - Performance comparison
- Multimodal support
  - Text embeddings
  - Image embeddings
  - Audio embeddings
- Search functionality
  - Cross-modal search
  - Relevance scoring
  - Performance metrics

## Success Criteria
- Clean migration
- Multimodal support
- Improved performance
- Type-safe operations

=== File: docs/issues/issue_15.md ===



==
issue_15
==


# Citation Visualization and Handling

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread Sheet Implementation](issue_11.md)
- Related to: [Message Type Reconciliation](issue_1.md)

## Description
Implement citation visualization and handling in the UI, allowing users to see and interact with prior references while maintaining the quantum harmonic model of knowledge coupling.

## Current State
- Have Prior type in ChorusModels
- Citations stored in Qdrant
- Need UI representation
- Need interaction model

## Tasks
1. Citation Data Model
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

2. Citation View Components
   ```swift
   struct CitationView: View {
       let citation: Citation
       @State private var isExpanded = false

       var body: some View {
           VStack(alignment: .leading) {
               // Citation preview
               HStack {
                   Text(citation.content)
                       .lineLimit(isExpanded ? nil : 2)
                   Spacer()
                   Text(String(format: "%.0f%%", citation.similarity * 100))
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
               withAnimation {
                   isExpanded.toggle()
               }
           }
       }
   }

   struct MessageCitationsView: View {
       let message: ThreadMessage

       var body: some View {
           if !message.citations.isEmpty {
               VStack(alignment: .leading, spacing: 8) {
                   Text("Citations")
                       .font(.headline)

                   ForEach(message.citations) { citation in
                       CitationView(citation: citation)
                           .padding(.vertical, 4)
                   }
               }
               .padding()
               .background(Color(.systemBackground))
               .cornerRadius(8)
           }
       }
   }
   ```

3. Citation Interaction
   ```swift
   class CitationManager: ObservableObject {
       @Published private(set) var activeCitations: [Citation] = []
       private let api: ChorusAPIClient

       func loadCitation(_ link: URL) async throws {
           guard let messageId = link.lastPathComponent else { return }
           let message = try await api.getMessage(messageId)
           // Create and add citation
       }

       func navigateToCitation(_ citation: Citation) {
           // Handle navigation to cited message
       }
   }
   ```

## Testing Requirements
1. Citation Parsing
   - Markdown link extraction
   - URL validation
   - Content parsing

2. UI Components
   - Layout rendering
   - Expansion behavior
   - Navigation handling

3. Interaction Flow
   - Citation loading
   - Navigation
   - Error handling

## Success Criteria
- Clean citation visualization
- Smooth interaction flow
- Clear relationship display
- Performance with many citations

=== File: docs/issues/issue_2.md ===



==
issue_2
==


# API Client Message Handling

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Blocks: [Coordinator Message Flow](issue_3.md)
- Related to: [Thread State Management](issue_5.md)

## Description
Update ChorusAPIClient to handle the new unified message types while maintaining compatibility with existing endpoints and response structures.

## Current State
- Have working API client with phase-specific endpoints
- Using existing response types from ChorusModels.swift
- Need to add message point handling
- Need to integrate with Qdrant collections

## Tasks
- [ ] Add message point endpoints
  - [ ] getMessage by ID
  - [ ] storeMessage with vector
  - [ ] getThreadMessages with pagination
- [ ] Update phase endpoints
  - [ ] Modify request/response types
  - [ ] Add message context
  - [ ] Handle errors gracefully
- [ ] Add thread operations
  - [ ] Create/get thread
  - [ ] Update thread state
  - [ ] Handle message lists
- [ ] Implement error handling
  - [ ] Type-specific errors
  - [ ] Retry logic
  - [ ] Error reporting

## Code Examples
```swift
extension ChorusAPIClient {
    // Message operations
    func getMessage(_ id: String) async throws -> MessagePoint {
        return try await post(endpoint: "messages/\(id)", body: EmptyBody())
    }

    func storeMessage(_ message: MessagePoint) async throws {
        try await post(endpoint: "messages", body: message)
    }

    func getThreadMessages(
        _ threadId: String,
        limit: Int = 50,
        before: String? = nil
    ) async throws -> [MessagePoint] {
        return try await post(
            endpoint: "threads/\(threadId)/messages",
            body: GetMessagesRequest(
                limit: limit,
                before: before
            )
        )
    }

    // Phase operations with message context
    func processAction(_ input: String, context: [MessagePoint]) async throws -> ActionResponse {
        return try await post(
            endpoint: "chorus/action",
            body: ActionRequestBody(
                content: input,
                threadID: currentThreadId,
                context: context
            )
        )
    }
}

// Error handling
enum APIError: Error {
    case messageNotFound(String)
    case invalidMessageData(String)
    case threadOperationFailed(String)
    case networkError(Error)
    case decodingError(Error)
}
```

## Testing Requirements
- Test message operations
  - Get/store messages
  - Thread message retrieval
  - Pagination handling
- Verify phase operations
  - Context handling
  - Response processing
  - Error cases
- Test error handling
  - Network errors
  - Invalid data
  - Missing resources

## Success Criteria
- Reliable message operations
- Clean error handling
- Type-safe API interface
- Proper context handling

=== File: docs/issues/issue_3.md ===



==
issue_3
==


# docs/issues/issue_3.md

# Tokenomics and CHOIR Token Integration

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Depends on: [SUI Blockchain Smart Contracts](issue_2.md)
- Blocks: [Proxy Security and Backend Services](issue_4.md)
- Related to: [Client-Side Intelligence and Personalization](issue_6.md)

## Description

Integrate the CHOIR token within the app, enabling staking, rewards distribution, and token transactions in line with the economic model. This involves setting up the token mechanics through smart contracts and ensuring seamless user interactions with tokens.

## Tasks

### 1. Token Mechanics Implementation

- **Display Token Balances**

  - Show users their CHOIR token balances within the app.
  - Include both wallet balance and staked amounts.

- **Implement Staking Functionality**

  - Allow users to stake tokens when participating in threads.
  - Enable staking amounts to vary based on thread temperature or frequency.

- **Reward Distribution**
  - Distribute rewards based on user contributions and participation.
  - Implement automated reward calculations tied to the quantum harmonic oscillator model.

### 2. User Interface Enhancements

- **Rewards Dashboard**

  - Create a dashboard displaying earned rewards.
  - Visualize performance and progress in token accumulation.

- **Staking Actions**

  - Include UI elements for staking and unstaking tokens.
  - Guide users through the staking process with clear instructions.

- **Transaction History**
  - Provide a ledger of token transactions.
  - Enhance transparency and user trust.

### 3. Education and Compliance

- **In-App Explanations**

  - Include explanations of token mechanics within the app.
  - Educate users on staking, rewards, and token usage.

- **Regulatory Compliance**
  - Ensure the tokenomics align with relevant financial and data protection regulations.
  - Implement necessary measures for compliance.

## Success Criteria

- **Seamless Token Integration**

  - Users can view, stake, and manage their CHOIR tokens effortlessly.
  - Token transactions are processed correctly and securely via the blockchain.

- **Aligned Economic Model**

  - Tokenomics reflect the documented economic principles of the platform.
  - Rewards distribution is fair and incentivizes desired user behaviors.

- **User Education**
  - Users understand how the token system works through in-app resources.
  - Compliance with regulations is maintained to avoid legal issues.

## Future Considerations

- **Advanced Token Features**

  - Explore decentralized governance models using CHOIR tokens.
  - Implement additional token utilities as the platform evolves.

- **Dynamic Reward Systems**
  - Adapt reward mechanisms based on user feedback and platform needs.
  - Introduce tiered rewards or bonuses for high contributors.

---

=== File: docs/issues/issue_4.md ===



==
issue_4
==


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

=== File: docs/issues/issue_5.md ===



==
issue_5
==


# Thread State Management

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md), [User Identity Implementation](issue_4.md)
- Blocks: None
- Related to: [Coordinator Message Flow](issue_3.md)

## Description
Implement thread state management that maintains local state while synchronizing with Qdrant storage, handling message history and thread metadata.

## Tasks
- [ ] Implement Thread model with message history
- [ ] Add thread state synchronization
- [ ] Handle message addition/removal
- [ ] Implement thread metadata updates

## Code Examples
```swift
class Thread: ObservableObject, Identifiable {
    let id: UUID
    let authorId: String  // public key
    @Published private(set) var messages: [ThreadMessage]

    func addMessage(_ content: String) async throws {
        let message = ThreadMessage(content: content)
        messages.append(message)

        // Sync with Qdrant
        try await vectorStorage.storeMessage(message)
    }

    func loadHistory() async throws {
        messages = try await api.getThreadMessages(id.uuidString)
            .map(ThreadMessage.init)
    }
}
```

## Testing Requirements
- Test thread creation/loading
- Verify message synchronization
- Test state management
- Validate error handling

## Success Criteria
- Reliable state management
- Clean synchronization
- Proper error handling

=== File: docs/issues/issue_6.md ===



==
issue_6
==


# Integration Testing Suite

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: All previous issues
- Blocks: None
- Related to: All implementation issues

## Description
Create comprehensive integration tests that verify the entire message flow, from user creation through thread management and message processing.

## Tasks
- [ ] Set up test environment
- [ ] Create end-to-end flow tests
- [ ] Add performance tests
- [ ] Implement error scenario tests

## Code Examples
```swift
class IntegrationTests: XCTestCase {
    func testCompleteMessageFlow() async throws {
        // Create user
        let user = try await userManager.createUser()

        // Create thread
        let thread = try await threadManager.createThread("Test Thread")

        // Add message
        let message = try await thread.addMessage("Test message")

        // Verify storage
        let stored = try await api.getMessage(message.id)
        XCTAssertEqual(stored.content, "Test message")

        // Verify thread state
        XCTAssertEqual(thread.messages.count, 1)
    }
}
```

## Testing Requirements
- Full flow coverage
- Error scenario testing
- Performance benchmarks
- State verification

## Success Criteria
- Complete test coverage
- Reliable test suite
- Clear failure reporting

=== File: docs/issues/issue_7.md ===



==
issue_7
==


# Error Handling Strategy

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: All implementation issues
- Blocks: None
- Related to: [Integration Testing Suite](issue_6.md)

## Description
Implement comprehensive error handling strategy across all layers (API, Coordinator, User, Thread) with proper error propagation and user feedback.

## Tasks
- [ ] Define error types hierarchy
- [ ] Implement error propagation
- [ ] Add error recovery strategies
- [ ] Create user-facing error messages

## Code Examples
```swift
enum ChoirError: Error {
    // API Errors
    case networkError(underlying: Error)
    case decodingError(context: String)

    // Domain Errors
    case messageNotFound(id: String)
    case threadAccessDenied(id: String)
    case userNotAuthenticated

    // State Errors
    case invalidPhaseTransition(from: Phase, to: Phase)
    case inconsistentThreadState(details: String)

    var userMessage: String {
        switch self {
        case .networkError:
            return "Unable to connect. Please check your connection."
        case .messageNotFound:
            return "Message not found."
        // etc...
        }
    }
}
```

=== File: docs/issues/issue_8.md ===



==
issue_8
==


# docs/issues/issue_8.md

# Documentation and Developer Onboarding

## Parent Issue

[Core Client-Side Implementation](issue_0.md)

## Related Issues

- Depends on: All previous issues (0-7)
- Blocks: None
- Related to: None

## Description

Update and expand documentation to facilitate team growth and knowledge sharing. Ensure that new team members can onboard quickly and contribute effectively by providing clear guides, coding standards, and comprehensive documentation of all components.

## Tasks

### 1. Update Technical Documentation

- **Document New Components**

  - Ensure that all newly implemented features (e.g., proxy authentication, SUI integration, carousel UI) are thoroughly documented.
  - Include architecture diagrams, flowcharts, and code examples where applicable.

- **API Usage Guides**

  - Provide detailed guides on how to use the integrated Anthropic and OpenAI APIs.
  - Document the abstraction layer facilitating future LFM integration.

- **Smart Contract Documentation**
  - Detail the functionalities of each smart contract deployed on the SUI blockchain.
  - Explain how thread ownership, token mechanics, and permissions are managed on-chain.

### 2. Create Onboarding Guides

- **Development Environment Setup**

  - Update `Development Environment Setup` to reflect the current client-side architecture and dependencies.
  - Include steps for setting up SwiftData, SUI wallets, and proxy server connections.

- **Coding Standards and Best Practices**

  - Define and document coding standards for Swift, ensuring consistency across the codebase.
  - Outline best practices for using SwiftUI, asynchronous programming, and secure coding.

- **Contribution Guidelines**
  - Provide guidelines on how to contribute to the project, including branching strategies, commit message conventions, and code review processes.

### 3. Knowledge Base Creation

- **Use Wikis or Documentation Sites**

  - Set up a centralized knowledge base using tools like GitHub Wikis, Notion, or ReadTheDocs.
  - Organize information for easy access, categorizing by components, features, and processes.

- **Encourage Team Contributions**
  - Allow team members to add and update documentation.
  - Implement a review process to ensure documentation quality and accuracy.

### 4. Continuous Documentation Updates

- **Maintain Up-to-Date Docs**

  - Regularly update documentation to reflect ongoing development and changes.
  - Assign ownership for different documentation sections to responsible team members.

- **Integrate Documentation into CI/CD**
  - Automate the generation and validation of documentation during the CI/CD pipeline.
  - Ensure that documentation is built and available with each release.

## Success Criteria

- **Comprehensive Documentation**

  - All aspects of the platform are well-documented, including architecture, features, and usage.
  - Documentation is clear, concise, and accessible to all team members.

- **Efficient Onboarding**

  - New developers can set up their development environment and start contributing quickly.
  - Onboarding guides cover all necessary steps and common issues.

- **Active Knowledge Sharing**
  - Team members regularly contribute to and update the knowledge base.
  - Documentation evolves with the project, maintaining relevance and accuracy.

## Future Considerations

- **Advanced Documentation Features**

  - Implement search functionality for the knowledge base to enhance accessibility.
  - Incorporate interactive tutorials or walkthroughs for complex features.

- **Localization and Internationalization**

  - Translate documentation into multiple languages to support a diverse development team.
  - Ensure that technical terms are consistently translated and understood.

- **Feedback Mechanisms**
  - Enable team members to provide feedback or suggest improvements to documentation.
  - Regularly review and incorporate feedback to enhance documentation quality.

## Action Plan

1. **Audit Existing Documentation**

   - Review current documentation for completeness and accuracy.
   - Identify gaps and prioritize areas needing updates.

2. **Assign Documentation Owners**

   - Assign team members to be responsible for different sections of the documentation.
   - Ensure accountability and regular updates.

3. **Implement Onboarding Guides**

   - Develop step-by-step guides for setting up the development environment.
   - Include troubleshooting sections for common setup issues.

4. **Establish Contribution Processes**

   - Define how team members can contribute to and update documentation.
   - Implement review processes to maintain documentation quality.

5. **Integrate into Development Workflow**

   - Make documentation updates a part of the development process.
   - Ensure that new features come with corresponding documentation.

6. **Regularly Update and Expand Docs**
   - Schedule periodic reviews of documentation to keep it up-to-date.
   - Expand documentation as the project grows and new features are added.

## Conclusion

Effective documentation and streamlined onboarding are crucial for the project's success, especially as the team expands. By maintaining comprehensive, accessible, and up-to-date documentation, we ensure that all team members can collaborate efficiently, contribute effectively, and uphold the platform's quality standards.

---

=== File: docs/issues/issue_9.md ===



==
issue_9
==


# State Recovery & Persistence

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread State Management](issue_5.md)
- Related to: [Coordinator Message Flow](issue_3.md)
- Critical for: Chorus Cycle coherence

## Description
Implement state recovery and persistence to maintain Chorus cycle coherence across app lifecycle events (termination, suspension, memory pressure). This isn't just about convenience - it's about preserving the integrity of the cycle's context and phase state.

## Core Requirements
1. Phase State Preservation
   - Save current phase (AEIOU-Y)
   - Preserve phase-specific context
   - Enable clean phase resumption
   - Maintain cycle coherence

2. Thread Context Continuity
   - Save full conversation context
   - Preserve message relationships
   - Maintain semantic connections
   - Enable coherent continuation

3. Cycle Integrity
   - Handle interruptions gracefully
   - Preserve cycle momentum
   - Maintain context relevance
   - Enable natural resumption

## Context Management & Summarization

1. Progressive Summarization
```swift
actor ContextManager {
    // Maintain sliding window of full context
    private var recentMessages: [MessagePoint]
    // Keep compressed summaries of older context
    private var historicalSummaries: [ContextSummary]

    struct ContextSummary: Codable {
        let timespan: DateInterval
        let keyPoints: [String]
        let semanticMarkers: [String: Float]
        let threadState: ThreadStateSnapshot

        // Link to full context if needed
        let archiveReference: String
    }

    func updateContext(_ newMessage: MessagePoint) async throws {
        // Add to recent messages
        recentMessages.append(newMessage)

        // Check if we need to summarize older messages
        if recentMessages.count > Constants.maxRecentMessages {
            try await compressOlderContext()
        }
    }

    private func compressOlderContext() async throws {
        let toCompress = recentMessages.prefix(Constants.compressionBatchSize)

        // Generate summary using AI
        let summary = try await generateContextSummary(toCompress)

        // Archive full messages for potential recovery
        try await archiveMessages(toCompress)

        // Update state
        historicalSummaries.append(summary)
        recentMessages.removeFirst(Constants.compressionBatchSize)
    }
}
```

2. Context Recovery
```swift
extension ContextManager {
    func recoverContext() async throws -> ThreadContext {
        // Start with recent messages
        var context = ThreadContext(messages: recentMessages)

        // Add relevant summaries
        for summary in historicalSummaries.reversed() {
            if await isRelevantToCurrentPhase(summary) {
                context.addSummary(summary)
            }

            // Stop if we have enough context
            if await context.isSufficient {
                break
            }
        }

        // If needed, fetch archived messages
        if !context.isSufficient {
            try await expandContext(context)
        }

        return context
    }

    private func expandContext(_ context: ThreadContext) async throws {
        // Identify gaps that need expansion
        let gaps = await context.findContextGaps()

        // Fetch archived messages for important gaps
        for gap in gaps {
            if await isGapCritical(gap) {
                let archived = try await fetchArchivedMessages(for: gap)
                context.fillGap(gap, with: archived)
            }
        }
    }
}
```

3. Semantic Continuity
```swift
struct SemanticMarker: Codable {
    let concept: String
    let strength: Float
    let firstMention: Date
    let recentMentions: [Date]

    var isActive: Bool {
        // Check if concept is still relevant
        Date().timeIntervalSince(recentMentions.last ?? firstMention) < Constants.conceptTimeout
    }
}

extension ContextManager {
    func maintainSemanticContinuity() async throws {
        // Track key concepts through summarization
        var activeMarkers = [SemanticMarker]()

        for message in recentMessages {
            let concepts = try await extractConcepts(from: message)
            try await updateMarkers(activeMarkers, with: concepts)
        }

        // Ensure summaries preserve important markers
        for marker in activeMarkers where marker.isActive {
            try await ensureMarkerPreserved(marker)
        }
    }
}
```

## Tasks
- [ ] Implement phase state persistence
  ```swift
  struct PhaseState: Codable {
      let phase: Phase
      let context: [MessagePoint]
      let intermediateResults: [String: Any]
      let timestamp: Date

      // Recovery metadata
      let cycleId: UUID
      let continuityMarkers: [String: String]
  }
  ```

- [ ] Add thread state recovery
  ```swift
  actor ThreadRecovery {
      func saveState(_ thread: Thread) async throws {
          let state = ThreadState(
              messages: thread.messages,
              currentPhase: thread.currentPhase,
              phaseState: thread.phaseState,
              contextualLinks: thread.contextualLinks
          )
          try await persistState(state)
      }

      func recoverThread(_ id: ThreadID) async throws -> Thread {
          guard let state = try await loadState(id) else {
              throw RecoveryError.stateNotFound
          }
          return try await rebuildThread(from: state)
      }
  }
  ```

- [ ] Implement cycle recovery logic
  ```swift
  extension ChorusCoordinator {
      func recoverCycle() async throws {
          let state = try await loadPhaseState()

          // Validate cycle integrity
          guard await validateCycleCoherence(state) else {
              throw CycleError.coherenceLost
          }

          // Restore phase context
          currentPhase = state.phase
          phaseContext = state.context

          // Resume cycle
          try await resumeCycle(from: state)
      }
  }
  ```

## Testing Requirements
1. Cycle Coherence
   - Test interruption at each phase
   - Verify context preservation
   - Check semantic continuity
   - Validate cycle resumption

2. State Recovery
   - Test app termination scenarios
   - Verify memory pressure handling
   - Check background task completion
   - Validate state reconstruction

3. User Experience
   - Verify seamless resumption
   - Test context continuity
   - Check interaction flow
   - Validate recovery UX

4. Context Management
   - Test progressive summarization
   - Verify semantic preservation
   - Check marker continuity
   - Validate context recovery
   - Test gap identification and filling

5. Summary Quality
   - Verify information preservation
   - Test semantic marker tracking
   - Check summary relevance
   - Validate compression ratios
   - Test recovery from summaries

## Success Criteria
- Maintains cycle coherence across interruptions
- Preserves semantic context
- Enables natural conversation flow
- Handles lifecycle events gracefully
- Provides seamless user experience
- Maintains semantic continuity through summarization
- Efficiently manages context depth vs. breadth
- Preserves critical information in summaries
- Enables smart context recovery
- Handles context gaps gracefully

## Code Examples
```swift
actor StateManager {
    func saveState() async throws {
        let state = AppState(
            currentThread: currentThread,
            currentMessage: currentMessage,
            phaseResults: phaseResults
        )
        try await persistState(state)
    }

    func recoverState() async throws {
        guard let state = try await loadPersistedState() else {
            return
        }
        // Restore state...
    }
}
