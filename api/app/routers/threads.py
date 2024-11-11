from fastapi import APIRouter, HTTPException
from app.models.api import ThreadCreate, ThreadUpdate, ThreadResponse, APIResponse
from app.database import DatabaseClient
from app.config import Config
from typing import Optional

router = APIRouter()
config = Config.from_env()
db = DatabaseClient(config)

@router.post("", response_model=APIResponse)
async def create_thread(request: ThreadCreate):
    try:
        thread = await db.create_thread(request)
        return APIResponse(
            success=True,
            data={"thread": thread}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{thread_id}", response_model=APIResponse)
async def get_thread(thread_id: str):
    try:
        thread = await db.get_thread(thread_id)
        if not thread:
            raise HTTPException(status_code=404, detail="Thread not found")
        return APIResponse(
            success=True,
            data={"thread": thread}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{thread_id}/messages", response_model=APIResponse)
async def get_thread_messages(thread_id: str, limit: int = 50, before: Optional[str] = None):
    try:
        messages = await db.get_thread_messages(thread_id, limit, before)
        return APIResponse(
            success=True,
            data={"messages": messages}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
