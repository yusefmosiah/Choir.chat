"""
Tests for multiturn functionality in PostChain.
"""
import pytest
import asyncio
import json
import logging
import uuid
from typing import Dict, Any, List

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage

from app.config import Config
from app.postchain.simple_graph import create_postchain_graph, stream_simple_postchain
from app.postchain.schemas.state import PostChainState
from app.postchain.utils import validate_thread_id
from app.postchain.state_manager import GLOBAL_STATE_MANAGER

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("test_multiturn")

@pytest.mark.asyncio
async def test_multiturn_conversation():
    """Test a simple multiturn conversation flow with the PostChain graph."""
    config = Config()

    # Message 1: Ask about the magic number
    thread_id = None  # Will be generated automatically
    user_query_1 = "The magic number is 137"

    # Let's debug with more detailed logging
    logger.info(f"Starting first turn with query: {user_query_1}")

    # First turn - collect results from the stream
    results_1 = []
    thread_id = None

    async for chunk in stream_simple_postchain(user_query_1, config, thread_id):
        results_1.append(chunk)
        # Capture thread_id from the first chunk that has it
        if thread_id is None and "thread_id" in chunk:
            thread_id = chunk["thread_id"]

    # Log the entire results for debugging
    logger.info(f"First turn result: {json.dumps(results_1, default=lambda x: str(x), indent=2)}")

    # Extract latest content for each phase from the results
    action_content = ""
    experience_content = ""

    for chunk in results_1:
        if chunk.get("current_phase") == "action" and chunk.get("content"):
            action_content = chunk.get("content")
        elif chunk.get("current_phase") == "experience" and chunk.get("content"):
            experience_content = chunk.get("content")

    logger.info(f"First turn action content: {action_content[:100]}...")
    logger.info(f"First turn experience content: {experience_content[:100]}...")

    # Directly check the state to verify it contains the messages with 137
    if thread_id:
        # Get the state from the state manager
        state = GLOBAL_STATE_MANAGER.get_state(thread_id)
        logger.info(f"Retrieved state for thread_id {thread_id}: {state is not None}")

        if state:
            # Debug: Print the state structure
            logger.info(f"State type: {type(state)}")
            logger.info(f"State attributes: {dir(state)}")
            logger.info(f"State dict: {state.dict() if hasattr(state, 'dict') else state}")

            # Debug: Print messages if they exist
            if hasattr(state, 'messages'):
                logger.info(f"Messages type: {type(state.messages)}")
                logger.info(f"Messages count: {len(state.messages)}")
                for i, msg in enumerate(state.messages):
                    logger.info(f"Message {i} type: {type(msg)}")
                    logger.info(f"Message {i} content: {msg.content[:50] if hasattr(msg, 'content') else 'No content'}")

        # Verify the state has the correct messages
        assert state is not None, "State should be found for the thread_id"
        assert hasattr(state, 'messages'), "State should have messages attribute"
        assert len(state.messages) >= 2, "State should have at least 2 messages (user query and AI response)"

        # Check if 137 is in the state
        state_has_137 = False
        for msg in state.messages:
            if hasattr(msg, 'content') and '137' in msg.content:
                state_has_137 = True
                logger.info(f"Found 137 in message: {msg.content[:50]}...")
                break

        assert state_has_137, "State should contain a message with '137'"

        # Now second turn
        user_query_2 = "What is the magic number you mentioned earlier?"
        logger.info(f"Starting second turn with query: {user_query_2} and thread_id: {thread_id}")

        # Collect results from second turn
        results_2 = []
        async for chunk in stream_simple_postchain(user_query_2, config, thread_id):
            results_2.append(chunk)

        logger.info(f"Second turn results count: {len(results_2)}")

        # Extract latest content for each phase from the second turn
        action_content_2 = ""
        experience_content_2 = ""

        for chunk in results_2:
            if chunk.get("current_phase") == "action" and chunk.get("content"):
                action_content_2 = chunk.get("content")
            elif chunk.get("current_phase") == "experience" and chunk.get("content"):
                experience_content_2 = chunk.get("content")

        logger.info(f"Second turn action content: {action_content_2[:100]}...")
        logger.info(f"Second turn experience content: {experience_content_2[:100]}...")

        # Check after the second turn that the state contains all messages
        state_after_turn_2 = GLOBAL_STATE_MANAGER.get_state(thread_id)
        if state_after_turn_2:
            logger.info(f"State after turn 2 has {len(state_after_turn_2.messages)} messages")
            for i, msg in enumerate(state_after_turn_2.messages):
                logger.info(f"Message {i} type: {type(msg)}")
                logger.info(f"Message {i} content: {msg.content[:50] if hasattr(msg, 'content') else 'No content'}")

        # Assert that the second turn responses reference the magic number 137
        # This confirms that the conversation history is properly maintained
        assert "137" in action_content_2, "Second turn action response should reference the magic number 137"

        # Assuming experience phase completes successfully, it should also mention 137
        if experience_content_2:
            assert "137" in experience_content_2, "Second turn experience response should reference the magic number 137"

    assert thread_id is not None, "Thread ID should be generated"

if __name__ == "__main__":
    # Run the test directly
    asyncio.run(test_multiturn_conversation())
