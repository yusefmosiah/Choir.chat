"""
Simple PostChain implementation using LangGraph with only the Action phase.

This module implements a simplified version of the PostChain with just the Action phase
using LangGraph's StateGraph for streaming results. This is intended as the first step
in the migration from Chorus Cycle to PostChain.
"""

from pydantic import BaseModel, Field
from typing import Dict, Any, Optional

import logging
import uuid
import copy
import json
from typing import Dict, Any, List, Optional, AsyncIterator, Union

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.messages.ai import AIMessageChunk

# LangGraph imports
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

# Local imports
from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    initialize_tool_compatible_model_list,
    get_model_provider,
    post_llm
)
from app.postchain.schemas.state import PostChainState
from app.postchain.utils import (
    validate_thread_id,
    load_state,
    recover_state,
    format_stream_event,
    handle_phase_error
)

# Configure logging
logger = logging.getLogger("postchain_simple")

# Define the structured output model for PostChain streaming
class PostchainStreamEvent(BaseModel):
    """
    Structured output model for PostChain streaming events.
    Provides a consistent data contract between backend and frontend.
    """
    # Core fields for all events
    current_phase: str = Field(..., description="Current active phase (action, experience, etc.)")
    phase_state: str = Field("in_progress", description="Phase state (in_progress, complete, error)")
    content: str = Field("", description="The current content for this phase")

    # Phase-specific metadata
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Phase-specific metadata")

    # Session information
    thread_id: Optional[str] = Field(None, description="Thread ID for persistence")
    error: Optional[str] = Field(None, description="Error message if applicable")

# Prompt templates for phases
COMMON_SYSTEM_PROMPT = """You are a helpful AI assistant for Choir's PostChain system.
You provide thoughtful and informative responses to user queries.
"""

ACTION_INSTRUCTION = """For this Action phase:
Your task is to provide a clear, informative initial response based solely on the user's query.
Do not use external tools or references at this stage - just respond with your best knowledge.
Keep your response concise and focused on the core question.
"""

EXPERIENCE_INSTRUCTION = """For this Experience phase:
Review the user's query and the initial action response.
Your task is to provide a reflective analysis of the action response, adding deeper context and exploring related concepts.
Consider different angles or interpretations of the query that might not have been addressed in the initial response.
"""

# Define state type alias
MessagesState = Dict[str, Any]

def create_system_message() -> SystemMessage:
    """Create a system message with the common system prompt."""
    return SystemMessage(content=COMMON_SYSTEM_PROMPT)

def create_message_with_phase(content: str, phase: str = "action") -> AIMessage:
    """
    Create an AIMessage with phase metadata.

    Args:
        content: The message content
        phase: The phase identifier (action, experience, etc.)

    Returns:
        AIMessage with phase metadata
    """
    # Log the creation for debugging
    logger.info(f"Creating message for phase '{phase}' with content: {content[:50]}...")
    return AIMessage(content=content, additional_kwargs={"phase": phase})

def log_experience_content(content, prefix="Experience phase"):
    if content:
        logger.info(f"{prefix} streaming content: {len(content)} characters")
        logger.info(f"{prefix} content first 100 chars: {content[:100]}...")
    else:
        logger.warning(f"{prefix} content is empty! This will cause issues with the client display.")

def create_postchain_graph(
    thread_id: str = None,
    config: Optional[Config] = None,
    model_config: Optional[ModelConfig] = None,
    disabled_providers: Optional[set] = None
) -> StateGraph:
    """
    Create a LangGraph for a PostChain with Action and Experience phases.

    Args:
        thread_id: Optional thread ID for persistence
        config: Optional configuration object. Will use app config if None.
        model_config: Optional model configuration.
        disabled_providers: Optional set of disabled providers.

    Returns:
        A configured StateGraph for the Action and Experience phases.
    """
    # Validate thread ID
    thread_id = validate_thread_id(thread_id)
    logger.info(f"Creating PostChain graph for thread {thread_id}")

    # Get configuration if not provided
    if config is None:
        config = Config()

    # Set up the model for both phases
    if model_config:
        models = [model_config]  # Make sure it's in a list
        model = model_config
        logger.info(f"Using specified model {model_config} for all phases")
    else:
        # Initialize model list with any disabled providers
        try:
            models = initialize_tool_compatible_model_list(config, disabled_providers=disabled_providers)
        except Exception as e:
            logger.error(f"Error initializing models: {e}")
            models = []

        if not models or len(models) == 0:
            # No models available
            logger.error("No models available - check API keys and config")
            raise ValueError("No language models available. Please check API keys and configuration.")

        # Use the first available model
        model = models[1]
        logger.info(f"Using model: {model}")

    # Initialize the state graph with the new state model
    builder = StateGraph(PostChainState)
    logger.info("Initialized StateGraph with PostChainState")

    # Define Action Phase Node
    async def action_node(state: PostChainState):
        """
        Process the Action phase of the PostChain.

        Args:
            state: The current PostChainState

        Yields:
            Stream of state updates during processing
        """
        # Set phase to processing
        state.phase_state["action"] = "processing"
        yield format_stream_event(state, content="Processing your request...")

        try:
            # Get user input from last message
            user_input = state.messages[-1].content if state.messages else ""

            # Prepend action instructions to the user input for the initial action phase
            enhanced_user_input = f"<action_instruction>{ACTION_INSTRUCTION}</action_instruction>\n\n{user_input}"

            # Create messages list with common system prompt
            messages = [create_system_message(), HumanMessage(content=enhanced_user_input)]

            # Convert model to a string format that post_llm expects
            model_name = f"{model.provider}/{model.model_name}" if hasattr(model, 'provider') and hasattr(model, 'model_name') else str(model)
            response = await post_llm(model_name, messages, config)

            # Get response content
            response_content = response.content if hasattr(response, 'content') else str(response)

            # Log the content for debugging
            logger.info(f"Action phase completed with content: {response_content[:100]}...")

            # Create AI message with phase metadata and add to state
            ai_message = create_message_with_phase(response_content, "action")
            state.messages.append(ai_message)

            # Update phase state
            state.phase_state["action"] = "complete"

            # Create event with explicit content
            action_event = {
                "current_phase": "action",
                "phase_state": "complete",
                "content": response_content,
                "thread_id": state.thread_id
            }

            # Yield event with explicit content rather than using format_stream_event
            yield action_event

            # Update state for next phase
            state.phase_state = {**state.phase_state, "action": "complete"}
            state.current_phase = "experience"

            # Final yield with state updates
            yield state

        except Exception as e:
            # Handle error
            handle_phase_error(state, "action", e)

            # Yield error event
            yield format_stream_event(state, error=str(e))

            # Update state for error case
            state.phase_state = {**state.phase_state, "action": "error"}
            state.error = str(e)
            state.current_phase = "yield"  # Skip to end on error

            # Final yield with error state
            yield state

    # Define Experience Phase Node
    async def experience_node(state: PostChainState):
        """
        Process the Experience phase of the PostChain.

        Args:
            state: The current PostChainState

        Yields:
            Stream of state updates during processing
        """
        # Set phase to processing
        state.phase_state["experience"] = "processing"
        yield format_stream_event(state, content="Enhancing with relevant information...")

        try:
            # Get the action message and user query from messages
            user_query = ""
            action_output = ""

            # Find the most recent user message for the query
            for message in reversed(state.messages):
                if isinstance(message, HumanMessage):
                    user_query = message.content
                    break

            # Find the most recent action message for action output
            for message in reversed(state.messages):
                if (isinstance(message, AIMessage) and
                    hasattr(message, 'additional_kwargs') and
                    message.additional_kwargs.get('phase') == 'action'):
                    action_output = message.content
                    break

            # Fallbacks if we couldn't find messages
            if not user_query:
                user_query = "No user query found"
                logger.warning("No user query found in messages")

            if not action_output:
                action_output = "No action output found"
                logger.warning("No action output found in messages")
            else:
                logger.info(f"Found action output: {action_output[:50]}...")

            # For subsequent phases like experience, use the instructions as the complete user prompt
            experience_prompt = f"{EXPERIENCE_INSTRUCTION}\n\nUser query: {user_query}\n\nInitial response: {action_output}"

            # Create messages list with common system prompt
            # We add the previous action response as an assistant message to maintain the proper pattern
            messages = [
                create_system_message(),
                HumanMessage(content=user_query),  # Original user query
                AIMessage(content=action_output),  # Action phase response
                HumanMessage(content=experience_prompt)  # Experience phase instructions
            ]

            model_name = f"{model.provider}/{model.model_name}" if hasattr(model, 'provider') and hasattr(model, 'model_name') else str(model)
            experience_response = await post_llm(model_name, messages, config)
            experience_content = experience_response.content if hasattr(experience_response, 'content') else str(experience_response)

            # Log for debugging
            log_experience_content(experience_content)

            # Create AI message with phase metadata and add to state
            experience_message = create_message_with_phase(experience_content, "experience")
            state.messages.append(experience_message)

            # Update phase state
            state.phase_state["experience"] = "complete"

            # Create event with explicit content
            experience_event = {
                "current_phase": "experience",
                "phase_state": "complete",
                "content": experience_content,
                "thread_id": state.thread_id
            }

            # Yield event with explicit content rather than using format_stream_event
            yield experience_event

            # Update state for next phase
            state.phase_state = {**state.phase_state, "experience": "complete"}
            state.current_phase = "yield"

            # Final yield with state updates
            yield state

        except Exception as e:
            # Handle error
            handle_phase_error(state, "experience", e)

            # Log the error details
            logger.error(f"Experience phase error: {str(e)}", exc_info=True)

            # Yield error event
            yield format_stream_event(state, error=str(e))

            # Update state for error case
            state.phase_state = {**state.phase_state, "experience": "error"}
            state.error = str(e)
            state.current_phase = "yield"  # Skip to end on error

            # Final yield with error state
            yield state

    # Add nodes to the graph
    builder.add_node("action", action_node)
    builder.add_node("experience", experience_node)

    # Add edges
    builder.add_edge("action", "experience")
    builder.add_edge("experience", END)

    # Set entry point
    builder.set_entry_point("action")

    # Configure persistence
    memory = MemorySaver()
    memory_key = f"postchain_{thread_id}"

    # Compile graph with persistence
    graph = builder.compile(checkpointer=memory)

    # Configure thread for persistence (set the key during use)
    thread_config = {"configurable": {"thread_id": thread_id, "checkpoint_id": memory_key}}

    return graph

async def stream_simple_postchain(
    user_query: str,
    config: Config,
    thread_id: Optional[str] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Stream the Simple PostChain graph execution with phase-by-phase streaming.
    Uses LangGraph's updates mode to provide clean node-by-node streaming.

    Args:
        user_query: The user's input query
        config: Configuration object
        thread_id: Optional thread ID for persistence

    Yields:
        Stream of structured events during execution
    """
    # Validate thread ID
    thread_id = validate_thread_id(thread_id)

    # Create graph
    graph = create_postchain_graph(thread_id=thread_id, config=config)

    # Create initial messages with user query
    initial_messages = [HumanMessage(content=user_query)]

    # Initial state
    initial_state = {
        "messages": initial_messages,
        "thread_id": thread_id
    }

    # Configure thread for persistence
    memory_key = f"postchain_{thread_id}"
    thread_config = {"configurable": {"thread_id": thread_id, "checkpoint_id": memory_key}}

    logger.info(f"Starting PostChain with query: {user_query[:50]}...")

    try:
        # Send initial "starting" event for action phase
        yield {
            "current_phase": "action",
            "phase_state": "processing",
            "content": "",
            "thread_id": thread_id
        }

        # Stream using updates mode for phase-by-phase streaming
        async for chunk in graph.astream(initial_state, config=thread_config, stream_mode="updates"):
            logger.info(f"Received chunk: {str(chunk)[:100]}...")

            # Process each node update
            for node_name, node_updates in chunk.items():
                # Skip processing for non-phase nodes if any
                if node_name not in ["action", "experience"]:
                    continue

                logger.info(f"Processing node {node_name} updates: {str(node_updates)[:200]}...")

                # Attempt to find content from multiple sources
                phase_content = ""

                # First check explicit content in any format_stream_event calls
                if "stream_events" in node_updates:
                    for event in node_updates["stream_events"]:
                        if isinstance(event, dict) and "content" in event and event["content"]:
                            phase_content = event.get("content", "")
                            logger.info(f"Found content in stream_events: {phase_content[:50]}...")
                            break

                # Next check messages if they were updated
                if phase_content == "" and "messages" in node_updates and node_updates["messages"]:
                    # Look for most recent AI message with this phase
                    messages = node_updates["messages"]
                    for msg in reversed(messages):
                        if (isinstance(msg, AIMessage) and
                            hasattr(msg, 'additional_kwargs') and
                            msg.additional_kwargs.get('phase') == node_name):
                            phase_content = msg.content
                            logger.info(f"Found content in messages: {phase_content[:50]}...")
                            break

                # Log if we still have no content
                if phase_content == "":
                    logger.warning(f"No content found for {node_name} phase in node updates")
                    # Debug log all keys in the update to help troubleshoot
                    logger.debug(f"Available keys in node update: {list(node_updates.keys())}")

                # Check phase state
                phase_state = "processing"
                if "phase_state" in node_updates and node_name in node_updates["phase_state"]:
                    phase_state = node_updates["phase_state"][node_name]

                # Yield phase update event with any content we found
                yield {
                    "current_phase": node_name,
                    "phase_state": phase_state,
                    "content": phase_content,
                    "thread_id": thread_id
                }

                # If this node is complete and we're transitioning to another phase,
                # send the initial event for the next phase
                if (phase_state == "complete" and
                    "current_phase" in node_updates and
                    node_updates["current_phase"] != node_name and
                    node_updates["current_phase"] in ["action", "experience", "yield"]):

                    next_phase = node_updates["current_phase"]
                    # Only yield for non-END phases
                    if next_phase != "yield":
                        yield {
                            "current_phase": next_phase,
                            "phase_state": "processing",
                            "content": "",
                            "thread_id": thread_id
                        }

    except Exception as e:
        logger.error(f"Error in stream_simple_postchain: {str(e)}", exc_info=True)
        yield {
            "current_phase": "error",
            "phase_state": "error",
            "content": "",
            "error": str(e),
            "thread_id": thread_id
        }
