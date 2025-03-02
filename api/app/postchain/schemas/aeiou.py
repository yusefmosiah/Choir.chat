"""
Schemas for the AEIOU cycle.
"""

from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional, Union

class AEIOUPhaseOutput(BaseModel):
    """Output schema for an AEIOU phase."""
    content: str = Field(..., description="The content of the phase output")

class ActionOutput(AEIOUPhaseOutput):
    """Output schema for the Action phase."""
    pass

class ExperienceOutput(AEIOUPhaseOutput):
    """Output schema for the Experience phase."""
    pass

class IntentionOutput(AEIOUPhaseOutput):
    """Output schema for the Intention phase."""
    pass

class ObservationOutput(AEIOUPhaseOutput):
    """Output schema for the Observation phase."""
    pass

class UnderstandingOutput(BaseModel):
    """Output schema for the Update phase."""
    should_loop: bool = Field(..., description="Whether to loop back to Action or proceed to Yield")
    reasoning: str = Field(..., description="Reasoning for the decision")

class YieldOutput(AEIOUPhaseOutput):
    """Output schema for the Yield phase."""
    pass

class AEIOUContext(BaseModel):
    """Context for the AEIOU cycle."""
    action_response: Optional[str] = Field(None, description="Response from the Action phase")
    experience_response: Optional[str] = Field(None, description="Response from the Experience phase")
    intention_response: Optional[str] = Field(None, description="Response from the Intention phase")
    observation_response: Optional[str] = Field(None, description="Response from the Observation phase")
    update_response: Optional[str] = Field(None, description="Response from the Update phase")
    yield_response: Optional[str] = Field(None, description="Response from the Yield phase")

class AEIOUState(BaseModel):
    """State for the AEIOU cycle."""
    messages: List[Any] = Field([], description="List of messages in the conversation")
    phase: str = Field("start", description="Current phase in the AEIOU cycle")
    should_loop: bool = Field(False, description="Whether to loop back to Action or proceed to Yield")
    context: AEIOUContext = Field(default_factory=AEIOUContext, description="Context information for the conversation")
    user_input: str = Field(..., description="The original user input")
    final_response: Optional[str] = Field(None, description="The final response to return to the user")
    max_loops: int = Field(2, description="Maximum number of loops allowed")
    current_loop: int = Field(0, description="Current loop count")
