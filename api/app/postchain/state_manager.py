"""
Custom state management for PostChain conversations.

This module provides a custom state persistence layer for PostChain conversations,
ensuring reliable state management across API calls and conversation turns.
"""

import logging
import threading
import uuid
import json
import os
import time
from typing import Dict, Any, List, Optional, TypedDict
import copy

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage

# Import PostChainState type, but only the type using TYPE_CHECKING to avoid circular imports
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.postchain.simple_graph import PostChainState
else:
    # Create a compatible type alias for runtime use
    from typing import Dict, TypedDict, List, Optional, Any
    class PostChainState(TypedDict, total=False):
        messages: List[BaseMessage]  # Conversation history
        thread_id: str  # Thread identifier
        metadata: Dict[str, Any]  # Metadata storage
        error: Optional[str]  # Error message if any

# Set up logging
logger = logging.getLogger("postchain_state_manager")

class ConversationStateManager:
    """
    Thread-safe conversation state manager for PostChain.

    This class provides reliable state persistence for PostChain conversations,
    storing conversation history by thread_id. It currently implements in-memory
    storage with optional persistence to disk, but could be extended to use
    Redis, a database, or other persistent storage.
    """

    def __init__(self, storage_dir: Optional[str] = None):
        """
        Initialize the conversation state manager.

        Args:
            storage_dir: Optional directory for persistent storage on disk.
                         If provided, states will be saved to and loaded from disk.
        """
        # Thread-safe dictionary to store conversation states by thread_id
        self._states: Dict[str, PostChainState] = {}
        self._lock = threading.RLock()

        # Configure storage directory for optional persistence
        self.storage_dir = storage_dir
        if storage_dir and not os.path.exists(storage_dir):
            try:
                os.makedirs(storage_dir, exist_ok=True)
                logger.info(f"Created storage directory: {storage_dir}")
            except Exception as e:
                logger.error(f"Error creating storage directory: {e}")

    def get_state(self, thread_id: str) -> Optional[PostChainState]:
        """
        Get the conversation state for a thread.

        Args:
            thread_id: The thread ID to get state for

        Returns:
            PostChainState object or None if not found
        """
        thread_id = self._validate_thread_id(thread_id)

        with self._lock:
            # First try memory cache
            if thread_id in self._states:
                logger.info(f"Found state in memory for thread {thread_id}")
                # Return a deep copy to prevent modification of the stored state
                return copy.deepcopy(self._states[thread_id])

            # If not in memory and we have disk storage, try loading from disk
            if self.storage_dir:
                logger.info(f"State not in memory, trying disk for thread {thread_id}")
                state = self._load_state_from_disk(thread_id)
                if state:
                    # Cache in memory for future access
                    self._states[thread_id] = state
                    # Return a deep copy to prevent modification of the stored state
                    return copy.deepcopy(state)

        # State not found
        logger.info(f"No state found for thread {thread_id}")
        return None

    def save_state(self, state: PostChainState) -> bool:
        """
        Save a conversation state.

        Args:
            state: The state to save, must include a thread_id

        Returns:
            True if successful, False otherwise
        """
        if not state or not isinstance(state, dict):
            logger.error(f"Invalid state type: {type(state)}")
            return False

        # Get thread_id from state
        thread_id = state.get("thread_id")
        if not thread_id:
            logger.error("Cannot save state without thread_id")
            return False

        thread_id = self._validate_thread_id(thread_id)

        try:
            with self._lock:
                # Store a deep copy to prevent external modification
                self._states[thread_id] = copy.deepcopy(state)
                logger.info(f"Saved state for thread {thread_id}")

                # Persist to disk if configured
                if self.storage_dir:
                    self._save_state_to_disk(thread_id, state)

            return True
        except Exception as e:
            logger.error(f"Error saving state for thread {thread_id}: {e}")
            return False

    def update_state(self, thread_id: str, updates: Dict[str, Any]) -> bool:
        """
        Update fields in an existing conversation state.

        Args:
            thread_id: The thread ID to update
            updates: Dictionary of fields to update

        Returns:
            True if successful, False otherwise
        """
        thread_id = self._validate_thread_id(thread_id)

        with self._lock:
            # Get current state
            state = self.get_state(thread_id)
            if not state:
                logger.error(f"Cannot update non-existent state for thread {thread_id}")
                return False

            # Apply updates
            for key, value in updates.items():
                state[key] = value

            # Save updated state
            return self.save_state(state)

    def add_message(self, thread_id: str, message: BaseMessage) -> bool:
        """
        Add a message to a conversation state.

        Args:
            thread_id: The thread ID to add message to
            message: The message to add

        Returns:
            True if successful, False otherwise
        """
        thread_id = self._validate_thread_id(thread_id)

        with self._lock:
            # Get current state
            state = self.get_state(thread_id)
            if not state:
                # Create new state with initial message
                state = {
                    "messages": [message],
                    "thread_id": thread_id,
                    "metadata": {},
                    "error": None
                }
            else:
                # Add message to existing state
                if "messages" in state:
                    state["messages"].append(message)
                else:
                    state["messages"] = [message]

            # Save updated state
            return self.save_state(state)

    def delete_state(self, thread_id: str) -> bool:
        """
        Delete a conversation state.

        Args:
            thread_id: The thread ID to delete

        Returns:
            True if successful, False otherwise
        """
        thread_id = self._validate_thread_id(thread_id)

        try:
            with self._lock:
                # Remove from memory
                if thread_id in self._states:
                    del self._states[thread_id]
                    logger.info(f"Deleted state for thread {thread_id}")
                else:
                    logger.info(f"No state to delete for thread {thread_id}")

                # Remove from disk if configured
                if self.storage_dir:
                    file_path = os.path.join(self.storage_dir, f"{thread_id}.json")
                    if os.path.exists(file_path):
                        os.remove(file_path)
                        logger.info(f"Deleted state file for thread {thread_id}")

            return True
        except Exception as e:
            logger.error(f"Error deleting state for thread {thread_id}: {e}")
            return False

    def list_threads(self) -> List[str]:
        """
        List all thread IDs with stored state.

        Returns:
            List of thread IDs
        """
        with self._lock:
            # Get threads from memory
            threads = list(self._states.keys())

            # Get threads from disk if configured
            if self.storage_dir and os.path.exists(self.storage_dir):
                for filename in os.listdir(self.storage_dir):
                    if filename.endswith('.json'):
                        thread_id = filename[:-5]  # Remove .json extension
                        if thread_id not in threads:
                            threads.append(thread_id)

            return threads

    def _validate_thread_id(self, thread_id: str) -> str:
        """
        Validate and normalize a thread ID.

        Args:
            thread_id: The thread ID to validate

        Returns:
            A normalized UUID string
        """
        if not thread_id:
            thread_id = str(uuid.uuid4())
            logger.warning(f"Empty thread_id provided, generated new one: {thread_id}")
            return thread_id

        try:
            # Try to parse and normalize UUID
            return str(uuid.UUID(thread_id))
        except ValueError:
            # If not a valid UUID, generate a new one
            new_id = str(uuid.uuid4())
            logger.warning(f"Invalid thread_id: {thread_id}. Generating new UUID: {new_id}")
            return new_id

    def _save_state_to_disk(self, thread_id: str, state: PostChainState) -> None:
        """
        Save state to disk.

        Args:
            thread_id: The conversation thread ID
            state: The state dict to save
        """
        if not self.storage_dir:
            return

        filepath = os.path.join(self.storage_dir, f"{thread_id}.json")

        # Convert state to serializable format
        serializable_state = self._prepare_state_for_serialization(state)

        # Write to file
        with open(filepath, 'w') as f:
            json.dump(serializable_state, f, indent=2)

    def _load_state_from_disk(self, thread_id: str) -> Optional[PostChainState]:
        """
        Load state from disk.

        Args:
            thread_id: The conversation thread ID

        Returns:
            The loaded state dict or None if not found
        """
        if not self.storage_dir:
            return None

        filepath = os.path.join(self.storage_dir, f"{thread_id}.json")

        if not os.path.exists(filepath):
            return None

        # Read from file
        with open(filepath, 'r') as f:
            serialized_state = json.load(f)

        # Convert back to proper message objects
        return self._deserialize_state(serialized_state)

    def _prepare_state_for_serialization(self, state: PostChainState) -> Dict[str, Any]:
        """
        Convert state to a JSON-serializable format.

        Args:
            state: The state dict to serialize

        Returns:
            JSON-serializable state dict
        """
        serializable_state = copy.deepcopy(state)

        # Convert message objects to serializable dicts
        if 'messages' in serializable_state:
            serializable_messages = []
            for msg in serializable_state['messages']:
                if isinstance(msg, BaseMessage):
                    msg_dict = {
                        'content': msg.content,
                        'type': self._get_message_type(msg),
                    }
                    # Preserve additional kwargs if any
                    if hasattr(msg, 'additional_kwargs') and msg.additional_kwargs:
                        msg_dict['additional_kwargs'] = msg.additional_kwargs
                    serializable_messages.append(msg_dict)
                elif isinstance(msg, dict):
                    serializable_messages.append(msg)
                else:
                    # Fallback for unknown message types
                    serializable_messages.append({
                        'content': str(msg),
                        'type': 'unknown'
                    })
            serializable_state['messages'] = serializable_messages

        return serializable_state

    def _deserialize_state(self, serialized_state: Dict[str, Any]) -> PostChainState:
        """
        Convert serialized state back to proper objects.

        Args:
            serialized_state: The serialized state dict

        Returns:
            State dict with proper message objects
        """
        state = copy.deepcopy(serialized_state)

        # Convert serialized messages back to message objects
        if 'messages' in state:
            messages = []
            for msg_dict in state['messages']:
                if isinstance(msg_dict, dict) and 'content' in msg_dict and 'type' in msg_dict:
                    msg_type = msg_dict['type'].lower()
                    content = msg_dict['content']
                    additional_kwargs = msg_dict.get('additional_kwargs', {})

                    if msg_type in ('ai', 'assistant'):
                        messages.append(AIMessage(content=content, additional_kwargs=additional_kwargs))
                    elif msg_type in ('human', 'user'):
                        messages.append(HumanMessage(content=content, additional_kwargs=additional_kwargs))
                    elif msg_type == 'system':
                        messages.append(SystemMessage(content=content, additional_kwargs=additional_kwargs))
                    else:
                        # Default to AI message for unknown types
                        logger.warning(f"Unknown message type: {msg_type}")
                        messages.append(AIMessage(content=content, additional_kwargs=additional_kwargs))
                else:
                    # Keep as is if not in expected format
                    messages.append(msg_dict)
            state['messages'] = messages

        return state

    def _get_message_type(self, msg: BaseMessage) -> str:
        """
        Get the type name for a message object.

        Args:
            msg: The message object

        Returns:
            String type name ('ai', 'human', or 'system')
        """
        if isinstance(msg, AIMessage):
            return 'ai'
        elif isinstance(msg, HumanMessage):
            return 'human'
        elif isinstance(msg, SystemMessage):
            return 'system'
        else:
            return 'unknown'

# Create a global instance for use throughout the application
# This ensures a single shared state repository
GLOBAL_STATE_MANAGER = ConversationStateManager(
    storage_dir=os.environ.get('POSTCHAIN_STATE_DIR')
)

def serialize_messages(messages: List[BaseMessage]) -> List[Dict[str, Any]]:
    """
    Convert message objects to serializable dictionaries.

    Args:
        messages: List of message objects

    Returns:
        List of serializable message dicts
    """
    serialized = []
    for msg in messages:
        if isinstance(msg, BaseMessage):
            msg_type = 'ai'
            if isinstance(msg, HumanMessage):
                msg_type = 'human'
            elif isinstance(msg, SystemMessage):
                msg_type = 'system'

            serialized.append({
                'content': msg.content,
                'type': msg_type,
                'additional_kwargs': getattr(msg, 'additional_kwargs', {})
            })
        elif isinstance(msg, dict) and 'content' in msg:
            # Already a dict with content
            if 'type' not in msg:
                msg['type'] = 'ai'  # Default type
            serialized.append(msg)
        else:
            # Fallback for unknown message types
            serialized.append({
                'content': str(msg),
                'type': 'unknown'
            })
    return serialized

def deserialize_messages(serialized: List[Dict[str, Any]]) -> List[BaseMessage]:
    """
    Convert serialized message dicts back to message objects.

    Args:
        serialized: List of serialized message dicts

    Returns:
        List of message objects
    """
    messages = []
    for msg_dict in serialized:
        if isinstance(msg_dict, dict) and 'content' in msg_dict:
            content = msg_dict['content']
            msg_type = msg_dict.get('type', 'ai').lower()
            additional_kwargs = msg_dict.get('additional_kwargs', {})

            if msg_type in ('ai', 'assistant'):
                messages.append(AIMessage(content=content, additional_kwargs=additional_kwargs))
            elif msg_type in ('human', 'user'):
                messages.append(HumanMessage(content=content, additional_kwargs=additional_kwargs))
            elif msg_type == 'system':
                messages.append(SystemMessage(content=content, additional_kwargs=additional_kwargs))
            else:
                # Default to AI message for unknown types
                logger.warning(f"Unknown message type: {msg_type}")
                messages.append(AIMessage(content=content, additional_kwargs=additional_kwargs))
        else:
            # Keep as is if not in expected format
            messages.append(msg_dict)
    return messages
