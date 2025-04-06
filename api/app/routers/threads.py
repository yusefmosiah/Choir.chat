from fastapi import APIRouter, HTTPException
from app.models.api import ThreadCreate, ThreadUpdate, ThreadResponse, APIResponse, MessagesAPIResponseModel, MessagesDataModel, MessageResponseModel
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

@router.get("/{thread_id}/messages", response_model=MessagesAPIResponseModel) # Use the specific response model
async def get_thread_messages(thread_id: str, limit: int = 50, before: Optional[str] = None):
    try:
        # db.get_thread_messages returns List[Dict[str, Any]]
        messages_data = await db.get_thread_messages(thread_id, limit, before)
        # Convert the list of dictionaries to a list of MessageResponseModel objects
        # Pydantic will handle validation and conversion based on the model definition
        message_models = [MessageResponseModel.parse_obj(msg) for msg in messages_data]

        return MessagesAPIResponseModel(
            success=True,
            data=MessagesDataModel(messages=message_models) # Structure the data correctly
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
