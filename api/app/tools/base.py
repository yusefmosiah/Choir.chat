"""
Base tool class that all tools will inherit from.
"""
from typing import Dict, Any, Optional
from pydantic import BaseModel

class BaseTool:
    """Base class for all tools.

    All tools should inherit from this class and implement the run method.
    """
    name: str
    description: str

    def __init__(self, name: Optional[str] = None, description: Optional[str] = None):
        """Initialize the tool with optional custom name and description."""
        if name:
            self.name = name
        if description:
            self.description = description

    async def run(self, input: str) -> str:
        """Execute the tool with the given input.

        Args:
            input: The input to the tool, typically a string query

        Returns:
            The result of the tool execution as a string

        Raises:
            NotImplementedError: This method must be implemented by subclasses
        """
        raise NotImplementedError("Subclasses must implement run method")

    def to_dict(self) -> Dict[str, Any]:
        """Convert the tool to a dictionary for serialization."""
        return {
            "name": self.name,
            "description": self.description
        }
