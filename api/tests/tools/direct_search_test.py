"""
Direct test of the web search tool.
"""
import asyncio
import logging
import json
from app.config import Config
from app.tools.web_search import WebSearchTool

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def main():
    config = Config()
    search = WebSearchTool(config=config)

    # Test Super Bowl LIX query
    query = 'Who won Super Bowl LIX (59) February 9 2025 Eagles Chiefs 40-22'
    logger.info(f"Searching for: {query}")

    result = await search.run(query)
    logger.info(f"Raw search result: {result}")

    # Check for key information
    has_eagles = 'eagles' in result.lower()
    has_40_22 = '40-22' in result

    logger.info(f"Contains Eagles: {has_eagles}")
    logger.info(f"Contains 40-22: {has_40_22}")

    # Try to parse JSON
    try:
        data = json.loads(result)
        results_array = data.get('results', [])
        logger.info(f"Number of results: {len(results_array)}")

        # Print each result
        for i, r in enumerate(results_array):
            logger.info(f"Result {i+1}:")
            logger.info(f"  Title: {r.get('title', 'N/A')}")
            logger.info(f"  URL: {r.get('url', 'N/A')}")
            logger.info(f"  Content: {r.get('content', 'N/A')}")

        # Check which providers were used
        providers = data.get('providers_used', [])
        logger.info(f"Providers used: {providers}")

    except json.JSONDecodeError:
        logger.error("Could not parse search result as JSON")

if __name__ == "__main__":
    asyncio.run(main())
