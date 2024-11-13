from fastapi import APIRouter, HTTPException
from app.models.api import ActionRequest, ActionResponse, APIResponse, ExperienceRequest, ExperienceResponse, IntentionRequest, ObservationRequest, UnderstandingRequest, UnderstandingResponse, YieldRequest
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
            data=result.model_dump()
        )
    except Exception as e:
        return APIResponse(
            success=False,
            message=str(e),
            data=None
        )

@router.post("/experience", response_model=APIResponse)
async def process_experience(request: ExperienceRequest):
    """
    Second step of the Chorus Cycle - find and synthesize relevant prior knowledge
    """
    try:
        # Get priors first
        embedding = await get_embedding(request.content, config.EMBEDDING_MODEL)
        priors = await db.search_vectors(embedding, limit=config.SEARCH_LIMIT)

        # Get the experience response
        result = await chorus_service.process_experience(
            request.content,
            request.action_response,
            priors
        )

        # Return both the experience response and the priors
        return APIResponse(
            success=True,
            data={
                **result.dict(),  # The experience response
                "priors": {  # Pass through the priors directly
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
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/intention", response_model=APIResponse)
async def process_intention(request: IntentionRequest):
    """
    Third step of the Chorus Cycle - analyze intent and select relevant priors
    """
    try:
        result = await chorus_service.process_intention(
            content=request.content,
            action_response=request.action_response,
            experience_response=request.experience_response,
            priors=request.priors
        )

        # Ensure the response includes selected_priors
        response_data = result.model_dump()
        if "selected_priors" not in response_data:
            response_data["selected_priors"] = []

        return APIResponse(
            success=True,
            data=response_data
        )
    except Exception as e:
        logger.error(f"Error in intention endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing intention: {str(e)}"
        )

@router.post("/observation", response_model=APIResponse)
async def process_observation(request: ObservationRequest):
    """
    Fourth step of the Chorus Cycle - analyze patterns and insights
    """
    try:
        # Filter priors to only selected ones
        selected_priors = {
            prior_id: request.priors[prior_id]
            for prior_id in request.selected_priors
            if prior_id in request.priors
        }

        result = await chorus_service.process_observation(
            content=request.content,
            action_response=request.action_response,
            experience_response=request.experience_response,
            intention_response=request.intention_response,
            selected_priors=selected_priors
        )
        return APIResponse(
            success=True,
            data=result.model_dump()  # Use model_dump() to convert to dict
        )
    except Exception as e:
        logger.error(f"Error in observation endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/understanding", response_model=APIResponse)
async def process_understanding(request: UnderstandingRequest):
    """
    Fifth step of the Chorus Cycle - decide whether to yield or loop back
    """
    try:
        result = await chorus_service.process_understanding(
            content=request.content,
            action_response=request.action_response,
            experience_response=request.experience_response,
            intention_response=request.intention_response,
            observation_response=request.observation_response,
            patterns=request.patterns,
            selected_priors=request.selected_priors
        )

        # Convert to dict and ensure required fields
        response_data = result.model_dump()
        if "should_yield" not in response_data:
            response_data["should_yield"] = True
        if not response_data["should_yield"] and "next_prompt" not in response_data:
            response_data["next_prompt"] = "Please provide more information."

        return APIResponse(
            success=True,
            data=response_data
        )
    except Exception as e:
        logger.error(f"Error in understanding endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing understanding: {str(e)}"
        )

@router.post("/yield", response_model=APIResponse)
async def process_yield(request: YieldRequest):
    """
    Final step of the Chorus Cycle - synthesize final response with citations
    """
    try:
        # Filter priors to only selected ones
        selected_prior_data = {
            prior_id: request.priors[prior_id]
            for prior_id in request.selected_priors
            if prior_id in request.priors
        }

        result = await chorus_service.process_yield(
            content=request.content,
            action_response=request.action_response,
            experience_response=request.experience_response,
            intention_response=request.intention_response,
            observation_response=request.observation_response,
            understanding_response=request.understanding_response,
            selected_priors=request.selected_priors,
            priors=selected_prior_data
        )
        return APIResponse(
            success=True,
            data=result.model_dump()
        )
    except Exception as e:
        logger.error(f"Error in yield endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing yield: {str(e)}"
        )
