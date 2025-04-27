"""
Notifications API router.
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from app.models.api import APIResponse
from app.database import DatabaseClient
from app.config import Config
from app.services.auth_service import get_current_user
from app.models.auth import TokenData

class DeviceTokenRegistration(BaseModel):
    device_token: str
    wallet_address: str

router = APIRouter()
config = Config.from_env()
db = DatabaseClient(config)

@router.get("", response_model=APIResponse)
async def get_notifications(current_user: TokenData = Depends(get_current_user)):
    """Get notifications for the current user."""
    try:
        if not current_user.wallet_address:
            return APIResponse(
                success=False,
                error="No wallet address associated with this user"
            )

        notifications = await db.get_user_notifications(current_user.wallet_address)

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
async def register_device_token(request: DeviceTokenRegistration, current_user: TokenData = Depends(get_current_user)):
    """Register a device token for push notifications."""
    try:
        # Verify that the wallet address matches the authenticated user
        if request.wallet_address != current_user.wallet_address:
            return APIResponse(
                success=False,
                error="Wallet address does not match authenticated user"
            )

        # Save the device token to the database
        result = await db.save_device_token(request.device_token, request.wallet_address)

        if "error" in result:
            return APIResponse(
                success=False,
                error=result.get("error", "Failed to register device token")
            )

        return APIResponse(
            success=True,
            data={"message": "Device token registered successfully"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
