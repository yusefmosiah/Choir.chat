"""
Notifications API router.
"""

from fastapi import APIRouter, HTTPException, Depends, Body
from typing import Optional, Dict, Any, List
from app.models.api import APIResponse
from app.database import DatabaseClient
from app.config import Config
from app.services.auth_service import get_current_user
from app.models.auth import TokenData
from app.services.notification_service import NotificationService
from app.services.push_notification_service import PushNotificationService

router = APIRouter()
config = Config.from_env()
db = DatabaseClient(config)
notification_service = NotificationService()
push_notification_service = PushNotificationService()

@router.get("", response_model=APIResponse)
async def get_notifications(wallet_address: Optional[str] = None, current_user: TokenData = Depends(get_current_user)):
    """
    Get notifications/transactions for the current user across all their wallets.

    Args:
        wallet_address: Optional wallet address to filter notifications for a specific wallet
    """
    try:
        if not current_user.wallet_address:
            return APIResponse(
                success=False,
                error="No wallet address associated with this user"
            )

        # Get all wallet addresses for the user
        wallet_addresses = []

        # If a specific wallet address is provided, only get notifications for that wallet
        if wallet_address:
            wallet_addresses = [wallet_address]
        else:
            # Otherwise, get all wallet addresses associated with the user
            # For now, we only have the authenticated wallet address
            # In the future, this could be expanded to include all wallets the user has
            wallet_addresses = [current_user.wallet_address]

        # Get notifications for all wallet addresses
        notifications = await db.get_user_notifications(wallet_addresses)

        return APIResponse(
            success=True,
            data={"notifications": notifications}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{notification_id}/read", response_model=APIResponse)
async def mark_notification_as_read(notification_id: str, current_user: TokenData = Depends(get_current_user)):
    """Mark a notification as read."""
    try:
        result = await db.mark_notification_as_read(notification_id)

        if not result.get("success"):
            return APIResponse(
                success=False,
                error=result.get("reason", "Failed to mark notification as read")
            )

        return APIResponse(
            success=True,
            data={"notification_id": notification_id}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/register-device", response_model=APIResponse)
async def register_device_token(
    device_token: str = Body(..., embed=True),
    wallet_address: str = Body(..., embed=True),
    current_user: TokenData = Depends(get_current_user)
):
    """
    Register a device token for push notifications.

    Args:
        device_token: The device token to register
        wallet_address: The wallet address to associate with the device token
    """
    try:
        # Verify that the wallet address belongs to the authenticated user
        if wallet_address != current_user.wallet_address:
            return APIResponse(
                success=False,
                error="Cannot register device token for a wallet address that doesn't belong to you"
            )

        # Save the device token
        result = await db.save_device_token(device_token, wallet_address)

        if not result.get("success"):
            return APIResponse(
                success=False,
                error=result.get("reason", "Failed to register device token")
            )

        return APIResponse(
            success=True,
            message="Device token registered successfully",
            data={"wallet_address": wallet_address}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/test-push", response_model=APIResponse)
async def test_push_notification(
    device_token: str = Body(..., embed=True),
    current_user: TokenData = Depends(get_current_user)
):
    """
    Send a test push notification to a device.

    Args:
        device_token: The device token to send the notification to
    """
    try:
        # Send a test notification
        result = await push_notification_service.send_push_notification(
            device_token=device_token,
            title="Test Notification",
            body="This is a test notification from Choir",
            data={"notification_type": "test"}
        )

        if not result.get("success"):
            return APIResponse(
                success=False,
                error=f"Failed to send test notification: {result.get('error', 'Unknown error')}"
            )

        return APIResponse(
            success=True,
            message="Test notification sent successfully",
            data=result
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
