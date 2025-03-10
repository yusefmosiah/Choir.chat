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
from app.postchain.simple_graph import stream_simple_postchain, invoke_simple_postchain

# Define request models
class SimplePostChainRequest(BaseModel):
    user_query: str = Field(..., description="The user's input query")
    thread_id: Optional[str] = Field(None, description="Optional thread ID for persistence")
    stream: bool = Field(False, description="Whether to stream the response")

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
    Process a request through the simplified PostChain (action phase only).

    This endpoint provides a simple one-phase PostChain response.
    If streaming is enabled, it will stream tokens one by one.
    """
    try:
        if request.stream:
            # Set up streaming response
            async def stream_generator():
                async for chunk in stream_simple_postchain(
                    user_query=request.user_query,
                    config=config,
                    thread_id=request.thread_id
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
            try:
                # Return single response
                result = await invoke_simple_postchain(
                    user_query=request.user_query,
                    config=config,
                    thread_id=request.thread_id
                )
                return result
            except Exception as e:
                # If there's an error, return a simple response with the error
                error_message = str(e)
                return {
                    "status": "error",
                    "message": f"Error processing request: {error_message}",
                    "phase_outputs": {"action": f"I encountered an issue while processing your request: {error_message}"},
                    "user_query": request.user_query,
                    "thread_id": request.thread_id or str(uuid.uuid4())
                }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing simple PostChain: {str(e)}")
