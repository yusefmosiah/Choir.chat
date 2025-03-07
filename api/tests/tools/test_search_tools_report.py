"""
Comprehensive test for search tools across all available models.
Generates a human-readable report of prompts, search results, and model responses.
"""
import asyncio
import logging
import json
import os
import time
import argparse
import sys
from datetime import datetime
from typing import Dict, Any, List, Union, Optional
from pathlib import Path

import pytest
from tqdm import tqdm

from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list
from app.tools.web_search import WebSearchTool
from app.tools.tavily_search import TavilySearchTool
from app.tools.duckduckgo_search import DuckDuckGoSearchTool
from app.tools.brave_search import BraveSearchTool
from app.tools.conversation import ConversationWithTools

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SearchToolsEvaluator:
    """Evaluates search tools across all available models and generates a report."""

    def __init__(self, config: Config = None):
        """Initialize the evaluator with configuration."""
        self.config = config or Config()
        self.reports_dir = Path(__file__).parent.parent.parent.parent / "reports"
        self.reports_dir.mkdir(exist_ok=True)

        # Create a timestamp to use for the report filename
        self.timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.report_path = self.reports_dir / f"search_tools_report_{self.timestamp}.md"

        # Initialize models (excluding OpenAI)
        self.models = initialize_model_list(self.config, disabled_providers={"openai"})

        # Initialize search tools
        self.web_search_tool = WebSearchTool(config=self.config)

        # Initialize individual search providers for direct testing
        try:
            self.tavily_tool = TavilySearchTool(config=self.config)
            self.has_tavily = True
        except Exception as e:
            logger.warning(f"Tavily search tool initialization failed: {e}")
            self.has_tavily = False

        self.duckduckgo_tool = DuckDuckGoSearchTool(config=self.config)

        try:
            self.brave_tool = BraveSearchTool(config=self.config)
            self.has_brave = True
        except Exception as e:
            logger.warning(f"Brave search tool initialization failed: {e}")
            self.has_brave = False

        # Test queries covering different time periods
        self.test_queries = [
            {
                "name": "super_bowl_lviii_2024",
                "query": "Who won Super Bowl LVIII in February 2024? Include the final score.",
                "description": "Recent event within possible training data (Chiefs beat 49ers 25-22)"
            },
            {
                "name": "super_bowl_lix_2025",
                "query": "Who won Super Bowl LIX on February 9, 2025? Include the final score.",
                "description": "Future event relative to training data (Eagles beat Chiefs 40-22)"
            },
            {
                "name": "current_us_president",
                "query": "Who is the current President of the United States as of today?",
                "description": "Current factual information that may change after training"
            },
            {
                "name": "recent_scientific_breakthrough",
                "query": "What was the most significant scientific breakthrough in the past 6 months?",
                "description": "Recent developments requiring up-to-date information"
            }
        ]

        # Report contents
        self.report_content = []

    async def evaluate_all(self):
        """Run the evaluation across all models and tools, generating a report."""
        # Start the report
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.report_content.append(f"# Search Tools Evaluation Report\n\nGenerated on: {timestamp}\n")

        # Log available models
        self.report_content.append(f"## Available Models ({len(self.models)})\n")
        for i, model in enumerate(self.models):
            self.report_content.append(f"{i+1}. `{model}`\n")
        self.report_content.append("\n")

        # Log available search tools
        self.report_content.append("## Available Search Tools\n")
        self.report_content.append("1. Web Search Tool (with fallback providers)\n")
        if self.has_tavily:
            self.report_content.append("2. Tavily Search Tool\n")
        if self.has_brave:
            self.report_content.append("3. Brave Search Tool\n")
        self.report_content.append("4. DuckDuckGo Search Tool\n\n")

        # Run tests for each model with the combined WebSearchTool
        self.report_content.append("## Evaluation Results\n")

        for model in tqdm(self.models, desc="Evaluating models"):
            model_name = str(model)
            self.report_content.append(f"### Model: {model_name}\n")

            # Test with WebSearchTool (combined with fallback)
            await self._evaluate_tool_with_model(model, self.web_search_tool, "Combined Web Search Tool")

            # Add some spacing in the report
            self.report_content.append("\n---\n")

        # Write the report
        with open(self.report_path, "w") as f:
            f.write("\n".join(self.report_content))

        logger.info(f"Report saved to: {self.report_path}")

    async def _evaluate_tool_with_model(self, model: ModelConfig, tool: Any, tool_name: str):
        """Evaluate a specific tool with a specific model."""
        self.report_content.append(f"#### Tool: {tool_name}\n")

        # Create a conversation with this tool
        conversation = ConversationWithTools(
            models=[model],
            tools=[tool],
            config=self.config
        )

        # Log system prompt
        self.report_content.append("**System Prompt:**\n")
        self.report_content.append(f"```\n{conversation.system_prompt}\n```\n")

        # Run each test query
        for test in tqdm(self.test_queries, desc=f"Testing {tool_name} with {model}", leave=False):
            self.report_content.append(f"##### Query: {test['name']}\n")
            self.report_content.append(f"**Description:** {test['description']}\n")
            self.report_content.append(f"**Prompt:** {test['query']}\n")

            # Capture start time
            start_time = time.time()

            # Process the message
            try:
                result = await conversation.process_message(test['query'])

                # Calculate elapsed time
                elapsed_time = time.time() - start_time

                # Extract the search query and results if available
                response_content = result.get('content', 'No response')
                search_query = None
                search_results = None

                # Look for tool usage
                if "[web_search] input:" in response_content:
                    # Extract search query
                    search_query_start = response_content.find("[web_search] input:") + len("[web_search] input:")
                    search_query_end = response_content.find("\n", search_query_start)
                    if search_query_end == -1:
                        search_query_end = len(response_content)
                    search_query = response_content[search_query_start:search_query_end].strip()

                    # Extract search results if present
                    if "[web_search] output:" in response_content:
                        search_results_start = response_content.find("[web_search] output:") + len("[web_search] output:")
                        search_results_end = response_content.find("\n\n", search_results_start)
                        if search_results_end == -1:
                            search_results_end = len(response_content)
                        search_results = response_content[search_results_start:search_results_end].strip()

                # Log the search query if found
                if search_query:
                    self.report_content.append(f"**Search Query:** {search_query}\n")

                # Log the search results if found (truncated for readability)
                if search_results:
                    # Try to parse and pretty-print if it's JSON
                    try:
                        search_results_obj = json.loads(search_results)
                        # Include only relevant parts for readability
                        readable_results = {
                            "query": search_results_obj.get("query", ""),
                            "results_count": len(search_results_obj.get("results", [])),
                            "sample_results": search_results_obj.get("results", [])[:5],  # Show first 5 results
                            "providers_used": search_results_obj.get("providers_used", [])
                        }
                        self.report_content.append("**Search Results (sample):**\n")

                        # Add a note if we're only showing a subset of results
                        total_results = len(search_results_obj.get("results", []))
                        if total_results > 5:
                            self.report_content.append(f"*Note: Showing 5 of {total_results} total results*\n")

                        self.report_content.append(f"```json\n{json.dumps(readable_results, indent=2)}\n```\n")
                    except:
                        # If not valid JSON, show truncated raw text
                        self.report_content.append("**Search Results (truncated):**\n")
                        self.report_content.append(f"```\n{search_results[:500]}...\n```\n")

                # Log the model's final answer
                self.report_content.append("**Model Response:**\n")

                # If there's a clear division between tool output and model's final answer, show just the final answer
                final_answer = response_content
                if "\n\n" in response_content and "[web_search] output:" in response_content:
                    parts = response_content.split("\n\n")
                    for i, part in enumerate(parts):
                        if "[web_search] output:" in part and i+1 < len(parts):
                            final_answer = "\n\n".join(parts[i+1:])
                            break

                self.report_content.append(f"```\n{final_answer}\n```\n")

                # Performance metrics
                self.report_content.append(f"**Time:** {elapsed_time:.2f} seconds\n")

                # Basic accuracy metrics for specific test cases
                has_correct_info = self._check_answer_accuracy(test['name'], response_content)
                self.report_content.append(f"**Contains Expected Information:** {has_correct_info}\n")

            except Exception as e:
                self.report_content.append(f"**ERROR:** {str(e)}\n")

            # Add spacing between test cases
            self.report_content.append("\n")

    def _check_answer_accuracy(self, test_name: str, response: str) -> bool:
        """Check if the response contains expected information for known test cases."""
        response = response.lower()

        if test_name == "super_bowl_lviii_2024":
            # Check for Chiefs win and 25-22 score
            has_chiefs = "chiefs won" in response or "chiefs defeated" in response
            has_score = "25-22" in response or "25 to 22" in response
            return has_chiefs and has_score

        elif test_name == "super_bowl_lix_2025":
            # Check for Eagles win and 40-22 score
            has_eagles = "eagles won" in response or "eagles defeated" in response
            has_score = "40-22" in response or "40 to 22" in response
            return has_eagles and has_score

        elif test_name == "current_us_president":
            # This depends on current time, adapt as needed
            return "biden" in response

        # For other queries, we can't easily validate automatically
        return None


@pytest.mark.asyncio
async def test_generate_search_tools_report():
    """Generate a comprehensive report on search tools performance."""
    evaluator = SearchToolsEvaluator()
    await evaluator.evaluate_all()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate search tools evaluation report")
    parser.add_argument("--provider", "-p", type=str, help="Filter models by provider (e.g., 'anthropic')")
    parser.add_argument("--output", "-o", type=str, help="Output file path for the report")
    args = parser.parse_args()

    evaluator = SearchToolsEvaluator()

    # Filter models by provider if specified
    if args.provider:
        provider = args.provider.lower()
        evaluator.models = [model for model in evaluator.models if model.provider.lower() == provider]
        if not evaluator.models:
            print(f"No models found for provider: {provider}")
            sys.exit(1)

        print(f"Found {len(evaluator.models)} models for {provider}: {evaluator.models}")

    # Set custom report path if specified
    if args.output:
        evaluator.report_path = Path(args.output)

    asyncio.run(evaluator.evaluate_all())
