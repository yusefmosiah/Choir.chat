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

from app.config import Config
from app.postchain.simple_graph import stream_simple_postchain
from app.postchain.utils import validate_thread_id, recover_state

# Define request models
class SimplePostChainRequest(BaseModel):
    user_query: str = Field(..., description="The user's input query")
    thread_id: Optional[str] = Field(None, description="Optional thread ID for persistence")
    stream: bool = Field(False, description="Whether to stream the response")

class RecoverThreadRequest(BaseModel):
    thread_id: str = Field(..., description="Thread ID to recover")

# Get config
def get_config():
    return Config()

router = APIRouter()

@router.get("/health")
async def health_check():
    """Check the health of the PostChain API."""
    return {"status": "healthy", "message": "PostChain API is running"}

@router.post("/simple")
async def process_simple_postchain(
    request: SimplePostChainRequest,
    config: Config = Depends(get_config)
):
    """
    Process a request through the PostChain.

    This endpoint provides a PostChain response with Action and Experience phases.
    Always streams updates for each phase, with format appropriate for the client's needs.
    """
    # Validate thread ID
    thread_id = validate_thread_id(request.thread_id)

    try:
        # Set up streaming response
        if request.stream:
            # Client-side streaming (SSE format)
            async def stream_generator():
                async for chunk in stream_simple_postchain(
                    user_query=request.user_query,
                    config=config,
                    thread_id=thread_id
                ):
                    # Convert chunk to JSON and yield with newline for proper SSE formatting
                    yield f"data: {json.dumps(chunk)}\n\n"

                # End of stream
                yield "data: [DONE]\n\n"

            # Return streaming response
            return StreamingResponse(
                stream_generator(),
                media_type="text/event-stream"
            )
        else:
            # For non-streaming clients, we still use the streaming function but collect all results
            results = []
            final_phase_outputs = {"action": "", "experience": ""}

            async for chunk in stream_simple_postchain(
                user_query=request.user_query,
                config=config,
                thread_id=thread_id
            ):
                results.append(chunk)

                # Keep track of the latest content for each phase
                if chunk.get("phase_state") in ["processing", "complete"]:
                    phase = chunk.get("current_phase")
                    content = chunk.get("content", "")
                    if phase in ["action", "experience"] and content:
                        final_phase_outputs[phase] = content

            # Return the final state as a single response
            return {
                "status": "success",
                "phase_outputs": final_phase_outputs,
                "user_query": request.user_query,
                "thread_id": thread_id
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PostChain: {str(e)}")

@router.post("/recover")
async def recover_thread(
    request: RecoverThreadRequest,
    config: Config = Depends(get_config)
):
    """
    Recover a thread from an interrupted conversation.

    This endpoint attempts to recover the state of a conversation that
    may have been interrupted or left in an inconsistent state.
    """
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
