"""
Rewards service for issuing Choir coins to users.
"""

import logging
import re
import math
from typing import Dict, List, Optional, Tuple, Any
import asyncio

from app.services.sui_service import SuiService
from app.services.notification_service import NotificationService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RewardsService:
    def __init__(self):
        self.sui_service = SuiService()
        self.notification_service = NotificationService()

    async def calculate_novelty_reward(self, max_similarity: float) -> int:
        """
        Calculate the reward amount for a novel prompt based on its similarity score.

        Args:
            max_similarity: The maximum similarity score (0.0 to 1.0) of the prompt compared to existing vectors

        Returns:
            The reward amount in CHOIR tokens (in Sui's smallest unit)
        """
        # If max_similarity is close to 1.0, the prompt is not novel
        if max_similarity > 0.95:
            return 0

        # Base reward amount (1 CHOIR = 1_000_000_000 units)
        base_reward = 1_000_000_000

        # Constants with clear meaning
        reference_similarity = 0.95  # The reference point where reward = min_reward
        min_reward = 0.01            # Reward at reference similarity
        reward_factor = 10           # How much reward increases per similarity_step
        similarity_step = 0.05       # How much similarity needs to decrease for reward to increase by reward_factor

        # Calculate exponent: ln(reward_factor) / similarity_step
        # This gives us how much the exponent changes per unit of similarity
        exponent_factor = math.log(reward_factor) / similarity_step

        # Calculate the reward using natural exponential function
        # This creates an exponential scale where:
        # 0.95 -> 0.01 CHOIR
        # 0.90 -> 0.1 CHOIR
        # 0.85 -> 1.0 CHOIR
        # 0.80 -> 10.0 CHOIR
        # 0.75 -> 100.0 CHOIR
        reward_multiplier = min_reward * math.exp(exponent_factor * (reference_similarity - max_similarity))

        # Cap the reward at 100 CHOIR
        reward_multiplier = min(reward_multiplier, 100.0)

        # Convert to smallest units
        scaled_reward = int(base_reward * reward_multiplier)

        logger.info(f"Calculated novelty reward: {scaled_reward/1_000_000_000} CHOIR (similarity: {max_similarity})")
        return scaled_reward

    def extract_citations(self, content: str) -> List[str]:
        """
        Extract citation IDs from the yield phase content.

        Args:
            content: The content of the yield phase response

        Returns:
            List of citation IDs
        """
        # First try to extract <vid>vector_id</vid> format
        vid_citations = re.findall(r'<vid>(.*?)</vid>', content)
        if vid_citations:
            logger.info(f"Found {len(vid_citations)} citations in <vid> format")
            return list(set(vid_citations))

        # If no <vid> tags found, try the old #number format
        citation_refs = re.findall(r'#(\d+)', content)
        if citation_refs:
            logger.info(f"Found {len(citation_refs)} citations in #number format")
            return list(set(citation_refs))

        # If no citations found in either format
        logger.info("No citations found in content")
        return []

    async def issue_novelty_reward(self, wallet_address: str, max_similarity: float) -> Dict[str, Any]:
        """
        Issue a reward for a novel prompt.

        Args:
            wallet_address: The wallet address to send the reward to
            max_similarity: The maximum similarity score of the prompt

        Returns:
            Result of the mint operation
        """
        reward_amount = await self.calculate_novelty_reward(max_similarity)

        if reward_amount <= 0:
            logger.info(f"No novelty reward issued for wallet {wallet_address} (similarity too high)")
            return {
                "success": False,
                "reason": "similarity_too_high",
                "similarity": max_similarity,
                "wallet": wallet_address
            }

        # Issue the reward
        result = await self.sui_service.mint_choir(wallet_address, reward_amount)

        if result["success"]:
            logger.info(f"Successfully issued novelty reward of {reward_amount/1_000_000_000} CHOIR to {wallet_address}")
        else:
            logger.error(f"Failed to issue novelty reward to {wallet_address}: {result.get('error')}")

        # Add reward details to the result
        result["reward_type"] = "novelty"
        result["reward_amount"] = reward_amount
        result["similarity"] = max_similarity

        return result

    async def issue_citation_rewards(self, wallet_address: str, citation_ids: List[str]) -> Dict[str, Any]:
        """
        Issue rewards for citations.

        Args:
            wallet_address: The wallet address to send the reward to
            citation_ids: List of vector IDs that were cited

        Returns:
            Result of the mint operation
        """
        logger.info(f"REWARDS SERVICE: Issuing citation rewards for wallet {wallet_address} with citations: {citation_ids}")
        print(f"REWARDS SERVICE: Issuing citation rewards for wallet {wallet_address} with citations: {citation_ids}")

        # Ensure citation_ids is a list
        if not citation_ids or not isinstance(citation_ids, list) or len(citation_ids) == 0:
            logger.info(f"No citation reward issued for wallet {wallet_address} (no citations)")
            return {
                "success": False,
                "reason": "no_citations",
                "wallet": wallet_address
            }

        # Base reward per citation (5 CHOIR = 5_000_000_000 units)
        base_reward_per_citation = 5_000_000_000

        # Cap at 5 citations max
        effective_citation_count = min(5, len(citation_ids))

        # We don't issue rewards to the citing user, only to the authors of the cited content
        # Initialize result with success=True
        result = {
            "success": True,
            "author_rewards": []
        }

        # Issue rewards to the authors of the cited content
        if citation_ids:
            from app.database import DatabaseClient
            from app.config import Config

            db = DatabaseClient(Config.from_env())
            author_rewards = []
            total_reward_amount = 0

            for vector_id in citation_ids:
                try:
                    # Get the vector to find the author
                    vector_info = await db.get_vector_by_id(vector_id)

                    if vector_info:
                        # Get the author's wallet address
                        author_wallet_address = vector_info.get("metadata", {}).get("wallet_address")

                        # Log only non-sensitive metadata for debugging
                        safe_metadata = vector_info.get('metadata', {}).copy()
                        if 'wallet_address' in safe_metadata:
                            safe_metadata['wallet_address'] = '***redacted***'
                        logger.info(f"Vector {vector_id} metadata (sensitive info redacted): {safe_metadata}")

                        # Skip if no wallet address or if it's "unknown"
                        if not author_wallet_address or author_wallet_address.lower() == "unknown":
                            logger.warning(f"No valid wallet address found for vector {vector_id}, skipping reward")
                            author_rewards.append({
                                "vector_id": vector_id,
                                "author": None,
                                "success": False,
                                "reason": "author_not_found"
                            })
                            continue

                        # Skip if the author is the same as the citing user (no self-rewards)
                        if author_wallet_address == wallet_address:
                            logger.info(f"Skipping self-citation reward for vector {vector_id}")
                            author_rewards.append({
                                "vector_id": vector_id,
                                "author": author_wallet_address,
                                "success": False,
                                "reason": "self_citation"
                            })

                            # Still send a self-citation notification
                            try:
                                notification_result = await self.notification_service.send_citation_notification(
                                    vector_id=vector_id,
                                    citing_wallet_address=wallet_address
                                )
                                logger.info(f"Self-citation notification result: {notification_result}")
                            except Exception as e:
                                logger.error(f"Error sending self-citation notification for vector {vector_id}: {e}", exc_info=True)

                            continue

                        # If we get here, we have a valid author wallet address
                        # Issue reward to the author
                        author_result = await self.sui_service.mint_choir(author_wallet_address, base_reward_per_citation)
                        total_reward_amount += base_reward_per_citation

                        if author_result["success"]:
                            logger.info(f"Successfully issued citation reward of {base_reward_per_citation/1_000_000_000} CHOIR to author {author_wallet_address} for vector {vector_id}")
                            author_rewards.append({
                                "vector_id": vector_id,
                                "author": author_wallet_address,
                                "reward_amount": base_reward_per_citation,
                                "success": True,
                                "digest": author_result.get("digest")
                            })

                            # Send citation notification
                            try:
                                notification_result = await self.notification_service.send_citation_notification(
                                    vector_id=vector_id,
                                    citing_wallet_address=wallet_address
                                )
                                logger.info(f"Citation notification result: {notification_result}")
                            except Exception as e:
                                logger.error(f"Error sending citation notification for vector {vector_id}: {e}", exc_info=True)
                        else:
                            logger.error(f"Failed to issue citation reward to author {author_wallet_address}: {author_result.get('error')}")
                            author_rewards.append({
                                "vector_id": vector_id,
                                "author": author_wallet_address,
                                "success": False,
                                "error": author_result.get("error")
                            })
                except Exception as e:
                    logger.error(f"Error processing author reward for vector {vector_id}: {e}", exc_info=True)

            # Add author rewards to the result
            result["author_rewards"] = author_rewards
            result["reward_amount"] = total_reward_amount / 1_000_000_000

        # Log error if the reward failed
        if not result["success"]:
            logger.error(f"Failed to issue citation reward to authors: {result.get('error')}")

        # Add reward details to the result
        result["reward_type"] = "citation"

        # Make sure reward_amount is set (it should be set above, but just in case)
        if "reward_amount" not in result:
            result["reward_amount"] = 0

        return result
