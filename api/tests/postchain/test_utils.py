"""
Shared testing utilities for postchain tests.
Contains common functionality used across different test scripts.
"""

import logging
import os
import re
from typing import Dict, Any, List
from dataclasses import dataclass

from app.config import Config
from tests.postchain.test_providers import (
    get_openai_models,
    get_anthropic_models,
    get_google_models,
    get_mistral_models,
    get_fireworks_models,
    get_cohere_models
)

logger = logging.getLogger(__name__)

@dataclass
class ModelConfig:
    provider: str
    model_name: str

    def __str__(self):
        return f"{self.provider}/{self.model_name}"

def load_prompts():
    """Load conversation prompts from the random_gen_prompts.md file.

    Returns:
        List[str]: A list of prompt strings
    """
    prompts = []
    try:
        # Get the directory of the current script
        current_dir = os.path.dirname(os.path.abspath(__file__))
        prompts_file = os.path.join(current_dir, "random_gen_prompts.md")

        with open(prompts_file, "r") as f:
            content = f.read()

        # Extract prompts using regex
        matches = re.findall(r'\d+\.\s+"(.*?)"', content)
        if matches:
            prompts = matches
            logger.info(f"Loaded {len(prompts)} prompts from random_gen_prompts.md")
        else:
            # Fallback prompts if file parsing fails
            prompts = set_fallback_prompts("Failed to parse prompts from file")
    except Exception as e:
        logger.error(f"Error loading prompts: {str(e)}")
        # Fallback prompts if file is missing
        prompts = set_fallback_prompts(f"Error reading prompts file: {str(e)}")

    return prompts

def set_fallback_prompts(reason):
    """Set fallback prompts when the file can't be loaded properly.

    Args:
        reason (str): Reason for using fallback prompts

    Returns:
        List[str]: A list of fallback prompts
    """
    fallback_prompts = [
        "Tell me about an interesting scientific concept.",
        "What are your thoughts on artificial intelligence?",
        "Explain a complex topic in simple terms.",
        "Share an interesting historical fact.",
        "What's your perspective on technological progress?",
        "Describe a philosophical dilemma.",
        "Tell me about a fascinating natural phenomenon.",
        "What are some emerging trends in technology?",
        "Explain how something in daily life works.",
        "Share some insights about human psychology."
    ]
    logger.warning(f"{reason}. Using {len(fallback_prompts)} fallback prompts.")
    return fallback_prompts

def initialize_model_list(config: Config) -> List[ModelConfig]:
    """Initialize the list of available models to choose from

    Args:
        config (Config): Application configuration with API keys

    Returns:
        List[ModelConfig]: List of available models
    """
    models = []
    if config.OPENAI_API_KEY:
        models.extend([ModelConfig("openai", m) for m in get_openai_models(config)])
    if config.ANTHROPIC_API_KEY:
        models.extend([ModelConfig("anthropic", m) for m in get_anthropic_models(config)])
    if config.GOOGLE_API_KEY:
        models.extend([ModelConfig("google", m) for m in get_google_models(config)])
    if config.MISTRAL_API_KEY:
        models.extend([ModelConfig("mistral", m) for m in get_mistral_models(config)])
    if config.FIREWORKS_API_KEY:
        models.extend([ModelConfig("fireworks", m) for m in get_fireworks_models(config)])
    if config.COHERE_API_KEY:
        models.extend([ModelConfig("cohere", m) for m in get_cohere_models(config)])
    logger.info(f"Initialized {len(models)} models for testing")
    return models

# Add self-test capability
if __name__ == "__main__":
    # Configure basic logging
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    print("==== Testing Postchain Test Utilities ====")

    # Test prompt loading
    print("\nTesting prompt loading:")
    prompts = load_prompts()
    print(f"Loaded {len(prompts)} prompts")
    if prompts:
        print("Sample prompts:")
        for i, prompt in enumerate(prompts[:3]):
            print(f"  {i+1}. {prompt[:50]}..." if len(prompt) > 50 else f"  {i+1}. {prompt}")

    # Test model initialization
    print("\nTesting model initialization:")
    config = Config()
    models = initialize_model_list(config)
    print(f"Initialized {len(models)} models")

    if models:
        print("Available model providers:")
        providers = set(model.provider for model in models)
        for provider in providers:
            provider_models = [model for model in models if model.provider == provider]
            print(f"  {provider}: {len(provider_models)} models")

    print("\n==== Test Utilities Check Complete ====")
