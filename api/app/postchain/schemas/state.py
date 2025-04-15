"""
State schema for the PostChain graph.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from langchain_core.messages import BaseMessage, AIMessage # Import AIMessage

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

# --- Search Result Models ---

class SearchResult(BaseModel):
    """Represents a single web search result."""
    title: str = Field(..., description="Title of the search result")
    url: str = Field(..., description="URL of the search result")
    content: str = Field(..., description="Snippet or content summary")
    provider: Optional[str] = Field(None, description="Search provider (e.g., brave, tavily)")

class VectorSearchResult(BaseModel):
    """Represents a single vector database search result."""
    content: str = Field(..., description="Content of the retrieved document chunk")
    score: float = Field(..., description="Similarity score")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Associated metadata")
    provider: Optional[str] = Field("qdrant", description="Vector DB provider")
    id: Optional[str] = Field(None, description="Unique identifier for this vector result")
    content_preview: Optional[str] = Field(None, description="Short preview of the content")

# --- Phase Output Models ---

class ExperiencePhaseOutput(BaseModel):
    """Structured output for the Experience phase."""
    experience_response: AIMessage = Field(..., description="The AI's reflective analysis message")
    web_results: List[SearchResult] = Field(default_factory=list, description="List of web search results used")
    vector_results: List[VectorSearchResult] = Field(default_factory=list, description="List of vector search results used")
    error: Optional[str] = Field(None, description="Error message if the phase failed")


class ExperienceVectorsPhaseOutput(BaseModel):
    """Structured output for the Experience Vectors phase."""
    experience_vectors_response: AIMessage = Field(..., description="The AI's message potentially triggering or summarizing the vector search")
    vector_results: List[VectorSearchResult] = Field(default_factory=list, description="List of vector search results found")
    error: Optional[str] = Field(None, description="Error message if the phase failed")

    class Config:
        arbitrary_types_allowed = True

class ExperienceWebPhaseOutput(BaseModel):
    """Structured output for the Experience Web phase."""
    experience_web_response: AIMessage = Field(..., description="The AI's message potentially triggering or summarizing the web search")
    web_results: List[SearchResult] = Field(default_factory=list, description="List of web search results found")
    error: Optional[str] = Field(None, description="Error message if the phase failed")

    class Config:
        arbitrary_types_allowed = True
