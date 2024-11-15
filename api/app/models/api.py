from pydantic import BaseModel, Field
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
    step: str = Field(..., description="The current phase name")
    content: str = Field(..., description="The main response content")
    confidence: float = Field(..., ge=0, le=1, description="Confidence score between 0 and 1")
    reasoning: str = Field(..., description="Reasoning behind the response")

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

# Move MessageContext definition before it's used
class MessageContext(BaseModel):
    content: str
    is_user: bool
    timestamp: str
    chorus_result: Optional[Dict[str, str]] = None

# Action models
class ActionRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    context: Optional[List[MessageContext]] = None

class ActionResponse(ChorusResponse):
    pass

# Experience models
class ExperienceRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    context: Optional[List[MessageContext]] = None

class ExperienceResponse(ChorusResponse):
    pass

class IntentionRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    priors: Dict[str, Dict[str, Any]]

class IntentionResponse(ChorusResponse):
    selected_priors: List[str] = Field(
        default_factory=list,
        description="IDs of selected relevant priors"
    )

class ObservationRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    intention_response: str
    selected_priors: List[str]
    priors: Dict[str, Dict[str, Any]]

class ObservationResponse(ChorusResponse):
    pass

class UnderstandingRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    intention_response: str
    observation_response: str
    patterns: List[Dict[str, str]]
    selected_priors: List[str]

class UnderstandingResponse(ChorusResponse):
    should_yield: bool = Field(..., description="Whether to proceed to yield phase")
    next_prompt: Optional[str] = Field(None, description="Next prompt if not yielding")

class YieldRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    action_response: str
    experience_response: str
    intention_response: str
    observation_response: str
    understanding_response: str
    selected_priors: List[str]
    priors: Dict[str, Dict[str, Any]]

class YieldResponse(ChorusResponse):
    pass
