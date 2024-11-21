from pysui.sui.sui_clients.sync_client import SuiClient
from pysui.sui.sui_builders.get_builders import GetBalance
from pysui.sui.sui_txresults.common import GenericRef

class SuiService:
    def __init__(self):
        # Initialize the client (use 'testnet' or 'mainnet' as needed)
        self.client = SuiClient(network="testnet")

    def get_balance(self, address: str):
        result = self.client.execute(GetBalance(owner=address))
        if result.is_ok():
            return result.result_data
        else:
            # Handle error
            return {"error": result.result_string}

    def transfer_sui(self, signer_keypair, recipient_address: str, amount: int):
        tx_result = self.client.transfer_sui(
            signer=signer_keypair,
            recipient=recipient_address,
            amount=amount
        )
        if tx_result.is_ok():
            return tx_result.result_data
        else:
            # Handle error
            return {"error": tx_result.result_string}
