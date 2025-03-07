"""
Tavily search tool implementation.
"""
import os
import logging
import asyncio
import json
from typing import Dict, Any, List, Optional, Union

# Conditional import since langchain_community might not be installed
try:
    from langchain_community.tools.tavily_search import TavilySearchResults as LCTavilySearch
except ImportError:
    LCTavilySearch = None

from .base import BaseTool
from app.config import Config

logger = logging.getLogger(__name__)

class TavilySearchTool(BaseTool):
    """Tool for performing web searches using Tavily.

    This tool leverages the Tavily API to perform web searches and extract relevant information.
    """
    name = "tavily_search"
    description = "Search the web for current information. Input should be a search query."

    def __init__(
        self,
        config: Config = None,
        tavily_api_key: Optional[str] = None,
        include_raw_content: bool = True,
        include_images: bool = False,
        k: int = 40,
        max_results_length: int = 2000
    ):
        """Initialize the Tavily search tool.

        Args:
            config: Application configuration
            tavily_api_key: Optional API key (overrides config)
            include_raw_content: Whether to include raw content in results
            include_images: Whether to include image links
            k: Number of results to return
            max_results_length: Maximum length of formatted results
        """
        super().__init__()

        self.config = config or Config()

        # Get API key from config, env var, or parameter
        self.api_key = tavily_api_key or os.environ.get("TAVILY_API_KEY")

        # Try to load from a path if defined
        if not self.api_key and os.environ.get("TAVILY_API_KEY_PATH"):
            try:
                with open(os.environ.get("TAVILY_API_KEY_PATH"), "r") as f:
                    self.api_key = f.read().strip()
            except Exception as e:
                logger.warning(f"Failed to load Tavily API key from path: {e}")

        self.include_raw_content = include_raw_content
        self.include_images = include_images
        self.k = k
        self.max_results_length = max_results_length

        # Initialize the langchain tool
        if LCTavilySearch is None:
            logger.warning("langchain_community not installed, Tavily search tool will not work")
            self._langchain_tool = None
        elif not self.api_key:
            logger.warning("Tavily API key not found, Tavily search tool will not work")
            self._langchain_tool = None
        else:
            self._langchain_tool = LCTavilySearch(
                tavily_api_key=self.api_key,
                k=self.k,
                include_raw_content=self.include_raw_content,
                include_images=self.include_images
            )

    def _format_results(self, results: List[Dict[str, str]]) -> str:
        """Format search results into a readable string.

        Args:
            results: List of search result dictionaries

        Returns:
            Formatted search results as a string
        """
        if not results:
            return "No results found."

        formatted_results = []

        for i, result in enumerate(results, 1):
            title = result.get("title", "No title")
            content = result.get("content", "No content")
            url = result.get("url", "No URL")

            formatted_result = f"Result {i}:\n"
            formatted_result += f"Title: {title}\n"
            formatted_result += f"Content: {content}\n"
            formatted_result += f"Source: {url}\n"

            formatted_results.append(formatted_result)

        # Join results and limit to max length
        all_results = "\n\n".join(formatted_results)
        if len(all_results) > self.max_results_length:
            all_results = all_results[:self.max_results_length] + "...(truncated)"

        return all_results

    async def run(self, query: str) -> str:
        """Execute the Tavily search.

        Args:
            query: The search query

        Returns:
            Formatted search results
        """
        if not self._langchain_tool:
            return "Error: Tavily search tool not properly configured."

        try:
            # Run in executor since the LangChain tool is synchronous
            loop = asyncio.get_event_loop()

            # Add retry logic for better error handling
            max_retries = 2
            backoff_factor = 2
            retry_count = 0

            while retry_count <= max_retries:
                try:
                    raw_results = await loop.run_in_executor(
                        None,
                        lambda: self._langchain_tool.invoke({"query": query})
                    )

                    # Log raw response for debugging
                    logger.debug(f"Raw Tavily response type: {type(raw_results)}")
                    if isinstance(raw_results, str):
                        logger.debug(f"Raw Tavily response prefix: {raw_results[:100]}")

                    # Response validation
                    if not raw_results:
                        raise ValueError("Empty response from Tavily")

                    # Break the retry loop on success
                    break

                except (ValueError, json.JSONDecodeError) as e:
                    logger.warning(f"Tavily search attempt {retry_count+1} failed: {str(e)}")
                    if retry_count == max_retries:
                        raise
                    retry_count += 1
                    # Exponential backoff
                    await asyncio.sleep(backoff_factor ** retry_count)

            # Format the results
            if isinstance(raw_results, list):
                return self._format_results(raw_results)
            elif isinstance(raw_results, str):
                return raw_results
            else:
                # Handle the case where results are in a different format
                return f"Search results for '{query}':\n\n{str(raw_results)}"

        except Exception as e:
            logger.error(f"Error in Tavily search: {str(e)}")
            return f"Error executing search: {str(e)}"
