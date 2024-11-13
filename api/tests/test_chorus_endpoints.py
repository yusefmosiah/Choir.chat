import httpx
import pytest
import asyncio
from typing import Dict, Any
import time
import json
import sys
from pathlib import Path

# Add parent directory to Python path
sys.path.append(str(Path(__file__).parent.parent))

BASE_URL = "http://localhost:8000/api"

# Helper functions to get responses for each phase
async def get_action_response(client) -> Dict[str, Any]:
    response = await client.post(
        f"{BASE_URL}/chorus/action",
        json={
            "content": "What is the capital of France?",
            "thread_id": None
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    return data["data"]

async def get_experience_response(client, action_data) -> Dict[str, Any]:
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
    return data["data"]

async def get_intention_response(client, action_data, experience_data) -> Dict[str, Any]:
    response = await client.post(
        f"{BASE_URL}/chorus/intention",
        json={
            "content": "What is the capital of France?",
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "priors": experience_data.get("priors", {}),
            "thread_id": None
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    return data["data"]

async def get_observation_response(client, action_data, experience_data, intention_data) -> Dict[str, Any]:
    """Helper function to get observation response"""
    response = await client.post(
        f"{BASE_URL}/chorus/observation",
        json={
            "content": "What is the capital of France?",
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "intention_response": intention_data["content"],
            "selected_priors": intention_data["selected_priors"],
            "priors": experience_data.get("priors", {})
        }
    )
    assert response.status_code == 200, f"Observation request failed: {response.text}"
    data = response.json()
    assert data["success"], f"Observation request unsuccessful: {data.get('message')}"
    return data["data"]

async def get_understanding_response(client, action_data, experience_data, intention_data, observation_data) -> Dict[str, Any]:
    """Helper function to get understanding response"""
    response = await client.post(
        f"{BASE_URL}/chorus/understanding",
        json={
            "content": "What is the capital of France?",
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "intention_response": intention_data["content"],
            "observation_response": observation_data["content"],
            "patterns": [],  # Empty list for patterns since we don't track them separately
            "selected_priors": intention_data["selected_priors"],
            "thread_id": None
        }
    )
    assert response.status_code == 200, f"Understanding request failed: {response.text}"
    data = response.json()
    assert data["success"], f"Understanding request unsuccessful: {data.get('message')}"
    return data["data"]

async def get_yield_response(client, action_data, experience_data, intention_data, observation_data, understanding_data) -> Dict[str, Any]:
    response = await client.post(
        f"{BASE_URL}/chorus/yield",
        json={
            "content": "What is the capital of France?",
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "intention_response": intention_data["content"],
            "observation_response": observation_data["content"],
            "understanding_response": understanding_data["content"],
            "selected_priors": intention_data["selected_priors"],
            "priors": experience_data.get("priors", {}),
            "thread_id": None
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    return data["data"]

# Test methods
async def test_action_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus action endpoint...")
        result = await get_action_response(client)

        assert result["step"].lower() == "action"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["reasoning"], str)

        print(f"✓ Response content: {result['content']}")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Reasoning: {result['reasoning']}")
        return result

async def test_experience_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus experience endpoint...")
        action_data = await get_action_response(client)
        result = await get_experience_response(client, action_data)

        assert result["step"].lower() == "experience"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["reasoning"], str)

        print(f"✓ Experience response: {result['content'][:100]}...")
        print(f"✓ Found {len(result.get('priors', {}))} total priors")
        if result.get('priors'):
            print("Sample of top priors:")
            sorted_priors = sorted(
                [{"id": k, **v} for k, v in result['priors'].items()],
                key=lambda x: x['similarity'],
                reverse=True
            )[:5]
            for i, prior in enumerate(sorted_priors, 1):
                print(f"  {i}. [{prior['similarity']:.3f}] {prior['content'][:100]}...")
        return result

async def test_intention_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus intention endpoint...")
        action_data = await get_action_response(client)
        experience_data = await get_experience_response(client, action_data)
        result = await get_intention_response(client, action_data, experience_data)

        assert result["step"].lower() == "intention"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["selected_priors"], list)
        assert isinstance(result["reasoning"], str)

        print(f"✓ Intention response: {result['content'][:100]}...")
        print(f"✓ Selected {len(result['selected_priors'])} relevant priors")
        if result['selected_priors']:
            print(f"✓ Sample prior IDs: {result['selected_priors'][:3]}")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Reasoning: {result['reasoning'][:100]}...")
        return result

async def test_observation_endpoint():
    """Test the observation endpoint"""
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus observation endpoint...")
        action_data = await get_action_response(client)
        experience_data = await get_experience_response(client, action_data)
        intention_data = await get_intention_response(client, action_data, experience_data)
        result = await get_observation_response(client, action_data, experience_data, intention_data)

        assert result["step"].lower() == "observation"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["reasoning"], str)

        print(f"✓ Observation response: {result['content'][:100]}...")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Reasoning: {result['reasoning'][:100]}...")
        return result

async def test_understanding_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus understanding endpoint...")
        action_data = await get_action_response(client)
        experience_data = await get_experience_response(client, action_data)
        intention_data = await get_intention_response(client, action_data, experience_data)
        observation_data = await get_observation_response(client, action_data, experience_data, intention_data)
        result = await get_understanding_response(client, action_data, experience_data, intention_data, observation_data)

        assert result["step"].lower() == "understanding"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["reasoning"], str)
        assert isinstance(result["should_yield"], bool)
        if not result["should_yield"]:
            assert isinstance(result["next_prompt"], str)

        print(f"✓ Understanding response: {result['content'][:100]}...")
        print(f"✓ Should yield: {result['should_yield']}")
        if not result["should_yield"]:
            print(f"✓ Next prompt: {result['next_prompt']}")
        return result

async def test_yield_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus yield endpoint...")
        action_data = await get_action_response(client)
        experience_data = await get_experience_response(client, action_data)
        intention_data = await get_intention_response(client, action_data, experience_data)
        observation_data = await get_observation_response(client, action_data, experience_data, intention_data)
        understanding_data = await get_understanding_response(client, action_data, experience_data, intention_data, observation_data)
        result = await get_yield_response(client, action_data, experience_data, intention_data, observation_data, understanding_data)

        assert result["step"].lower() == "yield"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["reasoning"], str)

        print(f"✓ Yield response: {result['content'][:100]}...")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Reasoning: {result['reasoning'][:100]}...")
        return result

if __name__ == "__main__":
    asyncio.run(test_action_endpoint())
    asyncio.run(test_experience_endpoint())
    asyncio.run(test_intention_endpoint())
    asyncio.run(test_observation_endpoint())
    asyncio.run(test_understanding_endpoint())
    asyncio.run(test_yield_endpoint())
