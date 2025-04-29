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

        # Get network from environment (default to devnet if not specified)
        self.network = os.getenv("SUI_NETWORK", "devnet")

        try:
            # Initialize config with appropriate RPC and private key based on network
            if self.network == "mainnet":
                rpc_url = "https://fullnode.mainnet.sui.io:443"
            else:
                rpc_url = "https://fullnode.devnet.sui.io:443"

            self.config = SuiConfig.user_config(
                rpc_url=rpc_url,
                prv_keys=[deployer_key]
            )
            self.client = SuiClient(config=self.config)
            self.signer = keypair_from_keystring(deployer_key)

            # Store deployed CHOIR contract info based on network
            logger.info(f"Initializing with contract IDs for {self.network}")
            print(f"Initializing with contract IDs for {self.network}")

            # Set package and treasury cap IDs based on network
            if self.network == "mainnet":
                self.package_id = "0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898"
                self.treasury_cap_id = "0x1ee8226165efd8c2cf965199855b40acb0a86c667d64ea5251a06163feeeaa12"
            else:
                self.package_id = "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a"
                self.treasury_cap_id = "0x6eab9c65acf9b4001199ac98813951140417b5feff8a85218eddd14a62d14f37"

            logger.info(f"Using package_id: {self.package_id}")
            logger.info(f"Using treasury_cap_id: {self.treasury_cap_id}")
            print(f"Using package_id: {self.package_id}")
            print(f"Using treasury_cap_id: {self.treasury_cap_id}")

            # Verify that the contract exists
            try:
                # Get object info for the treasury cap using the correct method signature
                # The pysui library expects the object_id as a positional argument, not a keyword
                logger.info(f"Verifying treasury cap object: {self.treasury_cap_id}")
                print(f"Verifying treasury cap object: {self.treasury_cap_id}")
                treasury_cap_result = self.client.get_object(self.treasury_cap_id)

                if not treasury_cap_result.is_ok():
                    logger.warning(f"Treasury cap object not found: {treasury_cap_result.result_string}")
                    logger.warning("This may indicate that the contract has been redeployed or is not available on this network")
                    print(f"WARNING: Treasury cap object not found: {treasury_cap_result.result_string}")
                    print("This may indicate that the contract has been redeployed or is not available on this network")
                else:
                    logger.info(f"Treasury cap object verified: {self.treasury_cap_id}")
                    print(f"Treasury cap object verified: {self.treasury_cap_id}")

                    # Get more details about the object
                    try:
                        object_details = treasury_cap_result.result_data
                        logger.info(f"Treasury cap object type: {object_details.type if hasattr(object_details, 'type') else 'Unknown'}")
                        logger.info(f"Treasury cap object owner: {object_details.owner if hasattr(object_details, 'owner') else 'Unknown'}")
                        logger.info(f"Treasury cap object status: {object_details.status if hasattr(object_details, 'status') else 'Unknown'}")
                    except Exception as detail_e:
                        logger.warning(f"Error getting treasury cap details: {detail_e}")
            except Exception as e:
                logger.warning(f"Error verifying treasury cap: {e}")
                print(f"Error verifying treasury cap: {e}")
                # We don't raise an exception here as we want to continue initialization

            logger.info("SuiService initialized successfully")
        except Exception as e:
            raise ValueError(f"Failed to initialize SuiService: {e}")

    async def mint_choir(self, recipient_address: str, amount: int = 1_000_000_000):
        """Mint CHOIR tokens to recipient (default 1 CHOIR)"""
        logger.info(f"SUI SERVICE: Minting {amount/1_000_000_000} CHOIR to {recipient_address}")
        print(f"SUI SERVICE: Minting {amount/1_000_000_000} CHOIR to {recipient_address}")

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

            # Add more detailed error logging
            if not result.is_ok():
                logger.error(f"Transaction execution failed with error: {result.result_string}")
                if hasattr(result, 'result_data') and hasattr(result.result_data, 'errors'):
                    logger.error(f"Transaction errors: {result.result_data.errors}")

            # Log the transaction details for debugging
            logger.info(f"Transaction target: {self.package_id}::choir::mint")
            logger.info(f"Transaction treasury_cap_id: {self.treasury_cap_id}")
            logger.info(f"Transaction amount: {amount}")
            logger.info(f"Transaction recipient: {recipient_address}")

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
