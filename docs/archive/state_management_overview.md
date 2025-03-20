# State Management Overview
## Table of Contents
1. [Introduction](#introduction)
2. [Actor State Fundamentals](#actor-state-fundamentals)
3. [State Persistence](#state-persistence)
4. [Actor-Agent Interaction](#actor-agent-interaction)
5. [State Evolution and Versioning](#state-evolution-and-versioning)
6. [Error Handling and Recovery](#error-handling-and-recovery)
7. [Migration Path to Database Persistence](#migration-path-to-database-persistence)
8. [Implementation Guidelines](#implementation-guidelines)

## Introduction

In Choir's actor-based architecture, state management is a critical aspect of system design. Actors encapsulate state and behavior, communicating with each other through message passing. This document describes how state is managed within this architecture, with a focus on pragmatic solutions that balance development speed with system reliability.

### Key Principles

1. **State Encapsulation**: Each actor manages its own state independently
2. **Message-Driven Updates**: State changes occur only in response to messages
3. **Persistence-Agnostic Design**: Core business logic is separated from persistence mechanics
4. **Progressive Enhancement**: Start simple and evolve as needed
5. **Type Safety**: Leverage Pydantic models for validation and serialization

## Actor State Fundamentals

### State Definition

Actor state in Choir is defined using Pydantic models, providing both runtime validation and serialization capabilities:
```python
from datetime import datetime
from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field


class ActorState(BaseModel):
    """Base model for all actor states"""
    actor_id: str
    actor_type: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    version: int = 1
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ProcessingActorState(ActorState):
    """State for processing actors"""
    processed_count: int = 0
    last_processed_id: Optional[str] = None
    processing_history: List[str] = Field(default_factory=list)


class AgentManagerActorState(ActorState):
    """State for actors that manage Pydantic AI agents"""
    agent_id: str
    agent_config: Dict[str, Any] = Field(default_factory=dict)
    agent_history: List[Dict[str, Any]] = Field(default_factory=list)
    last_interaction: Optional[datetime] = None
```

### State Lifecycle

The lifecycle of actor state follows these stages:

1. **Initialization**: State is created when an actor is first instantiated
2. **Updates**: State is modified in response to messages
3. **Persistence**: State is saved to external storage at appropriate intervals
4. **Recovery**: State is loaded when an actor is restarted
5. **Archival/Cleanup**: Old state may be archived or cleaned up based on retention policies

### State Access Patterns

Actors should follow these patterns when accessing state:

1. **Read-Only Access**: Methods that don't modify state should be clearly identified
2. **Atomic Updates**: State updates should be atomic operations
3. **Validation**: State changes should be validated before being applied
4. **Immutability**: Prefer immutable data structures for state components where possible

Example implementation in an actor:
```python
class ExampleActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = self._load_state() or ProcessingActorState(
            actor_id=self.id,
            actor_type="ExampleActor"
        )

    async def receive(self, message):
        if message.type == "PROCESS_ITEM":
            return await self._process_item(message.data)
        elif message.type == "GET_STATS":
            return self._get_stats()
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    async def _process_item(self, item):
        # Update state
        self.state.processed_count += 1
        self.state.last_processed_id = item["id"]
        self.state.processing_history.append(item["id"])
        self.state.updated_at = datetime.utcnow()

        # Persist state
        self._save_state()

        # Return response
        return Response(
            type="PROCESSING_COMPLETE",
            data={"status": "success", "processed_count": self.state.processed_count}
        )

    def _get_stats(self):
        # Read-only access to state
        return Response(
            type="STATS",
            data={
                "processed_count": self.state.processed_count,
                "last_processed_id": self.state.last_processed_id,
                "last_updated": self.state.updated_at.isoformat()
            }
        )
```

## State Persistence

Choir initially uses a file-based persistence strategy, evolving to database storage as the system matures.

### File-Based Persistence

The initial implementation uses JSON files for persistence, with a structured directory layout:
```
state/
├── actor_type_a/
│   ├── actor_id_1.json
│   └── actor_id_2.json
├── actor_type_b/
│   └── actor_id_3.json
└── metadata.json
```

Implementation example:
```python
import os
import json
from datetime import datetime

class StatePersistence:
    """Handles persistence of actor state to the filesystem"""

    @staticmethod
    def save_state(state: ActorState, base_dir: str = "state"):
        """Save actor state to a JSON file"""
        # Ensure type directory exists
        type_dir = os.path.join(base_dir, state.actor_type)
        os.makedirs(type_dir, exist_ok=True)

        # Create file path
        file_path = os.path.join(type_dir, f"{state.actor_id}.json")

        # Update timestamp
        state.updated_at = datetime.utcnow()

        # Write state to file
        with open(file_path, "w") as f:
            f.write(state.model_dump_json(indent=2))

    @staticmethod
    def load_state(actor_type: str, actor_id: str, base_dir: str = "state") -> Optional[ActorState]:
        """Load actor state from a JSON file"""
        file_path = os.path.join(base_dir, actor_type, f"{actor_id}.json")

        if not os.path.exists(file_path):
            return None

        with open(file_path, "r") as f:
            data = f.read()

        # Determine the correct state class based on actor_type
        state_class = get_state_class_for_type(actor_type)

        # Parse and validate the state
        return state_class.model_validate_json(data)


def get_state_class_for_type(actor_type: str) -> Type[ActorState]:
    """Return the appropriate state class for a given actor type"""
    type_map = {
        "ProcessingActor": ProcessingActorState,
        "AgentManagerActor": AgentManagerActorState,
        # Add mappings for other actor types
    }
    return type_map.get(actor_type, ActorState)
```

### Persistence Patterns

The implementation follows these patterns:

1. **Frequency**: State is persisted:

   - After significant state changes
   - At regular intervals (e.g., every N messages)
   - Before actor shutdown

2. **Transactional Safety**:

   - Write to temporary files first
   - Rename to target file after successful write
   - Use file locking where appropriate

3. **Efficiency**:

   - Only persist changed fields when possible
   - Consider incremental state updates for large states

4. **Backup**:

   - Keep a configurable number of state history files
   - Implement rolling backups with timestamp suffixes

## Actor-Agent Interaction

Choir uses Thespian actors to create and manage Pydantic AI agents. This section outlines how actors and agents interact.

### Agent Creation and Management

Actors that manage Pydantic AI agents follow this pattern:
```python
from pydantic_ai import Agent, RunContext
from thespian.actors import Actor

class AgentManagerActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = self._load_state() or AgentManagerActorState(
            actor_id=self.id,
            actor_type="AgentManagerActor",
            agent_id=f"{self.id}_agent"
        )

        # Create Pydantic AI agent based on state
        self.agent = self._create_agent()

    def _create_agent(self):
        """Create a Pydantic AI agent based on actor state"""
        # Create the agent with appropriate config
        agent = Agent(
            'openai:gpt-4o', # Or load from config
            deps_type=dict,  # Dependency type
            result_type=dict,  # Result type
            system_prompt=self.state.agent_config.get("system_prompt", "")
        )

        # Set up tools based on configuration
        if "tools" in self.state.agent_config:
            for tool_config in self.state.agent_config["tools"]:
                # Register appropriate tools
                pass

        return agent

    async def receive(self, message):
        if message.type == "PROCESS_WITH_AGENT":
            return await self._process_with_agent(message.data)
        elif message.type == "UPDATE_AGENT_CONFIG":
            return self._update_agent_config(message.data)
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    async def _process_with_agent(self, data):
        """Process a request with the Pydantic AI agent"""
        # Run the agent with the provided data
        result = await self.agent.run(data["input"], deps=data.get("context", {}))

        # Record interaction in state
        self.state.agent_history.append({
            "timestamp": datetime.utcnow().isoformat(),
            "input": data["input"],
            "output": result.data
        })
        self.state.last_interaction = datetime.utcnow()
        self.state.updated_at = datetime.utcnow()

        # Persist state
        self._save_state()

        # Return the result
        return Response(
            type="AGENT_RESPONSE",
            data={"result": result.data}
        )

    def _update_agent_config(self, config_data):
        """Update the agent configuration"""
        # Update config in state
        self.state.agent_config.update(config_data)
        self.state.updated_at = datetime.utcnow()

        # Recreate the agent with new config
        self.agent = self._create_agent()

        # Persist state
        self._save_state()

        return Response(
            type="CONFIG_UPDATED",
            data={"status": "success"}
        )
```

### Agent Tool Integration

Actors can provide tools to agents that allow the agents to interact with other actors or system components:
```python
@agent.tool
async def get_data_from_actor(ctx: RunContext[dict], query: str) -> str:
    """Fetch data from another actor based on a query"""
    # Get reference to another actor
    data_actor = await actor_system.get_actor("data_actor")

    # Send message to get data
    response = await data_actor.send(
        Message(
            type="QUERY_DATA",
            data={"query": query}
        )
    )

    # Format and return the response
    return json.dumps(response.data)
```

### Message Flow Between Actors and Agents

The typical message flow between actors and agents is:

1. An actor receives a message requesting agent processing
2. The actor prepares context and input for the agent
3. The actor runs the agent, which may use tools to interact with other system components
4. The agent produces a result
5. The actor processes the result, updates its state, and returns a response

## State Evolution and Versioning

As the system evolves, actor state schemas will need to evolve as well. This section outlines how to handle state versioning and migration.

### State Version Tracking

Each state model includes a `version` field that tracks the schema version:
```python
class ActorState(BaseModel):
    # ... other fields
    version: int = 1
```

### State Migration

When loading state, check the version and migrate if necessary:
```python
def load_and_migrate_state(actor_type: str, actor_id: str) -> ActorState:
    """Load state and migrate to current version if needed"""
    state = StatePersistence.load_state(actor_type, actor_id)

    if state is None:
        # Create new state
        state_class = get_state_class_for_type(actor_type)
        return state_class(actor_id=actor_id, actor_type=actor_type)

    # Check version and migrate if needed
    current_version = get_current_version_for_type(actor_type)

    if state.version < current_version:
        state = migrate_state(state, current_version)

    return state


def migrate_state(state: ActorState, target_version: int) -> ActorState:
    """Migrate state to target version"""
    current_version = state.version

    # Apply migrations in sequence
    while current_version < target_version:
        migration_func = get_migration_function(state.actor_type, current_version, current_version + 1)
        state = migration_func(state)
        current_version += 1

    return state
```

### Migration Functions

Define specific migration functions for each version transition:
```python
def migrate_processing_actor_v1_to_v2(state: ProcessingActorState) -> ProcessingActorState:
    """Migrate ProcessingActorState from v1 to v2"""
    # Create a new state with the updated schema
    new_state = ProcessingActorState(
        actor_id=state.actor_id,
        actor_type=state.actor_type,
        created_at=state.created_at,
        updated_at=state.updated_at,
        version=2,  # Update version
        metadata=state.metadata,
        processed_count=state.processed_count,
        last_processed_id=state.last_processed_id,
        processing_history=state.processing_history,
        error_count=0  # Add new field in v2
    )

    return new_state
```

## Error Handling and Recovery

Robust state management requires handling various error scenarios and providing recovery mechanisms.

### Error Scenarios

1. **File System Errors**:

   - File not found
   - Permission issues
   - Disk full errors

2. **Serialization Errors**:

   - Invalid JSON
   - Schema validation failures

3. **Corruption Errors**:

   - Partial writes
   - Unexpected format

### Recovery Strategies

1. **Backup Restoration**:

   - Keep multiple backup files with timestamps
   - Restore from the most recent valid backup

2. **Default State**:

   - Fall back to default state initialization if no valid state can be loaded
   - Log the error and notify monitoring systems

3. **State Repair**:
   - Implement repair strategies for common corruption patterns
   - Validate state integrity after loading

Implementation example:
```python
def safe_load_state(actor_type: str, actor_id: str) -> ActorState:
    """Load state with fallback to backups"""
    # Try loading the main state file
    try:
        state = StatePersistence.load_state(actor_type, actor_id)
        if state is not None:
            return state
    except Exception as e:
        logging.error(f"Error loading state for {actor_type}/{actor_id}: {e}")

    # Try loading from backups
    backups = list_backup_files(actor_type, actor_id)
    for backup_path in sorted(backups, reverse=True):  # Latest first
        try:
            with open(backup_path, "r") as f:
                data = f.read()

            state_class = get_state_class_for_type(actor_type)
            return state_class.model_validate_json(data)
        except Exception as e:
            logging.error(f"Error loading backup {backup_path}: {e}")

    # Fall back to new state
    logging.warning(f"Creating new state for {actor_type}/{actor_id} after failed recovery")
    state_class = get_state_class_for_type(actor_type)
    return state_class(actor_id=actor_id, actor_type=actor_type)
```

## Migration Path to Database Persistence

While Choir initially uses file-based persistence, the architecture is designed for eventual migration to database storage (libSQL). This section outlines the migration path.

### Abstraction Layer

Implement a persistence abstraction layer to isolate storage details:
```python
from abc import ABC, abstractmethod
from typing import Optional, Type

class PersistenceProvider(ABC):
    """Abstract base class for persistence providers"""

    @abstractmethod
    def save_state(self, state: ActorState) -> bool:
        """Save state to storage"""
        pass

    @abstractmethod
    def load_state(self, actor_type: str, actor_id: str) -> Optional[ActorState]:
        """Load state from storage"""
        pass

    @abstractmethod
    def list_actors(self, actor_type: Optional[str] = None) -> List[str]:
        """List actor IDs, optionally filtered by type"""
        pass

    @abstractmethod
    def delete_state(self, actor_type: str, actor_id: str) -> bool:
        """Delete state from storage"""
        pass


class FilePersistenceProvider(PersistenceProvider):
    """File-based persistence provider"""

    def __init__(self, base_dir: str = "state"):
        self.base_dir = base_dir

    def save_state(self, state: ActorState) -> bool:
        # Implementation for file-based persistence
        pass

    def load_state(self, actor_type: str, actor_id: str) -> Optional[ActorState]:
        # Implementation for file-based persistence
        pass

    def list_actors(self, actor_type: Optional[str] = None) -> List[str]:
        # Implementation for file-based persistence
        pass

    def delete_state(self, actor_type: str, actor_id: str) -> bool:
        # Implementation for file-based persistence
        pass


class LibSQLPersistenceProvider(PersistenceProvider):
    """LibSQL-based persistence provider"""

    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        # Initialize connection pool, etc.

    def save_state(self, state: ActorState) -> bool:
        # Implementation for LibSQL persistence
        pass

    def load_state(self, actor_type: str, actor_id: str) -> Optional[ActorState]:
        # Implementation for LibSQL persistence
        pass

    def list_actors(self, actor_type: Optional[str] = None) -> List[str]:
        # Implementation for LibSQL persistence
        pass

    def delete_state(self, actor_type: str, actor_id: str) -> bool:
        # Implementation for LibSQL persistence
        pass
```

## Implementation Guidelines

This section provides practical guidelines for implementing state management in Choir actors.

### Actor Implementation Pattern

Follow this pattern when implementing actors with state management:
```python
class MyActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        # Initialize state
        self.state = self._load_state() or MyActorState(
            actor_id=self.id,
            actor_type="MyActor"
        )
        # Additional initialization
        self._setup()

    def _load_state(self) -> Optional[MyActorState]:
        """Load actor state"""
        provider = get_persistence_provider()
        return provider.load_state("MyActor", self.id)

    def _save_state(self) -> bool:
        """Save actor state"""
        provider = get_persistence_provider()
        return provider.save_state(self.state)

    def _setup(self):
        """Setup actor based on state"""
        # Initialize resources based on state
        pass

    async def receive(self, message):
        """Handle incoming messages"""
        # Message handling logic
        pass

    def _before_shutdown(self):
        """Called before actor is shutdown"""
        # Save state before shutdown
        self._save_state()
        # Release resources
        pass
```

### State Design Best Practices

When designing actor state:

1. **Keep It Focused**: Include only what the actor needs to function
2. **Use Type Annotations**: Leverage Pydantic's type validation
3. **Consider Performance**: Balance between atomic state and performance
4. **Support Versioning**: Design with future changes in mind
5. **Provide Default Values**: Make state creation intuitive with defaults

### Testing State Management

Test strategies for state management:

1. **Unit Testing**: Test state loading, saving, and migration functions
2. **Property-Based Testing**: Use property-based testing for state mutations
3. **Recovery Testing**: Test recovery from corrupted state files
4. **Migration Testing**: Test state migration between versions
5. **Performance Testing**: Verify state operations meet performance requirements

## Conclusion

Choir's state management architecture provides a pragmatic approach to managing actor state. By starting with file-based persistence and providing a clear migration path to database storage, the system can evolve alongside business requirements without requiring major refactoring.

The use of Pydantic models for state definition ensures type safety and validation while enabling easy serialization and deserialization. The integration with Pydantic AI agents allows for powerful AI capabilities within the actor framework.

By following the patterns and practices outlined in this document, developers can create robust, maintainable actors that seamlessly integrate with the rest of the Choir ecosystem.
