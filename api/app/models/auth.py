from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime

class ChallengeRequest(BaseModel):
    """Request to get a challenge for authentication"""
    wallet_address: str = Field(..., description="The Sui wallet address requesting a challenge")

class ChallengeResponse(BaseModel):
    """Response containing a challenge for authentication"""
    challenge: str = Field(..., description="Random challenge string to be signed")
    expires_at: datetime = Field(..., description="Expiration time of the challenge")

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat()
        }

class AuthRequest(BaseModel):
    """Request to authenticate with a signed challenge"""
    wallet_address: str = Field(..., description="The Sui wallet address")
    signature: str = Field(..., description="The signature of the challenge")
    challenge: str = Field(..., description="The challenge that was signed")

class AuthResponse(BaseModel):
    """Response containing authentication token"""
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field("bearer", description="Token type")
    expires_at: datetime = Field(..., description="Expiration time of the token")
    user_id: str = Field(..., description="User ID in the system")

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat()
        }

class TokenData(BaseModel):
    """Data stored in JWT token"""
    user_id: str
    wallet_address: str
    exp: Optional[datetime] = None

    class Config:
        json_encoders = {
            datetime: lambda dt: dt.isoformat()
        }
