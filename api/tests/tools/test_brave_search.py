"""
Test the Brave Search tool.
"""
import json
import pytest
from unittest.mock import MagicMock, patch

from app.config import Config
from app.tools.base import BaseTool


class TestBraveSearchTool:
    """Tests for Brave Search tool implementation."""

    @pytest.mark.asyncio
    async def test_search_tool_creation(self):
        """Test that we can create the Brave Search tool."""
        try:
            from app.tools.brave_search import BraveSearchTool

            config = Config()
            # Skip if no API key
            if not config.get("BRAVE_API_KEY") and not config.get("BRAVE_API_KEY_PATH"):
                pytest.skip("Brave Search API key not configured")

            search_tool = BraveSearchTool(config=config)

            assert isinstance(search_tool, BaseTool)
            assert search_tool.name == "brave_search"
            assert "search the web" in search_tool.description.lower()
        except ImportError:
            pytest.fail("Could not import BraveSearchTool")

    @pytest.mark.asyncio
    @patch("app.tools.brave_search.requests.get")
    async def test_basic_search(self, mock_get):
        """Test that the search returns properly formatted results."""
        from app.tools.brave_search import BraveSearchTool

        # Mock search results
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "web": {
                "results": [
                    {
                        "title": "Test Result 1",
                        "url": "https://example.com/1",
                        "description": "This is the first test result"
                    },
                    {
                        "title": "Test Result 2",
                        "url": "https://example.com/2",
                        "description": "This is the second test result with more content"
                    }
                ],
                "totalCount": 2
            }
        }
        mock_get.return_value = mock_response

        # Create tool and run search
        search_tool = BraveSearchTool(config=Config(), api_key="test_key")
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
    @patch("app.tools.brave_search.requests.get")
    async def test_empty_results(self, mock_get):
        """Test handling of empty results."""
        from app.tools.brave_search import BraveSearchTool

        # Mock empty results
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "web": {
                "results": [],
                "totalCount": 0
            }
        }
        mock_get.return_value = mock_response

        # Create tool and run search
        search_tool = BraveSearchTool(config=Config(), api_key="test_key")
        result = await search_tool.run("query with no results")

        # Verify result indicates no results found
        data = json.loads(result)
        assert "results" in data
        assert len(data["results"]) == 0
        assert "query" in data
        assert "message" in data
        assert "no results found" in data["message"].lower()

    @pytest.mark.asyncio
    @patch("app.tools.brave_search.requests.get")
    async def test_api_error(self, mock_get):
        """Test handling of API errors."""
        from app.tools.brave_search import BraveSearchTool

        # Mock API error
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_response.text = "Unauthorized"
        mock_get.return_value = mock_response

        # Create tool and run search
        search_tool = BraveSearchTool(config=Config(), api_key="invalid_key")
        result = await search_tool.run("error query")

        # Verify error handling
        data = json.loads(result)
        assert "error" in data
        assert "401" in data["error"]

    @pytest.mark.asyncio
    @patch("app.tools.brave_search.requests.get")
    async def test_result_limit(self, mock_get):
        """Test that results are limited to the specified number."""
        from app.tools.brave_search import BraveSearchTool

        # Create many mock results
        mock_results = [
            {
                "title": f"Test Result {i}",
                "url": f"https://example.com/{i}",
                "description": f"This is test result number {i}"
            }
            for i in range(10)
        ]

        # Mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "web": {
                "results": mock_results,
                "totalCount": len(mock_results)
            }
        }
        mock_get.return_value = mock_response

        # Create tool with limit of 5 results
        search_tool = BraveSearchTool(config=Config(), api_key="test_key", max_results=5)
        result = await search_tool.run("test query")

        # Verify limited results
        data = json.loads(result)
        assert len(data["results"]) == 5
        assert data["results"][4]["title"] == "Test Result 4"


if __name__ == "__main__":
    pytest.main(["-xvs", __file__])
