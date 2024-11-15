import os
import sys
import pytest
import httpx
import asyncio
from pathlib import Path

# Add the project root directory to Python path
project_root = str(Path(__file__).parent.parent)
sys.path.append(project_root)

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

# Constants
BASE_URL = "http://localhost:8000/api"

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def client():
    """Create a shared httpx client for the test session."""
    async with httpx.AsyncClient() as client:
        yield client

@pytest.fixture(scope="session")
def base_url():
    """Provide the base URL for API endpoints."""
    return BASE_URL

@pytest.fixture(scope="session")
def test_input():
    """Provide test input data."""
    return {
        "content": "What is the capital of France?",
        "thread_id": None
    }
