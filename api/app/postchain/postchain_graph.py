"""
PostChain implementation using LangGraph.

This module implements the Chorus Cycle (AEIOU-Y) pattern using LangGraph's StateGraph.
Each phase is integrated with proper ToolNode patterns for tool access and follows
the established conventions in the codebase.
"""

import logging
import random
import uuid
import os
import re
from typing import Dict, Any, List, Optional, AsyncIterator

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage
from langchain_core.messages.ai import AIMessageChunk
from langchain_core.runnables import RunnableConfig
from langchain_core.tools import BaseTool as LCBaseTool

# LangGraph imports
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import ToolNode

# Local imports
from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    initialize_tool_compatible_model_list,
    get_model_provider,
    astream_langchain_llm_completion
)
from app.tools.base import BaseTool
from app.tools.qdrant import qdrant_search, qdrant_store
from app.tools.web_search import WebSearchTool

# Configure logging
logger = logging.getLogger("postchain")

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
Use your knowledge database to add important context that might not be explicitly mentioned.
Focus on factual information that provides a richer understanding of the topic.
""",
    "intention": """You are an intention agent for aligning with user intent.
Your task is to ensure the response matches what the user is truly asking for.
Consider the user's likely goals and needs beyond just the literal question.
Refine the response to better address the underlying intent.
""",
    "observation": """You are an observation agent for recording semantic connections.
Your task is to identify key concepts, entities, and relationships in the conversation.
Note any important information that should be remembered for future interactions.
Look for conceptual links that might be relevant for knowledge graph construction.
""",
    "understanding": """You are an understanding agent for determining next steps.
Your task is to assess whether the current response fully addresses the user's needs.
Evaluate if additional follow-up or clarification would be beneficial.
Make a clear determination about whether the response is complete or needs more work.
""",
    "yield": """You are a yield agent for producing the final response.
Your task is to synthesize all the insights from previous phases into a cohesive final response.
Ensure the response is well-structured, comprehensive, accurate, and addresses the user's intent.
Deliver a polished, final output that represents our best possible answer.
"""
}

# System prompts for each phase
ACTION_SYSTEM_PROMPT = PROMPTS["action"]
EXPERIENCE_SYSTEM_PROMPT = PROMPTS["experience"]
INTENTION_SYSTEM_PROMPT = PROMPTS["intention"]
OBSERVATION_SYSTEM_PROMPT = PROMPTS["observation"]
UNDERSTANDING_SYSTEM_PROMPT = PROMPTS["understanding"]
YIELD_SYSTEM_PROMPT = PROMPTS["yield"]

# Define state type aliases
MessagesState = Dict[str, Any]

def get_phase_prompt(phase: str) -> str:
    """Get the system prompt for a specific phase."""
    return PROMPTS.get(phase, ACTION_SYSTEM_PROMPT)

def extract_last_message(messages: List[BaseMessage], role_type=AIMessage) -> Optional[BaseMessage]:
    """Extract the last message of a specific type from a list of messages."""
    for message in reversed(messages):
        if isinstance(message, role_type):
            return message
    return None

def create_system_message(phase: str) -> SystemMessage:
    """Create a system message for a specific phase."""
    return SystemMessage(content=get_phase_prompt(phase))

def get_phase_metadata(message: BaseMessage) -> Optional[str]:
    """
    Extract phase metadata from a message.

    Args:
        message: The message to extract phase from

    Returns:
        The phase string if found, None otherwise
    """
    if not isinstance(message, AIMessage):
        return None

    # Try to get from additional_kwargs.phase
    if hasattr(message, 'additional_kwargs') and isinstance(message.additional_kwargs, dict):
        phase = message.additional_kwargs.get('phase')
        if phase:
            return phase

    # Try to find phase in content using a pattern match
    # Format: [phase:ACTION] or similar indicators
    if hasattr(message, 'content') and message.content:
        match = re.search(r'\[phase:(\w+)\]', message.content, re.IGNORECASE)
        if match:
            phase = match.group(1).lower()
            # Convert to canonical phase name if it's a match
            for p in phases:
                if phase in p or p in phase:
                    return p

    return None

def create_message_with_phase(content: str, phase: str) -> AIMessage:
    """
    Create an AIMessage with phase metadata.

    Args:
        content: The message content
        phase: The phase to tag the message with

    Returns:
        AIMessage with phase metadata
    """
    return AIMessage(content=content, additional_kwargs={"phase": phase})

def debug_model_config(model_config):
    """Debug function to print information about a ModelConfig object."""
    logger.info(f"Debug ModelConfig: {model_config}")
    logger.info(f"Type: {type(model_config)}")
    logger.info(f"Dir: {dir(model_config)}")

    try:
        logger.info(f"String representation: {str(model_config)}")
    except Exception as e:
        logger.info(f"Error converting to string: {e}")

    try:
        if hasattr(model_config, "provider") and hasattr(model_config, "model_name"):
            logger.info(f"Provider: {model_config.provider}")
            logger.info(f"Model name: {model_config.model_name}")
            logger.info(f"Combined: {model_config.provider}/{model_config.model_name}")
    except Exception as e:
        logger.info(f"Error accessing attributes: {e}")

    return model_config

def create_postchain_graph(
    config: Optional[Config] = None,
    model_config: Optional[ModelConfig] = None,
    disabled_providers: Optional[set] = None
) -> StateGraph:
    """
    Create a LangGraph for the PostChain AEIOU-Y pattern.

    This function creates a StateGraph with nodes for each phase of the
    Post Chain pattern, and edges connecting them in the right order.

    Args:
        config: Optional configuration object. Will use app config if None.
        model_config: Optional model configuration.
        disabled_providers: Optional set of disabled providers.

    Returns:
        A configured StateGraph for the AEIOU-Y pattern.
    """
    # Debug information to ensure we can identify what's happening during streaming
    logger.info("Creating PostChain graph with phases: {}".format(", ".join(phases)))

    # Get configuration if not provided
    if config is None:
        config = Config()

    # Set up the models for each phase
    # This could be randomized, fixed, or specified by the user
    phase_models = {}

    # If a specific model is provided, use it for all phases
    if model_config:
        logger.info(f"Using specified model {model_config} for all phases")
        for phase in phases:
            phase_models[phase] = model_config
    else:
        # Initialize model list with any disabled providers
        models = initialize_tool_compatible_model_list(config, disabled_providers=disabled_providers)

        # Get a list of available models
        logger.info(f"Available models: {[str(model) for model in models]}")

        # For testing: allow a primary model that will be used for all phases if set
        primary_model = os.environ.get("PRIMARY_MODEL")
        if primary_model:
            primary_provider, primary_model_name = primary_model.split("/")
            logger.info(f"Primary model: {primary_model}")
            primary_model_config = ModelConfig(provider=primary_provider, model_name=primary_model_name)
            for phase in phases:
                phase_models[phase] = primary_model_config
        else:
            # Randomly select a different model for each phase
            # In a production system, these would be chosen more deliberately
            for phase in phases:
                selected_model = random.choice(models)
                phase_models[phase] = selected_model
                logger.info(f"{phase.capitalize()} phase using model: {selected_model}")

    # Log all selected models
    logger.info("Selected models for each phase:")
    for phase, model in phase_models.items():
        logger.info(f"  {phase}: {model}")

    # Initialize the state graph
    builder = StateGraph(MessagesState)
    logger.info("Initialized StateGraph with MessagesState")

    # Define nodes for each phase

    # 1. Action Phase Node - Initial response without tools
    async def action_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Action phase of the AEIOU-Y cycle.

        This node:
        1. Takes the user query
        2. Generates a direct response with a model
        3. Attaches phase metadata to the output

        Returns:
            Updated state with Action phase completed
        """
        # Get the model for this phase
        action_model = phase_models["action"]

        # Debug the model config
        debug_model_config(action_model)

        # Try different ways to get the model name
        try:
            model_name = f"{action_model.provider}/{action_model.model_name}"
        except Exception as e:
            logger.error(f"Error creating model name from attributes: {e}")
            try:
                model_name = str(action_model)
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

        # Create system message for this phase
        system_message = create_system_message("action")

        # Prepare messages for the action phase
        messages_for_api = [
            system_message,
            latest_human_message
        ]

        # Get response
        completion = ""
        provider, _ = get_model_provider(action_model)

        try:
            async for chunk in astream_langchain_llm_completion(model_name, messages_for_api, config):
                # Create action phase AIMessage with phase metadata
                if hasattr(chunk, "content") and chunk.content:
                    completion += chunk.content

                    # Create a new message with phase metadata for each chunk
                    ai_message = create_message_with_phase(completion, "action")

                    # Return streaming update
                    state["messages"] = state["messages"][:-1] if ai_message in state["messages"] else state["messages"]
                    state["messages"].append(ai_message)
                    yield {
                        "messages": state["messages"],
                        "current_phase": "action",
                        "current_model": action_model
                    }
        except Exception as e:
            logger.error(f"Error in action_node: {str(e)}", exc_info=True)
            # Create a fallback message on error
            fallback_content = f"I encountered an issue while processing. Let's proceed to the next phase."
            ai_message = create_message_with_phase(fallback_content, "action")
            state["messages"].append(ai_message)

        # Final yield instead of return
        yield state

    # 2. Experience Phase Node - Information retrieval with tools
    # Set up tools for Experience node
    experience_tools = [qdrant_search]

    # Create ToolNode
    experience_tool_node = ToolNode(experience_tools)

    # Experience agent
    async def experience_agent(state: MessagesState) -> Dict[str, Any]:
        messages = state.get("messages", [])

        # Add system message if not present
        if not any(m.content.startswith("You are an experience agent") for m in messages if isinstance(m, SystemMessage)):
            # Add specialized system message for this phase
            experience_system_message = create_system_message("experience")
            messages = [experience_system_message] + messages

        # Get the model for this phase
        experience_model = phase_models["experience"]
        model_name = str(experience_model)  # Convert ModelConfig to string
        logger.info(f"Experience phase using model: {model_name}")

        # Create an initial message with empty content to start streaming
        streamed_message = AIMessage(content="", additional_kwargs={"phase": "experience"})

        # Create the updated messages list with the empty message that will be streamed into
        updated_messages = messages.copy() + [streamed_message]

        # Signal that we're starting to stream
        yield {
            "messages": updated_messages,
            "streaming": True,
            "current_phase": "experience",
            "current_model": model_name
        }

        # Check if the last user message has tool calls
        if _has_tool_calls(state):
            logger.info("Experience phase: Using existing tool calls")
            # Instead of returning state, yield the final state with streaming=False
            yield {
                "messages": state.get("messages", []),
                "streaming": False,
                "current_phase": "experience",
                "current_model": model_name
            }
            # Early return without value to exit the generator
            return

        # Stream tokens from model using tools
        content = ""
        try:
            async for chunk in astream_langchain_llm_completion(model_name, messages, config, tools=experience_tools):
                if isinstance(chunk, AIMessageChunk) and chunk.content:
                    # Accumulate content
                    content += chunk.content
                    # Update the message in-place
                    streamed_message.content = content
                    # Ensure the phase is properly marked
                    streamed_message.additional_kwargs["phase"] = "experience"
                    logger.debug(f"Experience phase streaming token: '{chunk.content}', total content length: {len(content)}")

                    # Yield updated state with partial content
                    yield {
                        "messages": updated_messages,
                        "streaming": True,
                        "current_phase": "experience",
                        "current_model": model_name
                    }
        except Exception as e:
            logger.error(f"Error in experience_agent streaming: {str(e)}")
            # Add error note to content
            error_msg = f"\n[Error occurred during streaming: {str(e)}]"
            content += error_msg
            streamed_message.content = content

        # Ensure the phase is properly marked in the final message
        streamed_message.additional_kwargs["phase"] = "experience"

        # Final state update with streaming completed
        yield {
            "messages": updated_messages,
            "streaming": False,
            "current_phase": "experience",
            "current_model": model_name
        }

        # Add a final yield of the state itself
        yield {
            **state,
            "messages": updated_messages
        }

    # 3. Intention Phase Node - Analysis without tools
    async def intention_node(state: MessagesState) -> Dict[str, Any]:
        messages = state.get("messages", [])

        # Change system message for Intention phase
        system_idx = next((i for i, m in enumerate(messages) if isinstance(m, SystemMessage)), None)
        if system_idx is not None:
            messages = messages.copy()
            messages[system_idx] = create_system_message("intention")
        else:
            messages = [create_system_message("intention")] + messages

        # Get the model for this phase
        intention_model = phase_models["intention"]
        model_name = str(intention_model)  # Convert ModelConfig to string
        logger.info(f"Intention phase using model: {model_name}")

        # Create an initial message with empty content to start streaming
        streamed_message = AIMessage(content="", additional_kwargs={"phase": "intention"})

        # Create the updated messages list with the empty message that will be streamed into
        updated_messages = messages.copy() + [streamed_message]

        # Signal that we're starting to stream
        yield {
            "messages": updated_messages,
            "streaming": True,
            "current_phase": "intention",
            "current_model": model_name
        }

        # Handle Mistral-specific requirements - they don't allow an assistant message as the last message
        provider = intention_model.provider.lower()
        messages_for_api = messages.copy()

        # If it's a Mistral model and the last message is an AIMessage, convert it to a user message
        if "mistral" in provider and len(messages_for_api) > 0 and isinstance(messages_for_api[-1], AIMessage):
            # Convert the last assistant message to a user message with a prefix to indicate it was from the assistant
            last_message = messages_for_api.pop()
            messages_for_api.append(HumanMessage(
                content=f"Previous assistant response: {last_message.content}",
                additional_kwargs={"original_role": "assistant"}
            ))
            logger.info("Converted last assistant message to user message for Mistral compatibility")

        # Stream tokens from model using full model identifier
        content = ""
        async for chunk in astream_langchain_llm_completion(model_name, messages_for_api, config):
            if isinstance(chunk, AIMessageChunk) and chunk.content:
                # Accumulate content
                content += chunk.content
                # Update the message in-place
                streamed_message.content = content
                # Yield updated state with partial content
                yield {
                    "messages": updated_messages,
                    "streaming": True,
                    "current_phase": "intention",
                    "current_model": model_name
                }

        # Final state update with streaming completed
        yield {
            "messages": updated_messages,
            "streaming": False,
            "current_phase": "intention",
            "current_model": model_name
        }

        # Add a final yield of the state itself
        yield {
            **state,
            "messages": updated_messages
        }

    # 4. Observation Phase Node - Reflection with storage tools
    # Set up tools for Observation node
    observation_tools = [qdrant_store]

    # Create ToolNode
    observation_tool_node = ToolNode(observation_tools)

    # Observation agent
    async def observation_agent(state: MessagesState) -> Dict[str, Any]:
        messages = state.get("messages", [])

        # Change system message for Observation phase
        system_idx = next((i for i, m in enumerate(messages) if isinstance(m, SystemMessage)), None)
        if system_idx is not None:
            messages = messages.copy()
            messages[system_idx] = create_system_message("observation")
        else:
            messages = [create_system_message("observation")] + messages

        # Get the model for this phase
        observation_model = phase_models["observation"]
        model_name = str(observation_model)  # Convert ModelConfig to string
        logger.info(f"Observation phase using model: {model_name}")

        # Create an initial message with empty content to start streaming
        streamed_message = AIMessage(content="", additional_kwargs={"phase": "observation"})

        # Create the updated messages list with the empty message that will be streamed into
        updated_messages = messages.copy() + [streamed_message]

        # Signal that we're starting to stream
        yield {
            "messages": updated_messages,
            "streaming": True,
            "current_phase": "observation",
            "current_model": model_name
        }

        # Handle Mistral-specific requirements - they don't allow an assistant message as the last message
        provider = observation_model.provider.lower()
        messages_for_api = messages.copy()

        # If it's a Mistral model and the last message is an AIMessage, convert it to a user message
        if "mistral" in provider and len(messages_for_api) > 0 and isinstance(messages_for_api[-1], AIMessage):
            # Convert the last assistant message to a user message with a prefix to indicate it was from the assistant
            last_message = messages_for_api.pop()
            messages_for_api.append(HumanMessage(
                content=f"Previous assistant response: {last_message.content}",
                additional_kwargs={"original_role": "assistant"}
            ))
            logger.info("Converted last assistant message to user message for Mistral compatibility")

        # Stream tokens from model using full model identifier
        content = ""
        async for chunk in astream_langchain_llm_completion(model_name, messages_for_api, config):
            if isinstance(chunk, AIMessageChunk) and chunk.content:
                # Accumulate content
                content += chunk.content
                # Update the message in-place
                streamed_message.content = content
                # Yield updated state with partial content
                yield {
                    "messages": updated_messages,
                    "streaming": True,
                    "current_phase": "observation",
                    "current_model": model_name
                }

        # Final state update with streaming completed
        yield {
            "messages": updated_messages,
            "streaming": False,
            "current_phase": "observation",
            "current_model": model_name
        }

        # Add a final yield of the state itself
        yield {
            **state,
            "messages": updated_messages
        }

    # 5. Understanding Phase Node - Decision node
    async def understanding_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Understanding phase of the AEIOU-Y cycle.

        This node:
        1. Takes all previous phase outputs
        2. Determines if we should loop back or continue
        3. Provides decision/reasoning

        Returns:
            Updated state with Understanding phase completed and loop_probability set
        """
        # Get the model for this phase
        understanding_model = phase_models["understanding"]
        model_name = str(understanding_model)  # Convert ModelConfig to string
        logger.info(f"Understanding phase using model: {model_name}")

        # Extract provider for model-specific handling
        provider, _ = get_model_provider(model_name)

        # Create system message for this phase
        system_message = create_system_message("understanding")

        messages_for_api = [system_message]
        messages_for_api.extend(state["messages"])

        # Prepare messages based on provider requirements
        messages_for_api = prepare_messages_for_provider(messages_for_api, provider)

        # Process with the model
        completion = ""

        try:
            async for chunk in astream_langchain_llm_completion(model_name, messages_for_api, config):
                if hasattr(chunk, "content") and chunk.content:
                    completion += chunk.content

                    # Create Understanding phase AIMessage with phase metadata
                    ai_message = create_message_with_phase(completion, "understanding")

                    # Return streaming update
                    state["messages"] = state["messages"][:-1] if ai_message in state["messages"] else state["messages"]
                    state["messages"].append(ai_message)
                    yield {
                        "messages": state["messages"],
                        "current_phase": "understanding",
                        "current_model": understanding_model
                    }
        except Exception as e:
            logger.error(f"Error in understanding_node: {str(e)}", exc_info=True)
            # Create a fallback message on error
            fallback_content = "Based on my reasoning, I'll proceed to the next phase."
            ai_message = create_message_with_phase(fallback_content, "understanding")
            state["messages"].append(ai_message)

        # Extract decision from the Understanding phase output
        # Default to continuing (not looping) if there's an error
        should_loop = False
        reasoning = "Default behavior is to proceed to Yield"
        loop_probability = 0.0

        # Set state values for routing
        state["loop_probability"] = loop_probability
        state["should_loop"] = should_loop

        # Final yield instead of return
        yield state

    # 6. Yield Phase Node - Final response
    async def yield_node(state: MessagesState) -> Dict[str, Any]:
        """
        Process the Yield phase of the AEIOU-Y cycle.

        This node:
        1. Takes all previous phase outputs
        2. Generates a final response
        3. Attaches phase metadata to the output

        Returns:
            Updated state with Yield phase completed
        """
        # Get the model for this phase
        yield_model = phase_models["yield"]
        model_name = str(yield_model)  # Convert ModelConfig to string
        logger.info(f"Yield phase using model: {model_name}")

        # Extract provider for model-specific handling
        provider, _ = get_model_provider(model_name)

        # Create system message for this phase
        system_message = create_system_message("yield")

        messages_for_api = [system_message]
        messages_for_api.extend(state["messages"])

        # Prepare messages based on provider requirements
        messages_for_api = prepare_messages_for_provider(messages_for_api, provider)

        # Process with the model
        completion = ""

        try:
            async for chunk in astream_langchain_llm_completion(model_name, messages_for_api, config):
                if hasattr(chunk, "content") and chunk.content:
                    completion += chunk.content

                    # Create yield phase AIMessage with phase metadata
                    ai_message = create_message_with_phase(completion, "yield")

                    # Return streaming update
                    state["messages"] = state["messages"][:-1] if ai_message in state["messages"] else state["messages"]
                    state["messages"].append(ai_message)
                    yield {
                        "messages": state["messages"],
                        "current_phase": "yield",
                        "current_model": yield_model
                    }
        except Exception as e:
            logger.error(f"Error in yield_node: {str(e)}", exc_info=True)
            # Create a fallback message on error
            fallback_content = "Thank you for your query. I've processed your request through the AEIOU-Y cycle."
            ai_message = create_message_with_phase(fallback_content, "yield")
            state["messages"].append(ai_message)

        # Final yield instead of return
        yield state

    # Add nodes to the graph
    builder.add_node("action", action_node)
    builder.add_node("experience_agent", experience_agent)
    builder.add_node("experience_tools", experience_tool_node)
    builder.add_node("intention", intention_node)
    builder.add_node("observation_agent", observation_agent)
    builder.add_node("observation_tools", observation_tool_node)
    builder.add_node("understanding", understanding_node)
    builder.add_node("yield", yield_node)

    # Add simple linear edges first
    builder.add_edge(START, "action")
    builder.add_edge("action", "experience_agent")
    builder.add_edge("experience_tools", "experience_agent")  # Loop back after tools
    builder.add_edge("intention", "observation_agent")
    builder.add_edge("observation_tools", "observation_agent")  # Loop back after tools
    builder.add_edge("yield", END)

    # Add conditional edge from experience_agent to tools if needed
    builder.add_conditional_edges(
        "experience_agent",
        lambda state: "experience_tools" if _has_tool_calls(state) else "intention"
    )

    # Add conditional edge from observation_agent to tools if needed
    builder.add_conditional_edges(
        "observation_agent",
        lambda state: "observation_tools" if _has_tool_calls(state) else "understanding"
    )

    # Add router for understanding node that checks the __next field
    def understanding_router(state: MessagesState) -> str:
        # Check if the state has a __next field
        next_node = state.get("__next")

        # If streaming is still in progress, continue with the current node
        if state.get("streaming", False):
            return "understanding"

        # If we have a specific next node, use it
        if next_node:
            return next_node

        # Default to yield if no specific direction
        return "yield"

    # Add conditional edges for the understanding node using the router
    builder.add_conditional_edges(
        "understanding",
        understanding_router,
        ["action", "yield"]  # Possible targets
    )

    # Compile and return the graph
    return builder.compile()

def _has_tool_calls(state: MessagesState) -> bool:
    """Check if the last AI message contains tool calls."""
    messages = state.get("messages", [])
    last_ai_message = extract_last_message(messages, AIMessage)

    if last_ai_message and hasattr(last_ai_message, "tool_calls") and last_ai_message.tool_calls:
        return True

    if last_ai_message and hasattr(last_ai_message, "additional_kwargs"):
        tool_calls = last_ai_message.additional_kwargs.get("tool_calls", [])
        return len(tool_calls) > 0

    return False

def extract_phase_outputs(messages: List[BaseMessage]) -> Dict[str, str]:
    """
    Extract content for each phase from a list of messages.

    This function looks for phase metadata in AIMessages and builds a dictionary
    mapping each phase to its content.

    Args:
        messages: List of messages to extract phase outputs from

    Returns:
        Dictionary mapping phase names to their content
    """
    outputs = {}

    for msg in messages:
        if not isinstance(msg, AIMessage):
            continue

        # Try to get phase from additional_kwargs
        phase = get_phase_metadata(msg)

        if phase and phase in phases:
            # If we find a phase, add or overwrite the content for that phase
            outputs[phase] = msg.content

    return outputs

async def invoke_postchain(
    user_query: str,
    config: Config,
    thread_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Invoke the PostChain graph with a user query.

    Args:
        user_query: The user's input query
        config: Configuration object
        thread_id: Optional thread ID for persistence

    Returns:
        Dictionary with the final state
    """
    # Create graph
    graph = create_postchain_graph(config=config)

    # Create initial messages with user query
    initial_messages = [HumanMessage(content=user_query)]

    # Initial state
    initial_state = {
        "messages": initial_messages,
        "loop_count": 0,
        "loop_probability": 0.0,
        "thread_id": thread_id or str(uuid.uuid4())
    }

    # Configure thread for persistence
    thread_config = {"configurable": {"thread_id": initial_state["thread_id"]}}

    # Execute graph
    final_state = await graph.ainvoke(initial_state, config=thread_config)

    # Extract phase outputs
    phase_outputs = extract_phase_outputs(final_state["messages"])

    # Return combined state with phase outputs
    return {
        **final_state,
        "phase_outputs": phase_outputs,
        "user_query": user_query
    }

async def stream_postchain(
    user_query: str,
    config: Config,
    thread_id: Optional[str] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Stream the PostChain graph execution with token-level streaming.

    Args:
        user_query: The user's input query
        config: Configuration object
        thread_id: Optional thread ID for persistence

    Yields:
        Stream of state updates during execution, including token-level streaming
    """
    # Create graph
    graph = create_postchain_graph(config=config)

    # Create initial messages with user query
    initial_messages = [HumanMessage(content=user_query)]

    # Initial state
    initial_state = {
        "messages": initial_messages,
        "loop_count": 0,
        "loop_probability": 0.0,
        "thread_id": thread_id or str(uuid.uuid4())
    }

    # Configure thread for persistence
    thread_config = {"configurable": {"thread_id": initial_state["thread_id"]}}

    logger.info(f"Starting PostChain stream with query: {user_query[:50]}...")

    # Track full state
    current_phase = "action"  # Always start with action
    last_known_phases = {}

    # Track outputs per phase - initialize with empty values for all known phases
    phase_outputs = {phase: "" for phase in phases}

    # Log the initial setup
    logger.info(f"Initialized phases: {list(phases)}")

    # Use stream_mode parameter explicitly
    stream_mode = "values"  # Changed from "messages" to "values"
    logger.info(f"Using stream_mode: {stream_mode}")

    try:
        # Send initial update to the client
        yield {
            "current_phase": current_phase,
            "phase_outputs": phase_outputs,
            "user_query": user_query,
            "thread_id": initial_state["thread_id"],
        }

        # Stream execution with values mode
        logger.info("Starting graph.astream execution")
        event_count = 0
        async for chunk in graph.astream(initial_state, config=thread_config, stream_mode=stream_mode):
            event_count += 1

            # For better debugging, log chunk type and content preview
            if isinstance(chunk, dict):
                keys = list(chunk.keys())
                logger.debug(f"[{event_count}] Chunk keys: {keys}")

                # Extract current phase if available
                if "current_phase" in chunk:
                    current_phase = chunk["current_phase"]
                    logger.info(f"[{event_count}] Phase: {current_phase}")

                # Extract messages if available
                if "messages" in chunk:
                    # Extract phase content from messages
                    new_phase_outputs = extract_phase_outputs(chunk["messages"])

                    # Update our phase outputs
                    for phase, content in new_phase_outputs.items():
                        # Only update if the content is different
                        if phase not in phase_outputs or content != phase_outputs[phase]:
                            phase_outputs[phase] = content
                            logger.info(f"[{event_count}] Updated {phase} content: {content[:30]}...")

                # Create update for client
                update = {
                    "current_phase": current_phase,
                    "phase_outputs": phase_outputs,
                    "user_query": user_query,
                    "thread_id": initial_state["thread_id"],
                }

                yield update

        logger.info(f"Completed streaming after {event_count} events")

        # Send a final completion event
        yield {
            "phase": "complete",
            "current_phase": "complete",
            "phase_outputs": phase_outputs,
            "thread_id": initial_state["thread_id"]
        }

    except Exception as e:
        logger.error(f"Error in stream_postchain: {str(e)}", exc_info=True)

        # Send an error event
        yield {
            "phase": "error",
            "error": str(e),
            "thread_id": initial_state["thread_id"],
            "phase_outputs": phase_outputs  # Include any partial outputs
        }
        raise

def prepare_messages_for_provider(messages: List[BaseMessage], provider: str) -> List[BaseMessage]:
    """
    Prepares messages for a specific provider, handling format requirements.

    Args:
        messages: List of messages to prepare
        provider: The target provider (openai, anthropic, mistral, etc.)

    Returns:
        Properly formatted messages for the specified provider
    """
    if provider == "mistral":
        # Mistral requires the last message to be a user or tool message
        # Convert the last AI message to a user message if needed
        result = []
        for i, message in enumerate(messages):
            if i == len(messages) - 1 and isinstance(message, AIMessage):
                # Convert the last AI message to a user message
                result.append(HumanMessage(content=f"Previous assistant response: {message.content}"))
                logger.info("Converted last assistant message to user message for Mistral compatibility")
            else:
                result.append(message)
        return result

    return messages.copy()
