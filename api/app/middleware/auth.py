from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.services.auth_service import get_current_user
import jwt
from app.config import Config

config = Config.from_env()

class JWTBearer(HTTPBearer):
    def __init__(self, auto_error: bool = True):
        super(JWTBearer, self).__init__(auto_error=auto_error)

    async def __call__(self, request: Request):
        credentials: HTTPAuthorizationCredentials = await super(JWTBearer, self).__call__(request)

        if credentials:
            if not credentials.scheme == "Bearer":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Invalid authentication scheme."
                )

            try:
                # Verify the token
                payload = jwt.decode(
                    credentials.credentials,
                    config.JWT_SECRET_KEY,
                    algorithms=[config.JWT_ALGORITHM]
                )

                # Add user info to request state
                request.state.user_id = payload.get("sub")
                request.state.wallet_address = payload.get("wallet_address")

                return credentials.credentials

            except jwt.PyJWTError:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Invalid token or expired token."
                )

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid authorization code."
        )

# Create an instance for use in route dependencies
jwt_bearer = JWTBearer()
