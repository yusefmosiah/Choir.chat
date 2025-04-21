"""
Router for PostChain endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional
import json
import asyncio
import uuid
import logging

from app.config import Config
from app.postchain.langchain_workflow import run_langchain_postchain_workflow # Import the new workflow
from app.postchain.utils import validate_thread_id, recover_state

# Import ModelConfig from langchain_utils
from app.langchain_utils import ModelConfig

# Import authentication dependencies
from app.services.auth_service import get_current_user
from app.models.auth import TokenData

class SimplePostChainRequest(BaseModel):
    user_query: str = Field(..., description="The user's input query")
    thread_id: str = Field(..., description="Thread ID for persistence") # Make thread_id required
    model_configs: Optional[Dict[str, ModelConfig]] = Field(None, description="Optional model configurations by phase")

class RecoverThreadRequest(BaseModel):
    thread_id: str = Field(..., description="Thread ID to recover")

# Get config
# def get_config(): # REMOVED - Config object no longer injected
#     return Config()

router = APIRouter()

@router.get("/health")
async def health_check():
    """Check the health of the PostChain API."""
    return {"status": "healthy", "message": "PostChain API is running"}

@router.post("/langchain")
async def process_simple_postchain(
    request: SimplePostChainRequest,
    # config: Config = Depends(get_config) # REMOVED - Config no longer injected
    current_user: TokenData = Depends(get_current_user)
):
    """
    Process a request through the PostChain.

    This endpoint provides a PostChain response with Action and Experience phases.
    Always streams updates for each phase.
    """
    # Get logger
    logger = logging.getLogger(__name__)

    # Log authenticated user
    logger.info(f"Processing PostChain request for user: {current_user.user_id}, wallet: {current_user.wallet_address}")

    # Validate thread ID
    thread_id = validate_thread_id(request.thread_id)

    try:
        # Client-side streaming (SSE format)
        async def stream_generator():
            # Recover message history using thread_id
            state = recover_state(thread_id)
            message_history = state.messages if state else []

            # Build model config overrides from request if provided
            model_overrides = {}
            if request.model_configs:
                for phase, model_config_from_request in request.model_configs.items():
                    # Convert phase name to the override parameter name
                    # IMPORTANT: The model_config_from_request MUST now contain the API keys sent from the client
                    if phase in ["action", "experience_vectors", "experience_web", "intention", "observation", "understanding", "yield"]:
                         # Ensure the received object is actually a ModelConfig instance
                         # (FastAPI should handle validation based on the request model)
                        model_overrides[f"{phase}_mc_override"] = model_config_from_request
            async for event in run_langchain_postchain_workflow(
                query=request.user_query,
                thread_id=thread_id,
                message_history=message_history, # Pass the recovered history
                # Pass user information for rewards
                user_id=current_user.user_id,
                wallet_address=current_user.wallet_address,
                # config=config, # REMOVED
                **model_overrides, # Expand the model overrides as keyword arguments
            ):
                # Convert chunk to JSON and yield with newline for proper SSE formatting
                json_data = json.dumps(event)
                # Enhanced debug logging
                if "model_name" in event:
                    print(f"SERVER: Sending event with model_name: {event['model_name']}")
                    print(f"SERVER: JSON keys: {list(event.keys())}")
                    print(f"SERVER: Full JSON: {json_data}")
                yield f"data: {json_data}\n\n"
                await asyncio.sleep(0.01) # Add a small delay to allow flushing

            # End of stream
            yield "data: [DONE]\n\n"

        # Return streaming response
        return StreamingResponse(
            stream_generator(),
            media_type="text/event-stream"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PostChain: {str(e)}")

@router.post("/recover")
async def recover_thread(
    request: RecoverThreadRequest,
    # config: Config = Depends(get_config) # REMOVED
    current_user: TokenData = Depends(get_current_user)
):
    """
    Recover a thread from an interrupted conversation.

    This endpoint attempts to recover the state of a conversation that
    may have been interrupted or left in an inconsistent state.
    """
    # Get logger
    logger = logging.getLogger(__name__)

    # Log authenticated user
    logger.info(f"Recovering thread for user: {current_user.user_id}, wallet: {current_user.wallet_address}")

    try:
        # Validate thread ID
        thread_id = validate_thread_id(request.thread_id)

        # Attempt to recover state
        state = recover_state(thread_id)

        if state:
            # Return recovered state information
            return {
                "status": "recovered",
                "thread_id": thread_id,
                "phase_states": state.phase_state,
                "current_phase": state.current_phase,
                "error": state.error,
                "message_count": len(state.messages)
            }
        else:
            # No state found
            return {
                "status": "not_found",
                "thread_id": thread_id,
                "message": "No state found for the specified thread ID"
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error recovering thread: {str(e)}")
