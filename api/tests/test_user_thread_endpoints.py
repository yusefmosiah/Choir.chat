import httpx
import pytest
import asyncio
from typing import List, Dict, Any

BASE_URL = "http://localhost:8000/api"

async def test_user_thread_flow():
    async with httpx.AsyncClient() as client:
        # 1. Create a user
        print("\nTesting user creation...")
        user_response = await client.post(
            f"{BASE_URL}/users",
            json={"public_key": "test_public_key_123"}
        )
        assert user_response.status_code == 200
        user_data = user_response.json()
        assert user_data["success"]
        user_id = user_data["data"]["user"]["id"]
        print(f"✓ User created with ID: {user_id}")

        # 2. Get user details
        print("\nTesting user retrieval...")
        get_user_response = await client.get(f"{BASE_URL}/users/{user_id}")
        assert get_user_response.status_code == 200
        assert get_user_response.json()["success"]
        print("✓ User retrieved successfully")

        # 3. Create a thread
        print("\nTesting thread creation...")
        thread_response = await client.post(
            f"{BASE_URL}/threads",
            json={
                "name": "Test Thread",
                "user_id": user_id,
                "initial_message": "Hello, this is a test thread"
            }
        )
        assert thread_response.status_code == 200
        thread_data = thread_response.json()
        assert thread_data["success"]
        thread_id = thread_data["data"]["thread"]["id"]
        print(f"✓ Thread created with ID: {thread_id}")

        # 4. Get thread details
        print("\nTesting thread retrieval...")
        get_thread_response = await client.get(f"{BASE_URL}/threads/{thread_id}")
        assert get_thread_response.status_code == 200
        assert get_thread_response.json()["success"]
        print("✓ Thread retrieved successfully")

        # 5. Get thread messages
        print("\nTesting thread messages retrieval...")
        messages_response = await client.get(f"{BASE_URL}/threads/{thread_id}/messages")
        assert messages_response.status_code == 200
        messages_data = messages_response.json()
        assert messages_data["success"]
        print(f"✓ Retrieved {len(messages_data['data']['messages'])} messages")

        # 6. Get user's threads
        print("\nTesting user's threads retrieval...")
        user_threads_response = await client.get(f"{BASE_URL}/users/{user_id}/threads")
        assert user_threads_response.status_code == 200
        user_threads_data = user_threads_response.json()
        assert user_threads_data["success"]
        threads = user_threads_data["data"]["threads"]
        assert len(threads) > 0
        print(f"✓ Retrieved {len(threads)} threads for user")

if __name__ == "__main__":
    asyncio.run(test_user_thread_flow())
