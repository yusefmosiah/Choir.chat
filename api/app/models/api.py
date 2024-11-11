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
