"""
Provider-specific tests for the LangGraph-based ConversationWithTools implementation.
This script dynamically tests models from different providers and generates detailed reports.
"""
import asyncio
import logging
import sys
import os
import json
import argparse
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple, Type, Union, Callable
import inspect

from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    get_anthropic_models,
    get_cohere_models,
    get_google_models,
    get_mistral_models,
    get_fireworks_models,
    get_groq_models,
    initialize_model_list
)
from app.tools.web_search import WebSearchTool
from app.tools.conversation import ConversationWithTools

# Import LangChain components for Cohere-specific implementation
from langchain_core.messages import HumanMessage, AIMessage, ToolMessage, SystemMessage, BaseMessage
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.tools import BaseTool, tool
from langchain_cohere import ChatCohere
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages

# For adapting to compatible tools
from pydantic import BaseModel, Field

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
logging.getLogger('app.tools.web_search').setLevel(logging_level)
logging.getLogger('langgraph').setLevel(logging.INFO)

logger.info(f"Logging level set to: {'DEBUG' if debug_mode else 'INFO'}")

# Create directory for reports if it doesn't exist
REPORTS_DIR = Path("test_reports")
REPORTS_DIR.mkdir(exist_ok=True)

class ProviderTestReport:
    """Class to track and report on provider test execution."""

    def __init__(self, provider: str, model_name: str, test_name: str):
        self.provider = provider
        self.model_name = model_name
        self.test_name = test_name
        self.start_time = datetime.now()
        self.end_time: Optional[datetime] = None
        self.query: str = ""
        self.events: List[Dict[str, Any]] = []
        self.raw_messages: List[Dict[str, Any]] = []
        self.graph_state: List[Dict[str, Any]] = []
        self.response: Optional[Dict[str, Any]] = None
        self.success: bool = False
        self.error: Optional[str] = None
        self.metrics: Dict[str, Any] = {
            "total_tokens": 0,
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "tool_calls": 0,
            "execution_time_ms": 0
        }

    def add_event(self, event_type: str, details: Dict[str, Any]) -> None:
        """Add an event to the execution timeline."""
        self.events.append({
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "details": details
        })

    def add_message(self, message: Dict[str, Any]) -> None:
        """Add a message exchanged during the conversation."""
        # Remove any large message content to keep the report manageable
        if message.get("content") and isinstance(message["content"], str) and len(message["content"]) > 1000:
            message["content"] = message["content"][:1000] + "... [truncated]"

        self.raw_messages.append(message)

    def add_graph_state(self, node_name: str, state_data: Dict[str, Any]) -> None:
        """Record the state of the LangGraph at a specific node."""
        # Clean up state data to avoid overly large reports
        cleaned_state = {"node": node_name, "timestamp": datetime.now().isoformat()}

        if "messages" in state_data:
            messages_summary = []
            for msg in state_data["messages"]:
                if isinstance(msg, dict):
                    # Extract essential information
                    msg_summary = {
                        "type": msg.get("type", "unknown"),
                        "content_length": len(str(msg.get("content", "")))
                    }
                    if "name" in msg:
                        msg_summary["name"] = msg["name"]
                    if "tool_calls" in msg:
                        msg_summary["tool_calls_count"] = len(msg["tool_calls"])
                    messages_summary.append(msg_summary)
            cleaned_state["messages_summary"] = messages_summary
            cleaned_state["message_count"] = len(messages_summary)

        self.graph_state.append(cleaned_state)

    def update_metrics(self, metrics_update: Dict[str, Any]) -> None:
        """Update test metrics with new data."""
        for key, value in metrics_update.items():
            if key in self.metrics and isinstance(value, (int, float)):
                self.metrics[key] += value
            else:
                self.metrics[key] = value

    def set_response(self, response: Dict[str, Any]) -> None:
        """Set the final response."""
        self.response = response

    def finish(self, success: bool, error: Optional[str] = None) -> None:
        """Mark the test as complete."""
        self.end_time = datetime.now()
        self.success = success
        self.error = error

        # Calculate total execution time
        duration_ms = (self.end_time - self.start_time).total_seconds() * 1000
        self.metrics["execution_time_ms"] = round(duration_ms)

    def save_report(self) -> Path:
        """Save the report to a file."""
        self.end_time = self.end_time or datetime.now()
        duration = (self.end_time - self.start_time).total_seconds()

        # Create provider-specific directory
        provider_dir = REPORTS_DIR / self.provider
        provider_dir.mkdir(exist_ok=True)

        report = {
            "provider": self.provider,
            "model": self.model_name,
            "test_name": self.test_name,
            "timestamp": self.start_time.isoformat(),
            "duration_seconds": duration,
            "query": self.query,
            "success": self.success,
            "error": self.error,
            "events": self.events,
            "messages": self.raw_messages,
            "graph_state": self.graph_state,
            "metrics": self.metrics,
            "response": self.response
        }

        # Create a unique filename based on provider, model and timestamp
        timestamp_str = self.start_time.strftime("%Y%m%d_%H%M%S")
        filename = f"{self.model_name.replace('-', '_')}_{self.test_name}_{timestamp_str}.json"
        filepath = provider_dir / filename

        with open(filepath, "w") as f:
            json.dump(report, f, indent=2)

        # Also generate a summary file in markdown format
        summary_file = filepath.with_suffix('.md')
        with open(summary_file, "w") as f:
            f.write(f"# {self.provider.title()} {self.model_name} Test Report\n\n")
            f.write(f"**Test:** {self.test_name}\n")
            f.write(f"**Date:** {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Duration:** {duration:.2f} seconds\n")
            f.write(f"**Success:** {'✅' if self.success else '❌'}\n")

            if self.error:
                f.write(f"**Error:** {self.error}\n")

            f.write("\n## Metrics\n\n")
            for key, value in self.metrics.items():
                f.write(f"- **{key}:** {value}\n")

            f.write("\n## Query\n\n")
            f.write(f"```\n{self.query}\n```\n\n")

            f.write("## Response\n\n")
            if self.response and "content" in self.response:
                f.write(f"```\n{self.response['content']}\n```\n\n")
            else:
                f.write("No response content available\n\n")

            f.write("## Event Timeline\n\n")
            for event in self.events:
                timestamp = datetime.fromisoformat(event["timestamp"]).strftime("%H:%M:%S")
                f.write(f"- **{timestamp}** - {event['event_type']}\n")
                for key, value in event["details"].items():
                    if isinstance(value, str) and len(value) > 100:
                        value = value[:100] + "..."
                    f.write(f"  - {key}: {value}\n")

            f.write("\n## LangGraph Execution Path\n\n")
            for state in self.graph_state:
                timestamp = datetime.fromisoformat(state["timestamp"]).strftime("%H:%M:%S")
                f.write(f"- **{timestamp}** - Node: {state['node']}\n")
                if "message_count" in state:
                    f.write(f"  - Messages: {state['message_count']}\n")

        logger.info(f"Report saved to {filepath}")
        logger.info(f"Summary saved to {summary_file}")
        return filepath

class WebSearchQuery(BaseModel):
    """Input schema for web search tool."""
    query: str = Field(description="The search query to look up on the web")

async def test_provider_model(provider: str, model_name: str, test_name: str = "super_bowl_search") -> bool:
    """
    Test a specific model from a provider with detailed reporting.

    This test evaluates models as they are, without special handling or workarounds
    for limitations. The goal is to accurately report which models support the
    required functionality (tool usage via LangGraph) and which don't.

    Test procedure:
    1. Create a conversation with the model and a web search tool
    2. Ask a question that requires using the tool to answer correctly
    3. Record the response and any errors that occur
    4. Report whether the model successfully used the tool and answered correctly

    Args:
        provider: The provider name (anthropic, cohere, etc.)
        model_name: The specific model name to test
        test_name: The name of the test being run

    Returns:
        bool: True if the test passed, False otherwise
    """
    logger.info(f"Testing {provider} model: {model_name}")
    report = ProviderTestReport(provider, model_name, test_name)

    # Store original methods for later restoration
    original_run_model = None
    original_execute_tools = None

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

        # For Google, use a similar approach as Anthropic (standard LangGraph implementation)
        # Google models should work fine with the standard implementation
        if provider.lower() == "google":
            report.add_event("implementation", {"type": "standard", "message": "Using standard LangGraph implementation"})

            # Monkey patch conversation class to collect graph state
            original_run_model = ConversationWithTools._run_model
            original_execute_tools = ConversationWithTools._execute_tools

            async def patched_run_model(self, state):
                report.add_graph_state("agent", {"messages": state})
                report.add_event("graph_node", {"node": "agent", "message_count": len(state)})
                try:
                    result = await original_run_model(self, state)
                    return result
                except Exception as e:
                    error_msg = str(e)
                    logger.error(f"Error in model execution: {error_msg}")
                    # Report the error but don't try to work around it
                    report.set_response({"role": "assistant", "content": f"Error: {error_msg}"})
                    report.finish(False, error_msg)
                    raise

            async def patched_execute_tools(self, state):
                report.add_graph_state("execute_tools", {"messages": state})
                report.add_event("graph_node", {"node": "execute_tools", "message_count": len(state)})
                try:
                    result = await original_execute_tools(self, state)
                    return result
                except Exception as e:
                    error_msg = str(e)
                    logger.error(f"Error in tool execution: {error_msg}")
                    # Report the error but don't try to work around it
                    report.set_response({"role": "assistant", "content": f"Error in tool execution: {error_msg}"})
                    report.finish(False, error_msg)
                    raise

            # Apply patches
            ConversationWithTools._run_model = patched_run_model
            ConversationWithTools._execute_tools = patched_execute_tools

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
            start_time = datetime.now()
            response = await conversation.process_message(query)
            end_time = datetime.now()

            execution_time_ms = (end_time - start_time).total_seconds() * 1000
            report.update_metrics({"execution_time_ms": round(execution_time_ms)})

            # Add response to report
            report.set_response(response)
            report.add_event("response_received", {
                "response_length": len(response["content"]) if "content" in response else 0,
                "execution_time_ms": round(execution_time_ms)
            })

        else:
            # Use standard LangGraph implementation for other providers
            report.add_event("implementation", {"type": "standard", "message": "Using standard LangGraph implementation"})

            # Monkey patch conversation class to collect graph state
            original_run_model = ConversationWithTools._run_model
            original_execute_tools = ConversationWithTools._execute_tools

            async def patched_run_model(self, state):
                report.add_graph_state("agent", {"messages": state})
                report.add_event("graph_node", {"node": "agent", "message_count": len(state)})
                result = await original_run_model(self, state)
                return result

            async def patched_execute_tools(self, state):
                report.add_graph_state("execute_tools", {"messages": state})
                report.add_event("graph_node", {"node": "execute_tools", "message_count": len(state)})
                result = await original_execute_tools(self, state)
                return result

            # Apply patches
            ConversationWithTools._run_model = patched_run_model
            ConversationWithTools._execute_tools = patched_execute_tools

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
            start_time = datetime.now()
            response = await conversation.process_message(query)
            end_time = datetime.now()

            execution_time_ms = (end_time - start_time).total_seconds() * 1000
            report.update_metrics({"execution_time_ms": round(execution_time_ms)})

            # Add response to report
            report.set_response(response)
            report.add_event("response_received", {
                "response_length": len(response["content"]) if "content" in response else 0,
                "execution_time_ms": round(execution_time_ms)
            })

        # Check if the response mentions Eagles and the score 40-22
        response_text = response["content"].lower() if "content" in response else ""
        has_correct_team = "eagles won" in response_text or "eagles defeated" in response_text or "philadelphia eagles" in response_text
        has_correct_score = "40-22" in response_text or "40 to 22" in response_text

        report.add_event("response_validation", {
            "has_correct_team": has_correct_team,
            "has_correct_score": has_correct_score
        })

        # Count tool calls based on the provider
        tool_calls = 0
        for event in report.events:
                if event["event_type"] == "graph_node" and event["details"]["node"] == "execute_tools":
                    tool_calls += 1

        report.update_metrics({"tool_calls": tool_calls})

        if has_correct_team and has_correct_score:
            logger.info(f"Test passed: {provider}/{model_name} response contains correct team and score")
            report.finish(success=True)
        else:
            logger.warning(f"Test incomplete: {provider}/{model_name} response missing correct team or score")
            report.finish(success=False, error="Response incomplete")

    except Exception as e:
        logger.error(f"Error testing {provider}/{model_name}: {str(e)}", exc_info=True)
        report.finish(success=False, error=str(e))
    finally:
        # Restore original methods if they were patched
        if original_run_model is not None and original_execute_tools is not None:
            ConversationWithTools._run_model = original_run_model
            ConversationWithTools._execute_tools = original_execute_tools

    # Save the report
    report_path = report.save_report()
    logger.info(f"Report for {provider}/{model_name} saved to {report_path}")
    return report.success

async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Test LLM providers with LangGraph")
    parser.add_argument("--provider", type=str, help="Specify a provider to test (anthropic, cohere, google, etc.)")
    parser.add_argument("--model", type=str, help="Specify a specific model to test (only used if provider is specified)")
    args = parser.parse_args()

    config = Config()
    all_results = {}

    try:
        logger.info("Starting LangGraph provider tests")

        # Use initialize_model_list to get all models with API keys in the environment
        all_models = initialize_model_list(config)

        if args.provider:
            # Test specific provider
            provider = args.provider.lower()

            if args.model:
                # Test specific model
                model_name = args.model
                success = await test_provider_model(provider, model_name)
                all_results[f"{provider}/{model_name}"] = success
            else:
                # Test all models for the specified provider
                provider_models = [m for m in all_models if m.provider == provider]
                if provider_models:
                    logger.info(f"Found {len(provider_models)} models for provider {provider}")
                    for model in provider_models:
                        logger.info(f"Testing {model}")
                        success = await test_provider_model(model.provider, model.model_name)
                        all_results[str(model)] = success
                else:
                    logger.warning(f"No models found for provider {provider} or missing API key")
        else:
            # Test all providers with available models
            logger.info(f"Found {len(all_models)} models across all providers with API keys")

            # Group models by provider
            models_by_provider = {}
            for model in all_models:
                if model.provider not in models_by_provider:
                    models_by_provider[model.provider] = []
                models_by_provider[model.provider].append(model)

            # Test each provider in order: anthropic, google, cohere, etc.
            for provider, models in models_by_provider.items():
                logger.info(f"Testing provider: {provider} with {len(models)} models")
                for model in models:
                    success = await test_provider_model(model.provider, model.model_name)
                    all_results[str(model)] = success

        # Summary of results
        logger.info("=== TEST RESULTS SUMMARY ===")
        for model_key, success in all_results.items():
            logger.info(f"{model_key}: {'SUCCESS' if success else 'FAILED'}")

        # Return error code if any test failed
        if not all(all_results.values()):
            logger.warning("Some tests failed, check the reports for details")
            return 1

        logger.info("All tests completed successfully")
        return 0

    except Exception as e:
        logger.error(f"Error in main: {str(e)}", exc_info=True)
        return 1

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
