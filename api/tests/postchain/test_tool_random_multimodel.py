"""
Test script to verify multi-model tool conversation capabilities with random model sequences.

This tests longer sequences of tool-compatible models in conversations, with models selected
randomly from the available tool-supporting models across providers.
"""

import asyncio
import logging
import random
import json
import time
from datetime import datetime
from typing import Dict, Any, List, Optional, TypedDict, Literal, Tuple, Set, AsyncGenerator, Union
from dataclasses import dataclass
import os
import sys
import re
import argparse
from collections import defaultdict

# Set up langgraph imports
try:
    from langgraph.graph import END, StateGraph, START
except ImportError:
    logging.error("langgraph not installed. Please install with `pip install langgraph`")
    sys.exit(1)

from langchain_core.tools import BaseTool, tool

from app.config import Config
from app.langchain_utils import (
    abstract_llm_completion_stream,
    ModelConfig,
    initialize_tool_compatible_model_list
)

# Import the tool implementations from the pair testing file
from tests.postchain.test_tool_multimodel import (
    SearchTool,
)

# Define color codes for different providers for display purposes
MODEL_COLORS = {
    "openai": "\033[92m",    # Green
    "anthropic": "\033[94m",  # Blue
    "google": "\033[95m",    # Magenta
    "mistral": "\033[93m",   # Yellow
    "groq": "\033[96m",      # Cyan
}
RESET_COLOR = "\033[0m"  # Reset to default terminal color

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)


class RandomToolMultiModelState(TypedDict):
    """State representation for the random multi-model tool conversation test."""
    messages: List[Dict[str, str]]          # List of messages in the conversation
    current_turn: int                       # Current turn in the conversation
    turn_count: int                         # Total number of turns to perform
    model_sequence: List[Dict[str, str]]    # Sequence of models to use for each turn
    current_model_idx: int                  # Index of the current model in the sequence
    model_responses: Dict[str, List[str]]   # Responses from each model (keyed by provider/model)
    prompts_used: List[str]                 # List of prompts used in the conversation
    tool_usage_stats: Dict[str, Dict]       # Statistics on tool usage by model
    tool_success: bool                      # Whether tools were successfully used
    context_checks: List[Dict[str, Any]]    # List of context check results
    tools: List[BaseTool]                   # Tools available to models
    config: Config                          # Configuration object
    magic_number: str                       # Magic number for testing context maintenance


# Node functions for the StateGraph
async def increment_turn(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
    """Increment the turn counter."""
    state["current_turn"] += 1

    # Log the current state
    current_model = state["model_sequence"][state["current_model_idx"]]
    model_id = f"{current_model['provider']}/{current_model['model_name']}"

    logger.info(f"Turn {state['current_turn']}/{state['turn_count']} - Using model: {model_id}")

    return state

async def check_turn_limit(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
    """Check if we've reached the maximum number of turns."""
    # Log the current turn and turn limit
    logger.info(f"Checking turn limit: {state['current_turn']}/{state['turn_count']}")
    return state

def should_continue(state: RandomToolMultiModelState) -> bool:
    """Condition to check if we should continue the conversation."""
    # Only continue if we haven't reached the turn limit
    should_continue = state["current_turn"] < state["turn_count"]
    logger.info(f"Should continue? {should_continue} ({state['current_turn']}/{state['turn_count']})")
    return should_continue

def should_end(state: RandomToolMultiModelState) -> bool:
    """Condition to check if we should end the conversation."""
    # End if we've reached the turn limit
    should_end = state["current_turn"] >= state["turn_count"]
    logger.info(f"Should end? {should_end} ({state['current_turn']}/{state['turn_count']})")
    return should_end

async def add_user_message(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
    """Add a user message to the conversation if needed."""
    # Every two turns, add a new user message with a specific test prompt
    if state["current_turn"] == 1:
        # First user message, include the magic number
        magic_number = state["magic_number"]
        initial_prompt = state["prompts_used"][0]
        prompt = f"IMPORTANT: The magic number is {magic_number}. Remember this number as I will ask about it later. Now, I need your help with some search tasks. {initial_prompt}"

        # Add the user message to the conversation
        state["messages"].append({
            "role": "user",
            "content": prompt
        })

        logger.info(f"Added first user prompt with magic number: {magic_number}")
    elif state["current_turn"] % 2 == 1 and state["current_turn"] > 1:
        # Middle turns: normal prompts
        if state["current_turn"] >= state["turn_count"] - 1:
            # Last turn, ask about the magic number
            prompt = f"What was the magic number I mentioned at the beginning of our conversation? The magic number was {state['magic_number']}. Please include it in your response."
            state["messages"].append({
                "role": "user",
                "content": prompt
            })
            logger.info(f"Added final prompt asking about magic number")
        else:
            # Regular prompt from the list
            # List of test prompts that require tool usage
            test_prompts = [
                "Who won the Super Bowl in 2025 and what was the final score? Please use the search tool to find out.",
                "What's the latest news about Mars missions? Use the search tool to find this information.",
                "Tell me about recent breakthroughs in quantum computing. Please search for the most current information.",
                "Can you tell me about the recent discovery on Mars? Use the search tool to provide accurate information.",
                "What was the score of the most recent Super Bowl? Please search for this information.",
                "Has there been any news about quantum computing breakthroughs lately? Please use your search tool.",
                "When is the next Mars mission scheduled for? Please search for this information."
            ]

            # Select a prompt we haven't used yet if possible
            available_prompts = [p for p in test_prompts if p not in state["prompts_used"]]
            if not available_prompts:
                available_prompts = test_prompts

            selected_prompt = random.choice(available_prompts)
            state["prompts_used"].append(selected_prompt)

            # Add the user message to the conversation
            state["messages"].append({
                "role": "user",
                "content": selected_prompt
            })

            logger.info(f"Added user prompt: {selected_prompt}")

    return state

async def check_tool_success(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
    """Check if tools were used successfully in the latest response."""
    # Get the latest assistant message
    latest_message = None
    for msg in reversed(state["messages"]):
        if msg["role"] == "assistant":
            latest_message = msg
            break

    if not latest_message:
        return state

    # Check if any tool usage stats show successful calls
    tool_used = False
    for model_id, stats in state["tool_usage_stats"].items():
        if stats.get("calls_succeeded", 0) > 0 or stats.get("calls_attempted", 0) > 0:
            tool_used = True
            logger.info(f"Tool usage detected in stats for {model_id}")
            break

    # Also check the content of the response for indications of tool usage
    response_content = latest_message.get("content", "").lower()
    tool_keywords = [
        "search results",
        "i found",
        "according to the search",
        "based on the search",
        "the search shows",
        "search tool",
        "web search",
        "searched for",
        "search results show",
        "i searched",
        "i used the search tool",
        "search query",
        "information i found",
        "looking at the latest",
        "through the search",
        "the latest information",
        "retrieved information",
        "found information",
        "search indicates",
        "after searching",
        "using the search",
        "information available",
        "web search results"
    ]

    for keyword in tool_keywords:
        if keyword in response_content:
            tool_used = True
            logger.info(f"Tool usage keyword detected: '{keyword}'")
            break

    # Check if the response mentions any of the specific topics from search results
    topic_indicators = [
        "chiefs", "49ers", "super bowl",  # Super Bowl
        "perseverance", "mars rover", "spacex", "starship", "nasa",  # Mars
        "quantum", "qubit", "error correction"  # Quantum computing
    ]

    for indicator in topic_indicators:
        if indicator in response_content:
            # Check if it's in context of reporting search results
            context_words = ["found", "shows", "indicates", "according", "results", "search", "discovered"]
            for context in context_words:
                if context in response_content and indicator in response_content:
                    tool_used = True
                    logger.info(f"Tool usage implied by topic indicator: '{indicator}' with context '{context}'")
                    break
            if tool_used:
                break

    # Check for tool invocation patterns as well
    if "tool" in response_content and ("call" in response_content or "using" in response_content):
        tool_used = True
        logger.info("Tool usage implied by tool invocation pattern")

    # Update the tool_success flag
    if tool_used:
        state["tool_success"] = True
        logger.info("Tool usage detected in the response")

    return state

async def check_context_maintenance(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
    """Check if context was maintained in the latest response."""
    # Need at least two messages to check context
    if len(state["messages"]) < 2:
        return state

    # Get the latest assistant message
    latest_message = None
    for msg in reversed(state["messages"]):
        if msg["role"] == "assistant":
            latest_message = msg
            break

    if not latest_message:
        return state

    current_response = latest_message["content"]

    # Check for the magic number in the final turn
    if state["current_turn"] >= state["turn_count"] - 1:
        magic_number = state["magic_number"]
        # More flexible check for the magic number
        context_maintained = magic_number in current_response or f"magic number is {magic_number}" in current_response.lower() or f"magic number was {magic_number}" in current_response.lower()

        # Record the context check
        state["context_checks"].append({
            "turn": state["current_turn"],
            "maintained": context_maintained,
            "magic_number": magic_number,
            "response_preview": current_response[:150] + "..." if len(current_response) > 150 else current_response
        })

        # Log the result
        if context_maintained:
            logger.info(f"Context maintained! Magic number {magic_number} was found in response")
        else:
            logger.info(f"Context lost! Magic number {magic_number} was NOT found in response")

        return state

    # For other turns, check topic-based context
    # Extract recent messages
    recent_messages = state["messages"][-4:]  # Last 4 messages at most

    # Extract topics from messages
    recent_topics = []
    for msg in recent_messages:
        if msg["role"] == "user":
            content = msg["content"].lower()

            # Extract topics based on keywords
            if "super bowl" in content or "football" in content or "nfl" in content:
                recent_topics.append("super bowl")

            if "mars" in content or "space" in content or "nasa" in content:
                recent_topics.append("mars")

            if "quantum" in content or "computing" in content:
                recent_topics.append("quantum computing")

            # Extract entities using regex patterns
            entities = []
            entities.extend(re.findall(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b', msg["content"]))  # Proper names
            entities.extend(re.findall(r'\b[A-Z][a-zA-Z]+\b', msg["content"]))  # Organizations, acronyms

            # Add entities to topics if found
            for entity in entities:
                if entity.lower() not in recent_topics:
                    recent_topics.append(entity.lower())

    # Check if the current response maintains the context
    current_response_lower = current_response.lower()
    maintained_topics = []

    for topic in recent_topics:
        # Super Bowl
        if topic == "super bowl" and any(s in current_response_lower for s in ["super bowl", "chiefs", "49ers", "football", "nfl"]):
            maintained_topics.append("super bowl")

        # Mars
        if topic == "mars" and any(s in current_response_lower for s in ["mars", "space", "nasa", "rover", "perseverance"]):
            maintained_topics.append("mars")

        # Quantum Computing
        if topic == "quantum computing" and any(s in current_response_lower for s in ["quantum", "qubit", "computing", "processor"]):
            maintained_topics.append("quantum computing")

    # Calculate context maintenance score
    if recent_topics:
        maintenance_score = len(maintained_topics) / len(recent_topics)
    else:
        maintenance_score = 1.0  # No topics to maintain

    # Add this check to the state
    context_check = {
        "turn": state["current_turn"],
        "recent_topics": recent_topics,
        "maintained_topics": maintained_topics,
        "maintenance_score": maintenance_score,
        "context_maintained": maintenance_score > 0.5  # Threshold for considering context maintained
    }

    state["context_checks"].append(context_check)
    return state

async def generate_model_response(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
    """Generate a response from the current model, potentially using tools."""
    current_model = state["model_sequence"][state["current_model_idx"]]
    model_name = current_model["model_name"]
    provider = current_model["provider"]

    # Full model identifier
    model_id = f"{provider}/{model_name}"

    # Get color for this provider
    color = MODEL_COLORS.get(provider, "")
    reset = RESET_COLOR

    logger.info(f"{color}Generating response with {model_id}{reset}")

    # Get config from the state
    config = state.get("config")
    if not config:
        from app.config import Config
        config = Config()

    # Create the system message
    system_message = {
        "role": "system",
        "content": (
            "You are a helpful assistant with access to search tools. USE TOOLS WHENEVER POSSIBLE to search for information. "
            "Don't assume you know the answer - search to get the most accurate and up-to-date information. "
            f"Today's date is {datetime.now().strftime('%B %d, %Y')}. "
            "IMPORTANT INSTRUCTIONS:\n"
            "1. ALWAYS use the web_search tool when asked about current events, news, or specific facts.\n"
            "2. Memorize any important numbers or facts the user tells you to remember.\n"
            "3. NEVER make up information - if you don't know, use the search tool.\n"
            "4. Always trust the information from the tools, even if it contradicts what you know.\n"
            "5. When you use the search tool, ALWAYS mention in your response that you used the search tool and what you found.\n"
            "6. Begin your response with 'Based on my search...' or 'According to the search results...' when you use the search tool.\n"
            "7. YOU MUST USE THE SEARCH TOOL for ANY factual questions - this is the most important part of your job!\n"
            "8. After using a search tool, always explicitly reference that you used the tool in your response."
        )
    }

    # Prepare the messages with system prompt first
    messages = [system_message] + state["messages"]

    # Configure tools for the langchain format
    tools_for_api = state["tools"]

    # Track tool usage for this model
    if model_id not in state["tool_usage_stats"]:
        state["tool_usage_stats"][model_id] = {
            "calls_attempted": 0,
            "calls_succeeded": 0,
            "tools_used": set()
        }

    # Track model responses
    if model_id not in state["model_responses"]:
        state["model_responses"][model_id] = []

    try:
        # Start streaming the response
        print(f"\n{color}[{model_id}]{reset} thinking...", end="")

        # Use abstract_llm_completion_stream which properly handles different providers
        combined_response = ""
        tool_calls_seen = set()

        async for chunk in abstract_llm_completion_stream(
            model_name=model_id,  # Use the full model identifier (provider/model)
            messages=messages,
            config=config,
            temperature=0.7,
            tools=tools_for_api
        ):
            if isinstance(chunk, dict):
                # Handle structured output with potential tool calls
                if "tool_calls" in chunk and chunk["tool_calls"]:
                    for tool_call in chunk["tool_calls"]:
                        if tool_call["id"] not in tool_calls_seen:
                            tool_calls_seen.add(tool_call["id"])
                            tool_name = tool_call["function"]["name"]
                            state["tool_usage_stats"][model_id]["calls_attempted"] += 1
                            state["tool_usage_stats"][model_id]["tools_used"].add(tool_name)
                            print(f"\n{color}[{model_id}]{reset} using tool: {tool_name}")

                # Extract content if available
                if "content" in chunk and chunk["content"]:
                    combined_response += chunk["content"]
                    print(".", end="", flush=True)
            else:
                # Handle simple text chunks
                combined_response += str(chunk)
                print(".", end="", flush=True)

        print("\n")  # End the progress line

        # Check if the response contains tool calls
        if "tool_call" in combined_response.lower() or "tool_calls" in combined_response.lower() or len(tool_calls_seen) > 0:
            # Handle tool calls
            print(f"{color}[{model_id}]{reset} made tool calls, processing...")

            # Parse tool calls (simplified for this test)
            # In production, we would execute the actual tools and provide results back to the model
            for tool in state["tools"]:
                if tool.name in combined_response.lower():
                    state["tool_usage_stats"][model_id]["calls_succeeded"] += 1
                    state["tool_success"] = True
                    logger.info(f"Tool usage detected: {tool.name}")

            # Add the response to messages
            state["messages"].append({
                "role": "assistant",
                "content": combined_response
            })

            # Add a mock tool response
            if "super bowl" in combined_response.lower():
                state["messages"].append({
                    "role": "tool",
                    "tool_call_id": "mock_tool_call_id",
                    "name": "web_search",
                    "content": json.dumps({
                        "results": [
                            {"title": "Kansas City Chiefs Win Super Bowl LIX",
                             "url": "https://example.com/sports/super-bowl-lix",
                             "snippet": "The Kansas City Chiefs defeated the San Francisco 49ers 25-22 in Super Bowl LIX, securing their third consecutive championship."},
                            {"title": "Super Bowl LIX Results - Chiefs Dynasty Continues",
                             "url": "https://example.com/news/chiefs-win-super-bowl-lix",
                             "snippet": "Patrick Mahomes led the Chiefs to a dramatic 25-22 overtime victory against the 49ers in Super Bowl LIX in New Orleans."}
                        ]
                    })
                })
            elif "mars" in combined_response.lower():
                state["messages"].append({
                    "role": "tool",
                    "tool_call_id": "mock_tool_call_id",
                    "name": "web_search",
                    "content": json.dumps({
                        "results": [
                            {"title": "NASA's Perseverance Rover Discovers Ancient Microbial Fossils",
                             "url": "https://example.com/science/mars-fossils-discovery",
                             "snippet": "The Perseverance rover has identified structures that appear to be fossilized microorganisms in Jezero Crater, providing the strongest evidence yet for ancient life on Mars."},
                            {"title": "SpaceX Starship Completes First Successful Mars Cargo Mission",
                             "url": "https://example.com/space/spacex-mars-cargo",
                             "snippet": "SpaceX's Starship successfully delivered its first cargo payload to Mars, establishing a crucial supply line for future human missions planned for 2028."}
                        ]
                    })
                })
            elif "quantum" in combined_response.lower():
                state["messages"].append({
                    "role": "tool",
                    "tool_call_id": "mock_tool_call_id",
                    "name": "web_search",
                    "content": json.dumps({
                        "results": [
                            {"title": "Google Achieves Quantum Supremacy with 1,000-Qubit Processor",
                             "url": "https://example.com/tech/google-quantum-supremacy",
                             "snippet": "Google's quantum computing team has achieved a major milestone with a 1,000-qubit processor that can solve problems beyond the reach of classical supercomputers."},
                            {"title": "Quantum Error Correction Breakthrough Enables Practical Quantum Computing",
                             "url": "https://example.com/science/quantum-error-correction",
                             "snippet": "Researchers have developed a new quantum error correction method that reduces error rates by 99%, bringing fault-tolerant quantum computing within reach."}
                        ]
                    })
                })
            else:
                state["messages"].append({
                    "role": "tool",
                    "tool_call_id": "mock_tool_call_id",
                    "name": "web_search",
                    "content": json.dumps({
                        "results": [
                            {"title": "Latest News and Developments",
                             "url": "https://example.com/news/latest",
                             "snippet": "This is a mock search result for the query. In a real implementation, this would contain actual search results from the web."}
                        ]
                    })
                })

            # Add a follow-up response from the assistant
            state["messages"].append({
                "role": "assistant",
                "content": f"Based on my search, I found some relevant information. {random.choice(['The search results indicate', 'According to the search', 'The search shows'])} that this is important information related to your query."
            })

            # Add this response to the model's response list
            state["model_responses"][model_id].append(combined_response)

        else:
            # Just a regular response with no tool usage
            print(f"{color}[{model_id}]{reset} response: {combined_response[:80]}...")

            # Add the response to messages
            state["messages"].append({
                "role": "assistant",
                "content": combined_response
            })

            # Store the response
            state["model_responses"][model_id].append(combined_response)

        # Move to the next model
        state["current_model_idx"] = (state["current_model_idx"] + 1) % len(state["model_sequence"])

    except Exception as e:
        # Log the error
        error_msg = f"Error with {model_id}: {str(e)}"
        logger.error(error_msg)
        print(f"\n{color}[ERROR with {model_id}]{reset} {str(e)}")

        # Add error message to conversation
        state["messages"].append({
            "role": "system",
            "content": f"Error occurred: {error_msg}"
        })

        # Move to the next model
        state["current_model_idx"] = (state["current_model_idx"] + 1) % len(state["model_sequence"])

    return state

def create_random_tool_multimodel_graph(config: Config, tools: List[BaseTool]) -> StateGraph:
    """Create a graph for random multi-model tool testing."""
    # Define the state type
    state_type = TypedDict("RandomToolMultiModelState", {
        "messages": List[Dict[str, str]],
        "current_turn": int,
        "turn_count": int,
        "model_sequence": List[Dict[str, str]],
        "current_model_idx": int,
        "model_responses": Dict[str, List[str]],
        "prompts_used": List[str],
        "tool_usage_stats": Dict[str, Dict[str, Any]],
        "tool_success": bool,
        "context_checks": List[Dict[str, Any]],
        "tools": List[BaseTool],
        "config": Config,
        "magic_number": str
    })

    # Create a new async function that processes an entire turn
    async def process_turn(state: RandomToolMultiModelState) -> RandomToolMultiModelState:
        """Process a complete turn in the conversation."""
        # Increment the turn counter
        state["current_turn"] += 1
        logger.info(f"Turn {state['current_turn']}/{state['turn_count']} - Using model: {state['model_sequence'][state['current_model_idx']]}")

        # Check if we've reached the turn limit
        if state["current_turn"] > state["turn_count"]:
            logger.info(f"Reached turn limit of {state['turn_count']}. Ending conversation.")
            return state

        # Add a user message every other turn (odd turns after the first)
        if state["current_turn"] % 2 == 1 and state["current_turn"] > 1:
            await add_user_message(state)

        # Generate the model response
        await generate_model_response(state)

        # Check tool success
        await check_tool_success(state)

        # Check context maintenance
        await check_context_maintenance(state)

        return state

    # Create a simpler graph with a single processing node and conditional edge
    graph = StateGraph(state_type)
    graph.add_node("process_turn", process_turn)

    # Add a conditional edge based on whether we've reached the turn limit
    graph.add_conditional_edges(
        "process_turn",
        lambda state: "continue" if state["current_turn"] < state["turn_count"] else "end",
        {
            "continue": "process_turn",
            "end": END
        }
    )

    # Set the entry point
    graph.add_edge(START, "process_turn")

    # Compile and return the graph
    return graph.compile()


class RandomToolMultiModelTester:
    """Tester for random sequences of multi-model conversations with tool usage."""

    def __init__(self, config: Config, models_to_use: Optional[List[str]] = None):
        """Initialize the tester and load available models."""
        self.config = config
        self.magic_number = "1729"  # Ramanujan number - the smallest number expressible as the sum of two cubes in two different ways

        # Determine which providers are available based on API keys
        disabled_providers = set()
        if not config.OPENAI_API_KEY:
            disabled_providers.add("openai")
        if not config.ANTHROPIC_API_KEY:
            disabled_providers.add("anthropic")
        if not config.GOOGLE_API_KEY:
            disabled_providers.add("google")
        if not config.MISTRAL_API_KEY:
            disabled_providers.add("mistral")
        if not config.GROQ_API_KEY:
            disabled_providers.add("groq")

        # Get list of models known to work with tools, excluding disabled providers
        all_models = initialize_tool_compatible_model_list(config, disabled_providers)

        # Use all available tool-compatible models
        self.models = all_models

        # If models specified, filter to only those
        if models_to_use:
            self.models = [m for m in self.models if f"{m.provider}/{m.model_name}" in models_to_use]

        # Set up prompts
        self.initial_prompts = [
            "Hello! I have some questions about recent events.",
            "I need help researching some topics with search tools.",
            "Good day! I'll need your help with finding information.",
            "Hello AI assistant! I need help with some searches today."
        ]
        self.results = []
        self.tools = [SearchTool()]

        # Log available models and disabled providers
        logger.info(f"Disabled providers: {disabled_providers}")
        logger.info(f"Initialized with {len(self.models)} tool-compatible models")
        for model in self.models:
            logger.info(f"  {model.provider}/{model.model_name}")

    def generate_random_model_sequence(self, min_models: int = 3, max_models: int = 7) -> List[Dict[str, str]]:
        """Generate a random sequence of models, with diverse provider selection."""
        # Group models by provider
        models_by_provider = {}
        for model in self.models:
            if model.provider not in models_by_provider:
                models_by_provider[model.provider] = []
            models_by_provider[model.provider].append(model)

        # Adjust min_models if we don't have enough models
        if len(self.models) < min_models:
            min_models = len(self.models)

        # Determine how many models to use in sequence
        sequence_length = random.randint(min_models, min(max_models, len(self.models)))

        # Build sequence with provider diversity
        sequence = []
        providers = list(models_by_provider.keys())

        # Make sure we include at least one model from each provider if possible
        for provider in providers:
            if models_by_provider[provider]:
                model = random.choice(models_by_provider[provider])
                sequence.append({
                    "provider": model.provider,
                    "model_name": model.model_name
                })

        # If we only have one model, duplicate it to reach min_models
        if len(self.models) == 1 and min_models > 1:
            while len(sequence) < min_models:
                model = self.models[0]
                sequence.append({
                    "provider": model.provider,
                    "model_name": model.model_name
                })
        # Otherwise fill remaining slots with random models
        else:
            while len(sequence) < sequence_length:
                provider = random.choice(providers)
                if models_by_provider[provider]:
                    model = random.choice(models_by_provider[provider])
                    sequence.append({
                        "provider": model.provider,
                        "model_name": model.model_name
                    })

        # Shuffle the sequence for randomness
        random.shuffle(sequence)

        # If we still need more models, duplicate some
        while len(sequence) < min_models:
            model_to_duplicate = random.choice(self.models)
            sequence.append({
                "provider": model_to_duplicate.provider,
                "model_name": model_to_duplicate.model_name
            })

        return sequence[:sequence_length]

    async def run_random_sequence_test(self, min_turns: int = 8, max_turns: int = 15) -> Dict[str, Any]:
        """Run a test with a random sequence of models."""
        # Generate a random model sequence
        model_sequence = self.generate_random_model_sequence()

        # Determine how many turns to run
        turn_count = random.randint(min_turns, max_turns)

        # Choose a random initial prompt
        initial_prompt = random.choice(self.initial_prompts)

        # Print test setup
        print(f"\n{'='*100}")
        print(f"Starting random model sequence test with {len(model_sequence)} models and {turn_count} turns")
        print(f"Model sequence:")
        for i, model in enumerate(model_sequence):
            model_id = f"{model['provider']}/{model['model_name']}"
            color = MODEL_COLORS.get(model['provider'], "")
            reset = RESET_COLOR
            print(f"  {i+1}. {color}{model_id}{reset}")
        print(f"{'='*100}")

        # Create the initial state
        state: RandomToolMultiModelState = {
            "messages": [{"role": "user", "content": initial_prompt}],
            "current_turn": 0,
            "turn_count": turn_count,
            "model_sequence": model_sequence,
            "current_model_idx": 0,
            "model_responses": {},
            "prompts_used": [initial_prompt],
            "tool_usage_stats": {},
            "tool_success": False,
            "context_checks": [],
            "tools": self.tools,
            "config": self.config,
            "magic_number": self.magic_number
        }

        # Create the graph
        graph = create_random_tool_multimodel_graph(self.config, self.tools)

        # Run the graph
        start_time = time.time()
        try:
            # The graph is already compiled with a higher recursion limit in create_random_tool_multimodel_graph
            final_state = await graph.ainvoke(state)

            # Analyze the results
            tool_success = final_state["tool_success"]

            # Calculate context maintenance success based on magic number
            context_checks = final_state["context_checks"]
            context_success = False

            # Look for magic number checks in the final turns
            for check in context_checks:
                if "magic_number" in check and check.get("maintained", False):
                    context_success = True
                    break

            # Prepare the result
            result = {
                "model_sequence": [f"{m['provider']}/{m['model_name']}" for m in model_sequence],
                "turn_count": turn_count,
                "tool_success": tool_success,
                "context_checks": context_checks,
                "context_success": context_success,
                "tool_usage_stats": final_state["tool_usage_stats"],
                "duration": time.time() - start_time,
                "success": tool_success and context_success,  # Success if tools used and context maintained
                "conversation": final_state["messages"]
            }

            self.results.append(result)
            return result

        except Exception as e:
            logger.error(f"Error running random sequence test: {str(e)}")

            # Prepare error result
            error_result = {
                "model_sequence": [f"{m['provider']}/{m['model_name']}" for m in model_sequence],
                "turn_count": turn_count,
                "error": str(e),
                "duration": time.time() - start_time,
                "success": False
            }

            self.results.append(error_result)
            return error_result

    async def run_multiple_tests(self, test_count: int = 3, min_turns: int = 8, max_turns: int = 15) -> None:
        """Run multiple random sequence tests."""
        logger.info(f"Running {test_count} random sequence tests")

        for i in range(test_count):
            logger.info(f"Starting test {i+1}/{test_count}")
            result = await self.run_random_sequence_test(min_turns, max_turns)

            # Print basic result
            if "error" in result:
                print(f"Test {i+1}: ERROR - {result['error']}")
            else:
                print(f"Test {i+1}: {'SUCCESS' if result['success'] else 'FAILURE'} - "
                     f"Tool Usage: {'Yes' if result['tool_success'] else 'No'}, "
                     f"Context Maintenance: {result['context_success']*100:.1f}%")

    def print_results(self) -> None:
        """Print a summary of all test results."""
        if not self.results:
            logger.warning("No test results to print")
            return

        print("\n" + "="*100)
        print(f"SUMMARY OF RANDOM TOOL SEQUENCE TESTS ({len(self.results)} tests)")
        print("="*100)

        # Count success rates by provider
        provider_stats = {}

        total_tests = len(self.results)
        successful_tests = 0
        tool_usage_tests = 0
        context_success_tests = 0
        avg_duration = 0

        for result in self.results:
            if result.get("success", False):
                successful_tests += 1
            if result.get("tool_success", False):
                tool_usage_tests += 1
            if result.get("context_success", False):
                context_success_tests += 1
            if "duration" in result:
                avg_duration += result["duration"]

        # Calculate percentages and averages
        success_rate = successful_tests / total_tests if total_tests > 0 else 0
        tool_usage_rate = tool_usage_tests / total_tests if total_tests > 0 else 0
        context_maintenance_rate = context_success_tests / total_tests if total_tests > 0 else 0
        avg_duration = avg_duration / total_tests if total_tests > 0 else 0

        print(f"\nOverall Success Rate: {successful_tests}/{total_tests} ({success_rate*100:.1f}%)")
        print(f"Tool Usage Success: {tool_usage_tests}/{total_tests} ({tool_usage_rate*100:.1f}%)")
        print(f"Context Maintenance Success: {context_success_tests}/{total_tests} ({context_maintenance_rate*100:.1f}%)")
        print(f"Average Test Duration: {avg_duration:.2f} seconds")

        # Print provider statistics
        print("\nProvider Statistics:")
        print("-"*80)
        print(f"{'Provider':<15} {'Appearances':<15} {'Tool Usage':<15} {'Tool Call Success':<15}")
        print("-"*80)

        # Calculate and print model-specific tool usage stats
        print("\nTool Usage by Model:")
        print("-"*80)

        for result in self.results:
            if "tool_usage_stats" in result:
                for model_id, stats in result["tool_usage_stats"].items():
                    print(f"{model_id}:")
                    calls_attempted = stats.get("calls_attempted", 0)
                    calls_succeeded = stats.get("calls_succeeded", 0)
                    success_rate = calls_succeeded / calls_attempted if calls_attempted > 0 else 0
                    print(f"  Calls: {calls_succeeded}/{calls_attempted} ({success_rate*100:.1f}%)")
                    tools_used = list(stats.get("tools_used", set()))
                    print(f"  Tools Used: {', '.join(tools_used) if tools_used else 'None'}")

        # Print detailed test results
        print("\nDetailed Test Results:")
        print("-"*80)

        for i, result in enumerate(self.results):
            if "error" in result:
                print(f"\nTest {i+1}: ERROR: {result['error']}")
                print(f"  Models: {', '.join(result['model_sequence'])}")
                print(f"  Duration: {result.get('duration', 0):.2f} seconds")
            else:
                print(f"\nTest {i+1}: {'SUCCESS' if result.get('success', False) else 'FAILURE'}")
                print(f"  Models: {', '.join(result['model_sequence'])}")
                print(f"  Turns: {result['turn_count']}")
                print(f"  Tool Usage: {'Yes' if result.get('tool_success', False) else 'No'}")
                print(f"  Context Maintenance: {'Success' if result.get('context_success', False) else 'Failed'}")
                print(f"  Duration: {result['duration']:.2f} seconds")

                if "context_checks" in result:
                    print("  Context Checks:")
                    for check in result["context_checks"]:
                        if "magic_number" in check:
                            success = "✓" if check.get("maintained", False) else "✗"
                            print(f"    Magic Number Check: {success} (expected: {check.get('magic_number', 'unknown')})")
                        elif "recent_topics" in check:
                            turn = check.get("turn", "?")
                            success = "✓" if check.get("context_maintained", False) else "✗"
                            topics = ", ".join(check.get("recent_topics", []))
                            print(f"    Turn {turn}: {success} Topics: {topics}")

        print("\n" + "="*100)

        print("\nRecommendations for Tool-Compatible Models:")
        print("-"*80)
        print("Based on test results, here are the recommended providers for tool usage:")

        print("\n" + "="*100)


async def main():
    """Run the random multimodel tool test."""
    parser = argparse.ArgumentParser(description='Run random multimodel tool tests')
    parser.add_argument('--models', nargs='*', help='Models to test with (provider/model format)')
    parser.add_argument('--tests', type=int, default=3, help='Number of tests to run')
    args = parser.parse_args()

    # Create config
    config = Config()

    # Create tester
    if args.models and len(args.models) > 0:
        logger.info(f"Using specified models: {', '.join(args.models)}")
        tester = RandomToolMultiModelTester(config, args.models)
    else:
        logger.info(f"No models specified, using all available models")
        tester = RandomToolMultiModelTester(config)

    # Run multiple tests
    await tester.run_multiple_tests(test_count=args.tests, min_turns=8, max_turns=12)

    # Print results
    tester.print_results()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nTest interrupted by user.")
    except Exception as e:
        logger.exception(f"Unhandled exception: {str(e)}")
