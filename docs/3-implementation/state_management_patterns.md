# State Management Patterns in the Actor Model

This document provides a comprehensive guide to managing state in Choir's actor-based architecture, outlining patterns and best practices for state encapsulation, persistence, and evolution.

## Fundamental Principles

The actor model's approach to state management is based on several key principles:

1. **Strict Encapsulation**: Each actor owns and manages its state exclusively
2. **Message-Based Mutation**: State changes occur only in response to messages
3. **Isolated Persistence**: Actors are responsible for persisting their own state
4. **Resilient Recovery**: Actors can recover their state after failures
5. **Consistent Serialization**: State must be serializable for persistence and recovery

These principles create a robust foundation for managing complex application state across distributed systems.

## Actor State Structure

### Base State Class

All actor states in Choir extend from a common base class that provides core functionality:

```python
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from datetime import datetime
import uuid

class ActorState(BaseModel):
    """Base class for all actor states"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    actor_type: str
    created_at: datetime = Field(default_factory=datetime.now)
    last_updated: datetime = Field(default_factory=datetime.now)
    version: int = 0
    metadata: Dict[str, Any] = Field(default_factory=dict)
```

### Specialized State Classes

Each actor type defines its own specialized state class that extends the base state:

```python
class ActionState(ActorState):
    """State for the Action actor"""
    messages: List[Dict[str, Any]] = Field(default_factory=list)
    current_input: Optional[str] = None

    class Config:
        """Pydantic configuration"""
        # Ensure all state mutations create copies rather than modifying in place
        frozen = False
        # Validate assignments to attributes
        validate_assignment = True

class ExperienceState(ActorState):
    """State for the Experience actor"""
    knowledge_base: List[Dict[str, Any]] = Field(default_factory=list)
    retrieved_context: List[Dict[str, Any]] = Field(default_factory=list)
    embedding_model: str = "text-embedding-3-small"
    retrieval_count: int = 5
```

## State Lifecycle Patterns

### 1. Initialization Pattern

Actors initialize their state either from a provided initial state or by creating a new state:

```python
class ExampleActor(Actor[ExampleState]):
    """Example actor implementation"""

    def __init__(self, name: str, initial_state: Optional[ExampleState] = None):
        """Initialize actor with optional initial state"""
        # Use provided state or create a new one
        state = initial_state or ExampleState(
            actor_type=self.__class__.__name__,
            metadata={"initialized_by": "system"}
        )
        super().__init__(name, state)
```

### 2. Immutable Update Pattern

For state updates, create new state instances rather than modifying existing state:

```python
async def process_message(self, message: Message) -> None:
    """Process a message and update state"""
    # Create a new state based on current state
    new_state = self.state.model_copy(deep=True)

    # Update the new state
    new_state.last_updated = datetime.now()
    new_state.version += 1

    # Add message to history
    new_state.messages.append({
        "id": message.id,
        "timestamp": message.created_at,
        "content": message.content
    })

    # Replace current state with new state
    self.state = new_state

    # Persist state
    await self.persist_state()
```

### 3. Persistence Pattern

States are persisted at key points in the actor lifecycle:

```python
async def persist_state(self) -> None:
    """Persist current state to storage"""
    if not self.state_manager:
        raise ValueError("No state manager configured")

    # Serialize state
    state_json = self.state.model_dump_json()

    # Store state with metadata
    await self.state_manager.save_state(
        actor_id=self.id,
        actor_type=self.__class__.__name__,
        state_json=state_json,
        version=self.state.version
    )
```

### 4. Recovery Pattern

Actors recover their state when restarted:

```python
@classmethod
async def create(cls, actor_id: str, state_manager: StateManager) -> 'Actor':
    """Create an actor, recovering state if available"""
    # Try to recover state
    state_json = await state_manager.load_state(actor_id)

    if state_json:
        # Deserialize and validate state
        try:
            state = cls.state_class.model_validate_json(state_json)
            actor = cls(actor_id, state)
        except ValidationError as e:
            logger.error(f"Failed to validate recovered state: {e}")
            # Fall back to new state
            actor = cls(actor_id)
    else:
        # Create with fresh state
        actor = cls(actor_id)

    actor.state_manager = state_manager
    return actor
```

## State Storage Patterns

### 1. libSQL/Turso Integration

Choir uses libSQL/Turso for state persistence with a schema optimized for actor state:

```python
class TursoStateManager(StateManager):
    """State manager implementation using libSQL/Turso"""

    async def __init__(self, connection_string: str):
        """Initialize with database connection"""
        self.db = await libsql_connect(connection_string)
        await self._ensure_schema()

    async def _ensure_schema(self):
        """Ensure the database schema exists"""
        await self.db.execute("""
            CREATE TABLE IF NOT EXISTS actor_states (
                actor_id TEXT PRIMARY KEY,
                actor_type TEXT NOT NULL,
                state_json TEXT NOT NULL,
                version INTEGER NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)

        await self.db.execute("""
            CREATE TABLE IF NOT EXISTS state_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                actor_id TEXT NOT NULL,
                state_json TEXT NOT NULL,
                version INTEGER NOT NULL,
                timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(actor_id) REFERENCES actor_states(actor_id)
            )
        """)

    async def save_state(self, actor_id: str, actor_type: str, state_json: str, version: int) -> None:
        """Save actor state to the database"""
        # Use upsert pattern for atomic updates
        await self.db.execute("""
            INSERT INTO actor_states (actor_id, actor_type, state_json, version, updated_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(actor_id) DO UPDATE SET
                state_json = excluded.state_json,
                version = excluded.version,
                updated_at = CURRENT_TIMESTAMP
                WHERE version < excluded.version
        """, (actor_id, actor_type, state_json, version))

        # Record state history
        await self.db.execute("""
            INSERT INTO state_history (actor_id, state_json, version)
            VALUES (?, ?, ?)
        """, (actor_id, state_json, version))
```

### 2. Vector Extension for Experience State

For actors like Experience that need semantic search capabilities:

```python
async def _ensure_schema(self):
    """Ensure the schema with vector support exists"""
    await super()._ensure_schema()

    # Add vector embeddings table
    await self.db.execute("""
        CREATE TABLE IF NOT EXISTS vector_embeddings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_id TEXT NOT NULL,
            content_id TEXT NOT NULL,
            embedding F32_BLOB(1536) NOT NULL,
            content TEXT NOT NULL,
            metadata TEXT,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(actor_id) REFERENCES actor_states(actor_id)
        )
    """)

    # Create vector index
    await self.db.execute("""
        CREATE INDEX IF NOT EXISTS idx_vector_embeddings
        ON vector_embeddings(libsql_vector_idx(embedding))
    """)
```

### 3. State Migration Pattern

As state schemas evolve, migration logic ensures compatibility:

```python
class StateMigrator:
    """Handles migration between state versions"""

    def __init__(self):
        """Initialize migrator with migration functions"""
        self.migrations = {
            # Map (from_version, to_version) to migration function
            (1, 2): self._migrate_v1_to_v2,
            (2, 3): self._migrate_v2_to_v3,
        }

    async def migrate(self, state_json: str, current_version: int, target_version: int) -> str:
        """Migrate state from current version to target version"""
        state_dict = json.loads(state_json)

        # Apply migrations sequentially
        version = current_version
        while version < target_version:
            migration_key = (version, version + 1)
            if migration_key not in self.migrations:
                raise ValueError(f"No migration path from version {version} to {version + 1}")

            # Apply migration
            state_dict = self.migrations[migration_key](state_dict)
            version += 1

        return json.dumps(state_dict)

    def _migrate_v1_to_v2(self, state_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Migrate from v1 to v2 schema"""
        # Example migration logic
        if "messages" in state_dict and isinstance(state_dict["messages"], list):
            # Add timestamp field to each message
            for message in state_dict["messages"]:
                if "timestamp" not in message:
                    message["timestamp"] = state_dict.get("last_updated")

        # Update version
        state_dict["version"] = 2
        return state_dict
```

## State Consistency Patterns

### 1. Versioned State Pattern

All state changes increment a version number to track state evolution:

```python
def update_state(self, update_func):
    """Update state using a function, incrementing version"""
    # Create a copy of current state
    new_state = self.state.model_copy(deep=True)

    # Apply update function to the new state
    update_func(new_state)

    # Update metadata
    new_state.version += 1
    new_state.last_updated = datetime.now()

    # Replace state
    self.state = new_state

    # Schedule persistence
    asyncio.create_task(self.persist_state())
```

### 2. Optimistic Concurrency Pattern

When multiple instances of an actor might exist (e.g., in a distributed system):

```python
async def persist_state(self) -> bool:
    """Persist state with optimistic concurrency control"""
    try:
        # Try to update with version constraint
        result = await self.state_manager.save_state_with_version(
            actor_id=self.id,
            state_json=self.state.model_dump_json(),
            expected_version=self.state.version - 1,  # Previous version
            new_version=self.state.version
        )

        if not result:
            # Version conflict - reload and retry
            await self.reload_state()
            return False

        return True
    except Exception as e:
        logger.error(f"Failed to persist state: {e}")
        return False
```

### 3. Event Sourcing Pattern

For critical actors, an event sourcing approach can be used:

```python
class EventSourcedActor(Actor[EventSourcedState]):
    """Actor that uses event sourcing for state management"""

    def __init__(self, name: str):
        """Initialize with empty state"""
        super().__init__(name, EventSourcedState(
            actor_type=self.__class__.__name__,
            events=[]
        ))

    async def apply_event(self, event: Dict[str, Any]) -> None:
        """Apply an event to the actor state"""
        # Add event to event list
        new_state = self.state.model_copy(deep=True)
        new_state.events.append(event)

        # Apply event to state
        self._apply_event_to_state(new_state, event)

        # Update version and timestamp
        new_state.version += 1
        new_state.last_updated = datetime.now()

        # Update state
        self.state = new_state

        # Persist event
        await self.event_store.append_event(self.id, event)

    @classmethod
    async def create(cls, actor_id: str, event_store: EventStore) -> 'EventSourcedActor':
        """Create actor by replaying events"""
        actor = cls(actor_id)
        actor.event_store = event_store

        # Replay all events
        events = await event_store.get_events(actor_id)
        for event in events:
            actor._apply_event_to_state(actor.state, event)
            actor.state.events.append(event)
            actor.state.version += 1

        if events:
            actor.state.last_updated = datetime.now()

        return actor
```

## State Compression Patterns

For actors with potentially large state, compression patterns help manage memory:

### 1. Time-Window Compression

Keep detailed state only for a recent time window:

```python
def compress_state(self):
    """Compress state by keeping only recent detailed information"""
    if not self.state.messages:
        return

    # Determine cutoff point (e.g., 24 hours ago)
    cutoff = datetime.now() - timedelta(hours=24)

    # Keep recent messages intact
    recent_messages = [
        msg for msg in self.state.messages
        if datetime.fromisoformat(msg["timestamp"]) >= cutoff
    ]

    # Summarize older messages
    older_messages = [
        msg for msg in self.state.messages
        if datetime.fromisoformat(msg["timestamp"]) < cutoff
    ]

    if older_messages:
        # Create a summary
        summary = {
            "type": "summary",
            "count": len(older_messages),
            "period": {
                "start": min(datetime.fromisoformat(msg["timestamp"]) for msg in older_messages).isoformat(),
                "end": max(datetime.fromisoformat(msg["timestamp"]) for msg in older_messages).isoformat()
            },
            "ids": [msg["id"] for msg in older_messages]
        }

        # Replace older messages with summary
        self.state.messages = [summary] + recent_messages
```

### 2. Semantic Compression

For actors like Experience that store semantic content:

```python
async def compress_knowledge(self):
    """Compress knowledge base using semantic clustering"""
    if len(self.state.knowledge_base) <= self.max_uncompressed_items:
        return

    # Extract embeddings for items
    embeddings = [item["embedding"] for item in self.state.knowledge_base if "embedding" in item]

    if len(embeddings) <= self.max_uncompressed_items:
        return

    # Perform clustering
    clusters = await self.semantic_clusterer.cluster(
        embeddings,
        n_clusters=self.max_compressed_clusters
    )

    # Create compressed knowledge base
    compressed_kb = []
    for cluster_id, item_indices in clusters.items():
        if len(item_indices) == 1:
            # Single item in cluster, keep as is
            compressed_kb.append(self.state.knowledge_base[item_indices[0]])
        else:
            # Multiple items, create a summary
            cluster_items = [self.state.knowledge_base[i] for i in item_indices]
            summary = await self.create_cluster_summary(cluster_items)
            compressed_kb.append(summary)

    # Update state with compressed knowledge base
    self.update_state(lambda s: setattr(s, "knowledge_base", compressed_kb))
```

## Multi-Modal State Patterns

For actors that handle multiple modalities (text, audio, video, code):

### 1. Polymorphic State Pattern

Define base state with modality-specific extensions:

```python
class ContentItem(BaseModel):
    """Base class for content items"""
    id: str
    created_at: datetime
    metadata: Dict[str, Any] = Field(default_factory=dict)

class TextContent(ContentItem):
    """Text content"""
    modality: Literal["text"] = "text"
    text: str

class ImageContent(ContentItem):
    """Image content"""
    modality: Literal["image"] = "image"
    image_url: str
    alt_text: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None

class AudioContent(ContentItem):
    """Audio content"""
    modality: Literal["audio"] = "audio"
    audio_url: str
    duration: Optional[float] = None
    transcript: Optional[str] = None

class MultiModalState(ActorState):
    """State for actors handling multiple modalities"""
    content_items: List[Union[TextContent, ImageContent, AudioContent]] = Field(default_factory=list)
```

### 2. Modality Routing Pattern

Route state operations based on content modality:

```python
async def process_content(self, content: Union[TextContent, ImageContent, AudioContent]) -> None:
    """Process content based on modality"""
    processor = self.get_processor_for_modality(content.modality)
    result = await processor.process(content)

    # Update state with processed content
    self.update_state(lambda s: s.content_items.append(result))

def get_processor_for_modality(self, modality: str) -> ContentProcessor:
    """Get appropriate processor for the modality"""
    processors = {
        "text": self.text_processor,
        "image": self.image_processor,
        "audio": self.audio_processor
    }

    if modality not in processors:
        raise ValueError(f"Unsupported modality: {modality}")

    return processors[modality]
```

## State Sharing Patterns

While the actor model emphasizes isolation, some patterns enable controlled sharing:

### 1. Reference State Pattern

Share references to immutable data to avoid duplication:

```python
class SharedReference(BaseModel):
    """Reference to shared immutable data"""
    ref_id: str
    ref_type: str
    metadata: Dict[str, Any] = Field(default_factory=dict)

class ReferenceState(ActorState):
    """State that includes references to shared data"""
    local_data: Dict[str, Any] = Field(default_factory=dict)
    shared_refs: List[SharedReference] = Field(default_factory=list)

    async def resolve_references(self, ref_resolver: ReferenceResolver) -> Dict[str, Any]:
        """Resolve references to their actual values"""
        resolved = {}
        for ref in self.shared_refs:
            resolved[ref.ref_id] = await ref_resolver.resolve(ref.ref_id, ref.ref_type)
        return resolved
```

### 2. Query State Pattern

Allow actors to query other actors' state in a controlled manner:

```python
class StateQuery(BaseModel):
    """Query for another actor's state"""
    target_actor: str
    query_fields: List[str]
    filters: Optional[Dict[str, Any]] = None

async def query_other_actor(self, query: StateQuery) -> Dict[str, Any]:
    """Query another actor's state"""
    # Create query message
    message = Message(
        type=MessageType.REQUEST,
        sender=self.name,
        recipient=query.target_actor,
        content={
            "type": "state_query",
            "fields": query.query_fields,
            "filters": query.filters
        }
    )

    # Send query and await response
    response = await self.send_and_receive(message)

    if response.type == MessageType.ERROR:
        # Handle query error
        raise StateQueryError(response.content.description)

    return response.content.result
```

## Testing State Patterns

### 1. State Snapshot Testing

Create snapshots of actor state for testing:

```python
async def test_action_actor_state_evolution():
    """Test that Action actor state evolves correctly"""
    # Create actor with test state
    actor = ActionActor("test-action", ActionState(
        actor_type="ActionActor",
        messages=[]
    ))

    # Process a message
    await actor.process_message(create_test_message("Hello"))

    # Take state snapshot
    state_snapshot_1 = actor.state.model_dump()

    # Process another message
    await actor.process_message(create_test_message("World"))

    # Take another snapshot
    state_snapshot_2 = actor.state.model_dump()

    # Verify state evolution
    assert len(state_snapshot_1["messages"]) == 1
    assert len(state_snapshot_2["messages"]) == 2
    assert state_snapshot_2["version"] == state_snapshot_1["version"] + 1
```

### 2. State Replay Testing

Test actor behavior by replaying state from events:

```python
async def test_event_sourced_actor_replay():
    """Test that event sourced actor correctly rebuilds state from events"""
    # Create test events
    events = [
        {"type": "created", "payload": {"id": "test-1", "name": "Test Actor"}},
        {"type": "updated", "payload": {"field": "value1"}},
        {"type": "updated", "payload": {"field": "value2"}}
    ]

    # Create mock event store
    event_store = MockEventStore(events)

    # Create actor by replaying events
    actor = await EventSourcedActor.create("test-1", event_store)

    # Verify state
    assert actor.state.version == 3
    assert actor.state.local_field == "value2"
    assert len(actor.state.events) == 3
```

## Conclusion

Effective state management is critical for actor-based systems. By following these patterns, Choir's implementation provides:

1. **Robustness**: Actors can persist and recover their state reliably
2. **Scalability**: State management scales across distributed systems
3. **Consistency**: Changes to state are predictable and verifiable
4. **Performance**: Compression and querying patterns optimize memory and processing
5. **Testability**: State patterns support comprehensive testing

These patterns form the foundation for Choir's actor model implementation, ensuring that each actor maintains its state effectively while collaborating within the larger system.

---

These patterns should be adapted as needed for specific actor implementations while maintaining the core principles of state encapsulation and message-based mutation that are central to the actor model.
