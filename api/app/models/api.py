from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# Base request/response models
class APIResponse(BaseModel): # Keep this generic
    success: bool
    message: Optional[str] = None
    data: Optional[Dict[str, Any]] = None # Allow flexible data structure


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

# Turn model (represents the structure within the list)
class TurnResponseModel(BaseModel):
    id: str
    content: Optional[str] = None # AI response content
    user_query: Optional[str] = Field(None, alias='user_query') # Explicit alias
    thread_id: str = Field(..., alias='thread_id') # Explicit alias, ensure it's required
    # role: Optional[str] = None # Role removed
    timestamp: Optional[datetime] = None # Keep as datetime for validation, will be stringified by FastAPI/Pydantic
    phase_outputs: Optional[Dict[str, str]] = Field(None, alias='phase_outputs')
    novelty_score: Optional[float] = Field(None, alias='novelty_score')
    similarity_scores: Optional[Any] = Field(None, alias='similarity_scores') # Keep Any for flexibility
    cited_prior_ids: Optional[List[str]] = Field(None, alias='cited_prior_ids')
    metadata: Optional[Dict[str, Any]] = None

    class Config:
        populate_by_name = True # Allow using alias for population

# Defines the structure within the 'data' field for the turns response
class TurnsDataModel(BaseModel):
    turns: List[TurnResponseModel]

# Defines the overall API response structure for fetching turns
class TurnsAPIResponseModel(BaseModel):
    success: bool
    message: Optional[str] = None
    data: Optional[TurnsDataModel] = None
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
