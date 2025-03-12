from typing import Any, Dict, List, Optional, Union
import asyncio
from pydantic import BaseModel, Field
from actor_model import Actor, ActorState, ActorSystem, Message, MessageType, TursoStorage

# Define state for each actor in the chain

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


# Define the actors for each stage in the Post Chain

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


class ExperienceActor(Actor[ExperienceState]):
    """Handles the Experience phase - enriches with prior knowledge"""

    def __init__(self, intention_actor: Optional['IntentionActor'] = None):
        super().__init__("experience", ExperienceState())
        self.register_handler(MessageType.REQUEST, self.handle_request)
        self.intention_actor = intention_actor

    async def handle_request(self, message: Message) -> Any:
        """Enrich with prior knowledge"""
        data = message.content
        user_input = data.get("user_input", "")
        initial_response = data.get("initial_response", "")

        # In a real implementation, this would perform RAG queries
        # to retrieve relevant knowledge
        retrieved_context = [
            {"source": "knowledge_base", "content": f"Relevant context for: {user_input}"}
        ]

        if self.state:
            self.state.retrieved_context = retrieved_context

        enriched_response = f"Enriched with context: {initial_response}"

        # Pass to Intention actor if available
        if self.intention_actor and message.correlation_id:
            await self.send(
                self.intention_actor,
                MessageType.REQUEST,
                {
                    "user_input": user_input,
                    "initial_response": initial_response,
                    "enriched_response": enriched_response,
                    "context": retrieved_context
                },
                correlation_id=message.correlation_id
            )

        return enriched_response


class IntentionActor(Actor[IntentionState]):
    """Handles the Intention phase - aligns with user intent"""

    def __init__(self, observation_actor: Optional['ObservationActor'] = None):
        super().__init__("intention", IntentionState())
        self.register_handler(MessageType.REQUEST, self.handle_request)
        self.observation_actor = observation_actor

    async def handle_request(self, message: Message) -> Any:
        """Align with user intent"""
        data = message.content
        user_input = data.get("user_input", "")
        enriched_response = data.get("enriched_response", "")

        # In a real implementation, this would analyze user intent
        detected_intent = f"Intent for: {user_input}"

        if self.state:
            self.state.current_intent = detected_intent
            self.state.user_intents.append(detected_intent)

        aligned_response = f"Aligned with intent: {enriched_response}"

        # Pass to Observation actor if available
        if self.observation_actor and message.correlation_id:
            await self.send(
                self.observation_actor,
                MessageType.REQUEST,
                {
                    "user_input": user_input,
                    "aligned_response": aligned_response,
                    "intent": detected_intent
                },
                correlation_id=message.correlation_id
            )

        return aligned_response


class ObservationActor(Actor[ObservationState]):
    """Handles the Observation phase - records semantic connections"""

    def __init__(self, understanding_actor: Optional['UnderstandingActor'] = None):
        super().__init__("observation", ObservationState())
        self.register_handler(MessageType.REQUEST, self.handle_request)
        self.understanding_actor = understanding_actor

    async def handle_request(self, message: Message) -> Any:
        """Record semantic connections"""
        data = message.content
        user_input = data.get("user_input", "")
        aligned_response = data.get("aligned_response", "")

        # In a real implementation, this would extract and record
        # semantic connections from the conversation
        observation = f"Observed patterns in: {user_input}"
        semantic_connection = {
            "input": user_input,
            "observation": observation,
            "timestamp": "2023-01-01T00:00:00Z"  # Would be actual timestamp
        }

        if self.state:
            self.state.observations.append(observation)
            self.state.semantic_connections.append(semantic_connection)

        observed_response = f"Observed: {aligned_response}"

        # Pass to Understanding actor if available
        if self.understanding_actor and message.correlation_id:
            await self.send(
                self.understanding_actor,
                MessageType.REQUEST,
                {
                    "user_input": user_input,
                    "observed_response": observed_response,
                    "semantic_connections": [semantic_connection]
                },
                correlation_id=message.correlation_id
            )

        return observed_response


class UnderstandingActor(Actor[UnderstandingState]):
    """Handles the Understanding phase - decides on continuation"""

    def __init__(self, yield_actor: Optional['YieldActor'] = None):
        super().__init__("understanding", UnderstandingState())
        self.register_handler(MessageType.REQUEST, self.handle_request)
        self.yield_actor = yield_actor

    async def handle_request(self, message: Message) -> Any:
        """Decide whether to continue the chain"""
        data = message.content
        user_input = data.get("user_input", "")
        observed_response = data.get("observed_response", "")

        # In a real implementation, this would make a decision about
        # whether to continue processing or finalize
        decision = {
            "input": user_input,
            "continue": True,
            "reason": "More processing needed"
        }

        if self.state:
            self.state.decisions.append(decision)
            self.state.continue_chain = decision["continue"]

        understood_response = f"Understanding complete: {observed_response}"

        # Pass to Yield actor if available
        if self.yield_actor and message.correlation_id:
            await self.send(
                self.yield_actor,
                MessageType.REQUEST,
                {
                    "user_input": user_input,
                    "understood_response": understood_response,
                    "decision": decision
                },
                correlation_id=message.correlation_id
            )

        return understood_response


class YieldActor(Actor[YieldState]):
    """Handles the Yield phase - produces final response"""

    def __init__(self):
        super().__init__("yield", YieldState())
        self.register_handler(MessageType.REQUEST, self.handle_request)

    async def handle_request(self, message: Message) -> Any:
        """Produce the final response"""
        data = message.content
        user_input = data.get("user_input", "")
        understood_response = data.get("understood_response", "")

        # In a real implementation, this would generate the final,
        # polished response to return to the user
        final_response = f"Final response for '{user_input}': {understood_response}"

        if self.state:
            self.state.current_response = final_response
            self.state.final_responses.append({
                "input": user_input,
                "response": final_response,
                "timestamp": "2023-01-01T00:00:00Z"  # Would be actual timestamp
            })

        # In a complete implementation, this would be returned to a user-facing component
        return final_response


# The complete Post Chain implementation

class PostChain:
    """Implements the AEIOU-Y Post Chain pattern using actors"""

    def __init__(self, storage: Optional[TursoStorage] = None):
        self.system = ActorSystem()
        self.storage = storage

        # Initialize all actors in reverse order to establish connections
        self.yield_actor = YieldActor()
        self.understanding_actor = UnderstandingActor(self.yield_actor)
        self.observation_actor = ObservationActor(self.understanding_actor)
        self.intention_actor = IntentionActor(self.observation_actor)
        self.experience_actor = ExperienceActor(self.intention_actor)
        self.action_actor = ActionActor(self.experience_actor)

        # Register with the system
        self.system.register_actor(self.action_actor)
        self.system.register_actor(self.experience_actor)
        self.system.register_actor(self.intention_actor)
        self.system.register_actor(self.observation_actor)
        self.system.register_actor(self.understanding_actor)
        self.system.register_actor(self.yield_actor)

        # Create a special system actor for initiating processes
        self.system.actors["system"] = Actor("system")

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
        )

        # This is a simplification - in a real implementation, you would:
        # 1. Track the message through the system using correlation_id
        # 2. Set up a future/promise to wait for the final response
        # 3. Return when the Yield actor completes

        # For now, we'll just simulate waiting for the chain to complete
        await asyncio.sleep(1)  # In reality, you'd wait for the completion signal

        # In a real implementation, you'd fetch the actual response from the Yield actor
        if self.yield_actor.state and self.yield_actor.state.current_response:
            return self.yield_actor.state.current_response
        return "Processing complete (default response)"

    async def save_state(self):
        """Save the state of all actors to storage"""
        if not self.storage:
            return

        # Save the state of each actor
        for actor_name, actor in self.system.actors.items():
            if actor.state:
                await self.storage.save_state(actor_name, actor.state)

    async def run(self):
        """Run the Post Chain system"""
        await self.system.run_all()


# Example usage

async def main():
    # Initialize storage with connection string
    storage = TursoStorage(connection_string="libsql://example.turso.io")

    # Create the Post Chain
    chain = PostChain(storage)

    # Process a user input
    response = await chain.process_input("Tell me about the actor model")
    print(f"Response: {response}")

    # Save state
    await chain.save_state()


if __name__ == "__main__":
    asyncio.run(main())
