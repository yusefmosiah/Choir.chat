from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

# Base request/response models
class APIResponse(BaseModel):
    success: bool
    message: Optional[str] = None
    data: Optional[Dict[str, Any]] = None

# Chorus cycle models
class ChorusRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    previous_responses: Optional[Dict[str, str]] = None

class ChorusResponse(BaseModel):
    step: str
    content: str
    confidence: float
    priors: Optional[List[Dict[str, Any]]] = None
    metadata: Optional[Dict[str, Any]] = None

# Vector operation models
class VectorSearchRequest(BaseModel):
    query_vector: List[float]
    limit: Optional[int] = 10

class VectorStoreRequest(BaseModel):
    content: str
    vector: List[float]
    metadata: Optional[Dict[str, Any]] = None

# Thread models
class ThreadCreate(BaseModel):
    name: str
    user_id: str
    initial_message: Optional[str] = None

class ThreadUpdate(BaseModel):
    name: Optional[str] = None
    co_authors: Optional[List[str]] = None

class ThreadResponse(BaseModel):
    id: str
    name: str
    created_at: datetime
    user_id: str
    co_authors: List[str]
    message_count: int
    last_activity: datetime

# User models
class UserCreate(BaseModel):
    public_key: str

class UserResponse(BaseModel):
    id: str
    public_key: str
    created_at: datetime
    thread_ids: List[str]

# Action models
class ActionRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None

class ActionResponse(BaseModel):
    response: str
    confidence: float
    reasoning: str

# Experience models
class ExperienceRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str  # Previous action response

class ExperienceResponse(BaseModel):
    response: str  # Analysis of how priors relate to query
    confidence: float
    synthesis: str  # How these priors connect to the current context

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "response": "Analysis of how priors relate to current query",
                "confidence": 0.8,
                "synthesis": "How these priors connect to the current context"
            }]
        }
    }

class IntentionRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    priors: Dict[str, Dict[str, Any]]  # Priors from experience phase

class IntentionResponse(BaseModel):
    reasoning: str  # Why these priors were selected
    selected_priors: List[str]  # IDs of most relevant priors
    response: str  # Analysis of intent
    confidence: float

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "reasoning": "Why these priors were selected",
                "selected_priors": ["prior_id_1", "prior_id_2"],
                "response": "Analysis of user's intent and relevant priors",
                "confidence": 0.8
            }]
        }
    }

class ObservationRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    intention_response: str
    selected_priors: List[str]  # IDs from intention phase
    priors: Dict[str, Dict[str, Any]]  # Full priors dictionary

class ObservationResponse(BaseModel):
    id: str
    reasoning: str
    patterns: List[Dict[str, Any]]
    response: str
    confidence: float

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "reasoning": "Analysis of patterns in priors and responses",
                "patterns": [
                    {"type": "theme", "description": "Pattern description"},
                    {"type": "insight", "description": "Insight description"}
                ],
                "response": "Synthesis of observations",
                "confidence": 0.8
            }]
        }
    }

class UnderstandingRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    intention_response: str
    observation_response: str
    patterns: List[Dict[str, Any]]  # Patterns from observation
    selected_priors: List[str]  # Selected priors from intention

class UnderstandingResponse(BaseModel):
    reasoning: str  # Analysis of whether we have sufficient understanding
    should_yield: bool  # Whether to proceed to yield or loop back
    confidence: float
    next_action: Optional[str] = None  # Suggested focus if looping back
    next_prompt: Optional[str] = None  # The actual prompt to use in next action phase

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "reasoning": "Analysis of understanding completeness",
                "should_yield": True,
                "confidence": 0.8,
                "next_action": None,
                "next_prompt": None
            }, {
                "reasoning": "Need to explore creative aspects",
                "should_yield": False,
                "confidence": 0.7,
                "next_action": "Explore creative storytelling",
                "next_prompt": "Tell me a story about a choir that incorporates themes of community and artistic expression"
            }]
        }
    }

class YieldRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    intention_response: str
    observation_response: str
    understanding_response: str
    selected_priors: List[str]  # Selected priors from intention
    priors: Dict[str, Dict[str, Any]]  # Full priors dictionary

class YieldResponse(BaseModel):
    reasoning: str  # How the response incorporates priors and insights
    citations: List[Dict[str, Any]]  # List of cited priors with context
    response: str  # Final synthesized response
    confidence: float

    model_config = {
        "json_schema_extra": {
            "examples": [{
                "reasoning": "How the response incorporates priors and insights",
                "citations": [
                    {
                        "prior_id": "id1",
                        "content": "cited content",
                        "context": "how this prior was used"
                    }
                ],
                "response": "Final synthesized response with inline citations",
                "confidence": 0.9
            }]
        }
    }
