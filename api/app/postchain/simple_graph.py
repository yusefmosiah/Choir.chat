"""
Simple PostChain implementation using LangGraph with currently only the Action and Experience phases.

This module implements a simplified version of the PostChain with just the Action and Experience phases
using LangGraph's StateGraph for streaming results. This is intended as the first step
in the migration from Chorus Cycle to PostChain.

Notes on State Management:
--------------------------
We've implemented a custom StateManagerCheckpointer that integrates with our
ConversationStateManager for persistent storage. This allows state to be stored
in a way that persists across server restarts and can be synced with external
databases or file systems.

The implementation provides:
1. Complete implementation of LangGraph's checkpoint interface
2. Thread-safe state persistence and retrieval
3. Proper handling of all required LangGraph checkpoint methods including aput_writes
4. In-memory caching with optional disk persistence through ConversationStateManager

This ensures that conversation state is properly maintained across multiple interactions,
even if the server is restarted or the conversation spans multiple separate requests.
"""

from pydantic import BaseModel, Field
from typing import Dict, Any, Optional

import logging
import uuid
import copy
import json
from typing import Dict, Any, List, Optional, AsyncIterator, Union, Tuple, NamedTuple

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.messages.ai import AIMessageChunk

# LangGraph imports
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.base import BaseCheckpointSaver, CheckpointMetadata, CheckpointTuple
from langgraph.checkpoint.memory import MemorySaver
from langgraph.checkpoint.base import empty_checkpoint

# Local imports
from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    initialize_tool_compatible_model_list,
    get_model_provider,
    post_llm
)
from app.postchain.schemas.state import PostChainState
from app.postchain.utils import (
    validate_thread_id,
    load_state,
    recover_state,
    format_stream_event,
    handle_phase_error
)
from app.postchain.checkpointer import PostChainCheckpointer
# Add import for the global state manager
from app.postchain.state_manager import GLOBAL_STATE_MANAGER

# Configure logging
logger = logging.getLogger("postchain_simple")

# Define the structured output model for PostChain streaming
class PostchainStreamEvent(BaseModel):
    """
    Structured output model for PostChain streaming events.
    Provides a consistent data contract between backend and frontend.
    """
    # Core fields for all events
    current_phase: str = Field(..., description="Current active phase (action, experience, etc.)")
    phase_state: str = Field("in_progress", description="Phase state (in_progress, complete, error)")
    content: str = Field("", description="The current content for this phase")

    # Phase-specific metadata
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Phase-specific metadata")

    # Session information
    thread_id: Optional[str] = Field(None, description="Thread ID for persistence")
    error: Optional[str] = Field(None, description="Error message if applicable")

# Prompt templates for phases
COMMON_SYSTEM_PROMPT = """You are a helpful AI assistant for Choir's PostChain system.
You provide thoughtful and informative responses to user queries.
"""

ACTION_INSTRUCTION = """For this Action phase:
Your task is to provide a clear, informative initial response based on the user's query.
Do not use external tools or references at this stage - just respond with your best knowledge.
Keep your response concise and focused on the core question.

IMPORTANT: When responding to follow-up questions or references to previous parts of the conversation,
you MUST explicitly reference the content from previous messages. For example, if the user asks
"What was that number you mentioned earlier?", you should recall and specifically include
the exact number from your previous messages.

Always maintain context continuity between conversation turns.
"""

EXPERIENCE_INSTRUCTION = """For this Experience phase:
Review the user's query and the initial action response.
Your task is to provide a reflective analysis of the action response, adding deeper context and exploring related concepts.
Consider different angles or interpretations of the query that might not have been addressed in the initial response.
"""

# Define state type alias
MessagesState = Dict[str, Any]

def create_system_message() -> SystemMessage:
    """Create a system message with the common system prompt."""
    return SystemMessage(content=COMMON_SYSTEM_PROMPT)

def create_message_with_phase(content: str, phase: str = "action") -> AIMessage:
    """
    Create an AIMessage with phase metadata.

    Args:
        content: The message content
        phase: The phase identifier (action, experience, etc.)

    Returns:
        AIMessage with phase metadata
    """
    # Log the creation for debugging
    logger.info(f"Creating message for phase '{phase}' with content: {content[:50]}...")
    return AIMessage(content=content, additional_kwargs={"phase": phase})

def log_experience_content(content, prefix="Experience phase"):
    if content:
        logger.info(f"{prefix} streaming content: {len(content)} characters")
        logger.info(f"{prefix} content first 100 chars: {content[:100]}...")
    else:
        logger.warning(f"{prefix} content is empty! This will cause issues with the client display.")

# Define a StateMetadata class to properly store the metadata that LangGraph expects
class StateMetadata(NamedTuple):
    """Metadata for the state with proper structure for LangGraph."""
    config: Dict[str, Any] = {}
    iteration: int = 0
    step_metadata: Dict[str, Any] = {}

# Custom storage implementation that uses our ConversationStateManager
class StateManagerStorage:
    """Custom storage implementation that uses our ConversationStateManager"""

    def get(self, key: str) -> Optional[Dict[str, Any]]:
        """Get state from storage"""
        # Extract thread_id from key
        thread_id = key.split(":")[-1] if ":" in key else key
        logger.info(f"StateManagerStorage.get: Retrieving state for thread_id={thread_id}")
        state = GLOBAL_STATE_MANAGER.get_state(thread_id)

        if state:
            # Ensure we return a dict, not a PostChainState object
            if hasattr(state, 'dict') and callable(getattr(state, 'dict')):
                logger.info(f"StateManagerStorage.get: Converting PostChainState to dict for thread_id={thread_id}")
                return state.dict()
            logger.info(f"StateManagerStorage.get: State already in dict format for thread_id={thread_id}")
            return state

        logger.info(f"StateManagerStorage.get: No state found for thread_id={thread_id}")
        return None

    def put(self, key: str, value: Any) -> None:
        """Store state in storage"""
        # Extract thread_id from key
        thread_id = key.split(":")[-1] if ":" in key else key
        logger.info(f"StateManagerStorage.put: Saving state for thread_id={thread_id}")

        # Ensure thread_id is in the state
        if isinstance(value, dict) and "thread_id" not in value:
            value["thread_id"] = thread_id

        # Save state
        GLOBAL_STATE_MANAGER.save_state(value)
        logger.info(f"StateManagerStorage.put: State saved for thread_id={thread_id}")

    def delete(self, key: str) -> None:
        """Delete state from storage"""
        thread_id = key.split(":")[-1] if ":" in key else key
        logger.info(f"StateManagerStorage.delete: Deleting state for thread_id={thread_id}")
        GLOBAL_STATE_MANAGER.delete_state(thread_id)

    def list(self) -> List[str]:
        """List all keys in storage"""
        logger.info("StateManagerStorage.list: Listing all thread IDs")
        return GLOBAL_STATE_MANAGER.list_threads()

# Custom checkpoint saver that integrates with our state manager
class StateManagerCheckpointer(BaseCheckpointSaver):
    """LangGraph-compatible checkpointer using our ConversationStateManager"""

    def __init__(self):
        super().__init__()
        self.storage = StateManagerStorage()
        logger.info("StateManagerCheckpointer initialized")

    def _get_checkpoint_key(self, config: Dict[str, Any]) -> str:
        """Get the checkpoint key from the config."""
        thread_id = config.get("configurable", {}).get("thread_id")
        if not thread_id:
            raise ValueError("thread_id not found in config")
        return f"postchain:{thread_id}"

    def get(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Get state from storage."""
        key = self._get_checkpoint_key(config)
        thread_id = config.get("configurable", {}).get("thread_id")
        logger.info(f"StateManagerCheckpointer.get: Getting state for thread_id={thread_id}")

        state = self.storage.get(key)
        if state is None:
            logger.info(f"StateManagerCheckpointer.get: Creating new state for thread_id={thread_id}")
            return {"thread_id": thread_id}

        logger.info(f"StateManagerCheckpointer.get: Found existing state for thread_id={thread_id}")
        return state

    def put(
        self,
        config: Dict[str, Any],
        checkpoint: Any,
        metadata: Dict[str, Any],
        new_versions: Any,
    ) -> Dict[str, Any]:
        """
        Save state to storage with all required parameters.

        Args:
            config: Configuration dict with thread_id
            checkpoint: Checkpoint data (ignored in our implementation)
            metadata: Metadata dict (ignored in our implementation)
            new_versions: New channel versions (ignored in our implementation)

        Returns:
            Updated config
        """
        key = self._get_checkpoint_key(config)
        thread_id = config.get("configurable", {}).get("thread_id")
        logger.info(f"StateManagerCheckpointer.put: Saving state for thread_id={thread_id}")

        # Get the actual state from the config
        state = config.get("state", {})

        # Make sure we properly handle the state
        if not state:
            logger.warning(f"Empty state in config for thread_id={thread_id}")
            state = {"thread_id": thread_id}
        elif not isinstance(state, dict):
            # Convert to dict if it's a PostChainState
            if hasattr(state, 'dict') and callable(getattr(state, 'dict')):
                logger.info(f"Converting PostChainState to dict for thread_id={thread_id}")
                state = state.dict()
            else:
                logger.warning(f"Unexpected state type: {type(state)}, using as is")

        # Ensure thread_id is in the state
        if "thread_id" not in state:
            state["thread_id"] = thread_id

        # Log the state for debugging
        logger.info(f"State to save: {state.keys()}")
        if 'messages' in state:
            logger.info(f"Messages count: {len(state['messages'])}")

        # Save state
        self.storage.put(key, state)
        logger.info(f"StateManagerCheckpointer.put: State saved successfully for thread_id={thread_id}")

        # Update the config with the saved state - ensure we return the full state
        if 'state' not in config or not config['state']:
            config['state'] = state

        return config

    def put_writes(
        self,
        config: Dict[str, Any],
        writes: Any,
        task_id: str,
        task_path: str = "",
    ) -> None:
        """
        Store intermediate writes linked to a checkpoint.

        Args:
            config: Configuration of the related checkpoint
            writes: Sequence of writes to store
            task_id: ID of the task that generated the writes
            task_path: Optional path of the task
        """
        logger.info(f"StateManagerCheckpointer.put_writes: Called with {len(writes) if writes else 0} writes")
        # We don't need to implement this for our use case
        # Just log the call so we know it's being invoked
        pass

    def get_tuple(self, config: Dict[str, Any]) -> CheckpointTuple:
        """Get state and metadata as a CheckpointTuple."""
        state = self.get(config)
        thread_id = config.get("configurable", {}).get("thread_id")
        logger.info(f"StateManagerCheckpointer.get_tuple: Getting tuple for thread_id={thread_id}")

        # Create a CheckpointTuple with the required fields
        return CheckpointTuple(
            config=config,                    # Config dict
            checkpoint=empty_checkpoint(),    # Empty checkpoint structure
            metadata={"step": 0},             # Metadata dict with step
            parent_config=None,               # No parent config
            pending_writes=None               # No pending writes
        )

    async def aget(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Async version of get."""
        return self.get(config)

    async def aput(
        self,
        config: Dict[str, Any],
        checkpoint: Any,
        metadata: Dict[str, Any],
        new_versions: Any,
    ) -> Dict[str, Any]:
        """
        Async version of put with all required parameters.

        Args:
            config: Configuration dict with thread_id
            checkpoint: Checkpoint data (ignored in our implementation)
            metadata: Metadata dict (ignored in our implementation)
            new_versions: New channel versions (ignored in our implementation)

        Returns:
            Updated config
        """
        logger.info(f"StateManagerCheckpointer.aput: Called with checkpoint and metadata")
        return self.put(config, checkpoint, metadata, new_versions)

    async def aput_writes(
        self,
        config: Dict[str, Any],
        writes: Any,
        task_id: str,
        task_path: str = "",
    ) -> None:
        """
        Async version of put_writes.

        Args:
            config: Configuration of the related checkpoint
            writes: Sequence of writes to store
            task_id: ID of the task that generated the writes
            task_path: Optional path of the task
        """
        logger.info(f"StateManagerCheckpointer.aput_writes: Called with {len(writes) if writes else 0} writes")
        self.put_writes(config, writes, task_id, task_path)

    async def aget_tuple(self, config: Dict[str, Any]) -> CheckpointTuple:
        """Async version of get_tuple."""
        state = await self.aget(config)
        thread_id = config.get("configurable", {}).get("thread_id")
        logger.info(f"StateManagerCheckpointer.aget_tuple: Getting tuple for thread_id={thread_id}")

        # Create a CheckpointTuple with the required fields (same as get_tuple)
        return CheckpointTuple(
            config=config,                    # Config dict
            checkpoint=empty_checkpoint(),    # Empty checkpoint structure
            metadata={"step": 0},             # Metadata dict with step
            parent_config=None,               # No parent config
            pending_writes=None               # No pending writes
        )

def create_postchain_graph(
    thread_id: str = None,
    config: Optional[Config] = None,
    model_config: Optional[ModelConfig] = None,
    disabled_providers: Optional[set] = None
) -> StateGraph:
    """
    Create a LangGraph for a PostChain with Action and Experience phases.

    Args:
        thread_id: Optional thread ID for persistence
        config: Optional configuration object. Will use app config if None.
        model_config: Optional model configuration.
        disabled_providers: Optional set of disabled providers.

    Returns:
        A configured StateGraph for the Action and Experience phases.
    """
    # Validate thread ID
    thread_id = validate_thread_id(thread_id)
    logger.info(f"Creating PostChain graph for thread {thread_id}")

    # Get configuration if not provided
    if config is None:
        config = Config()

    # Set up the model for both phases
    if model_config:
        models = [model_config]  # Make sure it's in a list
        model = model_config
        logger.info(f"Using specified model {model_config} for all phases")
    else:
        # Initialize model list with any disabled providers
        try:
            models = initialize_tool_compatible_model_list(config, disabled_providers=disabled_providers)
        except Exception as e:
            logger.error(f"Error initializing models: {e}")
            models = []

        if not models or len(models) == 0:
            # No models available
            logger.error("No models available - check API keys and config")
            raise ValueError("No language models available. Please check API keys and configuration.")

        # Use the first available model
        model = models[1]
        logger.info(f"Using model: {model}")

    # Initialize the state graph with the new state model
    builder = StateGraph(PostChainState)
    logger.info("Initialized StateGraph with PostChainState")

    # Define Action Phase Node
    async def action_node(state: PostChainState):
        """
        Process the Action phase of the PostChain.

        Args:
            state: The current PostChainState

        Yields:
            Stream of state updates during processing
        """
        # Ensure thread_id is set in the state
        if not state.thread_id:
            state.thread_id = str(uuid.uuid4())
            logger.info(f"Setting thread_id in state to {state.thread_id}")
        else:
            logger.info(f"Using existing thread_id in state: {state.thread_id}")

        # Set phase to processing
        state.phase_state["action"] = "processing"

        # Log the state for debugging
        logger.info(f"Action node received state with {len(state.messages)} messages")
        for i, msg in enumerate(state.messages):
            try:
                msg_content = msg.content[:50] if hasattr(msg, 'content') else str(msg)[:50]
                logger.info(f"Message {i}: {type(msg).__name__} - {msg_content}...")
            except Exception as e:
                logger.warning(f"Error logging message {i}: {e}")

        # Get user input from state.messages
        user_input = ""
        if state.messages:
            for msg in reversed(state.messages):
                if isinstance(msg, HumanMessage):
                    user_input = msg.content
                    break

        if not user_input:
            logger.warning("No user input found in state.messages")
            user_input = "No input provided"

        yield format_stream_event(state, content="Processing your request...")

        try:
            # Prepend action instructions to the user input for the initial action phase
            enhanced_user_input = f"<action_instruction>{ACTION_INSTRUCTION}</action_instruction>\n\n{user_input}"

            # Create messages list with common system prompt and all prior messages
            messages = [create_system_message()]

            # Add all messages except the last user message (which we'll add with enhanced instructions)
            if len(state.messages) > 1:
                # Log the message history for debugging
                logger.info(f"Including {len(state.messages)-1} prior messages in action context")
                for msg in state.messages[:-1]:
                    # Convert any serialized messages to proper LangChain message objects
                    if not isinstance(msg, BaseMessage):
                        from app.langchain_utils import _convert_serialized_messages
                        msg = _convert_serialized_messages([msg])[0]
                    messages.append(msg)

            # Add the enhanced user input as the final message
            messages.append(HumanMessage(content=enhanced_user_input))

            # Convert model to a string format that post_llm expects
            model_name = f"{model.provider}/{model.model_name}" if hasattr(model, 'provider') and hasattr(model, 'model_name') else str(model)
            response = await post_llm(model_name, messages, config)

            # Get response content
            response_content = response.content if hasattr(response, 'content') else str(response)

            # Log the content for debugging
            logger.info(f"Action phase completed with content: {response_content[:100]}...")

            # Create AI message with phase metadata and add to state
            ai_message = create_message_with_phase(response_content, "action")
            state.messages.append(ai_message)
            logger.info(f"Added AI message to state, now have {len(state.messages)} messages")

            # Update phase state
            state.phase_state["action"] = "complete"

            # Create event with explicit content
            action_event = {
                "current_phase": "action",
                "phase_state": "complete",
                "content": response_content,
                "thread_id": state.thread_id
            }

            # Yield event with explicit content rather than using format_stream_event
            yield action_event

            # Update state for next phase
            state.phase_state = {**state.phase_state, "action": "complete"}
            state.current_phase = "experience"

            # Log final state
            logger.info(f"Action node final state has {len(state.messages)} messages")

            # Final yield with state updates
            yield state

        except Exception as e:
            # Handle error
            handle_phase_error(state, "action", e)

            # Yield error event
            yield format_stream_event(state, error=str(e))

            # Update state for error case
            state.phase_state = {**state.phase_state, "action": "error"}
            state.error = str(e)
            state.current_phase = "yield"  # Skip to end on error

            # Final yield with error state
            yield state

    # Define Experience Phase Node
    async def experience_node(state: PostChainState):
        """
        Process the Experience phase of the PostChain.

        Args:
            state: The current PostChainState

        Yields:
            Stream of state updates during processing
        """
        # Ensure thread_id is set in the state
        if not state.thread_id:
            state.thread_id = str(uuid.uuid4())
            logger.info(f"Setting thread_id in state to {state.thread_id}")
        else:
            logger.info(f"Using existing thread_id in state: {state.thread_id}")

        # Set phase to processing
        state.phase_state["experience"] = "processing"

        # Log the state for debugging
        logger.info(f"Experience node received state with {len(state.messages)} messages")
        for i, msg in enumerate(state.messages):
            try:
                msg_content = msg.content[:50] if hasattr(msg, 'content') else str(msg)[:50]
                logger.info(f"Message {i}: {type(msg).__name__} - {msg_content}...")
            except Exception as e:
                logger.warning(f"Error logging message {i}: {e}")

        yield format_stream_event(state, content="Enhancing response with deeper context...")

        try:
            # Get user input from last user message
            user_input = next((m.content for m in reversed(state.messages) if isinstance(m, HumanMessage)), "")

            # Get action response from last AI message
            action_response = next((m.content for m in reversed(state.messages) if isinstance(m, AIMessage)), "")

            # Prepend experience instructions to the input
            enhanced_user_input = f"""<experience_instruction>{EXPERIENCE_INSTRUCTION}</experience_instruction>

Original Query: {user_input}

Initial Action Response: {action_response}

Your task: Provide a reflective analysis adding deeper context.
"""
            # Create messages list with common system prompt and conversation history
            messages = [create_system_message()]

            # Include all prior messages to provide full context
            if len(state.messages) > 0:
                logger.info(f"Including {len(state.messages)} prior messages in experience context")
                for msg in state.messages:
                    # Convert any serialized messages to proper LangChain message objects
                    if not isinstance(msg, BaseMessage):
                        from app.langchain_utils import _convert_serialized_messages
                        msg = _convert_serialized_messages([msg])[0]
                    messages.append(msg)

            # Add experience instructions
            messages.append(HumanMessage(content=enhanced_user_input))

            # Convert model to a string format
            model_name = f"{model.provider}/{model.model_name}" if hasattr(model, 'provider') and hasattr(model, 'model_name') else str(model)
            response = await post_llm(model_name, messages, config)

            # Get response content
            response_content = response.content if hasattr(response, 'content') else str(response)

            # Log content for debugging
            log_experience_content(response_content)

            # Create AI message with phase metadata and add to state
            ai_message = create_message_with_phase(response_content, "experience")
            state.messages.append(ai_message)
            logger.info(f"Added experience AI message to state, now have {len(state.messages)} messages")

            # Update phase state
            state.phase_state["experience"] = "complete"

            # Create event with explicit content
            experience_event = {
                "current_phase": "experience",
                "phase_state": "complete",
                "content": response_content,
                "thread_id": state.thread_id
            }

            # Yield event with explicit content
            yield experience_event

            # Update state for next phase (which would be END)
            state.phase_state = {**state.phase_state, "experience": "complete"}
            state.current_phase = "yield"  # No more phases, so yield for now

            # Log final state
            logger.info(f"Experience node final state has {len(state.messages)} messages")

            # Final yield with state updates
            yield state

        except Exception as e:
            # Handle error
            handle_phase_error(state, "experience", e)

            # Yield error event
            yield format_stream_event(state, error=str(e))

            # Update state for error case
            state.phase_state = {**state.phase_state, "experience": "error"}
            state.error = str(e)
            state.current_phase = "yield"  # Skip to end on error

            # Final yield with error state
            yield state

    # Add nodes to the graph
    builder.add_node("action", action_node)
    builder.add_node("experience", experience_node)

    # Add edges
    builder.add_edge("action", "experience")
    builder.add_edge("experience", END)

    # Set entry point
    builder.set_entry_point("action")

    # Use our custom state manager for persistence
    checkpointer = StateManagerCheckpointer()
    logger.info(f"Using StateManagerCheckpointer for thread {thread_id}")

    # Compile graph with the custom checkpointer
    graph = builder.compile(checkpointer=checkpointer)

    # Thread config just needs thread_id
    thread_config = {"configurable": {"thread_id": thread_id}}

    return graph

async def stream_simple_postchain(
    query: str,
    config: Optional[Config] = None,
    thread_id: Optional[str] = None,
    model_config: Optional[ModelConfig] = None,
    disabled_providers: Optional[set] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Stream results from a PostChain with Action and Experience phases.

    Args:
        query: User query text
        config: Optional configuration object. Will use app config if None.
        thread_id: Optional thread ID for persistence. Will generate if None.
        model_config: Optional explicit model configuration to use.
        disabled_providers: Optional set of disabled providers.

    Yields:
        Stream of structured events for the client
    """
    # Validate thread ID
    thread_id = validate_thread_id(thread_id)
    logger.info(f"Starting PostChain with query: {query[:50]}...")

    # Create the post chain graph
    graph = create_postchain_graph(thread_id, config, model_config, disabled_providers)

    # Initial human message
    human_message = HumanMessage(content=query)

    # Create initial state
    initial_state = PostChainState(
        messages=[human_message],
        current_phase="action",
        thread_id=thread_id,
        phase_state={"action": "pending", "experience": "pending"}
    )

    # Check if we have an existing state for this thread
    existing_state = GLOBAL_STATE_MANAGER.get_state(thread_id)
    if existing_state and existing_state.messages:
        logger.info(f"Found existing state with {len(existing_state.messages)} messages for thread {thread_id}")
        # Add the new query to the existing messages
        existing_state.messages.append(human_message)
        # Update the phase state
        existing_state.phase_state = {"action": "pending", "experience": "pending"}
        existing_state.current_phase = "action"
        # Use the existing state with the new message
        initial_state = existing_state
    else:
        # Save the initial state to ensure it's persisted
        logger.info(f"No existing state found, saving initial state with {len(initial_state.messages)} messages")
        GLOBAL_STATE_MANAGER.save_state(initial_state)

    # Run the graph with initial state
    async for event in graph.astream(initial_state, {"thread_id": thread_id}):
        # Format and yield each update
        if "messages" in event and isinstance(event["messages"], list):
            # Process messages if present in the event
            for message in event["messages"]:
                if hasattr(message, 'content') and message.content:
                    try:
                        # Extract phase from additional_kwargs if available
                        phase = message.additional_kwargs.get("phase", "unknown") if hasattr(message, 'additional_kwargs') else "unknown"
                        logger.info(f"Received message for phase {phase} with content: {message.content[:50]}...")

                        # Format and yield
                        temp_state = PostChainState(
                            messages=initial_state.messages + [message],
                            current_phase=phase,
                            thread_id=thread_id
                        )
                        yield format_stream_event(temp_state, content=message.content)
                    except Exception as e:
                        logger.error(f"Error processing message: {e}")
        else:
            # Process node updates
            if isinstance(event, dict):
                # For debug purposes
                logger.info(f"Received chunk: {event}")

                # Process node outputs
                for node, update in event.items():
                    if isinstance(update, dict) and "messages" in update:
                        messages = update["messages"]
                        logger.info(f"Processing node {node} updates: {messages}")

                        # Find any content in messages
                        content = ""
                        for msg in messages:
                            if hasattr(msg, 'content') and msg.content:
                                content = msg.content
                                logger.info(f"Found content in messages: {content[:50]}...")
                                break

                        # Update the global state with the new messages
                        if messages:
                            logger.info(f"Updating global state with {len(messages)} messages")
                            state_to_save = PostChainState(
                                messages=messages,
                                current_phase=node,
                                thread_id=thread_id,
                                phase_state={node: "complete"}
                            )
                            GLOBAL_STATE_MANAGER.save_state(state_to_save)

                        if node == "action":
                            logger.info(f"Found action output: {content[:50]}...")
                            temp_state = PostChainState(
                                messages=messages if isinstance(messages, list) else [],
                                current_phase="action",
                                thread_id=thread_id,
                                phase_state={"action": "complete"}
                            )
                            yield format_stream_event(temp_state, content=content)
                        elif node == "experience":
                            temp_state = PostChainState(
                                messages=messages if isinstance(messages, list) else [],
                                current_phase="experience",
                                thread_id=thread_id,
                                phase_state={"experience": "complete"}
                            )
                            yield format_stream_event(temp_state, content=content)

    # Final yield for completion
    final_state = PostChainState(
        current_phase="complete",
        thread_id=thread_id,
        messages=[]
    )
    yield format_stream_event(final_state, content="")
