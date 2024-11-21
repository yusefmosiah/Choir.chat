from fastapi import APIRouter, HTTPException
from app.services.sui_service import SuiService
from app.services.wallet_manager import WalletManager

router = APIRouter()
sui_service = SuiService()
wallet_manager = WalletManager()

@router.get("/balance/{address}")
async def get_balance(address: str):
    balance = sui_service.get_balance(address)
    return balance

@router.post("/mint_choir/{address}")
async def mint_choir(address: str):
    """Mint 1 CHOIR token to the specified address"""

    # Validate address format
    if not wallet_manager.validate_address(address):
        raise HTTPException(status_code=400, detail="Invalid SUI address format")

    # Mint 1 CHOIR (1 with 9 decimal places)
    result = await sui_service.mint_choir(address)

    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])

    return {
        "success": True,
        "transaction": result["digest"],
        "address": address,
        "amount": "1 CHOIR"
    }
