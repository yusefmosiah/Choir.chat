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
import json
import logging
from typing import List, Dict, Any, AsyncIterator, Optional

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage, ToolMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough, RunnableLambda
from langchain_openai import OpenAIEmbeddings

# Local imports
from app.config import Config # Although config object isn't passed directly, defaults might still be used
from app.postchain.postchain_llm import post_llm
from app.langchain_utils import ModelConfig
# Import updated schemas
from app.postchain.schemas.state import (
    PostChainState,
    ExperienceVectorsPhaseOutput,
    ExperienceWebPhaseOutput,
    YieldPhaseOutput,
    SearchResult,
    VectorSearchResult
)
from app.postchain.schemas.rewards import NoveltyRewardInfo, CitationRewardInfo
from app.services.rewards_service import RewardsService
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

from app.database import DatabaseClient # Add import for DB client

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


# --- Helper Functions ---

def prepare_messages_for_gemini(messages: List[BaseMessage]) -> List[BaseMessage]:
    """
    Prepare messages for Gemini models which require non-empty content in all parts.
    This function ensures that no empty messages are sent to Gemini models.

    Args:
        messages: List of LangChain message objects

    Returns:
        List of LangChain message objects with no empty content
    """
    logger.info("Preparing messages for Gemini model to prevent empty content errors")
    prepared_messages = []

    for message in messages:
        # Create a copy of the message to avoid modifying the original
        if isinstance(message, HumanMessage):
            # For user messages, ensure they have content
            content = message.content if message.content else "Please continue."
            prepared_messages.append(HumanMessage(content=content))
        elif isinstance(message, SystemMessage):
            # For system messages, ensure they have content
            content = message.content if message.content else "You are a helpful assistant."
            prepared_messages.append(SystemMessage(content=content))
        elif isinstance(message, AIMessage):
            # For AI messages, ensure they have content
            content = message.content if message.content else "I'll help you with that."
            # Preserve tool_calls if they exist
            if hasattr(message, 'tool_calls') and message.tool_calls:
                prepared_messages.append(AIMessage(content=content, tool_calls=message.tool_calls))
            else:
                prepared_messages.append(AIMessage(content=content))
        else:
            # For other message types (like ToolMessage), keep as is but ensure content is not empty
            if hasattr(message, 'content') and not message.content:
                # Create a new message with the same attributes but non-empty content
                message_dict = message.dict()
                message_dict['content'] = "Tool response received."
                prepared_messages.append(type(message)(**message_dict))
            else:
                prepared_messages.append(message)

    return prepared_messages


def sanitize_messages_for_openai(messages: List[BaseMessage]) -> List[BaseMessage]:
    """
    Sanitize messages for OpenAI models to ensure proper tool call handling.
    This function ensures that any assistant message with tool_calls has corresponding tool response messages.

    Args:
        messages: List of LangChain message objects

    Returns:
        List of LangChain message objects with proper tool call handling
    """
    logger.info("Sanitizing messages for OpenAI model to prevent tool call errors")
    sanitized_messages = []

    # First pass: identify assistant messages with tool_calls that don't have corresponding tool responses
    tool_call_ids_with_responses = set()
    for message in messages:
        if isinstance(message, ToolMessage) and hasattr(message, 'tool_call_id'):
            tool_call_ids_with_responses.add(message.tool_call_id)

    # Second pass: filter out problematic messages or add dummy tool responses
    i = 0
    while i < len(messages):
        message = messages[i]

        if isinstance(message, AIMessage) and hasattr(message, 'tool_calls') and message.tool_calls:
            # Check if all tool_calls have corresponding tool responses
            missing_tool_call_ids = []
            for tool_call in message.tool_calls:
                tool_call_id = tool_call.get('id')
                if tool_call_id and tool_call_id not in tool_call_ids_with_responses:
                    missing_tool_call_ids.append(tool_call_id)

            if missing_tool_call_ids:
                # Option 1: Remove tool_calls from the message
                sanitized_messages.append(AIMessage(content=message.content))
                logger.info(f"Removed tool_calls from assistant message to prevent OpenAI API errors")
            else:
                # All tool_calls have responses, keep the message as is
                sanitized_messages.append(message)
        else:
            # Keep all other message types as is
            sanitized_messages.append(message)

        i += 1

    return sanitized_messages

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

        # Prepare messages based on the provider
        prepared_messages = action_messages

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_messages = prepare_messages_for_gemini(action_messages)
            logger.info("Using prepared messages for Google Gemini model")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_messages = sanitize_messages_for_openai(action_messages)
            logger.info("Using sanitized messages for OpenAI model")

        response = await post_llm(
            model_config=model_config,
            messages=prepared_messages
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

async def run_experience_vectors_phase(
    messages: List[BaseMessage],
    model_config: ModelConfig,
    thread_id: str,
    user_id: Optional[str] = None,
    wallet_address: Optional[str] = None
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
                logger.info(f"Maximum similarity score: {max_similarity:.6f}")

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

        # --- 4. Calculate Novelty Reward --- #
        novelty_reward = None
        if wallet_address and max_similarity is not None:
            try:
                # Initialize rewards service
                rewards_service = RewardsService()

                # Issue novelty reward
                reward_result = await rewards_service.issue_novelty_reward(wallet_address, max_similarity)

                # Create reward info object if successful
                if reward_result.get("success"):
                    novelty_reward = NoveltyRewardInfo(
                        reward_type="novelty",
                        reward_amount=reward_result.get("reward_amount", 0),
                        success=True,
                        digest=reward_result.get("digest"),
                        similarity=max_similarity
                    )
                else:
                    # Create failed reward info
                    novelty_reward = NoveltyRewardInfo(
                        reward_type="novelty",
                        reward_amount=0,
                        success=False,
                        error=reward_result.get("reason") or "Unknown error",
                        similarity=max_similarity
                    )

                logger.info(f"Novelty reward processed: {novelty_reward.dict()}")
            except Exception as e:
                logger.error(f"Error processing novelty reward: {e}", exc_info=True)

        # --- 5. Call LLM with Search Results and Reward Information --- #
        # Prepare context string from results in the format specified in the prompt
        search_context = "\n\nRelevant Information from Internal Documents:\n"
        if vector_results_list:
            # Add results in simplified code block format
            for i, res in enumerate(vector_results_list):
                # Use the position number (1-based) as the reference, not the actual UUID
                position_number = i + 1
                # Include the actual vector ID for retrieval
                actual_vector_id = res.id if res.id else ""
                # Create a unique reference that includes the actual vector ID
                vector_id_display = f"ID: {actual_vector_id}" if actual_vector_id else ""

                # Use content preview if it exists, otherwise a short version of the content
                display_content = res.content
                if hasattr(res, 'content_preview') and res.content_preview:
                    display_content = res.content_preview
                elif len(res.content) > 200:
                    display_content = res.content[:200] + "..."

                # Create a unique reference format using vid tags that includes the actual vector ID
                # Format: <vid>{actual_vector_id}</vid>
                # This format is easier to parse on the client side and clearly distinguishes vector references
                unique_reference = f"<vid>{actual_vector_id}</vid>" if actual_vector_id else f"#{position_number}"

                search_context += f"""
```
{unique_reference} | {res.score:.2f} {vector_id_display}
{display_content}
```

"""
        else:
            search_context += "No relevant information found in internal documents.\n"

        # Add explicit instruction about the reference syntax
        search_context += "\nIMPORTANT: When referencing any vector result in your response, use the exact tag format shown above: <vid>vector_id</vid>. You MUST include the full vector ID as shown above. These references will be converted to clickable links in the UI, allowing users to view the full content of each result.\n\n"

        # Add novelty reward information if available
        reward_context = ""
        if novelty_reward and novelty_reward.success:
            reward_amount = float(novelty_reward.reward_amount) / 1_000_000_000.0  # Convert to CHOIR tokens
            novelty_score = 1.0 - max_similarity if max_similarity is not None else 0.0
            reward_context = f"\nNOVELTY REWARD: The user has earned {reward_amount:.2f} CHOIR tokens for this novel prompt! The novelty score is {novelty_score:.2f} (similarity: {max_similarity:.2f}).\n\n"
        elif max_similarity is not None:
            novelty_score = 1.0 - max_similarity
            reward_context = f"\nPROMPT SIMILARITY: This prompt has a novelty score of {novelty_score:.2f} (similarity: {max_similarity:.2f}).\n\n"

        # Find last AI message (likely Action response) to include in context
        last_ai_msg = next((m for m in reversed(messages) if isinstance(m, AIMessage)), None)

        # Prepare prompt for LLM (NO TOOL USAGE THIS TIME)
        instruction = experience_vectors_instruction(model_config) # Get base instruction
        phase_query = f"""<experience_vectors_instruction>{instruction}</experience_vectors_instruction>

Original Query: {last_user_msg.content}
{f'Previous Response: {last_ai_msg.content}' if last_ai_msg else ''}
{reward_context}{search_context}
Your task: Synthesize the information above and the conversation history to respond to the original query. DO NOT call any tools.
"""
        # Use current message history PLUS the new query incorporating search results
        phase_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=phase_query)]

        logger.info("Calling LLM to synthesize vector search results.")

        # Prepare messages based on the provider
        prepared_messages = phase_messages

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_messages = prepare_messages_for_gemini(phase_messages)
            logger.info("Using prepared messages for Google Gemini model in Experience Vectors phase")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_messages = sanitize_messages_for_openai(phase_messages)
            logger.info("Using sanitized messages for OpenAI model in Experience Vectors phase")

        llm_response = await post_llm(
            model_config=model_config,
            messages=prepared_messages,
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

    # We'll include all vector results that were shown to the LLM
    # The client will handle parsing the <vid> tags and displaying the appropriate content
    referenced_vector_results = vector_results_list[:MAX_VECTOR_RESULTS] if vector_results_list else []

    # Log the final selection of vectors
    if vector_results_list:
        logger.info(f"Selected {len(referenced_vector_results)} out of {len(vector_results_list)} total vector results to return to client")

    # Novelty reward was already calculated and issued before the LLM call

    # Return the structured output with the referenced vectors and reward info
    return ExperienceVectorsPhaseOutput(
        experience_vectors_response=final_response,
        vector_results=referenced_vector_results,
        error=error_msg,
        max_similarity=max_similarity,
        novelty_reward=novelty_reward
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

Your task: Eagerly use BraveSearchTool to find salient information from the web. Summarize and integrate the findings into your response.
"""
    phase_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=phase_query)]

    # Define the runnable chain
    async def _get_response(msgs):
        # Prepare messages based on the provider
        prepared_msgs = msgs

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_msgs = prepare_messages_for_gemini(msgs)
            logger.info("Using prepared messages for Google Gemini model in Experience Web phase")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_msgs = sanitize_messages_for_openai(msgs)
            logger.info("Using sanitized messages for OpenAI model in Experience Web phase")
        return await post_llm(model_config=model_config, messages=prepared_msgs, tools=tools)
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
                    for result in web_results_list:
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
        # Prepare messages based on the provider
        prepared_msgs = msgs

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_msgs = prepare_messages_for_gemini(msgs)
            logger.info("Using prepared messages for Google Gemini model in Intention phase")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_msgs = sanitize_messages_for_openai(msgs)
            logger.info("Using sanitized messages for OpenAI model in Intention phase")
        return await post_llm(model_config=model_config, messages=prepared_msgs)
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
        # Prepare messages based on the provider
        prepared_msgs = msgs

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_msgs = prepare_messages_for_gemini(msgs)
            logger.info("Using prepared messages for Google Gemini model in Observation phase")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_msgs = sanitize_messages_for_openai(msgs)
            logger.info("Using sanitized messages for OpenAI model in Observation phase")
        return await post_llm(model_config=model_config, messages=prepared_msgs)
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
        # Prepare messages based on the provider
        prepared_msgs = msgs

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_msgs = prepare_messages_for_gemini(msgs)
            logger.info("Using prepared messages for Google Gemini model in Understanding phase")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_msgs = sanitize_messages_for_openai(msgs)
            logger.info("Using sanitized messages for OpenAI model in Understanding phase")
        return await post_llm(model_config=model_config, messages=prepared_msgs)
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
    model_config: ModelConfig,
    user_id: Optional[str] = None,
    wallet_address: Optional[str] = None
) -> YieldPhaseOutput:
    """Runs the Yield phase using LCEL with structured output."""
    logger.info(f"Running Yield phase with model: {model_config.provider}/{model_config.model_name}")

    # Import YieldPhaseResponse here to avoid circular imports
    from app.postchain.schemas.state import YieldPhaseResponse

    # Enhanced yield instruction that emphasizes citation rewards
    enhanced_yield_instruction = f"""
    <yield_instruction>{yield_instruction(model_config)}</yield_instruction>

    IMPORTANT CITATION INSTRUCTIONS:
    1. When referencing vector search results, use the <vid>vector_id</vid> tag format.
    2. Each citation (up to 5) earns the user 0.5 CHOIR tokens as a reward.
    3. For each citation, provide a brief explanation of why this source was valuable.
    4. Users whose content is cited will receive a notification about the citation.

    Your response MUST be provided in the following structured format:
    ```json
    {{
        "response_content": "Your main response to the user's query, including <vid>vector_id</vid> citations",
        "citations": ["vector_id_1", "vector_id_2", ...],
        "citation_explanations": {{
            "vector_id_1": "Brief explanation of why this source was valuable",
            "vector_id_2": "Brief explanation of why this source was valuable",
            ...
        }}
    }}
    ```
    """

    yield_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=enhanced_yield_instruction)]

    async def yield_wrapper(msgs):
        logger.info(f"Calling post_llm with model: {model_config}")
        # Prepare messages based on the provider
        prepared_msgs = msgs

        # For Google models, ensure no empty content
        if model_config.provider.lower() == "google":
            prepared_msgs = prepare_messages_for_gemini(msgs)
            logger.info("Using prepared messages for Google Gemini model in Yield phase")

        # For OpenAI models, ensure proper tool call handling
        elif model_config.provider.lower() == "openai" or model_config.provider.lower() == "openrouter":
            prepared_msgs = sanitize_messages_for_openai(msgs)
            logger.info("Using sanitized messages for OpenAI model in Yield phase")

        # Use structured output with the YieldPhaseResponse schema
        return await post_llm(
            model_config=model_config,
            messages=prepared_msgs,
            response_model=YieldPhaseResponse
        )

    yield_chain = RunnableLambda(yield_wrapper)

    try:
        # Get structured response from the model
        structured_response = await yield_chain.ainvoke(yield_messages)

        # Check if we got a structured response or a regular AIMessage
        if isinstance(structured_response, YieldPhaseResponse):
            logger.info(f"🐍 YIELD PHASE: Received structured response with {len(structured_response.citations)} citations")

            # Create AIMessage from the structured response content
            response = AIMessage(content=structured_response.response_content)

            # Use citations from the structured response
            citations = structured_response.citations

            # Handle citation_explanations - could be a string or a dictionary
            if hasattr(structured_response, 'citation_explanations'):
                if isinstance(structured_response.citation_explanations, dict):
                    citation_explanations = structured_response.citation_explanations
                elif isinstance(structured_response.citation_explanations, str):
                    # Try to parse the string as JSON
                    try:
                        citation_explanations = json.loads(structured_response.citation_explanations)
                        logger.info(f"Successfully parsed citation_explanations string as JSON dictionary")
                    except json.JSONDecodeError:
                        logger.warning(f"Failed to parse citation_explanations as JSON: {structured_response.citation_explanations}")
                        citation_explanations = {}
                else:
                    logger.warning(f"Unexpected type for citation_explanations: {type(structured_response.citation_explanations)}")
                    citation_explanations = {}
            else:
                citation_explanations = {}

        elif isinstance(structured_response, AIMessage):
            # Fallback to parsing from regular AIMessage if structured output failed
            logger.warning("Structured output failed, falling back to regular response parsing")
            response = structured_response

            # Extract citations from the response content
            rewards_service = RewardsService()
            citations = rewards_service.extract_citations(response.content)
            citation_explanations = {}  # No explanations available in this case

        else:
            # Unexpected response type
            error_msg = f"Unexpected response type from yield model: {type(structured_response)}"
            logger.error(error_msg)
            return YieldPhaseOutput(
                yield_response=AIMessage(content=f"Error in phase: {error_msg}"),
                error=error_msg
            )

        logger.info(f"Yield phase completed. Found {len(citations)} citations.")

        # Process citation rewards
        citation_reward = None
        if wallet_address and citations:
            try:
                # Initialize rewards service
                rewards_service = RewardsService()

                # Issue citation reward
                reward_result = await rewards_service.issue_citation_rewards(wallet_address, len(citations))

                # Create reward info object if successful
                if reward_result.get("success"):
                    citation_reward = CitationRewardInfo(
                        reward_type="citation",
                        reward_amount=reward_result.get("reward_amount", 0),
                        success=True,
                        digest=reward_result.get("digest"),
                        citation_count=reward_result.get("citation_count", len(citations)),
                        cited_messages=citations
                    )
                else:
                    # Create failed reward info
                    citation_reward = CitationRewardInfo(
                        reward_type="citation",
                        reward_amount=0,
                        success=False,
                        error=reward_result.get("reason") or "Unknown error",
                        citation_count=len(citations),
                        cited_messages=citations
                    )

                logger.info(f"Citation reward processed: {citation_reward.dict()}")

                # Send notifications to users whose content was cited
                from app.services.notification_service import NotificationService
                notification_service = NotificationService()

                # Send notifications for each citation
                for vector_id in citations:
                    try:
                        notification_result = await notification_service.send_citation_notification(
                            vector_id=vector_id,
                            citing_wallet_address=wallet_address
                        )

                        if notification_result.get("success"):
                            logger.info(f"Sent citation notification for vector {vector_id} to {notification_result.get('recipient')}")
                        else:
                            logger.warning(f"Failed to send citation notification for vector {vector_id}: {notification_result.get('reason')}")

                    except Exception as e:
                        logger.error(f"Error sending citation notification for vector {vector_id}: {e}", exc_info=True)

            except Exception as e:
                logger.error(f"Error processing citation reward: {e}", exc_info=True)

        return YieldPhaseOutput(
            yield_response=response,
            citations=citations,
            citation_reward=citation_reward,
            citation_explanations=citation_explanations
        )
    except Exception as e:
        logger.error(f"Error during Yield phase: {e}", exc_info=True)
        return YieldPhaseOutput(
            yield_response=AIMessage(content=f"Error in phase: {e}"),
            error=f"Yield phase failed: {e}"
        )


# --- Main Workflow (Updated) ---

async def run_langchain_postchain_workflow(
    query: str,
    thread_id: str,
    message_history: List[BaseMessage],
    # User information for rewards
    user_id: Optional[str] = None,
    wallet_address: Optional[str] = None,
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
    # Ensure model_name is not empty for running status
    action_model_name = action_model_config.model_name if action_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "action",
        "status": "running",
        "provider": action_model_config.provider,
        "model_name": action_model_name
    }

    # Log the running status
    logger.info(f"🐍 ACTION PHASE: Sending running status with model_name: {action_model_name}")

    yield running_obj
    action_result = await run_action_phase(current_messages, action_model_config)
    if "error" in action_result:
        # Ensure model_name is not empty
        action_model_name = action_model_config.model_name if action_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "action",
            "status": "error",
            "content": action_result["error"],
            "provider": action_model_config.provider,
            "model_name": action_model_name
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 ACTION PHASE ERROR: Sending JSON response: {json.dumps(response_obj)}")

        yield response_obj
        return
    action_response: AIMessage = action_result["action_response"]
    current_messages.append(action_response)
    conversation_history_store[thread_id] = current_messages
    # Ensure model_name is not empty
    action_model_name = action_model_config.model_name if action_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "action",
        "status": "complete",
        "content": action_response.content,
        "provider": action_model_config.provider,
        "model_name": action_model_name
    }

    # Log the exact JSON that will be sent
    logger.info(f"🐍 ACTION PHASE: Sending JSON response: {json.dumps(response_obj)}")

    yield response_obj

    # 2. Experience Vectors Phase
    # Ensure model_name is not empty for running status
    exp_vectors_model_name = experience_vectors_model_config.model_name if experience_vectors_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "experience_vectors",
        "status": "running",
        "provider": experience_vectors_model_config.provider,
        "model_name": exp_vectors_model_name
    }

    # Log the running status
    logger.info(f"🐍 EXPERIENCE VECTORS PHASE: Sending running status with model_name: {exp_vectors_model_name}")

    yield running_obj
    exp_vectors_output: ExperienceVectorsPhaseOutput = await run_experience_vectors_phase(
        messages=current_messages,
        model_config=experience_vectors_model_config,
        thread_id=thread_id,
        user_id=user_id,
        wallet_address=wallet_address
    )
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

        # Ensure model_name is not empty
        exp_vectors_model_name = experience_vectors_model_config.model_name if experience_vectors_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "experience_vectors",
            "status": "error",
            "content": exp_vectors_output.error,
            "provider": experience_vectors_model_config.provider,
            "model_name": exp_vectors_model_name,
            "vector_results": vector_result_data # Include compact partial results on error
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 EXPERIENCE VECTORS PHASE ERROR: Sending JSON response with model_name: {exp_vectors_model_name}")

        yield response_obj
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
    # Ensure model_name is not empty
    exp_vectors_model_name = experience_vectors_model_config.model_name if experience_vectors_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "experience_vectors",
        "status": "complete",
        "content": exp_vectors_output.experience_vectors_response.content,
        "provider": experience_vectors_model_config.provider,
        "model_name": exp_vectors_model_name,
        "vector_results": vector_result_data,  # Include vector results for client
        "max_similarity": exp_vectors_output.max_similarity  # Include similarity score
    }

    # Add novelty reward information if available
    if exp_vectors_output.novelty_reward:
        response_obj["novelty_reward"] = exp_vectors_output.novelty_reward.dict()

    # Log the exact JSON that will be sent
    logger.info(f"🐍 EXPERIENCE VECTORS PHASE: Sending JSON response with model_name: {exp_vectors_model_name}")

    yield response_obj
    # 3. Experience Web Phase
    # Ensure model_name is not empty for running status
    exp_web_model_name = experience_web_model_config.model_name if experience_web_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "experience_web",
        "status": "running",
        "provider": experience_web_model_config.provider,
        "model_name": exp_web_model_name
    }

    # Log the running status
    logger.info(f"🐍 EXPERIENCE WEB PHASE: Sending running status with model_name: {exp_web_model_name}")

    yield running_obj
    exp_web_output: ExperienceWebPhaseOutput = await run_experience_web_phase(current_messages, experience_web_model_config)
    if exp_web_output.error:
        # Ensure model_name is not empty
        exp_web_model_name = experience_web_model_config.model_name if experience_web_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "experience_web",
            "status": "error",
            "content": exp_web_output.error,
            "provider": experience_web_model_config.provider,
            "model_name": exp_web_model_name,
            "web_results": [res.dict() for res in exp_web_output.web_results] # Include partial results on error
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 EXPERIENCE WEB PHASE ERROR: Sending JSON response with model_name: {exp_web_model_name}")

        yield response_obj
        return
    current_messages.append(exp_web_output.experience_web_response)
    conversation_history_store[thread_id] = current_messages
    # Ensure model_name is not empty
    exp_web_model_name = experience_web_model_config.model_name if experience_web_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "experience_web",
        "status": "complete",
        "content": exp_web_output.experience_web_response.content,
        "provider": experience_web_model_config.provider,
        "model_name": exp_web_model_name,
        "web_results": [res.dict() for res in exp_web_output.web_results] # Key for results
    }

    # Log the exact JSON that will be sent
    logger.info(f"🐍 EXPERIENCE WEB PHASE: Sending JSON response with model_name: {exp_web_model_name}")

    yield response_obj

    # 4. Intention Phase
    # Ensure model_name is not empty for running status
    intention_model_name = intention_model_config.model_name if intention_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "intention",
        "status": "running",
        "provider": intention_model_config.provider,
        "model_name": intention_model_name
    }

    # Log the running status
    logger.info(f"🐍 INTENTION PHASE: Sending running status with model_name: {intention_model_name}")

    yield running_obj
    intention_result = await run_intention_phase(current_messages, intention_model_config)
    if "error" in intention_result:
        # Ensure model_name is not empty
        intention_model_name = intention_model_config.model_name if intention_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "intention",
            "status": "error",
            "content": intention_result["error"],
            "provider": intention_model_config.provider,
            "model_name": intention_model_name
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 INTENTION PHASE ERROR: Sending JSON response with model_name: {intention_model_name}")

        yield response_obj
        return
    intention_response: AIMessage = intention_result["intention_response"]
    current_messages.append(intention_response)
    conversation_history_store[thread_id] = current_messages
    # Ensure model_name is not empty
    intention_model_name = intention_model_config.model_name if intention_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "intention",
        "status": "complete",
        "content": intention_response.content,
        "provider": intention_model_config.provider,
        "model_name": intention_model_name
    }

    # Log the exact JSON that will be sent
    logger.info(f"🐍 INTENTION PHASE: Sending JSON response with model_name: {intention_model_name}")

    yield response_obj

    # 5. Observation Phase
    # Ensure model_name is not empty for running status
    observation_model_name = observation_model_config.model_name if observation_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "observation",
        "status": "running",
        "provider": observation_model_config.provider,
        "model_name": observation_model_name
    }

    # Log the running status
    logger.info(f"🐍 OBSERVATION PHASE: Sending running status with model_name: {observation_model_name}")

    yield running_obj
    observation_result = await run_observation_phase(current_messages, observation_model_config)
    if "error" in observation_result:
        # Ensure model_name is not empty
        observation_model_name = observation_model_config.model_name if observation_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "observation",
            "status": "error",
            "content": observation_result["error"],
            "provider": observation_model_config.provider,
            "model_name": observation_model_name
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 OBSERVATION PHASE ERROR: Sending JSON response with model_name: {observation_model_name}")

        yield response_obj
        return
    observation_response: AIMessage = observation_result["observation_response"]
    current_messages.append(observation_response)
    conversation_history_store[thread_id] = current_messages
    # Ensure model_name is not empty
    observation_model_name = observation_model_config.model_name if observation_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "observation",
        "status": "complete",
        "content": observation_response.content,
        "provider": observation_model_config.provider,
        "model_name": observation_model_name
    }

    # Log the exact JSON that will be sent
    logger.info(f"🐍 OBSERVATION PHASE: Sending JSON response with model_name: {observation_model_name}")

    yield response_obj

    # 6. Understanding Phase
    # Ensure model_name is not empty for running status
    understanding_model_name = understanding_model_config.model_name if understanding_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "understanding",
        "status": "running",
        "provider": understanding_model_config.provider,
        "model_name": understanding_model_name
    }

    # Log the running status
    logger.info(f"🐍 UNDERSTANDING PHASE: Sending running status with model_name: {understanding_model_name}")

    yield running_obj
    understanding_result = await run_understanding_phase(current_messages, understanding_model_config)
    if "error" in understanding_result:
        # Ensure model_name is not empty
        understanding_model_name = understanding_model_config.model_name if understanding_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "understanding",
            "status": "error",
            "content": understanding_result["error"],
            "provider": understanding_model_config.provider,
            "model_name": understanding_model_name
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 UNDERSTANDING PHASE ERROR: Sending JSON response with model_name: {understanding_model_name}")

        yield response_obj
        return
    understanding_response: AIMessage = understanding_result["understanding_response"]
    current_messages.append(understanding_response)
    conversation_history_store[thread_id] = current_messages
    # Ensure model_name is not empty
    understanding_model_name = understanding_model_config.model_name if understanding_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "understanding",
        "status": "complete",
        "content": understanding_response.content,
        "provider": understanding_model_config.provider,
        "model_name": understanding_model_name,
    }

    # Log the exact JSON that will be sent
    logger.info(f"🐍 UNDERSTANDING PHASE: Sending JSON response with model_name: {understanding_model_name}")

    yield response_obj

    # 7. Yield Phase
    # Ensure model_name is not empty for running status
    yield_model_name = yield_model_config.model_name if yield_model_config.model_name else "unknown"

    # Create the response object for running status
    running_obj = {
        "phase": "yield",
        "status": "running",
        "provider": yield_model_config.provider,
        "model_name": yield_model_name
    }

    # Log the running status
    logger.info(f"🐍 YIELD PHASE: Sending running status with model_name: {yield_model_name}")

    yield running_obj
    yield_result = await run_yield_phase(
        messages=current_messages,
        model_config=yield_model_config,
        user_id=user_id,
        wallet_address=wallet_address
    )
    logger.info(f"🐍 WORKFLOW: Received yield_result: {yield_result}") # DEBUG LOG
    if yield_result.error:
        # Ensure model_name is not empty
        yield_model_name = yield_model_config.model_name if yield_model_config.model_name else "unknown"

        # Create the response object
        response_obj = {
            "phase": "yield",
            "status": "error",
            "content": yield_result.error,
            "provider": yield_model_config.provider,
            "model_name": yield_model_name
        }

        # Log the exact JSON that will be sent
        logger.info(f"🐍 YIELD PHASE ERROR: Sending JSON response with model_name: {yield_model_name}")

        yield response_obj
        return
    yield_response: AIMessage = yield_result.yield_response
    # Don't add Yield to history for now

    # Add debug logging for model information
    logger.info(f"🐍 YIELD PHASE: Sending model info - provider: '{yield_model_config.provider}', model_name: '{yield_model_config.model_name}'")

    # Ensure model_name is not empty
    model_name = yield_model_config.model_name if yield_model_config.model_name else "unknown"

    # Create the response object
    response_obj = {
        "phase": "yield",
        "status": "complete",
        "content": yield_response.content,
        "provider": yield_model_config.provider,
        "model_name": model_name,
    }

    # Add citation reward information if available
    if yield_result.citation_reward:
        response_obj["citation_reward"] = yield_result.citation_reward.dict()

    # Add citations if available
    if yield_result.citations:
        response_obj["citations"] = yield_result.citations

    # Add citation explanations if available
    if hasattr(yield_result, 'citation_explanations') and yield_result.citation_explanations:
        response_obj["citation_explanations"] = yield_result.citation_explanations

    # Log the exact JSON that will be sent
    logger.info(f"🐍 YIELD PHASE: Sending JSON response with model_name: {model_name}")

    yield response_obj

    logger.info(f"Langchain PostChain workflow completed for thread {thread_id}")

# This file is imported by routers/postchain.py and used to run the workflow
