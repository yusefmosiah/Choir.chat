"""
Test script for sending push notifications via APNs.
"""

import asyncio
import os
from app.services.push_notification_service import PushNotificationService

async def test_apns_token():
    """Test generating an APNs authentication token."""
    push_service = PushNotificationService()
    
    try:
        # Try to generate a token
        token = push_service._get_apns_token()
        print(f"Successfully generated APNs token: {token[:20]}...")
        return True
    except Exception as e:
        print(f"Error generating APNs token: {e}")
        return False

async def main():
    """Main test function."""
    print("Testing APNs configuration...")
    print(f"APNS_KEY_ID: {os.environ.get('APNS_KEY_ID', 'Not set')}")
    print(f"APNS_TEAM_ID: {os.environ.get('APNS_TEAM_ID', 'Not set')}")
    print(f"APNS_AUTH_KEY: {os.environ.get('APNS_AUTH_KEY', 'Not set')}")
    print(f"APNS_TOPIC: {os.environ.get('APNS_TOPIC', 'Not set')}")
    
    # Test APNs token generation
    token_success = await test_apns_token()
    
    if token_success:
        print("\nAPNs configuration is valid! You can now send push notifications.")
    else:
        print("\nAPNs configuration is invalid. Please check your environment variables and key file.")

if __name__ == "__main__":
    asyncio.run(main())
