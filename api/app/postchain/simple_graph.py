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

# Local imports
from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    initialize_tool_compatible_model_list,
    get_model_provider,
    astream_langchain_llm_completion,
    post_llm
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
ACTION_SYSTEM_PROMPT = """You are an action agent for the initial response to user queries.
Your task is to provide a clear, informative initial response based solely on the user's query.
Do not use external tools or references at this stage - just respond with your best knowledge.
Keep your response concise and focused on the core question.
"""

EXPERIENCE_SYSTEM_PROMPT = """You are an experience agent for Choir's PostChain system.
Review the user's query and the initial action response.
Your task is to provide a reflective analysis of the action response, adding deeper context and exploring related concepts.
Consider different angles or interpretations of the query that might not have been addressed in the initial response.
"""

# Define state type alias
MessagesState = Dict[str, Any]

def create_system_message(phase: str = "action") -> SystemMessage:
    """Create a system message for the specified phase."""
    if phase == "experience":
        return SystemMessage(content=EXPERIENCE_SYSTEM_PROMPT)
    else:
        return SystemMessage(content=ACTION_SYSTEM_PROMPT)

def create_message_with_phase(content: str, phase: str = "action") -> AIMessage:
    """
    Create an AIMessage with phase metadata.

    Args:
        content: The message content
        phase: The phase identifier (action, experience, etc.)

    Returns:
        AIMessage with phase metadata
    """
    return AIMessage(content=content, additional_kwargs={"phase": phase})

def log_experience_content(content, prefix="Experience phase"):
    if content:
        logger.info(f"{prefix} streaming content: {len(content)} characters")
        logger.info(f"{prefix} content first 100 chars: {content[:100]}...")
    else:
        logger.warning(f"{prefix} content is empty! This will cause issues with the client display.")

def create_simple_postchain_graph(
    config: Optional[Config] = None,
    model_config: Optional[ModelConfig] = None,
    disabled_providers: Optional[set] = None
) -> StateGraph:
    """
    Create a LangGraph for a simple PostChain with Action and Experience phases.

    Args:
        config: Optional configuration object. Will use app config if None.
        model_config: Optional model configuration.
        disabled_providers: Optional set of disabled providers.

    Returns:
        A configured StateGraph for the Action and Experience phases.
    """
    # Debug information
    logger.info("Creating Simple PostChain graph with Action and Experience phases")

    # Get configuration if not provided
    if config is None:
        config = Config()

    # Set up the model for both phases
    if model_config:
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
        model = models[0]
        logger.info(f"Using model: {model}")

    # Initialize the state graph
    builder = StateGraph(MessagesState)
    logger.info("Initialized StateGraph with MessagesState")

    # Define Action Phase Node
    async def action_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Action phase of the PostChain.

        This node:
        1. Takes the user query
        2. Generates a direct response with a model
        3. Attaches phase metadata to the output

        Returns:
            Updated state with Action phase completed
        """
        # Get the model name
        if hasattr(model, "provider") and hasattr(model, "model_name"):
            model_name = f"{model.provider}/{model.model_name}"
        else:
            # Model is likely already a string
            try:
                model_name = str(model)
            except Exception as e:
                logger.error(f"Error converting model to string: {e}")
                model_name = "anthropic/claude-3-5-haiku-latest"  # Fallback

        logger.info(f"Action phase using model: {model_name}")

        # Get the latest human message
        latest_human_message = None
        for message in reversed(state["messages"]):
            if isinstance(message, HumanMessage):
                latest_human_message = message
                break

        if not latest_human_message:
            raise ValueError("No human message found in messages")

        # Create system message for action phase
        system_message = create_system_message("action")

        # Prepare messages for the action phase
        messages_for_api = [
            system_message,
            latest_human_message
        ]

        # Get response
        completion = ""

        # Convert to string if it's a ModelConfig
        if hasattr(model, "__str__"):
            model_name_str = str(model)
        else:
            model_name_str = model_name  # Already a string

        provider, _ = get_model_provider(model_name_str)

        try:
            # Use the new post_llm function with streaming enabled
            stream_response = await post_llm(model_name_str, messages_for_api, config, stream=True)
            async for chunk in stream_response:
                # Create action phase AIMessage with phase metadata
                if hasattr(chunk, "content") and chunk.content:
                    completion += chunk.content

                    # Create a new message with phase metadata for each chunk
                    ai_message = create_message_with_phase(completion, "action")

                    # Update messages list, replacing any existing action message
                    for i, msg in enumerate(state["messages"]):
                        if isinstance(msg, AIMessage) and msg.additional_kwargs.get("phase") == "action":
                            state["messages"].pop(i)
                            break
                    state["messages"].append(ai_message)

                    # Yield streaming update for this phase
                    yield {
                        "messages": state["messages"],
                        "current_phase": "action",
                        "action_content": completion,
                        "current_model": model
                    }
        except Exception as e:
            logger.error(f"Error in action_node: {str(e)}", exc_info=True)
            # Create a fallback message on error
            fallback_content = f"I encountered an issue while processing your query. Error: {str(e)}"
            ai_message = create_message_with_phase(fallback_content, "action")
            state["messages"].append(ai_message)

        # Store the action result in state for the next phase
        state["action_content"] = completion

        # Final yield
        yield state

    # Define Experience Phase Node
    async def experience_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Experience phase of the PostChain.
        Uses the LangGraph state to access previous messages and generate an experience response.
        """
        logger.info("Starting Experience phase")

        # Get the model name from globals since it's defined at the module level
        # This matches how action_node is getting the model
        model_name = f"{model.provider}/{model.model_name}" if hasattr(model, "provider") and hasattr(model, "model_name") else str(model)

        logger.info(f"Experience phase using model: {model_name}")

        # Create a proper system message
        system_message = create_system_message("experience")

        # Create a fresh messages list with the system message first
        experience_messages = [system_message] + state["messages"]

        try:
            # Use post_llm with proper config object
            experience_content = ""
            
            # For debugging - ensure we're sending a valid request to the model
            logger.info(f"Experience phase sending {len(experience_messages)} messages to model")
            for idx, msg in enumerate(experience_messages):
                msg_type = msg.__class__.__name__
                msg_content = msg.content[:100] + "..." if msg.content and len(msg.content) > 100 else msg.content
                logger.info(f"Message {idx} ({msg_type}): {msg_content}")
            
            stream_response = await post_llm(model_name, experience_messages, config, stream=True)

            # Process streamed content
            async for chunk in stream_response:
                if hasattr(chunk, "content") and chunk.content:
                    experience_content += chunk.content

                    # Enhanced logging for experience content
                    log_experience_content(experience_content, "Experience phase streaming")
                    
                    # Create a fresh copy of state to avoid modifying the original
                    # This is important for LangGraph's state management
                    new_state = state.copy()
                    new_state["experience_content"] = experience_content
                    new_state["current_phase"] = "experience"

                    # Yield the updated state with experience content for streaming
                    logger.info(f"Yielding experience update with {len(experience_content)} characters")
                    yield new_state
            
            # If we have no content after streaming, create a default experience response
            if not experience_content:
                logger.warning("Experience phase produced no content! Creating fallback content.")
                experience_content = "Based on your query, I've leveraged my knowledge to provide this response. If you need more specific information or have questions about the details, please let me know."
            
            # Create an experience message to add to the messages list
            logger.info(f"Creating final experience message with {len(experience_content)} characters")
            experience_message = create_message_with_phase(experience_content, "experience")
            
            # Create a fresh copy of messages and append the experience message
            messages = state["messages"].copy()
            messages.append(experience_message)
            
            # Create the final state
            final_state = {
                **state,
                "messages": messages,
                "current_phase": "experience",
                "experience_content": experience_content
            }
            
            # Log the final experience message
            logger.info(f"Final experience message added to state, total messages: {len(messages)}")
            
            # Yield the final state with the experience message included
            yield final_state
        except Exception as e:
            logger.error(f"Error in experience_node: {str(e)}", exc_info=True)

            # Create fallback content on error
            fallback_content = f"I encountered an issue during the experience phase."
            experience_message = create_message_with_phase(fallback_content, "experience")

            # Update messages with fallback content
            messages = state["messages"].copy()
            messages.append(experience_message)

            # Yield error state
            yield {
                **state,
                "messages": messages,
                "current_phase": "experience",
                "experience_content": fallback_content
            }

    # Add nodes to the graph
    builder.add_node("action", action_node)
    builder.add_node("experience", experience_node)

    # Add edges to connect phases sequentially
    builder.add_edge(START, "action")
    builder.add_edge("action", "experience")
    builder.add_edge("experience", END)

    # Compile and return the graph
    return builder.compile()

async def invoke_simple_postchain(
    user_query: str,
    config: Config,
    thread_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Invoke the Simple PostChain graph with a user query.

    Args:
        user_query: The user's input query
        config: Configuration object
        thread_id: Optional thread ID for persistence

    Returns:
        Dictionary with the final state
    """
    # Create graph
    graph = create_simple_postchain_graph(config=config)

    # Create initial messages with user query
    initial_messages = [HumanMessage(content=user_query)]

    # Initial state
    initial_state = {
        "messages": initial_messages,
        "thread_id": thread_id or str(uuid.uuid4())
    }

    # Configure thread for persistence
    thread_config = {"configurable": {"thread_id": initial_state["thread_id"]}}

    # Execute graph
    final_state = await graph.ainvoke(initial_state, config=thread_config)

    # Extract phase outputs
    action_output = None
    experience_output = None

    for message in final_state["messages"]:
        if isinstance(message, AIMessage):
            phase = message.additional_kwargs.get("phase")
            if phase == "action":
                action_output = message.content
            elif phase == "experience":
                experience_output = message.content

    # Return combined state with phase outputs
    return {
        **final_state,
        "phase_outputs": {
            "action": action_output,
            "experience": experience_output
        },
        "user_query": user_query
    }

async def stream_simple_postchain(
    user_query: str,
    config: Config,
    thread_id: Optional[str] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Stream the Simple PostChain graph execution with phase-by-phase streaming.
    Uses structured outputs with consistent data contract.

    Args:
        user_query: The user's input query
        config: Configuration object
        thread_id: Optional thread ID for persistence

    Yields:
        Stream of structured events during execution
    """
    # Create graph
    graph = create_simple_postchain_graph(config=config)

    # Create initial messages with user query
    initial_messages = [HumanMessage(content=user_query)]

    # Initial state
    thread_id = thread_id or str(uuid.uuid4())
    initial_state = {
        "messages": initial_messages,
        "thread_id": thread_id
    }

    # Configure thread for persistence
    thread_config = {"configurable": {"thread_id": thread_id}}

    logger.info(f"Starting Simple PostChain stream with query: {user_query[:50]}...")

    # Track the phase outputs
    action_output = ""
    experience_output = ""
    current_phase = "action"

    # Track chunk count per phase for better debugging
    action_chunks = 0
    experience_chunks = 0

    # Use stream_mode parameter explicitly
    stream_mode = "values"
    logger.info(f"Using stream_mode: {stream_mode}")

    try:
        # Send initial "starting" event for action phase
        initial_event = PostchainStreamEvent(
            current_phase="action",
            phase_state="in_progress",
            content="",
            thread_id=thread_id
        )
        yield initial_event.model_dump()

        # Stream execution with values mode
        logger.info("Starting graph.astream execution")
        event_count = 0
        async for chunk in graph.astream(initial_state, config=thread_config, stream_mode=stream_mode):
            event_count += 1

            # For better debugging, log chunk type and content preview
            if isinstance(chunk, dict):
                keys = list(chunk.keys())
                logger.debug(f"[{event_count}] Chunk keys: {keys}")

                # Debug: Check for experience_content
                if "experience_content" in chunk:
                    exp_content = chunk["experience_content"]
                    logger.info(f"FOUND DIRECT experience_content in chunk: {len(exp_content)} chars")
                    experience_output = exp_content

                # Check if phase has changed
                if "current_phase" in chunk:
                    new_phase = chunk["current_phase"]
                    if new_phase != current_phase:
                        logger.info(f"Phase transition: {current_phase} -> {new_phase}")

                        # Send completion event for previous phase
                        if current_phase == "action":
                            logger.info(f"Action phase complete - received {action_chunks} chunks, output length: {len(action_output)}")
                            completion_event = PostchainStreamEvent(
                                current_phase="action",
                                phase_state="complete",
                                content=action_output,
                                thread_id=thread_id
                            )
                            logger.info(f"Sending action completion event with content length: {len(action_output)}")
                            yield completion_event.model_dump()

                            # Send initial event for next phase
                            initial_experience_event = PostchainStreamEvent(
                                current_phase="experience",
                                phase_state="in_progress",
                                content="",
                                thread_id=thread_id
                            )
                            logger.info("Sending initial experience event (empty content)")
                            yield initial_experience_event.model_dump()

                        current_phase = new_phase

                # Extract phase content from the chunk
                if current_phase == "action" and "action_content" in chunk:
                    action_chunks += 1
                    action_output = chunk["action_content"]
                    logger.info(f"[{event_count}] Action chunk {action_chunks}: {action_output[:30]}...")

                    # Yield action phase update
                    update_event = PostchainStreamEvent(
                        current_phase="action",
                        phase_state="in_progress",
                        content=action_output,
                        thread_id=thread_id
                    )
                    yield update_event.model_dump()

                # Check for experience content in various places
                elif current_phase == "experience":
                    # Primary location
                    if "experience_content" in chunk:
                        experience_chunks += 1
                        chunk_exp_content = chunk["experience_content"]
                        log_experience_content(chunk_exp_content)

                        # CRITICAL: Store this content in our variable to preserve it
                        experience_output = chunk_exp_content

                        # Yield experience phase update
                        update_event = PostchainStreamEvent(
                            current_phase="experience",
                            phase_state="in_progress",
                            content=experience_output,
                            thread_id=thread_id
                        )

                        # Log the actual content being sent in the event
                        serialized = json.dumps(update_event.model_dump())
                        logger.info(f"Sending experience update event with {len(experience_output)} chars: {serialized[:100]}...")

                        yield update_event.model_dump()

                    # Check nested messages for experience content
                    elif "messages" in chunk:
                        for message in chunk.get("messages", []):
                            if hasattr(message, "additional_kwargs") and message.additional_kwargs.get("phase") == "experience":
                                extracted_content = message.content
                                if extracted_content:
                                    logger.info(f"Found experience content in message: {len(extracted_content)} chars")
                                    experience_output = extracted_content

                                    # Send update with this content
                                    update_event = PostchainStreamEvent(
                                        current_phase="experience",
                                        phase_state="in_progress",
                                        content=experience_output,
                                        thread_id=thread_id
                                    )
                                    yield update_event.model_dump()

        logger.info(f"Completed streaming after {event_count} events")
        logger.info(f"Final experience_output length: {len(experience_output)} chars")

        # Fallback: If we've transitioned to experience phase but still have no content
        if current_phase == "experience" and not experience_output:
            logger.warning("Experience phase was detected but has no content - attempting recovery")

            # Attempt to retrieve experience content directly with a new invocation
            try:
                logger.info("Executing synchronous query to recover experience content")
                # Use the final state we have to get the experience content
                final_state = await graph.ainvoke(initial_state, config=thread_config)

                # Look for experience message in the final state
                for message in final_state.get("messages", []):
                    if hasattr(message, "additional_kwargs") and message.additional_kwargs.get("phase") == "experience":
                        experience_output = message.content
                        log_experience_content(experience_output, "Recovered experience")
                        break

                # If we found direct experience_content in the state, use that
                if "experience_content" in final_state:
                    direct_exp = final_state["experience_content"]
                    if direct_exp and len(direct_exp) > 0:
                        experience_output = direct_exp
                        log_experience_content(experience_output, "Recovered direct experience")
            except Exception as e:
                logger.error(f"Error recovering experience content: {str(e)}")

        # Final check: Make sure we have experience content
        if not experience_output and current_phase == "experience":
            logger.warning("Still missing experience content - execution will proceed with empty content")

        # Always force the final event to include whatever experience content we have
        logger.info(f"Sending final experience completion with {len(experience_output)} chars")

        # Send a final completion event for the experience phase
        completion_event = PostchainStreamEvent(
            current_phase="experience",
            phase_state="complete",
            content=experience_output,
            thread_id=thread_id
        )

        # Log the final completion event that's being sent
        serialized = json.dumps(completion_event.model_dump())
        logger.info(f"Sending final completion event: {serialized[:100]}...")

        yield completion_event.model_dump()
    except Exception as e:
        logger.error(f"Error in stream_simple_postchain: {str(e)}", exc_info=True)

        # Send an error event for the current phase
        error_event = PostchainStreamEvent(
            current_phase=current_phase,
            phase_state="error",
            content=experience_output if current_phase == "experience" else action_output,
            thread_id=thread_id,
            error=str(e)
        )
        yield error_event.model_dump()
        raise
