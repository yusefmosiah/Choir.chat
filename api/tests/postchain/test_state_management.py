"""
Tests for PostChain state management.
"""
import unittest
import uuid
import pytest

from app.postchain.utils import validate_thread_id, load_state, recover_state
from app.postchain.schemas.state import PostChainState
from langchain_core.messages import HumanMessage, SystemMessage

class TestPostChainStateManagement(unittest.TestCase):
    """Test cases for PostChain state management utilities."""

    def test_validate_thread_id_with_valid_uuid(self):
        """Test that a valid UUID is returned as-is."""
        valid_uuid = str(uuid.uuid4())
        result = validate_thread_id(valid_uuid)
        self.assertEqual(result, valid_uuid)

    def test_validate_thread_id_with_none(self):
        """Test that None generates a new UUID."""
        result = validate_thread_id(None)
        # Check that result is a valid UUID
        try:
            uuid_obj = uuid.UUID(result)
            is_valid = True
        except ValueError:
            is_valid = False
        self.assertTrue(is_valid)

    def test_validate_thread_id_with_invalid_string(self):
        """Test that an invalid string generates a new UUID."""
        result = validate_thread_id("not-a-uuid")
        # Check that result is a valid UUID and not the original string
        try:
            uuid_obj = uuid.UUID(result)
            is_valid = True
        except ValueError:
            is_valid = False
        self.assertTrue(is_valid)
        self.assertNotEqual(result, "not-a-uuid")

    def test_load_state_with_user_query(self):
        """Test loading a new state with a user query."""
        test_query = "Test query"
        result = load_state(None, test_query)

        # Check state structure
        self.assertIsInstance(result, PostChainState)
        self.assertEqual(len(result.messages), 2)  # System message + user query
        self.assertEqual(result.messages[0].content, "You are a helpful AI assistant.")
        self.assertEqual(result.messages[1].content, test_query)
        self.assertEqual(result.current_phase, "action")
        self.assertEqual(result.phase_state, {})
        self.assertEqual(result.phase_outputs, {})

    def test_load_state_without_user_query(self):
        """Test loading a new state without a user query."""
        result = load_state(None)

        # Check state structure
        self.assertIsInstance(result, PostChainState)
        self.assertEqual(len(result.messages), 1)  # Just system message
        self.assertEqual(result.messages[0].content, "You are a helpful AI assistant.")
        self.assertEqual(result.current_phase, "action")


@pytest.mark.asyncio
async def test_recover_interrupted_state():
    """Test recovering a state from an interrupted conversation."""
    # Create a test state with a phase in "processing" state
    thread_id = str(uuid.uuid4())
    state = PostChainState(
        thread_id=thread_id,
        messages=[
            SystemMessage(content="You are a helpful AI assistant."),
            HumanMessage(content="Test query")
        ],
        phase_state={"action": "processing"},
        current_phase="action"
    )

    # Store state using MemorySaver
    from langgraph.checkpoint.memory import MemorySaver
    memory = MemorySaver()
    memory_key = f"postchain_{thread_id}"

    # Configure thread for saving
    thread_config = {"configurable": {"thread_id": thread_id, "checkpoint_id": memory_key}}

    # Save state with configured thread
    memory.put_state(state, config=thread_config)

    # Recover state
    recovered_state = recover_state(thread_id)

    # Check that processing phase was marked as error
    assert recovered_state is not None
    assert recovered_state.phase_state["action"] == "error"
    assert recovered_state.error == "Conversation was interrupted"
