"""
Abstraction layer for interacting with various LLM providers through LangChain.
This module provides a unified interface for basic chat completions and structured output generations
across multiple model providers.
"""

import logging
import random
import copy
from typing import Dict, Any, List, Optional, Tuple, AsyncGenerator, AsyncIterator, Type, Union
from pydantic import BaseModel, Field, create_model
from dataclasses import dataclass
import re

from langchain_core.language_models import BaseChatModel
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, AIMessageChunk, BaseMessage, ToolMessage

# LangChain model imports
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from langchain_cohere import ChatCohere
from langchain_groq import ChatGroq

from .config import Config

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class ModelConfig:
    """Configuration for a model"""
    provider: str
    model_name: str

    def __str__(self) -> str:
        """Return the full model identifier"""
        return f"{self.provider}/{self.model_name}"

# Functions to get available models from each provider
def get_openai_models(config: Config) -> List[str]:
    """Get available OpenAI models"""
    return [
        # config.OPENAI_GPT_45_PREVIEW,
        config.OPENAI_GPT_4O,
        config.OPENAI_GPT_4O_MINI,
        # config.OPENAI_O1,
        config.OPENAI_O3_MINI
    ]

def get_anthropic_models(config: Config) -> List[str]:
    """Get available Anthropic models"""
    return [
        config.ANTHROPIC_CLAUDE_37_SONNET,
        config.ANTHROPIC_CLAUDE_35_HAIKU
    ]

def get_google_models(config: Config) -> List[str]:
    """Get available Google models"""
    return [
        config.GOOGLE_GEMINI_20_FLASH,
        config.GOOGLE_GEMINI_20_FLASH_LITE,
        config.GOOGLE_GEMINI_20_PRO_EXP,
        config.GOOGLE_GEMINI_20_FLASH_THINKING
    ]

def get_mistral_models(config: Config) -> List[str]:
    """Get available Mistral models"""
    return [
        config.MISTRAL_PIXTRAL_12B,
        config.MISTRAL_SMALL_LATEST,
        config.MISTRAL_PIXTRAL_LARGE,
        config.MISTRAL_LARGE_LATEST,
        config.MISTRAL_CODESTRAL
    ]

def get_fireworks_models(config: Config) -> List[str]:
    """Get available Fireworks models"""
    return [
        config.FIREWORKS_DEEPSEEK_R1,
        config.FIREWORKS_DEEPSEEK_V3,
        config.FIREWORKS_QWEN25_CODER,
        config.FIREWORKS_QWEN_QWQ_32B
    ]

def get_cohere_models(config: Config) -> List[str]:
    """Get available Cohere models"""
    return [
        config.COHERE_COMMAND_R7B
    ]

def get_groq_models(config: Config) -> List[str]:
    """Get available Groq models"""
    return [
        config.GROQ_LLAMA3_3_70B_VERSATILE,
        config.GROQ_QWEN_QWQ_32B,
        config.GROQ_DEEPSEEK_R1_DISTILL_QWEN_32B,
        config.GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B_SPECDEC,
        config.GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B
    ]

def get_tool_compatible_models(config: Config) -> Dict[str, List[str]]:
    """
    Get a dictionary of models known to work with tool use, organized by provider.

    Based on comprehensive testing results from plan_tools_checklist.md.

    Args:
        config: Application configuration with model names

    Returns:
        Dictionary with provider keys and lists of compatible model names
    """
    return {
        "openai": [
            # config.OPENAI_O1,
            config.OPENAI_O3_MINI,
            config.OPENAI_GPT_4O_MINI,
        ],
        "anthropic": [
            config.ANTHROPIC_CLAUDE_37_SONNET,
            config.ANTHROPIC_CLAUDE_35_HAIKU,
        ],
        "google": [
            config.GOOGLE_GEMINI_20_FLASH,
        ],
        "mistral": [
            config.MISTRAL_SMALL_LATEST,
            config.MISTRAL_LARGE_LATEST,
            config.MISTRAL_PIXTRAL_12B,
            config.MISTRAL_PIXTRAL_LARGE,
            config.MISTRAL_CODESTRAL,
        ],
        "groq": [
            config.GROQ_QWEN_QWQ_32B,
            config.GROQ_DEEPSEEK_R1_DISTILL_LLAMA_70B,
        ]
    }

def initialize_tool_compatible_model_list(config: Config, disabled_providers: set = None) -> List[ModelConfig]:
    """
    Initialize the list of models verified to work with tool calls.

    Args:
        config: Application configuration with API keys
        disabled_providers: Set of provider names to exclude (e.g., {"openai", "anthropic"})

    Returns:
        List of models verified to support tool use
    """
    models = []
    disabled_providers = disabled_providers or set()
    tool_models = get_tool_compatible_models(config)

    # Add models from each provider if API key is available and provider not disabled
    if config.OPENAI_API_KEY and "openai" not in disabled_providers:
        models.extend([ModelConfig("openai", m) for m in tool_models.get("openai", [])])

    if config.ANTHROPIC_API_KEY and "anthropic" not in disabled_providers:
        models.extend([ModelConfig("anthropic", m) for m in tool_models.get("anthropic", [])])

    if config.GOOGLE_API_KEY and "google" not in disabled_providers:
        models.extend([ModelConfig("google", m) for m in tool_models.get("google", [])])

    if config.MISTRAL_API_KEY and "mistral" not in disabled_providers:
        models.extend([ModelConfig("mistral", m) for m in tool_models.get("mistral", [])])

    if config.GROQ_API_KEY and "groq" not in disabled_providers:
        models.extend([ModelConfig("groq", m) for m in tool_models.get("groq", [])])

    return models

def initialize_model_list(config: Config, disabled_providers: set = None) -> List[ModelConfig]:
    """Initialize the list of available models from all providers.

    Args:
        config: Application configuration with API keys
        disabled_providers: Set of provider names to exclude (e.g., {"openai", "anthropic"})

    Returns:
        List of available models
    """
    models = []
    disabled_providers = disabled_providers or set()

    # Add models from each provider if API key is available and provider not disabled
    if config.OPENAI_API_KEY and "openai" not in disabled_providers:
        models.extend([ModelConfig("openai", m) for m in get_openai_models(config)])

    if config.ANTHROPIC_API_KEY and "anthropic" not in disabled_providers:
        models.extend([ModelConfig("anthropic", m) for m in get_anthropic_models(config)])

    if config.GOOGLE_API_KEY and "google" not in disabled_providers:
        models.extend([ModelConfig("google", m) for m in get_google_models(config)])

    if config.MISTRAL_API_KEY and "mistral" not in disabled_providers:
        models.extend([ModelConfig("mistral", m) for m in get_mistral_models(config)])

    if config.FIREWORKS_API_KEY and "fireworks" not in disabled_providers:
        models.extend([ModelConfig("fireworks", m) for m in get_fireworks_models(config)])

    if config.COHERE_API_KEY and "cohere" not in disabled_providers:
        models.extend([ModelConfig("cohere", m) for m in get_cohere_models(config)])

    if config.GROQ_API_KEY and "groq" not in disabled_providers:
        models.extend([ModelConfig("groq", m) for m in get_groq_models(config)])

    logger.info(f"Initialized {len(models)} models for model selection")
    return models

def get_user_message(messages: List[BaseMessage]) -> str:
    """Extract the latest user message from a list of messages."""
    for message in reversed(messages):
        if isinstance(message, HumanMessage):
            return message.content
    return ""

def get_model_provider(model_name: str) -> Tuple[str, str]:
    """
    Determine the provider and clean model name from a model string.

    Args:
        model_name: The model identifier string, potentially with a provider prefix

    Returns:
        Tuple of (provider, clean_model_name)

    Examples:
        >>> get_model_provider("anthropic/claude-3-5-haiku-latest")
        ("anthropic", "claude-3-5-haiku-latest")

        >>> get_model_provider("gpt-4o")
        ("openai", "gpt-4o")
    """
    if "/" in model_name:
        provider, clean_model_name = model_name.split("/", 1)
        return provider, clean_model_name

    # Default to OpenAI if no prefix is provided
    return "openai", model_name

def get_base_model(model_name: str, config: Config) -> BaseChatModel:
    """
    Initialize the appropriate LangChain model based on model name.

    Args:
        model_name: The model identifier string
        config: Application configuration object

    Returns:
        Initialized LangChain model

    Raises:
        ValueError: If the provider is not supported
    """
    provider, clean_name = get_model_provider(model_name)

    if provider == "openai":
        if clean_name in [config.OPENAI_O1, config.OPENAI_O3_MINI]:
            return ChatOpenAI(api_key=config.OPENAI_API_KEY, model=clean_name)
        return ChatOpenAI(
            api_key=config.OPENAI_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    elif provider == "anthropic":
        return ChatAnthropic(
            api_key=config.ANTHROPIC_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            max_tokens=config.MAX_TOKENS
        )
    elif provider == "google":
        return ChatGoogleGenerativeAI(
            api_key=config.GOOGLE_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    elif provider == "mistral":
        return ChatMistralAI(
            api_key=config.MISTRAL_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    elif provider == "fireworks":
        model_id = f"accounts/fireworks/models/{clean_name}"
        return ChatFireworks(
            api_key=config.FIREWORKS_API_KEY,
            model=model_id,
            temperature=config.TEMPERATURE
        )
    elif provider == "cohere":
        return ChatCohere(
            api_key=config.COHERE_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    elif provider == "azure":
        return ChatOpenAI(
            api_key=config.AZURE_API_KEY,
            api_base=config.AZURE_API_BASE,
            api_version=config.AZURE_API_VERSION,
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    elif provider == "openrouter":
        return ChatOpenAI(
            api_key=config.OPENROUTER_API_KEY,
            base_url="https://openrouter.ai/api/v1",
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    elif provider == "groq":
        return ChatGroq(
            api_key=config.GROQ_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE
        )
    raise ValueError(f"Unsupported provider: {provider}")

def get_streaming_model(model_name: str, config: Config) -> BaseChatModel:
    """
    Initialize a streaming-enabled LangChain model based on model name.

    Args:
        model_name: The model identifier string
        config: Application configuration object

    Returns:
        Initialized LangChain model with streaming enabled

    Raises:
        ValueError: If the provider is not supported
    """
    provider, clean_name = get_model_provider(model_name)

    if provider == "openai":
        if clean_name in [config.OPENAI_O3_MINI]:
            return ChatOpenAI(
                api_key=config.OPENAI_API_KEY,
                model=clean_name,
                streaming=True
            )
        return ChatOpenAI(
            api_key=config.OPENAI_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "anthropic":
        return ChatAnthropic(
            api_key=config.ANTHROPIC_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            max_tokens=config.MAX_TOKENS,
            streaming=True
        )
    elif provider == "google":
        return ChatGoogleGenerativeAI(
            api_key=config.GOOGLE_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "mistral":
        return ChatMistralAI(
            api_key=config.MISTRAL_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "fireworks":
        model_id = f"accounts/fireworks/models/{clean_name}"
        return ChatFireworks(
            api_key=config.FIREWORKS_API_KEY,
            model=model_id,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "cohere":
        return ChatCohere(
            api_key=config.COHERE_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "azure":
        return ChatOpenAI(
            api_key=config.AZURE_API_KEY,
            api_base=config.AZURE_API_BASE,
            api_version=config.AZURE_API_VERSION,
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "openrouter":
        return ChatOpenAI(
            api_key=config.OPENROUTER_API_KEY,
            base_url="https://openrouter.ai/api/v1",
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    elif provider == "groq":
        return ChatGroq(
            api_key=config.GROQ_API_KEY,
            model=clean_name,
            temperature=config.TEMPERATURE,
            streaming=True
        )
    raise ValueError(f"Unsupported provider: {provider}")

def convert_to_langchain_messages(messages: List[Dict[str, str]], provider: Optional[str] = None) -> List[Any]:
    """
    Convert dictionary-based messages to LangChain message objects,
    handling provider-specific formatting requirements.

    Args:
        messages: List of message dictionaries with 'role' and 'content' keys
        provider: Optional provider name to handle provider-specific formatting

    Returns:
        List of LangChain message objects
    """
    provider_lower = provider.lower() if provider else ""
    is_anthropic = "anthropic" in provider_lower
    is_google = "google" in provider_lower
    is_mistral = "mistral" in provider_lower

    # Provider-specific pre-processing
    processed_messages = []
    for msg in messages:
        # Skip empty content messages for Anthropic
        if is_anthropic and msg.get("role") == "assistant" and (not msg.get("content") or len(msg.get("content", "").strip()) == 0):
            continue

        # For Google Gemini, ensure content is never empty
        if is_google and (not msg.get("content") or len(msg.get("content", "").strip()) == 0):
            msg = msg.copy()  # Create a copy to avoid modifying the original
            msg["content"] = " "  # Use a space instead of empty string

        # For Mistral, handle message sequence constraints
        if is_mistral:
            # Mistral requires that the last message is either from user or a tool response
            # If it's an assistant message with no content, skip it
            if msg.get("role") == "assistant" and (not msg.get("content") or len(msg.get("content", "").strip()) == 0):
                continue

        processed_messages.append(msg)

    # If Mistral and the last message is an assistant message, convert to user format
    if is_mistral and processed_messages and processed_messages[-1].get("role") == "assistant":
        last_msg = processed_messages[-1]
        processed_messages[-1] = {
            "role": "user",
            "content": f"Previous assistant response: {last_msg.get('content', '')}"
        }

    # Now convert to LangChain message objects
    lc_messages = []
    for msg in processed_messages:
        role = msg.get("role", "")
        content = msg.get("content", "")

        # Make sure content is not empty
        if not content:
            content = " "  # Space instead of empty string

        if role == "system":
            lc_messages.append(SystemMessage(content=content))
        elif role == "user":
            lc_messages.append(HumanMessage(content=content))
        elif role == "assistant":
            # Handle special case for Mistral
            if is_mistral and "tool_calls" in msg:
                # Format tool calls in a way Mistral can understand
                formatted_content = content if content else "I'll help you with that."
                lc_messages.append(AIMessage(content=formatted_content))
            else:
                lc_messages.append(AIMessage(content=content))
        elif role == "tool":
            # For Anthropic models, don't use ToolMessage as they have their own format
            if is_anthropic:
                # Convert tool messages to user messages for Anthropic
                tool_name = msg.get("name", "tool")
                lc_messages.append(HumanMessage(content=f"Tool '{tool_name}' results: {content}"))
            elif is_mistral:
                # Mistral prefers tool messages in a specific format
                tool_name = msg.get("name", "tool")
                tool_call_id = msg.get("tool_call_id", "unknown_id")
                lc_messages.append(ToolMessage(
                    content=content,
                    tool_call_id=tool_call_id,
                    name=tool_name
                ))
            else:
                # Handle tool messages - extract information from the message
                tool_name = msg.get("name", "unknown_tool")
                tool_call_id = msg.get("tool_call_id", "unknown_id")
                lc_messages.append(ToolMessage(
                    content=content,
                    tool_call_id=tool_call_id,
                    name=tool_name
                ))

    # If Google Gemini and there are no messages or the only message is a system message,
    # add a simple user message to satisfy Gemini's requirements
    if is_google and (len(lc_messages) == 0 or (len(lc_messages) == 1 and isinstance(lc_messages[0], SystemMessage))):
        lc_messages.append(HumanMessage(content="Hello"))

    return lc_messages

def convert_tools_to_pydantic(tools: List[Any]) -> List[Type[BaseModel]]:
    """
    Convert BaseTool instances to Pydantic models for use with bind_tools.

    Args:
        tools: List of BaseTool instances

    Returns:
        List of Pydantic model classes that can be used with bind_tools
    """
    pydantic_tools = []

    for tool in tools:
        # For WebSearchTool and similar tools, we want to use a different schema
        if hasattr(tool, "name") and "search" in tool.name.lower():
            # Create a special model for search tools that accepts a query parameter
            tool_model = create_model(
                tool.name,  # Use the tool name as the class name
                __doc__=tool.description if hasattr(tool, "description") else f"Search using {tool.name}",
                query=(str, Field(..., description="The search query to look up"))
            )
        else:
            # Default model for other tools
            tool_model = create_model(
                tool.name if hasattr(tool, "name") else "Tool",  # Use the tool name as the class name
                __doc__=tool.description if hasattr(tool, "description") else "A tool to perform a task",
                input=(str, Field(..., description="Input to the tool")),  # Add an input field
            )
        pydantic_tools.append(tool_model)

        # Log the schema of the created tool model
        logger.info(f"Created Pydantic model for {tool.name if hasattr(tool, 'name') else 'Tool'}")

    return pydantic_tools

async def abstract_llm_completion(
    model_name: str,
    messages: List[Dict[str, str]],
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[float] = None,
    tools: Optional[List[Any]] = None
) -> Dict[str, Any]:
    """
    Unified interface for basic chat completion across providers.

    Args:
        model_name: The model identifier string
        messages: List of message dictionaries with 'role' and 'content' keys
        config: Application configuration object
        temperature: Optional temperature override
        max_tokens: Optional max tokens override
        tools: Optional list of tools to pass to the model

    Returns:
        Dictionary with status, content, provider, and model information
    """
    try:
        # Apply overrides if provided
        if temperature is not None or max_tokens is not None:
            # Create a copy of the config with overrides
            temp_config = Config()
            if temperature is not None:
                temp_config.TEMPERATURE = temperature
            if max_tokens is not None:
                temp_config.MAX_TOKENS = max_tokens
            config = temp_config

        provider, _ = get_model_provider(model_name)
        model = get_base_model(model_name, config)
        lc_messages = convert_to_langchain_messages(messages, provider)

        # If tools are provided, use bind_tools for models that support it
        if tools and tools:
            # Only use bind_tools for providers known to support it
            if provider in ["anthropic", "openai", "azure", "mistral", "cohere", "google"]:
                logger.info(f"Binding {len(tools)} tools to {model_name}")
                # Convert our tools to Pydantic models for bind_tools
                pydantic_tools = convert_tools_to_pydantic(tools)
                model = model.bind_tools(pydantic_tools)
                logger.info(f"Successfully bound tools to {model_name}")

        # Invoke the model
        response = await model.ainvoke(lc_messages)

        # Process the content which might be in different formats
        content = response.content
        processed_content = ""

        # Handle when content is a list (like with Anthropic's structured format)
        if isinstance(content, list):
            for item in content:
                if isinstance(item, dict) and "text" in item:
                    processed_content += item["text"]
        # Normal string content
        elif isinstance(content, str):
            processed_content = content
        else:
            # Fallback for other formats
            processed_content = str(content)

        return {
            "status": "success",
            "content": processed_content,
            "provider": get_model_provider(model_name)[0],
            "model": model_name,
            "raw_response": response
        }
    except Exception as e:
        logger.error(f"Error in abstract_llm_completion with {model_name}: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "content": str(e),
            "provider": get_model_provider(model_name)[0],
            "model": model_name
        }

async def abstract_llm_completion_stream(
    model_name: str,
    messages: List[Dict[str, str]],
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[float] = None,
    tools: Optional[List[Any]] = None
) -> AsyncGenerator[str, None]:
    """
    Unified interface for streaming chat completion across providers.
    Yields each token as it's generated by the model.

    Args:
        model_name: The model identifier string
        messages: List of message dictionaries with 'role' and 'content' keys
        config: Application configuration object
        temperature: Optional temperature override
        max_tokens: Optional max tokens override
        tools: Optional list of tools to make available to the model

    Yields:
        String tokens as they are generated
    """
    try:
        # Apply overrides if provided
        if temperature is not None or max_tokens is not None:
            # Create a copy of the config with overrides
            temp_config = Config()
            if temperature is not None:
                temp_config.TEMPERATURE = temperature
            if max_tokens is not None:
                temp_config.MAX_TOKENS = max_tokens
            config = temp_config

        # Get provider information
        provider, clean_model_name = get_model_provider(model_name)

        # Get streaming-enabled model
        model = get_streaming_model(model_name, config)
        lc_messages = convert_to_langchain_messages(messages, provider)

        # If tools are provided, use bind_tools for models that support it
        if tools and tools:
            # Only use bind_tools for providers known to support it
            if provider in ["anthropic", "openai", "azure", "mistral", "cohere", "google"]:
                logger.info(f"Binding {len(tools)} tools to {model_name}")
                # Convert our tools to Pydantic models for bind_tools
                pydantic_tools = convert_tools_to_pydantic(tools)
                model = model.bind_tools(pydantic_tools)
                logger.info(f"Successfully bound tools to {model_name}")

        # Stream the tokens
        async for chunk in model.astream(lc_messages):
            # Extract content from different types of chunks
            if isinstance(chunk, AIMessageChunk):
                content = chunk.content
                # Handle when content is a list (like with Anthropic's structured format)
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and "text" in item:
                            yield item["text"]
                # Normal string content
                elif isinstance(content, str) and content:
                    yield content
            elif isinstance(chunk, AIMessage):
                content = chunk.content
                # Handle when content is a list (like with Anthropic's structured format)
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and "text" in item:
                            yield item["text"]
                # Normal string content
                elif isinstance(content, str) and content:
                    yield content
            elif hasattr(chunk, "content"):
                content = chunk.content
                # Handle when content is a list (like with Anthropic's structured format)
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and "text" in item:
                            yield item["text"]
                # Normal string content
                elif isinstance(content, str) and content:
                    yield content
            elif isinstance(chunk, str) and chunk:
                yield chunk

    except Exception as e:
        error_message = f"Error in streaming with {model_name}: {str(e)}"
        logger.error(error_message, exc_info=True)
        yield error_message

async def abstract_llm_structured_output(
    model_name: str,
    messages: List[Dict[str, str]],
    response_model: BaseModel,
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None
) -> Dict[str, Any]:
    """
    Unified interface for structured output generation across providers.

    Args:
        model_name: The model identifier string
        messages: List of message dictionaries with 'role' and 'content' keys
        response_model: Pydantic model class for structured output
        config: Application configuration object
        temperature: Optional temperature override
        max_tokens: Optional max tokens override

    Returns:
        Dictionary with status, content, provider, and model information
    """
    try:
        # Apply overrides if provided
        if temperature is not None or max_tokens is not None:
            # Create a copy of the config with overrides
            temp_config = Config()
            if temperature is not None:
                temp_config.TEMPERATURE = temperature
            if max_tokens is not None:
                temp_config.MAX_TOKENS = max_tokens
            config = temp_config

        base_model = get_base_model(model_name, config)
        model = base_model.with_structured_output(response_model)

        lc_messages = convert_to_langchain_messages(messages)

        # Invoke the model
        response = await model.ainvoke(lc_messages)

        return {
            "status": "success",
            "content": response.model_dump(),
            "provider": get_model_provider(model_name)[0],
            "model": model_name,
            "raw_response": response
        }
    except Exception as e:
        logger.error(f"Error in abstract_llm_structured_output with {model_name}: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "content": str(e),
            "provider": get_model_provider(model_name)[0],
            "model": model_name
        }

async def langchain_llm_completion_stream(
    model_name: str,
    messages: List[BaseMessage],
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    tools: Optional[List[Any]] = None
) -> BaseMessage:
    """Get completions using LangChain message format.

    This function bridges between LangChain's message format and our internal format,
    allowing us to use our provider-agnostic completion with LangGraph tools.

    Args:
        model_name: The model to use
        messages: The conversation messages in LangChain format
        config: Configuration object
        temperature: Optional temperature override
        max_tokens: Optional max tokens override
        tools: Optional list of LangChain tools to bind to the model

    Returns:
        LangChain BaseMessage response
    """
    # Get the provider
    provider, model_provider_name = get_model_provider(model_name)

    # Log tool binding
    if tools:
        logger.info(f"Binding {len(tools)} tools to {model_name}")

    # Initialize the appropriate model class based on provider
    model_cls = None
    model_kwargs = {}

    if provider == "openai":
        model_cls = ChatOpenAI
        model_kwargs = {
            "model": model_provider_name,
            "api_key": config.OPENAI_API_KEY,
        }
        # Only add temperature for non-o1 models
        if model_provider_name != "o1" and temperature is not None:
            model_kwargs["temperature"] = temperature or config.TEMPERATURE
    elif provider == "anthropic":
        model_cls = ChatAnthropic
        model_kwargs = {
            "model": model_provider_name,
            "temperature": temperature or config.TEMPERATURE,
            "api_key": config.ANTHROPIC_API_KEY,
        }
    elif provider == "google":
        model_cls = ChatGoogleGenerativeAI
        model_kwargs = {
            "model": model_provider_name,
            "temperature": temperature or config.TEMPERATURE,
            "google_api_key": config.GOOGLE_API_KEY,
        }
    elif provider == "mistral":
        model_cls = ChatMistralAI
        model_kwargs = {
            "model": model_provider_name,
            "temperature": temperature or config.TEMPERATURE,
            "api_key": config.MISTRAL_API_KEY,
        }
    elif provider == "fireworks":
        model_cls = ChatFireworks
        model_kwargs = {
            "model": model_provider_name,
            "temperature": temperature or config.TEMPERATURE,
            "api_key": config.FIREWORKS_API_KEY,
        }
    elif provider == "groq":
        model_cls = ChatGroq
        model_kwargs = {
            "model": model_provider_name,
            "temperature": temperature or config.TEMPERATURE,
            "api_key": config.GROQ_API_KEY,
        }
    else:
        raise ValueError(f"Unsupported provider: {provider}")

    # Create model instance
    model = model_cls(**model_kwargs)

    # Bind tools if provided
    if tools:
        for tool in tools:
            # Convert pydantic schema if needed
            if not hasattr(tool, "args_schema"):
                tool_name = tool.__name__ if hasattr(tool, "__name__") else tool.name
                logger.info(f"Created Pydantic model for Tool {tool_name}")

        model_with_tools = model.bind_tools(tools)
        logger.info(f"Successfully bound tools to {model_name}")

        # Get AI response with tools
        return await model_with_tools.ainvoke(messages)
    else:
        # Get AI response without tools
        return await model.ainvoke(messages)

def is_tool_compatible(model_name: str, config: Config) -> bool:
    """
    Check if a model is compatible with tool binding.

    Args:
        model_name: The model identifier string
        config: Configuration object

    Returns:
        Boolean indicating if the model supports tool binding
    """
    provider, model_id = get_model_provider(model_name)

    # Get list of tool-compatible models
    tool_models = get_tool_compatible_models(config)

    # Check if this provider/model combination is in the tool-compatible list
    return provider in tool_models and model_id in tool_models.get(provider, [])

def is_temperature_compatible(model_name: str) -> bool:
    """
    Check if a model supports temperature parameter.

    Args:
        model_name: The model identifier string

    Returns:
        Boolean indicating if the model supports temperature parameter
    """
    provider, model_id = get_model_provider(model_name)

    # Models known to not support temperature
    if provider == "openai" and model_id.startswith("o3"):
        return False

    # Add other temperature-incompatible models here as needed

    # Default: most models support temperature
    return True

async def post_llm(
    model_name: str,
    messages: List[BaseMessage],
    config: Config,
    response_model: Optional[Type[BaseModel]] = None,
    stream: bool = False,  # We'll use this to determine whether to return complete messages or phase chunks
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    tools: Optional[List[Any]] = None
) -> Union[BaseMessage, AsyncIterator[AIMessageChunk]]:
    """
    Enhanced LLM completion function with structured output support.
    Modified to support phase-by-phase streaming without token-by-token streaming.

    Args:
        model_name: The model to use
        messages: The conversation messages in LangChain format
        config: Configuration object
        response_model: Optional Pydantic model for structured output
        stream: Whether to enable phase-based streaming (not token-by-token)
        temperature: Optional temperature override
        max_tokens: Optional max tokens override
        tools: Optional list of LangChain tools to bind to the model

    Returns:
        Either a complete message or an async iterator for phase chunks
    """
    # Extract provider from model name
    provider, provider_model = get_model_provider(model_name)
    logger.debug(f"Using {provider}/{provider_model} for completion")

    # Check temperature compatibility
    if temperature is not None and not is_temperature_compatible(model_name):
        logger.info(f"Model {provider_model} doesn't support temperature parameter - ignoring temperature setting")
        temperature = None

    # Always use non-streaming mode for the model itself
    # We'll handle the phase-based streaming in the LangGraph implementation
    model = get_base_model(model_name, config)

    # Apply overrides
    if temperature is not None and hasattr(model, "temperature"):
        model.temperature = temperature

    if max_tokens is not None:
        if hasattr(model, "max_tokens"):
            model.max_tokens = max_tokens
        elif hasattr(model, "max_tokens_to_sample"):
            model.max_tokens_to_sample = max_tokens

    # Handle special cases for different models
    if provider == "google" and provider_model.startswith("gemini"):
        messages = _prepare_messages_for_gemini(messages)

    # Bind tools if provided
    if tools:
        # Check if this model is compatible with tool binding
        if is_tool_compatible(model_name, config):
            logger.info(f"Binding {len(tools)} tools to {model_name}")
            try:
                # Convert pydantic schema if needed
                pydantic_tools = convert_tools_to_pydantic(tools)
                model = model.bind_tools(pydantic_tools)
                logger.info(f"Successfully bound tools to {model_name}")
            except Exception as e:
                logger.error(f"Error binding tools to {model_name}: {str(e)}")
        else:
            logger.warning(f"Model {model_name} is not known to be compatible with tools - skipping tool binding")

    # Add structured output if provided
    if response_model:
        try:
            model = model.with_structured_output(response_model)
            logger.info(f"Applied structured output model {response_model.__name__} to {model_name}")
        except Exception as e:
            logger.error(f"Error applying structured output: {str(e)}")

    # Execute request based on streaming mode
    try:
        if stream:
            # For phase-based streaming, we still return a full response but wrapped in an async generator
            # This allows LangGraph to continue its phase transitions
            async def phase_streamer():
                response = await model.ainvoke(messages)
                yield AIMessageChunk(content=response.content)

            return phase_streamer()
        else:
            # For non-streaming mode, just return the full response
            return await model.ainvoke(messages)
    except Exception as e:
        logger.error(f"Error in post_llm with {model_name}: {str(e)}")
        # Return a fallback message on error
        if stream:
            async def error_stream():
                yield AIMessageChunk(content=f"Error: {str(e)}")
            return error_stream()
        else:
            return AIMessage(content=f"Error: {str(e)}")

def _prepare_messages_for_gemini(messages: List[BaseMessage]) -> List[BaseMessage]:
    """Prepare messages for Gemini models which require non-empty content."""
    # Filter out empty messages
    filtered_messages = []
    for message in messages:
        # For user messages, ensure they have content
        if isinstance(message, HumanMessage):
            if not message.content or str(message.content).strip() == "":
                # Add a default prompt if message is empty
                logger.info(f"Adding default content to empty user message for Gemini model")
                message.content = "Please continue."
            filtered_messages.append(message)
        # For system messages, ensure they have content
        elif isinstance(message, SystemMessage):
            if not message.content or str(message.content).strip() == "":
                # Skip empty system messages or add placeholder content
                logger.info(f"Adding default content to empty system message for Gemini model")
                message.content = "You are a helpful assistant."
            filtered_messages.append(message)
        # Include all other message types
        else:
            filtered_messages.append(message)
    return filtered_messages

async def astream_langchain_llm_completion(
    model_name: str,
    messages: List[BaseMessage],
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    tools: Optional[List[Any]] = None
) -> AsyncIterator[AIMessageChunk]:
    """Stream completions using LangChain message format.

    DEPRECATED: Use post_llm with stream=True and response_model parameter instead.

    This function bridges between LangChain's message format and our internal format,
    allowing us to use our provider-agnostic completion with token-level streaming
    in LangGraph.

    Args:
        model_name: The model to use
        messages: The conversation messages in LangChain format
        config: Configuration object
        temperature: Optional temperature override
        max_tokens: Optional max tokens override
        tools: Optional list of LangChain tools to bind to the model

    Returns:
        AsyncIterator of AIMessageChunk objects for token-level streaming
    """
    # Extract provider from model name
    provider, provider_model = get_model_provider(model_name)
    logger.debug(f"Using {provider}/{provider_model} for streaming completion")

    # Check for models that don't support temperature
    temp_unsupported = False
    if provider == "openai" and provider_model.startswith("o3"):
        logger.info(f"Model {provider_model} doesn't support temperature parameter")
        temp_unsupported = True
        # Use a version of config with temperature removed
        modified_config = copy.deepcopy(config)
        modified_config.TEMPERATURE = None
        # Get the streaming-enabled model directly with modified config
        model = get_streaming_model(model_name, modified_config)
    else:
        # Get the streaming-enabled model directly
        model = get_streaming_model(model_name, config)

    # Special handling for Gemini models which require non-empty text in messages
    if provider == "google" and provider_model.startswith("gemini"):
        # Filter out empty messages
        filtered_messages = []
        for message in messages:
            # For user messages, ensure they have content
            if isinstance(message, HumanMessage):
                if not message.content or message.content.strip() == "":
                    # Add a default prompt if message is empty
                    logger.info(f"Adding default content to empty user message for Gemini model")
                    message.content = "Please continue."
                filtered_messages.append(message)
            # For system messages, ensure they have content
            elif isinstance(message, SystemMessage):
                if not message.content or message.content.strip() == "":
                    # Skip empty system messages or add placeholder content
                    logger.info(f"Adding default content to empty system message for Gemini model")
                    message.content = "You are a helpful assistant."
                filtered_messages.append(message)
            # Include all other message types
            else:
                filtered_messages.append(message)

        # Replace messages with filtered ones
        messages = filtered_messages
        logger.info(f"Prepared {len(messages)} messages for Gemini model")

    # Override temperature if provided and supported by the model
    if temperature is not None and not temp_unsupported:
        if hasattr(model, "temperature"):
            model.temperature = temperature

    # Override max_tokens if provided
    if max_tokens is not None:
        if provider in ["anthropic", "cohere"]:
            if hasattr(model, "max_tokens"):
                model.max_tokens = max_tokens
        else:
            if hasattr(model, "max_tokens_to_sample"):
                model.max_tokens_to_sample = max_tokens

    # Bind tools if provided
    if tools:
        for tool in tools:
            # Convert pydantic schema if needed
            if not hasattr(tool, "args_schema"):
                tool_name = tool.__name__ if hasattr(tool, "__name__") else tool.name
                logger.info(f"Created Pydantic model for Tool {tool_name}")

        model_with_tools = model.bind_tools(tools)
        logger.info(f"Successfully bound tools to {model_name} for streaming")

        # Stream response with tools
        try:
            async for chunk in model_with_tools.astream(messages):
                yield chunk
        except Exception as e:
            logger.error(f"Error streaming from {model_name} with tools: {str(e)}")
            # Yield a fallback message so the stream doesn't break
            yield AIMessageChunk(content=f"Error streaming: {str(e)}")
    else:
        # Stream response without tools
        try:
            async for chunk in model.astream(messages):
                yield chunk
        except Exception as e:
            logger.error(f"Error streaming from {model_name}: {str(e)}")
            # Yield a fallback message so the stream doesn't break
            yield AIMessageChunk(content=f"Error streaming: {str(e)}")
