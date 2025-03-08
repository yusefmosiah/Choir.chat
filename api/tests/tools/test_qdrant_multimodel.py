"""Tests for Qdrant tools with multiple models in conversation sequences.

This module tests the Qdrant vector database tools in complex multi-model
conversation scenarios to ensure they work across different model providers.
"""

import uuid
import random
import logging
import pytest
from typing import Dict, List, Any, Optional, Type, TypedDict, Literal

from langchain_core.tools import BaseTool
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, BaseMessage
from langgraph.prebuilt import ToolNode
from langgraph.graph import StateGraph, START, END, MessagesState

from app.config import Config
from app.tools.qdrant import qdrant_search, qdrant_store, qdrant_delete
from app.tools.qdrant_workflow import create_qdrant_workflow
from app.langchain_utils import initialize_tool_compatible_model_list, ModelConfig

logger = logging.getLogger(__name__)


class RandomToolMultiModelTester:
    """Tester for random sequences of multi-model conversations with Qdrant tools."""

    def __init__(self, config: Config, models_to_use: Optional[List[str]] = None):
        """Initialize the tester and load available models."""
        self.config = config
        self.magic_number = "1729"  # Ramanujan number - used for context tracking

        # Determine which providers are available based on API keys


        # Get list of models known to work with tools
        all_models = initialize_tool_compatible_model_list(config)

        # Use all available tool-compatible models
        self.models = all_models

        # If models specified, filter to only those
        if models_to_use:
            self.models = [m for m in self.models if f"{m.provider}/{m.model_name}" in models_to_use]

        # Set up prompts for Qdrant tools
        self.initial_prompts = [
            "I'd like to store some information in your vector database for later retrieval.",
            "I have some facts about the Post Chain architecture I need to save.",
            "Can you help me use the vector database to store and retrieve information?",
            "I need to keep track of some important information in your memory system."
        ]

        self.follow_up_prompts = [
            "Can you search for the information I just stored?",
            "Please use the qdrant_search tool to find what I saved earlier.",
            "I need to find something related to what we stored. Can you search for it?",
            "Let's search the vector database for the information we just saved."
        ]

        self.results = []

        # Log available models and disabled providers
        logger.info(f"Initialized with {len(self.models)} tool-compatible models")
        for model in self.models:
            logger.info(f"  {model.provider}/{model.model_name}")

    def generate_random_model_sequence(self, min_models: int = 3, max_models: int = 5) -> List[ModelConfig]:
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

        # Try to include at least one model from each provider if possible
        for provider in providers:
            if models_by_provider[provider]:
                model = random.choice(models_by_provider[provider])
                sequence.append(model)

        # If we only have one model, duplicate it to reach min_models
        if len(self.models) == 1 and min_models > 1:
            while len(sequence) < min_models:
                sequence.append(self.models[0])
        # Otherwise fill remaining slots with random models
        else:
            while len(sequence) < sequence_length:
                provider = random.choice(providers)
                if models_by_provider[provider]:
                    model = random.choice(models_by_provider[provider])
                    sequence.append(model)

        # Shuffle the sequence for randomness
        random.shuffle(sequence)

        return sequence

    async def run_test_with_tools(self, tools: List[BaseTool], min_turns: int = 3, max_turns: int = 5) -> Dict[str, Any]:
        """Run a test with the specified tools using a random model sequence."""
        # Generate a random sequence of models
        model_sequence = self.generate_random_model_sequence()

        if not model_sequence:
            return {"error": "No suitable models available for testing"}

        # Create a random number of conversation turns
        turn_count = random.randint(min_turns, max_turns)

        # Create unique test content with the magic number for context tracking
        test_content = f"Vector DB test content {self.magic_number} {uuid.uuid4()}"

        # Start with system message
        messages = [
            SystemMessage(content=(
                "You are a helpful assistant with access to vector database tools. "
                "You can store, search, and delete information as needed. "
                f"The magic number is {self.magic_number} - remember it throughout the conversation."
            ))
        ]

        # Keep track of tool usage and context maintenance
        tool_success = False
        context_maintenance_checks = []
        stored_vector_id = None

        try:
            # Run through conversation turns
            logger.info(f"Starting test with {len(model_sequence)} models for {turn_count} turns")

            for turn in range(turn_count):
                # Select model for this turn
                model_idx = turn % len(model_sequence)
                model_config = model_sequence[model_idx]
                logger.info(f"Turn {turn+1}/{turn_count} - Using model: {model_config}")

                # Create prompt for this turn
                if turn == 0:
                    # First turn - store something
                    prompt = f"{random.choice(self.initial_prompts)} Please store this exact text: '{test_content}'"
                    messages.append(HumanMessage(content=prompt))
                elif turn == 1:
                    # Second turn - search for what we stored
                    prompt = f"{random.choice(self.follow_up_prompts)} Look for: {test_content[:20]}"
                    messages.append(HumanMessage(content=prompt))
                elif turn == 2 and stored_vector_id:
                    # Third turn - delete if we have an ID
                    prompt = f"Please delete the vector with ID: {stored_vector_id}"
                    messages.append(HumanMessage(content=prompt))
                else:
                    # Other turns - mix of operations
                    operation = random.choice(["store", "search", "context_check"])

                    if operation == "store":
                        new_content = f"Additional content {uuid.uuid4()} with magic number {self.magic_number}"
                        prompt = f"Store this new information: '{new_content}'"
                    elif operation == "search":
                        prompt = f"Search for information containing the magic number {self.magic_number}"
                    else:  # context_check
                        prompt = "What was the magic number I mentioned earlier?"

                    messages.append(HumanMessage(content=prompt))

                # Create workflow for this model
                workflow = create_qdrant_workflow(model_config=model_config, config=self.config)

                # Get response
                try:
                    result = await workflow.ainvoke({"messages": messages})

                    # Update messages with model response
                    messages = result["messages"]

                    # Check for tool usage
                    last_message = messages[-1]
                    if isinstance(last_message, AIMessage):
                        # Extract vector ID if stored
                        if "Successfully stored" in last_message.content and "ID:" in last_message.content:
                            try:
                                stored_vector_id = last_message.content.split("ID:")[1].strip()
                                logger.info(f"Extracted vector ID: {stored_vector_id}")
                                tool_success = True
                            except Exception as e:
                                logger.warning(f"Could not extract vector ID: {e}")

                        # Check if search found content
                        if test_content in last_message.content:
                            logger.info("Search found the test content")
                            tool_success = True

                        # Check for context maintenance
                        if self.magic_number in last_message.content:
                            context_maintenance_checks.append({
                                "turn": turn,
                                "model": str(model_config),
                                "maintained": True
                            })
                        else:
                            context_maintenance_checks.append({
                                "turn": turn,
                                "model": str(model_config),
                                "maintained": False
                            })

                except Exception as e:
                    logger.error(f"Error during turn {turn+1}: {str(e)}")
                    messages.append(AIMessage(content=f"Error: {str(e)}"))

            # Calculate context maintenance rate
            context_success_rate = 0
            if context_maintenance_checks:
                maintained_count = sum(1 for check in context_maintenance_checks if check["maintained"])
                context_success_rate = maintained_count / len(context_maintenance_checks)

            # Return results
            return {
                "success": True,
                "tool_success": tool_success,
                "context_maintenance_rate": context_success_rate,
                "context_checks": context_maintenance_checks,
                "model_sequence": [str(model) for model in model_sequence],
                "turn_count": turn_count,
                "messages": [
                    {"role": "system" if isinstance(msg, SystemMessage) else
                             "user" if isinstance(msg, HumanMessage) else
                             "assistant",
                     "content": msg.content[:100] + "..." if len(msg.content) > 100 else msg.content}
                    for msg in messages
                ]
            }

        except Exception as e:
            logger.error(f"Test failed with error: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "model_sequence": [str(model) for model in model_sequence],
                "turn_count": turn_count
            }

    async def run_multiple_tests_with_tools(
        self,
        tools: List[BaseTool],
        test_count: int = 3,
        min_turns: int = 3,
        max_turns: int = 5
    ) -> Dict[str, Any]:
        """Run multiple tests with the provided tools and collect metrics."""
        logger.info(f"Running {test_count} tests with Qdrant tools")

        all_results = []
        metrics = {
            "total_tests": test_count,
            "successful_tests": 0,
            "tool_success_count": 0,
            "total_context_checks": 0,
            "successful_context_checks": 0
        }

        for i in range(test_count):
            logger.info(f"Starting test {i+1}/{test_count}")
            result = await self.run_test_with_tools(tools, min_turns, max_turns)
            all_results.append(result)

            if result.get("success", False):
                metrics["successful_tests"] += 1

                if result.get("tool_success", False):
                    metrics["tool_success_count"] += 1

                # Track context maintenance
                context_checks = result.get("context_checks", [])
                metrics["total_context_checks"] += len(context_checks)
                metrics["successful_context_checks"] += sum(1 for check in context_checks if check.get("maintained", False))

        # Calculate rates
        metrics["test_success_rate"] = metrics["successful_tests"] / metrics["total_tests"] if metrics["total_tests"] > 0 else 0
        metrics["tool_success_rate"] = metrics["tool_success_count"] / metrics["successful_tests"] if metrics["successful_tests"] > 0 else 0
        metrics["context_maintenance_rate"] = metrics["successful_context_checks"] / metrics["total_context_checks"] if metrics["total_context_checks"] > 0 else 0

        # Store results for later reporting
        self.results = all_results

        return {
            "detailed_results": all_results,
            **metrics
        }

    def print_results(self) -> None:
        """Print a summary of test results."""
        if not self.results:
            print("No test results available")
            return

        # Count successes
        successful_tests = sum(1 for result in self.results if result.get("success", False))
        tool_successes = sum(1 for result in self.results if result.get("tool_success", False))

        # Calculate context maintenance
        context_checks = []
        for result in self.results:
            context_checks.extend(result.get("context_checks", []))

        successful_checks = sum(1 for check in context_checks if check.get("maintained", False))
        context_maintenance_rate = successful_checks / len(context_checks) if context_checks else 0

        print("\n===== Random Multi-Model Test Results =====")
        print(f"Total Tests: {len(self.results)}")
        print(f"Successful Tests: {successful_tests}/{len(self.results)} ({successful_tests/len(self.results)*100:.1f}%)")
        print(f"Tool Success Rate: {tool_successes}/{successful_tests} ({tool_successes/successful_tests*100:.1f}% of successful tests)")
        print(f"Context Maintenance: {successful_checks}/{len(context_checks)} ({context_maintenance_rate*100:.1f}%)")

        # Models used
        models_used = set()
        for result in self.results:
            models_used.update(result.get("model_sequence", []))

        print(f"\nModels used: {len(models_used)}")
        for model in sorted(models_used):
            print(f"  - {model}")

        # Print individual test results
        print("\nIndividual Test Results:")
        for i, result in enumerate(self.results):
            if result.get("success", False):
                print(f"Test {i+1}: ✅ Success")
                print(f"  Tool Success: {'✅' if result.get('tool_success', False) else '❌'}")
                print(f"  Context Rate: {result.get('context_maintenance_rate', 0)*100:.1f}%")
                print(f"  Models: {', '.join(result.get('model_sequence', []))[:50]}...")
            else:
                print(f"Test {i+1}: ❌ Failed - {result.get('error', 'Unknown error')}")


@pytest.mark.asyncio
async def test_qdrant_random_multimodel():
    """Test Qdrant tools in a random multi-model conversation."""
    config = Config()
    logging.basicConfig(level=logging.INFO)

    # Create a RandomToolMultiModelTester instance
    tester = RandomToolMultiModelTester(config)

    # Skip test if not enough models are available
    if len(tester.models) < 2:
        pytest.skip("At least 2 tool-compatible models are required for this test")

    # Add Qdrant tools
    qdrant_tools = [qdrant_search, qdrant_store, qdrant_delete]

    # Run multiple random sequence tests
    results = await tester.run_multiple_tests_with_tools(
        tools=qdrant_tools,
        test_count=2,  # Reduced for faster testing
        min_turns=3,
        max_turns=5
    )

    # Print the results
    tester.print_results()

    # Verify essential metrics
    assert results["test_success_rate"] > 0.5, "Less than 50% of tests completed successfully"
    assert results["tool_success_rate"] > 0.5, "Tools were used successfully in less than 50% of tests"
    assert results["context_maintenance_rate"] > 0.5, "Context was maintained in less than 50% of checks"


if __name__ == "__main__":
    import asyncio
    logging.basicConfig(level=logging.INFO)
    asyncio.run(test_qdrant_random_multimodel())
