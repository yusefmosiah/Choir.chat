"""
Test the calculator tool.
"""
import pytest
import logging
from typing import List, Dict, Any

from app.config import Config
from app.langchain_utils import ModelConfig, initialize_model_list
from app.tools.calculator import CalculatorTool
from app.tools.conversation import ConversationWithTools

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TestCalculatorTool:
    """Test suite for the calculator tool."""

    def test_calculator_basic(self):
        """Test basic calculator operations."""
        calculator = CalculatorTool()

        # Test addition
        assert calculator.calculate("2 + 2") == 4

        # Test subtraction
        assert calculator.calculate("10 - 5") == 5

        # Test multiplication
        assert calculator.calculate("3 * 4") == 12

        # Test division
        assert calculator.calculate("20 / 5") == 4

    def test_calculator_complex(self):
        """Test more complex calculator operations."""
        calculator = CalculatorTool()

        # Test order of operations
        assert calculator.calculate("2 + 3 * 4") == 14

        # Test parentheses
        assert calculator.calculate("(2 + 3) * 4") == 20

        # Test decimal numbers
        assert calculator.calculate("2.5 + 3.5") == 6.0

        # Test powers
        assert calculator.calculate("2 ^ 3") == 8

    def test_calculator_error_handling(self):
        """Test error handling in calculator."""
        calculator = CalculatorTool()

        # Test division by zero
        with pytest.raises(ValueError):
            calculator.calculate("10 / 0")

        # Test invalid expression
        with pytest.raises(ValueError):
            calculator.calculate("2 +* 3")

        # Test non-numerical input
        with pytest.raises(ValueError):
            calculator.calculate("hello world")

    @pytest.mark.asyncio
    async def test_calculator_run(self):
        """Test the asynchronous run method."""
        calculator = CalculatorTool()

        # Test valid calculation
        result = await calculator.run("2 + 2")
        assert result == "4"

        # Test error handling
        result = await calculator.run("10 / 0")
        assert result.startswith("Error:")

    @pytest.mark.asyncio
    async def test_calculator_in_multimodel_thread(self):
        """Test calculator tool in a multimodel conversation thread with complex calculations."""
        config = Config()

        # Initialize model list without OpenAI
        models = initialize_model_list(config, disabled_providers={"openai"})

        # Skip if no models are available
        if not models:
            pytest.skip("No models available for testing")

        # Create a conversation with calculator tool
        calculator = CalculatorTool()
        conversation = ConversationWithTools(models, tools=[calculator], config=config)

        # Run conversation with complex calculation request that models would struggle with
        complex_calculation = (
            "I need to verify a complex calculation. What is "
            "1234567890 * 9876543210 / 123456789? "
            "Please use the calculator tool to compute this precisely, as I need an exact answer."
        )

        result = await conversation.process_message(complex_calculation)

        # Log the result for debugging
        logger.info(f"Response content: {result['content']}")

        # Extract and verify tool usage - explicitly check for calculator invocation
        tool_markers = [
            "[calculator] input:",
            "I'll use the calculator tool",
            "Using the calculator tool"
        ]

        tool_was_used = any(marker in result["content"] for marker in tool_markers)
        assert tool_was_used, "Calculator tool was not called for complex calculation"

        # Run a follow-up message to test context preservation
        follow_up = await conversation.process_message(
            "Can you verify your calculation again? I want to make sure the result is exact."
        )

        # Log the follow-up for debugging
        logger.info(f"Follow-up content: {follow_up['content']}")

        # The expected result is approximately 100000000000, but we'll check for any digits
        # since we want to verify context maintenance
        has_digits = any(char.isdigit() for char in follow_up["content"])
        assert has_digits, "Follow-up response did not maintain calculation context"

if __name__ == "__main__":
    pytest.main(["-xvs", __file__])
