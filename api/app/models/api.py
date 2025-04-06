from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# Base request/response models
class APIResponse(BaseModel):
    success: bool
    message: Optional[str] = None
    data: Optional[Dict[str, Any]] = None


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


# Message models for API response
class MessageResponseModel(BaseModel):
    id: str
    content: Optional[str] = None
    thread_id: str
    role: Optional[str] = None
    timestamp: Optional[datetime] = None
    phase_outputs: Optional[Dict[str, str]] = None
    novelty_score: Optional[float] = None
    similarity_scores: Optional[List[float]] = None
    cited_prior_ids: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None

    class Config:
        orm_mode = True # Enable ORM mode for potential future use with ORMs

class MessagesDataModel(BaseModel):
    messages: List[MessageResponseModel]

class MessagesAPIResponseModel(BaseModel):
    success: bool
    message: Optional[str] = None
    data: Optional[MessagesDataModel] = None

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
