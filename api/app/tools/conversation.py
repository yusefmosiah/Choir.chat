"""
Conversation wrapper with tool support.
"""
import logging
import re
import random
import asyncio
from typing import List, Dict, Any, Optional, Set

from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    abstract_llm_completion_stream
)
from .base import BaseTool

logger = logging.getLogger(__name__)

class ConversationWithTools:
    """Manages a conversation that supports tool use across multiple models."""

    def __init__(
        self,
        models: List[ModelConfig],
        tools: List[BaseTool],
        config: Optional[Config] = None,
        system_prompt: Optional[str] = None
    ):
        """Initialize a conversation with tools.

        Args:
            models: List of models to use for the conversation
            tools: List of tools available in the conversation
            config: Application configuration
            system_prompt: Optional system prompt to use
        """
        self.models = models
        self.tools = tools
        self.config = config or Config()
        self.messages = []

        # Create system prompt with tool descriptions
        tool_descriptions = "\n".join([
            f"- {tool.name}: {tool.description}" for tool in tools
        ])

        default_system_prompt = (
            "You are a helpful assistant that can use tools to provide better answers. "
            "You have access to the following tools:\n\n"
            f"{tool_descriptions}\n\n"
            "When you need to use a tool, respond with:\n"
            "I'll use the [tool_name] tool to help answer this.\n"
            "[tool_name] input: your_input_here\n\n"
            "Then, continue your answer after receiving the tool's output."
        )

        self.system_prompt = system_prompt or default_system_prompt
        self.current_model = None

    def _extract_tool_calls(self, content: str) -> List[Dict[str, Any]]:
        """Extract tool calls from a response.

        Args:
            content: Response content to extract tool calls from

        Returns:
            List of tool calls in the format {tool_name, input}
        """
        # Extract tool calls using regex pattern
        # This matches both formats:
        # [tool_name] input: input_text
        # [tool] input: input_text (for backward compatibility)
        pattern = r"\[([\w]+)\]\s+input:\s*(.*?)(?=\n\n|\n\[|\Z)"
        matches = re.finditer(pattern, content, re.DOTALL)

        tool_calls = []
        for match in matches:
            tool_name = match.group(1)
            tool_input = match.group(2).strip()

            # If tool_name is "tool", try to infer the actual tool from available tools
            if tool_name == "tool" and self.tools:
                # For now, just use the first available tool as default
                tool_name = self.tools[0].name

            tool_calls.append({
                "tool_name": tool_name,
                "input": tool_input
            })

        return tool_calls

    async def _execute_tool_calls(self, tool_calls: List[Dict[str, Any]]) -> str:
        """Execute tool calls and format the results.

        Args:
            tool_calls: List of tool calls to execute

        Returns:
            Formatted tool results
        """
        results = []

        for call in tool_calls:
            tool_name = call["tool_name"]
            tool_input = call["input"]

            # Find the tool by name
            tool = next((t for t in self.tools if t.name == tool_name), None)

            if tool is None:
                result = f"Error: Tool '{tool_name}' not found."
            else:
                try:
                    result = await tool.run(tool_input)
                except Exception as e:
                    result = f"Error executing {tool_name}: {str(e)}"

            formatted_result = f"[{tool_name}] output: {result}"
            results.append(formatted_result)

        return "\n\n".join(results)

    async def process_message(self, user_message: str) -> Dict[str, Any]:
        """Process a user message through the conversation.

        Args:
            user_message: The user's message

        Returns:
            Response containing the assistant's message
        """
        # Add user message to conversation
        self.messages.append({"role": "user", "content": user_message})

        # Select a random model if not already set
        if not self.current_model:
            self.current_model = random.choice(self.models)

        # Create messages array with system prompt
        formatted_messages = [
            {"role": "system", "content": self.system_prompt}
        ]
        formatted_messages.extend(self.messages)

        logger.info(f"Using model: {self.current_model}")

        # Generate initial response
        response_content = ""
        try:
            async for chunk in abstract_llm_completion_stream(
                model_name=str(self.current_model),
                messages=formatted_messages,
                config=self.config
            ):
                response_content += chunk
        except Exception as e:
            logger.error(f"Error in initial response generation: {str(e)}")
            response_content = f"Error: {str(e)}"
            return {"role": "assistant", "content": response_content}

        # Extract and execute tool calls
        tool_calls = self._extract_tool_calls(response_content)

        if tool_calls:
            logger.info(f"Found {len(tool_calls)} tool calls in response")

            # Execute tools
            tool_results = await self._execute_tool_calls(tool_calls)

            # Add assistant message with tool calls
            self.messages.append({"role": "assistant", "content": response_content})

            # Handle models differently based on their provider
            # For Mistral, we need to use user messages for follow-up and can't have consecutive assistant messages
            is_mistral = "mistral/" in str(self.current_model)

            if is_mistral:
                # For Mistral models, add tool results as a user message
                self.messages.append({"role": "user", "content": f"Tool results: {tool_results}"})
            else:
                # For other models, we add tool results as an assistant message
                self.messages.append({"role": "assistant", "content": tool_results})

            # Select a different model for continuation to test context preservation
            previous_model = self.current_model
            remaining_models = [m for m in self.models if m != previous_model]
            if remaining_models:
                self.current_model = random.choice(remaining_models)
            logger.info(f"Switching model from {previous_model} to {self.current_model}")

            # Generate follow-up response
            follow_up_content = ""

            # Create appropriately formatted messages for the next model
            new_mistral = "mistral/" in str(self.current_model)

            # Handle message formatting based on the model type
            if new_mistral:
                # For Mistral, simpler formatting works better
                formatted_messages = [
                    {"role": "system", "content": self.system_prompt}
                ]

                # Add messages but prevent consecutive assistant messages
                last_role = None
                for msg in self.messages:
                    # Skip consecutive assistant messages for Mistral
                    if msg["role"] == "assistant" and last_role == "assistant":
                        continue
                    formatted_messages.append(msg)
                    last_role = msg["role"]

                # Make sure the last message is a user message for Mistral
                if last_role == "assistant":
                    formatted_messages.append({
                        "role": "user",
                        "content": "Please continue with your response."
                    })
            else:
                # For other models, standard formatting
                formatted_messages = [
                    {"role": "system", "content": self.system_prompt}
                ]
                # Add all previous messages
                formatted_messages.extend(self.messages)

            try:
                async for chunk in abstract_llm_completion_stream(
                    model_name=str(self.current_model),
                    messages=formatted_messages,
                    config=self.config
                ):
                    follow_up_content += chunk
            except Exception as e:
                logger.error(f"Error in follow-up response generation: {str(e)}")
                follow_up_content = f"Error in streaming with {self.current_model}: {str(e)}"

            final_content = f"{response_content}\n\n{tool_results}\n\n{follow_up_content}"

            # Add final assistant message
            self.messages.append({"role": "assistant", "content": follow_up_content})

            return {"role": "assistant", "content": final_content}
        else:
            # No tool calls, just add the response
            self.messages.append({"role": "assistant", "content": response_content})
            return {"role": "assistant", "content": response_content}

    async def multi_turn_conversation(self, messages: List[str], max_turns: int = 3) -> List[Dict[str, Any]]:
        """Run a multi-turn conversation.

        Args:
            messages: List of user messages
            max_turns: Maximum number of turns

        Returns:
            List of conversation turns
        """
        results = []

        for i, message in enumerate(messages[:max_turns]):
            logger.info(f"Turn {i+1}: Processing user message")
            response = await self.process_message(message)
            results.append(response)

        return results
