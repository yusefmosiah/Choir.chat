"""
State schema for the PostChain graph.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from langchain_core.messages import BaseMessage

class PostChainState(BaseModel):
    """
    Structured state model for PostChain.

    This model represents the complete state for a PostChain conversation,
    including all messages, status tracking, and thread information required for
    the AEIOU-Y cycle processing.

    Each message can contain phase-specific metadata in its additional_kwargs
    attribute to track which phase generated the content.
    """

    # Core conversation state
    messages: List[BaseMessage] = Field(
        default_factory=list,
        description="Full conversation history including user and assistant messages with phase metadata"
    )
    current_phase: str = Field(
        "action",
        description="Current active phase in the AEIOU-Y cycle"
    )
    thread_id: Optional[str] = Field(
        None,
        description="Unique thread identifier for persistence"
    )

    # Processing state
    phase_state: Dict[str, str] = Field(
        default_factory=dict,
        description="Processing state for each phase (processing, complete, error)"
    )

    # Error handling
    error: Optional[str] = Field(
        None,
        description="Error message if any"
    )

    class Config:
        arbitrary_types_allowed = True
