"""
Web search tool with fallback capabilities across multiple providers.
"""
import json
import logging
import asyncio
from typing import Dict, Any, List, Optional, Union, Tuple

from app.config import Config
from app.tools.base import BaseTool
from app.tools.tavily_search import TavilySearchTool
from app.tools.duckduckgo_search import DuckDuckGoSearchTool
from app.tools.brave_search import BraveSearchTool


logger = logging.getLogger(__name__)


class WebSearchTool(BaseTool):
    """
    A web search tool that combines multiple search providers with fallback capabilities.

    This tool attempts to use the primary provider first, then falls back to alternatives
    if the primary search fails or returns no results.
    """

    name = "web_search"
    description = "Search the web for current information. Use this for recent events, facts, or information that might not be in the model's training data."

    def __init__(
        self,
        config: Config = None,
        primary_provider: str = "brave",
        fallback_providers: Optional[List[str]] = None,
        max_results: int = 40,
        name: Optional[str] = None,
        description: Optional[str] = None
    ):
        """
        Initialize the web search tool with fallback capability.

        Args:
            config: Application configuration
            primary_provider: The primary search provider to use ('brave', 'tavily', or 'duckduckgo')
            fallback_providers: Ordered list of fallback providers if primary fails
            max_results: Maximum number of results to return
            name: Optional custom name for the tool
            description: Optional custom description for the tool
        """
        self.config = config or Config()
        self.max_results = max_results

        # Set default fallback order if not provided
        if fallback_providers is None:
            fallback_providers = ["tavily", "duckduckgo"]  # Changed fallback order

        self.primary_provider = primary_provider
        self.fallback_providers = fallback_providers

        # Initialize search providers
        self.search_tools = {}

        # Initialize all available providers
        self._initialize_providers()

        # Initialize the base class
        super().__init__(name=name, description=description)

    def _initialize_providers(self):
        """Initialize all available search providers."""
        # Try to initialize Tavily
        try:
            self.search_tools["tavily"] = TavilySearchTool(
                config=self.config,
                k=self.max_results,
                max_results_length=4000,  # Increase result length for better context
                include_raw_content=True,
                include_images=False      # Disable images to focus on text content
            )
            logger.info("Tavily search provider initialized")
        except Exception as e:
            logger.warning(f"Failed to initialize Tavily search: {e}")

        # Try to initialize DuckDuckGo
        try:
            self.search_tools["duckduckgo"] = DuckDuckGoSearchTool(
                config=self.config,
                max_results=self.max_results,
                region="wt-wt",           # Use worldwide region
                time_period="m",          # Search last month by default
                backend="api",            # Explicitly use API backend
                safe_search="moderate"
            )
            logger.info("DuckDuckGo search provider initialized")
        except Exception as e:
            logger.warning(f"Failed to initialize DuckDuckGo search: {e}")

        # Try to initialize Brave
        try:
            self.search_tools["brave"] = BraveSearchTool(
                config=self.config,
                max_results=self.max_results
            )
            logger.info("Brave search provider initialized")
        except Exception as e:
            logger.warning(f"Failed to initialize Brave search: {e}")

    async def _try_search(self, provider: str, query: str) -> Tuple[bool, str, List[Dict[str, str]]]:
        """
        Try to search with a specific provider.

        Args:
            provider: The provider to use
            query: The search query

        Returns:
            Tuple of (success, raw_result, parsed_results)
        """
        if provider not in self.search_tools:
            logger.warning(f"Search provider '{provider}' not available")
            return False, "", []

        try:
            # Run the search
            raw_result = await self.search_tools[provider].run(query)
            data = json.loads(raw_result)

            # Check if there was an error
            if "error" in data:
                logger.warning(f"Error in {provider} search: {data['error']}")
                return False, raw_result, []

            # Check if there are results
            results = data.get("results", [])
            if not results:
                logger.info(f"No results from {provider} for query: {query}")
                return True, raw_result, []  # Success but no results

            return True, raw_result, results

        except Exception as e:
            logger.error(f"Exception in {provider} search: {str(e)}")
            return False, "", []

    async def run(self, query: str) -> str:
        """
        Execute the web search with fallback capability.

        Args:
            query: The search query

        Returns:
            A string containing the search results in JSON format
        """
        logger.info(f"Performing web search for: {query}")

        # Define search order - primary provider first, then fallbacks
        search_order = [self.primary_provider] + [
            p for p in self.fallback_providers if p != self.primary_provider
        ]

        results = []
        providers_used = []

        # Try providers in search_order
        for provider in search_order:
            # Skip if provider not available
            if provider not in self.search_tools:
                continue

            logger.info(f"Trying search with provider: {provider}")
            try:
                success, raw_results, parsed_results = await self._try_search(provider, query)

                if success and parsed_results:
                    # Add provider info to each result
                    for result in parsed_results:
                        result["provider"] = provider

                    results.extend(parsed_results)
                    providers_used.append(provider)

                    # If we have enough results, stop searching
                    if len(results) >= self.max_results:
                        logger.info(f"Found {len(results)} results with {provider}")
                        break

                    # Otherwise continue to next provider for more results
                    logger.info(f"Found {len(parsed_results)} results with {provider}, continuing search")
            except Exception as e:
                logger.error(f"Error in {provider} search: {e}")

        # Limit to max_results
        results = results[:self.max_results]

        # If no results, return a helpful message
        if not results:
            return json.dumps({
                "query": query,
                "error": "No results found across any search providers.",
                "providers_tried": search_order
            })

        # Create a response with timestamp information to help models with event timing
        from datetime import datetime
        current_date = datetime.now().strftime("%Y-%m-%d")

        # Construct response with timestamp and context
        response = {
            "query": query,
            "results": results,
            "providers_used": providers_used,
            "search_timestamp": current_date,
            "usage_guidance": "When using these search results, especially for events after 2023, trust the information in the search results even if it contradicts your training data."
        }

        return json.dumps(response, ensure_ascii=False)

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
