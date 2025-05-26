"""
Refactored implementation of the post_llm functionality extracted from langchain_utils.py.
This module provides a cleaner, more maintainable interface for LLM interactions in PostChain.
"""

import logging
from typing import Any, Type, List, Optional, Union, AsyncIterator
from pydantic import BaseModel

from langchain_core.messages import BaseMessage, AIMessage, AIMessageChunk
from langchain_core.language_models import BaseChatModel

from app.langchain_utils import ModelConfig, get_base_model, convert_tools_to_pydantic
from app.config import Config # Import global config

logger = logging.getLogger("postchain_llm")

# Load global config once at module level to access default API keys
global_config = Config()

async def initialize_model(model_config: ModelConfig) -> BaseChatModel:
    """
    Initialize the appropriate LangChain model based on configuration.
    If an API key is missing in model_config, it attempts to use the
    corresponding key from the global_config (loaded from .env).
    """
    try:
        # Create a copy to potentially modify with default keys
        effective_model_config = model_config.copy(deep=True) # Use deep copy

        # --- Key Fallback Logic ---
        provider = effective_model_config.provider

        # Map provider names to ModelConfig attribute names and global Config values
        key_attr_map = {
            "openai": ("openai_api_key", global_config.OPENAI_API_KEY),
            "google": ("google_api_key", global_config.GOOGLE_API_KEY),
            "anthropic": ("anthropic_api_key", global_config.ANTHROPIC_API_KEY),
            "mistralai": ("mistral_api_key", global_config.MISTRAL_API_KEY),
            "groq": ("groq_api_key", global_config.GROQ_API_KEY),
            "cohere": ("cohere_api_key", global_config.COHERE_API_KEY),
            "openrouter": ("openrouter_api_key", global_config.OPENROUTER_API_KEY),
            # Add mappings for other providers here if they follow the pattern
            # "provider_name": ("model_config_key_attr", global_config.DEFAULT_KEY_ATTR),
        }

        if provider in key_attr_map:
            key_attr_name, default_key_value = key_attr_map[provider]

            # Check if the key attribute exists and is None in the effective_model_config
            current_key_value = getattr(effective_model_config, key_attr_name, None)

            if current_key_value is None:
                # If default key exists in global config, use it
                if default_key_value:
                    logger.info(f"API key for provider '{provider}' not found in request ModelConfig, using default from environment.")
                    setattr(effective_model_config, key_attr_name, default_key_value)
                else:
                    # Key missing in request AND default config.
                    # Langchain's get_base_model will likely raise an error if the key is required.
                    logger.warning(f"API key for provider '{provider}' missing in request ModelConfig and no default found in environment.")
        else:
            logger.debug(f"Provider '{provider}' not in key fallback map or key not managed here.")

        # --- Initialize with effective config ---
        # Pass the potentially updated config to the Langchain model initializer
        return get_base_model(effective_model_config)

    except Exception as e:
        # Log the original model_config for easier debugging without exposing keys from effective_model_config
        logger.error(f"Failed to initialize model '{model_config.provider}/{model_config.model_name}': {e}", exc_info=True)
        # Avoid leaking keys in the exception message back to the client if possible
        raise ValueError(f"Model initialization failed for {model_config.provider}/{model_config.model_name}") from e


async def handle_tools(model: BaseChatModel, tools: Optional[List[Any]]) -> BaseChatModel:
    """Configure model with tools if provided."""
    if not tools:
        logger.info("No tools provided to handle_tools")
        return model

    try:
        logger.info(f"Processing tools for model binding: {tools}")

        # For Groq models, we need to create a special tool definition
        if hasattr(model, "model_name") and "groq" in str(model).lower():
            logger.info("Creating special tool definition for Groq model")

            # Create a list of tool definitions without the coroutine
            groq_tools = []
            for tool in tools:
                if isinstance(tool, dict) and "function" in tool:
                    # Create a clean version without the coroutine
                    clean_tool = {
                        "type": "function",
                        "function": tool["function"]
                    }
                    groq_tools.append(clean_tool)

            logger.info(f"Created clean tool definitions for Groq: {groq_tools}")

            # Bind the tools to the model
            bound_model = model.bind(tools=groq_tools)
            logger.info(f"Successfully bound tools to Groq model: {bound_model}")
            return bound_model

        # For other models, use the standard approach
        logger.info(f"Converting tools to pydantic: {tools}")
        pydantic_tools = convert_tools_to_pydantic(tools)
        logger.info(f"Binding tools to model: {pydantic_tools}")
        bound_model = model.bind_tools(pydantic_tools)
        logger.info(f"Successfully bound tools to model: {bound_model}")
        return bound_model
    except Exception as e:
        logger.error(f"Failed to bind tools to model: {e}", exc_info=True)
        raise ValueError(f"Tool binding failed: {e}") from e

async def process_streaming_response(model: BaseChatModel, messages: List[BaseMessage]) -> AsyncIterator[AIMessageChunk]:
    """Handle streaming response from the model."""
    try:
        async for chunk in model.astream(messages):
            yield chunk
    except Exception as e:
        logger.error(f"Error during streaming response: {e}", exc_info=True)
        # Yield an error chunk or re-raise depending on desired client handling
        yield AIMessageChunk(content=f"Error during streaming: {e}") # Example error chunk
        # Or simply raise: raise ValueError(f"Streaming failed: {e}") from e

async def process_non_streaming_response(
    model: BaseChatModel,
    messages: List[BaseMessage],
    response_model: Optional[Type[BaseModel]] = None,
    tools: Optional[List[Any]] = None
) -> Union[AIMessage, BaseModel]:
    """Handle non-streaming response from the model, optionally with structured output."""
    try:
        if response_model:
            # Use structured output if response_model is provided
            logger.info(f"Using structured output with model {response_model.__name__}")

            # Special handling for YieldPhaseResponse
            if response_model.__name__ == "YieldPhaseResponse":
                # First get the raw response
                raw_response = await model.ainvoke(messages)

                # Check if the response contains tool calls
                if hasattr(raw_response, 'additional_kwargs') and 'tool_calls' in raw_response.additional_kwargs:
                    logger.info(f"Response contains tool calls: {raw_response.additional_kwargs['tool_calls']}")

                    # Import json here to avoid UnboundLocalError
                    import json

                    # Process each tool call
                    for tool_call in raw_response.additional_kwargs['tool_calls']:
                        if 'function' in tool_call:
                            function_name = tool_call['function']['name']
                            function_args = json.loads(tool_call['function']['arguments'])

                            logger.info(f"Processing tool call: {function_name} with args: {function_args}")

                            # Find the matching tool
                            for tool in tools or []:
                                if isinstance(tool, dict) and 'function' in tool and tool['function']['name'] == function_name:
                                    if 'coroutine' in tool:
                                        # Call the coroutine with the arguments
                                        logger.info(f"Calling tool coroutine: {tool['coroutine']}")

                                        try:
                                            # Call the coroutine directly with the function arguments
                                            logger.info(f"About to call tool coroutine with input: {function_args}")
                                            result = await tool['coroutine'](**function_args)
                                            logger.info(f"Tool call result: {result}")

                                            # We'll use this result later when creating the response model
                                            if hasattr(result, 'dict'):
                                                raw_response.citation_reward_info = result.dict()
                                            else:
                                                raw_response.citation_reward_info = result
                                        except Exception as tool_error:
                                            logger.error(f"Error calling tool: {tool_error}", exc_info=True)
                                            raw_response.citation_reward_info = {
                                                "success": False,
                                                "error": str(tool_error)
                                            }

                                        break

                # Try to extract structured data from the raw response
                try:
                    import json
                    import re

                    # Extract JSON-like content from the response
                    content = raw_response.content

                    # Look for JSON blocks in the content
                    json_match = re.search(r'```json\s*(.*?)\s*```', content, re.DOTALL)
                    if json_match:
                        json_str = json_match.group(1)
                    else:
                        # Try to find any JSON-like structure
                        json_match = re.search(r'({.*})', content, re.DOTALL)
                        if json_match:
                            json_str = json_match.group(1)
                        else:
                            # No JSON found, use the standard approach
                            structured_model = model.with_structured_output(response_model)
                            return await structured_model.ainvoke(messages)

                    # Parse the JSON
                    data = json.loads(json_str)

                    # Create the response model
                    if "response_content" in data:
                        # Handle citation_explanations if it's a string
                        if "citation_explanations" in data and isinstance(data["citation_explanations"], str):
                            try:
                                data["citation_explanations"] = json.loads(data["citation_explanations"])
                            except json.JSONDecodeError:
                                data["citation_explanations"] = {}

                        # Handle citation_reward_info if it's a string
                        if "citation_reward_info" in data and isinstance(data["citation_reward_info"], str):
                            try:
                                data["citation_reward_info"] = json.loads(data["citation_reward_info"])
                            except json.JSONDecodeError:
                                data["citation_reward_info"] = None

                        # Check if we have citation_reward_info from a tool call
                        if hasattr(raw_response, 'citation_reward_info'):
                            data['citation_reward_info'] = raw_response.citation_reward_info
                            logger.info(f"Using citation_reward_info from tool call: {data['citation_reward_info']}")

                        # Create the response model
                        return response_model(**data)
                except Exception as parsing_error:
                    logger.warning(f"Failed to parse raw response as structured output: {parsing_error}")
                    # Fall back to standard approach

            # Standard approach for structured output
            structured_model = model.with_structured_output(response_model)
            return await structured_model.ainvoke(messages)
        else:
            # Regular invocation without structured output
            return await model.ainvoke(messages)
    except Exception as e:
        logger.error(f"Error during non-streaming response: {e}", exc_info=True)
        # Return an error message or re-raise
        return AIMessage(content=f"Error during invocation: {e}") # Example error message
        # Or simply raise: raise ValueError(f"Non-streaming invocation failed: {e}") from e

async def post_llm(
    messages: List[BaseMessage],
    model_config: ModelConfig,
    response_model: Optional[Type[BaseModel]] = None,
    stream: bool = False,
    tools: Optional[List[Any]] = None
) -> Union[AIMessage, BaseModel, AsyncIterator[AIMessageChunk]]:
    """Refactored version of post_llm with cleaner separation of concerns
    and API key fallback logic moved to initialize_model.

    Args:
        messages: Conversation messages in LangChain format
        model_config: Configuration for the model including provider (API keys are optional, will fallback to env)
        response_model: Optional Pydantic model for structured output
        stream: Whether to stream the response
        tools: Optional list of tools to bind to the model

    Returns:
        Either a single AIMessage, a Pydantic model instance, or an async iterator of AIMessageChunks
    """
    try:
        # Initialize model (handles API key fallback)
        model = await initialize_model(model_config)

        # Handle tools if provided
        if tools:
            logger.info(f"Tools provided to post_llm: {tools}")
            model = await handle_tools(model, tools)
        else:
            logger.info("No tools provided to post_llm")

        # Handle response based on streaming preference
        if stream:
            # Structured output is not supported with streaming
            if response_model:
                logger.warning("Structured output is not supported with streaming. Ignoring response_model.")
            return process_streaming_response(model, messages)
        else:
            # Pass response_model and tools to process_non_streaming_response
            return await process_non_streaming_response(model, messages, response_model, tools)

    except ValueError as e:
         # Catch initialization or tool binding errors specifically
         logger.error(f"Error in post_llm setup: {e}", exc_info=True)
         error_content = f"Error setting up LLM request: {e}"
         if stream:
             async def error_stream():
                 yield AIMessageChunk(content=error_content)
             return error_stream()
         else:
             return AIMessage(content=error_content)
    except Exception as e:
        # Catch unexpected errors during processing
        logger.error(f"Unexpected error in post_llm: {e}", exc_info=True)
        error_content = f"Unexpected error processing LLM request: {e}"
        if stream:
             async def error_stream():
                 yield AIMessageChunk(content=error_content)
             return error_stream()
        else:
             return AIMessage(content=error_content)
