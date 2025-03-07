"""
Test script to verify multi-model tool conversation capabilities using LangGraph.
This tests the ability of different tool-compatible models to use tools in a conversation and
maintain context across model transitions.

First test: 2-turn conversations between each pair of tool-compatible models,
testing if they can successfully use search tools and maintain conversation context.
"""

import asyncio
import logging
import itertools
import random
import json
import string
import time
from datetime import datetime
from typing import Dict, Any, List, Optional, TypedDict, Literal, Tuple, Type
from dataclasses import dataclass, field
import os
import sys
from enum import Enum

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langchain_core.tools import BaseTool, tool
from pydantic import BaseModel

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.config import Config
from app.langchain_utils import (
    abstract_llm_completion,
    abstract_llm_completion_stream,
    ModelConfig,
    initialize_tool_compatible_model_list
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Set up langgraph imports
try:
    from langgraph.graph import END, StateGraph, START
except ImportError:
    logger.error("langgraph not installed. Please install with `pip install langgraph`")
    sys.exit(1)

# Create a dictionary mapping model names to colors for visual output
MODEL_COLORS = {
    "openai": "\033[32m",      # Green
    "anthropic": "\033[36m",   # Cyan
    "google": "\033[35m",      # Magenta
    "mistral": "\033[34m",     # Blue
    "groq": "\033[33m",        # Yellow
}
RESET_COLOR = "\033[0m"        # Reset to default color


class SearchResult(TypedDict):
    """Structure for a single search result."""
    title: str
    url: str
    snippet: str


class SearchTool(BaseTool):
    """Mock search tool for testing tool usage."""

    name: str = "web_search"
    description: str = "Search the web for real-time information about any topic."
    search_responses: Dict[str, List[Dict[str, str]]] = None

    def __init__(self):
        """Initialize with mock search responses for testing."""
        super().__init__()
        # Mock responses for specific queries
        self.search_responses = {
            "super bowl 2025": [
                {"title": "Kansas City Chiefs Win Super Bowl LIX",
                 "url": "https://example.com/sports/super-bowl-lix",
                 "snippet": "The Kansas City Chiefs defeated the San Francisco 49ers 25-22 in Super Bowl LIX, securing their third consecutive championship."},
                {"title": "Super Bowl LIX Results - Chiefs Dynasty Continues",
                 "url": "https://example.com/news/chiefs-win-super-bowl-lix",
                 "snippet": "Patrick Mahomes led the Chiefs to a dramatic 25-22 overtime victory against the 49ers in Super Bowl LIX in New Orleans."}
            ],
            "mars missions": [
                {"title": "NASA's Perseverance Rover Discovers Ancient Microbial Fossils",
                 "url": "https://example.com/science/mars-fossils-discovery",
                 "snippet": "The Perseverance rover has identified structures that appear to be fossilized microorganisms in Jezero Crater, providing the strongest evidence yet for ancient life on Mars."},
                {"title": "SpaceX Starship Completes First Successful Mars Cargo Mission",
                 "url": "https://example.com/space/spacex-mars-cargo",
                 "snippet": "SpaceX's Starship successfully delivered its first cargo payload to Mars, establishing a crucial supply line for future human missions planned for 2028."}
            ],
            "quantum computing": [
                {"title": "Google Achieves Quantum Supremacy with 1,000-Qubit Processor",
                 "url": "https://example.com/tech/google-quantum-supremacy",
                 "snippet": "Google's quantum computing team has developed a stable 1,000-qubit processor that maintains coherence for unprecedented periods, solving problems beyond the reach of classical supercomputers."},
                {"title": "Quantum Error Correction Breakthrough Enables Practical Quantum Computing",
                 "url": "https://example.com/science/quantum-error-correction",
                 "snippet": "Scientists have developed a new quantum error correction method that reduces decoherence by 99%, bringing fault-tolerant quantum computing within practical reach."}
            ]
        }

    async def _arun(self, search_term: str) -> str:
        """Asynchronously run the search and return results."""
        # Clean up the search term
        search_term = search_term.lower().strip()

        # Find the most relevant mock response
        response = None
        for key, results in self.search_responses.items():
            if key in search_term:
                response = results
                break

        # If no specific match, provide a generic response
        if not response:
            return "No specific information found for this query. Please try a different search term."

        # Format the response
        formatted_response = "Here are the search results:\n\n"
        for result in response:
            formatted_response += f"Title: {result['title']}\n"
            formatted_response += f"URL: {result['url']}\n"
            formatted_response += f"Snippet: {result['snippet']}\n\n"

        return formatted_response

    def _run(self, search_term: str) -> str:
        """Run the search and return results (synchronous version)."""
        # This is just a wrapper for testing - implementation is in _arun
        return asyncio.run(self._arun(search_term))


class MultiModelToolState(TypedDict):
    """State representation for the multi-model tool conversation test."""
    messages: List[Dict[str, str]]          # List of messages in the conversation
    current_turn: int                       # Current turn in the conversation
    turn_count: int                         # Total number of turns to perform
    model_sequence: List[Dict[str, str]]    # Sequence of models to use for each turn
    current_model_idx: int                  # Index of the current model in the sequence
    final_responses: List[str]              # Final responses from each model
    tool_usage_stats: Dict[str, Dict]       # Statistics on tool usage by model
    tool_success: bool                      # Whether tools were successfully used
    context_maintained: bool                # Whether context was maintained
    tools: List[BaseTool]                   # Tools available to models


def create_multimodel_tool_graph(config: Config, tools: List[BaseTool]):
    """Create a state graph for the multi-model tool conversation test."""
    # Define the state graph with the MultiModelToolState type
    graph = StateGraph(MultiModelToolState)

    async def process_user_message(state: MultiModelToolState) -> MultiModelToolState:
        """Process the initial user message and prepare for the first model."""
        # Return the current state as we're starting with a predefined user message
        current_model = state["model_sequence"][state["current_model_idx"]]
        logger.info(f"Starting conversation with models: {', '.join([f'{m['provider']}/{m['model_name']}' for m in state['model_sequence']])}")
        logger.info(f"Turn {state['current_turn']}/{state['turn_count']} - Using model: {current_model}")

        return state

    async def generate_model_response(state: MultiModelToolState) -> MultiModelToolState:
        """Generate a response from the current model in the sequence."""
        from app.langchain_utils import abstract_llm_completion_stream

        # Get the current model from the sequence
        current_model = state["model_sequence"][state["current_model_idx"]]
        model_id = f"{current_model['provider']}/{current_model['model_name']}"

        # Show which model we're using
        logger.info(f"Generating response with {model_id}")

        # Build the model's prompt from conversation history
        messages = state["messages"].copy()

        # This is where we would stream the model's response
        # For testing, we'll replace this with a mock response generation
        try:
            # Create a thinking message placeholder for visualization
            print(f"\n[{model_id}] thinking...", end="", flush=True)

            # Use the real model for generation
            full_response = ""
            async for chunk in abstract_llm_completion_stream(
                model_name=model_id,
                messages=messages,
                config=config,
                tools=state["tools"]
            ):
                full_response += chunk

            # Record tool usage stats
            record_tool_usage(state, model_id, full_response)

            # Add the response to the message history
            messages.append({
                "role": "assistant",
                "content": full_response
            })

            print(f"\n\n[{model_id}] response: {full_response[:30]}...", flush=True)

        except Exception as e:
            error_msg = f"Error in streaming with {model_id}: {str(e)}"
            logger.error(error_msg)

            # Add error message to history
            messages.append({
                "role": "assistant",
                "content": error_msg
            })

            print(f"\n\n[{model_id}] response: {error_msg[:30]}...", flush=True)

        # Update the model index for the next turn
        next_model_idx = (state["current_model_idx"] + 1) % len(state["model_sequence"])
        next_turn = state["current_turn"] + 1

        # Store the final response for this model
        final_responses = state["final_responses"].copy()
        final_responses.append(messages[-1]["content"])

        # Check if context is maintained across models
        if state["current_turn"] > 1:
            # Compare responses between turns for context maintenance
            current_response = messages[-1]["content"].lower()
            previous_response = messages[-3]["content"].lower()
            user_message = messages[-2]["content"].lower()

            context_maintained = False

            # Check for specific indications of context maintenance
            if "super bowl" in user_message:
                if any(s in current_response for s in ["super bowl", "chiefs", "49ers", "san francisco", "kansas city", "25-22"]):
                    context_maintained = True

            elif "mars" in user_message:
                if any(s in current_response for s in ["mars", "perseverance", "rover", "jezero", "spacex", "starship"]):
                    context_maintained = True

            elif "quantum" in user_message:
                if any(s in current_response for s in ["quantum", "qubit", "processor", "error correction", "decoherence"]):
                    context_maintained = True

            state["context_maintained"] = context_maintained

        # Return the updated state
        return {
            **state,
            "messages": messages,
            "current_model_idx": next_model_idx,
            "current_turn": next_turn,
            "final_responses": final_responses
        }

    def record_tool_usage(state: MultiModelToolState, model_id: str, response: str) -> None:
        """Record statistics about tool usage by the model."""
        # If this is the first time we're seeing this model, initialize its stats
        if model_id not in state["tool_usage_stats"]:
            state["tool_usage_stats"][model_id] = {
                "attempts": 0,
                "successful_calls": 0,
                "tools_used": set()
            }

        # Increment the attempts counter
        state["tool_usage_stats"][model_id]["attempts"] += 1

        # Check for evidence of tool usage in the response
        response_lower = response.lower()

        # Check for search tool usage
        if "[web_search] search_term:" in response_lower:
            state["tool_usage_stats"][model_id]["tools_used"].add("web_search")
            state["tool_usage_stats"][model_id]["successful_calls"] += 1
            state["tool_success"] = True

            # Check for specific search queries that indicate good tool usage
            if "super bowl" in response_lower and any(s in response_lower for s in ["chiefs", "49ers", "25-22"]):
                state["tool_usage_stats"][model_id]["query_quality"] = "high"
            elif "mars" in response_lower and any(s in response_lower for s in ["perseverance", "fossils", "spacex", "starship"]):
                state["tool_usage_stats"][model_id]["query_quality"] = "high"
            elif "quantum" in response_lower and any(s in response_lower for s in ["google", "1,000-qubit", "error correction"]):
                state["tool_usage_stats"][model_id]["query_quality"] = "high"
            else:
                state["tool_usage_stats"][model_id]["query_quality"] = "medium"

    def should_continue(state: MultiModelToolState) -> Literal["continue", "end"]:
        """Determine whether to continue the conversation or end it."""
        # Check if we've reached the desired number of turns
        if state["current_turn"] > state["turn_count"]:
            logger.info(f"Reached maximum turns ({state['turn_count']}). Ending conversation.")
            return "end"

        # Add a user message every 2 turns (to keep the conversation going)
        if state["current_turn"] % 2 == 0:
            # Add a generic user message prompting for more information
            messages = state["messages"].copy()
            messages.append({
                "role": "user",
                "content": "Please tell me more about this topic."
            })
            state["messages"] = messages

        return "continue"

    # Add nodes to the graph
    graph.add_node("process_user_message", process_user_message)
    graph.add_node("generate_model_response", generate_model_response)

    # Add edges to the graph
    graph.add_edge(START, "process_user_message")
    graph.add_edge("process_user_message", "generate_model_response")
    graph.add_conditional_edges(
        "generate_model_response",
        should_continue,
        {
            "continue": "generate_model_response",
            "end": END
        }
    )

    return graph


class ToolMultiModelTester:
    """Tests multi-model conversations with tool use."""

    def __init__(self, config: Config):
        """Initialize with configuration."""
        self.config = config
        self.models = initialize_tool_compatible_model_list(config)
        self.test_prompts = [
            "Who won the Super Bowl in 2025 and what was the final score?",
            "What's the latest news about Mars missions?",
            "Tell me about recent breakthroughs in quantum computing.",
        ]
        self.results = []
        self.tools = [SearchTool()]

        # Log available models
        logger.info(f"Initialized with {len(self.models)} tool-compatible models")
        for model in self.models:
            logger.info(f"  {model.provider}/{model.model_name}")

    async def test_model_pair(self, model1: ModelConfig, model2: ModelConfig) -> Dict[str, Any]:
        """Test a pair of models in conversation with tool usage."""
        model1_id = f"{model1.provider}/{model1.model_name}"
        model2_id = f"{model2.provider}/{model2.model_name}"

        logger.info(f"Testing tool-based conversation between {model1_id} and {model2_id}")

        # Choose a random test prompt
        prompt = random.choice(self.test_prompts)

        # Create the initial state
        state: MultiModelToolState = {
            "messages": [{"role": "user", "content": prompt}],
            "current_turn": 0,
            "turn_count": 4,  # 4 turns total: user→model1→user→model2
            "model_sequence": [
                {"provider": model1.provider, "model_name": model1.model_name},
                {"provider": model2.provider, "model_name": model2.model_name}
            ],
            "current_model_idx": 0,
            "final_responses": [],
            "tool_usage_stats": {},
            "tool_success": False,
            "context_maintained": False,
            "tools": self.tools
        }

        # Create the graph
        graph = create_multimodel_tool_graph(self.config, self.tools)

        print(f"\n{'='*80}")
        print(f"Testing tool conversation: {model1_id} → {model2_id}")
        print(f"Prompt: {prompt}")
        print(f"{'='*80}")

        # Run the graph
        start_time = time.time()
        try:
            # First compile the graph, then use ainvoke
            compiled_graph = graph.compile()
            final_state = await compiled_graph.ainvoke(state)

            # Analyze the results
            tool_success = final_state["tool_success"]

            # Determine if context was maintained - check if second model references first model's response
            context_maintained = False
            if len(final_state["final_responses"]) >= 2:
                first_response = final_state["final_responses"][0].lower()
                second_response = final_state["final_responses"][1].lower()

                # Look for references to the first model's content in the second model's response
                # This is a simple heuristic and might need improvement
                for line in first_response.split("\n"):
                    if len(line) > 20 and line in second_response:
                        context_maintained = True
                        break

                # Also check for key terms in tool responses
                if "super bowl" in prompt.lower() and "40-22" in second_response:
                    context_maintained = True
                elif "mars" in prompt.lower() and "fossils" in second_response:
                    context_maintained = True
                elif "quantum" in prompt.lower() and "1,000-qubit" in second_response:
                    context_maintained = True

            final_state["context_maintained"] = context_maintained

            # Prepare the result
            result = {
                "model1": model1_id,
                "model2": model2_id,
                "prompt": prompt,
                "tool_success": tool_success,
                "context_maintained": context_maintained,
                "final_responses": final_state["final_responses"],
                "tool_usage_stats": final_state["tool_usage_stats"],
                "duration": time.time() - start_time,
                "success": tool_success and context_maintained
            }

            self.results.append(result)
            return result

        except Exception as e:
            # Log the error
            logger.error(f"Error running test between {model1_id} and {model2_id}: {str(e)}")

            # Prepare error result
            error_result = {
                "model1": model1_id,
                "model2": model2_id,
                "prompt": prompt,
                "error": str(e),
                "duration": time.time() - start_time,
                "success": False
            }

            self.results.append(error_result)
            return error_result

    async def run_all_pairs_tests(self, limit_per_provider: int = 1) -> Dict[str, List[Dict[str, Any]]]:
        """Run tests for all pairs of models, limiting to a subset for each provider."""
        logger.info(f"Running all pairs tests with {limit_per_provider} model(s) per provider")

        # Group models by provider
        models_by_provider = {}
        for model in self.models:
            if model.provider not in models_by_provider:
                models_by_provider[model.provider] = []
            models_by_provider[model.provider].append(model)

        # Limit the number of models per provider
        limited_models = []
        for provider, provider_models in models_by_provider.items():
            limited_models.extend(provider_models[:limit_per_provider])

        # Generate all pairs of limited models
        pairs = list(itertools.combinations(limited_models, 2))

        # Add self-pairs (same model to itself)
        pairs.extend([(model, model) for model in limited_models])

        # Shuffle to randomize the order
        random.shuffle(pairs)

        logger.info(f"Testing {len(pairs)} model pairs")

        # Run tests for each pair
        results_by_provider_pair = {}
        for model1, model2 in pairs:
            pair_key = f"{model1.provider}-{model2.provider}"

            if pair_key not in results_by_provider_pair:
                results_by_provider_pair[pair_key] = []

            result = await self.test_model_pair(model1, model2)
            results_by_provider_pair[pair_key].append(result)

        return results_by_provider_pair

    def print_results(self) -> None:
        """Print a summary of all test results."""
        if not self.results:
            logger.warning("No test results to print")
            return

        print("\n" + "="*100)
        print(f"SUMMARY OF TOOL-BASED CONVERSATION TESTS ({len(self.results)} tests)")
        print("="*100)

        # Count success rates by provider
        provider_stats = {}
        provider_pair_stats = {}

        total_tests = len(self.results)
        successful_tests = 0
        tool_usage_tests = 0
        context_maintained_tests = 0

        for result in self.results:
            # Skip tests with errors
            if "error" in result:
                continue

            # Extract provider information
            model1_parts = result["model1"].split("/")
            model2_parts = result["model2"].split("/")
            provider1 = model1_parts[0]
            provider2 = model2_parts[0]

            # Update provider stats
            for provider in [provider1, provider2]:
                if provider not in provider_stats:
                    provider_stats[provider] = {
                        "tests": 0,
                        "success": 0,
                        "tool_usage": 0,
                        "context_maintained": 0
                    }
                provider_stats[provider]["tests"] += 1
                if result.get("success", False):
                    provider_stats[provider]["success"] += 1
                if result.get("tool_success", False):
                    provider_stats[provider]["tool_usage"] += 1
                if result.get("context_maintained", False):
                    provider_stats[provider]["context_maintained"] += 1

            # Update provider pair stats
            pair_key = f"{provider1}-{provider2}"
            if pair_key not in provider_pair_stats:
                provider_pair_stats[pair_key] = {
                    "tests": 0,
                    "success": 0,
                    "tool_usage": 0,
                    "context_maintained": 0
                }
            provider_pair_stats[pair_key]["tests"] += 1
            if result.get("success", False):
                provider_pair_stats[pair_key]["success"] += 1
            if result.get("tool_success", False):
                provider_pair_stats[pair_key]["tool_usage"] += 1
            if result.get("context_maintained", False):
                provider_pair_stats[pair_key]["context_maintained"] += 1

            # Update overall stats
            if result.get("success", False):
                successful_tests += 1
            if result.get("tool_success", False):
                tool_usage_tests += 1
            if result.get("context_maintained", False):
                context_maintained_tests += 1

        # Print overall stats
        print(f"\nOverall Success Rate: {successful_tests}/{total_tests} ({successful_tests/total_tests*100:.1f}%)")
        print(f"Tool Usage Success: {tool_usage_tests}/{total_tests} ({tool_usage_tests/total_tests*100:.1f}%)")
        print(f"Context Maintained: {context_maintained_tests}/{total_tests} ({context_maintained_tests/total_tests*100:.1f}%)")

        # Print provider stats
        print("\nProvider Statistics:")
        print("-"*80)
        print(f"{'Provider':<15} {'Tests':<8} {'Success':<15} {'Tool Usage':<15} {'Context':<15}")
        print("-"*80)

        for provider, stats in provider_stats.items():
            success_rate = stats["success"] / stats["tests"] * 100 if stats["tests"] > 0 else 0
            tool_rate = stats["tool_usage"] / stats["tests"] * 100 if stats["tests"] > 0 else 0
            context_rate = stats["context_maintained"] / stats["tests"] * 100 if stats["tests"] > 0 else 0

            print(f"{provider:<15} {stats['tests']:<8} {stats['success']}/{stats['tests']} ({success_rate:.1f}%) "
                  f"{stats['tool_usage']}/{stats['tests']} ({tool_rate:.1f}%) "
                  f"{stats['context_maintained']}/{stats['tests']} ({context_rate:.1f}%)")

        # Print provider pair stats
        print("\nProvider Pair Statistics:")
        print("-"*80)
        print(f"{'Provider Pair':<20} {'Tests':<8} {'Success':<15} {'Tool Usage':<15} {'Context':<15}")
        print("-"*80)

        for pair, stats in provider_pair_stats.items():
            success_rate = stats["success"] / stats["tests"] * 100 if stats["tests"] > 0 else 0
            tool_rate = stats["tool_usage"] / stats["tests"] * 100 if stats["tests"] > 0 else 0
            context_rate = stats["context_maintained"] / stats["tests"] * 100 if stats["tests"] > 0 else 0

            print(f"{pair:<20} {stats['tests']:<8} {stats['success']}/{stats['tests']} ({success_rate:.1f}%) "
                  f"{stats['tool_usage']}/{stats['tests']} ({tool_rate:.1f}%) "
                  f"{stats['context_maintained']}/{stats['tests']} ({context_rate:.1f}%)")

        # Print model-specific tool usage stats
        print("\nTool Usage by Model:")
        print("-"*80)

        tool_stats_by_model = {}
        for result in self.results:
            if "error" in result or "tool_usage_stats" not in result:
                continue

            for model_id, stats in result["tool_usage_stats"].items():
                if model_id not in tool_stats_by_model:
                    tool_stats_by_model[model_id] = {
                        "attempts": 0,
                        "successful_calls": 0,
                        "tools_used": set()
                    }

                tool_stats_by_model[model_id]["attempts"] += stats.get("attempts", 0)
                tool_stats_by_model[model_id]["successful_calls"] += stats.get("successful_calls", 0)
                if "tools_used" in stats:
                    for tool in stats["tools_used"]:
                        tool_stats_by_model[model_id]["tools_used"].add(tool)

        for model_id, stats in tool_stats_by_model.items():
            success_rate = stats["successful_calls"] / stats["attempts"] * 100 if stats["attempts"] > 0 else 0
            tools_used = ", ".join(stats["tools_used"]) if stats["tools_used"] else "None"

            print(f"{model_id}:")
            print(f"  Calls: {stats['successful_calls']}/{stats['attempts']} ({success_rate:.1f}%)")
            print(f"  Tools Used: {tools_used}")

        print("\nDetailed Test Results:")
        print("-"*80)

        for i, result in enumerate(self.results):
            if "error" in result:
                print(f"\nTest {i+1}: {result['model1']} → {result['model2']} - ERROR: {result['error']}")
            else:
                print(f"\nTest {i+1}: {result['model1']} → {result['model2']} - "
                      f"{'SUCCESS' if result.get('success', False) else 'FAILURE'}")
                print(f"  Prompt: {result['prompt']}")
                print(f"  Tool Usage: {'Yes' if result.get('tool_success', False) else 'No'}")
                print(f"  Context Maintained: {'Yes' if result.get('context_maintained', False) else 'No'}")
                print(f"  Duration: {result.get('duration', 0):.2f} seconds")

        print("\n" + "="*100)


async def main():
    """Main entry point for the test script."""
    config = Config()

    # Initialize the tester
    tester = ToolMultiModelTester(config)

    # Run all pairs tests with 1 model per provider
    await tester.run_all_pairs_tests(limit_per_provider=1)

    # Print results
    tester.print_results()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nTest interrupted by user.")
    except Exception as e:
        logger.exception(f"Unhandled exception: {str(e)}")
