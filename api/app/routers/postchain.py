"""
Router for PostChain endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional
import json
import asyncio
import uuid

from app.config import Config
from app.postchain.langchain_workflow import run_langchain_postchain_workflow # Import the new workflow
from app.postchain.utils import validate_thread_id

# Import ModelConfig from langchain_utils
from app.langchain_utils import ModelConfig

class SimplePostChainRequest(BaseModel):
    user_query: str = Field(..., description="The user's input query")
    thread_id: str = Field(..., description="Thread ID for context and potential future use") # Still useful for context
    recent_history: List[Dict[str, str]] = Field(..., description="Recent conversation history for context (e.g., [{'role': 'user', 'content': '...'}])")
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
    background_tasks: BackgroundTasks,
    # config: Config = Depends(get_config) # REMOVED - Config no longer injected
):
    """
    Process a request through the PostChain.

    This endpoint provides a PostChain response with Action and Experience phases.
    Always streams updates for each phase.
    """
    # Validate thread ID
    thread_id = validate_thread_id(request.thread_id)

    try:
        # Client-side streaming (SSE format)
        async def stream_generator():
            # message_history = [] # History is now passed in the request

            # Build model config overrides from request if provided
            model_overrides = {}
            if request.model_configs:
                for phase, model_config_from_request in request.model_configs.items():
                    # Convert phase name to the override parameter name
                    # IMPORTANT: The model_config_from_request MUST now contain the API keys sent from the client
                    if phase in ["action", "experience", "intention", "observation", "understanding", "yield"]:
                         # Ensure the received object is actually a ModelConfig instance
                         # (FastAPI should handle validation based on the request model)
                        model_overrides[f"{phase}_mc_override"] = model_config_from_request
            async for event in run_langchain_postchain_workflow(
                query=request.user_query,
                thread_id=thread_id,
                message_history=request.recent_history, # Pass history from the request
                # config=config, # REMOVED
                background_tasks=background_tasks, # Pass background tasks instance
                **model_overrides, # Expand the model overrides as keyword arguments
            ):
                # Convert chunk to JSON and yield with newline for proper SSE formatting
                yield f"data: {json.dumps(event)}\n\n"
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
