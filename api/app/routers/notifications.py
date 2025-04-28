"""
Transactions API router.
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import Optional
from app.models.api import APIResponse
from app.database import DatabaseClient
from app.config import Config
from app.services.auth_service import get_current_user
from app.models.auth import TokenData

router = APIRouter()
config = Config.from_env()
db = DatabaseClient(config)

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
