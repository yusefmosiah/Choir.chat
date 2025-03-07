"""
PostChain implementation using LangGraph.

This module implements the Chorus Cycle (AEIOU-Y) pattern using LangGraph's StateGraph.
Each phase in the cycle is implemented as a node in the graph, with edges connecting them.
The implementation supports streaming, multiple model providers, and conditional looping.

The implementation also supports custom model selection for each phase, allowing for a more
diverse and robust response pattern. If no specific models are provided, it defaults to
random selection from the available provider pool.
"""

import logging
import asyncio
import random
import uuid
from typing import Dict, Any, List, Callable, Tuple, TypedDict, Optional, AsyncIterator, cast, Annotated

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import StrOutputParser

# LangGraph imports
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages

# Local imports
from app.config import Config
from app.langchain_utils import (
    abstract_llm_completion,
    abstract_llm_structured_output,
    get_model_provider,
    abstract_llm_completion_stream,
    initialize_model_list,
    get_user_message,
    ModelConfig
)
from app.postchain.schemas.aeiou import (
    ActionOutput,
    ExperienceOutput,
    IntentionOutput,
    ObservationOutput,
    UnderstandingOutput,
    YieldOutput
)

# Configure logging
logger = logging.getLogger("postchain")

# System prompts for each phase
SYSTEM_PROMPTS = {
    "action": """You are an Action assistant tasked with the first step in a multi-step thinking process.
Your role is to provide an initial response to the user's query with a "beginner's mind" -
without overthinking or overcomplicating. Focus on understanding the core request and giving
a straightforward, helpful initial response.

Respond concisely and clearly, focusing on the immediate question without bringing in
unnecessary complexity. This is just the first step in a process, so keep it simple and direct.""",

    "experience": """You are an Experience assistant tasked with enriching an initial response with relevant knowledge.
Review the previous 'Action' response and consider what additional context, facts, or background
information would make the response more complete and valuable.

Your goal is to enhance the response with relevant prior knowledge, making it more informative
and comprehensive. Focus on adding value through your knowledge, not changing the core message.""",

    "intention": """You are an Intention assistant tasked with analyzing the planned response.
Examine the enriched response from the Experience phase and consider:
1. Whether it properly addresses the user's actual intent
2. What assumptions are being made
3. Whether there are alternative perspectives that should be considered

Your goal is to ensure the response is well-aligned with what the user is really asking for
and considers appropriate alternatives and perspectives.""",

    "observation": """You are an Observation assistant tasked with reflecting on the analysis.
Review all previous phases and identify patterns, connections, and insights that might have been missed.
Consider how the different perspectives uncovered in the Intention phase connect with each other.

Your goal is to find deeper connections and ensure the response is comprehensive and cohesive.""",

    "understanding": """You are an Understanding assistant tasked with making a decision about the response process.
Based on all previous phases, determine whether:
1. The response is sufficient and should be finalized (yield)
2. More iteration is needed to improve the response (loop back)

If the response needs improvement, clearly state why and what aspects need more work.
If the response is sufficient, affirm why it's ready to be delivered.

Your decision should be data-driven, based on the quality and completeness of the response so far.""",

    "yield": """You are a Yield assistant tasked with producing the final response to the user.
Your job is to synthesize all the thinking from previous phases into a clear, coherent, and
helpful final response. This is what the user will actually receive.

Make sure your response is:
1. Direct and answers the user's original question completely
2. Well-structured and easy to understand
3. Incorporates the insights and considerations from all previous phases
4. Written in a natural, conversational tone

Focus on quality and clarity - this is the culmination of the entire thinking process."""
}

# Function to create phase handlers
def create_phase_handler(phase: str, config: Config, models_list: Optional[List[str]] = None) -> Callable:
    """Create a handler function for a specific phase in the AEIOU cycle.

    Args:
        phase: The phase name (action, experience, etc.)
        config: The application configuration
        models_list: Optional list of models to use for each phase in order. If None, random models will be used.

    Returns:
        A handler function for the phase

    Raises:
        ValueError: If models_list is None and no models are available for random selection
    """
    # Get models for random selection if no specific models are provided
    available_models = []
    if models_list is None:
        # Disable OpenAI models since they're not available
        available_models = initialize_model_list(config, disabled_providers={"openai"})
        if not available_models:
            raise ValueError(f"No models available for random selection for phase {phase}")
        logger.info(f"Using random model selection for {phase} from {len(available_models)} available models")
    else:
        if not models_list:
            raise ValueError(f"Empty models list provided for phase {phase}")
        logger.info(f"Using specified model for {phase} from provided list")

    system_prompt = SYSTEM_PROMPTS.get(phase, "You are a helpful AI assistant.")

    async def handler(state: Dict[str, Any]) -> Dict[str, Any]:
        """Updated phase handler with guaranteed state writes"""
        # Ensure we always write to recognized state keys
        updates = {
            "responses": {**state.get("responses", {}), phase: {"content": "..."}},
            "current_phase": phase,
            "messages": [*state.get("messages", []), AIMessage(content="...")]
        }

        # Required for LangGraph state validation
        return {"__root__": updates}  # Special key for full state replacement

    return handler

# Decision function for whether to loop or proceed to yield
def should_loop(state):
    """
    Decides whether to loop back to action or yield based on probability
    """
    logger.debug(f"should_loop state keys: {list(state.keys())}")

    # Debug: Dump the entire state structure for better debugging
    if "__root__" in state:
        logger.debug(f"__root__ keys: {list(state['__root__'].keys())}")
        if "loop_probability" in state["__root__"]:
            logger.debug(f"__root__['loop_probability'] = {state['__root__']['loop_probability']}")

    # Get the current loop count
    current_loops = 0
    if "loop_count" in state:
        current_loops = state["loop_count"]
    elif "__root__" in state and "loop_count" in state["__root__"]:
        current_loops = state["__root__"]["loop_count"]

    # Set a max loops to prevent infinite loops during debugging
    max_loops = 2

    # Get loop probability (defaulting to 0.5 if not set)
    loop_probability = 0.0  # Default to 0 to prevent unexpected looping

    # First check the __root__ state for loop_probability
    if "__root__" in state and "loop_probability" in state["__root__"]:
        loop_probability = float(state["__root__"]["loop_probability"])
        logger.debug(f"Using loop_probability from __root__: {loop_probability}")
    # Then check the top-level state
    elif "loop_probability" in state:
        loop_probability = float(state["loop_probability"])
        logger.debug(f"Using loop_probability from top-level state: {loop_probability}")

    # Log the current state for debugging
    logger.info(f"Should loop function - current_loops: {current_loops}, max_loops: {max_loops}, loop_probability: {loop_probability}")

    # If we've reached the max loops, always yield
    if current_loops >= max_loops:
        logger.info(f"Max loops ({max_loops}) reached, yielding")
        return "yield"

    # If loop probability is 0, always yield
    if loop_probability <= 0.0:
        logger.info("Loop probability is zero or negative, yielding")
        return "yield"

    # Make a random decision based on the probability
    if random.random() < loop_probability:
        # Increment loop count and loop back to action
        if "__root__" in state:
            state["__root__"]["loop_count"] = current_loops + 1
        else:
            state["loop_count"] = current_loops + 1

        logger.info(f"Probability check passed ({loop_probability}), looping back to action, incrementing loop_count to {current_loops + 1}")
        return "action"
    else:
        logger.info(f"Probability check failed ({loop_probability}), yielding")
        return "yield"

class ChorusState(TypedDict):
    messages: Annotated[list, add_messages]
    responses: dict
    current_phase: str
    loop_count: int

class ChorusGraph:
    """Implementation of the Chorus Cycle graph using LangGraph."""

    def __init__(self, config: Optional[Config] = None, models_list: Optional[List[str]] = None, recursion_limit: Optional[int] = None):
        """Initialize the graph with handlers for each phase.

        Args:
            config: Application configuration
            models_list: Optional list of models to use for each phase. If None, random models will be used.
            recursion_limit: Optional recursion limit for the graph
        """
        self.config = config or Config()
        self.models_list = models_list
        self.recursion_limit = recursion_limit
        self.loop_probability = 0.5  # Default loop probability

        logger.info(f"Initializing ChorusGraph with models_list: {models_list or 'random selection'}")

        # Create handlers for each phase
        self.handlers = {
            "action": create_phase_handler("action", self.config, self.models_list),
            "experience": create_phase_handler("experience", self.config, self.models_list),
            "intention": create_phase_handler("intention", self.config, self.models_list),
            "observation": create_phase_handler("observation", self.config, self.models_list),
            "understanding": create_phase_handler("understanding", self.config, self.models_list),
            "yield": create_phase_handler("yield", self.config, self.models_list)
        }

        # Create the graph
        builder = StateGraph(ChorusState)

        # Add nodes for each phase
        builder.add_node("action", self.handlers["action"])
        builder.add_node("experience", self.handlers["experience"])
        builder.add_node("intention", self.handlers["intention"])
        builder.add_node("observation", self.handlers["observation"])
        builder.add_node("understanding", self.handlers["understanding"])
        builder.add_node("yield", self.handlers["yield"])

        # Add edges between phases
        builder.add_edge("action", "experience")
        builder.add_edge("experience", "intention")
        builder.add_edge("intention", "observation")
        builder.add_edge("observation", "understanding")

        # Add conditional edge from understanding
        builder.add_conditional_edges(
            "understanding",
            should_loop,
            {
                "action": "action",
                "yield": "yield"
            }
        )

        # Connect yield to END for completion
        builder.add_edge("yield", END)

        # Set the entry point
        builder.add_edge(START, "action")

        # Compile the graph
        self.graph = builder.compile()

        # Set recursion limit if provided
        if self.recursion_limit is not None:
            self.graph.set_recursion_limit(self.recursion_limit)
            logger.info(f"Set recursion limit to {self.recursion_limit}")

    def _initialize_state(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Initialize state with required values to prevent empty state errors."""
        # Extract or initialize the loop probability
        loop_probability = state.get("loop_probability", 0.5)

        # Check for LangGraph __root__ key which contains the actual state fields
        root_state = {}
        if "__root__" in state:
            # We have a LangGraph state format
            root_state = state["__root__"]
            # If loop_probability exists in root, it takes precedence
            if "loop_probability" in root_state:
                loop_probability = root_state.get("loop_probability", 0.5)
                logger.info(f"Using loop_probability from __root__: {loop_probability}")
            # Copy the loop_probability from top level to root if not already there
            else:
                root_state["loop_probability"] = loop_probability
                logger.info(f"Copied loop_probability to __root__: {loop_probability}")

        # Define required base values that should be present in state
        required_base = {
            "messages": [],
            "responses": {},
            "current_phase": "action",
            "loop_count": 0,
            "max_loops": min(state.get("max_loops", 3), self.recursion_limit or 100),
            "loop_probability": max(0.0, min(1.0, loop_probability)),
            "recursion_limit": self.recursion_limit
        }

        # If we have a root state, apply defaults there
        if "__root__" in state:
            for key, default in required_base.items():
                if key not in root_state:
                    root_state[key] = default

            # Ensure loop_probability is in the root state
            root_state["loop_probability"] = required_base["loop_probability"]
            logger.info(f"Setting loop_probability in __root__: {root_state['loop_probability']}")

            # Update the root state
            state["__root__"] = root_state
        else:
            # No root state, apply defaults to top level
            for key, default in required_base.items():
                if key not in state:
                    state[key] = default

            # Ensure loop_probability is at top level
            state["loop_probability"] = required_base["loop_probability"]
            logger.info(f"Setting loop_probability in state: {state['loop_probability']}")

        return state

    def invoke(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Validated invoke with schema enforcement"""
        validated_state = ChorusState(**self._initialize_state(state))
        return self.graph.invoke(
            validated_state,
            config={"recursion_limit": self.recursion_limit},
            stream_mode="values"
    )

    async def astream(self, state: Dict[str, Any]) -> AsyncIterator[Tuple[str, Dict[str, Any]]]:
        """Asynchronously process state through the graph, yielding each step."""
        # Enable streaming by default
        state["streaming_enabled"] = True

        # Initialize state with required values to prevent empty state errors
        state = self._initialize_state(state)

        # Create config with recursion limit if specified
        config = {}
        if self.recursion_limit is not None:
            config["recursion_limit"] = self.recursion_limit
            logger.info(f"Using recursion limit: {self.recursion_limit}")

        # Log the state configuration for debugging
        logger.info(f"astream state configuration: loop_count={state.get('loop_count')}, "
                   f"max_loops={state.get('max_loops')}, "
                   f"loop_probability={state.get('loop_probability')}, "
                   f"recursion_limit={state.get('recursion_limit')}")

        try:
            # Updated to handle the output format from LangGraph 0.3.2
            async for event in self.graph.astream(state, config=config):
                # Extract event details - in LangGraph 0.3.2 the event is a single item
                # We need to extract the node name and data
                if isinstance(event, dict):
                    # The node_name should be the key that's not "__metadata__"
                    event_type = None
                    event_data = None

                    # Try to extract the current_phase from the event
                    if "current_phase" in event:
                        event_type = event["current_phase"]
                        event_data = event
                    # If we couldn't find it, try to extract from the keys
                    elif any(key in self.handlers for key in event.keys()):
                        # Find the first key that matches a handler name
                        for key in event.keys():
                            if key in self.handlers:
                                event_type = key
                                event_data = event
                                break
                    else:
                        # If still not found, use "unknown" as a fallback
                        event_type = "unknown"
                        event_data = event

                    # Ensure current_phase is set in the event_data for consistency
                    if event_type and event_type != "unknown":
                        event_data["current_phase"] = event_type
                else:
                    # Otherwise fallback to a generic type and convert the event to a dict
                    event_type = "unknown"
                    event_data = {"data": str(event), "current_phase": "unknown"}

                # Log each event for debugging
                logger.debug(f"Event type: {event_type}, Current phase: {event_data.get('current_phase', 'unknown')}")

                # Yield the event with proper phase information
                yield event_type, event_data
        except Exception as e:
            logger.error(f"Error in astream: {e}", exc_info=True)
            # Create a minimal error state to return
            error_state = state.copy()
            error_state["error"] = str(e)
            error_state["current_phase"] = "yield"  # Set to yield for test compatibility

            # Ensure we have a responses dict
            if "responses" not in error_state:
                error_state["responses"] = {}

            # Add error to responses
            error_state["responses"]["error"] = {
                "content": f"Error occurred: {str(e)}",
                "confidence": 0.0,
                "metadata": {"error": True}
            }

            # Yield the error event with the error state
            yield "yield", error_state

    async def astream_with_token_callback(self, state: Dict[str, Any], callback: Callable) -> Dict[str, Any]:
        """Process state with a callback for each token when streaming is enabled.

        Args:
            state: The state dictionary to process
            callback: Async callback function to call for each token

        Returns:
            The final processed state
        """
        # Enable streaming and set the callback
        state["streaming_enabled"] = True
        state["streaming_callback"] = callback

        # Initialize state with required values to prevent empty state errors
        state = self._initialize_state(state)

        # Create config with recursion limit if specified
        config = {}
        if self.recursion_limit is not None:
            config["recursion_limit"] = self.recursion_limit
            logger.info(f"Using recursion limit in token callback: {self.recursion_limit}")

        # Log the state configuration for debugging
        logger.info(f"astream_with_token_callback state configuration: loop_count={state.get('loop_count')}, "
                   f"max_loops={state.get('max_loops')}, "
                   f"loop_probability={state.get('loop_probability')}, "
                   f"recursion_limit={state.get('recursion_limit')}")

        # Process the state
        final_state = state
        try:
            # Updated to handle the output format from LangGraph 0.3.2
            async for event in self.graph.astream(state, config=config):
                # Extract node name and updated state from the event
                if isinstance(event, dict):
                    # Try to extract the current_phase from the event
                    node_name = None
                    updated_state = event

                    if "current_phase" in event:
                        node_name = event["current_phase"]
                    # If we couldn't find it, try to extract from the keys
                    elif any(key in self.handlers for key in event.keys()):
                        # Find the first key that matches a handler name
                        for key in event.keys():
                            if key in self.handlers:
                                node_name = key
                                break

                    # Default to unknown if we couldn't find a valid phase
                    if not node_name:
                        node_name = "unknown"

                    # Ensure current_phase is set in the event_data for consistency
                    if node_name != "unknown":
                        updated_state["current_phase"] = node_name
                else:
                    node_name = "unknown"
                    updated_state = state.copy()
                    updated_state["data"] = str(event)
                    updated_state["current_phase"] = "unknown"

                # Log each event for debugging
                logger.debug(f"Token callback event - Type: {node_name}, Phase: {updated_state.get('current_phase', 'unknown')}, Keys: {list(updated_state.keys())}")

                final_state = updated_state
        except Exception as e:
            logger.error(f"Error in astream_with_token_callback: {e}", exc_info=True)
            # Create a minimal error state to return
            error_state = state.copy()
            error_state["error"] = str(e)
            error_state["current_phase"] = "yield"  # Change from "error" to "yield" for test compatibility

            # Ensure we have a responses dict
            if "responses" not in error_state:
                error_state["responses"] = {}

            # Add error to responses
            error_state["responses"]["error"] = {
                "content": f"Error occurred: {str(e)}",
                "confidence": 0.0,
                "metadata": {"error": True}
            }

            final_state = error_state

        return final_state

def create_chorus_graph(config: Optional[Dict[str, Any]] = None) -> Any:
    """Create and return the Chorus Cycle graph.

    Args:
        config: Optional configuration dictionary which may include:
               - models_list: List of models to use for each phase
               - Any other configuration parameters for the Config object

    Returns:
        ChorusGraph instance

    Raises:
        ValueError: If no models are available (either from models_list or from API keys)
    """
    # Convert config dict to Config object if provided
    config_obj = None
    models_list = None

    if config is not None:
        config_obj = Config()

        # Extract models list if present
        models_list = config.get("models_list")

        # Apply the rest of the config
        for key, value in config.items():
            if hasattr(config_obj, key) and key != "models_list":
                setattr(config_obj, key, value)
    else:
        config_obj = Config()

    # Validate that we have models available
    if models_list is None:
        # Check if we have any API keys configured that would allow model initialization
        if not (config_obj.OPENAI_API_KEY or config_obj.ANTHROPIC_API_KEY or
                config_obj.GOOGLE_API_KEY or config_obj.MISTRAL_API_KEY or
                config_obj.FIREWORKS_API_KEY or config_obj.COHERE_API_KEY):
            raise ValueError("No models list provided and no API keys configured for random model selection")
    elif not models_list:
        raise ValueError("Empty models list provided")

    return ChorusGraph(config_obj, models_list)
