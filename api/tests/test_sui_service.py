from app.services.sui_service import SuiService

def test_get_balance():
    sui_service = SuiService()
    address = "0x..."
    balance = sui_service.get_balance(address)
    assert "error" not in balance

def test_transfer_sui():
    sui_service = SuiService()
    # Use test keypairs and addresses
    signer_keypair = ...
    recipient_address = "0x..."
    result = sui_service.transfer_sui(signer_keypair, recipient_address, 100)
    assert "error" not in result
