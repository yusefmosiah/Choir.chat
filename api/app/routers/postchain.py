"""
Router for PostChain endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List, Optional

from app.config import Config
from app.postchain.api import router as aeiou_router

router = APIRouter()

# Include the AEIOU router
router.include_router(aeiou_router, prefix="/aeiou", tags=["aeiou"])

@router.get("/health")
async def health_check():
    """Check the health of the PostChain API."""
    return {"status": "healthy", "message": "PostChain API is running"}