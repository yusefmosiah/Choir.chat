from fastapi import APIRouter, HTTPException
from app.models.api import UserCreate, UserResponse, APIResponse
from app.database import DatabaseClient
from app.config import Config

router = APIRouter()
config = Config.from_env()
db = DatabaseClient(config)

@router.post("", response_model=APIResponse)
async def create_user(request: UserCreate):
    try:
        user = await db.create_user(request)
        return APIResponse(
            success=True,
            data={"user": user}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{user_id}", response_model=APIResponse)
async def get_user(user_id: str):
    try:
        user = await db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return APIResponse(
            success=True,
            data={"user": user}
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from uuid import UUID
from fastapi import Path

@router.get("/{user_id}/threads", response_model=APIResponse)
async def get_user_threads(user_id: UUID = Path(..., description="User UUID")):
    try:
        threads = await db.get_user_threads(str(user_id))
        return APIResponse(
            success=True,
            data={"threads": threads}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
