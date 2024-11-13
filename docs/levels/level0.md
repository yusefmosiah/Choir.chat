# Level 0 Documentation



=== File: docs/issues/issue_-1.md ===



==
issue_-1
==


# Development Environment Setup

## Description
Set up and configure development environment for efficient implementation of core message system.

## Tasks
- [ ] Configure test environment
  - [ ] Set up test database # the database we have is the test database. when ready to launch we will make new database
  - [ ] Configure test vectors
  - [ ] Add test users/threads
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


# Core Message System Implementation

## Overview
Implement the foundational message system that reconciles our Swift types with Qdrant storage, enables user identity, and manages thread state. Focus on clean type system that supports existing ~20k message points while enabling future features.

## Sub-Issues
1. [Message Type Reconciliation](issue_1.md) - Reconcile ChorusModels with Qdrant
2. [API Client Message Handling](issue_2.md) - Update client for new types
3. [Coordinator Message Flow](issue_3.md) - Handle message lifecycle
4. [User Identity Implementation](issue_4.md) - Basic key management
5. [Thread State Management](issue_5.md) - Local state with sync
6. [Integration Testing Suite](issue_6.md) - End-to-end validation

## Dependencies
- Existing Qdrant setup (~20k message points)
- Current `ChorusModels.swift` with response types
- Python API endpoints
- Working collections (messages, users, threads)

## Architecture Decisions
1. Message Storage
   - Points stored in Qdrant with vectors
   - Full message history in payload
   - Support for legacy points

2. State Management
   - Local thread state in Swift
   - Sync with Qdrant as source of truth
   - Clean type conversion

3. Identity System
   - Public keys as user IDs
   - UserDefaults for development
   - Simple key management

4. API Design
   - Stateless endpoints
   - Type-safe requests/responses
   - Graceful error handling

## Success Metrics
1. Type System
   - Clean conversion between Swift/Qdrant
   - Support for legacy points
   - Type-safe operations

2. Message Flow
   - Reliable message handling
   - Proper state management
   - Error resilience

3. Testing
   - Comprehensive test suite
   - Performance validation
   - Error scenario coverage

=== File: docs/issues/issue_1.md ===



==
issue_1
==


# Message Type Reconciliation

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: None
- Blocks: [API Client Message Handling](issue_2.md)
- Related to: [Coordinator Message Flow](issue_3.md)

## Description
Reconcile existing `ChorusModels.swift` response types with Qdrant schema, ensuring backward compatibility with ~20k existing message points while enabling future features.

## Current State
- Have `ChorusModels.swift` with:
  - Base response types
  - Phase-specific responses
  - Supporting types (Prior, Pattern)
- ~20k points in Qdrant
- Need unified message type system

## Tasks
- [ ] Create `MessagePoint` struct matching Qdrant schema
  - [ ] Support all required fields
  - [ ] Handle optional fields
  - [ ] Add chorus result support
- [ ] Implement `ThreadMessage` for UI state
  - [ ] Convert from MessagePoint
  - [ ] Handle UI-specific state
- [ ] Add graceful decoding for legacy points
  - [ ] Default values for missing fields
  - [ ] Validation logic
- [ ] Add conversion tests
  - [ ] Legacy point handling
  - [ ] Full message conversion
  - [ ] Error cases

## Code Examples
```swift
// Message point matching Qdrant schema
struct MessagePoint: Codable {
    let id: String
    let content: String
    let threadId: String
    let createdAt: String
    let role: String?
    let step: String?
    let chorusResult: ChorusCycleResult?

    // Graceful decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        threadId = try container.decode(String.self, forKey: .threadId)
        createdAt = try container.decode(String.self, forKey: .createdAt)

        // Optional fields with empty defaults
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? ""
        step = try container.decodeIfPresent(String.self, forKey: .step) ?? ""
        chorusResult = try container.decodeIfPresent(ChorusCycleResult.self, forKey: .chorusResult)
    }
}
```

## Testing Requirements
- Test decoding of legacy points
  - Missing optional fields
  - Different date formats
  - Invalid data
- Verify conversion to ThreadMessage
  - All fields mapped correctly
  - UI state initialized properly
- Validate chorus result handling
  - All phase responses
  - Missing phases
  - Invalid data

## Success Criteria
- Clean type conversion
- Backward compatibility
- Comprehensive test coverage
- Clear error handling

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


# Coordinator Message Flow

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [API Client Message Handling](issue_2.md)
- Blocks: [Thread State Management](issue_5.md)
- Related to: [Message Type Reconciliation](issue_1.md)

## Description
Update RESTChorusCoordinator to handle the complete message lifecycle using the new unified type system while maintaining compatibility with the existing chorus cycle phases.

## Current State
- Have working RESTChorusCoordinator
- Using phase-specific response types
- Need to integrate MessagePoint/ThreadMessage
- Need to maintain phase results

## Tasks
- [ ] Update coordinator state
  - [ ] Add MessagePoint handling
  - [ ] Manage ThreadMessage state
  - [ ] Track phase results
- [ ] Implement message lifecycle
  - [ ] Initial message creation
  - [ ] Phase processing
  - [ ] Result accumulation
  - [ ] Final state updates
- [ ] Add thread integration
  - [ ] Thread state updates
  - [ ] Message synchronization
  - [ ] History management
- [ ] Handle errors and cancellation
  - [ ] Phase-specific errors
  - [ ] State cleanup
  - [ ] Graceful cancellation

## Code Examples
```swift
@MainActor
class RESTChorusCoordinator: ChorusCoordinator {
    // State management
    private(set) var currentMessage: ThreadMessage?
    private(set) var currentPhase: Phase = .action
    private(set) var phaseResults: [Phase: BaseResponse] = [:]

    // Process message through phases
    func process(_ input: String) async throws {
        // Create initial message
        let messagePoint = MessagePoint(
            id: UUID().uuidString,
            content: input,
            threadId: threadId,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            role: "user",
            step: Phase.action.rawValue
        )

        // Process through phases
        currentMessage = ThreadMessage(from: messagePoint)

        do {
            // Action phase
            currentPhase = .action
            let actionResponse = try await processAction(input)
            phaseResults[.action] = actionResponse

            // Experience phase with context
            currentPhase = .experience
            let experienceResponse = try await processExperience(
                input,
                context: currentMessage
            )
            phaseResults[.experience] = experienceResponse

            // Continue through phases...

            // Update final state
            currentMessage?.chorusResult = ChorusCycleResult(
                action: phaseResults[.action] as? ActionResponse,
                experience: phaseResults[.experience] as? ExperienceResponseData,
                // ... other phases
            )

            // Store final message
            try await api.storeMessage(messagePoint)

        } catch {
            // Handle errors while maintaining state consistency
            phaseResults[currentPhase] = BaseResponse(
                step: currentPhase.rawValue,
                content: "Error: \(error.localizedDescription)",
                confidence: 0.0,
                reasoning: "Phase failed"
            )
            throw error
        }
    }

    // Support cancellation
    func cancel() {
        // Cleanup state
        currentPhase = .action
        phaseResults.removeAll()
    }
}
```

## Testing Requirements
- Test phase progression
  - State transitions
  - Result accumulation
  - Error handling
- Verify message lifecycle
  - Creation
  - Processing
  - Storage
- Test cancellation
  - State cleanup
  - Resource release
  - Error propagation

## Success Criteria
- Clean state transitions
- Proper error handling
- Type-safe operations
- Reliable cancellation

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


# Performance Monitoring

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: Basic implementation issues
- Related to: [Integration Testing Suite](issue_6.md)

## Description
Add performance monitoring and metrics collection to track system behavior with real usage.

## Tasks
- [ ] Add timing metrics
- [ ] Track memory usage
- [ ] Monitor API latency
- [ ] Implement performance tests

## Code Examples
```swift
actor PerformanceMonitor {
    private var metrics: [String: TimeInterval] = [:]

    func track<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - start

        await update(operation, duration)
        return result
    }
}

=== File: docs/issues/issue_9.md ===



==
issue_9
==


# State Recovery & Persistence

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread State Management](issue_5.md)
- Related to: [User Identity Implementation](issue_4.md)

## Description
Implement state recovery and persistence strategies to handle app termination, crashes, and background state.

## Tasks
- [ ] Add state persistence
- [ ] Implement recovery logic
- [ ] Handle background tasks
- [ ] Add migration support

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
