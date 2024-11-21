from pysui import SuiConfig
from pysui.sui.sui_crypto import SuiKeyPair
from pysui.sui.sui_types.address import SuiAddress

class WalletManager:
    def __init__(self):
        self.config = SuiConfig.default_config()

    def validate_address(self, address: str) -> bool:
        """Validate a SUI address format"""
        try:
            SuiAddress(address)
            return True
        except:
            return False

    def create_wallet(self):
        # Generate a new keypair
        keypair = SUIKeyPair.create_new()
        # Save the keypair securely (e.g., encrypt and store in database)
        # For example purposes, we return the address and keypair
        return {
            "address": keypair.address,
            "private_key": keypair.serialize()
        }

    def load_wallet(self, serialized_keypair: str):
        # Load the keypair from serialized data
        keypair = SUIKeyPair.from_b64(serialized_keypair)
        return keypair
