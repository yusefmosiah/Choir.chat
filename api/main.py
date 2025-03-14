from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import  threads, users, balance, postchain
from app.config import Config

app = FastAPI(title="Choir API", version="1.0.0")

config = Config.from_env()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers

app.include_router(threads.router, prefix="/api/threads", tags=["threads"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(balance.router, prefix="/api/balance", tags=["balance"])
app.include_router(postchain.router, prefix="/api/postchain", tags=["postchain"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
