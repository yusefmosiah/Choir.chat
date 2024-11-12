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

        return APIResponse(
            success=True,
            data={
                "step": "intention",
                "content": result.response,
                "confidence": result.confidence,
                "selected_priors": result.selected_priors,
                "metadata": {
                    "reasoning": result.reasoning
                }
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/observation", response_model=APIResponse)
async def process_observation(request: ObservationRequest):
    """
    Fourth step of the Chorus Cycle - analyze patterns and insights
    """
    try:
        # Filter priors to only selected ones
        selected_priors = {
            prior_id: prior_data
            for prior_id, prior_data in request.priors.items()
            if prior_id in request.selected_priors
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
            data={
                "step": "observation",
                "id": result.id,  # Include the observation ID
                "content": result.response,
                "confidence": result.confidence,
                "patterns": result.patterns,
                "metadata": {
                    "reasoning": result.reasoning
                }
            }
        )
    except Exception as e:
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

        return APIResponse(
            success=True,
            data={
                "step": "understanding",
                "content": result.reasoning,
                "confidence": result.confidence,
                "should_yield": result.should_yield,
                "metadata": {
                    "next_action": result.next_action
                }
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/yield", response_model=APIResponse)
async def process_yield(request: YieldRequest):
    """
    Final step of the Chorus Cycle - synthesize final response with citations
    """
    try:
        # Filter priors to only selected ones
        selected_priors = {
            prior_id: prior_data
            for prior_id, prior_data in request.priors.items()
            if prior_id in request.selected_priors
        }

        result = await chorus_service.process_yield(
            content=request.content,
            action_response=request.action_response,
            experience_response=request.experience_response,
            intention_response=request.intention_response,
            observation_response=request.observation_response,
            understanding_response=request.understanding_response,
            selected_priors=selected_priors
        )

        return APIResponse(
            success=True,
            data={
                "step": "yield",
                "content": result.response,
                "confidence": result.confidence,
                "citations": result.citations,
                "metadata": {
                    "reasoning": result.reasoning
                }
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
