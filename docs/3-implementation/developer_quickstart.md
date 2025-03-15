# Developer Quickstart Guide: Choir Actor Model

This guide provides a fast onboarding path for developers to start working with Choir's actor-based architecture. It covers environment setup, basic actor implementation, message flow, and debugging techniques.

## Prerequisites

- Python 3.10+
- Docker (for containerized deployment)
- Git
- Basic understanding of asynchronous programming in Python
- Familiarity with the actor model concept (see [Actor Model Overview](../1-concepts/actor_model_overview.md))

## Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/choir.git
cd choir
```

### 2. Create a Virtual Environment

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Install Development Tools

```bash
pip install pytest pytest-asyncio pytest-cov black mypy
```

### 5. Initialize Configuration

```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

## Basic Actor Implementation

Let's create a simple actor to understand the basics of the actor model in Choir:

### 1. Create Actor State Class

First, define a state class for your actor using Pydantic:

```python
# myactor/state.py
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field

class SimpleActorState(BaseModel):
    """State class for a simple actor"""
    messages: List[Dict[str, Any]] = Field(default_factory=list)
    counter: int = 0
    last_message: Optional[str] = None
```

### 2. Implement Actor Class

Next, implement the actor that uses this state:

```python
# myactor/actor.py
from typing import Any, Dict, List, Optional
from thespian.actors import Actor as ThespianActor
import uuid
from datetime import datetime

from choir.common.message import Message, MessageType
from .state import SimpleActorState

class SimpleActor:
    """A simple actor implementation"""

    def __init__(self, name: str, initial_state: Optional[SimpleActorState] = None):
        self.name = name
        self.state = initial_state or SimpleActorState()

    async def process(self, message: Message) -> Any:
        """Process an incoming message"""
        # Update the state based on the message
        if self.state:
            self.state.counter += 1
            self.state.last_message = str(message.content)
            self.state.messages.append({
                "timestamp": datetime.now().isoformat(),
                "content": message.content,
                "type": message.type.value
            })

        # Return a simple response
        return f"Processed message: {message.content} (count: {self.state.counter})"

    async def send(self, target_actor, message_type: MessageType, content: Any,
                   correlation_id: Optional[str] = None) -> None:
        """Send a message to another actor"""
        message = Message(
            id=str(uuid.uuid4()),
            type=message_type,
            sender=self.name,
            recipient=target_actor.name,
            content=content,
            correlation_id=correlation_id
        )

        # In a real implementation, this would use the actor system to deliver the message
        return await target_actor.process(message)
```

## Creating an Actor System

To connect multiple actors, we need to set up an actor system:

```python
# myactor/system.py
from typing import Dict, Optional, Any
import uuid
from choir.common.message import Message, MessageType

class SimpleActorSystem:
    """A basic actor system implementation for demonstration"""

    def __init__(self):
        self.actors = {}

    def register_actor(self, actor):
        """Register an actor with the system"""
        self.actors[actor.name] = actor

    async def send_message(self, sender: str, recipient: str,
                          message_type: MessageType, content: Any,
                          correlation_id: Optional[str] = None) -> Any:
        """Send a message from one actor to another"""
        if recipient not in self.actors:
            raise ValueError(f"Actor {recipient} not found")

        message = Message(
            id=str(uuid.uuid4()),
            type=message_type,
            sender=sender,
            recipient=recipient,
            content=content,
            correlation_id=correlation_id or f"corr-{uuid.uuid4()}"
        )

        return await self.actors[recipient].process(message)
```

## Example: Simple PostChain Implementation

Let's implement a simplified version of the PostChain with just two actors:

```python
# example.py
import asyncio
from myactor.actor import SimpleActor
from myactor.system import SimpleActorSystem
from choir.common.message import MessageType

async def main():
    # Create actor system
    system = SimpleActorSystem()

    # Create actors
    action_actor = SimpleActor("action")
    response_actor = SimpleActor("response")

    # Register actors with the system
    system.register_actor(action_actor)
    system.register_actor(response_actor)

    # Process a user message through the mini-chain
    user_input = "Hello, Choir!"
    correlation_id = "example-correlation-id"

    # Send message to action actor
    action_result = await system.send_message(
        "user",
        "action",
        MessageType.REQUEST,
        user_input,
        correlation_id
    )
    print(f"Action result: {action_result}")

    # Send result to response actor
    final_result = await system.send_message(
        "action",
        "response",
        MessageType.REQUEST,
        action_result,
        correlation_id
    )
    print(f"Final result: {final_result}")

# Run the example
if __name__ == "__main__":
    asyncio.run(main())
```

Run the example:

```bash
python example.py
```

## Connecting to libSQL Database

For state persistence, integrate with libSQL/Turso:

```python
# myactor/persistence.py
import asyncio
from typing import Optional, Type, Any
import json
import libsql_client
from pydantic import BaseModel

class StateManager:
    """Manages actor state persistence with libSQL"""

    def __init__(self, db_url: str, auth_token: Optional[str] = None):
        self.db_url = db_url
        self.auth_token = auth_token
        self.client = None

    async def connect(self):
        """Connect to the libSQL database"""
        if not self.client:
            self.client = libsql_client.create_client(
                url=self.db_url,
                auth_token=self.auth_token
            )

        # Create the state table if it doesn't exist
        await self.client.execute("""
            CREATE TABLE IF NOT EXISTS actor_state (
                actor_name TEXT PRIMARY KEY,
                state_json TEXT,
                updated_at INTEGER
            )
        """)

    async def save_state(self, actor_name: str, state: BaseModel):
        """Save an actor's state to the database"""
        if not self.client:
            await self.connect()

        # Convert state to JSON
        state_json = state.model_dump_json()

        # Save to database
        await self.client.execute(
            "INSERT OR REPLACE INTO actor_state (actor_name, state_json, updated_at) VALUES (?, ?, unixepoch())",
            [actor_name, state_json]
        )

    async def load_state(self, actor_name: str, state_class: Type[BaseModel]) -> Optional[BaseModel]:
        """Load an actor's state from the database"""
        if not self.client:
            await self.connect()

        # Query the database
        result = await self.client.execute(
            "SELECT state_json FROM actor_state WHERE actor_name = ?",
            [actor_name]
        )

        rows = result.rows
        if not rows:
            return None

        # Deserialize the state
        state_json = rows[0][0]
        return state_class.model_validate_json(state_json)
```

## Understanding Message Flow

Messages flow through the actor system as follows:

1. **Creation**: Messages are created with a specified sender, recipient, and content
2. **Routing**: The actor system delivers messages to recipient actors' mailboxes
3. **Processing**: Actors process messages and update their state
4. **Response**: Actors can send response messages to other actors

Messages are traced through the system using correlation IDs, allowing you to track a request through multiple actors.

## Testing Actors

Testing actors is straightforward with pytest and pytest-asyncio:

```python
# test_simple_actor.py
import pytest
import asyncio
from choir.common.message import Message, MessageType
from myactor.actor import SimpleActor

@pytest.mark.asyncio
async def test_simple_actor_processes_message():
    # Arrange
    actor = SimpleActor("test_actor")
    test_message = Message(
        id="test-id",
        type=MessageType.REQUEST,
        sender="test_sender",
        recipient="test_actor",
        content="Hello, test!"
    )

    # Act
    result = await actor.process(test_message)

    # Assert
    assert "Processed message: Hello, test!" in result
    assert actor.state.counter == 1
    assert actor.state.last_message == "Hello, test!"
    assert len(actor.state.messages) == 1
```

Run the tests:

```bash
pytest -xvs test_simple_actor.py
```

## Debugging Techniques

### 1. Message Logging

Add logging to track message flow:

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LoggingActorSystem(SimpleActorSystem):
    async def send_message(self, sender, recipient, message_type, content, correlation_id=None):
        logger.info(f"Message {message_type.value} from {sender} to {recipient}: {content[:50]}...")
        return await super().send_message(sender, recipient, message_type, content, correlation_id)
```

### 2. State Inspection

Add methods to inspect actor state:

```python
class DebuggableActor(SimpleActor):
    def get_state_snapshot(self):
        """Get a snapshot of the current actor state"""
        return self.state.model_dump() if self.state else None

    async def process(self, message):
        result = await super().process(message)
        print(f"Actor {self.name} state after processing: {self.get_state_snapshot()}")
        return result
```

### 3. Message Tracing

Implement a message tracer:

```python
class MessageTracer:
    def __init__(self):
        self.traces = {}

    def trace_message(self, message):
        """Record a message in the trace"""
        if message.correlation_id not in self.traces:
            self.traces[message.correlation_id] = []

        self.traces[message.correlation_id].append({
            "timestamp": datetime.now().isoformat(),
            "message_id": message.id,
            "sender": message.sender,
            "recipient": message.recipient,
            "type": message.type.value,
            "content_summary": str(message.content)[:100]
        })

    def get_trace(self, correlation_id):
        """Get the trace for a correlation ID"""
        return self.traces.get(correlation_id, [])
```

## Next Steps

Now that you understand the basics of working with Choir's actor-based architecture, you can:

1. Explore the full PostChain implementation in the codebase
2. Learn about the [Phase Worker Pool](../2-architecture/phase_worker_pools.md) pattern
3. Implement specialized actors for different modalities
4. Study the [Message Protocol Reference](../message_protocol_reference.md) for more details
5. Understand [State Management Patterns](state_management_patterns.md) for advanced state handling

---

This quickstart guide provides a foundation for working with Choir's actor-based architecture. For more detailed information, refer to the comprehensive documentation sections.
