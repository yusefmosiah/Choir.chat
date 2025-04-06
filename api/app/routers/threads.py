import logging # Import logging
from fastapi import APIRouter, HTTPException
from app.models.api import ThreadCreate, ThreadUpdate, ThreadResponse, APIResponse, TurnResponseModel # Import base APIResponse and TurnResponseModel
from app.database import DatabaseClient
from app.config import Config
from typing import Optional, List, Dict, Any # Ensure necessary imports

router = APIRouter()
config = Config.from_env()
logger = logging.getLogger(__name__) # Add logger instance
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

# Update the decorator to use the base APIResponse model
@router.get("/{thread_id}/messages", response_model=APIResponse)
async def get_thread_messages(thread_id: str, limit: int = 50, before: Optional[str] = None):
    try:
        # Fetch raw message data (List[Dict[str, Any]])
        raw_turns_data = await db.get_thread_messages(thread_id, limit, before)

        # Validate and convert raw data to TurnResponseModel objects, then dump back to dict
        validated_turns_data = []
        for turn_dict in raw_turns_data:
            # Explicitly check and add thread_id if somehow missing from payload
            # This is unlikely given db logic but adds robustness
            if 'thread_id' not in turn_dict or not turn_dict['thread_id']:
                 turn_dict['thread_id'] = thread_id
                 logger.warning(f"Manually added missing thread_id {thread_id} to turn {turn_dict.get('id')}")

            # Use model_validate to parse into TurnResponseModel, handling potential extra fields
            try:
                # Validate the dictionary against the TurnResponseModel model
                validated_turn = TurnResponseModel.model_validate(turn_dict)
                # Dump the validated model back to a dictionary using aliases (snake_case keys) for JSON response
                # Exclude None values to keep the response clean
                validated_turns_data.append(validated_turn.model_dump(by_alias=True, exclude_none=True))
            except Exception as val_err:
                logger.error(f"Validation/Serialization error for turn {turn_dict.get('id')}: {val_err}", exc_info=True)
                # Decide how to handle validation errors - skip message or return error? Skip for now.

        logger.info(f"Returning {len(validated_turns_data)} validated turns for thread {thread_id} under 'turns' key")
        if validated_turns_data:
             # Log keys of the first turn to confirm structure before sending
             logger.debug(f" First turn keys: {list(validated_turns_data[0].keys())}")

        # Construct the response manually with the key "turns"
        return APIResponse(
            success=True,
            data={"turns": validated_turns_data}
        )
    except Exception as e:
        # Log the full exception traceback
        logger.error(f"Error loading messages for thread {thread_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
