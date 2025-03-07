"""
Simplified test for Claude 3.5 Haiku model with the web search tool using LangGraph.
Tests a single query to verify the model's ability to handle tool calls properly.
"""
import asyncio
import logging
import json
import sys
import os
from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list
from app.tools.web_search import WebSearchTool
from app.tools.conversation import ConversationWithTools

# Configure logging
# Check if DEBUG environment variable is set
debug_mode = os.environ.get('DEBUG', 'false').lower() in ('true', '1', 't')
logging_level = logging.DEBUG if debug_mode else logging.INFO

logging.basicConfig(
    level=logging_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Set logging levels for specific modules
logging.getLogger('app.tools.conversation').setLevel(logging_level)
logging.getLogger('app.langchain_utils').setLevel(logging_level)
logging.getLogger('langchain_core').setLevel(logging.INFO)  # Keep LangChain logs at INFO level
logging.getLogger('langgraph').setLevel(logging.INFO)  # Set LangGraph logs to INFO

logger.info(f"Logging level set to: {'DEBUG' if debug_mode else 'INFO'}")

async def test_haiku_web_search():
    """Test Claude 3.5 Haiku with web search tool using LangGraph."""
    # Initialize config
    config = Config()

    # Create model configuration for Claude 3.5 Haiku
    model = ModelConfig(provider="anthropic", model_name="claude-3-5-haiku-latest")
    logger.info(f"Testing model: {model}")

    # Create web search tool
    search = WebSearchTool(config=config)
    logger.info(f"Created web search tool: {search.name}")

    # Create conversation with this model and the tool
    logger.info("Initializing conversation with tools using LangGraph")
    conversation = ConversationWithTools(
        models=[model],
        tools=[search],
        config=config
    )

    # Test query
    query = "Who won Super Bowl LIX on February 9, 2025? Include the final score."
    logger.info(f"Testing query: {query}")

    # Process the query
    logger.info("Sending query to conversation graph")
    response = await conversation.process_message(query)

    logger.info("RESPONSE RECEIVED")
    logger.info("===== RESPONSE CONTENT BEGIN =====")
    logger.info(response["content"])
    logger.info("===== RESPONSE CONTENT END =====")

    # Check if the response mentions Eagles and the score 40-22
    response_text = response["content"].lower()
    has_correct_team = "eagles won" in response_text or "eagles defeated" in response_text or "philadelphia eagles won" in response_text
    has_correct_score = "40-22" in response_text or "40 to 22" in response_text

    logger.info(f"Response contains correct team (Eagles): {has_correct_team}")
    logger.info(f"Response contains correct score (40-22): {has_correct_score}")

    return has_correct_team, has_correct_score

async def main():
    """Main entry point."""
    try:
        logger.info("Starting haiku_search_test with LangGraph")
        await test_haiku_web_search()
        logger.info("Test completed successfully")
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
