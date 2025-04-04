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

# Configure logging
logger = logging.getLogger("postchain_utils")


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
