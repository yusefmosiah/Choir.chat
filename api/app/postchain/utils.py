"""
Utility functions for PostChain.

This module contains utility functions for the PostChain implementation,
including thread ID validation, state management, and formatting utilities.
"""

import uuid
import logging
import json
import os
from typing import Dict, Any, List, Optional, Union

from langchain_core.messages import SystemMessage, HumanMessage, AIMessage

from app.postchain.schemas.state import PostChainState
# from app.postchain.state_manager import GLOBAL_STATE_MANAGER # Removed state_manager import

# Configure logging
logger = logging.getLogger("postchain_utils")

STATE_STORAGE_DIR = "thread_state" # Define directory for thread state storage

def save_state(state: PostChainState) -> bool:
    """Save PostChainState to a JSON file."""
    thread_id = state.thread_id
    if not thread_id:
        logger.warning("Attempted to save state with no thread_id")
        return False

    # Ensure storage directory exists
    if not os.path.exists(STATE_STORAGE_DIR):
        os.makedirs(STATE_STORAGE_DIR, exist_ok=True)

    filepath = os.path.join(STATE_STORAGE_DIR, f"{thread_id}.json")
    try:
        with open(filepath, 'w') as f:
            json.dump(state.dict(), f, indent=2)
        logger.debug(f"Saved state for thread {thread_id} to disk")
        return True
    except Exception as e:
        logger.error(f"Error saving state to disk for thread {thread_id}: {e}", exc_info=True)
        return False

def recover_state(thread_id: str) -> Optional[PostChainState]:
    """Recover PostChainState from a JSON file."""
    thread_id = validate_thread_id(thread_id)
    filepath = os.path.join(STATE_STORAGE_DIR, f"{thread_id}.json")

    if not os.path.exists(filepath):
        logger.debug(f"No state file found on disk for thread {thread_id}")
        return None

    try:
        with open(filepath, 'r') as f:
            state_dict = json.load(f)
            loaded_state = PostChainState.parse_obj(state_dict) # Load state directly from dict
            logger.info(f"Recovered state from disk for thread {thread_id} with {len(loaded_state.messages)} messages")
            return loaded_state
    except FileNotFoundError:
        logger.debug(f"No state file found on disk for thread {thread_id}")
        return None
    except json.JSONDecodeError:
        logger.error(f"JSONDecodeError while loading state for thread {thread_id}, state file possibly corrupted. Returning None.", exc_info=True)
    except Exception as e:
        logger.error(f"Error loading state from disk for thread {thread_id}: {e}", exc_info=True)
    return None

def delete_state(thread_id: str) -> bool: # Add delete_state function
    """Delete state file for a thread."""
    thread_id = validate_thread_id(thread_id)
    filepath = os.path.join(STATE_STORAGE_DIR, f"{thread_id}.json")
    try:
        if os.path.exists(filepath):
            os.remove(filepath)
            logger.info(f"Deleted state file for thread {thread_id} from disk")
            return True
        logger.info(f"No state file found to delete for thread {thread_id}")
        return False
    except Exception as e:
        logger.error(f"Error deleting state file for thread {thread_id}: {e}", exc_info=True)
        return False


def validate_thread_id(thread_id: str) -> str:
    """Validate and return a thread_id string.

    Args:
        thread_id: The thread ID to validate

    Returns:
        The validated thread_id

    Raises:
        ValueError: If thread_id is not a valid UUID string
    """
    try:
        uuid.UUID(thread_id)
        return thread_id
    except ValueError:
        logger.error(f"Invalid thread_id format: {thread_id}")
        raise ValueError(f"Invalid thread_id format: {thread_id}")


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
