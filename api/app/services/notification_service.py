"""
Notification service for sending notifications to users.
"""

import logging
from typing import Dict, Any, List, Optional
from app.database import DatabaseClient
from app.config import Config

# Configure logging
logger = logging.getLogger("notification_service")

class NotificationService:
    """Service for sending notifications to users."""
    
    def __init__(self):
        """Initialize the notification service."""
        self.config = Config.from_env()
        self.db = DatabaseClient(self.config)
        
    async def send_citation_notification(self, vector_id: str, citing_wallet_address: str) -> Dict[str, Any]:
        """
        Send a notification to the user whose content was cited.
        
        Args:
            vector_id: The ID of the vector that was cited
            citing_wallet_address: The wallet address of the user who cited the content
            
        Returns:
            Result of the notification operation
        """
        try:
            # Get the vector from the database to find the author
            vector_info = await self.db.get_vector_by_id(vector_id)
            
            if not vector_info:
                logger.warning(f"Vector {vector_id} not found, cannot send citation notification")
                return {
                    "success": False,
                    "reason": "vector_not_found",
                    "vector_id": vector_id
                }
            
            # Get the author's wallet address from the vector metadata
            author_wallet_address = vector_info.get("metadata", {}).get("wallet_address")
            
            if not author_wallet_address:
                logger.warning(f"No wallet address found for vector {vector_id}, cannot send citation notification")
                return {
                    "success": False,
                    "reason": "author_not_found",
                    "vector_id": vector_id
                }
                
            # Don't send notification if the author is the same as the citing user
            if author_wallet_address == citing_wallet_address:
                logger.info(f"Author {author_wallet_address} is the same as citing user, skipping notification")
                return {
                    "success": False,
                    "reason": "self_citation",
                    "vector_id": vector_id
                }
            
            # Create the notification
            notification = {
                "type": "citation",
                "recipient_wallet_address": author_wallet_address,
                "sender_wallet_address": citing_wallet_address,
                "vector_id": vector_id,
                "read": False
            }
            
            # Save the notification to the database
            result = await self.db.save_notification(notification)
            
            if result.get("id"):
                logger.info(f"Successfully sent citation notification to {author_wallet_address} for vector {vector_id}")
                return {
                    "success": True,
                    "notification_id": result.get("id"),
                    "recipient": author_wallet_address
                }
            else:
                logger.error(f"Failed to send citation notification to {author_wallet_address} for vector {vector_id}")
                return {
                    "success": False,
                    "reason": "notification_save_failed",
                    "vector_id": vector_id
                }
                
        except Exception as e:
            logger.error(f"Error sending citation notification for vector {vector_id}: {e}", exc_info=True)
            return {
                "success": False,
                "reason": str(e),
                "vector_id": vector_id
            }
