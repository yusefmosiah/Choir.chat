from fastapi import APIRouter, HTTPException
from app.models.api import ActionRequest, ActionResponse, APIResponse, ExperienceRequest, ExperienceResponse
from app.services.chorus import ChorusService
from app.config import Config
from app.utils import get_embedding
from app.database import DatabaseClient

router = APIRouter()
config = Config.from_env()
chorus_service = ChorusService(config)
db = DatabaseClient(config)

@router.post("/action", response_model=APIResponse)
async def process_action(request: ActionRequest):
    """
    First step of the Chorus Cycle - pure response with "beginner's mind"
    """
    try:
        result = await chorus_service.process_action(request.content)
        return APIResponse(
            success=True,
            data={
                "step": "action",
                "content": result.response,
                "confidence": result.confidence,
                "metadata": {
                    "reasoning": result.reasoning
                }
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/experience", response_model=APIResponse)
async def process_experience(request: ExperienceRequest):
    """
    Second step of the Chorus Cycle - find and synthesize relevant prior knowledge
    """
    try:
        # Get priors first
        embedding = await get_embedding(request.content, config.EMBEDDING_MODEL)
        priors = await db.search_vectors(embedding, limit=config.SEARCH_LIMIT)

        # Convert priors list to dictionary keyed by message_id
        priors_dict = {
            prior["id"]: {
                "content": prior["content"],
                "similarity": prior["similarity"],
                "created_at": prior["created_at"],
                "thread_id": prior["thread_id"],
                "role": prior["role"],
                "step": prior["step"]
            }
            for prior in priors
        }

        # Then get analysis - FIXED: Pass priors list to service
        result = await chorus_service.process_experience(
            request.content,
            request.action_response,
            priors  # Pass the raw priors list for analysis
        )

        return APIResponse(
            success=True,
            data={
                "step": "experience",
                "content": result.response,
                "confidence": result.confidence,
                "priors": priors_dict,  # Pass through priors as dictionary
                "metadata": {
                    "synthesis": result.synthesis
                }
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
