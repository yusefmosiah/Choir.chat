import httpx
import pytest
import asyncio
from typing import Dict, Any

BASE_URL = "http://localhost:8000/api"

async def test_action_endpoint():
    async with httpx.AsyncClient() as client:
        print("\nTesting chorus action endpoint...")

        # Test with a simple question
        response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "What is the capital of France?",
                "thread_id": None  # Optional for now
            }
        )

        assert response.status_code == 200, f"Failed with status {response.status_code}: {response.text}"
        data = response.json()
        assert data["success"], f"Request failed: {data.get('message')}"

        result = data["data"]
        assert result["step"] == "action"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert "reasoning" in result["metadata"]

        print(f"✓ Response content: {result['content'][:100]}...")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Reasoning: {result['metadata']['reasoning'][:100]}...")

        # Test with a more complex prompt
        response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "Explain the concept of quantum entanglement in simple terms.",
                "thread_id": None
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"]

        result = data["data"]
        print(f"\n✓ Complex prompt response: {result['content'][:100]}...")
        print(f"✓ Confidence: {result['confidence']}")

async def test_experience_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:  # 30 second timeout
        print("\nTesting chorus experience endpoint...")

        # First get an action response
        action_response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "What is the capital of France?",
                "thread_id": None
            }
        )
        assert action_response.status_code == 200
        action_data = action_response.json()["data"]

        # Then test experience with the action response
        response = await client.post(
            f"{BASE_URL}/chorus/experience",
            json={
                "content": "What is the capital of France?",
                "action_response": action_data["content"],
                "thread_id": None
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"]

        result = data["data"]
        assert result["step"] == "experience"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["priors"], dict)  # Now expecting a dictionary
        assert "synthesis" in result["metadata"]

        print(f"✓ Experience response: {result['content'][:100]}...")
        print(f"✓ Found {len(result['priors'])} total priors")
        print("Sample of top priors:")
        # Sort priors by similarity and take top 5
        sorted_priors = sorted(
            [{"id": k, **v} for k, v in result["priors"].items()],
            key=lambda x: x['similarity'],
            reverse=True
        )[:5]
        for i, prior in enumerate(sorted_priors, 1):
            print(f"  {i}. [{prior['similarity']:.3f}] {prior['content'][:100]}...")
        print(f"✓ Synthesis: {result['metadata']['synthesis'][:100]}...")

if __name__ == "__main__":
    asyncio.run(test_action_endpoint())
    asyncio.run(test_experience_endpoint())
