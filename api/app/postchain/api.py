"""
API endpoints for the PostChain AEIOU cycle.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List, Optional

from app.config import Config
from app.postchain.aeiou import AEIOUCycle

router = APIRouter()

class AEIOURequest(BaseModel):
    """Request model for the AEIOU cycle API."""
    user_input: str
    max_loops: Optional[int] = 2
    use_multi_provider: Optional[bool] = False

class AEIOUResponse(BaseModel):
    """Response model for the AEIOU cycle API."""
    status: str
    final_response: Optional[str] = None
    phases_visited: Optional[List[str]] = None
    loops_completed: Optional[int] = None
    error: Optional[str] = None

@router.post("/aeiou", response_model=AEIOUResponse)
async def process_aeiou(request: AEIOURequest, config: Config = Depends(Config.from_env)):
    """Process a user input through the AEIOU cycle."""
    try:
        # Create the AEIOU cycle
        aeiou = AEIOUCycle(config)
        
        # Set up multi-provider models if requested
        if request.use_multi_provider:
            aeiou.setup_multi_provider_models()
        
        # Process the user input
        result = aeiou.process(request.user_input, request.max_loops)
        
        # Check if the process was successful
        if result["status"] == "error":
            raise HTTPException(status_code=500, detail=result["error"])
        
        # Return the response
        return AEIOUResponse(
            status="success",
            final_response=result["final_response"],
            phases_visited=result["phases_visited"],
            loops_completed=result["loops_completed"]
        )
    except Exception as e:
        return AEIOUResponse(
            status="error",
            error=str(e)
        )