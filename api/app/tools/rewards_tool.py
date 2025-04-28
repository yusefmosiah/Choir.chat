"""
Rewards tool for issuing citation rewards.
"""

import logging
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field, validator

from app.services.rewards_service import RewardsService
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)

class CitationRewardInput(BaseModel):
    """Input for the citation reward tool."""
    wallet_address: str = Field(..., description="The wallet address of the user who is citing content")
    citation_ids: List[str] = Field(..., description="The IDs of the vectors being cited")
    citation_explanations: Dict[str, str] = Field(default_factory=dict, description="Explanations for why each citation was included")

    @validator('wallet_address')
    def validate_wallet_address(cls, v):
        """Ensure wallet_address is not 'unknown'."""
        if v.lower() == 'unknown' or not v:
            raise ValueError("Cannot issue rewards to unknown wallet addresses")
        return v

    @validator('citation_ids')
    def validate_citation_ids(cls, v):
        """Ensure citation_ids are strings and remove duplicates."""
        # Convert all IDs to strings and remove duplicates
        return list(set(str(id) for id in v))

class CitationRewardOutput(BaseModel):
    """Output from the citation reward tool."""
    success: bool = Field(..., description="Whether the reward was successfully issued")
    reward_amount: float = Field(0.0, description="The amount of CHOIR tokens rewarded")
    digest: Optional[str] = Field(None, description="The transaction digest if successful")
    error: Optional[str] = Field(None, description="Error message if the reward failed")
    notification_results: List[Dict[str, Any]] = Field(default_factory=list, description="Results of sending notifications")
    author_rewards: List[Dict[str, Any]] = Field(default_factory=list, description="Rewards issued to authors of cited content")

class RewardsTool:
    """Tool for issuing citation rewards."""

    def __init__(self):
        logger.info("Initializing rewards tool")
        self.rewards_service = RewardsService()
        self.notification_service = NotificationService()

    async def issue_citation_rewards(self, input_data: CitationRewardInput) -> CitationRewardOutput:
        """Issue citation rewards for the given citations."""
        logger.info(f"TOOL CALLED: Issuing citation rewards for wallet {input_data.wallet_address} with citations: {input_data.citation_ids}")
        print(f"TOOL CALLED: Issuing citation rewards for wallet {input_data.wallet_address} with citations: {input_data.citation_ids}")

        try:
            if not input_data.citation_ids:
                return CitationRewardOutput(
                    success=False,
                    error="No citation IDs provided"
                )

            # Issue citation rewards to the authors of the cited content
            # The wallet_address is only used to track who is citing the content
            reward_result = await self.rewards_service.issue_citation_rewards(
                input_data.wallet_address,
                input_data.citation_ids
            )

            # Process notification results
            notification_results = []
            for vector_id in input_data.citation_ids:
                try:
                    notification_result = await self.notification_service.send_citation_notification(
                        vector_id=vector_id,
                        citing_wallet_address=input_data.wallet_address
                    )

                    notification_results.append({
                        "vector_id": vector_id,
                        "success": notification_result.get("success", False),
                        "recipient": notification_result.get("recipient"),
                        "reason": notification_result.get("reason")
                    })

                    if notification_result.get("success"):
                        logger.info(f"Sent citation notification for vector {vector_id} to {notification_result.get('recipient')}")
                    else:
                        logger.warning(f"Failed to send citation notification for vector {vector_id}: {notification_result.get('reason')}")

                except Exception as e:
                    logger.error(f"Error sending citation notification for vector {vector_id}: {e}", exc_info=True)
                    notification_results.append({
                        "vector_id": vector_id,
                        "success": False,
                        "reason": str(e)
                    })

            # Create the output
            if reward_result.get("success"):
                # Get the reward amount in smallest units
                reward_amount_base = reward_result.get("reward_amount", 0)

                # Convert to CHOIR tokens for display in the output
                reward_amount = reward_amount_base / 1_000_000_000

                # Get author rewards if available
                author_rewards = reward_result.get("author_rewards", [])

                # Convert author reward amounts from smallest unit to CHOIR tokens for display
                for reward in author_rewards:
                    if "reward_amount" in reward:
                        # Store the original amount in base units
                        base_amount = reward["reward_amount"]
                        # Convert to CHOIR tokens for display
                        reward["reward_amount"] = base_amount / 1_000_000_000

                return CitationRewardOutput(
                    success=True,
                    reward_amount=reward_amount,
                    digest=reward_result.get("digest"),
                    notification_results=notification_results,
                    author_rewards=author_rewards
                )
            else:
                return CitationRewardOutput(
                    success=False,
                    error=reward_result.get("reason") or "Unknown error",
                    notification_results=notification_results
                )

        except Exception as e:
            logger.error(f"Error issuing citation rewards: {e}", exc_info=True)
            return CitationRewardOutput(
                success=False,
                error=str(e)
            )

def get_rewards_tool():
    """Get the rewards tool."""
    logger.info("Getting rewards tool")
    rewards_tool = RewardsTool()

    # Create a simpler schema for the tool
    tool_def = {
        "type": "function",
        "function": {
            "name": "issue_citation_rewards",
            "description": "Issue citation rewards to the authors of the cited content and send notifications to them",
            "parameters": {
                "type": "object",
                "properties": {
                    "wallet_address": {
                        "type": "string",
                        "description": "The wallet address of the user who is citing content"
                    },
                    "citation_ids": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        },
                        "description": "The IDs of the vectors being cited"
                    }
                },
                "required": ["wallet_address", "citation_ids"]
            }
        },
        "coroutine": rewards_tool.issue_citation_rewards
    }

    logger.info(f"Returning rewards tool definition: {tool_def}")
    return tool_def
