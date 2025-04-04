import asyncio
import logging
from typing import List, Dict, Any, AsyncIterator, Optional

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage, ToolMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough, RunnableLambda
import json # Added for parsing tool results

# Local imports
from app.config import Config
from app.postchain.postchain_llm import post_llm
from app.langchain_utils import ModelConfig
from app.postchain.schemas.state import PostChainState, ExperiencePhaseOutput, SearchResult, VectorSearchResult # Import new schemas
from app.postchain.utils import format_stream_event #, save_state, recover_state # Removed state management utils
from app.postchain.prompts.prompts import action_instruction, experience_instruction, intention_instruction, understanding_instruction, observation_instruction, yield_instruction

# Langchain Tool Imports (Example)
from app.tools.brave_search import BraveSearchTool
from app.tools.qdrant import qdrant_search # Import the specific tool function

# Configure logging
logger = logging.getLogger("postchain_langchain")

COMMON_SYSTEM_PROMPT = """
You are representing Choir's PostChain, in which many different AI models collaborate to provide an improvisational, dynamic, and contextually rich response in a single harmonized voice.
You will see <phase_instructions> embedded in user messages, which contain the instructions for the current phase. Followe these instructions carefully.
"""

# --- In-memory state store (replace with persistent store later) ---
conversation_history_store: Dict[str, List[BaseMessage]] = {}


# --- Phase Implementations using LCEL ---

async def run_action_phase(
    messages: List[BaseMessage],
    # config: Config, # REMOVED - Keys are in model_config
    model_config: ModelConfig # This should now contain API keys
) -> Dict[str, Any]:
    """Runs the Action phase using LCEL."""
    logger.info(f"Running Action phase with model: {model_config.provider}/{model_config.model_name}")

    # Prepare prompt
    # Note: Injecting instructions directly into the human message for simplicity here.
    # A more robust approach might use specific prompt templates or message roles.
    last_message = messages[-1]
    if isinstance(last_message, HumanMessage):
        action_query = f"<action_instruction>{action_instruction(model_config)}</action_instruction>\n\n{last_message.content}"
        action_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages[:-1] + [HumanMessage(content=action_query)]
    else:
        # Fallback if the last message isn't HumanMessage (shouldn't happen in normal flow)
        logger.warning("Last message was not HumanMessage, running action phase without specific instruction injection.")
        action_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages

    try:
        # Invoke the chain and await the result from post_llm
        # --- Direct call to post_llm for debugging ---
        logger.info(f"Directly calling post_llm with model: {model_config}")
        # Pass the complete ModelConfig object which includes keys
        response = await post_llm(
            model_config=model_config,
            messages=action_messages
        )
        # --- End Direct call ---

        # Ensure response is an AIMessage before accessing .content
        if isinstance(response, AIMessage):
            logger.info(f"Action phase completed. Response: {response.content[:100]}...")
            return {"action_response": response}
        else:
            # Handle cases where post_llm might return something else on error
            error_msg = f"Unexpected response type from action model: {type(response)}. Content: {response}"
            logger.error(error_msg)
            return {"error": error_msg}

    except Exception as e:
        logger.error(f"Error during Action phase: {e}", exc_info=True)
        return {"error": f"Action phase failed: {e}"}

async def run_experience_phase(
    messages: List[BaseMessage],
    # config: Config, # REMOVED - Keys are in model_config
    model_config: ModelConfig # This should now contain API keys
) -> ExperiencePhaseOutput: # Updated return type
    """Runs the Experience phase using LCEL, including tool handling."""
    logger.info(f"Running Experience phase with model: {model_config.provider}/{model_config.model_name}")

    # --- Instantiate Tools ---
    # Note: qdrant_search is already decorated with @tool, so we just pass the function.
    # Langchain handles the instantiation and schema generation.
    # TODO: How should tools requiring config (like BraveSearchTool) be handled now?
    # Option 1: Pass keys via model_config to the tool constructor if possible.
    # Option 2: Re-evaluate if these tools *need* server-side config.
    # For now, let's assume BraveSearchTool can work without server config or gets keys differently.
    # If BraveSearchTool needs a key, it must be added to ModelConfig and accessed here.
    # Assuming BraveSearchTool is modified or doesn't strictly need the key from server Config for now.
    tools = [BraveSearchTool(), qdrant_search] # Add Qdrant tool

    # Prepare prompt - find last user query and last AI (Action) response
    last_user_msg = next((m for m in reversed(messages) if isinstance(m, HumanMessage)), None)
    last_ai_msg = next((m for m in reversed(messages) if isinstance(m, AIMessage)), None)

    if not last_user_msg or not last_ai_msg:
        logger.error("Could not find previous user query or action response for Experience phase.")
        return {"error": "Experience phase failed: Missing context."}

    experience_query = f"""<experience_instruction>{experience_instruction(model_config)}</experience_instruction>

Original Query: {last_user_msg.content}

Initial Action Response: {last_ai_msg.content}

Your task: Provide a reflective analysis adding deeper context.
"""
    # Include system prompt and all messages for context, add specific instruction
    experience_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=experience_query)]

    # Define the runnable chain for the experience phase, passing tools
    async def _get_experience_response(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")

        # Pass the complete ModelConfig object
        return await post_llm(
            model_config=model_config,
            messages=msgs,
            tools=tools
        )
    experience_chain = RunnableLambda(_get_experience_response)

    try:
        # --- Initial LLM Call ---
        response = await experience_chain.ainvoke(experience_messages) # AWAIT HERE

        # Check response type after initial call
        if not isinstance(response, AIMessage):
            error_msg = f"Unexpected response type from experience model (initial call): {type(response)}. Content: {response}"
            logger.error(error_msg)
            return {"error": error_msg}

        logger.info(f"Experience phase initial call completed. Response: {response.content[:100]}...")

        # --- Tool Call Handling ---
        tool_messages: List[ToolMessage] = []
        web_results_list: List[SearchResult] = []
        vector_results_list: List[VectorSearchResult] = []

        if hasattr(response, 'tool_calls') and response.tool_calls:
            logger.info(f"Detected {len(response.tool_calls)} tool calls.")
            experience_messages.append(response) # Add the AI message with tool_calls

            for tool_call in response.tool_calls:
                tool_name = tool_call.get("name")
                tool_args = tool_call.get("args")
                tool_id = tool_call.get("id")
                logger.info(f"Executing tool: {tool_name} with args: {tool_args}")

                # Find and execute the corresponding tool
                # Note: We match by name. BraveSearchTool has name 'brave_search', qdrant_search has name 'qdrant_search'.
                tool_to_execute = next((t for t in tools if hasattr(t, 'name') and t.name == tool_name), None)
                tool_output_str = "" # Raw string output from the tool
                parsed_results = [] # Parsed results for structured storage

                if tool_to_execute:
                    try:
                        # Adapt based on tool's expected input (dict vs string)
                        # Use asyncio.to_thread for synchronous run method if arun is not available
                        input_arg_val = None
                        if isinstance(tool_args, dict):
                            # Qdrant expects dict, Brave expects query string within dict
                            input_arg_val = tool_args.get('query', tool_args)
                            if not isinstance(input_arg_val, str): input_arg_val = str(input_arg_val) # Ensure string for run/arun
                        elif isinstance(tool_args, str):
                            input_arg_val = tool_args

                        if input_arg_val is not None:
                            if hasattr(tool_to_execute, 'arun'):
                                tool_output_str = await tool_to_execute.arun(input_arg_val)
                            elif hasattr(tool_to_execute, 'run'):
                                # Check if 'run' is async or sync
                                if asyncio.iscoroutinefunction(tool_to_execute.run):
                                    # Await async 'run' method directly
                                    tool_output_str = await tool_to_execute.run(input_arg_val)
                                else:
                                    # Run synchronous 'run' method in a separate thread
                                    tool_output_str = await asyncio.to_thread(tool_to_execute.run, input_arg_val)
                            else:
                                tool_output_str = f"Error: Tool {tool_name} has neither 'run' nor 'arun' method."
                                logger.error(tool_output_str)
                        else:
                            tool_output_str = f"Error: Unsupported tool args format for {tool_name}: {type(tool_args)}"
                            logger.error(tool_output_str) # Log error here as well

                        # --- Parse Tool Output ---
                        # Ensure tool_output_str is actually a string before parsing
                        if isinstance(tool_output_str, str):
                            try:
                                # Attempt to parse JSON for structured results (Brave, potentially others)
                                parsed_output = json.loads(tool_output_str)
                                if isinstance(parsed_output, dict) and "results" in parsed_output:
                                    raw_results = parsed_output["results"]
                                    if tool_name == "brave_search":
                                        for res in raw_results:
                                            web_results_list.append(SearchResult(
                                                title=res.get("title", ""),
                                                url=res.get("url", ""),
                                                content=res.get("content", res.get("description", "")), # Use description as fallback
                                                provider=tool_name
                                            ))
                                    # Add parsing logic for other tools if needed

                            except json.JSONDecodeError:
                                # If not JSON, assume it's a string summary (like qdrant_search)
                                logger.debug(f"Tool {tool_name} output is not JSON, treating as string summary.")
                                if tool_name == "qdrant_search":
                                    # Qdrant tool returns a string summary. Create a single VectorSearchResult.
                                    vector_results_list.append(VectorSearchResult(
                                        content=tool_output_str,
                                        score=0.0, # Add required score field (placeholder)
                                    provider=tool_name,
                                    # Add other fields like score, metadata if parseable or available
                                ))
                            # Keep tool_output_str as is for the LLM ToolMessage

                    except Exception as tool_err:
                        tool_output_str = f"Error executing tool {tool_name}: {tool_err}"
                        logger.error(tool_output_str, exc_info=True)
                else:
                    tool_output_str = f"Error: Tool '{tool_name}' not found."
                    logger.error(tool_output_str)

                # Append the raw tool output string to the message for the LLM
                tool_messages.append(
                    ToolMessage(
                        content=tool_output_str, # Pass the raw string output
                        tool_call_id=tool_id,
                        name=tool_name
                    )
                )

            experience_messages.extend(tool_messages)

            # --- Second LLM Call (with tool results) ---
            logger.info("Calling LLM again with tool results.")
            # Need to await the result of post_llm here
            logger.info(f"Calling post_llm with model: {model_config}")

            # Pass the complete ModelConfig object
            response = await post_llm(
                model_config=model_config,
                messages=experience_messages # Pass messages including tool results
            )

            # Check response type after second call
            if not isinstance(response, AIMessage):
                error_msg = f"Unexpected response type from experience model (second call): {type(response)}. Content: {response}"
                logger.error(error_msg)
                return ExperiencePhaseOutput(experience_response=AIMessage(content="Error processing tool results."), error=error_msg)

            logger.info(f"Experience phase second call completed. Response: {response.content[:100]}...")

        # Return the structured output
        return ExperiencePhaseOutput(
            experience_response=response,
            web_results=web_results_list,
            vector_results=vector_results_list # Will be empty if qdrant tool wasn't called or parsing failed
        )

    except Exception as e:
        logger.error(f"Error during Experience phase: {e}", exc_info=True)
        # Return structured error
        return ExperiencePhaseOutput(
            experience_response=AIMessage(content=f"Experience phase failed: {e}"),
            error=f"Experience phase failed: {e}"
        )

async def run_intention_phase(
    messages: List[BaseMessage],
    # config: Config, # REMOVED
    model_config: ModelConfig # This should now contain API keys
) -> Dict[str, Any]:
    """Runs the Intention phase using LCEL."""
    logger.info(f"Running Intention phase with model: {model_config.provider}/{model_config.model_name}")

    # Prepare prompt - include full history
    intention_query = f"<intention_instruction>{intention_instruction(model_config)}</intention_instruction>"

    intention_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=intention_query)]

    # Define the runnable chain for the intention phase
    async def _get_intention_response(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")

        # Pass the complete ModelConfig object
        return await post_llm(
            model_config=model_config,
            messages=msgs
        )
    intention_chain = RunnableLambda(_get_intention_response)

    try:
        # Invoke the chain and await the result
        response = await intention_chain.ainvoke(intention_messages)

        # Ensure response is an AIMessage before accessing .content
        if isinstance(response, AIMessage):
            logger.info(f"Intention phase completed. Response: {response.content[:100]}...")
            return {"intention_response": response}
        else:
            error_msg = f"Unexpected response type from intention model: {type(response)}. Content: {response}"
            logger.error(error_msg)
            return {"error": error_msg}

    except Exception as e:
        logger.error(f"Error during Intention phase: {e}", exc_info=True)
        return {"error": f"Intention phase failed: {e}"}

async def run_observation_phase(
    messages: List[BaseMessage],
    # config: Config, # REMOVED
    model_config: ModelConfig # This should now contain API keys
) -> Dict[str, Any]:
    """Runs the Observation phase using LCEL."""
    logger.info(f"Running Observation phase with model: {model_config.provider}/{model_config.model_name}")

    # Prepare prompt - include full history
    observation_query = f"<observation_instruction>{observation_instruction(model_config)}</observation_instruction>"

    observation_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=observation_query)]
    # Define the runnable chain for the observation phase
    async def observation_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")

        # Pass the complete ModelConfig object
        return await post_llm(
            model_config=model_config,
            messages=msgs
        )
    observation_chain = RunnableLambda(observation_wrapper)

    try:
        # Invoke the chain and await the result
        response = await observation_chain.ainvoke(observation_messages)

        # Ensure response is an AIMessage before accessing .content
        if isinstance(response, AIMessage):
            logger.info(f"Observation phase completed. Response: {response.content[:100]}...")
            # Note: This phase's output is primarily for internal state/logging.
            return {"observation_response": response}
        else:
            error_msg = f"Unexpected response type from observation model: {type(response)}. Content: {response}"
            logger.error(error_msg)
            return {"error": error_msg}

    except Exception as e:
        logger.error(f"Error during Observation phase: {e}", exc_info=True)
        return {"error": f"Observation phase failed: {e}"}

async def run_understanding_phase(
    messages: List[BaseMessage],
    # config: Config, # REMOVED
    model_config: ModelConfig # This should now contain API keys
) -> Dict[str, Any]:
    """Runs the Understanding phase using LCEL."""
    logger.info(f"Running Understanding phase with model: {model_config.provider}/{model_config.model_name}")

    # Prepare prompt - include full history
    understanding_query = f"<understanding_instruction>{understanding_instruction(model_config)}</understanding_instruction>"

    understanding_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=understanding_query)]

    # Define the runnable chain for the understanding phase
    async def understanding_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")

        # Pass the complete ModelConfig object
        return await post_llm(
            model_config=model_config,
            messages=msgs
        )
    understanding_chain = RunnableLambda(understanding_wrapper)

    try:
        # Invoke the chain and await the result
        response = await understanding_chain.ainvoke(understanding_messages)

        # Ensure response is an AIMessage before accessing .content
        if isinstance(response, AIMessage):
            logger.info(f"Understanding phase completed. Response: {response.content[:100]}...")
            # Note: This phase's output is primarily for internal state/filtering.
            return {"understanding_response": response}
        else:
            error_msg = f"Unexpected response type from understanding model: {type(response)}. Content: {response}"
            logger.error(error_msg)
            return {"error": error_msg}

    except Exception as e:
        logger.error(f"Error during Understanding phase: {e}", exc_info=True)
        return {"error": f"Understanding phase failed: {e}"}

async def run_yield_phase(
    messages: List[BaseMessage],
    # config: Config, # REMOVED
    model_config: ModelConfig # This should now contain API keys
) -> Dict[str, Any]:
    """Runs the Yield phase using LCEL."""
    logger.info(f"Running Yield phase with model: {model_config.provider}/{model_config.model_name}")

    yield_query = f"<yield_instruction>{yield_instruction(model_config)}</yield_instruction>"

    # Include system prompt and relevant history (maybe just understanding?) for final response generation
    # For simplicity, using full history here, but could be optimized
    yield_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=yield_query)]


    # Define the runnable chain for the yield phase
    async def yield_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")

        # Pass the complete ModelConfig object
        return await post_llm(
            model_config=model_config,
            messages=msgs
        )
    yield_chain = RunnableLambda(yield_wrapper)

    try:
        # Invoke the chain
        response: AIMessage = await yield_chain.ainvoke(yield_messages)
        logger.info(f"Yield phase completed. Final Response: {response.content[:100]}...")
        return {"yield_response": response, "final_content": response.content} # Include final_content in yield phase output
    except Exception as e:
        logger.error(f"Error during Yield phase: {e}", exc_info=True)
        return {"error": f"Yield phase failed: {e}"}


# --- Main Workflow ---

async def run_langchain_postchain_workflow(
    query: str,
    thread_id: str,
    message_history: List[BaseMessage],
    # config: Config, # REMOVED - Keys are now expected within the model_config overrides
    # Allow overriding models per phase for testing
    action_mc_override: Optional[ModelConfig] = None,
    experience_mc_override: Optional[ModelConfig] = None,
    intention_mc_override: Optional[ModelConfig] = None,
    observation_mc_override: Optional[ModelConfig] = None,
    understanding_mc_override: Optional[ModelConfig] = None,
    yield_mc_override: Optional[ModelConfig] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Runs the full PostChain workflow using Langchain LCEL.
    Allows overriding model selection per phase for testing.
    The provided override ModelConfig objects MUST contain the necessary API keys.
    """
    logger.info(f"Starting Langchain PostChain workflow for thread {thread_id}")

    # --- Model Configuration (Prioritize Overrides) ---
    try:
        # Use override if provided, otherwise use default with temperature set
        default_temp = 0.333  # Default temperature for all models
        action_model_config = action_mc_override if action_mc_override else ModelConfig(provider="google", model_name="gemini-2.0-flash-lite", temperature=default_temp)
        experience_model_config = experience_mc_override if experience_mc_override else ModelConfig(provider="openrouter", model_name="ai21/jamba-1.6-mini", temperature=default_temp)
        intention_model_config = intention_mc_override if intention_mc_override else ModelConfig(provider="google", model_name="gemini-2.0-flash", temperature=default_temp)
        observation_model_config = observation_mc_override if observation_mc_override else ModelConfig(provider="groq", model_name="qwen-qwq-32b", temperature=default_temp)
        understanding_model_config = understanding_mc_override if understanding_mc_override else ModelConfig(provider="openrouter", model_name="openrouter/quasar-alpha", temperature=default_temp)
        yield_model_config = yield_mc_override if yield_mc_override else ModelConfig(provider="google", model_name="gemini-2.5-pro-exp-03-25", temperature=default_temp)

        # Log the final model configuration being used for this run
        logger.info(f"Workflow Models - Action: {action_model_config}, Experience: {experience_model_config}, Intention: {intention_model_config}, Observation: {observation_model_config}, Understanding: {understanding_model_config}, Yield: {yield_model_config}")

    except Exception as e:
        logger.error(f"Failed to initialize models: {e}")
        yield {"error": f"Model initialization failed: {e}"}
        return

    # --- State Management ---
    # Load history from in-memory store and merge with passed history
    global conversation_history_store
    stored_history = conversation_history_store.get(thread_id, [])
    merged_history = stored_history + message_history
    current_messages = merged_history + [HumanMessage(content=query)]

    # --- Workflow Definition using LCEL (Simplified) ---

    # 1. Action Phase
    yield {"phase": "action", "status": "running"}
    action_result = await run_action_phase(current_messages, action_model_config)

    if "error" in action_result:
        yield {"phase": "action", "status": "error", "content": action_result["error"]}
        return # Stop workflow on error

    action_response: AIMessage = action_result["action_response"]
    current_messages.append(action_response)

    # Update in-memory history store after each phase
    conversation_history_store[thread_id] = current_messages

    yield {
        "phase": "action",
        "status": "complete",
        "content": action_response.content,
        "provider": action_model_config.provider, # Add provider
        "model_name": action_model_config.model_name # Add model name
    }

    # 2. Experience Phase
    yield {"phase": "experience", "status": "running"}
    experience_output: ExperiencePhaseOutput = await run_experience_phase(current_messages, experience_model_config)

    if experience_output.error:
        yield {
            "phase": "experience",
            "status": "error",
            "content": experience_output.error,
            "provider": experience_model_config.provider, # Add provider
            "model_name": experience_model_config.model_name, # Add model name
            "web_results": [], # Ensure lists are present even on error
            "vector_results": []
        }
        return # Stop workflow on error

    # Add the AI's response message to the history
    current_messages.append(experience_output.experience_response)

    # Update in-memory history store
    conversation_history_store[thread_id] = current_messages

    # Yield the completion event including search results
    yield {
        "phase": "experience",
        "status": "complete",
        "content": experience_output.experience_response.content,
        "provider": experience_model_config.provider, # Add provider
        "model_name": experience_model_config.model_name, # Add model name
        "web_results": [res.dict() for res in experience_output.web_results], # Convert Pydantic models to dicts for JSON serialization
        "vector_results": [res.dict() for res in experience_output.vector_results]
    }

    # 3. Intention Phase
    yield {"phase": "intention", "status": "running"}
    intention_result = await run_intention_phase(current_messages, intention_model_config)

    if "error" in intention_result:
        yield {
            "phase": "intention",
            "status": "error",
            "content": intention_result["error"],
            "provider": intention_model_config.provider, # Add provider
            "model_name": intention_model_config.model_name # Add model name
        }
        return # Stop workflow on error

    intention_response: AIMessage = intention_result["intention_response"]
    current_messages.append(intention_response)

    # Update in-memory history store
    conversation_history_store[thread_id] = current_messages

    yield {
        "phase": "intention",
        "status": "complete",
        "content": intention_response.content,
        "provider": intention_model_config.provider, # Add provider
        "model_name": intention_model_config.model_name # Add model name
    }

    # 4. Observation Phase
    yield {"phase": "observation", "status": "running"}
    observation_result = await run_observation_phase(current_messages, observation_model_config)

    if "error" in observation_result:
        yield {
            "phase": "observation",
            "status": "error",
            "content": observation_result["error"],
            "provider": observation_model_config.provider, # Add provider
            "model_name": observation_model_config.model_name # Add model name
        }
        return # Stop workflow on error

    observation_response: AIMessage = observation_result["observation_response"]
    current_messages.append(observation_response)
    # Note: Observation output is usually internal, but we yield it here for visibility during development

    # Update in-memory history store
    conversation_history_store[thread_id] = current_messages

    yield {
        "phase": "observation",
        "status": "complete",
        "content": observation_response.content,
        "provider": observation_model_config.provider, # Add provider
        "model_name": observation_model_config.model_name # Add model name
    }

    # 5. Understanding Phase
    yield {"phase": "understanding", "status": "running"}
    understanding_result = await run_understanding_phase(current_messages, understanding_model_config)

    if "error" in understanding_result:
        yield {
            "phase": "understanding",
            "status": "error",
            "content": understanding_result["error"],
            "provider": understanding_model_config.provider, # Add provider
            "model_name": understanding_model_config.model_name # Add model name
        }
        return # Stop workflow on error

    understanding_response: AIMessage = understanding_result["understanding_response"]
    current_messages.append(understanding_response)
    # Note: Understanding output is usually internal, but we yield it here for visibility

    # Update in-memory history store
    conversation_history_store[thread_id] = current_messages

    yield {
        "phase": "understanding",
        "status": "complete",
        "content": understanding_response.content,
        "provider": understanding_model_config.provider, # Add provider
        "model_name": understanding_model_config.model_name # Add model name
    }

    # 6. Yield Phase
    yield {"phase": "yield", "status": "running"}
    yield_result = await run_yield_phase(current_messages, yield_model_config)

    if "error" in yield_result:
        yield {
            "phase": "yield",
            "status": "error",
            "content": yield_result["error"],
            "provider": yield_model_config.provider, # Add provider
            "model_name": yield_model_config.model_name # Add model name
        }
        return # Stop workflow on error

    yield_response: AIMessage = yield_result["yield_response"]
    # Don't add Yield response to message history unless needed for recursion logic (omitted here)
    yield {
        "phase": "yield",
        "status": "complete",
        "final_content": yield_response.content, # Use final_content key for yield
        "provider": yield_model_config.provider, # Add provider
        "model_name": yield_model_config.model_name # Add model name
    }


    logger.info(f"Langchain PostChain workflow completed for thread {thread_id}")

# --- Example Usage (for testing) ---
async def main():
    # config = Config() # REMOVED - Config object no longer needed here
    thread_id = "test-thread-lc"
    message_history = [] # Start with empty history
    query = "What is the capital of France? Search the web if you don't know."

    # --- IMPORTANT: For this test main function to work, ---
    # --- the default ModelConfigs created in run_langchain_postchain_workflow ---
    # --- MUST now include hardcoded API keys, or this test will fail. ---
    # --- Alternatively, pass ModelConfig overrides with keys here. ---

    # Example passing overrides (replace with actual keys or load from env for testing)
    test_action_mc = ModelConfig(provider="google", model_name="gemini-2.0-flash-lite", google_api_key="YOUR_GOOGLE_KEY")
    test_experience_mc = ModelConfig(provider="openrouter", model_name="ai21/jamba-1.6-mini", openrouter_api_key="YOUR_OPENROUTER_KEY")
    # ... add other phase configs with keys ...

    async for event in run_langchain_postchain_workflow(
        query=query,
        thread_id=thread_id,
        message_history=message_history,
        # Pass overrides if needed for testing:
        # action_mc_override=test_action_mc,
        # experience_mc_override=test_experience_mc,
        # ...
    ):
        print(json.dumps(event, indent=2))
        # Add AI responses to history for subsequent phases/turns (simplified)
        if event.get("status") == "complete" and "content" in event and event.get("phase") != "yield":
             message_history.append(AIMessage(content=event["content"], additional_kwargs={"phase": event.get("phase")}))
        elif event.get("phase") == "yield" and event.get("status") == "complete":
             print("\n--- FINAL RESPONSE ---")
             print(event.get("final_content"))
             print("----------------------")


if __name__ == "__main__":
    import asyncio
    import json
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
