"""
Abstraction layer for interacting with various LLM providers through LangChain.
This module provides a unified interface for basic chat completions and structured output generations
across multiple model providers.
"""

import logging
import random
from typing import Dict, Any, List, Optional, Tuple, AsyncGenerator
from pydantic import BaseModel
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
        config.OPENAI_GPT_45_PREVIEW,
        config.OPENAI_GPT_4O,
        config.OPENAI_GPT_4O_MINI,
        config.OPENAI_O1,
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
        config.FIREWORKS_QWEN25_CODER
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
        if clean_name in [config.OPENAI_O1, config.OPENAI_O3_MINI]:
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
    Convert dictionary-based messages to LangChain message objects.

    Args:
        messages: List of message dictionaries with 'role' and 'content' keys
        provider: Optional provider name to handle provider-specific formatting

    Returns:
        List of LangChain message objects
    """
    is_anthropic = provider and "anthropic" in provider.lower() if provider else False

    lc_messages = []
    for msg in messages:
        if msg["role"] == "system":
            lc_messages.append(SystemMessage(content=msg["content"]))
        elif msg["role"] == "user":
            lc_messages.append(HumanMessage(content=msg["content"]))
        elif msg["role"] == "assistant":
            lc_messages.append(AIMessage(content=msg["content"]))
        elif msg["role"] == "tool":
            # For Anthropic models, don't use ToolMessage as they have their own format
            if is_anthropic:
                # Convert tool messages to user messages for Anthropic
                lc_messages.append(HumanMessage(content=f"Tool results: {msg['content']}"))
            else:
                # Handle tool messages - parse tool name from the content if possible
                tool_name = "unknown_tool"
                content = msg["content"]

                # Try to extract tool name if in format [tool_name] output: result
                tool_match = re.match(r"\[([\w_]+)\]\s+output:", content)
                if tool_match:
                    tool_name = tool_match.group(1)

                lc_messages.append(ToolMessage(content=content, tool_call_id=tool_name))
        # Ignore other message types
    return lc_messages

async def abstract_llm_completion(
    model_name: str,
    messages: List[Dict[str, str]],
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None
) -> Dict[str, Any]:
    """
    Unified interface for basic chat completion across providers.

    Args:
        model_name: The model identifier string
        messages: List of message dictionaries with 'role' and 'content' keys
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

        provider, _ = get_model_provider(model_name)
        model = get_base_model(model_name, config)
        lc_messages = convert_to_langchain_messages(messages, provider)

        # Invoke the model
        response = await model.ainvoke(lc_messages)

        return {
            "status": "success",
            "content": response.content,
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
    max_tokens: Optional[int] = None
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

        # Get streaming-enabled model
        provider, _ = get_model_provider(model_name)
        model = get_streaming_model(model_name, config)
        lc_messages = convert_to_langchain_messages(messages, provider)

        # Stream the tokens
        async for chunk in model.astream(lc_messages):
            # Extract content from different types of chunks
            if isinstance(chunk, AIMessageChunk):
                # For AIMessageChunks, content is directly accessible
                if chunk.content:
                    yield chunk.content
            elif isinstance(chunk, AIMessage):
                # For complete AIMessages (some providers might return these)
                if chunk.content:
                    yield chunk.content
            elif isinstance(chunk, BaseMessage):
                # Generic handling for other message types
                if chunk.content:
                    yield chunk.content
            elif hasattr(chunk, "content"):
                # For objects with content attribute
                if chunk.content:
                    yield chunk.content
            else:
                # Fallback for other formats (e.g., dictionaries or strings)
                content = str(chunk)
                if content:
                    yield content

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
