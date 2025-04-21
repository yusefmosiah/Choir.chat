import logging
from app.config import Config
from pysui import SuiConfig
from pysui.sui.sui_clients.sync_client import SuiClient
from pysui.sui.sui_types.address import SuiAddress
from pysui.sui.sui_crypto import keypair_from_keystring
from pysui.sui.sui_txn.sync_transaction import SuiTransaction
from pysui.sui.sui_types.scalars import ObjectID, SuiU64
from pysui.sui.sui_builders.get_builders import GetAllCoinBalances
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

config = Config.from_env()

class SuiService:
    def __init__(self):
        # Get deployer key from environment
        deployer_key = os.getenv("SUI_PRIVATE_KEY")
        if not deployer_key:
            raise ValueError("SUI_PRIVATE_KEY environment variable not set")

        try:
            # Initialize config with devnet RPC and private key
            self.config = SuiConfig.user_config(
                rpc_url="https://fullnode.devnet.sui.io:443",
                prv_keys=[deployer_key]
            )
            self.client = SuiClient(config=self.config)
            self.signer = keypair_from_keystring(deployer_key)

            # Store deployed CHOIR contract info
            self.package_id = "0xd3b2e1abf59c4e135015f3f3917ad54424c6d45f16cc069585a905af9815c999"
            self.treasury_cap_id = "0x343a5b3780a05eaf4ea139f786a28cee4120cdc14334d0666c386e014dbe8659"

            logger.info("SuiService initialized successfully")
        except Exception as e:
            raise ValueError(f"Failed to initialize SuiService: {e}")

    async def mint_choir(self, recipient_address: str, amount: int = 1_000_000_000):
        """Mint CHOIR tokens to recipient (default 1 CHOIR)"""
        try:
            # Create transaction
            txn = SuiTransaction(client=self.client)

            # Add move call command with proper argument types
            txn.move_call(
                target=f"{self.package_id}::choir::mint",
                arguments=[
                    ObjectID(self.treasury_cap_id),    # Treasury cap as ObjectID
                    SuiU64(amount),                    # Amount as SuiU64
                    SuiAddress(recipient_address)      # Recipient as SuiAddress
                ],
                type_arguments=[]
            )

            # Execute transaction
            result = txn.execute()

            # Log the full result for debugging
            logger.info(f"Transaction result: {result.result_data}")

            if result.is_ok():
                # Get transaction digest
                tx_digest = result.result_data.digest

                # Check effects directly from result
                effects = result.result_data.effects

                if effects and hasattr(effects, 'status'):
                    if effects.status.status != 'success':
                        error_msg = f"Transaction failed: {effects.status.error}"
                        logger.error(error_msg)
                        return {
                            "success": False,
                            "error": error_msg,
                            "digest": tx_digest
                        }

                logger.info(f"Successfully minted {amount/1_000_000_000} CHOIR to {recipient_address}")
                return {
                    "success": True,
                    "digest": tx_digest,
                    "amount": f"{amount/1_000_000_000} CHOIR",
                    "recipient": recipient_address
                }
            else:
                error_msg = f"Transaction creation failed: {result.result_string}"
                logger.error(error_msg)
                return {
                    "success": False,
                    "error": error_msg
                }

        except Exception as e:
            error_msg = f"Error minting CHOIR: {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg
            }

    def get_balance(self, address: str):
        """Get SUI balance for address"""
        try:
            # Create a builder for getting all coin balances
            builder = GetAllCoinBalances(
                owner=SuiAddress(address)
            )
            # Execute the builder through the client
            result = self.client.execute(builder)

            if result.is_ok():
                balances = result.result_data
                logger.info(f"Balance retrieved for {address}: {balances}")
                return balances
            else:
                logger.error(f"Failed to get balance: {result.result_string}")
                return None
        except Exception as e:
            error_msg = f"Error getting balance: {str(e)}"
            logger.error(error_msg)
            return {"error": error_msg}
