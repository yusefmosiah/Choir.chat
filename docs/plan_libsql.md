# libSQL Integration Plan for Choir

## Overview

This document outlines the implementation plan for integrating libSQL/Turso as the local persistence layer for the Choir application. This system will provide both offline functionality and synchronization with our global vector database infrastructure, while supporting the FQAHO model parameters and Post Chain architecture.

## Core Objectives

1. Implement libSQL as the primary local persistence solution
2. Design a flexible schema that can accommodate evolving data models
3. Implement vector search capabilities to support semantic matching in the Experience phase
4. Create a synchronization system between local and global databases
5. Support the FQAHO model parameters (α, K₀, m) in the database schema
6. Enable offline functionality with seamless online synchronization

## Implementation Philosophy

Our approach to database implementation will be guided by these principles:

1. **Core System First** - Focus on getting the core UX and system operational before fully committing to a database schema
2. **Flexibility** - Design the database to be adaptable as our data model evolves
3. **Incremental Implementation** - Add database features in phases, starting with the most essential components
4. **Performance** - Optimize for mobile device constraints and offline-first operation

## Technical Implementation

### 1. Database Setup and Initialization

```swift
import Libsql

class DatabaseService {
    static let shared = try! DatabaseService()

    private let database: Database
    private let connection: Connection

    private init() throws {
        // Get path to document directory for local database
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = documentsDirectory.appendingPathComponent("choir.db").path

        // Initialize database with sync capabilities
        self.database = try Database(
            path: dbPath,
            url: Environment.tursoDbUrl,      // Remote database URL
            authToken: Environment.tursoToken, // Authentication token
            syncInterval: 10000               // Sync every 10 seconds
        )

        self.connection = try database.connect()

        // Initialize schema
        try setupSchema()
    }

    private func setupSchema() throws {
        try connection.execute("""
            -- Users table
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                name TEXT,
                last_active INTEGER
            );

            -- Threads table
            CREATE TABLE IF NOT EXISTS threads (
                id TEXT PRIMARY KEY,
                title TEXT,
                created_at INTEGER,
                updated_at INTEGER,
                k0 REAL,           -- FQAHO parameter K₀
                alpha REAL,        -- FQAHO parameter α (fractional)
                m REAL             -- FQAHO parameter m
            );

            -- Messages table with vector support
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                thread_id TEXT,
                user_id TEXT,
                content TEXT,
                embedding F32_BLOB(1536),  -- Vector embedding for semantic search
                phase TEXT,                -- Post Chain phase identifier
                created_at INTEGER,
                approval_status TEXT,      -- For approval/refusal statistics
                FOREIGN KEY(thread_id) REFERENCES threads(id),
                FOREIGN KEY(user_id) REFERENCES users(id)
            );

            -- Vector index for similarity search in Experience phase
            CREATE INDEX IF NOT EXISTS messages_embedding_idx
            ON messages(libsql_vector_idx(embedding));

            -- Parameter history for FQAHO model tracking
            CREATE TABLE IF NOT EXISTS parameter_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                thread_id TEXT,
                timestamp INTEGER,
                k0 REAL,
                alpha REAL,
                m REAL,
                event_type TEXT,  -- What caused the parameter change
                FOREIGN KEY(thread_id) REFERENCES threads(id)
            );
        """)
    }
}
```

### 2. Thread and Message Operations

```swift
extension DatabaseService {
    // MARK: - Thread Operations

    func createThread(id: String, title: String, k0: Double, alpha: Double, m: Double) throws {
        let now = Int(Date().timeIntervalSince1970)

        try connection.execute("""
            INSERT INTO threads (id, title, created_at, updated_at, k0, alpha, m)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, [id, title, now, now, k0, alpha, m])

        // Record initial parameters
        try connection.execute("""
            INSERT INTO parameter_history (thread_id, timestamp, k0, alpha, m, event_type)
            VALUES (?, ?, ?, ?, ?, ?)
        """, [id, now, k0, alpha, m, "thread_creation"])
    }

    func getThread(id: String) throws -> Thread? {
        let results = try connection.query(
            "SELECT * FROM threads WHERE id = ?",
            [id]
        )

        guard let result = results.first else { return nil }

        return Thread(
            id: result["id"] as! String,
            title: result["title"] as! String,
            createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(result["updated_at"] as! Int)),
            k0: result["k0"] as! Double,
            alpha: result["alpha"] as! Double,
            m: result["m"] as! Double
        )
    }

    func updateThreadParameters(threadId: String, k0: Double, alpha: Double, m: Double, eventType: String) throws {
        let now = Int(Date().timeIntervalSince1970)

        // Update thread
        try connection.execute("""
            UPDATE threads
            SET k0 = ?, alpha = ?, m = ?, updated_at = ?
            WHERE id = ?
        """, [k0, alpha, m, now, threadId])

        // Record parameter change
        try connection.execute("""
            INSERT INTO parameter_history (thread_id, timestamp, k0, alpha, m, event_type)
            VALUES (?, ?, ?, ?, ?, ?)
        """, [threadId, now, k0, alpha, m, eventType])
    }

    // MARK: - Message Operations

    func createMessage(id: String, threadId: String, userId: String, content: String,
                       embedding: [Float], phase: String) throws {
        let now = Int(Date().timeIntervalSince1970)
        let vectorString = "vector32('\(embedding)')"

        try connection.execute("""
            INSERT INTO messages (id, thread_id, user_id, content, embedding, phase, created_at, approval_status)
            VALUES (?, ?, ?, ?, \(vectorString), ?, ?, 'pending')
        """, [id, threadId, userId, content, phase, now])

        // Update thread's last activity
        try connection.execute("""
            UPDATE threads
            SET updated_at = ?
            WHERE id = ?
        """, [now, threadId])
    }

    func updateMessageApprovalStatus(messageId: String, status: String) throws {
        try connection.execute("""
            UPDATE messages
            SET approval_status = ?
            WHERE id = ?
        """, [status, messageId])

        // If we wanted to update FQAHO parameters based on approval/refusal, we could do that here
        if let message = try getMessage(id: messageId),
           let thread = try getThread(id: message.threadId) {

            // Calculate new parameters based on approval/refusal
            let newK0 = calculateNewK0(currentK0: thread.k0, approvalStatus: status)
            let newAlpha = calculateNewAlpha(currentAlpha: thread.alpha, approvalStatus: status)
            let newM = calculateNewM(currentM: thread.m, approvalStatus: status)

            try updateThreadParameters(
                threadId: message.threadId,
                k0: newK0,
                alpha: newAlpha,
                m: newM,
                eventType: "message_\(status)"
            )
        }
    }

    func getMessage(id: String) throws -> Message? {
        let results = try connection.query(
            "SELECT * FROM messages WHERE id = ?",
            [id]
        )

        guard let result = results.first else { return nil }

        return Message(
            id: result["id"] as! String,
            threadId: result["thread_id"] as! String,
            userId: result["user_id"] as! String,
            content: result["content"] as! String,
            phase: result["phase"] as! String,
            createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
            approvalStatus: result["approval_status"] as! String
        )
    }
}
```

### 3. Vector Search for Experience Phase

```swift
extension DatabaseService {
    // Find semantically similar messages for the Experience phase
    func findSimilarExperiences(threadId: String, queryEmbedding: [Float], limit: Int = 5) throws -> [Message] {
        let vectorString = "vector32('\(queryEmbedding)')"

        let results = try connection.query("""
            SELECT m.*
            FROM vector_top_k('messages_embedding_idx', \(vectorString), ?) as v
            JOIN messages m ON m.rowid = v.id
            WHERE m.thread_id = ?
            AND m.approval_status = 'approved'
        """, [limit, threadId])

        return results.map { result in
            Message(
                id: result["id"] as! String,
                threadId: result["thread_id"] as! String,
                userId: result["user_id"] as! String,
                content: result["content"] as! String,
                phase: result["phase"] as! String,
                createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
                approvalStatus: result["approval_status"] as! String
            )
        }
    }

    // Get experiences with prior parameter values (for display in Experience step)
    func getExperiencesWithPriors(threadId: String, limit: Int = 10) throws -> [(Message, ParameterSet)] {
        let results = try connection.query("""
            SELECT m.*, p.k0, p.alpha, p.m
            FROM messages m
            JOIN parameter_history p ON
                m.thread_id = p.thread_id AND
                m.created_at >= p.timestamp
            WHERE m.thread_id = ?
            AND m.phase = 'experience'
            ORDER BY m.created_at DESC
            LIMIT ?
        """, [threadId, limit])

        return results.map { result in
            let message = Message(
                id: result["id"] as! String,
                threadId: result["thread_id"] as! String,
                userId: result["user_id"] as! String,
                content: result["content"] as! String,
                phase: result["phase"] as! String,
                createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
                approvalStatus: result["approval_status"] as! String
            )

            let parameters = ParameterSet(
                k0: result["k0"] as! Double,
                alpha: result["alpha"] as! Double,
                m: result["m"] as! Double
            )

            return (message, parameters)
        }
    }
}
```

### 4. Synchronization Management

```swift
extension DatabaseService {
    // Trigger manual sync with remote database
    func syncWithRemote() throws {
        try database.sync()
    }

    // Check if a sync is needed
    var needsSync: Bool {
        // Implementation depends on how we track local changes
        // Could check for pending operations or time since last sync
        return true
    }

    // Handle network status changes
    func handleNetworkStatusChange(isOnline: Bool) {
        if isOnline && needsSync {
            do {
                try syncWithRemote()
            } catch {
                print("Sync error: \(error)")
                // Handle sync failure
            }
        }
    }
}
```

### 5. FQAHO Parameter Calculation Functions

```swift
extension DatabaseService {
    // Calculate new K₀ value based on approval/refusal
    private func calculateNewK0(currentK0: Double, approvalStatus: String) -> Double {
        // Implementation of FQAHO model K₀ adjustment
        let adjustment: Double = approvalStatus == "approved" ? 0.05 : -0.08
        return max(0.1, min(10.0, currentK0 + adjustment))
    }

    // Calculate new α value based on approval/refusal
    private func calculateNewAlpha(currentAlpha: Double, approvalStatus: String) -> Double {
        // Implementation of FQAHO model α adjustment
        // Fractional parameter capturing memory effects
        let adjustment: Double = approvalStatus == "approved" ? 0.02 : -0.03
        return max(0.1, min(2.0, currentAlpha + adjustment))
    }

    // Calculate new m value based on approval/refusal
    private func calculateNewM(currentM: Double, approvalStatus: String) -> Double {
        // Implementation of FQAHO model m adjustment
        let adjustment: Double = approvalStatus == "approved" ? -0.01 : 0.02
        return max(0.5, min(5.0, currentM + adjustment))
    }
}
```

## Phased Implementation Approach

Given that UX has more pressing issues and the data model is still evolving, we'll adopt a phased approach to database implementation:

### Phase 1: Core UX Development (Current Focus)

- Continue developing the core UI and interaction flow
- Prioritize UX improvements over database implementation
- Use in-memory or mock data for testing

### Phase 2: Schema Development and Validation

- Finalize initial schema design as the core system stabilizes
- Create prototypes to validate the schema with real usage patterns
- Ensure the schema can adapt to evolving requirements

### Phase 3: Basic Database Implementation

- Implement basic CRUD operations for threads and messages
- Set up the database connection and initialization
- Create simplified data services for the UI to consume

### Phase 4: Vector Search Implementation

- Add vector embedding storage and search
- Connect the Experience phase to vector similarity search
- Optimize for performance and memory usage

### Phase 5: FQAHO Parameter Support

- Implement parameter storage and history tracking
- Add parameter calculation algorithms
- Connect parameter adjustments to the UI

### Phase 6: Synchronization

- Configure embedded replicas
- Implement sync management
- Handle offline/online transitions

## Integration with Post Chain Phases

The libSQL implementation will support all phases of the Post Chain:

1. **Action** - Store user messages and initial parameters
2. **Experience** - Use vector search to find relevant prior experiences
3. **Understanding** - Track message reactions and parameter adjustments
4. **Web Search** - Store search results with vector embeddings for future reference
5. **Tool Use** - Record tool usage patterns and outcomes

## Flexible Schema Design Principles

Since the data model is still evolving, the database schema should follow these principles:

1. **Versioned Schema** - Include version markers in the schema to facilitate future migrations
2. **Nullable Fields** - Use nullable fields where appropriate to accommodate evolving requirements
3. **Isolated Tables** - Keep related concepts in separate tables to minimize the impact of changes
4. **Extensible Records** - Consider using a JSON or blob field for attributes that might change frequently
5. **Minimal Dependencies** - Limit foreign key constraints to essential relationships

## Future Considerations

1. **Multi-device Sync**

   - Ensure consistent user experience across devices
   - Handle conflict resolution

2. **Advanced Vector Quantization**

   - Implement quantization for more efficient storage
   - Optimize for mobile device constraints

3. **Partitioned User Databases**

   - Implement per-user database isolation
   - Support multi-tenancy within the app

4. **Backup and Recovery**

   - Implement regular backup mechanisms
   - Create recovery procedures

5. **Extensions for Multimodal Support**
   - Extend schema for image and audio data
   - Implement multimodal vector embeddings

## Resources

- [Turso Swift Documentation](https://docs.turso.tech/swift)
- [libSQL Swift GitHub Repository](https://github.com/tursodatabase/libsql-swift)
- [Embedded Replicas Documentation](https://docs.turso.tech/embedded-replicas)
- [Vector Search Documentation](https://docs.turso.tech/vector-search)
