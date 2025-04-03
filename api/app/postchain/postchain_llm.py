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
from app.config import Config

logger = logging.getLogger("postchain_llm")

async def initialize_model(model_config: ModelConfig) -> BaseChatModel:
    """Initialize the appropriate LangChain model based on configuration."""
    try:
        return get_base_model(model_config)
    except Exception as e:
        logger.error(f"Failed to initialize model: {e}", exc_info=True)
        raise ValueError(f"Model initialization failed: {e}") from e

async def handle_tools(model: BaseChatModel, tools: Optional[List[Any]]) -> BaseChatModel:
    """Configure model with tools if provided."""
    if not tools:
        return model

    try:
        pydantic_tools = convert_tools_to_pydantic(tools)
        return model.bind_tools(pydantic_tools)
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
        raise ValueError(f"Streaming failed: {e}") from e

async def process_non_streaming_response(model: BaseChatModel, messages: List[BaseMessage]) -> AIMessage:
    """Handle non-streaming response from the model."""
    try:
        return await model.ainvoke(messages)
    except Exception as e:
        logger.error(f"Error during non-streaming response: {e}", exc_info=True)
        raise ValueError(f"Non-streaming invocation failed: {e}") from e

async def post_llm(
    messages: List[BaseMessage],
    model_config: ModelConfig,
    response_model: Optional[Type[BaseModel]] = None,
    stream: bool = False,
    tools: Optional[List[Any]] = None
) -> Union[AIMessage, AsyncIterator[AIMessageChunk]]:
    """
    Refactored version of post_llm with cleaner separation of concerns.

    Args:
        messages: Conversation messages in LangChain format
        model_config: Configuration for the model including provider and API keys
        response_model: Optional Pydantic model for structured output
        stream: Whether to stream the response
        tools: Optional list of tools to bind to the model

    Returns:
        Either a single AIMessage or an async iterator of AIMessageChunks
    """
    # Initialize model
    model = await initialize_model(model_config)

    # Handle tools if provided
    if tools:
        model = await handle_tools(model, tools)

    # Handle response based on streaming preference
    if stream:
        return process_streaming_response(model, messages)
    return await process_non_streaming_response(model, messages)
