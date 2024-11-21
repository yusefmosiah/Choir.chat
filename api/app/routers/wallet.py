from fastapi import APIRouter
from app.services.wallet_manager import WalletManager

router = APIRouter()
wallet_manager = WalletManager()

@router.post("/wallet/create")
async def create_wallet():
    wallet = wallet_manager.create_wallet()
    return wallet

@router.post("/wallet/load")
async def load_wallet(serialized_keypair: str):
    keypair = wallet_manager.load_wallet(serialized_keypair)
    return {"address": keypair.address}
