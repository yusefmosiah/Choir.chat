"""
Utility functions for PostChain.

This module contains utility functions for the PostChain implementation,
including thread ID validation, state management, and formatting utilities.
"""

import uuid
import logging
from typing import Dict, Any, List, Optional

from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
from langgraph.checkpoint.memory import MemorySaver

from app.postchain.schemas.state import PostChainState

# Configure logging
logger = logging.getLogger("postchain_utils")

def validate_thread_id(thread_id: str) -> str:
    """
    Validate and normalize thread ID.

    Args:
        thread_id: The thread ID to validate

    Returns:
        A normalized UUID string

    If the thread ID is invalid or None, a new UUID is generated.
    """
    if not thread_id:
        return str(uuid.uuid4())

    # Check if valid UUID format
    try:
        uuid_obj = uuid.UUID(thread_id)
        return str(uuid_obj)
    except ValueError:
        # If not valid UUID, generate new one
        logger.warning(f"Invalid thread ID format: {thread_id}. Generating new UUID.")
        return str(uuid.uuid4())

def load_state(thread_id: str, user_query: str = None) -> PostChainState:
    """
    Load existing state or create new one.

    Args:
        thread_id: The thread ID to load state for
        user_query: Optional user query to add to the state

    Returns:
        The loaded or newly created PostChainState
    """
    thread_id = validate_thread_id(thread_id)
    memory = MemorySaver()
    memory_key = f"postchain_{thread_id}"

    # Configure thread for loading
    thread_config = {"configurable": {"thread_id": thread_id, "checkpoint_id": memory_key}}

    try:
        existing_state = memory.get_state(config=thread_config)
        if existing_state:
            # Log message count and types
            logger.info(f"Loaded thread {thread_id} with {len(existing_state.messages)} messages")

            # Log message details for debugging
            for i, msg in enumerate(existing_state.messages):
                msg_type = type(msg).__name__
                content_preview = msg.content[:50] if hasattr(msg, 'content') else "No content"
                phase = msg.additional_kwargs.get('phase') if hasattr(msg, 'additional_kwargs') else "No phase"
                logger.info(f"Message {i}: {msg_type}, phase={phase}, content={content_preview}...")

            # Add the new message if provided
            if user_query:
                existing_state.messages.append(HumanMessage(content=user_query))
                logger.info(f"Added new user message: {user_query[:50]}...")

            return existing_state
    except Exception as e:
        logger.error(f"Error loading state for thread {thread_id}: {e}")

    # Create new state if loading failed or no existing state
    logger.info(f"Creating new thread state for {thread_id}")
    initial_state = PostChainState(
        thread_id=thread_id,
        messages=[SystemMessage(content="You are a helpful AI assistant.")]
    )

    if user_query:
        initial_state.messages.append(HumanMessage(content=user_query))
        logger.info(f"Added initial user message: {user_query[:50]}...")

    return initial_state

def recover_state(thread_id: str) -> Optional[PostChainState]:
    """
    Attempt to recover state from interrupted conversation.

    Args:
        thread_id: The thread ID to recover state for

    Returns:
        The recovered PostChainState or None if recovery failed
    """
    thread_id = validate_thread_id(thread_id)
    memory = MemorySaver()
    memory_key = f"postchain_{thread_id}"

    # Configure thread for loading
    thread_config = {"configurable": {"thread_id": thread_id, "checkpoint_id": memory_key}}

    try:
        existing_state = memory.get_state(config=thread_config)
        if existing_state:
            # Mark any "processing" phases as "error" to indicate interruption
            for phase in existing_state.phase_state:
                if existing_state.phase_state[phase] == "processing":
                    existing_state.phase_state[phase] = "error"
                    existing_state.error = "Conversation was interrupted"

            return existing_state
    except Exception as e:
        logger.error(f"Error recovering state for thread {thread_id}: {e}")
        return None

    return None

def format_stream_event(state: PostChainState, content: str = None, error: str = None) -> Dict[str, Any]:
    """
    Format state for streaming to clients.

    Args:
        state: The current PostChainState
        content: Optional explicit content for the current phase (overrides message content)
        error: Optional error message

    Returns:
        A formatted event dictionary for streaming
    """
    # If content isn't provided, try to find it in messages for the current phase
    event_content = content

    if event_content is None and state.messages:
        # Look for messages with this phase in metadata
        for message in reversed(state.messages):
            if (isinstance(message, AIMessage) and
                hasattr(message, 'additional_kwargs') and
                message.additional_kwargs.get('phase') == state.current_phase):
                event_content = message.content
                break

    # Still no content, provide empty string
    if event_content is None:
        event_content = ""

    return {
        "current_phase": state.current_phase,
        "phase_state": state.phase_state.get(state.current_phase, "processing"),
        "content": event_content,
        "thread_id": state.thread_id,
        "error": error or state.error
    }

def handle_phase_error(state: PostChainState, phase: str, error: Exception) -> None:
    """
    Update state with error information for a specific phase.

    Args:
        state: The current PostChainState
        phase: The phase that encountered an error
        error: The exception that occurred
    """
    # Update phase state
    state.phase_state[phase] = "error"

    # Set error message
    state.error = str(error)

    # Log error
    logger.error(f"Error in {phase} phase: {error}")
