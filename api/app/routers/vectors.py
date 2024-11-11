from fastapi import APIRouter, HTTPException
from app.models.api import VectorSearchRequest, VectorStoreRequest, APIResponse
from app.database import DatabaseClient
from app.config import Config

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
