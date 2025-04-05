from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict
import secrets
import time

router = APIRouter()

# Temporary in-memory challenge store: {address: (challenge, timestamp)}
from typing import Tuple

challenge_store: Dict[str, Tuple[str, float]] = {}

CHALLENGE_EXPIRY_SECONDS = 300  # 5 minutes

class ChallengeRequest(BaseModel):
    address: str  # Sui address string

class ChallengeResponse(BaseModel):
    challenge: str

class VerifyRequest(BaseModel):
    address: str
    signature: str

class VerifyResponse(BaseModel):
    user_id: str

@router.post("/request_challenge", response_model=ChallengeResponse)
async def request_challenge(req: ChallengeRequest):
    challenge = secrets.token_hex(16)
    challenge_store[req.address] = (challenge, time.time())
    return ChallengeResponse(challenge=challenge)

@router.post("/verify", response_model=VerifyResponse)
async def verify_signature(req: VerifyRequest):
    import base64
    import uuid, hashlib
    from app.database import DatabaseClient
    from app.config import Config
    # from pysui.sui.sui_crypto import verify_signature

    # Check challenge exists and is fresh
    entry = challenge_store.get(req.address)
    if not entry:
        raise HTTPException(status_code=400, detail="No challenge found for this address")
    challenge, timestamp = entry
    if time.time() - timestamp > CHALLENGE_EXPIRY_SECONDS:
        del challenge_store[req.address]
        raise HTTPException(status_code=400, detail="Challenge expired")

    try:
        # TODO: Restore real signature verification with pysui
        verified = True  # Mocked for testing account creation flow
    except Exception:
        verified = False

    if not verified:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Map Sui address to UUID (hash or generate)
    user_uuid = str(uuid.UUID(hashlib.sha256(req.address.encode()).hexdigest()[0:32]))

    # Create user in Qdrant if new
    db = DatabaseClient(Config.from_env())
    try:
        existing_user = await db.get_user(user_uuid)
    except Exception:
        existing_user = None

    if not existing_user:
        # Create user point
        from datetime import datetime, timezone
        payload = {
            "public_key": req.address,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "thread_ids": []
        }
        try:
            await db.client.upsert(
                collection_name=db.config.USERS_COLLECTION,
                points=[
                    {
                        "id": user_uuid,
                        "vector": [0.0] * db.config.VECTOR_SIZE,
                        "payload": payload
                    }
                ]
            )
        except Exception as e:
            print(f"Error creating user in Qdrant: {e}")

    # Cleanup challenge
    del challenge_store[req.address]

    return VerifyResponse(user_id=user_uuid)
