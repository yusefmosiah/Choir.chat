"""
Test the Tavily search tool.
"""
import os
import pytest
import logging
from typing import List, Dict, Any

from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list
from app.tools.conversation import ConversationWithTools

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TestTavilySearchTool:
    """Test suite for the Tavily search tool."""

    @pytest.mark.asyncio
    async def test_tavily_search_basic(self):
        """Test basic Tavily search functionality."""
        # Skip if no Tavily API key
        if not os.environ.get("TAVILY_API_KEY") and not os.environ.get("TAVILY_API_KEY_PATH"):
            pytest.skip("Tavily API key not configured")

        from app.tools.tavily_search import TavilySearchTool

        config = Config()
        search = TavilySearchTool(config=config)

        # Test a simple search query
        result = await search.run("What is the capital of France?")

        # Log the result for debugging
        logger.info(f"Search result: {result[:200]}...")

        # Verify we got meaningful results
        assert "Paris" in result
        assert len(result) > 100  # Ensure we got substantial content

    @pytest.mark.asyncio
    async def test_tavily_search_format(self):
        """Test Tavily search result formatting."""
        # Skip if no Tavily API key
        if not os.environ.get("TAVILY_API_KEY") and not os.environ.get("TAVILY_API_KEY_PATH"):
            pytest.skip("Tavily API key not configured")

        from app.tools.tavily_search import TavilySearchTool

        config = Config()
        search = TavilySearchTool(config=config)

        # Test with more complex query that should return structured results
        result = await search.run("Latest news about renewable energy technology")

        # Log the result for debugging
        logger.info(f"Search result: {result[:200]}...")

        # Verify formatting includes sources
        assert "Source:" in result or "http" in result
        assert len(result.split("\n")) > 3  # Multiple lines of content

    @pytest.mark.asyncio
    async def test_tavily_search_in_multimodel_thread(self):
        """Test Tavily search tool in a multimodel conversation thread."""
        # Skip if no Tavily API key
        if not os.environ.get("TAVILY_API_KEY") and not os.environ.get("TAVILY_API_KEY_PATH"):
            pytest.skip("Tavily API key not configured")

        from app.tools.tavily_search import TavilySearchTool

        config = Config()

        # Initialize model list without OpenAI
        models = initialize_model_list(config, disabled_providers={"openai"})

        # Skip if no models are available
        if not models:
            pytest.skip("No models available for testing")

        # Create a conversation with search tool
        search = TavilySearchTool(config=config)
        conversation = ConversationWithTools(models, tools=[search], config=config)

        # Run conversation with search query
        result = await conversation.process_message(
            "What are the latest developments in quantum computing? Please search for this information."
        )

        # Log the result for debugging
        logger.info(f"Response content: {result['content'][:200]}...")

        # Check for search tool usage
        tool_markers = [
            "[tavily_search] input:",
            "I'll use the tavily_search tool",
            "search for quantum computing"
        ]

        tool_was_used = any(marker in result["content"] for marker in tool_markers)
        assert tool_was_used, "Search tool was not called"

        # Run a follow-up message to test context preservation
        follow_up = await conversation.process_message(
            "Can you explain one of these developments in more detail?"
        )

        # Log the follow-up for debugging
        logger.info(f"Follow-up content: {follow_up['content'][:200]}...")

        # Verify the follow-up references something from the search results
        has_context = len(follow_up["content"]) > 200  # Substantive response
        assert has_context, "Follow-up response did not maintain search context"

if __name__ == "__main__":
    pytest.main(["-xvs", __file__])
