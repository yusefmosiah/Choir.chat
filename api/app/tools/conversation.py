"""
Conversation wrapper with tool support.
"""
import logging
import re
import random
import asyncio
from typing import List, Dict, Any, Optional, Set
from datetime import datetime

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, ToolMessage

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
        system_prompt: Optional[str] = None,
    ):
        """
        Initialize a conversation with tools.

        Args:
            models: List of models to use for the conversation
            tools: List of tools to make available to the models
            config: Configuration object
            system_prompt: Optional system prompt to use
        """
        self.models = models
        self.tools = tools
        self.config = config or Config()

        # Get the current date to include in the system prompt
        current_date = datetime.now().strftime("%Y-%m-%d")

        # Create default system prompt with date if not provided
        if system_prompt is None:
            # Define the system prompt with date and tool instructions
            self.system_prompt = f"""Today's date is {current_date}. You are a helpful AI assistant with access to tools.
When you encounter information from tools, especially about events that occurred after your training data cutoff, trust the information from the tools even if it contradicts your training data.

You will be given access to the following tools: {', '.join([tool.name for tool in tools])}.

Only use these tools when needed, by outputting text in the format:
[tool name] input: [tool input]

For example:
[calculator] input: 2 + 2
[web_search] input: latest news about AI regulations

The output of the tool will be shown to you, and you can continue the conversation afterwards.
"""
        else:
            self.system_prompt = system_prompt + f"\n\nToday's date is {current_date}."

        self.messages = [
            {"role": "system", "content": self.system_prompt}
        ]
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
        """
        Process a user message, potentially using tools to generate a response.

        Args:
            user_message: The message from the user

        Returns:
            The assistant's response, including tool usage
        """
        # Add user message
        self.messages.append({"role": "user", "content": user_message})

        # If no current model, select the first one
        if self.current_model is None:
            self.current_model = self.models[0]

        logger.info(f"Using model: {self.current_model}")

        # Create messages array with system prompt
        formatted_messages = [
            {"role": "system", "content": self.system_prompt}
        ]
        formatted_messages.extend(self.messages)

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
            # Some models need special handling for tool results
            is_mistral = "mistral/" in str(self.current_model)
            is_cohere = "cohere/" in str(self.current_model)
            is_anthropic = "anthropic/" in str(self.current_model)

            # Both Mistral and Cohere need tool results as user messages
            if is_mistral or is_cohere:
                # Add tool results as a user message
                self.messages.append({"role": "user", "content": f"Tool results: {tool_results}"})
            elif is_anthropic:
                # For Anthropic models, we need to extract tool use IDs and format the results differently
                # Instead of sending a tool message, we need to update the last user message with tool results
                # Since we don't have access to the actual tool_use_id from Anthropic's response,
                # we'll use a different approach and format tool results as a regular user message
                self.messages.append({"role": "user", "content": f"The tools returned the following results:\n\n{tool_results}"})
            else:
                # For other models, add tool results as a tool message
                # This uses the proper LangChain ToolMessage type for models that support it
                self.messages.append({"role": "tool", "content": tool_results})

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
