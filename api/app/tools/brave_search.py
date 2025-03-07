"""
Brave Search tool implementation.
"""
import os
import json
import logging
import asyncio
import requests
from typing import Dict, Any, List, Optional, Union

from app.config import Config
from app.tools.base import BaseTool

logger = logging.getLogger(__name__)

class BraveSearchTool(BaseTool):
    """
    A tool that performs web searches using the Brave Search API.

    This provides high-quality search results with official API support.
    """

    name = "brave_search"
    description = "Search the web for current information using Brave Search. Use this for recent events, facts, or information that might not be in the model's training data."

    # Brave Search API endpoint
    API_ENDPOINT = "https://api.search.brave.com/res/v1/web/search"

    def __init__(
        self,
        config: Config = None,
        api_key: Optional[str] = None,
        max_results: int = 40,
        country: Optional[str] = None,
        search_lang: Optional[str] = None,
        name: Optional[str] = None,
        description: Optional[str] = None
    ):
        """
        Initialize the Brave Search tool.

        Args:
            config: Application configuration
            api_key: Optional API key (overrides config)
            max_results: Maximum number of results to return
            country: Optional country code for localized results (e.g., 'us', 'gb')
            search_lang: Optional language code (e.g., 'en', 'es', 'fr')
            name: Optional custom name for the tool
            description: Optional custom description for the tool
        """
        self.config = config or Config()

        # Get API key
        self.api_key = api_key or os.environ.get("BRAVE_API_KEY")

        # Try to load from a path if defined
        if not self.api_key and os.environ.get("BRAVE_API_KEY_PATH"):
            try:
                with open(os.environ.get("BRAVE_API_KEY_PATH"), "r") as f:
                    self.api_key = f.read().strip()
            except Exception as e:
                logger.warning(f"Failed to load Brave API key from path: {e}")

        self.max_results = max_results
        self.country = country
        self.search_lang = search_lang

        # Initialize the base class
        super().__init__(name=name, description=description)

    async def run(self, query: str) -> str:
        """
        Execute a web search with Brave Search API.

        Args:
            query: The search query

        Returns:
            A JSON string with search results formatted as:
            {
                "query": "your search query",
                "results": [
                    {
                        "title": "Result title",
                        "url": "https://example.com",
                        "content": "Snippet from the result"
                    },
                    ...
                ]
            }
        """
        try:
            logger.info(f"Performing Brave search for: {query}")

            if not self.api_key:
                return json.dumps({
                    "query": query,
                    "results": [],
                    "error": "Brave Search API key not configured"
                })

            # Set up headers with API key
            headers = {
                "Accept": "application/json",
                "X-Subscription-Token": self.api_key
            }

            # Set up parameters
            params = {
                "q": query,
                "count": min(self.max_results, 20),  # Limit to 20 as that's the API's maximum
            }

            # Add optional parameters if specified
            if self.country:
                params["country"] = self.country
            if self.search_lang:
                params["search_lang"] = self.search_lang

            # Make the request
            response = requests.get(self.API_ENDPOINT, headers=headers, params=params)

            # Check if the request was successful
            if response.status_code != 200:
                logger.error(f"Brave Search API error: {response.status_code} - {response.text}")
                return json.dumps({
                    "query": query,
                    "results": [],
                    "error": f"Search API returned error {response.status_code}: {response.text}"
                })

            # Parse the response
            data = response.json()

            # Format the results
            results = []
            web_results = data.get("web", {}).get("results", [])

            for result in web_results[:self.max_results]:
                results.append({
                    "title": result.get("title", ""),
                    "url": result.get("url", ""),
                    "content": result.get("description", "")
                })

            # Create the response object
            response_data = {
                "query": query,
                "results": results
            }

            # Add a message for empty results
            if not results:
                response_data["message"] = "No results found for your query"
                logger.warning(f"No results found for query: {query}")

            return json.dumps(response_data, ensure_ascii=False)

        except Exception as e:
            logger.error(f"Error during Brave search: {str(e)}")
            error_response = {
                "query": query,
                "results": [],
                "error": f"The search could not be completed due to an error: {str(e)}"
            }
            return json.dumps(error_response, ensure_ascii=False)

    def to_dict(self) -> Dict[str, Any]:
        """Convert the tool to a dictionary for serialization."""
        base_dict = super().to_dict()
        base_dict["parameters"] = {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "The search query to look up on the web"
                }
            },
            "required": ["query"]
        }
        return base_dict
