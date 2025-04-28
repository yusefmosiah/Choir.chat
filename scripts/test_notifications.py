#!/usr/bin/env python3
"""
Test script for the notification system.

This script tests the end-to-end flow of the notification system:
1. Creates a test message
2. Creates a citation to that message
3. Verifies that a notification was created
"""

import asyncio
import sys
import os
import logging
import uuid
from datetime import datetime, UTC

# Add the API directory to the path so we can import from app
api_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'api')
sys.path.append(api_dir)

from app.config import Config
from app.database import DatabaseClient
from app.services.notification_service import NotificationService
from app.services.rewards_service import RewardsService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("test_notifications")

async def test_notification_flow():
    """Test the end-to-end notification flow."""
    config = Config.from_env()
    db = DatabaseClient(config)
    notification_service = NotificationService()
    rewards_service = RewardsService()

    # Generate test wallet addresses
    author_wallet = "0x" + uuid.uuid4().hex[:40]  # Generate a random wallet address
    citing_wallet = "0x" + uuid.uuid4().hex[:40]  # Generate a random wallet address

    logger.info(f"Test author wallet: {author_wallet}")
    logger.info(f"Test citing wallet: {citing_wallet}")

    # Step 1: Create a test message with the author's wallet address
    logger.info("Creating test message...")
    message_content = f"Test message created at {datetime.now(UTC).isoformat()}"
    message_vector = [0.1] * config.VECTOR_SIZE  # Simple test vector
    message_metadata = {
        "wallet_address": author_wallet,
        "test": True
    }

    message_result = await db.save_message({
        "content": message_content,
        "vector": message_vector,
        "metadata": message_metadata
    })

    if not message_result or "id" not in message_result:
        logger.error("Failed to create test message")
        return False

    vector_id = message_result["id"]
    logger.info(f"Created test message with ID: {vector_id}")

    # Step 2: Verify the message was created and has the correct metadata
    logger.info("Verifying test message...")
    vector_info = await db.get_vector_by_id(vector_id)

    if not vector_info:
        logger.error(f"Failed to retrieve test message with ID: {vector_id}")
        return False

    logger.info(f"Retrieved test message: {vector_info}")

    # Step 3: Test direct notification creation
    logger.info("Testing direct notification creation...")
    notification_result = await notification_service.send_citation_notification(
        vector_id=vector_id,
        citing_wallet_address=citing_wallet
    )

    if not notification_result or not notification_result.get("success"):
        logger.error(f"Failed to create notification: {notification_result}")
        return False

    logger.info(f"Direct notification result: {notification_result}")

    # Step 4: Test notification retrieval
    logger.info("Testing notification retrieval...")
    notifications = await db.get_user_notifications([author_wallet])

    if not notifications:
        logger.error("No notifications found for author wallet")
        return False

    logger.info(f"Retrieved {len(notifications)} notifications")
    for i, notification in enumerate(notifications):
        logger.info(f"Notification {i+1}: {notification}")

    # Step 5: Test notification creation through rewards service
    logger.info("Testing notification creation through rewards service...")
    rewards_result = await rewards_service.issue_citation_rewards(
        wallet_address=citing_wallet,
        citation_ids=[vector_id]
    )

    if not rewards_result or not rewards_result.get("success"):
        logger.error(f"Failed to issue citation rewards: {rewards_result}")
        return False

    logger.info(f"Rewards result: {rewards_result}")

    # Step 6: Verify that a second notification was created
    logger.info("Verifying second notification...")
    notifications_after = await db.get_user_notifications([author_wallet])

    if len(notifications_after) <= len(notifications):
        logger.error("No new notifications created through rewards service")
        return False

    logger.info(f"Retrieved {len(notifications_after)} notifications after rewards")
    for i, notification in enumerate(notifications_after):
        logger.info(f"Notification {i+1}: {notification}")

    logger.info("Notification test completed successfully!")
    return True

async def main():
    """Main function."""
    try:
        success = await test_notification_flow()
        if success:
            logger.info("All tests passed!")
            sys.exit(0)
        else:
            logger.error("Tests failed!")
            sys.exit(1)
    except Exception as e:
        logger.error(f"Error during tests: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
