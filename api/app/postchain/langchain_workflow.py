import asyncio
import logging
from typing import List, Dict, Any, AsyncIterator, Optional, Callable, Union
from langchain_openai import OpenAIEmbeddings
import uuid
from datetime import datetime, UTC

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage, ToolMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables import RunnablePassthrough, RunnableLambda
import json

# Local imports
from app.config import Config
from app.postchain.postchain_llm import post_llm
from app.langchain_utils import ModelConfig
from app.postchain.schemas.state import PostChainState, ExperiencePhaseOutput, SearchResult, VectorSearchResult
# from app.postchain.utils import format_stream_event # REMOVE import
from app.postchain.prompts.prompts import action_instruction, experience_instruction, intention_instruction, understanding_instruction, observation_instruction, yield_instruction

# Langchain Tool Imports (Example)
from app.tools.brave_search import BraveSearchTool
from app.tools.qdrant import qdrant_search

# Configure logging
logger = logging.getLogger("postchain_langchain")

COMMON_SYSTEM_PROMPT = """
You are representing Choir's PostChain, in which many different AI models collaborate to provide an improvisational, dynamic, and contextually rich response in a single harmonized voice.
You will see <phase_instructions> embedded in user messages, which contain the instructions for the current phase. Followe these instructions carefully.
"""

# --- Refactored Phase Runner ---

async def _run_single_phase(
    phase_name: str,
    messages: List[BaseMessage], # History up to the point *before* this phase runs
    model_config: ModelConfig,
    prompt_instruction_func: Callable[[ModelConfig], str],
    tools: Optional[List[Any]] = None # Only used for experience phase
) -> Union[Dict[str, Any], ExperiencePhaseOutput]:
    """
    Helper function to run a single Postchain phase.
    Receives the message history *up to this point*.
    Constructs the specific prompt/query for the current phase.
    Calls the LLM.
    Returns a dictionary with 'response' (AIMessage) or 'error' (str),
    or ExperiencePhaseOutput for the experience phase.
    """
    logger.info(f"Running {phase_name} phase with model: {model_config.provider}/{model_config.model_name}")

    # Prepare prompt instruction tag
    instruction = prompt_instruction_func(model_config)
    phase_instruction_tag = f"<{phase_name}_instruction>{instruction}</{phase_name}_instruction>"

    # Default query content is just the instruction tag
    phase_query_content = phase_instruction_tag

    # Special handling for Experience phase prompt structure
    if phase_name == "experience":
        # Find the most recent HumanMessage (the user query for the *current* turn)
        last_user_msg = next((m for m in reversed(messages) if isinstance(m, HumanMessage)), None)
        # Find the most recent AIMessage (the output of the *previous* phase, Action)
        last_ai_msg = next((m for m in reversed(messages) if isinstance(m, AIMessage)), None)

        if not last_user_msg or not last_ai_msg:
            err_msg = f"Could not find previous user query or action response for {phase_name} phase context."
            logger.error(err_msg)
            # Return specific type for Experience phase error
            return ExperiencePhaseOutput(experience_response=AIMessage(content=f"Error: {err_msg}"), error=err_msg)

        # Construct the specific query content for the experience phase
        phase_query_content = f"""{phase_instruction_tag}

Original Query: {last_user_msg.content}
Initial Action Response: {last_ai_msg.content}
Your task: Provide a reflective analysis adding deeper context."""

    # Construct messages for the LLM call: History + New Instruction Query
    phase_messages = [SystemMessage(content=COMMON_SYSTEM_PROMPT)] + messages + [HumanMessage(content=phase_query_content)]

    try:
        # --- Initial LLM Call ---
        response = await post_llm(
            model_config=model_config,
            messages=phase_messages,
            tools=tools # Pass tools if provided (for experience phase)
        )

        if not isinstance(response, AIMessage):
            error_msg = f"Unexpected response type from {phase_name} model (initial call): {type(response)}. Content: {response}"
            logger.error(error_msg)
            if phase_name == "experience":
                return ExperiencePhaseOutput(experience_response=AIMessage(content=f"Error: {error_msg}"), error=error_msg)
            else:
                 return {"error": error_msg}

        logger.info(f"{phase_name} phase initial call completed. Response: {response.content[:100]}...")

        # --- Tool Call Handling (Specific to Experience Phase) ---
        if phase_name == "experience" and hasattr(response, 'tool_calls') and response.tool_calls:
            logger.info(f"Detected {len(response.tool_calls)} tool calls for Experience phase.")
            phase_messages.append(response) # Add the AI message with tool_calls
            tool_messages: List[ToolMessage] = []
            web_results_list: List[SearchResult] = []
            vector_results_list: List[VectorSearchResult] = []

            for tool_call in response.tool_calls:
                tool_name, tool_args, tool_id = tool_call.get("name"), tool_call.get("args"), tool_call.get("id")
                logger.info(f"Executing tool: {tool_name} with args: {tool_args}")
                tool_to_execute = next((t for t in tools if hasattr(t, 'name') and t.name == tool_name), None)
                tool_output_str = ""
                if tool_to_execute:
                    try:
                        input_arg_val = None
                        if isinstance(tool_args, dict): input_arg_val = tool_args.get('query', tool_args)
                        elif isinstance(tool_args, str): input_arg_val = tool_args
                        if input_arg_val is not None:
                            if not isinstance(input_arg_val, str): input_arg_val = str(input_arg_val)
                            if hasattr(tool_to_execute, 'arun'): tool_output_str = await tool_to_execute.arun(input_arg_val)
                            elif hasattr(tool_to_execute, 'run'):
                                if asyncio.iscoroutinefunction(tool_to_execute.run): tool_output_str = await tool_to_execute.run(input_arg_val)
                                else: tool_output_str = await asyncio.to_thread(tool_to_execute.run, input_arg_val)
                            else: tool_output_str = f"Error: Tool {tool_name} has neither 'run' nor 'arun' method."; logger.error(tool_output_str)
                        else: tool_output_str = f"Error: Unsupported tool args format for {tool_name}: {type(tool_args)}"; logger.error(tool_output_str)
                        if isinstance(tool_output_str, str):
                            try:
                                parsed_output = json.loads(tool_output_str)
                                if isinstance(parsed_output, dict) and "results" in parsed_output:
                                    raw_results = parsed_output["results"]
                                    if tool_name == "brave_search":
                                        for res in raw_results: web_results_list.append(SearchResult(title=res.get("title", ""), url=res.get("url", ""), content=res.get("content", res.get("description", "")), provider=tool_name))
                            except json.JSONDecodeError:
                                logger.debug(f"Tool {tool_name} output is not JSON, treating as string summary.")
                                if tool_name == "qdrant_search": vector_results_list.append(VectorSearchResult(content=tool_output_str, score=0.0, provider=tool_name))
                    except Exception as tool_err: tool_output_str = f"Error executing tool {tool_name}: {tool_err}"; logger.error(tool_output_str, exc_info=True)
                else: tool_output_str = f"Error: Tool '{tool_name}' not found."; logger.error(tool_output_str)
                tool_messages.append(ToolMessage(content=tool_output_str, tool_call_id=tool_id, name=tool_name))

            phase_messages.extend(tool_messages)
            logger.info("Calling LLM again with tool results for Experience phase.")
            response = await post_llm(model_config=model_config, messages=phase_messages) # No tools needed for second call
            if not isinstance(response, AIMessage):
                error_msg = f"Unexpected response type from experience model (second call): {type(response)}. Content: {response}"
                logger.error(error_msg)
                return ExperiencePhaseOutput(experience_response=AIMessage(content="Error processing tool results."), error=error_msg)
            logger.info(f"Experience phase second call completed. Response: {response.content[:100]}...")

            # Return the structured output for Experience phase
            return ExperiencePhaseOutput(
                experience_response=response,
                web_results=web_results_list,
                vector_results=vector_results_list
            )

        # For non-experience phases or experience without tool calls
        if phase_name == "experience":
             return ExperiencePhaseOutput(experience_response=response, web_results=[], vector_results=[])
        else:
            # Return standard dictionary for other phases
            return {"response": response}

    except Exception as e:
        logger.error(f"Error during {phase_name} phase: {e}", exc_info=True)
        error_msg = f"{phase_name} phase failed: {e}"
        if phase_name == "experience":
             return ExperiencePhaseOutput(experience_response=AIMessage(content=f"Error: {error_msg}"), error=error_msg)
        else:
            return {"error": error_msg}


# --- Main Workflow ---

async def run_langchain_postchain_workflow(
    query: str,
    thread_id: str,
    message_history: List[BaseMessage], # This is likely unused now as history is loaded from DB
    action_mc_override: Optional[ModelConfig] = None,
    experience_mc_override: Optional[ModelConfig] = None,
    intention_mc_override: Optional[ModelConfig] = None,
    observation_mc_override: Optional[ModelConfig] = None,
    understanding_mc_override: Optional[ModelConfig] = None,
    yield_mc_override: Optional[ModelConfig] = None
) -> AsyncIterator[Dict[str, Any]]:
    """
    Runs the full PostChain workflow using Langchain LCEL.
    Saves ONE record per turn containing user query and AI response + phase outputs.
    Yields events for each phase status update.
    """
    logger.info(f"Starting Langchain PostChain workflow for thread {thread_id}")

    # Initialize embedding model
    embeddings = OpenAIEmbeddings(model=Config().EMBEDDING_MODEL)

    # --- Model Configuration (Prioritize Overrides) ---
    try:
        default_temp = 0.333
        action_model_config = action_mc_override if action_mc_override else ModelConfig(provider="google", model_name="gemini-2.0-flash-lite", temperature=default_temp)
        experience_model_config = experience_mc_override if experience_mc_override else ModelConfig(provider="openrouter", model_name="ai21/jamba-1.6-mini", temperature=default_temp)
        intention_model_config = intention_mc_override if intention_mc_override else ModelConfig(provider="google", model_name="gemini-2.0-flash", temperature=default_temp)
        observation_model_config = observation_mc_override if observation_mc_override else ModelConfig(provider="groq", model_name="qwen-qwq-32b", temperature=default_temp)
        understanding_model_config = understanding_mc_override if understanding_mc_override else ModelConfig(provider="openrouter", model_name="openrouter/quasar-alpha", temperature=default_temp)
        yield_model_config = yield_mc_override if yield_mc_override else ModelConfig(provider="google", model_name="gemini-2.5-pro-exp-03-25", temperature=default_temp)
        logger.info(f"Workflow Models - Action: {action_model_config}, Experience: {experience_model_config}, Intention: {intention_model_config}, Observation: {observation_model_config}, Understanding: {understanding_model_config}, Yield: {yield_model_config}")
    except Exception as e:
        logger.error(f"Failed to initialize models: {e}")
        yield {"phase": "system", "status": "error", "error": f"Model initialization failed: {e}"}
        return

    # --- State Management & Accumulation ---
    accumulated_phase_outputs: Dict[str, str] = {} # Dictionary to store phase results
    from app.database import DatabaseClient
    db_client = DatabaseClient(Config())

    # Load message history from Qdrant
    try:
        qdrant_history = await db_client.get_message_history(thread_id)
        loaded_history = []
        for msg in qdrant_history:
            # role = msg.get("role") # Role no longer used in this way
            content = msg.get("content", "") # This is the AI response content
            user_query_from_history = msg.get("user_query") # Get the user query for this turn

            # Reconstruct conversation flow for model context
            if user_query_from_history:
                 loaded_history.append(HumanMessage(content=user_query_from_history))
            # Assistant content always follows user query (if available)
            loaded_history.append(AIMessage(content=content)) # Add AI content

    except Exception as db_err:
         logger.error(f"Failed to load history for thread {thread_id}: {db_err}", exc_info=True)
         yield {"phase": "system", "status": "error", "error": f"Failed to load history: {db_err}"}
         return

    # Start with loaded history and add the current user query for this turn's context
    current_messages: List[BaseMessage] = loaded_history + [HumanMessage(content=query)]

    # --- Run Phases Sequentially using Helper ---
    phases_to_run = [
        ("action", action_model_config, action_instruction, None),
        ("experience", experience_model_config, experience_instruction, [BraveSearchTool(), qdrant_search]), # Pass tools here
        ("intention", intention_model_config, intention_instruction, None),
        ("observation", observation_model_config, observation_instruction, None),
        ("understanding", understanding_model_config, understanding_instruction, None),
        ("yield", yield_model_config, yield_instruction, None),
    ]

    final_yield_response: Optional[AIMessage] = None

    for phase_name, model_config, instruction_func, tools in phases_to_run:
        # Yield running status
        yield {"phase": phase_name, "status": "running", "content": f"Running {phase_name} phase..."}

        # Call the helper function
        # Pass the *current* message list including the latest user query and previous AI phase outputs
        phase_result = await _run_single_phase(
            phase_name=phase_name,
            messages=current_messages, # Pass the updated list
            model_config=model_config,
            prompt_instruction_func=instruction_func,
            tools=tools
        )

        # Process result
        error_message = None
        phase_response = None
        metadata = {} # Default empty metadata

        # Special handling for Experience phase output structure
        if phase_name == "experience":
            if isinstance(phase_result, ExperiencePhaseOutput):
                error_message = phase_result.error
                phase_response = phase_result.experience_response
                metadata = {"web_results_count": len(phase_result.web_results or []), "vector_results_count": len(phase_result.vector_results or [])}
            else: # Handle potential error dict return from helper
                 error_message = phase_result.get("error", f"Unknown error structure in {phase_name} phase")
        else: # Other phases return Dict
             if isinstance(phase_result, dict):
                 error_message = phase_result.get("error")
                 phase_response = phase_result.get("response")
             else: # Should not happen if helper returns correctly
                 error_message = f"Unexpected return type from {phase_name} phase: {type(phase_result)}"

        # Handle errors
        if error_message:
            yield {"phase": phase_name, "status": "error", "error": error_message, "provider": model_config.provider, "model_name": model_config.model_name}
            return # Stop workflow on error

        # Check for valid AI response
        if not phase_response or not isinstance(phase_response, AIMessage):
             yield {"phase": phase_name, "status": "error", "error": f"Invalid or missing AI response from {phase_name} phase.", "provider": model_config.provider, "model_name": model_config.model_name}
             return # Stop workflow

        # Success: Update history, accumulate output, yield completion
        current_messages.append(phase_response) # Add successful AI response to context for the *next* phase
        accumulated_phase_outputs[phase_name] = phase_response.content
        yield {"phase": phase_name, "status": "complete", "content": phase_response.content, "provider": model_config.provider, "model_name": model_config.model_name, "metadata": metadata}

        # Store the final yield response separately
        if phase_name == "yield":
            final_yield_response = phase_response


    # --- Save the Single Turn Record ---
    if not final_yield_response:
         logger.error(f"Yield phase did not produce a final response for thread {thread_id}.")
         yield {"phase": "system", "status": "error", "error": "Workflow completed without a final yield response."}
         return

    final_content = final_yield_response.content
    try:
        final_vector = await embeddings.aembed_query(final_content)
        logger.info(f"Generated embedding for final AI message (length: {len(final_vector)})")
    except Exception as embed_err:
        logger.error(f"Failed to generate embedding for AI message: {embed_err}", exc_info=True)
        final_vector = [0.0] * Config().VECTOR_SIZE # Use zero vector as fallback

    # Construct the single payload for this turn
    turn_payload = {
        "content": final_content, # AI's final response
        "vector": final_vector, # Embedding of AI's final response
        "thread_id": thread_id,
        # "role": "assistant", # REMOVED role
        "user_query": query, # Store the original user query
        "timestamp": datetime.now(UTC).isoformat(),
        "phase_outputs": accumulated_phase_outputs, # Include all phase outputs
        "metadata": { # Populate metadata with model info using __str__
            "action_model": str(action_model_config),
            "experience_model": str(experience_model_config),
            "intention_model": str(intention_model_config),
            "observation_model": str(observation_model_config),
            "understanding_model": str(understanding_model_config),
            "yield_model": str(yield_model_config),
        },
        # TODO: Add novelty_score, similarity_scores, cited_prior_ids if available
        "novelty_score": None, # Placeholder
        "similarity_scores": None, # Placeholder
        "cited_prior_ids": None, # Placeholder
    }

    try:
        # Save the single turn record
        await db_client.save_message(turn_payload)
        logger.info(f"Successfully saved turn record with phase_outputs for thread {thread_id}. Payload keys: {list(turn_payload.keys())}")
    except Exception as save_err:
        logger.error(f"Failed to save turn record for thread {thread_id}: {save_err}", exc_info=True)
        yield {"phase": "system", "status": "error", "error": f"Failed to save turn record: {save_err}"}
        # Don't return here, let the workflow complete normally if possible

    logger.info(f"Langchain PostChain workflow completed for thread {thread_id}")
    # Yield final completion event
    yield {
        "phase": "complete",
        "status": "complete",
        "content": "Workflow finished."
    }

# --- Example Usage (for testing) ---
# (main function remains largely the same, but history building might need adjustment)
async def main():
    thread_id = "test-thread-lc-turn"
    message_history = []
    query = "What was the score of the last Lakers game? Search the web."

    test_action_mc = ModelConfig(provider="google", model_name="gemini-2.0-flash-lite") # Add keys if needed locally
    test_experience_mc = ModelConfig(provider="openrouter", model_name="ai21/jamba-1.6-mini") # Add keys if needed locally

    async for event in run_langchain_postchain_workflow(
        query=query,
        thread_id=thread_id,
        message_history=message_history, # Pass empty history for first turn
        # action_mc_override=test_action_mc,
        # experience_mc_override=test_experience_mc,
    ):
        print(json.dumps(event, indent=2))
        # History reconstruction for multi-turn tests would need updating
        # based on the new single-record model if running subsequent turns here.
        if event.get("phase") == "yield" and event.get("status") == "complete":
             print("\n--- FINAL RESPONSE ---")
             print(event.get("content")) # Use 'content' key now
             print("----------------------")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    # Example of running the main function for testing
    # asyncio.run(main())
    pass

# REMOVE OLD PHASE FUNCTIONS (as they are replaced by the helper)
# async def run_action_phase(...): ...
# async def run_experience_phase(...): ...
# async def run_intention_phase(...): ...
# async def run_observation_phase(...): ...
# async def run_understanding_phase(...): ...
# async def run_yield_phase(...): ...
