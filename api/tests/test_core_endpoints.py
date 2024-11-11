import httpx
import pytest
import asyncio
from typing import List

BASE_URL = "http://localhost:8000/api"

async def test_endpoints():
    async with httpx.AsyncClient() as client:
        # Test embedding generation
        print("\nTesting embedding generation...")
        embed_response = await client.post(
            f"{BASE_URL}/embeddings/generate",
            json={"content": "Test message for embedding"}
        )
        assert embed_response.status_code == 200
        embedding_data = embed_response.json()
        assert embedding_data["success"]
        embedding = embedding_data["data"]["embedding"]
        assert isinstance(embedding, list)
        assert len(embedding) == 1536  # Standard embedding size
        print(f"✓ Embedding generated successfully: {embedding[:5]}")

        # Test vector storage
        print("\nTesting vector storage...")
        store_response = await client.post(
            f"{BASE_URL}/vectors/store",
            json={
                "content": "Test message for storage",
                "vector": embedding,
                "metadata": {"test": True}
            }
        )
        assert store_response.status_code == 200
        assert store_response.json()["success"]
        print("✓ Vector stored successfully")

        # Test vector search
        print("\nTesting vector search...")
        search_response = await client.post(
            f"{BASE_URL}/vectors/search",
            json={
                "query_vector": embedding,
                "limit": 5
            }
        )
        assert search_response.status_code == 200
        search_data = search_response.json()
        assert search_data["success"]
        results = search_data["data"]["results"]
        assert isinstance(results, list)
        print(f"✓ Search returned {len(results)} results")

if __name__ == "__main__":
    asyncio.run(test_endpoints())
