from app.services.sui_service import SuiService
import pytest
import os
import logging

# Configure logging for tests
logging.basicConfig(level=logging.INFO)

@pytest.fixture
def sui_service():
    # Ensure test environment has required env vars
    if not os.getenv("SUI_PRIVATE_KEY"):
        pytest.skip("SUI_PRIVATE_KEY not set")
    return SuiService()

@pytest.mark.asyncio
async def test_mint_choir_success(sui_service):
    # Use the specified test address
    test_address = "0x0688dd8b5acd4ed64696876676cae1d1cc8ab8cef926074a7e7ccc3956c670f9"
    # Mint 1 CHOIR token (1_000_000_000 units with 9 decimals)
    result = await sui_service.mint_choir(test_address, 1_000_000_000)

    # Log the result for debugging
    logging.info(f"Mint result: {result}")

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
    # Use the specified test address
    test_address = "0x0688dd8b5acd4ed64696876676cae1d1cc8ab8cef926074a7e7ccc3956c670f9"
    result = sui_service.get_balance(test_address)

    # Log the result for debugging
    logging.info(f"Balance result: {result}")

    assert result is not None

@pytest.mark.asyncio
async def test_get_balance_invalid_address(sui_service):
    result = sui_service.get_balance("invalid_address")
    assert "error" in result

@pytest.mark.asyncio
async def test_mint_choir_with_custom_amount(sui_service):
    # Use the specified test address
    test_address = "0x0688dd8b5acd4ed64696876676cae1d1cc8ab8cef926074a7e7ccc3956c670f9"
    # Mint 0.5 CHOIR tokens (500_000_000 units with 9 decimals)
    amount = 500_000_000
    result = await sui_service.mint_choir(test_address, amount)

    # Log the result for debugging
    logging.info(f"Custom mint result: {result}")

    assert result["success"] is True
    assert "digest" in result
    assert result["amount"] == f"{amount/1_000_000_000} CHOIR"
    assert result["recipient"] == test_address
