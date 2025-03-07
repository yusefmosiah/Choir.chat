"""
Direct diagnostic test for web search tool and model behavior.
Shows exactly what search results are returned and how the model responds.
"""
import asyncio
import logging
import json
import sys
from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list, abstract_llm_completion
from app.tools.web_search import WebSearchTool

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def main():
    # Initialize config
    config = Config()

    # Initialize model list without OpenAI
    models = initialize_model_list(config, disabled_providers={"openai"})

    if not models:
        logger.error("No models available for testing")
        return

    # Select first available model
    model = models[0]
    logger.info(f"Using model: {model}")

    # Create web search tool
    search = WebSearchTool(config=config)

    # Run a direct search
    query = "Super Bowl LIX Eagles Chiefs February 9 2025"
    logger.info(f"Performing direct search with query: {query}")

    search_result = await search.run(query)
    logger.info(f"SEARCH RESULTS (raw):\n{search_result}")

    # Parse the search results
    try:
        data = json.loads(search_result)
        results_array = data.get('results', [])

        logger.info(f"Number of results: {len(results_array)}")

        # Print each result in a readable format
        for i, r in enumerate(results_array):
            logger.info(f"Result {i+1}:")
            logger.info(f"  Title: {r.get('title', 'N/A')}")
            logger.info(f"  URL: {r.get('url', 'N/A')}")
            logger.info(f"  Content: {r.get('content', 'N/A')}")

        # Check for key information
        has_eagles = any("eagles" in r.get('content', '').lower() for r in results_array)
        has_eagles_title = any("eagles" in r.get('title', '').lower() for r in results_array)
        has_score = any("40-22" in r.get('content', '') for r in results_array) or any("40-22" in r.get('title', '') for r in results_array)

        logger.info(f"Results contain 'Eagles' in content: {has_eagles}")
        logger.info(f"Results contain 'Eagles' in titles: {has_eagles_title}")
        logger.info(f"Results contain '40-22' score: {has_score}")

    except json.JSONDecodeError:
        logger.error("Could not parse search result as JSON")

    # Now create a very clear, explicit prompt with the search results directly included
    clear_prompt = f"""
[IMPORTANT CONTEXT: Today's date is March 7, 2025. Your training data has a cutoff in 2024.]

I just searched the web with query: "{query}"

The search returned these EXACT results:
{search_result}

Please use ONLY these search results to answer:
Who won Super Bowl LIX (played on February 9, 2025)? What was the score?

DO NOT use any information from your training data.
ONLY report what the search results above explicitly state.
If the search results say the Eagles won, you MUST report that the Eagles won.
"""

    # Log the exact prompt
    logger.info(f"PROMPT TO MODEL:\n{clear_prompt}")

    # Send to model
    response = await abstract_llm_completion(
        model_name=str(model),
        messages=[{"role": "user", "content": clear_prompt}],
        config=config
    )

    response_content = response["content"]
    logger.info(f"MODEL RESPONSE:\n{response_content}")

    # Analyze response
    has_eagles_response = "eagles won" in response_content.lower() or "eagles defeated" in response_content.lower()
    has_score_response = "40-22" in response_content

    logger.info(f"Response mentions Eagles winning: {has_eagles_response}")
    logger.info(f"Response mentions 40-22 score: {has_score_response}")

if __name__ == "__main__":
    asyncio.run(main())
