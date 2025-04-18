import logging
import secrets
import time
from datetime import datetime, timedelta, UTC
from typing import Dict, Optional, Tuple

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

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
    def verify_challenge(wallet_address: str, challenge: str, signature: str) -> bool:
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

            # For now, we'll use a temporary verification method
            # In a production environment, you would implement proper signature verification
            # using PySUI's cryptographic functions
            try:
                # The message that was signed by the client
                message_text = f"Sign this message to authenticate with Choir: {challenge}"

                # Convert the signature from hex to bytes
                signature_bytes = bytes.fromhex(clean_signature)

                # For now, we'll assume the signature is valid if it's properly formatted
                # This is a temporary solution until proper verification is implemented
                is_valid = len(signature_bytes) > 0

                # Log that we're using a temporary verification method
                logger.warning("Using temporary signature verification - implement proper verification!")
                logger.warning("For proper verification, see: https://pysui.readthedocs.io/en/latest/pysui.abstracts.html")

                if is_valid:
                    logger.info(f"Signature format verified for wallet {wallet_address} (temporary verification)")
                else:
                    logger.warning(f"Signature format verification failed for wallet {wallet_address}")

                # TODO: Implement proper signature verification using PySUI
                # The proper implementation would follow these steps:
                # 1. Format the message with the challenge
                # 2. Apply ULEB128 length prefixing using PureInput.pure
                # 3. Add intent prefix [3, 0, 0] for personal messages
                # 4. Hash using Blake2b-256
                # 5. Verify the signature against the hash using the public key
                # Reference: https://pysui.readthedocs.io/en/latest/pysui.abstracts.html
            except Exception as e:
                logger.error(f"Error processing signature: {e}")
                is_valid = False

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
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # Decode the JWT token
        payload = jwt.decode(
            token,
            config.JWT_SECRET_KEY,
            algorithms=[config.JWT_ALGORITHM]
        )

        user_id: str = payload.get("sub")
        wallet_address: str = payload.get("wallet_address")

        if user_id is None or wallet_address is None:
            raise credentials_exception

        # Check token expiration
        exp = payload.get("exp")
        if exp is None or time.time() > exp:
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

    except jwt.PyJWTError:
        raise credentials_exception
