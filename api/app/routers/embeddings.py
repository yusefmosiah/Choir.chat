from fastapi import APIRouter, HTTPException
from app.models.api import APIResponse
from app.utils import get_embedding
from app.config import Config
from pydantic import BaseModel

class EmbeddingRequest(BaseModel):
    content: str

router = APIRouter()
config = Config.from_env()

@router.post("/generate", response_model=APIResponse)
async def generate_embedding(request: EmbeddingRequest):
    try:
        embedding = await get_embedding(request.content, config.EMBEDDING_MODEL)
        return APIResponse(
            success=True,
            data={"embedding": embedding}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
