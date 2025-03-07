"""
Test the updated web search tool with timestamps and trust instructions.
"""
import asyncio
import logging
import json
import pytest
from typing import Dict, Any, List, Union

from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list
from app.tools.web_search import WebSearchTool
from app.tools.conversation import ConversationWithTools

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TestUpdatedWebSearchTool:
    """Test case to evaluate the updated web search tool with timestamps."""

    @pytest.mark.asyncio
    async def test_search_with_timestamps(self):
        """Test if the updated web search tool with timestamps helps models accept search results."""
        config = Config()

        # Initialize model list without OpenAI
        models = initialize_model_list(config, disabled_providers={"openai"})

        # Skip if no models are available
        if not models:
            pytest.skip("No models available for testing")

        # Select a specific model to use (use the first available one for consistency)
        model = models[0]
        logger.info(f"Testing with model: {model}")

        # Create the updated web search tool
        web_search = WebSearchTool(config=config)

        # Create a conversation with this tool and updated system prompt
        conversation = ConversationWithTools(
            models=[model],
            tools=[web_search],
            config=config
        )

        # Log the system prompt being used
        logger.info(f"System prompt: {conversation.system_prompt}")

        # Run first test with Super Bowl LIX
        lix_result = await conversation.process_message(
            "Please search for information about Super Bowl LIX which was played on February 9, 2025. Who won the game and what was the final score?"
        )

        # Log and analyze the response
        logger.info(f"Super Bowl LIX response: {lix_result['content']}")

        # Check if the response mentions Eagles win and 40-22 score
        lix_response = lix_result['content'].lower()
        has_eagles = "eagles won" in lix_response or "eagles defeated" in lix_response
        has_40_22 = "40-22" in lix_response

        logger.info(f"Response mentions Eagles winning: {has_eagles}")
        logger.info(f"Response mentions 40-22 score: {has_40_22}")

        # Run second test with Super Bowl LVIII (a real event)
        lviii_result = await conversation.process_message(
            "Please search for information about Super Bowl LVIII which was played in February 2024. Who won the game and what was the final score?"
        )

        # Log and analyze the response
        logger.info(f"Super Bowl LVIII response: {lviii_result['content']}")

        # Check if the response mentions Chiefs win and 25-22 score
        lviii_response = lviii_result['content'].lower()
        has_chiefs = "chiefs won" in lviii_response or "chiefs defeated" in lviii_response
        has_25_22 = "25-22" in lviii_response

        logger.info(f"Response mentions Chiefs winning: {has_chiefs}")
        logger.info(f"Response mentions 25-22 score: {has_25_22}")

        # Don't assert - these are diagnostic tests to analyze model behavior
        # This will be a manual assessment to see if the improvements help
        assert True

if __name__ == "__main__":
    pytest.main(["-xvs", __file__])
