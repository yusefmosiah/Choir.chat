from fastapi import APIRouter
from app.services.sui_service import SuiService

router = APIRouter()
sui_service = SuiService()

@router.get("/balance/{address}")
async def get_balance(address: str):
    balance = sui_service.get_balance(address)
    return balance
