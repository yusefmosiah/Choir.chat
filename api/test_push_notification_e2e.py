#!/usr/bin/env python3
"""
End-to-end test script for push notifications in the Choir app.

This script tests the complete flow of push notifications:
1. Verifies APNs configuration
2. Tests sending a notification to a specific device token
3. Tests the citation notification flow
4. Verifies notification delivery

Usage:
    python test_push_notification_e2e.py [device_token]

If device_token is provided, it will be used for testing.
Otherwise, the script will prompt for a device token.
"""

import asyncio
import sys
import os
import logging
import json
import uuid
from datetime import datetime, UTC

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("push_notification_test")

# Import services
from app.config import Config
from app.database import DatabaseClient
from app.services.push_notification_service import PushNotificationService
from app.services.notification_service import NotificationService
from app.services.rewards_service import RewardsService

async def test_apns_configuration():
    """Test the APNs configuration."""
    logger.info("Testing APNs configuration...")
    
    # Print environment variables
    logger.info(f"APNS_KEY_ID: {os.environ.get('APNS_KEY_ID', 'Not set')}")
    logger.info(f"APNS_TEAM_ID: {os.environ.get('APNS_TEAM_ID', 'Not set')}")
    logger.info(f"APNS_AUTH_KEY: {os.environ.get('APNS_AUTH_KEY', 'Not set')}")
    logger.info(f"APNS_TOPIC: {os.environ.get('APNS_TOPIC', 'Not set')}")
    
    # Initialize the push notification service
    push_service = PushNotificationService()
    
    try:
        # Generate a token
        token = push_service._get_apns_token()
        logger.info(f"Successfully generated APNs token: {token[:20]}...")
        return True
    except Exception as e:
        logger.error(f"Error generating APNs token: {e}", exc_info=True)
        return False

async def test_direct_notification(device_token):
    """Test sending a direct notification to a device."""
    logger.info(f"Testing direct notification to device token: {device_token[:8]}...")
    
    # Initialize the push notification service
    push_service = PushNotificationService()
    
    try:
        # Send a test notification
        result = await push_service.send_push_notification(
            device_token=device_token,
            title="Choir Test Notification",
            body="This is a test notification from the Choir app",
            data={"notification_type": "test"}
        )
        
        if result.get("success"):
            logger.info("Successfully sent test notification!")
            return True
        else:
            logger.error(f"Failed to send test notification: {result}")
            return False
    except Exception as e:
        logger.error(f"Error sending test notification: {e}", exc_info=True)
        return False

async def test_citation_notification_flow(device_token):
    """Test the complete citation notification flow."""
    logger.info("Testing citation notification flow...")
    
    config = Config.from_env()
    db = DatabaseClient(config)
    notification_service = NotificationService()
    rewards_service = RewardsService()
    
    # Generate test wallet addresses
    author_wallet = "0x" + uuid.uuid4().hex[:40]
    citing_wallet = "0x" + uuid.uuid4().hex[:40]
    
    logger.info(f"Test author wallet: {author_wallet}")
    logger.info(f"Test citing wallet: {citing_wallet}")
    
    # Step 1: Register the device token for the author's wallet
    try:
        logger.info(f"Registering device token for author wallet...")
        
        # Create a device token record
        token_payload = {
            "type": "device_token",
            "wallet_address": author_wallet,
            "token": device_token,
            "created_at": datetime.now(UTC).isoformat(),
            "platform": "ios"
        }
        
        # Save to database
        token_id = str(uuid.uuid4())
        db.client.upsert(
            collection_name=config.NOTIFICATIONS_COLLECTION,
            points=[
                models.PointStruct(
                    id=token_id,
                    vector=[0.0] * config.VECTOR_SIZE,  # Placeholder vector
                    payload=token_payload
                )
            ]
        )
        
        logger.info(f"Successfully registered device token for author wallet")
    except Exception as e:
        logger.error(f"Error registering device token: {e}", exc_info=True)
        return False
    
    # Step 2: Create a test vector with the author's wallet address
    try:
        logger.info("Creating test vector...")
        
        message_content = f"Test vector for citation notification created at {datetime.now(UTC).isoformat()}"
        message_vector = [0.1] * config.VECTOR_SIZE
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
            logger.error("Failed to create test vector")
            return False
        
        vector_id = message_result["id"]
        logger.info(f"Created test vector with ID: {vector_id}")
    except Exception as e:
        logger.error(f"Error creating test vector: {e}", exc_info=True)
        return False
    
    # Step 3: Simulate a citation to the vector
    try:
        logger.info(f"Simulating citation to vector {vector_id}...")
        
        # Send citation notification
        notification_result = await notification_service.send_citation_notification(
            vector_id=vector_id,
            citing_wallet_address=citing_wallet
        )
        
        if not notification_result or not notification_result.get("success"):
            logger.error(f"Failed to send citation notification: {notification_result}")
            return False
        
        logger.info(f"Citation notification result: {notification_result}")
        
        # Check push notification result
        push_result = notification_result.get("push_notification", {})
        if push_result.get("success"):
            logger.info("Push notification was sent successfully!")
        else:
            logger.warning(f"Push notification was not sent: {push_result}")
        
        return True
    except Exception as e:
        logger.error(f"Error in citation notification flow: {e}", exc_info=True)
        return False

async def main():
    """Main function."""
    # Get device token from command line or prompt
    if len(sys.argv) > 1:
        device_token = sys.argv[1]
    else:
        device_token = input("Enter a device token for testing: ")
    
    if not device_token:
        logger.error("No device token provided. Exiting.")
        sys.exit(1)
    
    # Test APNs configuration
    apns_config_valid = await test_apns_configuration()
    if not apns_config_valid:
        logger.error("APNs configuration is invalid. Please check your environment variables.")
        sys.exit(1)
    
    # Test direct notification
    direct_notification_success = await test_direct_notification(device_token)
    if not direct_notification_success:
        logger.warning("Direct notification test failed. Check the device token and APNs configuration.")
    
    # Test citation notification flow
    citation_flow_success = await test_citation_notification_flow(device_token)
    if citation_flow_success:
        logger.info("Citation notification flow test completed successfully!")
    else:
        logger.error("Citation notification flow test failed.")
    
    # Print summary
    logger.info("\nTest Summary:")
    logger.info(f"APNs Configuration: {'✅ Valid' if apns_config_valid else '❌ Invalid'}")
    logger.info(f"Direct Notification: {'✅ Success' if direct_notification_success else '❌ Failed'}")
    logger.info(f"Citation Flow: {'✅ Success' if citation_flow_success else '❌ Failed'}")
    
    if apns_config_valid and (direct_notification_success or citation_flow_success):
        logger.info("\nPush notification system is working! Check your device for notifications.")
        sys.exit(0)
    else:
        logger.error("\nPush notification system has issues. Please check the logs for details.")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
