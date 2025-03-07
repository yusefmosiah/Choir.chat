import json
import logging
from typing import Any, Dict, List, Optional

from duckduckgo_search import DDGS

from app.config import Config
from app.tools.base import BaseTool


logger = logging.getLogger(__name__)


class DuckDuckGoSearchTool(BaseTool):
    """
    A tool that performs web searches using the DuckDuckGo search engine.

    This serves as a backup search provider that doesn't require API keys,
    making it suitable for development and testing environments.
    """

    name = "web_search"
    description = (
        "Search the web for real-time information about any topic. "
        "Use this tool when you need up-to-date information that might not be available "
        "in your training data, or when you need to verify current facts."
    )

    def __init__(
        self,
        config: Config,
        max_results: int = 40,
        safe_search: str = "moderate",
        region: Optional[str] = "wt-wt",
        time_period: Optional[str] = "m",
        backend: Optional[str] = "api",
        name: Optional[str] = None,
        description: Optional[str] = None
    ):
        """
        Initialize the DuckDuckGo search tool.

        Args:
            config: The application configuration
            max_results: Maximum number of results to return
            safe_search: Safe search setting ('off', 'moderate', or 'strict')
            region: Region code for localized results (e.g., 'us-en')
            time_period: Time period filter ('d' for day, 'w' for week, 'm' for month, 'y' for year)
            backend: Backend to use ('api', 'html', or 'lite')
            name: Optional custom name for the tool
            description: Optional custom description for the tool
        """
        self.config = config
        self.max_results = max_results
        self.safe_search = safe_search
        self.region = region
        self.time_period = time_period
        self.backend = backend

        # Initialize the base class
        super().__init__(name=name, description=description)

    async def run(self, query: str) -> str:
        """
        Execute a web search with the provided query.

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
            logger.info(f"Performing DuckDuckGo search for: {query}")

            # Try different backends if specified backend fails
            backends_to_try = [self.backend] if self.backend else ["api", "html", "lite"]

            search_results = []
            last_error = None

            for backend in backends_to_try:
                try:
                    # Create DuckDuckGo search client
                    ddgs = DDGS()

                    logger.debug(f"Trying DuckDuckGo search with backend: {backend}")

                    if backend == "api":
                        # Use the API backend
                        raw_results = list(ddgs.text(
                            query,
                            region=self.region,
                            safesearch=self.safe_search,
                            timelimit=self.time_period,
                            max_results=max(30, self.max_results * 2),
                            backend=backend
                        ))
                    else:
                        # Use other backends
                        raw_results = list(ddgs.text(
                            query,
                            region=self.region,
                            safesearch=self.safe_search,
                            timelimit=self.time_period,
                            max_results=max(30, self.max_results * 2)
                        ))

                    # If we got results, use them and stop trying other backends
                    if raw_results:
                        search_results = raw_results[:self.max_results]
                        break

                except Exception as e:
                    last_error = e
                    logger.warning(f"DuckDuckGo search with {backend} backend failed: {str(e)}")
                    continue  # Try next backend

            # If all backends failed, raise the last error to be caught by outer try-except
            if not search_results and last_error:
                raise last_error

            # Process results
            formatted_results = []
            for result in search_results:
                formatted_results.append({
                    "title": result.get("title", ""),
                    "url": result.get("href", ""),
                    "content": result.get("body", "")
                })

            # Create formatted response
            response = {
                "query": query,
                "results": formatted_results
            }

            # Add a message for empty results - match expected message exactly
            if not formatted_results:
                response["message"] = "No results found for your query"
                logger.warning(f"No results found for query: {query}")

            return json.dumps(response, ensure_ascii=False)

        except Exception as e:
            logger.error(f"Error during DuckDuckGo search: {str(e)}")
            error_response = {
                "query": query,
                "results": [],
                "error": "The search could not be completed due to an error"
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
