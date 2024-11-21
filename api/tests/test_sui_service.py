from app.services.sui_service import SuiService
from app.services.wallet_manager import WalletManager
import pytest

@pytest.fixture
def sui_service():
    return SuiService()

@pytest.fixture
def wallet_manager():
    return WalletManager()

def test_validate_address(wallet_manager):
    # Valid address
    assert wallet_manager.validate_address(
        "0xe9e9eba13e6868cbb3ab97b5615b2f09459fd6bbac500a251265165febc3073d"
    )

    # Invalid addresses
    assert not wallet_manager.validate_address("not-an-address")
    assert not wallet_manager.validate_address("0x123")  # Too short

@pytest.mark.asyncio
async def test_mint_choir(sui_service):
    result = await sui_service.mint_choir(
        "0xe9e9eba13e6868cbb3ab97b5615b2f09459fd6bbac500a251265165febc3073d"
    )
    assert result["success"]
    assert "digest" in result
