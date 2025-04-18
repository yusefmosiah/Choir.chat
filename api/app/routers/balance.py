from fastapi import APIRouter, HTTPException, Depends
from app.services.sui_service import SuiService
from app.services.auth_service import get_current_user
from app.models.auth import TokenData

router = APIRouter()
sui_service = SuiService()

@router.get("/balance/{address}")
async def get_balance(address: str, current_user: TokenData = Depends(get_current_user)):
    balance = sui_service.get_balance(address)
    return balance

@router.post("/mint_choir/{recipient_address}")
async def mint_choir(recipient_address: str, amount: int = 1_000_000_000, current_user: TokenData = Depends(get_current_user)):
    result = await sui_service.mint_choir(recipient_address, amount)
    if result["success"]:
        return {
            "digest": result["digest"],
            "amount": result["amount"],
            "recipient": result["recipient"]
        }
    else:
        raise HTTPException(status_code=500, detail=result["error"])
