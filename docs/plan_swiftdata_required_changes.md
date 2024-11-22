# SwiftData Implementation Plan for Choir

## Current State
- Working REST API integration
- Functional wallet management
- In-memory message handling
- Chorus cycle visualization

## Notes from Current Implementation

### API Integration Patterns
- REST coordinator successfully handles phased responses
- Each phase (action, experience, etc.) has distinct response types
- Need to preserve phase-specific data in SwiftData models

### Wallet Integration Learnings
```swift
// Example of how wallet and user data should sync
class CHUser {
    var walletAddress: String
    var lastKnownBalance: Double?
    var lastBalanceUpdate: Date?
    var transactionHistory: [CHTransaction]? // Consider adding
}
```

### Chorus Result Structure
- Current implementation tracks phases separately
- Need to maintain phase order and relationships
- Consider structured storage for phase-specific data:
```swift
@Model
class CHChorusResult {
    // Each phase needs specific fields
    var experiencePhase: CHPhase? {
        // Experience phase needs priors
        didSet { updatePriorReferences() }
    }
    var intentionPhase: CHPhase? {
        // Intention phase needs selected priors
        didSet { updateSelectedPriors() }
    }
}
```

### Performance Considerations
- Docker deployment shows importance of caching
- Apply similar caching strategy to SwiftData queries
- Consider batch loading for message history
- Implement lazy loading for chorus results

### Error Handling Patterns
- Current REST implementation has robust error handling
- Need similar error handling for data persistence
- Consider adding retry logic for failed saves
- Track data consistency across models

### Migration Requirements
- Need to preserve existing message history
- Maintain chorus phase relationships
- Keep wallet state synchronized
- Consider incremental migration strategy

### Testing Focus Areas
1. Phase Data Integrity
   - Verify all chorus phases are preserved
   - Test phase relationship consistency
   - Validate prior references

2. Wallet Integration
   - Test balance updates
   - Verify transaction history
   - Ensure address consistency

3. Performance Metrics
   - Message loading times
   - Thread switching speed
   - Memory usage patterns

4. Error Recovery
   - Network failure handling
   - Data consistency checks
   - Wallet state recovery

Remember: The current REST and wallet implementations are working well - maintain their functionality while adding persistence.

## Chunk 1: Core Models & Migration Setup

### Models
```swift
@Model
class CHUser {
    var id: UUID
    var walletAddress: String
    var threads: [CHThread]
    var createdAt: Date

    // Wallet integration
    var lastKnownBalance: Double?
    var lastBalanceUpdate: Date?
}

@Model
class CHThread {
    var id: UUID
    var title: String
    var messages: [CHMessage]
    var owner: CHUser?
    var createdAt: Date
    var lastActivity: Date
}

@Model
class CHMessage {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var thread: CHThread?
    var chorusResult: CHChorusResult?
}

@Model
class CHChorusResult {
    var id: UUID
    var message: CHMessage?
    var phases: [String: String] // Store as JSON or structured data
    var confidence: Double
    var timestamp: Date
}
```

### Migration Strategy
1. Create temporary storage for current messages
2. Initialize SwiftData container
3. Migrate existing data
4. Validate persistence

## Chunk 2: ViewModel Updates

### ThreadListViewModel
```swift
@MainActor
class ThreadListViewModel: ObservableObject {
    @Query private var threads: [CHThread]
    private let modelContext: ModelContext

    // CRUD operations
    func createThread() -> CHThread
    func deleteThread(_ thread: CHThread)
    func loadThreads() async
}
```

### ThreadDetailViewModel
```swift
@MainActor
class ThreadDetailViewModel: ObservableObject {
    private let thread: CHThread
    private let modelContext: ModelContext
    private let chorusCoordinator: ChorusCoordinator

    // Message handling
    func sendMessage(_ content: String) async
    func processAIResponse(_ response: ChorusResponse)
}
```

## Chunk 3: View Updates

1. Update ContentView
   - Replace @State threads with @Query
   - Inject ThreadListViewModel

2. Update ThreadDetailView
   - Use ThreadDetailViewModel
   - Maintain Chorus cycle visualization
   - Add persistence for message states

3. Update MessageRow
   - Support CHMessage model
   - Keep existing UI components

## Chunk 4: Wallet Integration

1. Link WalletManager with CHUser
2. Persist wallet state
3. Update balance tracking
4. Add transaction history

## Chunk 5: Testing & Refinement

1. Migration Testing
   - Test data preservation
   - Verify relationships

2. Performance Testing
   - Message loading
   - Thread switching
   - Memory usage

3. Error Handling
   - Data consistency
   - Network failures
   - Wallet operations



——

@Model
class CHChorusResult {
    var id: UUID
    var message: CHMessage?
    var timestamp: Date

    // Store phases as structured data instead of [String: String]
    var actionPhase: CHPhase?
    var experiencePhase: CHPhase?
    var intentionPhase: CHPhase?
    var observationPhase: CHPhase?
    var understandingPhase: CHPhase?
    var yieldPhase: CHPhase?

    // Track overall metrics
    var overallConfidence: Double
    var processingDuration: TimeInterval?
}

@Model
class CHPhase {
    var id: UUID
    var type: String  // "action", "experience", etc.
    var content: String
    var confidence: Double
    var reasoning: String?
    var timestamp: Date

    // For experience phase
    var priors: [CHPrior]?

    // For understanding phase
    var shouldYield: Bool?
    var nextPrompt: String?
}

@Model
class CHPrior {
    var id: UUID
    var content: String
    var similarity: Double
    var sourceMessage: CHMessage?
    var sourceThread: CHThread?
}


——

@MainActor
class ThreadDetailViewModel: ObservableObject {
    private let thread: CHThread
    private let modelContext: ModelContext
    private let chorusCoordinator: ChorusCoordinator

    @Published private(set) var messages: [CHMessage] = []
    @Published private(set) var isProcessing = false
    @Published var error: Error?

    init(thread: CHThread, modelContext: ModelContext) {
        self.thread = thread
        self.modelContext = modelContext
        self.chorusCoordinator = RESTChorusCoordinator()
    }

    func sendMessage(_ content: String) async {
        do {
            // Create and save user message
            let userMessage = CHMessage(
                id: UUID(),
                content: content,
                isUser: true,
                timestamp: Date(),
                thread: thread
            )
            modelContext.insert(userMessage)
            try modelContext.save()

            // Create placeholder AI message
            let aiMessage = CHMessage(
                id: UUID(),
                content: "...",
                isUser: false,
                timestamp: Date(),
                thread: thread
            )
            modelContext.insert(aiMessage)
            try modelContext.save()

            // Process with Chorus
            try await processAIResponse(userMessage: userMessage, aiMessage: aiMessage)

        } catch {
            self.error = error
        }
    }

    private func processAIResponse(userMessage: CHMessage, aiMessage: CHMessage) async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Start processing with coordinator
        try await chorusCoordinator.process(userMessage.content)

        // Create ChorusResult
        let chorusResult = CHChorusResult(
            id: UUID(),
            message: aiMessage,
            timestamp: Date()
        )

        // Add phases
        if let actionResponse = chorusCoordinator.actionResponse {
            chorusResult.actionPhase = CHPhase(
                id: UUID(),
                type: "action",
                content: actionResponse.content,
                confidence: actionResponse.confidence,
                reasoning: actionResponse.reasoning,
                timestamp: Date()
            )
        }

        // Add other phases similarly...

        // Update AI message
        aiMessage.content = chorusCoordinator.yieldResponse?.content ?? "Error processing response"
        aiMessage.chorusResult = chorusResult

        try modelContext.save()
    }
}

—

extension WalletManager {
    func syncWithUser() async throws {
        guard let wallet = self.wallet else { return }

        let address = try wallet.accounts[0].address()

        // Find or create user
        let fetchDescriptor = FetchDescriptor<CHUser>(
            predicate: #Predicate<CHUser> { user in
                user.walletAddress == address
            }
        )

        let existingUser = try modelContext.fetch(fetchDescriptor).first

        let user = existingUser ?? CHUser(
            id: UUID(),
            walletAddress: address,
            createdAt: Date()
        )

        // Update balance
        user.lastKnownBalance = self.balance
        user.lastBalanceUpdate = Date()

        if existingUser == nil {
            modelContext.insert(user)
        }

        try modelContext.save()
    }
}

—

class DataMigrationManager {
    static func migrateExistingData(
        from oldThreads: [ChoirThread],
        to context: ModelContext
    ) async throws {
        for oldThread in oldThreads {
            // Create new thread
            let newThread = CHThread(
                id: oldThread.id,
                title: oldThread.title,
                createdAt: Date()
            )

            context.insert(newThread)

            // Migrate messages
            for oldMessage in oldThread.messages {
                let newMessage = CHMessage(
                    id: oldMessage.id,
                    content: oldMessage.content,
                    isUser: oldMessage.isUser,
                    timestamp: oldMessage.timestamp,
                    thread: newThread
                )

                // Migrate chorus result if exists
                if let oldChorusResult = oldMessage.chorusResult {
                    let newChorusResult = CHChorusResult(
                        id: UUID(),
                        message: newMessage,
                        timestamp: oldMessage.timestamp
                    )

                    // Migrate phases
                    for (phase, content) in oldChorusResult.phases {
                        let newPhase = CHPhase(
                            id: UUID(),
                            type: phase.rawValue,
                            content: content,
                            confidence: 1.0, // Default if not available
                            timestamp: oldMessage.timestamp
                        )

                        // Assign to appropriate phase property
                        switch phase {
                        case .action: newChorusResult.actionPhase = newPhase
                        case .experience: newChorusResult.experiencePhase = newPhase
                        // ... other phases
                        }
                    }

                    newMessage.chorusResult = newChorusResult
                }

                context.insert(newMessage)
            }
        }

        try context.save()
    }
}
