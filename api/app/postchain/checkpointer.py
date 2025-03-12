"""
Custom LangGraph checkpointer for PostChain.

This module provides a LangGraph-compatible checkpoint implementation
that uses our ConversationStateManager for reliable state persistence.
"""

from typing import Any, Dict, List, Optional, Tuple, Union
from langgraph.checkpoint.base import BaseCheckpointSaver, CheckpointMetadata

from app.postchain.state_manager import GLOBAL_STATE_MANAGER
from app.postchain.schemas.state import PostChainState

class CheckpointResult:
    """Object that matches LangGraph's expected return format"""
    def __init__(self, state: Dict[str, Any], metadata: CheckpointMetadata, config: Dict[str, Any]):
        self.state = state
        self.metadata = metadata
        self.config = config
        self.parent_config = config

class PostChainCheckpointer(BaseCheckpointSaver):
    """
    LangGraph-compatible checkpointer using our ConversationStateManager.

    This class implements the BaseCheckpointSaver interface required by LangGraph,
    wrapping our ConversationStateManager to provide thread-safe state persistence
    for LangGraph's StateGraph execution.
    """

    def get_tuple(self, config: Dict[str, Any]) -> CheckpointResult:
        """
        Retrieve state for a given thread ID.

        Args:
            config: Configuration dict containing thread_id

        Returns:
            Tuple of (state_dict, metadata)
        """
        thread_id = config["configurable"]["thread_id"]
        state = GLOBAL_STATE_MANAGER.get_state(thread_id)

        if state is None:
            # Return empty state if not found
            state_dict = PostChainState(thread_id=thread_id).dict()
        elif isinstance(state, PostChainState):
            state_dict = state.dict()
        else:
            state_dict = state

        return CheckpointResult(
            state=state_dict,
            metadata=CheckpointMetadata(),
            config=config
        )

    async def aget_tuple(self, config: Dict[str, Any]) -> CheckpointResult:
        """
        Async version of get_tuple.

        Args:
            config: Configuration dict containing thread_id

        Returns:
            Tuple of (state_dict, metadata)
        """
        # Simply call the sync version since our state manager is already thread-safe
        return self.get_tuple(config)

    def put(self, config: Dict[str, Any], checkpoint: Dict, metadata: CheckpointMetadata) -> None:
        """
        Save state for a given thread ID.

        Args:
            config: Configuration dict containing thread_id
            checkpoint: The state dict to save
            metadata: Checkpoint metadata
        """
        thread_id = config["configurable"]["thread_id"]

        # Ensure thread_id is in the state
        if "thread_id" not in checkpoint:
            checkpoint["thread_id"] = thread_id

        # Save state
        GLOBAL_STATE_MANAGER.save_state(checkpoint)

    async def aput(self, config: Dict[str, Any], checkpoint: Dict, metadata: CheckpointMetadata) -> None:
        """
        Async version of put.

        Args:
            config: Configuration dict containing thread_id
            checkpoint: The state dict to save
            metadata: Checkpoint metadata
        """
        # Simply call the sync version since our state manager is already thread-safe
        self.put(config, checkpoint, metadata)

    def list(self, config: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        List all available thread IDs.

        Args:
            config: Configuration dict

        Returns:
            List of thread config dicts
        """
        threads = GLOBAL_STATE_MANAGER.list_threads()
        return [{"thread_id": tid} for tid in threads]

    async def alist(self, config: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Async version of list.

        Args:
            config: Configuration dict

        Returns:
            List of thread config dicts
        """
        # Simply call the sync version since our state manager is already thread-safe
        return self.list(config)
