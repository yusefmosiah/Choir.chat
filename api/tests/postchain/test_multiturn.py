"""
Tests for multiturn functionality in PostChain.
"""
import pytest
import asyncio
import json
import logging
from typing import Dict, Any, List

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage

from app.config import Config
from app.postchain.simple_graph import create_postchain_graph, invoke_simple_postchain
from app.postchain.schemas.state import PostChainState
from app.postchain.utils import validate_thread_id

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

    # First turn
    result_1 = await invoke_simple_postchain(user_query_1, config, thread_id)
    thread_id = result_1["thread_id"]

    # Log the entire result for debugging
    logger.info(f"First turn result: {json.dumps(result_1, default=lambda x: str(x), indent=2)}")

    # Log phase outputs specifically
    action_output = result_1.get("phase_outputs", {}).get("action")
    experience_output = result_1.get("phase_outputs", {}).get("experience")
    logger.info(f"First turn action output: {action_output}")
    logger.info(f"First turn experience output: {experience_output}")

    # Check if any message objects contain the outputs
    messages_with_content = []
    for i, msg in enumerate(result_1.get("messages", [])):
        if hasattr(msg, 'content') and msg.content:
            messages_with_content.append(f"Message {i}: {msg.content[:50]}...")
            if hasattr(msg, 'additional_kwargs'):
                logger.info(f"Message {i} additional_kwargs: {msg.additional_kwargs}")

    logger.info(f"Messages with content: {messages_with_content}")

    # Second turn - if we get here
    if thread_id:
        user_query_2 = "What is the magic number you mentioned earlier?"
        logger.info(f"Starting second turn with query: {user_query_2} and thread_id: {thread_id}")
        result_2 = await invoke_simple_postchain(user_query_2, config, thread_id)
        logger.info(f"Second turn result: {json.dumps(result_2, default=lambda x: str(x), indent=2)}")

        # Check messages for content
        logger.info(f"Second turn messages count: {len(result_2.get('messages', []))}")
        for i, msg in enumerate(result_2.get("messages", [])):
            if hasattr(msg, 'content') and msg.content:
                logger.info(f"Message {i}: {msg.content[:50]}...")

    assert thread_id is not None, "Thread ID should be generated"

if __name__ == "__main__":
    # Run the test directly
    asyncio.run(test_multiturn_conversation())
