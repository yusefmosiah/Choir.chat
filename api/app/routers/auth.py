import logging
from fastapi import APIRouter, HTTPException, status, Depends
from app.models.auth import ChallengeRequest, ChallengeResponse, AuthRequest, AuthResponse, TokenData
from app.services.auth_service import AuthService, get_current_user
from app.config import Config
from datetime import datetime, UTC

router = APIRouter()
config = Config.from_env()
auth_service = AuthService()
logger = logging.getLogger(__name__)

@router.post("/challenge", response_model=ChallengeResponse)
async def get_challenge(request: ChallengeRequest):
    """Get a challenge string for authentication"""
    logger = logging.getLogger(__name__)
    logger.info(f"Challenge request received for wallet: {request.wallet_address}")

    try:
        challenge, expires_at = auth_service.generate_challenge(request.wallet_address)
        logger.info(f"Challenge generated: {challenge}, expires at: {expires_at}")

        response = ChallengeResponse(
            challenge=challenge,
            expires_at=expires_at
        )
        logger.info(f"Returning challenge response: {response}")
        return response
    except Exception as e:
        logger.error(f"Error generating challenge: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating challenge: {str(e)}"
        )

@router.post("/login", response_model=AuthResponse)
async def login(request: AuthRequest):
    """Authenticate with a signed challenge"""
    logger = logging.getLogger(__name__)
    logger.info(f"Login request received for wallet: {request.wallet_address}")
    logger.info(f"Challenge: {request.challenge}")
    logger.info(f"Signature: {request.signature}")

    # Verify the signature
    is_valid = auth_service.verify_challenge(
        request.wallet_address,
        request.challenge,
        request.signature
    )

    if not is_valid:
        logger.warning(f"Invalid signature or expired challenge for wallet: {request.wallet_address}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature or expired challenge"
        )

    logger.info(f"Signature verified successfully for wallet: {request.wallet_address}")

    # Get or create user
    user_id = await auth_service.get_or_create_user(request.wallet_address)
    logger.info(f"User ID: {user_id} for wallet: {request.wallet_address}")

    # Create access token
    token, expires_at = auth_service.create_access_token(user_id, request.wallet_address)
    logger.info(f"Access token created, expires at: {expires_at}")

    response = AuthResponse(
        access_token=token,
        token_type="bearer",
        expires_at=expires_at,
        user_id=user_id
    )

    logger.info(f"Returning login response for user: {user_id}")
    return response

@router.get("/me", response_model=TokenData)
async def get_current_user_info(current_user: TokenData = Depends(get_current_user)):
    """Get information about the currently authenticated user"""
    # Get logger instance
    logger.info(f"Current user info request received for user: {current_user.user_id}, wallet: {current_user.wallet_address}, expires at: {current_user.exp}")
    return current_user
