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

@router.post("/mint_choir/{recipient_address}")
async def mint_choir(recipient_address: str, amount: int = 1_000_000_000):
    result = await sui_service.mint_choir(recipient_address, amount)
    if result["success"]:
        return {
            "digest": result["digest"],
            "amount": result["amount"],
            "recipient": result["recipient"]
        }
    else:
        raise HTTPException(status_code=500, detail=result["error"])
