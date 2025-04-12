# Replacement content for /Users/wiz/Choir/api/app/postchain/langchain_workflow.py

import asyncio
import logging
from typing import List, Dict, Any, AsyncIterator, Optional
import json

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage, ToolMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough, RunnableLambda

# Local imports
from app.config import Config # Although config object isn't passed directly, defaults might still be used
from app.postchain.postchain_llm import post_llm
from app.langchain_utils import ModelConfig
# Import updated schemas
from app.postchain.schemas.state import (
    PostChainState,
    ExperienceVectorsPhaseOutput,
    ExperienceWebPhaseOutput,
    SearchResult,
    VectorSearchResult
)
from app.postchain.utils import format_stream_event
# Import updated prompts
from app.postchain.prompts.prompts import (
    action_instruction,
    experience_vectors_instruction,
    experience_web_instruction,
    intention_instruction,
    understanding_instruction,
    observation_instruction,
    yield_instruction
)

# Langchain Tool Imports
from app.tools.brave_search import BraveSearchTool # Specific tool for web search phase
from app.tools.qdrant import qdrant_search # Specific tool for vector search phase

# Configure logging
logger = logging.getLogger("postchain_langchain")

COMMON_SYSTEM_PROMPT = """
You are representing Choir's PostChain, in which many different AI models collaborate to provide an improvisational, dynamic, and contextually rich response in a single harmonized voice.
You will see <phase_instructions> embedded in user messages, which contain the instructions for the current phase. Follow these instructions carefully.
"""

# --- In-memory state store (replace with persistent store later) ---
conversation_history_store: Dict[str, List[BaseMessage]] = {}


# --- Phase Implementations using LCEL ---

async def run_action_phase(
    messages: List[BaseMessage],
    model_config: ModelConfig
) -> Dict[str, Any]:
    """Runs the Action phase using LCEL."""
    logger.info(f"Running Action phase with model: {model_config.provider}/{model_config.model_name}")

    # Prepare prompt
    last_message = messages[-1]
    if isinstance(last_message, HumanMessage):
        action_query = f"<action_instruction>{action_instruction(model_config)}</action_instruction>\n\n{last_message.content}"
        action_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages[:-1] + [HumanMessage(content=action_query)]
    else:
        logger.warning("Last message was not HumanMessage, running action phase without specific instruction injection.")
        action_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages

    try:
        logger.info(f"Directly calling post_llm with model: {model_config}")
        response = await post_llm(
            model_config=model_config,
            messages=action_messages
        )

        if isinstance(response, AIMessage):
            logger.info(f"Action phase completed. Response: {response.content[:100]}...")
            return {"action_response": response}
        else:
            error_msg = f"Unexpected response type from action model: {type(response)}. Content: {response}"
            logger.error(error_msg)
            return {"error": error_msg}

    except Exception as e:
        logger.error(f"Error during Action phase: {e}", exc_info=True)
        return {"error": f"Action phase failed: {e}"}


# --- New Phase Implementations ---

# --- Refactored Phase Implementation (Manual Vector Search) ---
from langchain_openai import OpenAIEmbeddings # Add import for embeddings
from app.database import DatabaseClient # Add import for DB client

async def run_experience_vectors_phase(
    messages: List[BaseMessage],
    model_config: ModelConfig,
    thread_id: str
) -> ExperienceVectorsPhaseOutput:
    """Runs the Experience Vectors phase: Embeds query, searches Qdrant, calls LLM with results."""
    logger.info(f"Running Experience Vectors phase (manual search) with model: {model_config.provider}/{model_config.model_name}")

    # Get necessary components
    app_config = Config() # Get app config for embedding model name etc.
    db_client = DatabaseClient(app_config) # Instantiate DB client

    # Find last user message for query content
    last_user_msg = next((m for m in reversed(messages) if isinstance(m, HumanMessage)), None)
    if not last_user_msg:
        logger.error("Could not find previous user query for Experience Vectors phase.")
        return ExperienceVectorsPhaseOutput(
            experience_vectors_response=AIMessage(content="Error: Missing user query for vector search."),
            error="Experience Vectors phase failed: Missing user query."
        )
    query_text = last_user_msg.content

    vector_results_list: List[VectorSearchResult] = []
    final_response: Optional[AIMessage] = None
    error_msg: Optional[str] = None

    try:
        # --- 1. Embed the User Query --- #
        logger.info(f"Embedding query for vector search: '{query_text[:100]}...' using {app_config.EMBEDDING_MODEL}")
        embeddings = OpenAIEmbeddings(model=app_config.EMBEDDING_MODEL, api_key=app_config.OPENAI_API_KEY) # Pass key if needed
        query_vector = await embeddings.aembed_query(query_text)

        # --- 2. Search Qdrant --- #
        logger.info(f"Searching Qdrant collection '{app_config.MESSAGES_COLLECTION}' with embedded query.")
        qdrant_raw_results = await db_client.search_vectors(query_vector, limit=app_config.SEARCH_LIMIT)
        logger.info(f"Qdrant returned {len(qdrant_raw_results)} results.")

        # --- 3. Save Query Vector --- #
        metadata = {
            "role": "user_query",
            "phase": "experience_vectors",
            "thread_id": thread_id
        }

        save_result = await db_client.store_vector(
            content=query_text,
            vector=query_vector,
            metadata=metadata
        )
        logger.info(f"Saved query vector with ID: {save_result.get('id')}")

        # --- 4. Format Qdrant Results --- #
        seen_content = set()
        for res_dict in qdrant_raw_results:
            content = res_dict.get("content")
            if content is not None and content not in seen_content:
                 try:
                     # Adapt raw result keys to VectorSearchResult schema
                     vector_results_list.append(VectorSearchResult(
                         score=res_dict.get("similarity", 0.0), # Qdrant calls it similarity
                         provider="qdrant",
                         content=content,
                         metadata=res_dict.get("metadata", {}),
                         id=res_dict.get("id")
                     ))
                     seen_content.add(content)
                 except Exception as pydantic_err:
                      logger.error(f"Error parsing Qdrant result item: {res_dict} - {pydantic_err}")

        logger.info(f"Formatted {len(vector_results_list)} unique vector search results.")

        # --- 4. Call LLM with Search Results --- #
        # Prepare context string from results
        search_context = "\n\nRelevant Information from Internal Documents:\n"
        if vector_results_list:
            for i, res in enumerate(vector_results_list):
                 search_context += f"{i+1}. [Score: {res.score:.3f}] {res.content}\n"
        else:
            search_context += "No relevant information found in internal documents.\n"
        search_context += "\n"

        # Find last AI message (likely Action response) to include in context
        last_ai_msg = next((m for m in reversed(messages) if isinstance(m, AIMessage)), None)

        # Prepare prompt for LLM (NO TOOL USAGE THIS TIME)
        instruction = experience_vectors_instruction(model_config) # Get base instruction
        phase_query = f"""<experience_vectors_instruction>{instruction}</experience_vectors_instruction>

Original Query: {last_user_msg.content}
{f'Previous Response: {last_ai_msg.content}' if last_ai_msg else ''}
{search_context}
Your task: Synthesize the information above and the conversation history to respond to the original query. DO NOT call any tools.
"""
        # Use current message history PLUS the new query incorporating search results
        phase_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=phase_query)]

        logger.info("Calling LLM to synthesize vector search results.")
        llm_response = await post_llm(
            model_config=model_config,
            messages=phase_messages,
            tools=None # Explicitly disable tools for this call
        )

        if not isinstance(llm_response, AIMessage):
            raise ValueError(f"Unexpected response type from synthesis LLM: {type(llm_response)}. Content: {llm_response}")

        final_response = llm_response
        logger.info(f"Experience Vectors phase synthesis completed. Response: {final_response.content[:100]}...")

    except Exception as e:
        logger.error(f"Error during Experience Vectors phase (manual search): {e}", exc_info=True)
        error_msg = f"Experience Vectors phase failed: {e}"
        # Use a generic error message if LLM call failed before assignment
        final_response = final_response or AIMessage(content=f"Error in phase: {e}")

    # Return the structured output
    return ExperienceVectorsPhaseOutput(
        experience_vectors_response=final_response,
        vector_results=vector_results_list,
        error=error_msg
    )


async def run_experience_web_phase(
    messages: List[BaseMessage],
    model_config: ModelConfig
) -> ExperienceWebPhaseOutput:
    """Runs the Experience Web phase using LCEL (Web Search)."""
    logger.info(f"Running Experience Web phase with model: {model_config.provider}/{model_config.model_name}")

    # Instantiate the specific tool needed for this phase
    web_search_tool = BraveSearchTool() # Using Brave directly for simplicity
    tools = [web_search_tool]
    tool_map = {t.name: t for t in tools} # Should just be 'brave_search'

    # Prepare prompt - Include history up to Experience Vectors phase
    last_user_msg = next((m for m in reversed(messages) if isinstance(m, HumanMessage)), None)
    # Find last AI message (could be Action or Experience Vectors)
    last_ai_msg = next((m for m in reversed(messages) if isinstance(m, AIMessage)), None)

    if not last_user_msg or not last_ai_msg:
        logger.error("Could not find previous user query or AI response for Experience Web phase.")
        return ExperienceWebPhaseOutput(
            experience_web_response=AIMessage(content="Error: Missing context for web search."),
            error="Experience Web phase failed: Missing context."
        )

    phase_query = f"""<experience_web_instruction>{experience_web_instruction(model_config)}</experience_web_instruction>

Original Query: {last_user_msg.content}
Conversation History: [Review previous messages]

Your task: Decide if web search is needed and call BraveSearchTool if relevant. Summarize findings or integrate them into your response.
"""
    phase_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=phase_query)]

    # Define the runnable chain
    async def _get_response(msgs):
        return await post_llm(model_config=model_config, messages=msgs, tools=tools)
    chain = RunnableLambda(_get_response)

    web_results_list: List[SearchResult] = []
    final_response: Optional[AIMessage] = None

    try:
        # --- Initial LLM Call ---
        response = await chain.ainvoke(phase_messages)
        final_response = response

        if not isinstance(response, AIMessage):
            raise ValueError(f"Unexpected response type from model: {type(response)}. Content: {response}")

        logger.info(f"Experience Web phase initial call completed. Response: {response.content[:100]}...")

        # --- Tool Call Handling (Simplified for single tool) ---
        tool_messages: List[ToolMessage] = []
        if hasattr(response, 'tool_calls') and response.tool_calls:
            logger.info(f"Detected {len(response.tool_calls)} tool calls for Experience Web.")
            phase_messages.append(response)

            for tool_call in response.tool_calls:
                tool_name = tool_call.get("name")
                tool_args = tool_call.get("args")
                tool_id = tool_call.get("id")

                # Expecting 'brave_search'
                if tool_name != web_search_tool.name:
                    logger.warning(f"Ignoring unexpected tool call in Experience Web phase: {tool_name}")
                    tool_output_str = f"Error: Tool '{tool_name}' is not allowed in this phase."
                else:
                    logger.info(f"Executing tool: {tool_name} with args: {tool_args}")
                    tool_to_execute = tool_map.get(tool_name)
                    tool_output_str = ""

                    if tool_to_execute:
                        try:
                            input_arg_val = None
                            if isinstance(tool_args, dict):
                                input_arg_val = tool_args.get('query', tool_args)
                                if not isinstance(input_arg_val, str): input_arg_val = str(input_arg_val)
                            elif isinstance(tool_args, str):
                                input_arg_val = tool_args

                            if input_arg_val is not None:
                                # --- Execute Web Search Tool ---
                                tool_output_json_str = await tool_to_execute.run(input_arg_val)
                                tool_output_str = tool_output_json_str # Keep JSON string for ToolMessage

                                # --- Parse Web Search Output ---
                                try:
                                    parsed_output = json.loads(tool_output_json_str)
                                    # Expecting format like {"results": [...]}
                                    if isinstance(parsed_output, dict) and "results" in parsed_output:
                                        raw_results = parsed_output.get("results", [])
                                        if isinstance(raw_results, list):
                                            for res_dict in raw_results:
                                                try:
                                                    # Add provider if missing
                                                    res_dict.setdefault("provider", tool_name)
                                                    web_results_list.append(SearchResult(**res_dict))
                                                except Exception as pydantic_err:
                                                    logger.error(f"Error parsing Web Search result item: {res_dict} - {pydantic_err}")
                                        else:
                                            logger.warning(f"Web Search 'results' field was not a list: {type(raw_results)}")
                                    else:
                                        logger.warning(f"Web Search tool output JSON did not contain a 'results' key or was not a dict: {tool_output_json_str[:200]}...")

                                except json.JSONDecodeError:
                                    logger.error(f"Web Search tool output was not valid JSON: {tool_output_json_str[:200]}...")
                                except Exception as parse_err:
                                     logger.error(f"Error processing Web Search JSON output: {parse_err}", exc_info=True)

                            else:
                                tool_output_str = f"Error: Invalid arguments for {tool_name}: {tool_args}"
                                logger.error(tool_output_str)

                        except Exception as tool_err:
                            tool_output_str = f"Error executing tool {tool_name}: {tool_err}"
                            logger.error(tool_output_str, exc_info=True)
                    else:
                        # Should not happen if tool_name is checked
                        tool_output_str = f"Error: Tool '{tool_name}' not found internally."
                        logger.error(tool_output_str)

                tool_messages.append(ToolMessage(content=tool_output_str, tool_call_id=tool_id, name=tool_name))

            if tool_messages:
                phase_messages.extend(tool_messages)

                # --- Second LLM Call (with tool results) ---
                logger.info("Calling LLM again with Experience Web tool results.")
                response_after_tool = await chain.ainvoke(phase_messages)

                if not isinstance(response_after_tool, AIMessage):
                     raise ValueError(f"Unexpected response type from model (after tool call): {type(response_after_tool)}. Content: {response_after_tool}")

                final_response = response_after_tool
                logger.info(f"Experience Web phase second call completed. Response: {final_response.content[:100]}...")

        # Return the structured output
        if final_response is None:
            final_response = AIMessage(content="Error: Phase failed before generating a response.")

        return ExperienceWebPhaseOutput(
            experience_web_response=final_response,
            web_results=web_results_list
        )

    except Exception as e:
        logger.error(f"Error during Experience Web phase: {e}", exc_info=True)
        error_msg = f"Experience Web phase failed: {e}"
        # Return structured error
        return ExperienceWebPhaseOutput(
            experience_web_response=final_response or AIMessage(content=f"Error in phase: {e}"),
            web_results=web_results_list, # Return any results found before error
            error=error_msg
        )

# --- Other Phase Implementations (Intention, Observation, Understanding, Yield - unchanged) ---

async def run_intention_phase(
    messages: List[BaseMessage],
    model_config: ModelConfig
) -> Dict[str, Any]:
    """Runs the Intention phase using LCEL."""
    logger.info(f"Running Intention phase with model: {model_config.provider}/{model_config.model_name}")
    intention_query = f"<intention_instruction>{intention_instruction(model_config)}</intention_instruction>"
    intention_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=intention_query)]

    async def _get_intention_response(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")
        return await post_llm(model_config=model_config, messages=msgs)
    intention_chain = RunnableLambda(_get_intention_response)

    try:
        response = await intention_chain.ainvoke(intention_messages)
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
    model_config: ModelConfig
) -> Dict[str, Any]:
    """Runs the Observation phase using LCEL."""
    logger.info(f"Running Observation phase with model: {model_config.provider}/{model_config.model_name}")
    observation_query = f"<observation_instruction>{observation_instruction(model_config)}</observation_instruction>"
    observation_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=observation_query)]

    async def observation_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")
        return await post_llm(model_config=model_config, messages=msgs)
    observation_chain = RunnableLambda(observation_wrapper)

    try:
        response = await observation_chain.ainvoke(observation_messages)
        if isinstance(response, AIMessage):
            logger.info(f"Observation phase completed. Response: {response.content[:100]}...")
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
    model_config: ModelConfig
) -> Dict[str, Any]:
    """Runs the Understanding phase using LCEL."""
    logger.info(f"Running Understanding phase with model: {model_config.provider}/{model_config.model_name}")
    understanding_query = f"<understanding_instruction>{understanding_instruction(model_config)}</understanding_instruction>"
    understanding_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=understanding_query)]

    async def understanding_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")
        return await post_llm(model_config=model_config, messages=msgs)
    understanding_chain = RunnableLambda(understanding_wrapper)

    try:
        response = await understanding_chain.ainvoke(understanding_messages)
        if isinstance(response, AIMessage):
            logger.info(f"Understanding phase completed. Response: {response.content[:100]}...")
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
    model_config: ModelConfig
) -> Dict[str, Any]:
    """Runs the Yield phase using LCEL."""
    logger.info(f"Running Yield phase with model: {model_config.provider}/{model_config.model_name}")
    yield_query = f"<yield_instruction>{yield_instruction(model_config)}</yield_instruction>"
    yield_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=yield_query)]

    async def yield_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")
        return await post_llm(model_config=model_config, messages=msgs)
    yield_chain = RunnableLambda(yield_wrapper)

    try:
        response: AIMessage = await yield_chain.ainvoke(yield_messages)
        logger.info(f"Yield phase completed. Final Response: {response.content[:100]}...")
        return {"yield_response": response, "final_content": response.content}
    except Exception as e:
        logger.error(f"Error during Yield phase: {e}", exc_info=True)
        return {"error": f"Yield phase failed: {e}"}


# --- Main Workflow (Updated) ---

async def run_langchain_postchain_workflow(
    query: str,
    thread_id: str,
    message_history: List[BaseMessage],
    # Allow overriding models per phase for testing
    action_mc_override: Optional[ModelConfig] = None,
    experience_vectors_mc_override: Optional[ModelConfig] = None, # New override
    experience_web_mc_override: Optional[ModelConfig] = None,     # New override
    intention_mc_override: Optional[ModelConfig] = None,
    observation_mc_override: Optional[ModelConfig] = None,
    understanding_mc_override: Optional[ModelConfig] = None,
    yield_mc_override: Optional[ModelConfig] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Runs the full PostChain workflow using Langchain LCEL with split Experience phases.
    Allows overriding model selection per phase for testing.
    The provided override ModelConfig objects can optionally contain API keys,
    otherwise defaults from the environment will be used.
    """
    logger.info(f"Starting Langchain PostChain workflow for thread {thread_id}")

    # --- Model Configuration (Prioritize Overrides) ---
    try:
        default_temp = 0.333
        action_model_config = action_mc_override or ModelConfig(provider="google", model_name="gemini-2.0-flash-lite", temperature=default_temp)
        # Assign defaults for new phases
        experience_vectors_model_config = experience_vectors_mc_override or ModelConfig(provider="openrouter", model_name="x-ai/grok-3-mini-beta", temperature=default_temp)
        experience_web_model_config = experience_web_mc_override or ModelConfig(provider="google", model_name="gemini-2.0-flash-lite", temperature=default_temp) # Can use same default or different
        intention_model_config = intention_mc_override or ModelConfig(provider="openrouter", model_name="x-ai/grok-3-mini-beta", temperature=default_temp)
        observation_model_config = observation_mc_override or ModelConfig(provider="groq", model_name="qwen-qwq-32b", temperature=default_temp)
        understanding_model_config = understanding_mc_override or ModelConfig(provider="openrouter", model_name="openrouter/optimus-alpha", temperature=default_temp)
        yield_model_config = yield_mc_override or ModelConfig(provider="openrouter", model_name="x-ai/grok-3-mini-beta", temperature=default_temp)

        logger.info(f"Workflow Models - Action: {action_model_config}, ExpVectors: {experience_vectors_model_config}, ExpWeb: {experience_web_model_config}, Intention: {intention_model_config}, Observation: {observation_model_config}, Understanding: {understanding_model_config}, Yield: {yield_model_config}")

    except Exception as e:
        logger.error(f"Failed to initialize models: {e}")
        yield {"error": f"Model initialization failed: {e}"}
        return

    # --- State Management ---
    global conversation_history_store
    stored_history = conversation_history_store.get(thread_id, [])
    merged_history = stored_history + message_history
    current_messages = merged_history + [HumanMessage(content=query)]

    # --- Workflow Sequence ---

    # 1. Action Phase
    yield {"phase": "action", "status": "running"}
    action_result = await run_action_phase(current_messages, action_model_config)
    if "error" in action_result:
        yield {"phase": "action", "status": "error", "content": action_result["error"]}
        return
    action_response: AIMessage = action_result["action_response"]
    current_messages.append(action_response)
    conversation_history_store[thread_id] = current_messages
    yield {
        "phase": "action", "status": "complete", "content": action_response.content,
        "provider": action_model_config.provider, "model_name": action_model_config.model_name
    }

    # 2. Experience Vectors Phase
    yield {"phase": "experience_vectors", "status": "running"}
    exp_vectors_output: ExperienceVectorsPhaseOutput = await run_experience_vectors_phase(current_messages, experience_vectors_model_config, thread_id=thread_id)
    if exp_vectors_output.error:
        yield {
            "phase": "experience_vectors", "status": "error", "content": exp_vectors_output.error,
            "provider": experience_vectors_model_config.provider, "model_name": experience_vectors_model_config.model_name,
            "vector_results": [res.dict() for res in exp_vectors_output.vector_results] # Include partial results on error
        }
        return
    current_messages.append(exp_vectors_output.experience_vectors_response)
    conversation_history_store[thread_id] = current_messages
    yield {
        "phase": "experience_vectors", "status": "complete", "content": exp_vectors_output.experience_vectors_response.content,
        "provider": experience_vectors_model_config.provider, "model_name": experience_vectors_model_config.model_name,
        "vector_results": [res.dict() for res in exp_vectors_output.vector_results] # Key for results
    }

    # 3. Experience Web Phase
    yield {"phase": "experience_web", "status": "running"}
    exp_web_output: ExperienceWebPhaseOutput = await run_experience_web_phase(current_messages, experience_web_model_config)
    if exp_web_output.error:
        yield {
            "phase": "experience_web", "status": "error", "content": exp_web_output.error,
            "provider": experience_web_model_config.provider, "model_name": experience_web_model_config.model_name,
            "web_results": [res.dict() for res in exp_web_output.web_results] # Include partial results on error
        }
        return
    current_messages.append(exp_web_output.experience_web_response)
    conversation_history_store[thread_id] = current_messages
    yield {
        "phase": "experience_web", "status": "complete", "content": exp_web_output.experience_web_response.content,
        "provider": experience_web_model_config.provider, "model_name": experience_web_model_config.model_name,
        "web_results": [res.dict() for res in exp_web_output.web_results] # Key for results
    }

    # 4. Intention Phase
    yield {"phase": "intention", "status": "running"}
    intention_result = await run_intention_phase(current_messages, intention_model_config)
    if "error" in intention_result:
        yield {
            "phase": "intention", "status": "error", "content": intention_result["error"],
             "provider": intention_model_config.provider, "model_name": intention_model_config.model_name
        }
        return
    intention_response: AIMessage = intention_result["intention_response"]
    current_messages.append(intention_response)
    conversation_history_store[thread_id] = current_messages
    yield {
        "phase": "intention", "status": "complete", "content": intention_response.content,
        "provider": intention_model_config.provider, "model_name": intention_model_config.model_name
    }

    # 5. Observation Phase
    yield {"phase": "observation", "status": "running"}
    observation_result = await run_observation_phase(current_messages, observation_model_config)
    if "error" in observation_result:
        yield {
            "phase": "observation", "status": "error", "content": observation_result["error"],
            "provider": observation_model_config.provider, "model_name": observation_model_config.model_name
        }
        return
    observation_response: AIMessage = observation_result["observation_response"]
    current_messages.append(observation_response)
    conversation_history_store[thread_id] = current_messages
    yield {
        "phase": "observation", "status": "complete", "content": observation_response.content,
        "provider": observation_model_config.provider, "model_name": observation_model_config.model_name
    }

    # 6. Understanding Phase
    yield {"phase": "understanding", "status": "running"}
    understanding_result = await run_understanding_phase(current_messages, understanding_model_config)
    if "error" in understanding_result:
        yield {
            "phase": "understanding", "status": "error", "content": understanding_result["error"],
            "provider": understanding_model_config.provider, "model_name": understanding_model_config.model_name
        }
        return
    understanding_response: AIMessage = understanding_result["understanding_response"]
    current_messages.append(understanding_response)
    conversation_history_store[thread_id] = current_messages
    yield {
        "phase": "understanding", "status": "complete", "content": understanding_response.content,
        "provider": understanding_model_config.provider, "model_name": understanding_model_config.model_name
    }

    # 7. Yield Phase
    yield {"phase": "yield", "status": "running"}
    yield_result = await run_yield_phase(current_messages, yield_model_config)
    if "error" in yield_result:
        yield {
            "phase": "yield", "status": "error", "content": yield_result["error"],
            "provider": yield_model_config.provider, "model_name": yield_model_config.model_name
        }
        return
    yield_response: AIMessage = yield_result["yield_response"]
    # Don't add Yield to history for now
    yield {
        "phase": "yield", "status": "complete", "final_content": yield_response.content,
        "provider": yield_model_config.provider, "model_name": yield_model_config.model_name
    }


    logger.info(f"Langchain PostChain workflow completed for thread {thread_id}")

# --- Example Usage (for testing - needs update for new overrides) ---
async def main():
    thread_id = "test-thread-lc-split"
    message_history = []
    query = "Tell me about the latest developments in large language models. Search web and internal docs."

    # Example passing overrides (replace with actual keys or load from env for testing)
    # test_action_mc = ModelConfig(provider="google", model_name="gemini-2.0-flash-lite", google_api_key="YOUR_GOOGLE_KEY")
    # test_exp_vectors_mc = ModelConfig(provider="openrouter", model_name="...", openrouter_api_key="YOUR_OR_KEY", ...)
    # test_exp_web_mc = ModelConfig(provider="openrouter", model_name="...", openrouter_api_key="YOUR_OR_KEY", brave_api_key="YOUR_BRAVE_KEY", ...)

    print(f"--- Starting Workflow for Query: {query} ---")
    async for event in run_langchain_postchain_workflow(
        query=query,
        thread_id=thread_id,
        message_history=message_history,
        # Pass overrides if needed for testing:
        # action_mc_override=test_action_mc,
        # experience_vectors_mc_override=test_exp_vectors_mc,
        # experience_web_mc_override=test_exp_web_mc,
    ):
        print(json.dumps(event, indent=2))
        # Update history (simplified)
        if event.get("status") == "complete":
             phase = event.get("phase")
             content = event.get("content") or event.get("final_content")
             response_msg = None
             if phase == "action" and content:
                 # Need access to the original result dict to get the AIMessage object
                 # This simplified history tracking in main() won't work perfectly without refactoring how results are stored/passed
                 # For the sake of testing, we'll just create a new AIMessage
                 response_msg = AIMessage(content=content, additional_kwargs={"phase": phase})
             elif phase == "experience_vectors" and content:
                 # Same issue as above
                 response_msg = AIMessage(content=content, additional_kwargs={"phase": phase})
             elif phase == "experience_web" and content:
                 # Same issue as above
                 response_msg = AIMessage(content=content, additional_kwargs={"phase": phase})
             elif phase == "intention" and content:
                 # Same issue as above
                 response_msg = AIMessage(content=content, additional_kwargs={"phase": phase})
             elif phase == "observation" and content:
                  # Same issue as above
                  response_msg = AIMessage(content=content, additional_kwargs={"phase": phase})
             elif phase == "understanding" and content:
                  # Same issue as above
                  response_msg = AIMessage(content=content, additional_kwargs={"phase": phase})
             # Don't add yield to history

             if response_msg and isinstance(response_msg, AIMessage):
                 message_history.append(response_msg)

             if phase == "yield" and content:
                 print("\n--- FINAL RESPONSE ---")
                 print(content)
                 print("----------------------")

if __name__ == "__main__":
    import asyncio
    import json
    logging.basicConfig(level=logging.INFO)
    # Set higher level for noisy libraries if needed
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    asyncio.run(main())
