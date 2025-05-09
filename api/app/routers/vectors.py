from fastapi import APIRouter, HTTPException
from app.models.api import VectorSearchRequest, VectorStoreRequest, APIResponse
from app.database import DatabaseClient
from app.config import Config
import logging

logger = logging.getLogger("api")

router = APIRouter()
config = Config.from_env()
db = DatabaseClient(config)

@router.post("/search", response_model=APIResponse)
async def search_vectors(request: VectorSearchRequest):
    try:
        results = await db.search_similar(
            config.MESSAGES_COLLECTION,
            request.query_vector,
            request.limit or config.SEARCH_LIMIT
        )
        return APIResponse(
            success=True,
            data={"results": results}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/store", response_model=APIResponse)
async def store_vector(request: VectorStoreRequest):
    try:
        await db.save_message({
            "content": request.content,
            "vector": request.vector,
            "metadata": request.metadata
        })
        return APIResponse(
            success=True,
            message="Vector stored successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vector_id}", response_model=APIResponse)
async def get_vector(vector_id: str):
    """Get a specific vector by ID."""
    logger.info(f"Getting vvvvvvector with ID: {vector_id}")
    try:
        result = await db.get_vector(vector_id)
        if not result:
            raise HTTPException(status_code=404, detail="Vector not found")

        return APIResponse(
            success=True,
            data=result
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
