from typing import Any, Callable, Dict, List, Optional, Type, TypeVar, Generic, Union
import asyncio
from pydantic import BaseModel, Field
import uuid
import logging
from datetime import datetime
from enum import Enum, auto


# Base message type for actor communication
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


# Actor state management
class ActorState(BaseModel):
    """Base class for actor-specific state"""
    pass


T = TypeVar('T', bound=ActorState)
M = TypeVar('M', bound=Message)


class Actor(Generic[T]):
    """Base Actor implementation following the actor model pattern"""

    def __init__(self, name: str, initial_state: Optional[T] = None):
        self.name = name
        self.state = initial_state
        self.mailbox: asyncio.Queue[Message] = asyncio.Queue()
        self.handlers: Dict[MessageType, Callable] = {}
        self.logger = logging.getLogger(f"actor.{name}")

    async def send(self, recipient: 'Actor', message_type: MessageType, content: Any,
                   correlation_id: Optional[str] = None) -> str:
        """Send a message to another actor"""
        message = Message(
            type=message_type,
            sender=self.name,
            recipient=recipient.name,
            content=content,
            correlation_id=correlation_id
        )
        await recipient.mailbox.put(message)
        self.logger.debug(f"Sent message {message.id} to {recipient.name}")
        return message.id

    async def receive(self) -> Message:
        """Receive the next message from the mailbox"""
        message = await self.mailbox.get()
        self.logger.debug(f"Received message {message.id} from {message.sender}")
        return message

    def register_handler(self, message_type: MessageType, handler: Callable[[Message], Any]):
        """Register a handler for a specific message type"""
        self.handlers[message_type] = handler

    async def process_next_message(self) -> Any:
        """Process the next message in the mailbox using registered handlers"""
        message = await self.receive()

        if message.type in self.handlers:
            try:
                result = await self.handlers[message.type](message)
                return result
            except Exception as e:
                self.logger.error(f"Error processing message {message.id}: {str(e)}")
                return None
        else:
            self.logger.warning(f"No handler for message type {message.type}")
            return None

    async def run(self):
        """Run the actor's message processing loop"""
        self.logger.info(f"Actor {self.name} starting")
        while True:
            await self.process_next_message()


# Example Post Chain Actors

class ActionState(ActorState):
    """State for the Action actor"""
    messages: List[Dict[str, Any]] = Field(default_factory=list)
    current_input: Optional[str] = None


class ActionActor(Actor[ActionState]):
    """Handles the Action phase of the Post Chain"""

    def __init__(self, name: str = "action"):
        super().__init__(name, ActionState())
        self.register_handler(MessageType.REQUEST, self.handle_request)

    async def handle_request(self, message: Message) -> Any:
        """Process a user input request"""
        user_input = message.content

        # Update state
        if self.state:
            self.state.current_input = user_input
            self.state.messages.append({"role": "user", "content": user_input})

        # In a real implementation, this would call an LLM
        response = f"Processed in Action phase: {user_input}"

        # Forward to next actor in the chain
        # This is where you'd implement the actual Post Chain logic

        return response


# A centralized actor system for managing actors

class ActorSystem:
    """Manages the lifecycle and references of actors"""

    def __init__(self):
        self.actors: Dict[str, Actor] = {}

    def register_actor(self, actor: Actor):
        """Register an actor with the system"""
        self.actors[actor.name] = actor

    def get_actor(self, name: str) -> Optional[Actor]:
        """Get an actor by name"""
        return self.actors.get(name)

    async def send_message(self, sender: str, recipient: str,
                          message_type: MessageType, content: Any) -> Optional[str]:
        """Send a message between registered actors"""
        sender_actor = self.get_actor(sender)
        recipient_actor = self.get_actor(recipient)

        if not sender_actor or not recipient_actor:
            return None

        return await sender_actor.send(recipient_actor, message_type, content)

    async def run_all(self):
        """Run all registered actors"""
        await asyncio.gather(*(actor.run() for actor in self.actors.values()))


# Example Post Chain implementation

class PostChain:
    """Implements the AEIOU-Y Post Chain pattern using actors"""

    def __init__(self):
        self.system = ActorSystem()

        # Initialize all actors in the chain
        self.action = ActionActor()
        # Add other actors: Experience, Intention, Observation, Understanding, Yield

        # Register with the system
        self.system.register_actor(self.action)
        # Register other actors

    async def process_input(self, user_input: str) -> str:
        """Process user input through the full chain"""
        # In a complete implementation, this would coordinate the full AEIOU-Y flow
        # For now, we just demonstrate the action phase
        await self.system.send_message(
            "system",
            self.action.name,
            MessageType.REQUEST,
            user_input
        )

        # This is a simplification - in reality, you'd need to track the message
        # through the system and wait for the final response
        return "Response from Post Chain"

    async def run(self):
        """Run the Post Chain system"""
        await self.system.run_all()


# Example with libsql/turso integration

class TursoStorage(BaseModel):
    """Integration with libsql/turso for state persistence and RAG"""
    connection_string: str

    async def save_state(self, actor_name: str, state: ActorState):
        """Save actor state to the database"""
        # Implementation would use libsql to store the state
        # This is a placeholder
        pass

    async def load_state(self, actor_name: str, state_type: Type[ActorState]) -> Optional[ActorState]:
        """Load actor state from the database"""
        # Implementation would use libsql to retrieve the state
        # This is a placeholder
        return None

    async def perform_rag_query(self, query: str) -> List[Dict[str, Any]]:
        """Perform a RAG query against the stored data"""
        # Implementation would combine SQL and vector search
        # This is a placeholder
        return []
