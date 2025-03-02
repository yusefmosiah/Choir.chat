"""
Test script to verify multi-model conversation capabilities using LangGraph.
This tests the ability of different models to interact with each other in a conversation.

First test: 2-turn conversations between each pair of models across providers,
testing if the second model can recall information (a magic number) provided to the first model.
"""

import asyncio
import logging
import itertools
from typing import Dict, Any, List, Optional, TypedDict, Literal
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

class MultiModelConversationState(TypedDict):
    """State representation for the multi-model conversation test."""
    messages: List[Dict[str, str]]     # List of messages in the conversation
    current_turn: int                  # Current turn in the conversation
    turn_count: int                    # Total number of turns to perform
    model_sequence: List[Dict[str, str]]  # Sequence of models to use for each turn
    current_model_idx: int             # Index of the current model in the sequence
    final_responses: List[str]         # Final responses from each model
    magic_number: str                  # The magic number to test context retention
    context_maintained: bool           # Whether context was successfully maintained

@dataclass
class ModelConfig:
    """Configuration for a specific model."""
    provider: str
    model_name: str

    def __str__(self):
        return f"{self.provider}/{self.model_name}"

def create_multimodel_conversation_graph(config: Config):
    """Create a LangGraph for multi-model conversation testing."""
    graph = StateGraph(MultiModelConversationState)

    async def process_user_message(state: MultiModelConversationState) -> MultiModelConversationState:
        """Process the user message at the start of the conversation."""
        new_state = state.copy()

        # Initialize with a prompt containing the magic number
        if state["current_turn"] == 0:
            magic_number = state["magic_number"]
            new_state["messages"].append({
                "role": "user",
                "content": f"The magic number is {magic_number}. Explain what makes this number interesting in simple terms."
            })

        return new_state

    async def generate_model_response(state: MultiModelConversationState) -> MultiModelConversationState:
        """Generate a response from the current model in the sequence."""
        new_state = state.copy()

        # Get the current model configuration
        current_model = state["model_sequence"][state["current_model_idx"]]
        provider = current_model["provider"]
        model_name = current_model["model_name"]

        logger.info(f"Turn {state['current_turn']}: Generating response from {provider}/{model_name}")

        try:
            # Use the abstraction layer to generate a response
            response = await abstract_llm_completion(
                model_name=f"{provider}/{model_name}",
                messages=state['messages'],
                config=config,
                temperature=0  # Lower temperature for more consistent responses
            )

            if response["status"] == "success":
                # Add the AI response to the messages
                content = response["content"]
                new_state["messages"].append({"role": "assistant", "content": content})
                new_state["final_responses"].append(content)

                # For the next turn, add a follow-up question asking about the magic number
                if state["current_turn"] < state["turn_count"] - 1:
                    new_state["messages"].append({
                        "role": "user",
                        "content": "What was the magic number I mentioned earlier? Please include it in your response."
                    })

                # Check if the second model's response contains the magic number
                if state["current_turn"] == 1:
                    magic_number = state["magic_number"]
                    new_state["context_maintained"] = magic_number in content
            else:
                # Handle error in model response
                error_message = f"Error from {provider}/{model_name}: {response['content']}"
                logger.error(error_message)
                new_state["messages"].append({"role": "assistant", "content": error_message})
                new_state["final_responses"].append(error_message)

        except Exception as e:
            # Handle any exceptions during response generation
            error_message = f"Exception with {provider}/{model_name}: {str(e)}"
            logger.error(error_message)
            new_state["messages"].append({"role": "assistant", "content": error_message})
            new_state["final_responses"].append(error_message)

        # Move to the next model in the sequence
        new_state["current_model_idx"] = (state["current_model_idx"] + 1) % len(state["model_sequence"])
        # Increment the turn counter
        new_state["current_turn"] = state["current_turn"] + 1

        return new_state

    def should_continue(state: MultiModelConversationState) -> Literal["continue", "end"]:
        """Determine if we should continue the conversation or end it."""
        if state["current_turn"] >= state["turn_count"]:
            return END
        return "continue"

    # Set up the graph structure
    graph.add_node("process_user_message", process_user_message)
    graph.add_node("generate_model_response", generate_model_response)

    # Set the entry point and define edges
    graph.set_entry_point("process_user_message")
    graph.add_edge("process_user_message", "generate_model_response")
    graph.add_conditional_edges("generate_model_response", should_continue, {
        "continue": "generate_model_response",
        END: END
    })

    return graph.compile()

class SimpleMultiModelTester:
    """Test multi-model conversation capabilities."""

    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, List[Dict[str, Any]]] = {}
        self.system_prompt = "You are a helpful assistant in a conversation with other AI assistants. Be clear, concise, and build upon previous responses."
        self.turn_count = 2  # 2-turn conversations for initial test
        self.all_models: List[ModelConfig] = []
        self.magic_number = "0b10001001"  # 137 in binary

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

    async def test_model_pair(self, model1: ModelConfig, model2: ModelConfig) -> Dict[str, Any]:
        """Test a conversation between two models."""
        try:
            pair_name = f"{model1.provider}/{model1.model_name} ↔ {model2.provider}/{model2.model_name}"
            logger.info(f"Testing model pair: {pair_name}")

            # Initialize the conversation state
            initial_state: MultiModelConversationState = {
                "messages": [{"role": "system", "content": self.system_prompt}],
                "current_turn": 0,
                "turn_count": self.turn_count,
                "model_sequence": [
                    {"provider": model1.provider, "model_name": model1.model_name},
                    {"provider": model2.provider, "model_name": model2.model_name}
                ],
                "current_model_idx": 0,
                "final_responses": [],
                "magic_number": self.magic_number,
                "context_maintained": False
            }

            # Create and run the graph
            graph = create_multimodel_conversation_graph(self.config)
            final_state = await graph.ainvoke(initial_state)

            # Get results - check if both models responded and if the second model maintained context
            success = len(final_state["final_responses"]) == self.turn_count
            context_maintained = final_state.get("context_maintained", False)

            # Extract final responses for review
            responses = final_state["final_responses"]
            responses_preview = [r[:150] + "..." if len(r) > 150 else r for r in responses]

            return {
                "status": "success" if success else "failure",
                "model_pair": pair_name,
                "model1": {"provider": model1.provider, "model_name": model1.model_name},
                "model2": {"provider": model2.provider, "model_name": model2.model_name},
                "responses": responses,
                "responses_preview": responses_preview,
                "message_count": len(final_state["messages"]),
                "context_maintained": context_maintained,
                "magic_number": self.magic_number
            }
        except Exception as e:
            logger.error(f"Error testing model pair {model1} ↔ {model2}: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "model_pair": f"{model1.provider}/{model1.model_name} ↔ {model2.provider}/{model2.model_name}",
                "model1": {"provider": model1.provider, "model_name": model1.model_name},
                "model2": {"provider": model2.provider, "model_name": model2.model_name},
                "responses": [],
                "context_maintained": False,
                "magic_number": self.magic_number
            }

    async def run_all_pairs_tests(self, limit_per_provider: int = 1) -> Dict[str, List[Dict[str, Any]]]:
        """Run tests for all combinations of models."""
        self.initialize_model_list()

        # Group models by provider
        provider_models: Dict[str, List[ModelConfig]] = {}
        for model in self.all_models:
            if model.provider not in provider_models:
                provider_models[model.provider] = []
            provider_models[model.provider].append(model)

        # Limit the number of models per provider if requested
        for provider, models in provider_models.items():
            if limit_per_provider > 0 and len(models) > limit_per_provider:
                provider_models[provider] = models[:limit_per_provider]
                logger.info(f"Limiting {provider} to {limit_per_provider} models")

        # Flatten the list again
        limited_models = []
        for models in provider_models.values():
            limited_models.extend(models)

        # Generate all unique pairs
        model_pairs = list(itertools.combinations(limited_models, 2))
        logger.info(f"Testing {len(model_pairs)} unique model pairs")

        # Run tests for each model pair
        results = []
        for model1, model2 in model_pairs:
            result = await self.test_model_pair(model1, model2)
            results.append(result)

        # Group results by provider pairs
        provider_pairs: Dict[str, List[Dict[str, Any]]] = {}
        for result in results:
            model1 = result["model1"]
            model2 = result["model2"]
            provider_pair = f"{model1['provider']} ↔ {model2['provider']}"

            if provider_pair not in provider_pairs:
                provider_pairs[provider_pair] = []

            provider_pairs[provider_pair].append(result)

        self.results = provider_pairs
        return provider_pairs

    def print_results(self) -> None:
        """Print test results in a readable format."""
        if not self.results:
            logger.info("No test results available. Run tests first.")
            return

        logger.info("\n" + "="*70)
        logger.info("MULTI-MODEL CONTEXT MAINTENANCE TEST RESULTS")
        logger.info("="*70)

        total_pairs = 0
        successful_pairs = 0
        context_maintained_pairs = 0
        error_pairs = 0

        for provider_pair, results_list in self.results.items():
            logger.info(f"\n{provider_pair} Provider Pairs:")
            logger.info("-"*70)

            for result in results_list:
                status = result.get("status", "unknown")
                model_pair = result.get("model_pair", "unknown")
                context_maintained = result.get("context_maintained", False)
                magic_number = result.get("magic_number", "unknown")

                if status == "success":
                    if context_maintained:
                        logger.info(f"✅✅ {model_pair}: SUCCESS - CONTEXT MAINTAINED ({magic_number})")
                        context_maintained_pairs += 1
                    else:
                        logger.info(f"✅❌ {model_pair}: SUCCESS - CONTEXT LOST")

                    # Print responses
                    for i, response in enumerate(result.get("responses_preview", [])):
                        logger.info(f"   Response {i+1}: {response}")

                    successful_pairs += 1
                elif status == "error":
                    logger.info(f"❌ {model_pair}: ERROR - {result.get('error', 'Unknown error')}")
                    error_pairs += 1
                else:
                    logger.info(f"❌ {model_pair}: FAILURE")
                    error_pairs += 1

                total_pairs += 1
                logger.info(f"   {'=' * 50}")

            logger.info("-"*70)

        # Overall summary
        logger.info("\nOverall Summary:")
        logger.info(f"Total Model Pairs: {total_pairs}")
        logger.info(f"Successful Pairs: {successful_pairs}")
        logger.info(f"Context Maintained Pairs: {context_maintained_pairs} ({context_maintained_pairs/total_pairs*100:.2f}%)")
        logger.info(f"Failed/Error Pairs: {error_pairs}")
        logger.info(f"Success Rate: {successful_pairs/total_pairs*100:.2f}%")
        logger.info(f"Context Maintenance Rate: {context_maintained_pairs/successful_pairs*100:.2f}% of successful conversations")
        logger.info("="*70)

async def main():
    """Run the multi-model conversation tests."""
    config = Config()
    tester = SimpleMultiModelTester(config)

    # Limit to 1 model per provider for this test run (to keep it manageable)
    await tester.run_all_pairs_tests(limit_per_provider=1)
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())
