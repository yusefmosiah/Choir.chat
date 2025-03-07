"""
Conversation wrapper with tool support using LangGraph.
"""
import logging
import json
import random
from typing import List, Dict, Any, Optional, Tuple, Union, Callable, TypedDict, cast
from datetime import datetime

from langchain_core.messages import (
    BaseMessage,
    HumanMessage,
    AIMessage,
    SystemMessage,
    ToolMessage,
    FunctionMessage,
    ChatMessage
)
from langgraph.graph import END, StateGraph
from langgraph.graph.message import MessageGraph
from langgraph.prebuilt import ToolNode, chat_agent_executor

from app.config import Config
from app.langchain_utils import (
    ModelConfig,
    initialize_model_list,
    abstract_llm_completion_stream,
    get_base_model,
    convert_tools_to_pydantic
)
from .base import BaseTool

logger = logging.getLogger(__name__)

class ConversationWithTools:
    """
    Manages a conversation that supports tool use across multiple models using LangGraph.
    """

    def __init__(
        self,
        models: List[ModelConfig],
        tools: List[BaseTool],
        config: Optional[Config] = None,
        system_prompt: Optional[str] = None,
    ):
        """
        Initialize a conversation with tools using LangGraph.

        Args:
            models: List of models to use for the conversation
            tools: List of tools to make available to the models
            config: Configuration object
            system_prompt: Optional system prompt to use
        """
        self.models = models
        self.tools = tools
        self.config = config or Config()
        self.current_model = None

        # Get the current date to include in the system prompt
        current_date = datetime.now().strftime("%Y-%m-%d")

        # Create default system prompt with date if not provided
        if system_prompt is None:
            # Format tool descriptions for the system prompt
            tool_descriptions = []
            for tool in tools:
                tool_desc = f"- {tool.name}: {tool.description}"
                tool_descriptions.append(tool_desc)

            tool_section = "\n".join(tool_descriptions)

            # Define the system prompt with date and tool instructions
            self.system_prompt = f"""Today's date is {current_date}. You are a helpful AI assistant with access to tools.

You have access to the following tools:
{tool_section}

When you need information that might be beyond your knowledge or requires real-time data, use an appropriate tool. The tools will automatically be called with your specified parameters, and the results will be returned to you.

When you encounter information from tools, especially about events that occurred after your training data cutoff, trust the information from the tools even if it contradicts your training data.
"""
        else:
            self.system_prompt = system_prompt + f"\n\nToday's date is {current_date}."

        # Initialize conversation state
        self.messages = [
            SystemMessage(content=self.system_prompt)
        ]

        # Build the graph
        self._build_graph()

    def _build_graph(self):
        """Build the LangGraph conversation graph with tools."""
        # Create a message graph
        builder = MessageGraph()

        # Add agent node that processes messages using the model
        builder.add_node("agent", self._run_model)

        # Add tool execution node
        builder.add_node("execute_tools", self._execute_tools)

        # Add routing logic to determine if we need to execute tools
        builder.add_conditional_edges(
            "agent",
            self._route_after_agent,
            {
                "execute_tools": "execute_tools",
                "end": END
            }
        )

        # After executing tools, return to the agent for further processing
        builder.add_edge("execute_tools", "agent")

        # Set entry point
        builder.set_entry_point("agent")

        # Compile the graph
        self.graph = builder.compile()
        logger.info(f"Built conversation graph with {len(self.tools)} tools")

    async def _run_model(self, state: List[BaseMessage]) -> List[BaseMessage]:
        """
        Run the model on the current state to generate a response.

        Args:
            state: List of messages representing the conversation state

        Returns:
            Updated list of messages with the model's response
        """
        # If no current model, select the first one
        if self.current_model is None:
            self.current_model = self.models[0]

        logger.info(f"Running model: {self.current_model}")

        try:
            # Get the base LLM for this model
            model = get_base_model(str(self.current_model), self.config)

            # Bind tools to the model if we have any
            if self.tools:
                # Convert our tools to LangChain-compatible Pydantic models
                pydantic_tools = convert_tools_to_pydantic(self.tools)

                # Log information about the tools being bound
                tool_names = [tool.name for tool in self.tools]
                logger.info(f"Binding tools to model: {tool_names}")

                # Bind the tools using LangChain's bind_tools method
                model = model.bind_tools(pydantic_tools)
                logger.info(f"Successfully bound {len(pydantic_tools)} tools to model {self.current_model}")

            # Generate a response using the model with the current conversation state
            logger.info(f"Generating response with {len(state)} messages")
            response = await model.ainvoke(state)

            # Log information about the response
            if hasattr(response, "tool_calls") and response.tool_calls:
                logger.info(f"Model response includes {len(response.tool_calls)} tool calls")
                for i, tc in enumerate(response.tool_calls):
                    logger.info(f"Tool call {i+1}: {tc.get('name')} with args: {tc.get('args')}")
            else:
                logger.info("Model response contains no tool calls")

            # Return updated state with model response
            return state + [response]

        except Exception as e:
            logger.error(f"Error in model execution: {str(e)}", exc_info=True)
            # Create an error message if the model fails
            error_message = AIMessage(content=f"I encountered an error: {str(e)}")
            return state + [error_message]

    def _route_after_agent(self, state: List[BaseMessage]) -> str:
        """
        Determine the next step based on the current state.

        Args:
            state: List of messages representing the conversation state

        Returns:
            Next node to execute
        """
        # Check the last message for tool calls
        last_message = state[-1]

        # Only check for the modern tool_calls attribute
        if hasattr(last_message, "tool_calls") and last_message.tool_calls:
            logger.info(f"Detected {len(last_message.tool_calls)} tool calls in message")
            return "execute_tools"

        logger.info("No tool calls detected, ending conversation turn")
        return "end"

    async def _execute_tools(self, state: List[BaseMessage]) -> List[BaseMessage]:
        """
        Execute any tool calls in the last message.

        Args:
            state: List of messages representing the conversation state

        Returns:
            Updated list of messages with tool execution results
        """
        last_message = state[-1]
        results = []

        # Handle only the modern tool_calls format
        if hasattr(last_message, "tool_calls") and last_message.tool_calls:
            for tool_call in last_message.tool_calls:
                tool_name = tool_call.get("name")
                tool_args = tool_call.get("args")
                tool_id = tool_call.get("id", "unknown")

                # Find matching tool
                tool = next((t for t in self.tools if t.name == tool_name), None)

                if tool:
                    try:
                        logger.info(f"Executing tool: {tool_name} with args: {tool_args}")

                        # Extract the appropriate parameter
                        # For web_search tools, we expect a "query" parameter
                        if isinstance(tool_args, dict) and "query" in tool_args:
                            tool_input = tool_args["query"]
                        # For other tools, use the full args or convert to string
                        elif isinstance(tool_args, dict):
                            if len(tool_args) == 1 and next(iter(tool_args.values())) is not None:
                                # If there's only one argument, use its value
                                tool_input = next(iter(tool_args.values()))
                            else:
                                # Use the full args dict
                                tool_input = tool_args
                        else:
                            tool_input = str(tool_args) if tool_args is not None else ""

                        result = await tool.run(tool_input)
                        logger.info(f"Tool execution result length: {len(str(result))}")

                        # Create a proper ToolMessage with the correct tool_call_id
                        results.append(
                            ToolMessage(
                                content=str(result),
                                tool_call_id=tool_id,
                                name=tool_name
                            )
                        )
                    except Exception as e:
                        logger.error(f"Error executing tool {tool_name}: {str(e)}", exc_info=True)
                        results.append(
                            ToolMessage(
                                content=f"Error executing {tool_name}: {str(e)}",
                                tool_call_id=tool_id,
                                name=tool_name
                            )
                        )
                else:
                    logger.warning(f"Tool '{tool_name}' not found")
                    results.append(
                        ToolMessage(
                            content=f"Error: Tool '{tool_name}' not found.",
                            tool_call_id=tool_id,
                            name=tool_name
                        )
                    )

        if not results:
            logger.warning("No tool results generated")

        return state + results

    async def process_message(self, user_message: str) -> Dict[str, Any]:
        """
        Process a user message, potentially using tools to generate a response.

        This method:
        1. Adds the user message to the conversation state
        2. Passes the state to the LangGraph for processing
        3. Formats the result into a consistent response structure

        Args:
            user_message: The message from the user

        Returns:
            The assistant's response, including tool usage
        """
        # Convert user message to HumanMessage and record message ID
        human_message = HumanMessage(content=user_message)
        user_message_id = getattr(human_message, "id", None)

        # Add to internal state for tracking
        initial_message_count = len(self.messages)
        self.messages.append(human_message)

        try:
            # Invoke the graph with current messages
            logger.info(f"Processing message with {len(self.messages)} messages in state")
            result = await self.graph.ainvoke(self.messages)

            # Update internal state with the resulting messages
            self.messages = result

            # Find new messages by comparing with the initial state
            new_messages = self.messages[initial_message_count:]
            logger.info(f"Graph execution added {len(new_messages)} messages")

            # Extract assistant and tool messages from the new messages
            ai_messages = [msg for msg in new_messages if isinstance(msg, AIMessage)]
            tool_messages = [msg for msg in new_messages if isinstance(msg, ToolMessage)]

            logger.info(f"Extracted {len(ai_messages)} AI messages and {len(tool_messages)} tool messages")

            # Format the final response
            response_parts = []

            # Include the initial AI response
            if ai_messages:
                # Log debug info about the first AI message
                first_ai = ai_messages[0]
                logger.debug(f"First AI message type: {type(first_ai)}")
                logger.debug(f"First AI message content type: {type(first_ai.content)}")

                # Ensure we're getting a string from the content
                content = first_ai.content
                if not isinstance(content, str):
                    # Handle Anthropic's structured format
                    if isinstance(content, list):
                        # Extract text from structured content
                        text_parts = []
                        for item in content:
                            if isinstance(item, dict) and "text" in item:
                                text_parts.append(item["text"])
                        content = "".join(text_parts)
                    else:
                        # Convert other content types to string
                        content = str(content)

                response_parts.append(content)
                logger.info(f"Added initial AI response of length {len(content)}")

            # Include tool results, if any
            if tool_messages:
                # Format tool responses consistently
                tool_results = []
                for msg in tool_messages:
                    tool_name = getattr(msg, "name", "tool")

                    # Ensure content is a string
                    content = msg.content
                    if not isinstance(content, str):
                        content = str(content)

                    tool_results.append(f"[{tool_name}] output: {content}")

                formatted_tool_results = "\n\n".join(tool_results)
                response_parts.append(formatted_tool_results)
                logger.info(f"Added {len(tool_results)} tool results")

            # Include the follow-up AI response, if any
            if len(ai_messages) > 1:
                last_ai = ai_messages[-1]

                # Ensure we're getting a string from the content
                content = last_ai.content
                if not isinstance(content, str):
                    # Handle Anthropic's structured format
                    if isinstance(content, list):
                        # Extract text from structured content
                        text_parts = []
                        for item in content:
                            if isinstance(item, dict) and "text" in item:
                                text_parts.append(item["text"])
                        content = "".join(text_parts)
                    else:
                        # Convert other content types to string
                        content = str(content)

                response_parts.append(content)
                logger.info(f"Added follow-up AI response of length {len(content)}")

            # Make sure all response parts are strings before joining
            for i, part in enumerate(response_parts):
                if not isinstance(part, str):
                    logger.warning(f"Response part {i} is not a string: {type(part)}")
                    response_parts[i] = str(part)

            # Combine all parts with clear separation
            final_content = "\n\n".join(response_parts)

            if not final_content.strip():
                # Handle the case where no content was generated
                logger.warning("No content generated by the model or tools")
                final_content = "I apologize, but I wasn't able to generate a proper response. Please try rephrasing your query."

            return {"role": "assistant", "content": final_content}

        except Exception as e:
            logger.error(f"Error in conversation graph execution: {str(e)}", exc_info=True)
            return {
                "role": "assistant",
                "content": f"I apologize, but I encountered an error while processing your message: {str(e)}"
            }

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
