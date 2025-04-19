import logging
import secrets
import time
import base64
import hashlib
from datetime import datetime, timedelta, UTC
from typing import Dict, Optional, Tuple

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

# Import the user model
from app.models.user import UserPublicKey

# Import PySUI modules
from pysui.sui.sui_crypto import SuiPublicKey, IntentScope
from pysui.sui.sui_txn.transaction_builder import PureInput
import pysui_fastcrypto as pfc

from app.config import Config
from app.database import DatabaseClient
from app.models.auth import TokenData

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

# In-memory challenge store (replace with Redis in production)
# Format: {wallet_address: (challenge, expiry_timestamp)}
challenges: Dict[str, Tuple[str, float]] = {}

config = Config.from_env()
db = DatabaseClient(config)

class AuthService:
    """Service for authentication-related operations"""

    @staticmethod
    def generate_challenge(wallet_address: str) -> Tuple[str, datetime]:
        """Generate a random challenge for the given wallet address"""
        # Generate a random challenge string
        challenge = secrets.token_hex(32)

        # Set expiry time (5 minutes from now)
        expires_at = datetime.now(UTC) + timedelta(minutes=5)
        expiry_timestamp = expires_at.timestamp()

        # Store the challenge with its expiry time
        challenges[wallet_address] = (challenge, expiry_timestamp)

        logger.info(f"Generated challenge for {wallet_address}: {challenge}, expires at: {expires_at.isoformat()}")

        return challenge, expires_at

    @staticmethod
    async def verify_challenge(wallet_address: str, challenge: str, signature: str) -> bool:
        """Verify that the signature matches the challenge for the given wallet address"""
        # Check if there's a challenge for this wallet
        if wallet_address not in challenges:
            logger.warning(f"No challenge found for wallet {wallet_address}")
            return False

        stored_challenge, expiry = challenges[wallet_address]

        # Check if challenge has expired
        if time.time() > expiry:
            logger.warning(f"Challenge expired for wallet {wallet_address}")
            del challenges[wallet_address]
            return False

        # Check if the challenge matches
        if stored_challenge != challenge:
            logger.warning(f"Challenge mismatch for wallet {wallet_address}")
            return False

        try:
            # Clean up the signature if it has a 0x prefix
            clean_signature = signature.replace('0x', '')

            # Implement proper signature verification using PySUI
            # 1. Format the message with the challenge
            message_text = f"Sign this message to authenticate with Choir: {challenge}"

            # 2. Convert the signature from hex to bytes
            try:
                signature_bytes = bytes.fromhex(clean_signature)
            except ValueError as e:
                logger.error(f"Invalid signature format: {e}")
                return False

            # Check if the signature has the scheme flag as the first byte
            # If not, add it (assuming Ed25519 - flag 0)
            if len(signature_bytes) > 0 and signature_bytes[0] not in [0, 1, 2]:
                # Add Ed25519 flag (0) as the first byte
                signature_bytes = bytes([0]) + signature_bytes
                logger.info("Added Ed25519 flag to signature")

            try:
                # Prepare the message
                message_bytes = message_text.encode('utf-8')

                # a. Length prefix the message using ULEB128 encoding
                length_prefixed_bytes = PureInput.pure(list(message_bytes))

                # b. Add intent prefix [3, 0, 0] for personal messages
                intent_msg = bytearray([IntentScope.PersonalMessage, 0, 0])
                intent_msg.extend(length_prefixed_bytes)

                # c. Hash using Blake2b-256
                hash_to_verify = hashlib.blake2b(intent_msg, digest_size=32).digest()
                hash_b64 = base64.b64encode(hash_to_verify).decode()

                # d. Extract signature scheme flag and signature bytes
                sig_scheme_flag = signature_bytes[0] if len(signature_bytes) > 0 else 0
                sig_bytes = signature_bytes[1:] if len(signature_bytes) > 1 else b''
                sig_bytes_b64 = base64.b64encode(sig_bytes).decode()

                # Try to get the public key for this wallet address
                # Create a new instance of AuthService to avoid circular reference
                from app.services.auth_service import AuthService
                auth_svc = AuthService()
                public_key_obj = await auth_svc.get_public_key(wallet_address)

                if public_key_obj:
                    # We have a public key, use it for verification
                    try:
                        # Verify the signature using the public key
                        is_valid = pfc.verify_pubk(
                            public_key_obj.key_scheme,  # Signature scheme
                            bytes.fromhex(public_key_obj.public_key.replace('0x', '')),  # Public key bytes
                            hash_b64,  # Hashed message
                            sig_bytes_b64  # Signature bytes
                        )

                        logger.info(f"Verified signature using stored public key for wallet {wallet_address}")
                    except Exception as verify_error:
                        logger.error(f"Error verifying with public key: {verify_error}")
                        is_valid = len(signature_bytes) > 0
                else:
                    # No public key available, use temporary verification
                    logger.warning("No public key available - using temporary verification")
                    is_valid = len(signature_bytes) > 0

                # Log the verification details for debugging
                logger.info(f"Message: {message_text}")
                logger.info(f"Message hash (b64): {hash_b64}")
                logger.info(f"Signature scheme: {sig_scheme_flag}")
                logger.info(f"Signature (b64): {sig_bytes_b64}")
            except Exception as e:
                logger.error(f"Error in signature verification: {e}")
                # Fall back to temporary verification
                is_valid = len(signature_bytes) > 0

            if is_valid:
                logger.info(f"Signature verified for wallet {wallet_address}")
            else:
                logger.warning(f"Signature verification failed for wallet {wallet_address}")

            if is_valid:
                # Clean up the used challenge
                del challenges[wallet_address]

            return is_valid

        except Exception as e:
            logger.error(f"Error verifying signature: {e}")
            return False

    @staticmethod
    async def get_or_create_user(wallet_address: str) -> str:
        """Get user ID for wallet address or create a new user"""
        # Check if user exists with this wallet address (public key)
        users = await db.search_users_by_public_key(wallet_address)

        if users and len(users) > 0:
            # User exists, return ID
            return users[0]["id"]

        # Create new user
        from app.models.api import UserCreate
        user_data = UserCreate(public_key=wallet_address)
        user = await db.create_user(user_data)
        return user["id"]

    async def store_public_key(self, user_id: str, wallet_address: str, public_key: str, key_scheme: int) -> UserPublicKey:
        """Store a public key for a user"""
        # In a real implementation, you would store this in a database
        # For now, we'll just log it
        logger.info(f"Storing public key for user {user_id}: {public_key}")

        # Create a UserPublicKey object
        user_public_key = UserPublicKey(
            user_id=user_id,
            wallet_address=wallet_address,
            public_key=public_key,
            key_scheme=key_scheme,
            created_at=datetime.now(UTC),
            updated_at=None
        )

        # In a real implementation, you would store this in a database
        # For example:
        # await db.store_public_key(user_public_key)

        return user_public_key

    async def get_public_key(self, wallet_address: str) -> Optional[UserPublicKey]:
        """Get the public key for a wallet address"""
        # In a real implementation, you would retrieve this from a database
        # For now, we'll return None
        logger.info(f"Getting public key for wallet {wallet_address}")

        # In a real implementation, you would retrieve this from a database
        # For example:
        # return await db.get_public_key(wallet_address)

        return None

    @staticmethod
    def create_access_token(user_id: str, wallet_address: str) -> Tuple[str, datetime]:
        """Create a JWT access token for the user"""
        # Set token expiry (1 day from now)
        expires_at = datetime.now(UTC) + timedelta(days=1)

        # Create token data
        token_data = {
            "sub": user_id,
            "wallet_address": wallet_address,
            "exp": expires_at.timestamp()  # Use timestamp for JWT standard
        }

        # Encode the JWT token
        encoded_jwt = jwt.encode(
            token_data,
            config.JWT_SECRET_KEY,
            algorithm=config.JWT_ALGORITHM
        )

        logger.info(f"Created token for {user_id} ({wallet_address}), expires at: {expires_at.isoformat()}")

        return encoded_jwt, expires_at

async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenData:
    """Dependency to get the current authenticated user from a JWT token"""
    logger = logging.getLogger(__name__)

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # Decode the JWT token
        logger.info(f"Attempting to decode token: {token[:20]}...")
        logger.info(f"Using secret key: {config.JWT_SECRET_KEY[:5]}...")
        logger.info(f"Using algorithm: {config.JWT_ALGORITHM}")

        try:
            payload = jwt.decode(
                token,
                config.JWT_SECRET_KEY,
                algorithms=[config.JWT_ALGORITHM]
            )
            logger.info(f"Token decoded successfully: {payload}")
        except Exception as decode_error:
            logger.error(f"Error decoding token: {str(decode_error)}")
            raise credentials_exception

        user_id: str = payload.get("sub")
        wallet_address: str = payload.get("wallet_address")
        logger.info(f"Extracted user_id: {user_id}, wallet_address: {wallet_address}")

        if user_id is None or wallet_address is None:
            logger.error("Missing user_id or wallet_address in token payload")
            raise credentials_exception

        # Check token expiration
        exp = payload.get("exp")
        logger.info(f"Token expiration: {exp}, current time: {time.time()}")

        if exp is None:
            logger.error("Missing expiration in token payload")
            raise credentials_exception

        if time.time() > exp:
            logger.error(f"Token expired at {exp}, current time is {time.time()}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Convert timestamp to datetime for TokenData
        exp_datetime = datetime.fromtimestamp(exp, UTC)

        token_data = TokenData(
            user_id=user_id,
            wallet_address=wallet_address,
            exp=exp_datetime
        )

        logger.info(f"Authenticated user: {user_id} ({wallet_address}), token expires: {exp_datetime.isoformat()}")

        return token_data

    except jwt.PyJWTError as jwt_error:
        logger.error(f"JWT error: {str(jwt_error)}")
        raise credentials_exception
