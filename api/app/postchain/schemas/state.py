"""
State schema for the PostChain graph.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from langchain_core.messages import BaseMessage

class PostChainState(BaseModel):
    """State for the PostChain graph."""
    messages: List[BaseMessage] = Field(default_factory=list)
    current_step: str = "action"
    thread_id: Optional[str] = None
    error_state: Optional[Dict[str, Any]] = None
    priors: Optional[List[Dict[str, Any]]] = None
    responses: Dict[str, Any] = Field(default_factory=dict)
    should_loop: bool = False
    tools_used: List[Dict[str, Any]] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)