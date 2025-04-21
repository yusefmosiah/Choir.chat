"""
Rewards service for issuing Choir coins to users.
"""

import logging
import re
from typing import Dict, List, Optional, Tuple, Any
import asyncio

from app.services.sui_service import SuiService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RewardsService:
    def __init__(self):
        self.sui_service = SuiService()
        
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
            
        # Calculate novelty score (1 - similarity)
        # Apply softmax-like transformation to emphasize differences
        novelty_score = 1 - max_similarity
        
        # Base reward amount (1 CHOIR = 1_000_000_000 units)
        base_reward = 1_000_000_000
        
        # Scale reward based on novelty (0.1 to 1.0 CHOIR)
        scaled_reward = int(base_reward * max(0.1, min(1.0, novelty_score)))
        
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
        # Extract all #number references
        citation_refs = re.findall(r'#(\d+)', content)
        if not citation_refs:
            return []
            
        # Return unique citation references
        return list(set(citation_refs))
    
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
    
    async def issue_citation_rewards(self, wallet_address: str, citation_count: int) -> Dict[str, Any]:
        """
        Issue rewards for citations.
        
        Args:
            wallet_address: The wallet address to send the reward to
            citation_count: The number of citations
            
        Returns:
            Result of the mint operation
        """
        if citation_count <= 0:
            logger.info(f"No citation reward issued for wallet {wallet_address} (no citations)")
            return {
                "success": False,
                "reason": "no_citations",
                "citation_count": 0,
                "wallet": wallet_address
            }
            
        # Base reward per citation (0.5 CHOIR = 500_000_000 units)
        base_reward_per_citation = 500_000_000
        
        # Cap at 5 citations max
        effective_citation_count = min(5, citation_count)
        
        # Calculate total reward
        reward_amount = base_reward_per_citation * effective_citation_count
        
        # Issue the reward
        result = await self.sui_service.mint_choir(wallet_address, reward_amount)
        
        if result["success"]:
            logger.info(f"Successfully issued citation reward of {reward_amount/1_000_000_000} CHOIR to {wallet_address} for {effective_citation_count} citations")
        else:
            logger.error(f"Failed to issue citation reward to {wallet_address}: {result.get('error')}")
            
        # Add reward details to the result
        result["reward_type"] = "citation"
        result["reward_amount"] = reward_amount
        result["citation_count"] = effective_citation_count
        
        return result
