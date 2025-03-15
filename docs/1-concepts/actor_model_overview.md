# Actor Model Overview

## Introduction to the Actor Model

The Actor Model is a mathematical model of concurrent computation that treats "actors" as the universal primitives of computation. In the context of Choir's PostChain architecture, actors serve as the fundamental building blocks for implementing the AEIOU-Y phases in a distributed, scalable, and fault-tolerant manner.

```
┌─────────────────────────────────────────────────────┐
│                  ACTOR MODEL                         │
│                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐       │
│  │  Actor A │    │  Actor B │    │  Actor C │       │
│  │  ┌────┐  │    │  ┌────┐  │    │  ┌────┐  │       │
│  │  │State│  │    │  │State│  │    │  │State│  │       │
│  │  └────┘  │    │  └────┘  │    │  └────┘  │       │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘       │
│       │               │                │            │
│       └───────────────┼────────────────┘            │
│                       │                              │
│                 Message Passing                      │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Core Principles

### 1. Actors as Fundamental Units

In the Actor Model, each actor is an independent computational entity with:

- **Private State**: Encapsulated and accessible only to the actor itself
- **Message Processing Logic**: Behavior defined by how it responds to messages
- **Communication Channel**: Ability to send messages to other actors

In Choir's implementation, each phase of the PostChain (Action, Experience, Intention, Observation, Understanding, Yield) is represented by a specialized actor.

### 2. Message-Based Communication

Actors communicate exclusively through asynchronous message passing:

- Messages are sent and delivered asynchronously
- No shared state between actors
- Each actor processes messages one at a time
- Messages are immutable once sent

Example message structure in Choir:

```python
class Message(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    type: MessageType
    sender: str
    recipient: str
    created_at: datetime = Field(default_factory=datetime.now)
    content: Any
    correlation_id: Optional[str] = None  # For tracking request/response chains
```

### 3. Isolation and Encapsulation

Each actor:

- Maintains its own state
- Cannot directly access the state of other actors
- Processes messages sequentially
- Handles its own failures

This isolation provides natural boundaries for error containment and scalability.

## Actor Model vs. Graph-Based Architecture

| Aspect               | Actor Model                   | Graph-Based (LangGraph)         |
| -------------------- | ----------------------------- | ------------------------------- |
| **State Management** | Distributed across actors     | Centralized in graph state      |
| **Communication**    | Asynchronous messages         | Function calls and edges        |
| **Error Handling**   | Isolated to individual actors | Can affect entire graph         |
| **Scalability**      | Horizontal (add more actors)  | Primarily vertical              |
| **Concurrency**      | Natural parallel execution    | More complex coordination       |
| **Memory Usage**     | Distributed (500MB-1GB)       | Centralized (2-4GB per session) |
| **Modality Support** | Natural extension points      | More rigid structure            |

## PostChain Actors in Choir

The AEIOU-Y PostChain maps naturally to specialized actors:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐          │
│  │ Action  │    │Experience│    │Intention│          │
│  │ Actor   │───▶│  Actor  │───▶│  Actor  │───┐      │
│  └─────────┘    └─────────┘    └─────────┘   │      │
│       ▲                                       │      │
│       │                                       ▼      │
│       │                                       │      │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐   │      │
│  │  Yield  │◀───│Understand│◀───│Observe  │◀──┘      │
│  │  Actor  │    │  Actor   │    │ Actor   │          │
│  └─────────┘    └─────────┘    └─────────┘          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

- **Action Actor**: Processes user input and generates initial responses
- **Experience Actor**: Enriches context with historical knowledge and RAG retrievals
- **Intention Actor**: Aligns responses with identified user intents
- **Observation Actor**: Records semantic patterns and connections
- **Understanding Actor**: Makes decisions about processing flow
- **Yield Actor**: Produces final, polished responses

## Actor State Management

Each actor in the PostChain manages its own specialized state:

```python
class ActionState(ActorState):
    """State for the Action actor"""
    messages: List[Dict[str, Any]] = Field(default_factory=list)
    current_input: Optional[str] = None

class ExperienceState(ActorState):
    """State for the Experience actor"""
    knowledge_base: List[Dict[str, Any]] = Field(default_factory=list)
    retrieved_context: List[Dict[str, Any]] = Field(default_factory=list)

# ... other actor states ...
```

This state is:

- Persisted to libSQL/Turso database
- Private to each actor
- Restored when an actor restarts
- Type-validated using Pydantic

## Message Flow in the Actor System

1. **Message Creation**: An actor creates a message with a specific recipient
2. **Message Sending**: The message is sent to the recipient's mailbox
3. **Message Processing**: The recipient processes the message according to its behavior
4. **State Update**: The recipient may update its internal state
5. **Response Creation**: The recipient may send response messages to other actors

Example message flow:

```python
# User input flows through the PostChain
async def process_input(self, user_input: str) -> str:
    # Generate correlation ID for tracking this request through the chain
    correlation_id = f"req-{uuid.uuid4()}"

    # Start at Action actor
    await self.system.send_message(
        "system",
        self.action_actor.name,
        MessageType.REQUEST,
        user_input,
        correlation_id=correlation_id
    )

    # Wait for result from Yield actor
    result = await self.wait_for_completion(correlation_id)
    return result
```

## Error Handling and Supervision

In the actor model:

- Actors can monitor each other through supervision relationships
- Failed actors can be restarted with their last known state
- Errors are contained within actor boundaries
- Supervision hierarchies manage actor lifecycles

```python
class ActorSupervisor:
    async def handle_actor_failure(self, actor_name: str, error: Exception):
        # Load last known state
        state = await self.state_manager.load_state(actor_name)

        # Recreate actor with recovered state
        new_actor = self.create_actor(actor_name, initial_state=state)

        # Register the new actor
        self.system.register_actor(new_actor)

        # Log the recovery
        logger.info(f"Recovered actor {actor_name} after failure: {error}")
```

## Extension through the Phase Worker Pool

The actor model is extended through the Phase Worker Pool pattern, which:

- Separates phase types from actor implementations
- Supports multiple modalities (text, audio, video, code)
- Abstracts AI model access through worker pools
- Enables specialized domain actors (medical, legal, financial)

This pattern is covered in detail in the [Phase Worker Pool Architecture](../phase_worker_pool_architecture.md) document.

## Practical Implementation Considerations

When implementing actors in the Choir system:

1. **Actor Granularity**: Design actors at the right level of granularity (typically one per phase)
2. **Message Design**: Define clear message types and content structures
3. **State Management**: Determine what state needs to be persisted vs. transient
4. **Error Handling**: Implement supervision relationships and recovery mechanisms
5. **Testing**: Test actors in isolation using mock messages

## Advantages of the Actor Model for Choir

The actor model provides several advantages for Choir's architecture:

1. **Memory Efficiency**: Each actor manages its own memory independently
2. **Fault Tolerance**: Failures are isolated to individual actors
3. **Scalability**: Actors can be distributed across multiple processes or machines
4. **Modality Support**: Natural extension to different input types
5. **Concurrent Processing**: Natural parallelism where appropriate
6. **Deployment Flexibility**: Actors can be deployed and scaled independently

## Key Implementation Components

Choir's actor model implementation is built on:

1. **Thespian**: Actor framework for message passing and lifecycle management
2. **Pydantic**: Type validation for messages and state
3. **libSQL/Turso**: State persistence for actors
4. **FastAPI**: API layer for external communication
5. **PySUI**: Blockchain integration for economic model

## Next Steps

To begin working with the actor model in Choir:

1. Review the [Actor Implementation Guide](../3-implementation/actor_implementation_guide.md)
2. Explore the [Message Protocol Reference](../message_protocol_reference.md)
3. Learn about [State Management Patterns](../3-implementation/state_management_patterns.md)
4. Understand [Phase Worker Pools](../2-architecture/phase_worker_pools.md)

---

This document provides a foundation for understanding the actor model architecture in Choir. For more detailed implementation guidelines, refer to the linked documents in the Next Steps section.
