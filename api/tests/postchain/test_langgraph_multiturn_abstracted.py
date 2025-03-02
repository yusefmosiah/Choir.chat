"""
Test script to verify multi-turn conversation capabilities using LangGraph and the abstraction layer.
This tests the ability of models to maintain context across multiple turns using a LangGraph implementation.

The test uses a prompt chain format:
<user="hello"><ai><user="the magic number is 1729"><ai><user="whats the magic number"><ai_response_contains~="1729">
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional, TypedDict, Literal

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

class ConversationState(TypedDict):
    """State representation for the multi-turn conversation test."""
    messages: List[Dict[str, str]]  # List of messages in the conversation
    current_turn: int               # Current turn in the conversation
    expected_content: str           # Content we expect to see in the final response
    model_name: str                 # Name of the model being tested
    provider: str                   # Provider of the model being tested
    final_response: Optional[str]   # The final response from the model

def create_conversation_graph(model_name: str, config: Config):
    """Create a LangGraph for multi-turn conversation testing using the abstraction layer."""
    graph = StateGraph(ConversationState)

    async def process_user_message(state: ConversationState) -> ConversationState:
        """Process the user message and update the state at each turn."""
        current_turn = state["current_turn"]
        new_state = state.copy()

        logger.info(f"Processing user message at turn {current_turn} for {state['provider']}/{state['model_name']}")

        # Add user message based on the current turn
        if current_turn == 0:
            new_state["messages"].append({"role": "user", "content": "hello"})
        elif current_turn == 1:
            new_state["messages"].append({"role": "user", "content": "the magic number is 1729"})
        elif current_turn == 2:
            new_state["messages"].append({"role": "user", "content": "whats the magic number again? repeat it. this is a multi-turn chat context test."})

        return new_state

    async def generate_ai_response(state: ConversationState) -> ConversationState:
        """Generate an AI response using the abstraction layer."""
        new_state = state.copy()

        logger.info(f"Generating AI response at turn {state['current_turn']} using {state['provider']}/{state['model_name']}")

        try:
            # Use the abstraction layer to generate a response
            response = await abstract_llm_completion(
                model_name=f"{state['provider']}/{state['model_name']}",
                messages=state['messages'],
                config=config,
                temperature=0  # Use deterministic responses for testing
            )

            if response["status"] == "success":
                # Add the AI response to the messages
                new_state["messages"].append({"role": "assistant", "content": response["content"]})

                # If this is the final turn, store the response for validation
                if state["current_turn"] == 2:
                    new_state["final_response"] = response["content"]
            else:
                # Handle error in model response
                error_message = f"Error: {response['content']}"
                new_state["messages"].append({"role": "assistant", "content": error_message})
                new_state["final_response"] = error_message

        except Exception as e:
            # Handle any exceptions during response generation
            error_message = f"Exception: {str(e)}"
            new_state["messages"].append({"role": "assistant", "content": error_message})
            new_state["final_response"] = error_message
            logger.error(f"Error in generate_ai_response: {str(e)}")

        # Increment the turn counter
        new_state["current_turn"] = state["current_turn"] + 1

        return new_state

    def should_continue(state: ConversationState) -> Literal["continue", "end"]:
        """Determine if we should continue the conversation or end it."""
        if state["current_turn"] >= 3:
            return END
        return "continue"

    # Set up the graph structure
    graph.add_node("process_user_message", process_user_message)
    graph.add_node("generate_ai_response", generate_ai_response)

    # Set the entry point and define edges
    graph.set_entry_point("process_user_message")
    graph.add_edge("process_user_message", "generate_ai_response")
    graph.add_conditional_edges("generate_ai_response", should_continue, {
        "continue": "process_user_message",
        END: END
    })

    return graph.compile()

class AbstractedLangGraphMultiTurnTester:
    """Test multi-turn conversation capabilities using the abstraction layer."""

    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, List[Dict[str, Any]]] = {}
        self.system_prompt = "You are a helpful assistant."
        self.expected_content = "1729"

    async def test_model(self, provider: str, model_name: str) -> Dict[str, Any]:
        """Test a specific model using the abstraction layer with LangGraph."""
        try:
            logger.info(f"Testing multi-turn conversation with {provider}/{model_name}")

            # Initialize the conversation state
            initial_state: ConversationState = {
                "messages": [{"role": "system", "content": self.system_prompt}],
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": provider,
                "final_response": None
            }

            # Create and run the graph
            graph = create_conversation_graph(model_name, self.config)
            final_state = await graph.ainvoke(initial_state)

            # Check if the final response contains the expected content
            success = False
            if final_state["final_response"]:
                success = self.expected_content in final_state["final_response"]

            return {
                "status": "success" if success else "failure",
                "model": model_name,
                "provider": provider,
                "final_response": final_state["final_response"],
                "contains_expected": success
            }
        except Exception as e:
            logger.error(f"Error testing {provider}/{model_name}: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "model": model_name,
                "provider": provider,
                "final_response": None,
                "contains_expected": False
            }

    async def test_provider_models(self, provider: str, models: List[str]) -> List[Dict[str, Any]]:
        """Test all models for a specific provider."""
        if not models:
            return [{"status": "skipped", "reason": "No models configured", "provider": provider}]

        results = []
        for model_name in models:
            result = await self.test_model(provider, model_name)
            results.append(result)
        return results

    async def test_openai(self) -> List[Dict[str, Any]]:
        """Test OpenAI models."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "openai"}]
        return await self.test_provider_models("openai", get_openai_models(self.config))

    async def test_anthropic(self) -> List[Dict[str, Any]]:
        """Test Anthropic models."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "anthropic"}]
        return await self.test_provider_models("anthropic", get_anthropic_models(self.config))

    async def test_google(self) -> List[Dict[str, Any]]:
        """Test Google models."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "google"}]
        return await self.test_provider_models("google", get_google_models(self.config))

    async def test_mistral(self) -> List[Dict[str, Any]]:
        """Test Mistral models."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "mistral"}]
        return await self.test_provider_models("mistral", get_mistral_models(self.config))

    async def test_fireworks(self) -> List[Dict[str, Any]]:
        """Test Fireworks models."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "fireworks"}]
        return await self.test_provider_models("fireworks", get_fireworks_models(self.config))

    async def test_cohere(self) -> List[Dict[str, Any]]:
        """Test Cohere models."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "cohere"}]
        return await self.test_provider_models("cohere", get_cohere_models(self.config))

    async def run_all_tests(self, providers: list = None) -> Dict[str, List[Dict[str, Any]]]:
        """Run all provider tests or a subset if specified."""
        all_providers = {
            "OpenAI": self.test_openai,
            "Anthropic": self.test_anthropic,
            "Google": self.test_google,
            "Mistral": self.test_mistral,
            "Fireworks": self.test_fireworks,
            "Cohere": self.test_cohere
        }

        # Filter providers if specified
        test_providers = all_providers
        if providers:
            test_providers = {k: v for k, v in all_providers.items() if k in providers}

        # Run tests in parallel
        tasks = [func() for func in test_providers.values()]
        results = await asyncio.gather(*tasks)

        # Store results
        self.results = {provider: result for provider, result in zip(test_providers.keys(), results)}

        return self.results

    def print_results(self) -> None:
        """Print test results in a readable format."""
        if not self.results:
            logger.info("No test results available. Run tests first.")
            return

        logger.info("\n" + "="*50)
        logger.info("ABSTRACTED LANGGRAPH MULTI-TURN TEST RESULTS")
        logger.info("="*50)

        total_models = 0
        total_success = 0
        total_error = 0
        total_skipped = 0

        for provider, results_list in self.results.items():
            logger.info(f"\n{provider} Models:")
            logger.info("-"*50)

            # Check if the provider was skipped entirely
            if len(results_list) == 1 and results_list[0].get("status") == "skipped":
                logger.info(f"⚠️ {provider}: SKIPPED - {results_list[0].get('reason', 'No reason provided')}")
                total_skipped += 1
                continue

            # Process each model result
            for result in results_list:
                status = result.get("status", "unknown")
                model_name = result.get("model", "unknown")
                final_response = result.get("final_response", "No response")

                if isinstance(final_response, str):
                    final_response_preview = final_response[:100] + "..." if len(final_response) > 100 else final_response
                else:
                    final_response_preview = str(final_response)

                if status == "success":
                    logger.info(f"✅ {model_name}: SUCCESS - Response: {final_response_preview}")
                    total_success += 1
                elif status == "error":
                    logger.info(f"❌ {model_name}: ERROR - {result.get('error', 'Unknown error')}")
                    total_error += 1
                elif status == "skipped":
                    logger.info(f"⚠️ {model_name}: SKIPPED - {result.get('reason', 'No reason provided')}")
                    total_skipped += 1
                else:
                    logger.info(f"❌ {model_name}: FAILURE - Response: {final_response_preview}")
                    total_error += 1

                total_models += 1

            logger.info("-"*50)

        # Overall summary
        logger.info("\nSummary by Provider:")
        for provider, results_list in self.results.items():
            if len(results_list) == 1 and results_list[0].get("status") == "skipped":
                provider_status = "SKIPPED"
            else:
                success_count = sum(1 for r in results_list if r.get("status") == "success")
                total_count = len(results_list)
                provider_status = f"{success_count}/{total_count} models successful"

            logger.info(f"{provider}: {provider_status}")

        logger.info("\nOverall Summary:")
        logger.info(f"Total Models: {total_models}")
        logger.info(f"Successful: {total_success}")
        logger.info(f"Failed/Error: {total_error}")
        logger.info(f"Skipped: {total_skipped}")
        logger.info("="*50)

        # Compare with original implementation
        logger.info("\nComparison with Original Implementation:")
        logger.info("This test uses the abstraction layer to achieve the same results")
        logger.info("with a simpler, more maintainable implementation that handles")
        logger.info("provider-specific details automatically through langchain_utils.")
        logger.info("="*50)

async def main():
    """Run the multi-turn conversation tests using the abstraction layer."""
    # Parse command-line arguments if any
    # You can add argparse here to allow running tests for specific providers

    config = Config()
    tester = AbstractedLangGraphMultiTurnTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())
