"""
Provider-specific tests for the LangGraph-based ConversationWithTools implementation.
This script tests models from different providers and generates detailed execution reports.
"""
import asyncio
import logging
import sys
import os
import json
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional

from app.config import Config
from app.langchain_utils import ModelConfig
from app.tools.web_search import WebSearchTool
from app.tools.conversation import ConversationWithTools

# Configure logging
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
logging.getLogger('langgraph').setLevel(logging.INFO)

logger.info(f"Logging level set to: {'DEBUG' if debug_mode else 'INFO'}")

# Create directory for reports if it doesn't exist
REPORTS_DIR = Path("test_reports")
REPORTS_DIR.mkdir(exist_ok=True)

class ProviderTestReport:
    """Class to track and report on provider test execution."""

    def __init__(self, provider: str, model_name: str):
        self.provider = provider
        self.model_name = model_name
        self.start_time = datetime.now()
        self.end_time: Optional[datetime] = None
        self.query: str = ""
        self.events: List[Dict[str, Any]] = []
        self.response: Optional[Dict[str, Any]] = None
        self.success: bool = False
        self.error: Optional[str] = None

    def add_event(self, event_type: str, details: Dict[str, Any]) -> None:
        """Add an event to the execution timeline."""
        self.events.append({
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "details": details
        })

    def set_response(self, response: Dict[str, Any]) -> None:
        """Set the final response."""
        self.response = response

    def finish(self, success: bool, error: Optional[str] = None) -> None:
        """Mark the test as complete."""
        self.end_time = datetime.now()
        self.success = success
        self.error = error

    def save_report(self) -> Path:
        """Save the report to a file."""
        self.end_time = self.end_time or datetime.now()
        duration = (self.end_time - self.start_time).total_seconds()

        report = {
            "provider": self.provider,
            "model": self.model_name,
            "timestamp": self.start_time.isoformat(),
            "duration_seconds": duration,
            "query": self.query,
            "success": self.success,
            "error": self.error,
            "events": self.events,
            "response": self.response
        }

        # Create a unique filename based on provider, model, and timestamp
        timestamp_str = self.start_time.strftime("%Y%m%d_%H%M%S")
        filename = f"{self.provider}_{self.model_name.replace('-', '_')}_{timestamp_str}.json"
        filepath = REPORTS_DIR / filename

        with open(filepath, "w") as f:
            json.dump(report, f, indent=2)

        logger.info(f"Report saved to {filepath}")
        return filepath

async def test_anthropic_provider():
    """Test the Anthropic provider with Claude 3.5 Haiku model."""
    provider = "anthropic"
    model_name = "claude-3-5-haiku-latest"

    logger.info(f"Testing provider: {provider} with model: {model_name}")
    report = ProviderTestReport(provider, model_name)

    try:
        # Initialize config
        config = Config()
        report.add_event("initialization", {"message": "Configuration initialized"})

        # Create model configuration
        model = ModelConfig(provider=provider, model_name=model_name)
        report.add_event("model_setup", {"provider": provider, "model": model_name})

        # Create web search tool
        search = WebSearchTool(config=config)
        report.add_event("tool_creation", {"tool_name": search.name})

        # Create conversation with this model and the tool
        conversation = ConversationWithTools(
            models=[model],
            tools=[search],
            config=config
        )
        report.add_event("conversation_creation", {"tools": [search.name]})

        # Test query
        query = "Who won Super Bowl LIX on February 9, 2025? Include the final score."
        report.query = query
        report.add_event("query_submission", {"query": query})

        # Process the query
        logger.info(f"Processing query with {provider}/{model_name}: {query}")
        response = await conversation.process_message(query)

        # Add response to report
        report.set_response(response)
        report.add_event("response_received", {
            "response_length": len(response["content"]) if "content" in response else 0
        })

        # Check if the response mentions Eagles and the score 40-22
        response_text = response["content"].lower() if "content" in response else ""
        has_correct_team = "eagles won" in response_text or "eagles defeated" in response_text or "philadelphia eagles" in response_text
        has_correct_score = "40-22" in response_text or "40 to 22" in response_text

        report.add_event("response_validation", {
            "has_correct_team": has_correct_team,
            "has_correct_score": has_correct_score
        })

        if has_correct_team and has_correct_score:
            logger.info("Test passed: Response contains correct team and score")
            report.finish(success=True)
        else:
            logger.warning("Test incomplete: Response missing correct team or score")
            report.finish(success=False, error="Response incomplete")

    except Exception as e:
        logger.error(f"Error testing {provider}/{model_name}: {str(e)}", exc_info=True)
        report.finish(success=False, error=str(e))

    # Save the report
    report_path = report.save_report()
    logger.info(f"Report for {provider}/{model_name} saved to {report_path}")
    return report.success

async def test_cohere_provider():
    """Test the Cohere provider."""
    provider = "cohere"
    model_name = "command-r-plus"  # Using Command R+

    logger.info(f"Testing provider: {provider} with model: {model_name}")
    report = ProviderTestReport(provider, model_name)

    try:
        # Initialize config
        config = Config()
        report.add_event("initialization", {"message": "Configuration initialized"})

        # Create model configuration
        model = ModelConfig(provider=provider, model_name=model_name)
        report.add_event("model_setup", {"provider": provider, "model": model_name})

        # Create web search tool
        search = WebSearchTool(config=config)
        report.add_event("tool_creation", {"tool_name": search.name})

        # Create conversation with this model and the tool
        conversation = ConversationWithTools(
            models=[model],
            tools=[search],
            config=config
        )
        report.add_event("conversation_creation", {"tools": [search.name]})

        # Test query
        query = "Who won Super Bowl LIX on February 9, 2025? Include the final score."
        report.query = query
        report.add_event("query_submission", {"query": query})

        # Process the query
        logger.info(f"Processing query with {provider}/{model_name}: {query}")
        response = await conversation.process_message(query)

        # Add response to report
        report.set_response(response)
        report.add_event("response_received", {
            "response_length": len(response["content"]) if "content" in response else 0
        })

        # Check if the response mentions Eagles and the score 40-22
        response_text = response["content"].lower() if "content" in response else ""
        has_correct_team = "eagles won" in response_text or "eagles defeated" in response_text or "philadelphia eagles" in response_text
        has_correct_score = "40-22" in response_text or "40 to 22" in response_text

        report.add_event("response_validation", {
            "has_correct_team": has_correct_team,
            "has_correct_score": has_correct_score
        })

        if has_correct_team and has_correct_score:
            logger.info("Test passed: Response contains correct team and score")
            report.finish(success=True)
        else:
            logger.warning("Test incomplete: Response missing correct team or score")
            report.finish(success=False, error="Response incomplete")

    except Exception as e:
        logger.error(f"Error testing {provider}/{model_name}: {str(e)}", exc_info=True)
        report.finish(success=False, error=str(e))

    # Save the report
    report_path = report.save_report()
    logger.info(f"Report for {provider}/{model_name} saved to {report_path}")
    return report.success

async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Test providers with LangGraph")
    parser.add_argument("--provider", type=str, help="Specify a provider to test (anthropic, cohere)")
    args = parser.parse_args()

    results = {}
    try:
        logger.info("Starting provider LangGraph tests")

        if args.provider:
            # Test specific provider
            if args.provider.lower() == "anthropic":
                results["anthropic"] = await test_anthropic_provider()
            elif args.provider.lower() == "cohere":
                results["cohere"] = await test_cohere_provider()
            else:
                logger.error(f"Unknown provider: {args.provider}")
                return 1
        else:
            # Test all providers
            logger.info("Testing Anthropic provider")
            results["anthropic"] = await test_anthropic_provider()

            logger.info("Testing Cohere provider")
            results["cohere"] = await test_cohere_provider()

        # Summary of results
        logger.info("=== TEST RESULTS SUMMARY ===")
        for provider, success in results.items():
            logger.info(f"{provider}: {'SUCCESS' if success else 'FAILED'}")

        # Return error code if any test failed
        if not all(results.values()):
            logger.warning("Some tests failed, check the reports for details")
            return 1

        logger.info("All tests completed successfully")
        return 0

    except Exception as e:
        logger.error(f"Error in main: {str(e)}", exc_info=True)
        return 1

if __name__ == "__main__":
    import argparse
    sys.exit(asyncio.run(main()))
