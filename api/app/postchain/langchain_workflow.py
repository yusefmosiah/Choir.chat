# Replacement content for /Users/wiz/Choir/api/app/postchain/langchain_workflow.py
#
# IMPORTANT OPTIMIZATION NOTES:
# -----------------------------
# 1. This file contains performance optimizations to prevent client-side freezing issues:
#    - MAX_RETRIEVED_CONTENT_LENGTH is set to 2000 chars to prevent large payloads
#    - MAX_VECTOR_RESULTS limits vector results returned to the client to 10
#    - Vector content sent to client is truncated to 100 chars for preview
#    - Qdrant search limit has been reduced from 80 to 20 results
#
# 2. Long user inputs (>25k chars) have special handling:
#    - For large user inputs, we embed the Action response instead of the full prompt
#    - This avoids truncation issues with embeddings and provides more relevant vectors
#    - We store a truncated prompt with full Action response for better context retrieval
#
# 3. Duplicate prevention is implemented via prompt hash and similarity checking

import asyncio
import hashlib
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

# Constants for content limits
MAX_RETRIEVED_CONTENT_LENGTH = 2000  # Maximum length for retrieved content from Qdrant (reduced to prevent client-side hanging)
MAX_INPUT_LENGTH_FOR_EMBEDDING = 25000  # Maximum length for direct embedding (avoid excessive tokens)
PROMPT_TRUNCATION_LENGTH = 500  # How much of a long prompt to include when storing with Action response
SIMILARITY_EPSILON = 1e-6  # Small tolerance for floating point comparison
# Limit vector search results to reduce payload size
MAX_VECTOR_RESULTS = 10  # Maximum number of vector results to return to client

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
    """Runs the Experience Vectors phase: Embeds query, searches Qdrant, calls LLM with results.

    This implementation includes several optimizations for handling large amounts of text:

    1. Content Length Management:
       - For long user prompts (>MAX_INPUT_LENGTH_FOR_EMBEDDING chars), we embed the Action
         response instead of the prompt to avoid truncation issues with the embedding model
       - When storing long prompts, we save a truncated version of the prompt plus the
         full Action response
       - Retrieved content is truncated to MAX_RETRIEVED_CONTENT_LENGTH chars to prevent
         client-side performance issues

    2. Duplicate Prevention:
       - Calculates similarity between the current embedding and existing vectors
       - Skips saving if an exact match (similarity ≈ 1.0) is found
       - Uses prompt hash in metadata for potential future optimizations
    """
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
        # --- 1. Embed the User Query or Action Response --- #
        query_vector = None
        content_to_store = query_text  # Default content to store
        embedded_content_type = "user_prompt"  # Default type

        # Calculate prompt hash regardless of length (used for metadata)
        normalized_prompt = query_text.strip()  # Basic normalization
        prompt_hash = hashlib.sha256(normalized_prompt.encode('utf-8')).hexdigest()

        embeddings = OpenAIEmbeddings(model=app_config.EMBEDDING_MODEL, api_key=app_config.OPENAI_API_KEY)

        if len(query_text) <= MAX_INPUT_LENGTH_FOR_EMBEDDING:
            logger.info(f"Prompt is short ({len(query_text)} chars). Embedding user prompt.")
            query_vector = await embeddings.aembed_query(query_text)
            # content_to_store remains query_text
            # embedded_content_type remains "user_prompt"
        else:
            logger.info(f"Prompt is long ({len(query_text)} chars). Embedding Action response instead.")
            # Extract Action response content (assuming it's the last AI message in history)
            action_response_content = "Error: Action response not found."  # Default error message
            last_ai_msg = next((m for m in reversed(messages) if isinstance(m, AIMessage)), None)
            if last_ai_msg and hasattr(last_ai_msg, 'content'):
                action_response_content = last_ai_msg.content
                logger.info("Found Action response content to embed.")
            else:
                logger.error("Could not find Action response in message history to embed for long prompt.")
                # Decide handling: Proceed with error content? Skip embedding/saving? Let's proceed for now.

            # Embed the Action response
            query_vector = await embeddings.aembed_query(action_response_content)
            embedded_content_type = "action_response"

            # Prepare content to store: truncated prompt + action response
            truncated_prompt = query_text[:PROMPT_TRUNCATION_LENGTH] + "..."
            content_to_store = f"--- User Prompt (Truncated) ---\n{truncated_prompt}\n\n--- Action Response ---\n{action_response_content}"

        # Ensure query_vector is not None before proceeding
        if query_vector is None:
            logger.error("Failed to generate query vector. Skipping search and save.")
            return ExperienceVectorsPhaseOutput(
                experience_vectors_response=AIMessage(content="Error: Could not process query embedding."),
                error="Embedding failed."
            )

        # --- 2. Search Qdrant --- #
        logger.info(f"Searching Qdrant collection '{app_config.MESSAGES_COLLECTION}' with embedded query.")
        # Use a smaller limit for search to reduce processing overhead
        search_limit = min(20, app_config.SEARCH_LIMIT)  # Reduce the search limit from default (80)
        qdrant_raw_results = await db_client.search_vectors(query_vector, limit=search_limit)
        logger.info(f"Qdrant returned {len(qdrant_raw_results)} results from limit {search_limit}.")

        # --- 3. Check for Exact Duplicates --- #
        max_similarity = 0.0
        if qdrant_raw_results:
            # Ensure similarity scores are treated as floats
            scores = [float(res.get("similarity", 0.0)) for res in qdrant_raw_results]
            if scores:
                max_similarity = max(scores)

        # Skip saving if we find an exact duplicate
        should_save_query = (max_similarity < (1.0 - SIMILARITY_EPSILON))

        if not should_save_query:
            logger.info(f"Max similarity ({max_similarity:.6f}) is effectively 1.0. Skipping save for this vector.")
        else:
            # --- Save Query Vector --- #
            metadata = {
                "role": "user_query_embedding",
                "embedded_content_type": embedded_content_type,
                "phase": "experience_vectors",
                "thread_id": thread_id,
                "prompt_hash": prompt_hash,
                "original_prompt_length": len(query_text),
            }

            save_result = await db_client.store_vector(
                content=content_to_store,
                vector=query_vector,
                metadata=metadata
            )
            logger.info(f"Saved vector (type: {embedded_content_type}) with ID: {save_result.get('id')}")

        # --- 4. Format Qdrant Results --- #
        seen_content = set()
        for res_dict in qdrant_raw_results:
            content = res_dict.get("content")
            if content is not None and content not in seen_content:
                 try:
                     # Create a preview version for shorter payload
                     content_preview = content
                     if len(content) > 100:
                         content_preview = content[:100] + "..."

                     # For very long content, also create a shorter version for the main content field
                     stored_content = content
                     if len(content) > MAX_RETRIEVED_CONTENT_LENGTH:
                         stored_content = content[:MAX_RETRIEVED_CONTENT_LENGTH] + "..."
                         logger.warning(f"Truncated retrieved content from point {res_dict.get('id')} due to length ({len(content)} chars -> {MAX_RETRIEVED_CONTENT_LENGTH} chars).")

                     # Adapt raw result keys to VectorSearchResult schema
                     vector_results_list.append(VectorSearchResult(
                         score=res_dict.get("similarity", 0.0), # Qdrant calls it similarity
                         provider="qdrant",
                         content=stored_content,
                         content_preview=content_preview,
                         metadata=res_dict.get("metadata", {}),
                         id=res_dict.get("id")
                     ))
                     seen_content.add(content)
                 except Exception as pydantic_err:
                      logger.error(f"Error parsing Qdrant result item: {res_dict} - {pydantic_err}")

        logger.info(f"Formatted {len(vector_results_list)} unique vector search results.")

        # --- 4. Call LLM with Search Results --- #
        # Prepare context string from results in the format specified in the prompt
        search_context = "\n\nRelevant Information from Internal Documents:\n"
        if vector_results_list:
            # Add results in simplified code block format
            for i, res in enumerate(vector_results_list):
                # Use the position number (1-based) as the reference, not the actual UUID
                position_number = i + 1
                # Include the ID in the context for potential future retrieval
                vector_id = f"ID: {res.id}" if res.id else ""

                # Use content preview if it exists, otherwise a short version of the content
                display_content = res.content
                if hasattr(res, 'content_preview') and res.content_preview:
                    display_content = res.content_preview
                elif len(res.content) > 200:
                    display_content = res.content[:200] + "..."

                search_context += f"""
```
#{position_number} | {res.score:.2f} {vector_id}
{display_content}
```

"""
        else:
            search_context += "No relevant information found in internal documents.\n"

        # Add explicit instruction about the reference syntax
        search_context += "\nIMPORTANT: When referencing any vector result in your response, use the #ID syntax (e.g., #123). These references will be converted to clickable links in the UI, allowing users to view the full content of each result. You MUST use this syntax whenever referring to specific vector results.\n\n"

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

    # Find vector results that are referenced in the response
    referenced_vector_results = []

    if final_response and vector_results_list:
        # Use our helper function to extract referenced vectors
        referenced_vector_results = get_referenced_vectors(
            final_response.content,
            vector_results_list
        )

        # If no references were found or no valid references exist, include default vectors as fallback
        if not referenced_vector_results:
            logger.info(f"No valid vector references found, including up to {MAX_VECTOR_RESULTS} default vectors")
            referenced_vector_results = vector_results_list[:MAX_VECTOR_RESULTS]

    # Log the final selection of vectors
    if vector_results_list:
        logger.info(f"Selected {len(referenced_vector_results)} out of {len(vector_results_list)} total vector results to return to client")

    # Return the structured output with the referenced vectors
    return ExperienceVectorsPhaseOutput(
        experience_vectors_response=final_response,
        vector_results=referenced_vector_results,
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
                                logger.info(f"Web search tool output: {tool_output_json_str[:200]}...")
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

                # Add explicit web search results summary to help the model format results properly
                if web_results_list:
                    web_results_summary = "\n\nWeb Search Results:\n"
                    for i, result in enumerate(web_results_list):
                        # Format in the simplified way specified in the prompt
                        web_results_summary += f"[{result.title}]({result.url})\n"
                        web_results_summary += f"> {result.content}\n\n"

                    # Add this as a human message to make it clear these are the results
                    phase_messages.append(HumanMessage(content=f"""
The web search returned {len(web_results_list)} results. Please incorporate the most relevant ones into your response
using the inline link + blockquote format as instructed, and then synthesize the information to answer the query.

{web_results_summary}
"""))

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

        # Limit the number of web results sent to the client to prevent performance issues
        # We'll still use all results for the LLM synthesis internally, but limit what's sent to the client
        limited_web_results = web_results_list[:MAX_VECTOR_RESULTS] if web_results_list else []
        if len(web_results_list) > MAX_VECTOR_RESULTS:
            logger.info(f"Limiting web results returned to client from {len(web_results_list)} to {MAX_VECTOR_RESULTS}")

        return ExperienceWebPhaseOutput(
            experience_web_response=final_response,
            web_results=limited_web_results
        )

    except Exception as e:
        logger.error(f"Error during Experience Web phase: {e}", exc_info=True)
        error_msg = f"Experience Web phase failed: {e}"
        # Limit the number of web results sent to the client to prevent performance issues
        limited_web_results = web_results_list[:MAX_VECTOR_RESULTS] if web_results_list else []
        if len(web_results_list) > MAX_VECTOR_RESULTS:
            logger.info(f"Limiting web results on error from {len(web_results_list)} to {MAX_VECTOR_RESULTS}")

        # Return structured error
        return ExperienceWebPhaseOutput(
            experience_web_response=final_response or AIMessage(content=f"Error in phase: {e}"),
            web_results=limited_web_results, # Return limited results found before error
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
        logger.info(f"🐍 YIELD PHASE: Raw response content length: {len(response.content)}. Content snippet: '{response.content[:100]}...'" if hasattr(response, 'content') else "🐍 YIELD PHASE: Raw response has no content attribute") # DEBUG LOG
        logger.info(f"Yield phase completed. Final Response: {response.content[:100]}...")
        return {"yield_response": response}
    except Exception as e:
        logger.error(f"Error during Yield phase: {e}", exc_info=True)
        return {"error": f"Yield phase failed: {e}"}


# --- Main Workflow (Updated) ---

# Helper function to extract vector references from text and fetch the corresponding vectors
def get_referenced_vectors(text, available_vectors):
    """
    Extract vector references from text and return the referenced vectors.

    Args:
        text (str): The text to search for vector references
        available_vectors (list): List of VectorSearchResult objects

    Returns:
        list: The vector results that are referenced in the text
    """
    import re
    referenced_vectors = []

    # Extract all #number references
    vector_refs = re.findall(r'#(\d+)', text)
    if not vector_refs:
        return []

    # Convert to integers and get unique values
    referenced_indices = sorted(set(int(ref) for ref in vector_refs if ref.isdigit()))
    logger.info(f"Found vector references: {referenced_indices}")

    # Get the referenced vectors
    for ref_num in referenced_indices:
        array_idx = ref_num - 1  # Convert 1-based to 0-based
        if 0 <= array_idx < len(available_vectors):
            referenced_vectors.append(available_vectors[array_idx])
            logger.info(f"Including vector #{ref_num}")
        else:
            logger.warning(f"Vector reference #{ref_num} is out of range (1-{len(available_vectors)})")

    return referenced_vectors

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
        understanding_model_config = understanding_mc_override or ModelConfig(provider="openai", model_name="gpt-4.1-mini", temperature=default_temp)
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
        # Use same format for error case, but include full content
        vector_result_data = []
        for res in exp_vectors_output.vector_results:
            compact_result = {
                "score": round(res.score, 3),
                "id": getattr(res, "id", None),
                # Include first 3 paragraphs or up to 500 chars of content
                "content": "\n\n".join(res.content.split("\n\n")[:3])[:500] if res.content else res.content,
                # Always include preview
                "content_preview": res.content_preview if hasattr(res, "content_preview") and res.content_preview else (res.content[:100] + "..." if len(res.content) > 100 else res.content)
            }
            vector_result_data.append(compact_result)

        yield {
            "phase": "experience_vectors", "status": "error", "content": exp_vectors_output.error,
            "provider": experience_vectors_model_config.provider, "model_name": experience_vectors_model_config.model_name,
            "vector_results": vector_result_data # Include compact partial results on error
        }
        return
    current_messages.append(exp_vectors_output.experience_vectors_response)
    conversation_history_store[thread_id] = current_messages
    # Generate a compact payload with ALL vector results that were used by the LLM
    vector_result_data = []

    # Log detailed information about the vector results available
    logger.info(f"Experience Vectors phase has {len(exp_vectors_output.vector_results) if exp_vectors_output.vector_results else 0} vector results available")

    # Add a test vector if none exist to help debug client-side handling
    if not exp_vectors_output.vector_results or len(exp_vectors_output.vector_results) == 0:
        logger.warning("No vector results found. Adding a test vector to debug client-side handling.")
        test_vector = {
            "score": 0.95,
            "id": "test-vector-1",  # ID is critical for fetching full content later
            "content": "This is a test vector content to verify client rendering.",  # Short content for testing
            "content_preview": "This is a test vector content preview."
        }
        vector_result_data.append(test_vector)
    else:
        # Include ALL vector results that were available to the LLM
        logger.info(f"Including all {len(exp_vectors_output.vector_results)} vector results used by LLM")

        # Create compact results for all vectors
        for res in exp_vectors_output.vector_results:
            compact_result = {
                "score": round(res.score, 3),
                "id": getattr(res, "id", None),
                # Include first 3 paragraphs or up to 500 chars of content
                "content": "\n\n".join(res.content.split("\n\n")[:3])[:500] if res.content else res.content,
                # Always include preview
                "content_preview": res.content_preview if hasattr(res, "content_preview") and res.content_preview else (res.content[:100] + "..." if len(res.content) > 100 else res.content)
            }
            vector_result_data.append(compact_result)

    # Log what we're sending to the client
    logger.info(f"Sending {len(vector_result_data)} vector results to client for experience_vectors phase")
    for i, v in enumerate(vector_result_data):
        logger.info(f"Vector {i+1}: id={v.get('id', 'None')}, content length={len(v.get('content', ''))}")

    # Create the event payload
    yield {
        "phase": "experience_vectors",
        "status": "complete",
        "content": exp_vectors_output.experience_vectors_response.content,
        "provider": experience_vectors_model_config.provider,
        "model_name": experience_vectors_model_config.model_name,
        "vector_results": vector_result_data  # Include vector results for client
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
        "provider": understanding_model_config.provider, "model_name": understanding_model_config.model_name,
    }

    # 7. Yield Phase
    yield {"phase": "yield", "status": "running"}
    yield_result = await run_yield_phase(current_messages, yield_model_config)
    logger.info(f"🐍 WORKFLOW: Received yield_result: {yield_result}") # DEBUG LOG
    if "error" in yield_result:
        yield {
            "phase": "yield", "status": "error", "content": yield_result["error"],
            "provider": yield_model_config.provider, "model_name": yield_model_config.model_name
        }
        return
    yield_response: AIMessage = yield_result["yield_response"]
    # Don't add Yield to history for now
    yield {
        "phase": "yield", "status": "complete", "content": yield_response.content,
        "provider": yield_model_config.provider, "model_name": yield_model_config.model_name,
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
