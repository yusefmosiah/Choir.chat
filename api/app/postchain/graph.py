"""
LangGraph implementation for the PostChain (AEIOU-Y) cycle.
This is a simplified version that will be built incrementally.
"""

import logging
import uuid
import os
import re
from typing import Dict, Any, List, Optional, AsyncIterator

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.messages.ai import AIMessageChunk
from langchain_core.runnables import RunnableConfig

# LangGraph imports
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import ToolNode

# Local imports
from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    get_model_provider,
    astream_langchain_llm_completion
)

# Configure logging
logger = logging.getLogger("postchain_graph")

# Phase definitions
phases = ["action", "experience", "intention", "observation", "understanding", "yield"]
logger.info(f"Defined PostChain phases: {phases}")

# Prompt templates for each phase
PROMPTS = {
    "action": """You are an action agent for the initial response to user queries.
Your task is to provide a clear, informative initial response based solely on the user's query.
Do not use external tools or references at this stage - just respond with your best knowledge.
Keep your response concise and focused on the core question.
""",
    "experience": """You are an experience agent for enriching responses with background knowledge.
Your task is to add depth and context to the conversation by providing relevant background information.
Use the search results provided to augment the initial response with additional relevant information.
Focus on factual information that provides a richer understanding of the topic.
Integrate the search results naturally into your response, adding value to the initial answer.
"""
}

# System prompts for each phase (currently just the first two phases)
ACTION_SYSTEM_PROMPT = PROMPTS["action"]
EXPERIENCE_SYSTEM_PROMPT = PROMPTS["experience"]

# Define state type aliases
MessagesState = Dict[str, Any]

def get_phase_prompt(phase: str) -> str:
    """Get the prompt for a specific phase."""
    return PROMPTS.get(phase, "")

def extract_last_message(messages: List[BaseMessage], role_type=AIMessage) -> Optional[BaseMessage]:
    """Extract the last message of a specific role type."""
    for message in reversed(messages):
        if isinstance(message, role_type):
            return message
    return None

def create_system_message(phase: str) -> SystemMessage:
    """Create a system message for a specific phase."""
    return SystemMessage(content=get_phase_prompt(phase))

def get_phase_metadata(message: BaseMessage) -> Optional[str]:
    """Extract phase metadata from a message."""
    if hasattr(message, "additional_kwargs") and "phase" in message.additional_kwargs:
        return message.additional_kwargs["phase"]
    return None

def create_message_with_phase(content: str, phase: str) -> AIMessage:
    """Create an AI message with phase metadata."""
    message = AIMessage(content=content)
    if not hasattr(message, "additional_kwargs"):
        message.additional_kwargs = {}
    message.additional_kwargs["phase"] = phase
    return message

def debug_model_config(model_config):
    """Debug information about a model configuration."""
    try:
        if hasattr(model_config, "provider") and hasattr(model_config, "model_name"):
            logger.info(f"Model config: {model_config.provider}/{model_config.model_name}")
        else:
            logger.info(f"Model config: {model_config}")
    except Exception as e:
        logger.error(f"Error debugging model config: {e}")

def create_postchain_graph(
    config: Optional[Config] = None,
    disabled_providers: Optional[set] = None,
    include_phases: Optional[List[str]] = None
) -> StateGraph:
    """
    Create a LangGraph for the PostChain AEIOU-Y pattern.
    This is a simplified version that can be built incrementally.

    Args:
        config: Optional configuration object. Will use app config if None.
        disabled_providers: Optional set of disabled providers.
        include_phases: List of phases to include in the graph. If None, only includes "action".

    Returns:
        A configured StateGraph for the PostChain pattern.
    """
    # Get configuration if not provided
    if config is None:
        config = Config.from_env()

    # Default to just action phase if not specified
    if include_phases is None:
        include_phases = ["action"]

    # Initialize model list
    models = initialize_model_list(config, disabled_providers=disabled_providers)

    # Select a model for each phase (using the first available one for simplicity)
    if not models:
        raise ValueError("No models available")

    action_model = models[0]  # Use the first available model
    experience_model = models[0]  # Use the same model for experience phase

    logger.info(f"Action phase using model: {action_model}")
    if "experience" in include_phases:
        logger.info(f"Experience phase using model: {experience_model}")

    # Initialize the state graph
    builder = StateGraph(MessagesState)
    logger.info("Initialized StateGraph with MessagesState")

    # Define Action Phase Node
    async def action_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Action phase - initial response based on user query.
        """
        # Get model name
        model_name = f"{action_model.provider}/{action_model.model_name}"
        logger.info(f"Action phase using model: {model_name}")

        # Get the latest human message
        latest_human_message = None
        for message in reversed(state["messages"]):
            if isinstance(message, HumanMessage):
                latest_human_message = message
                break

        if not latest_human_message:
            raise ValueError("No human message found in messages")

        # Create system message for this phase
        system_message = create_system_message("action")

        # Prepare messages for the model
        messages = [
            system_message,
            latest_human_message
        ]

        # Call the model
        response_content = ""
        async for chunk in astream_langchain_llm_completion(
            model_name=model_name,
            messages=messages,
            config=config
        ):
            if chunk.content:
                response_content += chunk.content

        # Create AI message with phase metadata
        ai_message = create_message_with_phase(response_content, "action")

        # Update state with the new message
        new_messages = state["messages"].copy()
        new_messages.append(ai_message)

        return {"messages": new_messages}

    # Define Experience Phase Node (Vector DB Enrichment)
    async def experience_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Experience phase - enrich response with vector search results.
        """
        # Get model name
        model_name = f"{experience_model.provider}/{experience_model.model_name}"
        logger.info(f"Experience phase using model: {model_name}")

        # Get the latest human message and action response
        latest_human_message = None
        latest_action_message = None

        for message in reversed(state["messages"]):
            if isinstance(message, HumanMessage) and latest_human_message is None:
                latest_human_message = message
            elif isinstance(message, AIMessage) and get_phase_metadata(message) == "action" and latest_action_message is None:
                latest_action_message = message

            if latest_human_message and latest_action_message:
                break

        if not latest_human_message:
            raise ValueError("No human message found in messages")

        if not latest_action_message:
            raise ValueError("No action message found in messages")

        # Create system message for this phase
        system_message = create_system_message("experience")

        # Get the original query to search for
        query = latest_human_message.content

        # Create a message instructing to search the vector DB
        search_instruction = f"""
        First, I need you to search for relevant information in our vector database to enrich the initial response.

        Here's the user's query: "{query}"

        Retrieving relevant information from the vector database is critical to providing a complete answer.
        """

        # Create a message about the initial response
        action_context = f"""
        Initial response (to be enriched with vector search results):
        {latest_action_message.content}
        """

        # Prepare messages for the model
        messages = [
            system_message,
            latest_human_message,
            AIMessage(content=latest_action_message.content),
            HumanMessage(content=f"{search_instruction}\n\n{action_context}")
        ]

        # Call the model to get the experience-enriched response
        response_content = ""
        async for chunk in astream_langchain_llm_completion(
            model_name=model_name,
            messages=messages,
            config=config
        ):
            if chunk.content:
                response_content += chunk.content

        # Create AI message with phase metadata
        ai_message = create_message_with_phase(response_content, "experience")

        # Update state with the new message
        new_messages = state["messages"].copy()
        new_messages.append(ai_message)

        return {"messages": new_messages}

    # Add nodes to the graph
    builder.add_node("action", action_node)

    # Add experience node if included
    if "experience" in include_phases:
        builder.add_node("experience", experience_node)

    # Start with action phase
    builder.add_edge(START, "action")

    # Connect action to experience if included, otherwise end
    if "experience" in include_phases:
        builder.add_edge("action", "experience")
        builder.add_edge("experience", END)
    else:
        builder.add_edge("action", END)

    # Compile the graph
    return builder.compile()

def _has_tool_calls(state: MessagesState) -> bool:
    """Check if the current state has any tool calls."""
    # For now, just a placeholder - will be implemented when adding tool support
    return False

def extract_phase_outputs(messages: List[BaseMessage]) -> Dict[str, str]:
    """
    Extract outputs from each phase from a list of messages.

    Args:
        messages: List of messages to extract from

    Returns:
        Dictionary mapping phase names to their outputs
    """
    outputs = {}

    for message in messages:
        if not isinstance(message, AIMessage):
            continue

        phase = get_phase_metadata(message)
        if phase and phase in phases:
            outputs[phase] = message.content

    return outputs

async def stream_postchain(
    user_query: str,
    config: Config,
    thread_id: Optional[str] = None,
    include_phases: Optional[List[str]] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Stream the PostChain graph execution with token-level streaming.

    This implementation preserves phase-specific content and emits metadata events
    when transitioning between phases, allowing clients to display multiple phases
    simultaneously.

    Args:
        user_query: The user's input query
        config: Configuration object
        thread_id: Optional thread ID for persistence
        include_phases: List of phases to include in the graph. If None, only includes "action".

    Yields:
        Stream of state updates during execution, including token-level streaming and phase transitions
    """
    # Generate thread_id if not provided
    if thread_id is None:
        thread_id = str(uuid.uuid4())

    # Default phases
    if include_phases is None:
        include_phases = ["action"]

    # Get models for each phase
    models = initialize_model_list(config)
    if not models:
        raise ValueError("No models available")
    model = models[0]  # Use the first available model
    model_name = f"{model.provider}/{model.model_name}"

    # Create initial messages with user query
    messages = [
        create_system_message("action"),
        HumanMessage(content=user_query)
    ]

    # Track previous phase outputs for client display
    previous_phases = {}
    current_phase = "action"

    # First yield metadata event including the phase info
    yield {
        "event": "metadata",
        "data": {
            "thread_id": thread_id,
            "phase": current_phase,
            "previous_phases": previous_phases
        }
    }

    try:
        logger.info(f"Starting action phase streaming for thread {thread_id}")
        # Process the action phase first
        action_response = ""
        async for chunk in astream_langchain_llm_completion(
            model_name=model_name,
            messages=messages,
            config=config
        ):
            if chunk.content:
                # Yield each token as a chunk event with consistent dictionary structure
                yield {
                    "event": "chunk",
                    "data": {
                        "phase": current_phase,
                        "content": chunk.content
                    }
                }
                action_response += chunk.content

        # Create action message with phase metadata
        action_message = create_message_with_phase(action_response, "action")
        messages.append(action_message)

        # Store action phase output for client reference
        previous_phases["action"] = action_response
        logger.info(f"Completed action phase streaming for thread {thread_id}")

        # Process additional phases if requested
        if "experience" in include_phases and include_phases.index("experience") > include_phases.index("action"):
            logger.info(f"Starting experience phase streaming for thread {thread_id}")
            # Signal phase transition to experience
            current_phase = "experience"
            yield {
                "event": "metadata",
                "data": {
                    "thread_id": thread_id,
                    "phase": current_phase,
                    "previous_phases": previous_phases
                }
            }

            # Create experience phase messages
            experience_messages = [
                create_system_message("experience"),
                HumanMessage(content=user_query),
                action_message
            ]

            # Add search instruction
            search_instruction = f"""
            First, I need you to search for relevant information in our vector database to enrich the initial response.

            Here's the user's query: "{user_query}"

            Retrieving relevant information from the vector database is critical to providing a complete answer.
            """

            # Add context about the initial response
            action_context = f"""
            Initial response (to be enriched with vector search results):
            {action_message.content}
            """

            # Add an additional human message with search instructions
            experience_messages.append(HumanMessage(content=f"{search_instruction}\n\n{action_context}"))

            # Stream the experience phase response token by token
            experience_response = ""
            async for chunk in astream_langchain_llm_completion(
                model_name=model_name,
                messages=experience_messages,
                config=config
            ):
                if chunk.content:
                    # Yield each token as a chunk event with consistent dictionary structure
                    yield {
                        "event": "chunk",
                        "data": {
                            "phase": current_phase,
                            "content": chunk.content
                        }
                    }
                    experience_response += chunk.content

            # Create experience message with phase metadata
            experience_message = create_message_with_phase(experience_response, "experience")
            messages.append(experience_message)

            # Store experience phase output
            previous_phases["experience"] = experience_response
            logger.info(f"Completed experience phase streaming for thread {thread_id}")

        # Additional phases can be added here following the same pattern

    except Exception as e:
        logger.error(f"Error in stream_postchain: {str(e)}", exc_info=True)
        # Yield error event
        yield {
            "event": "error",
            "data": str(e)
        }
        return

    # Final completion event with all phase information
    logger.info(f"Streaming completed for thread {thread_id}, phases: {list(previous_phases.keys())}")
    yield {
        "event": "done",
        "data": {
            "thread_id": thread_id,
            "phase": current_phase,
            "previous_phases": previous_phases  # Include all phase outputs
        }
    }
