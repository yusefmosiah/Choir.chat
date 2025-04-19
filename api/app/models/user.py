"""User models for the API."""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class UserPublicKey(BaseModel):
    """User public key model for signature verification."""
    user_id: str = Field(..., description="User ID in the system")
    wallet_address: str = Field(..., description="Wallet address")
    public_key: str = Field(..., description="Public key in base64 format")
    key_scheme: int = Field(..., description="Key scheme (0 for Ed25519, 1 for Secp256k1, 2 for Secp256r1)")
    created_at: datetime = Field(default_factory=lambda: datetime.now(), description="Creation time")
    updated_at: Optional[datetime] = Field(None, description="Last update time")
