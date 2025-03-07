import json
import pytest
from unittest.mock import MagicMock, patch

from app.config import Config
from app.tools.base import BaseTool


class TestDuckDuckGoSearchTool:
    """Tests for DuckDuckGo search tool implementation."""

    @pytest.mark.asyncio
    async def test_search_tool_creation(self):
        """Test that we can create the DuckDuckGo search tool."""
        try:
            from app.tools.duckduckgo_search import DuckDuckGoSearchTool

            config = Config()
            search_tool = DuckDuckGoSearchTool(config=config)

            assert isinstance(search_tool, BaseTool)
            assert search_tool.name == "web_search"
            assert "search the web" in search_tool.description.lower()
        except ImportError:
            pytest.fail("Could not import DuckDuckGoSearchTool")

    @pytest.mark.asyncio
    @patch("app.tools.duckduckgo_search.DDGS")
    async def test_basic_search(self, mock_ddgs):
        """Test that the search returns properly formatted results."""
        from app.tools.duckduckgo_search import DuckDuckGoSearchTool

        # Mock search results
        mock_results = [
            {
                "title": "Test Result 1",
                "href": "https://example.com/1",
                "body": "This is the first test result"
            },
            {
                "title": "Test Result 2",
                "href": "https://example.com/2",
                "body": "This is the second test result with more content"
            }
        ]

        # Set up the mock
        mock_instance = MagicMock()
        mock_instance.text.return_value = mock_results
        mock_ddgs.return_value = mock_instance

        # Create tool and run search
        search_tool = DuckDuckGoSearchTool(config=Config())
        result = await search_tool.run("test query")

        # Verify result structure
        assert isinstance(result, str)
        data = json.loads(result)
        assert "results" in data
        assert len(data["results"]) == 2
        assert "query" in data
        assert data["query"] == "test query"

        # Verify first result
        first_result = data["results"][0]
        assert "title" in first_result
        assert "url" in first_result
        assert "content" in first_result
        assert first_result["title"] == "Test Result 1"
        assert first_result["url"] == "https://example.com/1"
        assert first_result["content"] == "This is the first test result"

    @pytest.mark.asyncio
    @patch("app.tools.duckduckgo_search.DDGS")
    async def test_empty_results(self, mock_ddgs):
        """Test handling of empty results."""
        from app.tools.duckduckgo_search import DuckDuckGoSearchTool

        # Mock empty results
        mock_instance = MagicMock()
        mock_instance.text.return_value = []
        mock_ddgs.return_value = mock_instance

        # Create tool and run search
        search_tool = DuckDuckGoSearchTool(config=Config())
        result = await search_tool.run("query with no results")

        # Verify result indicates no results found
        data = json.loads(result)
        assert "results" in data
        assert len(data["results"]) == 0
        assert "query" in data
        assert "message" in data

        # Check that the message contains the expected text (case-insensitive)
        assert "no results found for your query" in data["message"].lower()

    @pytest.mark.asyncio
    @patch("app.tools.duckduckgo_search.DDGS")
    async def test_result_limit(self, mock_ddgs):
        """Test that results are limited to the specified number."""
        from app.tools.duckduckgo_search import DuckDuckGoSearchTool

        # Create many mock results
        mock_results = [
            {
                "title": f"Test Result {i}",
                "href": f"https://example.com/{i}",
                "body": f"This is test result number {i}"
            }
            for i in range(20)  # Create 20 results
        ]

        # Set up the mock
        mock_instance = MagicMock()
        mock_instance.text.return_value = mock_results
        mock_ddgs.return_value = mock_instance

        # Create tool with limit of 5 results
        search_tool = DuckDuckGoSearchTool(config=Config(), max_results=5)
        result = await search_tool.run("test query")

        # Verify limited results
        data = json.loads(result)
        assert len(data["results"]) == 5
        assert data["results"][4]["title"] == "Test Result 4"

    @pytest.mark.asyncio
    @patch("app.tools.duckduckgo_search.DDGS")
    async def test_error_handling(self, mock_ddgs):
        """Test that the tool properly handles errors during search."""
        from app.tools.duckduckgo_search import DuckDuckGoSearchTool

        # Set up mock to raise an exception
        mock_instance = MagicMock()
        mock_instance.text.side_effect = Exception("Search error")
        mock_ddgs.return_value = mock_instance

        # Create tool and run search
        search_tool = DuckDuckGoSearchTool(config=Config())
        result = await search_tool.run("error query")

        # Verify error handling
        assert "error" in result.lower()
        assert "search could not be completed" in result.lower()
