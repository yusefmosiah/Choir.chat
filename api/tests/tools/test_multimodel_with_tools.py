"""
Test multi-model conversations with tools.
"""
import asyncio
import logging
import random
import pytest
from typing import List, Dict, Any, Optional

from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list
from app.tools.calculator import CalculatorTool
from app.tools.conversation import ConversationWithTools

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MultiModelToolsTester:
    """Test multi-model conversations with tools."""

    def __init__(self, config: Config):
        """Initialize the tester.

        Args:
            config: Application configuration
        """
        self.config = config
        self.results = {}
        self.tools = []
        self.prompts = []
        self.turns_per_conversation = 3

    def setup_tools(self):
        """Setup the tools for testing."""
        # Add calculator tool
        calculator = CalculatorTool()
        self.tools.append(calculator)

        logger.info(f"Initialized {len(self.tools)} tools for testing")

    def setup_prompts(self):
        """Setup test prompts that use tools."""
        self.prompts = [
            "I need to verify a complex calculation. What is 1234567890 * 9876543210 / 123456789? Please use the calculator tool to compute this precisely, as I need an exact answer.",
            "What is the exact value of 9876543210 divided by 12345678? Please use the calculator tool for precision.",
            "Calculate 9999999 * 8888888 + 7777777. Please use the calculator tool to verify the result, as I need a precise answer.",
            "I'm trying to calculate the area of a circle with radius 123456.789. Can you use the calculator tool to compute pi * r^2 precisely?",
            "What is 15% of 987654321? Please use the calculator tool to get the exact amount.",
            "I need to calculate (987654 * 123456) / (7890 + 12345). Can you use the calculator tool to solve this precisely?"
        ]
        logger.info(f"Initialized {len(self.prompts)} prompts for testing")

    async def run_tool_conversation(self, models: List[ModelConfig], prompt_index: Optional[int] = None) -> Dict[str, Any]:
        """Run a conversation with tools.

        Args:
            models: List of models to use
            prompt_index: Optional index of prompt to use

        Returns:
            Dictionary with conversation results
        """
        # Setup tools if not already done
        if not self.tools:
            self.setup_tools()

        # Setup prompts if not already done
        if not self.prompts:
            self.setup_prompts()

        # Select a random prompt if index not provided
        if prompt_index is None:
            prompt_index = random.randint(0, len(self.prompts) - 1)

        initial_prompt = self.prompts[prompt_index]
        follow_up_prompt = "Can you confirm that the answer was correct? Show your work again."

        # Create conversation
        conversation = ConversationWithTools(models, tools=self.tools, config=self.config)

        # First turn
        logger.info(f"Starting conversation with prompt: {initial_prompt}")
        first_turn = await conversation.process_message(initial_prompt)

        # Second turn
        logger.info("Sending follow-up message")
        second_turn = await conversation.process_message(follow_up_prompt)

        # Analyze results for context maintenance
        tool_markers = [
            "[calculator] input:",
            "I'll use the calculator tool",
            "Using the calculator tool",
            "Let me use the calculator"
        ]

        has_calculator_call = any(marker in first_turn["content"] for marker in tool_markers)
        maintains_context = (
            any(marker in second_turn["content"] for marker in tool_markers) or
            any(char.isdigit() for char in second_turn["content"])
        )

        return {
            "turns": [first_turn, second_turn],
            "has_calculator_call": has_calculator_call,
            "maintains_context": maintains_context,
            "prompt": initial_prompt
        }

    async def run_multiple_conversations(self, num_conversations: int = 3):
        """Run multiple conversations with tools.

        Args:
            num_conversations: Number of conversations to run
        """
        # Initialize model list without OpenAI
        models = initialize_model_list(self.config, disabled_providers={"openai"})

        if not models:
            logger.error("No models available for testing")
            return

        logger.info(f"Running {num_conversations} tool-enabled conversations")
        logger.info(f"Using {len(models)} models with OpenAI disabled")

        for i in range(num_conversations):
            logger.info(f"Starting conversation {i+1}/{num_conversations}")
            result = await self.run_tool_conversation(models)

            # Store result
            conversation_id = f"conversation-{i+1}"
            self.results[conversation_id] = result

    def print_summary(self):
        """Print summary of test results."""
        if not self.results:
            logger.warning("No results to summarize")
            return

        total = len(self.results)
        tool_calls = sum(1 for r in self.results.values() if r.get("has_calculator_call", False))
        context_maintained = sum(1 for r in self.results.values() if r.get("maintains_context", False))

        success_rate = (context_maintained / total) * 100 if total > 0 else 0

        print("\n" + "=" * 80)
        print("MULTI-MODEL TOOL CONVERSATION TEST SUMMARY")
        print("=" * 80)
        print(f"\nTotal conversations: {total}")
        print(f"Tool calls detected: {tool_calls} ({tool_calls/total*100:.1f}% of conversations)")
        print(f"Context maintained: {context_maintained} ({success_rate:.1f}% of conversations)")
        print("\nSample conversation prompts:")

        for i, (conversation_id, result) in enumerate(list(self.results.items())[:3]):
            print(f"  {i+1}: {result['prompt'][:50]}..." if len(result['prompt']) > 50 else f"  {i+1}: {result['prompt']}")

        print("=" * 80)

@pytest.mark.asyncio
async def test_calculator_multi_model():
    """Test calculator in multi-model conversations."""
    config = Config()
    tester = MultiModelToolsTester(config)

    # Run a single conversation with the calculator
    models = initialize_model_list(config, disabled_providers={"openai"})

    # Skip if no models are available
    if not models:
        pytest.skip("No models available for testing")

    tester.setup_tools()
    tester.setup_prompts()

    # Use a specific prompt that requires calculation
    result = await tester.run_tool_conversation(models, prompt_index=0)

    # Verify tool was called
    assert result["has_calculator_call"], "Calculator tool was not called"

    # Verify context was maintained
    assert result["maintains_context"], "Context was not maintained across turns"

    # Log result for debugging
    logger.info(f"First turn: {result['turns'][0]['content'][:200]}...")
    logger.info(f"Second turn: {result['turns'][1]['content'][:200]}...")

if __name__ == "__main__":
    # Run the tests directly
    config = Config()
    tester = MultiModelToolsTester(config)

    asyncio.run(tester.run_multiple_conversations(num_conversations=2))
    tester.print_summary()
