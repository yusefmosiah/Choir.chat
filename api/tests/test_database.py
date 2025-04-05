import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch, MagicMock

from app.database import DatabaseClient
from app.config import Config

@pytest_asyncio.fixture
async def db_client():
    config = Config()
    client = DatabaseClient(config)
    # Patch the underlying QdrantClient inside DatabaseClient
    client.qdrant = MagicMock()
    return client

@pytest.mark.asyncio
async def test_save_message_calls_upsert(db_client):
    # Arrange
    db_client.qdrant.upsert = AsyncMock(return_value={"result": "ok"})
    message_data = {
        "thread_id": "thread123",
        "role": "user",
        "content": "Hello world",
        "timestamp": "2024-01-01T00:00:00Z",
        "vector": [0.1] * 1536
    }

    # Act
    result = await db_client.save_message(message_data)

    # Assert
    db_client.qdrant.upsert.assert_called_once()
    assert result == {"status": "success"}

@pytest.mark.asyncio
async def test_get_message_history_calls_search(db_client):
    # Arrange
    mock_result = [
        {
            "payload": {
                "thread_id": "thread123",
                "role": "user",
                "content": "Hello world",
                "timestamp": "2024-01-01T00:00:00Z"
            },
            "score": 1.0
        }
    ]
    db_client.qdrant.scroll = AsyncMock(return_value=({"points": mock_result}, None))

    # Act
    messages = await db_client.get_message_history("thread123")

    # Assert
    db_client.qdrant.scroll.assert_called_once()
    assert isinstance(messages, list)
    assert messages[0]["content"] == "Hello world"
