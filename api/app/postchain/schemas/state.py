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
    including all phase outputs, status tracking, and metadata required for
    the AEIOU-Y cycle processing.
    """
    # Configure model to disable protected namespace warnings
    model_config = {
        "protected_namespaces": ()  # Disable protected namespace checks
    }

    # Core conversation state
    messages: List[BaseMessage] = Field(
        default_factory=list,
        description="Full conversation history including user and assistant messages"
    )
    current_phase: str = Field(
        "action",
        description="Current active phase in the AEIOU-Y cycle"
    )
    thread_id: Optional[str] = Field(
        None,
        description="Unique thread identifier for persistence"
    )

    # Phase-specific state tracking
    phase_outputs: Dict[str, str] = Field(
        default_factory=dict,
        description="Output content for each phase"
    )
    phase_state: Dict[str, str] = Field(
        default_factory=dict,
        description="Processing state for each phase (processing, complete, error)"
    )

    # Enhanced metadata
    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Phase-specific metadata and structured data"
    )
    tools_used: List[str] = Field(
        default_factory=list,
        description="Record of tools used during processing"
    )
    search_results: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Search results from external sources"
    )
    model_attempts: Dict[str, List[str]] = Field(
        default_factory=dict,
        description="Record of model attempts for each phase"
    )

    # Context management
    summary: Optional[str] = Field(
        None,
        description="Summary of conversation history"
    )
    context_window_size: int = Field(
        10,
        description="Number of messages to keep in context"
    )

    # Flow control
    next_phase: Optional[str] = Field(
        None,
        description="Override for next phase to execute"
    )
    error: Optional[str] = Field(
        None,
        description="Error message if any"
    )
