# SwiftData Implementation Plan for Choir

## Current State
- Working REST API integration
- Functional wallet management
- In-memory message handling
- Chorus cycle visualization

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
