import httpx
import pytest
import asyncio
from typing import Dict, Any
import time
import json

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
        print(f" Synthesis: {result['metadata']['synthesis'][:100]}...")

async def test_intention_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus intention endpoint...")

        # First get action response
        action_response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "What is the purpose of Choir?",
                "thread_id": None
            }
        )
        assert action_response.status_code == 200
        action_data = action_response.json()["data"]

        # Then get experience response
        experience_response = await client.post(
            f"{BASE_URL}/chorus/experience",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "thread_id": None
            }
        )
        assert experience_response.status_code == 200
        experience_data = experience_response.json()["data"]

        # Finally test intention
        response = await client.post(
            f"{BASE_URL}/chorus/intention",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"]

        result = data["data"]
        assert result["step"] == "intention"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["selected_priors"], list)
        assert "reasoning" in result["metadata"]

        print(f"✓ Intention response: {result['content'][:100]}...")
        print(f"✓ Selected {len(result['selected_priors'])} relevant priors")
        print(f"✓ Prior sample: {result['selected_priors'][:5]}")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Reasoning: {result['metadata']['reasoning'][:100]}...")

async def test_observation_endpoint():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting chorus observation endpoint...")

        # First get action response
        action_response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "What is the purpose of Choir?",
                "thread_id": None
            }
        )
        assert action_response.status_code == 200
        action_data = action_response.json()["data"]

        # Then get experience response
        experience_response = await client.post(
            f"{BASE_URL}/chorus/experience",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "thread_id": None
            }
        )
        assert experience_response.status_code == 200
        experience_data = experience_response.json()["data"]

        # Get intention response
        intention_response = await client.post(
            f"{BASE_URL}/chorus/intention",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )
        assert intention_response.status_code == 200
        intention_data = intention_response.json()["data"]

        # Finally test observation
        response = await client.post(
            f"{BASE_URL}/chorus/observation",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "selected_priors": intention_data["selected_priors"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"]

        result = data["data"]
        assert result["step"] == "observation"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["patterns"], list)
        assert "reasoning" in result["metadata"]

        print(f"✓ Observation response: {result['content'][:100]}...")
        print(f"✓ Found {len(result['patterns'])} patterns")
        print("Sample of patterns:")
        for i, pattern in enumerate(result["patterns"][:3], 1):
            print(f"  {i}. [{pattern['type']}] {pattern['description'][:100]}...")
        print(f"✓ Reasoning: {result['metadata']['reasoning'][:100]}...")

        # Get the observation ID from the response
        observation_id = response.json()["data"].get("id")
        assert observation_id, "No observation ID returned"

        # Add delay to allow for indexing
        time.sleep(1)  # 1 second delay

        # Get the observation using the API
        get_response = await client.get(f"{BASE_URL}/vectors/{observation_id}")
        assert get_response.status_code == 200, "Failed to retrieve observation"
        observation_data = get_response.json()["data"]

        # Verify the observation
        assert observation_data["metadata"]["type"] == "observation"
        assert "purpose of Choir" in observation_data["content"]
        print("✓ Found stored observation in database")
        print(f"  Content: {observation_data['content'][:100]}...")
        print(f"  Patterns: {len(observation_data['metadata']['patterns'])} patterns stored")
        print(f"  Selected priors: {len(observation_data['metadata']['selected_priors'])} priors referenced")

async def test_understanding_endpoint():
    async with httpx.AsyncClient(timeout=120.0) as client:
        print("\nTesting chorus understanding endpoint...")

        # First get action response
        action_response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "Tell me a story",  # Using creative prompt to test looping
                "thread_id": None
            }
        )
        assert action_response.status_code == 200
        action_data = action_response.json()["data"]

        # Then get experience response
        experience_response = await client.post(
            f"{BASE_URL}/chorus/experience",
            json={
                "content": "Tell me a story",
                "action_response": action_data["content"],
                "thread_id": None
            }
        )
        assert experience_response.status_code == 200
        experience_data = experience_response.json()["data"]

        # Get intention response
        intention_response = await client.post(
            f"{BASE_URL}/chorus/intention",
            json={
                "content": "Tell me a story",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )
        assert intention_response.status_code == 200
        intention_data = intention_response.json()["data"]

        # Get observation response
        observation_response = await client.post(
            f"{BASE_URL}/chorus/observation",
            json={
                "content": "Tell me a story",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "selected_priors": intention_data["selected_priors"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )
        assert observation_response.status_code == 200
        observation_data = observation_response.json()["data"]

        # Finally test understanding
        response = await client.post(
            f"{BASE_URL}/chorus/understanding",
            json={
                "content": "Tell me a story",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "observation_response": observation_data["content"],
                "patterns": observation_data["patterns"],
                "selected_priors": intention_data["selected_priors"],
                "thread_id": None
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"]

        result = data["data"]
        assert result["step"] == "understanding"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["should_yield"], bool)
        assert "next_action" in result["metadata"]

        print(f"✓ Understanding response: {result['content'][:100]}...")
        print(f"✓ Confidence: {result['confidence']}")
        print(f"✓ Should yield: {result['should_yield']}")
        if not result["should_yield"]:
            print(f"✓ Next action: {result['metadata']['next_action']}")
            print(f"✓ Next prompt: {result['metadata']['next_prompt']}")

async def test_yield_endpoint():
    async with httpx.AsyncClient(timeout=120.0) as client:
        print("\nTesting chorus yield endpoint...")

        print("✓ Getting action response...")
        action_response = await client.post(
            f"{BASE_URL}/chorus/action",
            json={
                "content": "What is the purpose of Choir?",
                "thread_id": None
            }
        )
        assert action_response.status_code == 200
        action_data = action_response.json()["data"]

        print("✓ Getting experience response...")
        experience_response = await client.post(
            f"{BASE_URL}/chorus/experience",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "thread_id": None
            }
        )
        assert experience_response.status_code == 200
        experience_data = experience_response.json()["data"]

        print("✓ Getting intention response...")
        intention_response = await client.post(
            f"{BASE_URL}/chorus/intention",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )
        assert intention_response.status_code == 200
        intention_data = intention_response.json()["data"]

        print("✓ Getting observation response...")
        observation_response = await client.post(
            f"{BASE_URL}/chorus/observation",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "selected_priors": intention_data["selected_priors"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )
        assert observation_response.status_code == 200
        observation_data = observation_response.json()["data"]

        print("✓ Getting understanding response...")
        understanding_response = await client.post(
            f"{BASE_URL}/chorus/understanding",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "observation_response": observation_data["content"],
                "patterns": observation_data["patterns"],
                "selected_priors": intention_data["selected_priors"],
                "thread_id": None
            }
        )
        assert understanding_response.status_code == 200
        understanding_data = understanding_response.json()["data"]

        print("✓ Testing yield response...")
        response = await client.post(
            f"{BASE_URL}/chorus/yield",
            json={
                "content": "What is the purpose of Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "observation_response": observation_data["content"],
                "understanding_response": understanding_data["content"],
                "selected_priors": intention_data["selected_priors"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"]

        result = data["data"]
        assert result["step"] == "yield"
        assert isinstance(result["content"], str)
        assert isinstance(result["confidence"], float)
        assert isinstance(result["citations"], list)
        assert "reasoning" in result["metadata"]

        print("\n✓ Yield Response:")
        print(json.dumps(result, indent=2))
        print(f"\n✓ Number of citations: {len(result['citations'])}")
        print("\nSample citations:")
        for i, citation in enumerate(result["citations"][:3], 1):
            print(f"\n{i}. Prior: {citation['prior_id']}")
            print(f"   Content: {citation['content'][:100]}...")
            print(f"   Context: {citation['context'][:100]}...")

if __name__ == "__main__":
    asyncio.run(test_action_endpoint())
    asyncio.run(test_experience_endpoint())
    asyncio.run(test_intention_endpoint())
    asyncio.run(test_observation_endpoint())
    asyncio.run(test_understanding_endpoint())
    asyncio.run(test_yield_endpoint())
