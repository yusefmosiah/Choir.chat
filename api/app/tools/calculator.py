"""
Calculator tool implementation.
"""
import re
import ast
import math
import operator
from typing import Dict, Any, Union, Optional

from .base import BaseTool

# Define supported operators
OPERATORS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.Pow: operator.pow,
    ast.USub: operator.neg,  # Unary minus
}

class CalculatorTool(BaseTool):
    """Tool for performing mathematical calculations.

    Supports basic arithmetic operations, parentheses, and common math functions.
    """
    name = "calculator"
    description = "Perform mathematical calculations. Input should be a mathematical expression like '2 + 2' or 'sqrt(16)'."

    def __init__(self, name: Optional[str] = None, description: Optional[str] = None):
        """Initialize the calculator tool."""
        super().__init__(name, description)

    def _sanitize_input(self, expression: str) -> str:
        """Sanitize the input expression to prevent code execution.

        Args:
            expression: The mathematical expression to sanitize

        Returns:
            Sanitized expression

        Raises:
            ValueError: If the expression contains invalid characters
        """
        # Remove whitespace
        expression = expression.strip()

        # Only allow valid mathematical expression characters
        if not re.match(r'^[0-9\s\.\+\-\*\/\(\)\^\%\,sqrt]+$', expression):
            raise ValueError(
                "Invalid characters in expression. Only numbers, basic operators "
                "(+, -, *, /, ^, %), parentheses, and 'sqrt' are allowed."
            )

        # Replace sqrt() with math.sqrt()
        expression = expression.replace('sqrt', 'math.sqrt')

        # Replace ^ with **
        expression = expression.replace('^', '**')

        return expression

    def _safe_eval(self, node):
        """Safely evaluate a mathematical AST node.

        Args:
            node: The AST node to evaluate

        Returns:
            The result of evaluating the node

        Raises:
            ValueError: If an unsupported operation is encountered
        """
        if isinstance(node, ast.Num):
            return node.n
        elif isinstance(node, ast.BinOp):
            if type(node.op) not in OPERATORS:
                raise ValueError(f"Unsupported operation: {type(node.op).__name__}")

            left = self._safe_eval(node.left)
            right = self._safe_eval(node.right)

            # Check for division by zero
            if isinstance(node.op, ast.Div) and right == 0:
                raise ValueError("Division by zero")

            return OPERATORS[type(node.op)](left, right)
        elif isinstance(node, ast.UnaryOp):
            if type(node.op) not in OPERATORS:
                raise ValueError(f"Unsupported operation: {type(node.op).__name__}")

            operand = self._safe_eval(node.operand)
            return OPERATORS[type(node.op)](operand)
        elif isinstance(node, ast.Call):
            if not isinstance(node.func, ast.Attribute) or not isinstance(node.func.value, ast.Name) or node.func.value.id != 'math':
                raise ValueError("Only math module functions are allowed")

            # Currently only supporting sqrt
            if node.func.attr != 'sqrt':
                raise ValueError(f"Unsupported function: {node.func.attr}")

            arg = self._safe_eval(node.args[0])
            if arg < 0:
                raise ValueError("Cannot take square root of negative number")

            return math.sqrt(arg)
        else:
            raise ValueError(f"Unsupported node type: {type(node).__name__}")

    def calculate(self, expression: str) -> Union[int, float]:
        """Calculate the result of a mathematical expression.

        Args:
            expression: The mathematical expression to evaluate

        Returns:
            The result of the calculation

        Raises:
            ValueError: If the expression is invalid or contains unsupported operations
        """
        try:
            # Sanitize the input
            sanitized = self._sanitize_input(expression)

            # Parse the expression into an AST
            parsed = ast.parse(sanitized, mode='eval')

            # Evaluate the AST
            result = self._safe_eval(parsed.body)

            return result
        except Exception as e:
            raise ValueError(f"Error evaluating expression: {str(e)}")

    async def run(self, input: str) -> str:
        """Execute the calculator tool.

        Args:
            input: The mathematical expression to evaluate

        Returns:
            The result of the calculation as a string
        """
        try:
            result = self.calculate(input)
            return str(result)
        except ValueError as e:
            return f"Error: {str(e)}"
