"""
Anthropic Provider-specific LangGraph test with detailed execution reporting.
This script tests Claude models and generates comprehensive reports about execution flow.
"""
import asyncio
import logging
import sys
import os
import json
import argparse
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
logging.getLogger('app.tools.web_search').setLevel(logging_level)
logging.getLogger('langgraph').setLevel(logging.INFO)

logger.info(f"Logging level set to: {'DEBUG' if debug_mode else 'INFO'}")

# Create directory for reports if it doesn't exist
REPORTS_DIR = Path("test_reports/anthropic")
REPORTS_DIR.mkdir(exist_ok=True, parents=True)

class AnthropicTestReport:
    """Class to track and report on Anthropic model test execution."""

    def __init__(self, model_name: str, test_name: str):
        self.provider = "anthropic"
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

        # Create a unique filename based on model and timestamp
        timestamp_str = self.start_time.strftime("%Y%m%d_%H%M%S")
        filename = f"{self.model_name.replace('-', '_')}_{self.test_name}_{timestamp_str}.json"
        filepath = REPORTS_DIR / filename

        with open(filepath, "w") as f:
            json.dump(report, f, indent=2)

        # Also generate a summary file in markdown format
        summary_file = filepath.with_suffix('.md')
        with open(summary_file, "w") as f:
            f.write(f"# Anthropic {self.model_name} Test Report\n\n")
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

async def test_claude_haiku():
    """Test Claude 3.5 Haiku with detailed reporting."""
    model_name = "claude-3-5-haiku-latest"
    test_name = "super_bowl_search"

    logger.info(f"Testing Anthropic model: {model_name}")
    report = AnthropicTestReport(model_name, test_name)

    try:
        # Initialize config
        config = Config()
        report.add_event("initialization", {"message": "Configuration initialized"})

        # Create model configuration
        model = ModelConfig(provider="anthropic", model_name=model_name)
        report.add_event("model_setup", {"model": model_name})

        # Create web search tool
        search = WebSearchTool(config=config)
        report.add_event("tool_creation", {"tool_name": search.name})

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
        logger.info(f"Processing query with {model_name}: {query}")
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

        # Count tool calls
        tool_calls = 0
        for event in report.events:
            if event["event_type"] == "graph_node" and event["details"]["node"] == "execute_tools":
                tool_calls += 1

        report.update_metrics({"tool_calls": tool_calls})

        if has_correct_team and has_correct_score:
            logger.info("Test passed: Response contains correct team and score")
            report.finish(success=True)
        else:
            logger.warning("Test incomplete: Response missing correct team or score")
            report.finish(success=False, error="Response incomplete")

        # Restore original methods
        ConversationWithTools._run_model = original_run_model
        ConversationWithTools._execute_tools = original_execute_tools

    except Exception as e:
        logger.error(f"Error testing {model_name}: {str(e)}", exc_info=True)
        report.finish(success=False, error=str(e))

    # Save the report
    report_path = report.save_report()
    logger.info(f"Report for Anthropic {model_name} saved to {report_path}")
    return report.success

async def test_claude_opus():
    """Test Claude 3 Opus with detailed reporting."""
    model_name = "claude-3-opus-20240229"
    test_name = "super_bowl_search"

    logger.info(f"Testing Anthropic model: {model_name}")
    report = AnthropicTestReport(model_name, test_name)

    try:
        # Initialize config
        config = Config()
        report.add_event("initialization", {"message": "Configuration initialized"})

        # Create model configuration
        model = ModelConfig(provider="anthropic", model_name=model_name)
        report.add_event("model_setup", {"model": model_name})

        # Create web search tool
        search = WebSearchTool(config=config)
        report.add_event("tool_creation", {"tool_name": search.name})

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
        logger.info(f"Processing query with {model_name}: {query}")
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

        # Count tool calls
        tool_calls = 0
        for event in report.events:
            if event["event_type"] == "graph_node" and event["details"]["node"] == "execute_tools":
                tool_calls += 1

        report.update_metrics({"tool_calls": tool_calls})

        if has_correct_team and has_correct_score:
            logger.info("Test passed: Response contains correct team and score")
            report.finish(success=True)
        else:
            logger.warning("Test incomplete: Response missing correct team or score")
            report.finish(success=False, error="Response incomplete")

        # Restore original methods
        ConversationWithTools._run_model = original_run_model
        ConversationWithTools._execute_tools = original_execute_tools

    except Exception as e:
        logger.error(f"Error testing {model_name}: {str(e)}", exc_info=True)
        report.finish(success=False, error=str(e))

    # Save the report
    report_path = report.save_report()
    logger.info(f"Report for Anthropic {model_name} saved to {report_path}")
    return report.success

async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Test Anthropic models with LangGraph")
    parser.add_argument("--model", type=str, help="Specify a model to test (haiku, opus)")
    args = parser.parse_args()

    results = {}
    try:
        logger.info("Starting Anthropic LangGraph tests")

        if args.model:
            # Test specific model
            if args.model.lower() == "haiku":
                results["haiku"] = await test_claude_haiku()
            elif args.model.lower() == "opus":
                results["opus"] = await test_claude_opus()
            else:
                logger.error(f"Unknown model: {args.model}")
                return 1
        else:
            # Test all Anthropic models
            logger.info("Testing Claude 3.5 Haiku")
            results["haiku"] = await test_claude_haiku()

            logger.info("Testing Claude 3 Opus")
            results["opus"] = await test_claude_opus()

        # Summary of results
        logger.info("=== ANTHROPIC TEST RESULTS SUMMARY ===")
        for model, success in results.items():
            logger.info(f"{model}: {'SUCCESS' if success else 'FAILED'}")

        # Return error code if any test failed
        if not all(results.values()):
            logger.warning("Some tests failed, check the reports for details")
            return 1

        logger.info("All Anthropic tests completed successfully")
        return 0

    except Exception as e:
        logger.error(f"Error in main: {str(e)}", exc_info=True)
        return 1

if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
