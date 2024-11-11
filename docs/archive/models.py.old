from pydantic import BaseModel, validator
from typing import Set, List, Optional, Union, Dict, Any
from datetime import datetime
from enum import Enum

class StepEnum(str, Enum):
    ACTION = "action"
    EXPERIENCE = "experience"
    INTENTION = "intention"
    OBSERVATION = "observation"
    UPDATE = "update"
    YIELD = "yield"

class BaseState(BaseModel):
    id: str
    created_at: datetime
    updated_at: datetime
    version: int

    def validate_state(self):
        # Validation logic
        pass

    def transition_to(self, new_state: 'BaseState'):
        # Transition logic
        pass

class Thread(BaseState):
    co_authors: Set[str]
    messages: List['Message']
    token_balance: int
    status: 'ThreadStatus'

    @validator('co_authors')
    def validate_co_authors(cls, v):
        if not v:
            raise ValueError("Thread must have at least one co-author")
        return v

class Message(BaseState):
    content: str
    author: str
    approvals: Set['Approval']
    status: 'MessageStatus'
    thread_id: str

    @validator('content')
    def validate_content(cls, v):
        if not v.strip():
            raise ValueError("Content cannot be empty")
        if len(v) > 1000:  # Example max length
            raise ValueError("Content exceeds maximum length")
        return v

class ThreadStatus(str, Enum):
    ACTIVE = "active"
    CLOSED = "closed"

class MessageStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class Approval(BaseModel):
    co_author: str
    timestamp: datetime

class ConnectionState(BaseModel):
    client_id: str
    user: Optional[Dict[str, Any]]
    thread_id: Optional[str]
    status: str
    error_state: Optional[Dict[str, Any]]

class ClientMessage(BaseModel):
    type: str
    data: Dict[str, Any]

class ServerMessage(BaseModel):
    type: str
    data: Dict[str, Any]

class Effect(BaseModel):
    type: str
    payload: Dict[str, Any]

class ChorusState(BaseModel):
    messages: List[Message]
    current_step: StepEnum
    thread_id: str
    error_state: Optional[Dict[str, Any]] = None
    priors: Optional[List[Dict[str, Any]]] = None
    current_response: Optional[Dict[str, Any]] = None

class User(BaseModel):
    id: str
    public_key: str
    created_at: str
    chat_threads: List[str]

class ActionResponse(BaseModel):
    initial_thoughts: str
    proposed_response: str
    confidence: float

class Prior(BaseModel):
    id: str
    content: str
    thread_id: str
    similarity: float
    created_at: str
    role: str
    token_value: int = 0

class ExperienceResponse(BaseModel):
    synthesis: str
    confidence: float
    all_priors: List[Prior]  # Store all 80 priors

class IntentionResponse(BaseModel):
    explicit_intent: str
    implicit_intent: str
    confidence: float
    selected_priors: List[Prior]  # The most relevant priors selected from all_priors
    selection_reasoning: str  # Why these priors were selected

class ObservationResponse(BaseModel):
    patterns: List[str]
    context_analysis: str
    user_state: str
    confidence: float

class UpdateResponse(BaseModel):
    loop: bool  # True to continue cycle, False to proceed to yield
    reasoning: str
    confidence: float
    key_insights: List[str]

class YieldResponse(BaseModel):
    final_response: str
    reasoning: str
    confidence: float
    priors_used: Optional[List[str]] = None
