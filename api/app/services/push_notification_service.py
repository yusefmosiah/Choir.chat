"""
Push notification service for sending notifications to mobile devices.
"""

import logging
import json
import http.client
import jwt
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta, UTC
from app.database import DatabaseClient
from app.config import Config

# Configure logging
logger = logging.getLogger("push_notification_service")

class PushNotificationService:
    """Service for sending push notifications to mobile devices."""

    def __init__(self):
        """Initialize the push notification service."""
        self.config = Config.from_env()
        self.db = DatabaseClient(self.config)
        
        # Apple Push Notification service configuration
        self.apns_key_id = self.config.APNS_KEY_ID
        self.apns_team_id = self.config.APNS_TEAM_ID
        self.apns_auth_key = self.config.APNS_AUTH_KEY
        self.apns_topic = self.config.APNS_TOPIC  # Bundle ID of your app
        self.apns_production = not self.config.DEBUG  # Use production APNs in non-debug mode
        
        # Cache the JWT token for 50 minutes (APNs tokens are valid for 60 minutes)
        self.apns_token = None
        self.apns_token_expiry = datetime.now(UTC)

    def _get_apns_token(self) -> str:
        """
        Get a JWT token for APNs authentication.
        
        Returns:
            A JWT token for APNs authentication
        """
        # Check if we have a valid token
        if self.apns_token and datetime.now(UTC) < self.apns_token_expiry:
            return self.apns_token
            
        # Create a new token
        try:
            # Token is valid for 60 minutes, but we'll refresh after 50
            token_expiry = datetime.now(UTC) + timedelta(minutes=50)
            
            # Create the JWT payload
            token_payload = {
                'iss': self.apns_team_id,
                'iat': datetime.now(UTC).timestamp()
            }
            
            # Sign the token with the private key
            with open(self.apns_auth_key, 'r') as key_file:
                private_key = key_file.read()
                
            token = jwt.encode(
                token_payload,
                private_key,
                algorithm='ES256',
                headers={
                    'kid': self.apns_key_id
                }
            )
            
            # Cache the token
            self.apns_token = token
            self.apns_token_expiry = token_expiry
            
            return token
        except Exception as e:
            logger.error(f"Error creating APNs token: {e}", exc_info=True)
            raise

    async def get_device_tokens_for_wallet(self, wallet_address: str) -> List[str]:
        """
        Get all device tokens for a wallet address.
        
        Args:
            wallet_address: The wallet address to get device tokens for
            
        Returns:
            List of device tokens
        """
        try:
            # Query the database for device tokens
            search_result = await self.db.client.scroll(
                collection_name=self.config.NOTIFICATIONS_COLLECTION,
                scroll_filter=models.Filter(
                    must=[
                        models.FieldCondition(
                            key="type",
                            match=models.MatchValue(value="device_token")
                        ),
                        models.FieldCondition(
                            key="wallet_address",
                            match=models.MatchValue(value=wallet_address)
                        )
                    ]
                ),
                limit=100,  # Get up to 100 device tokens
                with_payload=True
            )
            
            points, _ = search_result
            
            # Extract the tokens
            tokens = [point.payload.get("token") for point in points if point.payload.get("token")]
            
            logger.info(f"Found {len(tokens)} device tokens for wallet {wallet_address}")
            return tokens
        except Exception as e:
            logger.error(f"Error getting device tokens for wallet {wallet_address}: {e}", exc_info=True)
            return []

    async def send_push_notification(self, device_token: str, title: str, body: str, data: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Send a push notification to a device.
        
        Args:
            device_token: The device token to send the notification to
            title: The notification title
            body: The notification body
            data: Additional data to include with the notification
            
        Returns:
            Result of the send operation
        """
        try:
            # Determine the APNs server to use
            if self.apns_production:
                apns_host = "api.push.apple.com"
            else:
                apns_host = "api.sandbox.push.apple.com"
                
            # Create the notification payload
            payload = {
                "aps": {
                    "alert": {
                        "title": title,
                        "body": body
                    },
                    "sound": "default",
                    "badge": 1
                }
            }
            
            # Add custom data if provided
            if data:
                payload.update(data)
                
            # Convert payload to JSON
            payload_json = json.dumps(payload)
            
            # Get the APNs token
            token = self._get_apns_token()
            
            # Set up the connection
            conn = http.client.HTTPSConnection(apns_host, 443)
            
            # Set up the headers
            headers = {
                "authorization": f"bearer {token}",
                "apns-topic": self.apns_topic,
                "apns-push-type": "alert",
                "apns-priority": "10"  # High priority
            }
            
            # Send the notification
            conn.request(
                "POST",
                f"/3/device/{device_token}",
                payload_json,
                headers
            )
            
            # Get the response
            response = conn.getresponse()
            response_data = response.read().decode("utf-8")
            
            # Close the connection
            conn.close()
            
            # Check the response
            if response.status == 200:
                logger.info(f"Successfully sent push notification to device {device_token}")
                return {
                    "success": True,
                    "status_code": response.status
                }
            else:
                logger.error(f"Failed to send push notification to device {device_token}: {response.status} {response_data}")
                return {
                    "success": False,
                    "status_code": response.status,
                    "response": response_data
                }
        except Exception as e:
            logger.error(f"Error sending push notification to device {device_token}: {e}", exc_info=True)
            return {
                "success": False,
                "error": str(e)
            }

    async def send_citation_notification(self, wallet_address: str, vector_id: str, citing_wallet_address: str) -> Dict[str, Any]:
        """
        Send a citation notification to a wallet address.
        
        Args:
            wallet_address: The wallet address to send the notification to
            vector_id: The ID of the vector that was cited
            citing_wallet_address: The wallet address of the user who cited the content
            
        Returns:
            Result of the send operation
        """
        try:
            # Get device tokens for the wallet
            device_tokens = await self.get_device_tokens_for_wallet(wallet_address)
            
            if not device_tokens:
                logger.info(f"No device tokens found for wallet {wallet_address}, skipping push notification")
                return {
                    "success": False,
                    "reason": "no_device_tokens",
                    "wallet_address": wallet_address
                }
                
            # Get the vector to include some content in the notification
            vector_info = await self.db.get_vector_by_id(vector_id)
            
            if not vector_info:
                logger.warning(f"Vector {vector_id} not found, using generic notification")
                content_preview = "your content"
            else:
                # Get a preview of the content
                content = vector_info.get("content", "")
                content_preview = content[:50] + "..." if len(content) > 50 else content
                
            # Create the notification title and body
            title = "Your content was cited!"
            body = f"Someone cited your content: \"{content_preview}\""
            
            # Create the notification data
            data = {
                "notification_type": "citation",
                "vector_id": vector_id,
                "citing_wallet_address": citing_wallet_address
            }
            
            # Send the notification to each device
            results = []
            for token in device_tokens:
                result = await self.send_push_notification(token, title, body, data)
                results.append(result)
                
            # Check if any notifications were sent successfully
            success = any(result.get("success", False) for result in results)
            
            if success:
                logger.info(f"Successfully sent citation push notification to wallet {wallet_address}")
                return {
                    "success": True,
                    "device_count": len(device_tokens),
                    "success_count": sum(1 for result in results if result.get("success", False))
                }
            else:
                logger.warning(f"Failed to send citation push notification to any devices for wallet {wallet_address}")
                return {
                    "success": False,
                    "reason": "all_sends_failed",
                    "device_count": len(device_tokens),
                    "results": results
                }
        except Exception as e:
            logger.error(f"Error sending citation push notification to wallet {wallet_address}: {e}", exc_info=True)
            return {
                "success": False,
                "reason": str(e),
                "wallet_address": wallet_address
            }
