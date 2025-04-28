"""
Reward schemas for the PostChain.
"""

from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

class RewardInfo(BaseModel):
    """Information about a reward issued to a user."""
    reward_type: str = Field(..., description="Type of reward (novelty, citation)")
    reward_amount: int = Field(..., description="Amount of CHOIR tokens issued (in smallest unit)")
    success: bool = Field(..., description="Whether the reward was successfully issued")
    digest: Optional[str] = Field(None, description="Transaction digest if successful")
    error: Optional[str] = Field(None, description="Error message if unsuccessful")

    # Additional fields based on reward type
    similarity: Optional[float] = Field(None, description="Similarity score for novelty rewards")

class NoveltyRewardInfo(RewardInfo):
    """Information about a novelty reward."""
    reward_type: str = "novelty"
    similarity: float = Field(..., description="Similarity score used to calculate the reward")

class CitationRewardInfo(RewardInfo):
    """Information about a citation reward."""
    reward_type: str = "citation"
    cited_messages: Optional[List[str]] = Field(None, description="IDs of cited messages")
    author_rewards: Optional[List[Dict[str, Any]]] = Field(None, description="Information about rewards issued to authors (with sensitive info redacted)")
