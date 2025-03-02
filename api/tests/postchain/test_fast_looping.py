"""
Fast tests for the ChorusGraph looping behavior.

This module provides lightweight tests for verifying the looping behavior of the ChorusGraph
without making actual API calls to LLM providers, which makes the tests run much faster.
"""

import pytest
import asyncio
import logging
from typing import Dict, Any, List, Callable
from unittest.mock import patch, MagicMock

from app.config import Config
from app.chorus_graph import create_chorus_graph, ChorusGraph, should_loop

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create a mock response for the understanding phase that will trigger looping
MOCK_UNDERSTANDING_RESPONSE = {
    "status": "success",
    "content": {
        "should_loop": True,
        "reasoning": "This is mock reasoning for testing purposes."
    }
}

# Create a minimal mock config that provides just enough to run the tests
class MockConfig(Config):
    """Mock configuration for testing."""
    def __init__(self):
        super().__init__()


# Mock the abstract_llm_structured_output function
async def mock_llm_structured_output(*args, **kwargs):
    """Mock implementation that always returns success and should_loop=True."""
    return MOCK_UNDERSTANDING_RESPONSE


# Mock handler that always sets should_loop=True
async def mock_understanding_handler(state: Dict[str, Any]) -> Dict[str, Any]:
    """Mock handler for understanding phase that always sets should_loop=True."""
    # Initialize responses dictionary if not present
    if "responses" not in state:
        state["responses"] = {}

    # Set current phase
    state["current_phase"] = "understanding"

    # Add mock response for understanding phase
    state["responses"]["understanding"] = {
        "content": "Mock understanding reasoning",
        "should_loop": True,
        "reasoning": "Mock understanding reasoning",
        "confidence": 0.9,
        "metadata": {
            "model": "mock/model",
            "provider": "mock"
        }
    }

    # Set should_loop in state
    state["should_loop"] = True

    return state


@pytest.mark.asyncio
async def test_should_loop_function():
    """Test the should_loop function directly to verify looping logic."""
    # Test case 1: should loop (explicit should_loop=True)
    state1 = {
        "should_loop": True,
        "loop_count": 0,
        "max_loops": 3
    }

    result1 = should_loop(state1)
    assert result1 == "action", "Should route to action when should_loop=True"
    assert state1["loop_count"] == 1, "Should increment loop count"

    # Test case 2: should not loop after max_loops
    state2 = {
        "should_loop": True,
        "loop_count": 3,
        "max_loops": 3
    }

    result2 = should_loop(state2)
    assert result2 == "yield", "Should route to yield when max_loops reached"

    # Test case 3: loop with probability
    state3 = {
        "should_loop": False,  # Model says no
        "loop_probability": 0.9,  # But probability says yes
        "loop_count": 0,
        "max_loops": 3
    }

    result3 = should_loop(state3)
    assert result3 == "action", "Should route to action when loop_probability is high"
    assert state3["loop_count"] == 1, "Should increment loop count"


@pytest.mark.asyncio
async def test_loop_count_tracking():
    """Test that loop count is properly tracked and incremented."""
    # Create a state that will loop 2 times due to loop_config
    state = {
        "content": "Test prompt",
        "loop_config": {
            "should_loop": True,
            "loop_probability": 0.9
        },
        "max_loops": 3,
        "loop_count": 0
    }

    # Directly test the loop counting logic
    result1 = should_loop(state)
    assert result1 == "action", "First call should route to action"
    assert state["loop_count"] == 1, f"Loop count should be 1, got {state['loop_count']}"

    result2 = should_loop(state)
    assert result2 == "action", "Second call should route to action"
    assert state["loop_count"] == 2, f"Loop count should be 2, got {state['loop_count']}"

    result3 = should_loop(state)
    assert result3 == "action", "Third call should route to action"
    assert state["loop_count"] == 3, f"Loop count should be 3, got {state['loop_count']}"

    # Now we've reached max_loops
    result4 = should_loop(state)
    assert result4 == "yield", "Fourth call should route to yield"
    assert state["loop_count"] == 3, "Loop count should remain at 3"


@pytest.mark.asyncio
async def test_initialize_state_with_loop_config():
    """Test that _initialize_state properly sets up loop configuration."""
    # Create a graph instance
    graph = create_chorus_graph()

    # Test state with loop_config
    state = {
        "content": "Test prompt",
        "loop_config": {
            "should_loop": True,
            "loop_probability": 0.9
        }
    }

    # Initialize the state
    initialized_state = graph._initialize_state(state)

    # Verify loop config was properly applied
    assert initialized_state["should_loop"] is True, "should_loop should be True"
    assert initialized_state["loop_probability"] == 0.9, "loop_probability should be 0.9"
    assert initialized_state["loop_count"] == 0, "loop_count should be initialized to 0"
    assert initialized_state["max_loops"] == 3, "max_loops should default to 3"


# Create a simplified mock for each phase handler
async def mock_phase_handler(state: Dict[str, Any]) -> Dict[str, Any]:
    """Generic mock phase handler that adds minimal response data."""
    phase = state.get("current_phase", "unknown")

    # Initialize responses if not present
    if "responses" not in state:
        state["responses"] = {}

    # Add a minimal response for the phase
    state["responses"][phase] = {
        "content": f"Mock {phase} response",
        "reasoning": f"Mock {phase} reasoning",
        "confidence": 0.9,
        "metadata": {
            "model": "mock/model",
            "provider": "mock"
        }
    }

    # For understanding phase, set should_loop based on loop_config
    if phase == "understanding":
        should_loop_val = state.get("should_loop", False)
        # If loop_config explicitly sets should_loop, use that value
        if "loop_config" in state and isinstance(state["loop_config"], dict):
            if "should_loop" in state["loop_config"]:
                should_loop_val = state["loop_config"]["should_loop"]

        state["responses"][phase]["should_loop"] = should_loop_val
        state["should_loop"] = should_loop_val

    return state


class FastMockChorusGraph:
    """A lightweight mock version of ChorusGraph for fast testing."""

    def __init__(self):
        self.handlers = {
            "action": mock_phase_handler,
            "experience": mock_phase_handler,
            "intention": mock_phase_handler,
            "observation": mock_phase_handler,
            "understanding": mock_phase_handler,
            "yield": mock_phase_handler
        }

    def _initialize_state(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Initialize state with required values."""
        # Ensure we have required fields
        if "content" not in state:
            state["content"] = "Mock input"

        # Initialize default values
        if "responses" not in state:
            state["responses"] = {}

        if "loop_count" not in state:
            state["loop_count"] = 0

        if "max_loops" not in state:
            state["max_loops"] = 3

        # Handle loop_config if present
        if "loop_config" in state and isinstance(state["loop_config"], dict):
            config = state["loop_config"]
            if "should_loop" in config:
                state["should_loop"] = config["should_loop"]
            if "loop_probability" in config:
                state["loop_probability"] = config["loop_probability"]

        return state

    async def run_with_loops(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Run through the graph with mocked handlers, simulating the looping behavior."""
        # Initialize state
        state = self._initialize_state(state)

        # Process phases in order
        phases = ["action", "experience", "intention", "observation", "understanding"]

        # Track loops
        loops_completed = 0
        max_loops = state.get("max_loops", 3)

        while loops_completed < max_loops:
            # Process each phase in the current loop
            for phase in phases:
                state["current_phase"] = phase
                state = await self.handlers[phase](state)

            # After understanding, check if we should loop
            should_loop_decision = should_loop(state)

            if should_loop_decision == "yield":
                # Process yield phase and exit
                state["current_phase"] = "yield"
                state = await self.handlers["yield"](state)
                break
            else:
                # Loop back to action
                loops_completed += 1
                continue

        # Ensure yield phase is processed if we break out of loop due to max_loops
        if state["current_phase"] != "yield":
            state["current_phase"] = "yield"
            state = await self.handlers["yield"](state)

        return state


@pytest.mark.asyncio
async def test_mock_graph_looping():
    """Test looping behavior using a mock graph without real API calls."""
    # Create mock graph
    mock_graph = FastMockChorusGraph()

    # Create state with explicit loop configuration
    state = {
        "content": "Test prompt",
        "loop_config": {
            "should_loop": True,
            "loop_probability": 0.9
        },
        "max_loops": 3
    }

    # Run the mock graph
    result_state = await mock_graph.run_with_loops(state)

    # Verify looping occurred
    assert result_state["loop_count"] >= 2, f"Expected at least 2 loops, got {result_state['loop_count']}"

    # Test with different max_loops
    state2 = {
        "content": "Test prompt",
        "loop_config": {
            "should_loop": True,
            "loop_probability": 0.9
        },
        "max_loops": 5  # Allow more loops
    }

    result_state2 = await mock_graph.run_with_loops(state2)
    assert result_state2["loop_count"] >= 3, f"Expected at least 3 loops with max_loops=5, got {result_state2['loop_count']}"


if __name__ == "__main__":
    # Run tests with pytest
    pytest.main(["-v", __file__])
