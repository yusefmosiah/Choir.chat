import pytest
import httpx
from typing import Dict, Any

pytestmark = pytest.mark.integration

# Helper functions to get responses for each phase
async def get_action_response(client, base_url, test_input) -> Dict[str, Any]:
    response = await client.post(
        f"{base_url}/chorus/action",
        json=test_input
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    result = data["data"]
    # Ensure the response has the required fields from ChorusResponse
    assert "step" in result
    assert "content" in result
    assert "confidence" in result
    assert "reasoning" in result
    return result

async def get_experience_response(client, base_url, action_data) -> Dict[str, Any]:
    response = await client.post(
        f"{base_url}/chorus/experience",
        json={
            "content": action_data["content"],
            "action_response": action_data["content"],
            "thread_id": action_data.get("thread_id")
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    result = data["data"]
    # Ensure the response has the required fields from ChorusResponse
    assert "step" in result
    assert "content" in result
    assert "confidence" in result
    assert "reasoning" in result
    return result

async def get_intention_response(client, base_url, action_data, experience_data) -> Dict[str, Any]:
    response = await client.post(
        f"{base_url}/chorus/intention",
        json={
            "content": action_data["content"],
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "priors": {},
            "thread_id": action_data.get("thread_id")
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    result = data["data"]
    # Ensure the response has the required fields from ChorusResponse
    assert "step" in result
    assert "content" in result
    assert "confidence" in result
    assert "reasoning" in result
    return result

async def get_observation_response(client, base_url, action_data, experience_data, intention_data) -> Dict[str, Any]:
    """Helper function to get observation response"""
    response = await client.post(
        f"{base_url}/chorus/observation",
        json={
            "content": action_data["content"],
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "intention_response": intention_data["content"],
            "selected_priors": intention_data.get("selected_priors", []),
            "priors": {},
            "thread_id": action_data.get("thread_id")
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    result = data["data"]
    # Ensure the response has the required fields from ChorusResponse
    assert "step" in result
    assert "content" in result
    assert "confidence" in result
    assert "reasoning" in result
    return result

async def get_understanding_response(client, base_url, action_data, experience_data, intention_data, observation_data) -> Dict[str, Any]:
    """Helper function to get understanding response"""
    response = await client.post(
        f"{base_url}/chorus/understanding",
        json={
            "content": action_data["content"],
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "intention_response": intention_data["content"],
            "observation_response": observation_data["content"],
            "patterns": [],  # Empty list for patterns since we don't track them separately
            "selected_priors": intention_data.get("selected_priors", []),
            "thread_id": None
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    result = data["data"]
    # Ensure the response has the required fields from ChorusResponse
    assert "step" in result
    assert "content" in result
    assert "confidence" in result
    assert "reasoning" in result
    return result

async def get_yield_response(client, base_url, action_data, experience_data, intention_data, observation_data, understanding_data) -> Dict[str, Any]:
    """Helper function to get yield response"""
    response = await client.post(
        f"{base_url}/chorus/yield",
        json={
            "content": action_data["content"],
            "action_response": action_data["content"],
            "experience_response": experience_data["content"],
            "intention_response": intention_data["content"],
            "observation_response": observation_data["content"],
            "understanding_response": understanding_data["content"],
            "selected_priors": intention_data.get("selected_priors", []),
            "priors": {},
            "thread_id": None
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"]
    result = data["data"]
    # Ensure the response has the required fields from ChorusResponse
    assert "step" in result
    assert "content" in result
    assert "confidence" in result
    assert "reasoning" in result
    return result

@pytest.fixture
async def client():
    async with httpx.AsyncClient(timeout=30.0) as client:
        yield client

@pytest.fixture
def base_url():
    return "http://localhost:8000/api"

@pytest.fixture
def test_input():
    return {
        "content": "What is the capital of France?",
        "thread_id": None
    }

@pytest.mark.asyncio
async def test_action_endpoint(client, base_url, test_input):
    """Test the action endpoint."""
    data = await get_action_response(client, base_url, test_input)
    assert "step" in data
    assert "content" in data
    assert "confidence" in data
    assert "reasoning" in data

@pytest.mark.asyncio
async def test_experience_endpoint(client, base_url, test_input):
    """Test the experience endpoint."""
    action_data = await get_action_response(client, base_url, test_input)
    data = await get_experience_response(client, base_url, action_data)
    assert "step" in data
    assert "content" in data
    assert "confidence" in data
    assert "reasoning" in data

@pytest.mark.asyncio
async def test_intention_endpoint(client, base_url, test_input):
    """Test the intention endpoint."""
    action_data = await get_action_response(client, base_url, test_input)
    experience_data = await get_experience_response(client, base_url, action_data)
    data = await get_intention_response(client, base_url, action_data, experience_data)
    assert "step" in data
    assert "content" in data
    assert "confidence" in data
    assert "reasoning" in data

@pytest.mark.asyncio
async def test_full_chorus_cycle(client, base_url, test_input):
    """Test the complete chorus cycle."""
    # Action phase
    action_data = await get_action_response(client, base_url, test_input)
    assert "step" in action_data
    assert "content" in action_data
    assert "confidence" in action_data
    assert "reasoning" in action_data
    
    # Experience phase
    experience_data = await get_experience_response(client, base_url, action_data)
    assert "step" in experience_data
    assert "content" in experience_data
    assert "confidence" in experience_data
    assert "reasoning" in experience_data
    
    # Intention phase
    intention_data = await get_intention_response(client, base_url, action_data, experience_data)
    assert "step" in intention_data
    assert "content" in intention_data
    assert "confidence" in intention_data
    assert "reasoning" in intention_data
    
    # Observation phase
    observation_data = await get_observation_response(client, base_url, action_data, experience_data, intention_data)
    assert "step" in observation_data
    assert "content" in observation_data
    assert "confidence" in observation_data
    assert "reasoning" in observation_data
    
    # Understanding phase
    understanding_data = await get_understanding_response(client, base_url, action_data, experience_data, intention_data, observation_data)
    assert "step" in understanding_data
    assert "content" in understanding_data
    assert "confidence" in understanding_data
    assert "reasoning" in understanding_data
    
    # Yield phase
    yield_data = await get_yield_response(client, base_url, action_data, experience_data, intention_data, observation_data, understanding_data)
    assert "step" in yield_data
    assert "content" in yield_data
    assert "confidence" in yield_data
    assert "reasoning" in yield_data
