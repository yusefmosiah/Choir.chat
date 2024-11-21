from app.services.sui_service import SuiService
import pytest
import os

@pytest.fixture
def sui_service():
    # Ensure test environment has required env vars
    if not os.getenv("SUI_PRIVATE_KEY"):
        pytest.skip("SUI_PRIVATE_KEY not set")
    return SuiService()

@pytest.mark.asyncio
async def test_mint_choir_success(sui_service):
    test_address = "0x1627415da5090894ad13c6971feb691204e4bdcd7ba874932f08800b7b1257a5"
    result = await sui_service.mint_choir(test_address)

    assert result["success"] is True
    assert "digest" in result
    assert result["amount"] == "1.0 CHOIR"
    assert result["recipient"] == test_address

@pytest.mark.asyncio
async def test_mint_choir_invalid_address(sui_service):
    result = await sui_service.mint_choir("invalid_address")
    assert result["success"] is False
    assert "error" in result

@pytest.mark.asyncio
async def test_get_balance_success(sui_service):
    test_address = "0x1627415da5090894ad13c6971feb691204e4bdcd7ba874932f08800b7b1257a5"
    result = sui_service.get_balance(test_address)
    assert result is not None

@pytest.mark.asyncio
async def test_get_balance_invalid_address(sui_service):
    result = sui_service.get_balance("invalid_address")
    assert "error" in result
