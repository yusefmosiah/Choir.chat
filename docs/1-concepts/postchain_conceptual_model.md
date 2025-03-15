# PostChain Actor Model Implementation

## Overview

The Choir PostChain (AEIOU-Y) is implemented using the actor model, where each phase of the PostChain is represented by a specialized actor with encapsulated state. This document details the technical architecture, message flow, state management, and implementation patterns.

## Core Architecture

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐          │
│  │ Action  │    │Experience│    │Intention│          │
│  │ Actor   │───▶│  Actor  │───▶│  Actor  │───┐      │
│  └─────────┘    └─────────┘    └─────────┘   │      │
│       ▲                                       │      │
│       │                                       ▼      │
│       │           POST CHAIN                  │      │
│       │                                       │      │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐   │      │
│  │  Yield  │◀───│Understand│◀───│Observe  │◀──┘      │
│  │  Actor  │    │  Actor   │    │ Actor   │          │
│  └─────────┘    └─────────┘    └─────────┘          │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                       ▲
         │   ┌───────────────┐   │
         └──▶│  libsql/turso │───┘
             │  (SQL + RAG)  │
             └───────────────┘
```

## Actor Definitions

### Base Classes

```python
class ActorState(BaseModel):
    """Base class for actor-specific state"""
    pass

class Actor(Generic[T]):
    """Base Actor implementation following the actor model pattern"""

    def __init__(self, name: str, initial_state: Optional[T] = None):
        self.name = name
        self.state = initial_state
        self.mailbox: asyncio.Queue[Message] = asyncio.Queue()
        self.handlers: Dict[MessageType, Callable] = {}
```

### PostChain Actor States

Each actor in the PostChain maintains its own specialized state:

```python
class ActionState(ActorState):
    """State for the Action actor"""
    messages: List[Dict[str, Any]] = Field(default_factory=list)
    current_input: Optional[str] = None

class ExperienceState(ActorState):
    """State for the Experience actor"""
    knowledge_base: List[Dict[str, Any]] = Field(default_factory=list)
    retrieved_context: List[Dict[str, Any]] = Field(default_factory=list)

class IntentionState(ActorState):
    """State for the Intention actor"""
    user_intents: List[str] = Field(default_factory=list)
    current_intent: Optional[str] = None

class ObservationState(ActorState):
    """State for the Observation actor"""
    semantic_connections: List[Dict[str, Any]] = Field(default_factory=list)
    observations: List[str] = Field(default_factory=list)

class UnderstandingState(ActorState):
    """State for the Understanding actor"""
    decisions: List[Dict[str, Any]] = Field(default_factory=list)
    continue_chain: bool = True

class YieldState(ActorState):
    """State for the Yield actor"""
    final_responses: List[Dict[str, Any]] = Field(default_factory=list)
    current_response: Optional[str] = None
```

## Message Protocol

Actors communicate via strongly-typed messages:

```python
class MessageType(Enum):
    REQUEST = auto()
    RESPONSE = auto()
    ERROR = auto()
    EVENT = auto()

class Message(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    type: MessageType
    sender: str
    recipient: str
    created_at: datetime = Field(default_factory=datetime.now)
    content: Any
    correlation_id: Optional[str] = None  # For tracking request/response chains
```

## Actor Implementation

Each phase of the PostChain is implemented as a specialized actor:

### Action Actor

```python
class ActionActor(Actor[ActionState]):
    """Handles the Action phase - initial response to user input"""

    def __init__(self, experience_actor: Optional['ExperienceActor'] = None):
        super().__init__("action", ActionState())
        self.register_handler(MessageType.REQUEST, self.handle_request)
        self.experience_actor = experience_actor

    async def handle_request(self, message: Message) -> Any:
        """Process a user input and generate initial response"""
        user_input = message.content

        # Update state
        if self.state:
            self.state.current_input = user_input
            self.state.messages.append({"role": "user", "content": user_input})

        # In a real implementation, this would call an LLM to process the input
        initial_response = f"Initial processing of: {user_input}"

        # Pass to Experience actor if available
        if self.experience_actor and message.correlation_id:
            await self.send(
                self.experience_actor,
                MessageType.REQUEST,
                {
                    "user_input": user_input,
                    "initial_response": initial_response
                },
                correlation_id=message.correlation_id
            )

        return initial_response
```

Similar patterns apply to other actors in the chain (Experience, Intention, Observation, Understanding, Yield).

## State Management

Each actor manages its own state, which solves several key problems:

1. **Context Window Management**: Each actor can apply its own strategy for state compression and relevance determination
2. **Memory Specialization**: Actors keep state relevant to their specific responsibility
3. **Fault Isolation**: State corruption in one actor doesn't affect others
4. **Persistence Flexibility**: Each actor's state can be persisted independently

### State Persistence

Actor states are persisted to libSQL/Turso:

```python
async def save_state(self, actor_name: str, state: ActorState):
    """Save actor state to the database"""
    if not self.db:
        await self.connect()

    # Convert state to JSON
    state_json = state.model_dump_json()

    # Save to database
    await self.db.execute(
        "INSERT INTO actor_state (actor_name, state_json) VALUES (?, ?)",
        (actor_name, state_json)
    )
    await self.db.commit()

async def load_state(self, actor_name: str, state_type: Type[ActorState]) -> Optional[ActorState]:
    """Load actor state from the database"""
    if not self.db:
        await self.connect()

    # Get the latest state for this actor
    cursor = await self.db.execute(
        "SELECT state_json FROM actor_state WHERE actor_name = ? ORDER BY created_at DESC LIMIT 1",
        (actor_name,)
    )
    row = await cursor.fetchone()

    if not row:
        return None

    # Convert JSON back to state object
    state_json = row[0]
    return state_type.model_validate_json(state_json)
```

## Message Flow Control

The PostChain manages the flow of messages through the actor system:

```python
async def process_input(self, user_input: str) -> str:
    """Process user input through the full Post Chain"""
    # Generate correlation ID for tracking this request through the chain
    correlation_id = f"req-{user_input[:10]}-{asyncio.get_event_loop().time()}"

    # Start the chain at the Action actor
    await self.system.send_message(
        "system",
        self.action_actor.name,
        MessageType.REQUEST,
        user_input,
        correlation_id=correlation_id
    )

    # Wait for processing to complete through the chain
    # This would use a future/promise pattern in production
    result = await self.wait_for_completion(correlation_id)

    return result
```

## Knowledge Integration (RAG)

The Experience actor integrates with RAG capabilities via libSQL/Turso:

```python
async def perform_rag_query(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
    """Perform a RAG query against the stored data"""
    # Generate embedding for the query
    query_embedding = await self.embedding_model.embed_text(query)

    # In a real implementation, libSQL would have vector search capabilities
    # Return relevant documents based on embedding similarity
    return results
```

## Blockchain Integration

The citation mechanism integrates with the Sui blockchain via PySUI:

```python
async def record_citation(self, cited_message_id: str, citing_message_id: str, citation_value: float):
    """Record a citation on the blockchain and trigger token transfer"""
    # Create a transaction on Sui
    tx = await self.sui_client.create_citation_transaction(
        cited_message_id,
        citing_message_id,
        citation_value
    )

    # Execute the transaction
    result = await self.sui_client.execute_transaction(tx)

    return result
```

## Security Model

The actor model provides natural security boundaries:

1. **Message Validation**: All inter-actor messages are validated by Pydantic
2. **Isolated State**: Actors cannot directly access each other's state
3. **Explicit Communication**: All interactions happen through well-defined message channels
4. **Controlled Access**: Actors only have access to resources explicitly provided to them

## Deployment Architecture

The entire system is containerized using Docker:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Future Extensions

The actor model enables several powerful extensions:

1. **Dynamic Actor Creation**: Specialized actors can be created on demand
2. **Actor Hierarchies**: Supervisory patterns can manage actor lifecycles
3. **Distributed Deployment**: Actors can be distributed across multiple hosts
4. **Actor Specialization**: New actor types can be added for specific capabilities
5. **Rust Migration**: Performance-critical actors can be reimplemented in Rust


## Actor Specialization
```python
class VideoActionActor(Actor[VideoActionState]):
    async def process(self, message: Message) -> Any:
        # Video-specific preprocessing
        video_analysis = await self.video_worker.process(message.content)
        return await self.experience_actor.process(
            Message(content=video_analysis)
        )

class FinancialExperienceActor(Actor[ExperienceState]):
    async def retrieve_context(self, query: str):
        # Specialized financial context retrieval
        return await self.financial_rag(query)
```

## Conclusion

The actor-based PostChain implementation provides a natural fit for agent-based AI systems, with clean separation of concerns, robust message passing, and flexible state management. This architecture resolves the fundamental challenges of state management in conversational AI, providing a foundation for scalable, resilient multi-agent systems.
