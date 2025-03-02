"""
Test script to verify multi-model conversation capabilities using LangGraph with random model selection.
This tests the ability of different models to maintain context in a longer conversation chain (5-20 turns).

The test randomly selects a sequence of models from different providers and uses random prompts
from random_gen_prompts.md to drive the conversation, measuring how well context is maintained
throughout the entire sequence.
"""

import asyncio
import logging
import random
import re
import os
import sys
from typing import Dict, Any, List, Optional, TypedDict, Literal, Set, Tuple
from dataclasses import dataclass

from langgraph.graph import StateGraph, END
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage

from app.config import Config
from app.langchain_utils import abstract_llm_completion

from tests.postchain.test_providers import (
    get_openai_models,
    get_anthropic_models,
    get_google_models,
    get_mistral_models,
    get_fireworks_models,
    get_cohere_models
)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class RandomMultiModelState(TypedDict):
    """State representation for the random multi-model conversation test."""
    messages: List[Dict[str, str]]          # List of messages in the conversation
    current_turn: int                       # Current turn in the conversation
    turn_count: int                         # Total number of turns to perform
    model_sequence: List[Dict[str, str]]    # Sequence of models to use for each turn
    current_model_idx: int                  # Index of the current model in the sequence
    model_responses: Dict[str, List[str]]   # Responses from each model (keyed by provider/model)
    prompts_used: List[str]                 # List of prompts used in the conversation
    magic_number: str                       # The magic number to test context retention
    context_checks: List[Dict[str, Any]]    # List of context check results

@dataclass
class ModelConfig:
    """Configuration for a specific model."""
    provider: str
    model_name: str

    def __str__(self):
        return f"{self.provider}/{self.model_name}"

    def as_dict(self):
        return {
            "provider": self.provider,
            "model_name": self.model_name
        }

def create_random_multimodel_graph(config: Config):
    """Create a LangGraph for random multi-model conversation testing."""
    graph = StateGraph(RandomMultiModelState)

    async def process_user_message(state: RandomMultiModelState) -> RandomMultiModelState:
        """Process the user message based on the current turn."""
        new_state = state.copy()

        # For the first message, include the magic number
        if state["current_turn"] == 0:
            magic_number = state["magic_number"]
            prompt = f"The magic number is {magic_number}. Remember this number for later. " + state["prompts_used"][0]
            new_state["messages"].append({
                "role": "user",
                "content": prompt
            })
        # For a middle turn, use the next prompt from the sequence
        elif state["current_turn"] < state["turn_count"] - 1:
            prompt_index = state["current_turn"]
            prompt = state["prompts_used"][prompt_index]
            new_state["messages"].append({
                "role": "user",
                "content": prompt
            })
        # For the last turn, ask about the magic number
        else:
            new_state["messages"].append({
                "role": "user",
                "content": "What was the magic number I mentioned at the start of our conversation? Please include it in your response."
            })

        return new_state

    async def generate_model_response(state: RandomMultiModelState) -> RandomMultiModelState:
        """Generate a response from the current model in the sequence."""
        new_state = state.copy()

        # Get the current model configuration
        current_model = state["model_sequence"][state["current_model_idx"]]
        provider = current_model["provider"]
        model_name = current_model["model_name"]
        model_key = f"{provider}/{model_name}"

        logger.info(f"Turn {state['current_turn']+1}/{state['turn_count']}: Generating response from {model_key}")

        try:
            # Use the abstraction layer to generate a response
            response = await abstract_llm_completion(
                model_name=model_key,
                messages=state['messages'],
                config=config,
                temperature=0.3  # Lower temperature for more consistent responses
            )

            if response["status"] == "success":
                # Add the AI response to the messages
                content = response["content"]
                new_state["messages"].append({"role": "assistant", "content": content})

                # Store the response for this model
                if model_key not in new_state["model_responses"]:
                    new_state["model_responses"][model_key] = []
                new_state["model_responses"][model_key].append(content)

                # Check for context maintenance - look for the magic number
                if state["current_turn"] == state["turn_count"] - 1:
                    magic_number = state["magic_number"]
                    context_maintained = magic_number in content

                    # Record the context check
                    new_state["context_checks"].append({
                        "turn": state["current_turn"],
                        "model": model_key,
                        "maintained": context_maintained,
                        "magic_number": magic_number,
                        "response_preview": content[:150] + "..." if len(content) > 150 else content
                    })

                # Move to the next model and turn
                new_state["current_model_idx"] = (state["current_model_idx"] + 1) % len(state["model_sequence"])
                new_state["current_turn"] += 1
            else:
                # Handle error in model response
                error_message = f"Error from {provider}/{model_name}: {response['content']}"
                logger.error(error_message)
                new_state["messages"].append({"role": "assistant", "content": error_message})

                if model_key not in new_state["model_responses"]:
                    new_state["model_responses"][model_key] = []
                new_state["model_responses"][model_key].append(error_message)

                # Move to the next model and turn even if there's an error
                new_state["current_model_idx"] = (state["current_model_idx"] + 1) % len(state["model_sequence"])
                new_state["current_turn"] += 1
        except Exception as e:
            # Handle exceptions
            error_message = f"Exception when calling {provider}/{model_name}: {str(e)}"
            logger.error(error_message)
            new_state["messages"].append({"role": "assistant", "content": error_message})

            if model_key not in new_state["model_responses"]:
                new_state["model_responses"][model_key] = []
            new_state["model_responses"][model_key].append(error_message)

            # Move to the next model and turn even if there's an exception
            new_state["current_model_idx"] = (state["current_model_idx"] + 1) % len(state["model_sequence"])
            new_state["current_turn"] += 1

        return new_state

    def should_continue(state: RandomMultiModelState) -> Literal["continue", "end"]:
        """Determine whether to continue the conversation or end it."""
        if state["current_turn"] < state["turn_count"]:
            return "continue"
        return "end"

    # Set up the states and transitions
    graph.add_node("process_user_message", process_user_message)
    graph.add_node("generate_model_response", generate_model_response)

    # Define the edges
    graph.add_edge("process_user_message", "generate_model_response")
    graph.add_conditional_edges(
        "generate_model_response",
        should_continue,
        {
            "continue": "process_user_message",
            "end": END
        }
    )

    # Set the entry point
    graph.set_entry_point("process_user_message")

    return graph.compile()  # Make sure to compile the graph

class RandomMultiModelTester:
    """Test multi-model conversation capabilities with random model sequences."""

    def __init__(self, config: Config):
        self.config = config
        self.all_models: List[ModelConfig] = []
        self.results: List[Dict[str, Any]] = []
        self.prompts: List[str] = []
        self.system_prompt = "You are a helpful assistant in a conversation with the user and potentially other AI assistants. Be clear, concise, and maintain awareness of the conversation history."
        self.magic_number = "1729"  # Ramanujan number

    def load_prompts(self):
        """Load conversation prompts from the random_gen_prompts.md file."""
        try:
            # Get the directory of the current script
            current_dir = os.path.dirname(os.path.abspath(__file__))
            prompts_file = os.path.join(current_dir, "random_gen_prompts.md")

            with open(prompts_file, "r") as f:
                content = f.read()

            # Extract prompts using regex
            matches = re.findall(r'\d+\.\s+"(.*?)"', content)
            if matches:
                self.prompts = matches
                logger.info(f"Loaded {len(self.prompts)} prompts from random_gen_prompts.md")
            else:
                # Fallback prompts if file parsing fails
                self.prompts = [
                    "Tell me about an interesting scientific concept.",
                    "What are your thoughts on artificial intelligence?",
                    "Explain a complex topic in simple terms.",
                    "Share an interesting historical fact.",
                    "What's your perspective on technological progress?",
                    "Describe a philosophical dilemma.",
                    "Tell me about a fascinating natural phenomenon.",
                    "What are some emerging trends in technology?",
                    "Explain how something in daily life works.",
                    "Share some insights about human psychology."
                ]
                logger.warning(f"Failed to parse prompts from file. Using {len(self.prompts)} fallback prompts.")
        except Exception as e:
            logger.error(f"Error loading prompts: {str(e)}")
            # Fallback prompts if file is missing
            self.prompts = [
                "Tell me about an interesting scientific concept.",
                "What are your thoughts on artificial intelligence?",
                "Explain a complex topic in simple terms.",
                "Share an interesting historical fact.",
                "What's your perspective on technological progress?",
                "Describe a philosophical dilemma.",
                "Tell me about a fascinating natural phenomenon.",
                "What are some emerging trends in technology?",
                "Explain how something in daily life works.",
                "Share some insights about human psychology."
            ]
            logger.warning(f"Using {len(self.prompts)} fallback prompts due to error.")

    def initialize_model_list(self):
        """Initialize the list of available models from all providers."""
        # OpenAI models
        if self.config.OPENAI_API_KEY:
            for model_name in get_openai_models(self.config):
                self.all_models.append(ModelConfig("openai", model_name))

        # Anthropic models
        if self.config.ANTHROPIC_API_KEY:
            for model_name in get_anthropic_models(self.config):
                self.all_models.append(ModelConfig("anthropic", model_name))

        # Google models
        if self.config.GOOGLE_API_KEY:
            for model_name in get_google_models(self.config):
                self.all_models.append(ModelConfig("google", model_name))

        # Mistral models
        if self.config.MISTRAL_API_KEY:
            for model_name in get_mistral_models(self.config):
                self.all_models.append(ModelConfig("mistral", model_name))

        # Fireworks models
        if self.config.FIREWORKS_API_KEY:
            for model_name in get_fireworks_models(self.config):
                self.all_models.append(ModelConfig("fireworks", model_name))

        # Cohere models
        if self.config.COHERE_API_KEY:
            for model_name in get_cohere_models(self.config):
                self.all_models.append(ModelConfig("cohere", model_name))

        logger.info(f"Initialized {len(self.all_models)} models for testing")

    def generate_random_model_sequence(self, min_turns: int = 5, max_turns: int = 20) -> Tuple[List[ModelConfig], int]:
        """Generate a random sequence of models for the conversation.

        Returns:
            A tuple of (list of models, turn count)
        """
        if not self.all_models:
            self.initialize_model_list()

        # Determine the number of turns for this test
        turn_count = random.randint(min_turns, max_turns)

        # Select random models for each turn, ensuring different providers when possible
        model_sequence = []
        used_providers: Set[str] = set()

        for _ in range(turn_count):
            # Prioritize unused providers if available
            unused_models = [m for m in self.all_models if m.provider not in used_providers]

            if unused_models and len(used_providers) < len(set(m.provider for m in self.all_models)):
                # Select a model from an unused provider
                selected_model = random.choice(unused_models)
            else:
                # All providers used at least once, select any model
                selected_model = random.choice(self.all_models)

            model_sequence.append(selected_model)
            used_providers.add(selected_model.provider)

        return model_sequence, turn_count

    async def run_random_sequence_test(self, min_turns: int = 5, max_turns: int = 20) -> Dict[str, Any]:
        """Run a test with a random sequence of models."""
        self.initialize_model_list()
        if not self.prompts:
            self.load_prompts()

        # Generate a random model sequence
        model_sequence, turn_count = self.generate_random_model_sequence(min_turns, max_turns)

        # Select random prompts for each turn (need turn_count prompts)
        selected_prompts = random.sample(self.prompts, turn_count) if len(self.prompts) >= turn_count else \
                           random.choices(self.prompts, k=turn_count)

        model_sequence_str = " → ".join([str(model) for model in model_sequence])
        logger.info(f"Running random sequence test with {turn_count} turns")
        logger.info(f"Model sequence: {model_sequence_str}")

        try:
            # Initialize the conversation state
            initial_state: RandomMultiModelState = {
                "messages": [{"role": "system", "content": self.system_prompt}],
                "current_turn": 0,
                "turn_count": turn_count,
                "model_sequence": [model.as_dict() for model in model_sequence],
                "current_model_idx": 0,
                "model_responses": {},
                "prompts_used": selected_prompts,
                "magic_number": self.magic_number,
                "context_checks": []
            }

            # Create and run the graph
            graph = create_random_multimodel_graph(self.config)
            final_state = await graph.ainvoke(initial_state)  # Changed from arun to ainvoke

            # Extract results
            context_maintained = False
            if final_state["context_checks"]:
                context_maintained = final_state["context_checks"][-1]["maintained"]

            # Create a summary of model usage
            model_usage = {}
            for model_key, responses in final_state["model_responses"].items():
                model_usage[model_key] = len(responses)

            # Count how many turns were completed successfully
            successful_turns = sum(len(responses) for responses in final_state["model_responses"].values())

            return {
                "status": "success",
                "turn_count": turn_count,
                "completed_turns": successful_turns,
                "model_sequence": [str(model) for model in model_sequence],
                "context_maintained": context_maintained,
                "magic_number": self.magic_number,
                "model_usage": model_usage,
                "prompts_used": selected_prompts,
                "context_checks": final_state["context_checks"],
                "full_conversation": final_state["messages"]
            }
        except Exception as e:
            logger.error(f"Error in random sequence test: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "turn_count": turn_count,
                "model_sequence": [str(model) for model in model_sequence],
                "context_maintained": False,
                "magic_number": self.magic_number
            }

    async def run_multiple_tests(self, test_count: int = 5, min_turns: int = 5, max_turns: int = 20) -> None:
        """Run multiple random sequence tests."""
        self.results = []

        for i in range(test_count):
            logger.info(f"Running test {i+1}/{test_count}")
            result = await self.run_random_sequence_test(min_turns, max_turns)
            self.results.append(result)

        self.print_results()

    def print_results(self) -> None:
        """Print test results in a readable format."""
        if not self.results:
            logger.info("No test results available. Run tests first.")
            return

        logger.info("\n" + "="*100)
        logger.info("RANDOM MULTI-MODEL CONVERSATION TEST RESULTS")
        logger.info("="*100)

        successful_tests = 0
        context_maintained_tests = 0
        total_tests = len(self.results)

        for i, result in enumerate(self.results):
            logger.info(f"\nTest {i+1}/{total_tests}:")
            logger.info("-"*100)

            if result.get("status") == "success":
                successful_tests += 1

                # Print basic test info
                turn_count = result.get("turn_count", 0)
                completed_turns = result.get("completed_turns", 0)
                context_maintained = result.get("context_maintained", False)
                if context_maintained:
                    context_maintained_tests += 1

                logger.info(f"Turns: {completed_turns}/{turn_count} completed")
                logger.info(f"Context maintained: {'✅ Yes' if context_maintained else '❌ No'}")

                # Print model sequence
                model_sequence = result.get("model_sequence", [])
                logger.info(f"Model sequence: {' → '.join(model_sequence)}")

                # Print conversation highlights
                context_checks = result.get("context_checks", [])
                if context_checks:
                    final_check = context_checks[-1]
                    logger.info(f"Final model: {final_check['model']}")
                    logger.info(f"Final response: {final_check['response_preview']}")

                # Print all prompts briefly
                prompts = result.get("prompts_used", [])
                if prompts:
                    logger.info("\nPrompts used:")
                    for j, prompt in enumerate(prompts):
                        if j < 3 or j == len(prompts) - 1:  # Show first 3 and last prompt
                            logger.info(f"  {j+1}: {prompt[:50]}..." if len(prompt) > 50 else f"  {j+1}: {prompt}")
                        elif j == 3:
                            logger.info(f"  ... ({len(prompts) - 4} more prompts) ...")
            else:
                logger.info(f"❌ Test failed: {result.get('error', 'Unknown error')}")

            logger.info("-"*100)

        # Overall summary
        logger.info("\nOverall Summary:")
        logger.info(f"Total Tests: {total_tests}")
        logger.info(f"Successful Tests: {successful_tests}")
        logger.info(f"Context Maintained: {context_maintained_tests}/{successful_tests} " +
                    f"({context_maintained_tests/successful_tests*100:.2f}% of successful tests)" if successful_tests else "N/A")
        logger.info(f"Success Rate: {successful_tests/total_tests*100:.2f}%")
        logger.info("="*100)

async def main():
    """Run the random multi-model conversation tests."""
    config = Config()
    tester = RandomMultiModelTester(config)

    # Run 3 random tests with 5-10 turns each
    await tester.run_multiple_tests(test_count=3, min_turns=5, max_turns=10)

if __name__ == "__main__":
    asyncio.run(main())
