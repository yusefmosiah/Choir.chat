"""
Notification service for recording in-app notifications.
"""

import logging
from typing import Dict, Any, List, Optional
from app.database import DatabaseClient
from app.config import Config

# Configure logging
logger = logging.getLogger("notification_service")

class NotificationService:
    """Service for recording in-app notifications."""

    def __init__(self):
        """Initialize the notification service."""
        self.config = Config.from_env()
        self.db = DatabaseClient(self.config)

    async def send_citation_notification(self, vector_id: str, citing_wallet_address: str) -> Dict[str, Any]:
        """
        Record a citation notification in the database.

        Args:
            vector_id: The ID of the vector that was cited
            citing_wallet_address: The wallet address of the user who cited the content

        Returns:
            Result of the notification operation
        """
        logger.info(f"NOTIFICATION SERVICE: Sending citation notification for vector {vector_id} cited by {citing_wallet_address}")
        print(f"NOTIFICATION SERVICE: Sending citation notification for vector {vector_id} cited by {citing_wallet_address}")

        try:
            # Get the vector from the database to find the author
            logger.info(f"Retrieving vector {vector_id} from database")
            vector_info = await self.db.get_vector_by_id(vector_id)

            if vector_info:
                logger.info(f"Vector {vector_id} found in database")
                # Log vector content (truncated for privacy)
                content_preview = vector_info.get("content", "")[:100] + "..." if len(vector_info.get("content", "")) > 100 else vector_info.get("content", "")
                logger.info(f"Vector content preview: {content_preview}")
                # Log metadata keys (without values for privacy)
                metadata_keys = list(vector_info.get("metadata", {}).keys())
                logger.info(f"Vector metadata keys: {metadata_keys}")
            else:
                logger.warning(f"Vector {vector_id} not found, cannot record citation notification")
                return {
                    "success": False,
                    "reason": "vector_not_found",
                    "vector_id": vector_id
                }

            # Get the author's wallet address from the vector metadata
            author_wallet_address = vector_info.get("metadata", {}).get("wallet_address")
            logger.info(f"Author wallet address found: {bool(author_wallet_address)}")

            if not author_wallet_address:
                logger.warning(f"No wallet address found for vector {vector_id}, cannot record citation notification")
                return {
                    "success": False,
                    "reason": "author_not_found",
                    "vector_id": vector_id
                }

            # Determine if this is a self-citation
            is_self_citation = author_wallet_address == citing_wallet_address
            notification_type = "self_citation" if is_self_citation else "citation"

            # Create the notification record
            notification = {
                "type": notification_type,
                "recipient_wallet_address": author_wallet_address,
                "sender_wallet_address": citing_wallet_address,
                "vector_id": vector_id,
                "read": False,
                "created_at": None  # Will be set by the database client
            }

            logger.info(f"Preparing to save {notification_type} notification: {notification}")
            print(f"Preparing to save {notification_type} notification to {author_wallet_address}")

            # Save the notification to the database
            try:
                logger.info(f"Calling db.save_notification for {notification_type}")
                result = await self.db.save_notification(notification)
                logger.info(f"db.save_notification result: {result}")
            except Exception as e:
                logger.error(f"Exception in db.save_notification: {e}", exc_info=True)
                raise

            if result.get("id"):
                logger.info(f"Successfully recorded {notification_type} notification for {author_wallet_address} for vector {vector_id}")
                logger.info(f"Notification ID: {result.get('id')}")
                return {
                    "success": True,
                    "notification_id": result.get("id"),
                    "recipient": author_wallet_address,
                    "self_citation": is_self_citation
                }
            else:
                logger.error(f"Failed to record {notification_type} notification for {author_wallet_address}")
                logger.error(f"Save result: {result}")
                return {
                    "success": False,
                    "reason": "notification_save_failed",
                    "vector_id": vector_id
                }

        except Exception as e:
            logger.error(f"Error recording citation notification for vector {vector_id}: {e}", exc_info=True)
            return {
                "success": False,
                "reason": str(e),
                "vector_id": vector_id
            }
