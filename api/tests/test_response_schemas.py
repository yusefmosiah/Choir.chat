import httpx
import asyncio
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000/api/chorus"

def print_schema(phase: str, data: Dict[str, Any]):
    print(f"\n{phase.upper()} RESPONSE SCHEMA:")
    print(json.dumps(data, indent=2))

async def test_response_schemas():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nTesting response schemas for all phases...")

        # Action phase
        print("\nCalling action phase...")
        action_response = await client.post(
            f"{BASE_URL}/action",
            json={
                "content": "What is Choir?",
                "thread_id": None
            }
        )

        assert action_response.status_code == 200, f"Action request failed: {action_response.text}"
        action_json = action_response.json()
        assert action_json["success"], f"Action request unsuccessful: {action_json.get('message')}"
        action_data = action_json["data"]
        assert action_data is not None, "Action data is None"
        print_schema("action", action_data)

        # Experience phase
        print("\nCalling experience phase...")
        experience_response = await client.post(
            f"{BASE_URL}/experience",
            json={
                "content": "What is Choir?",
                "action_response": action_data["content"],
                "thread_id": None
            }
        )
        assert experience_response.status_code == 200
        experience_data = experience_response.json()["data"]
        print_schema("experience", experience_data)

        # Intention phase
        print("\nCalling intention phase...")
        intention_response = await client.post(
            f"{BASE_URL}/intention",
            json={
                "content": "What is Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "priors": experience_data["priors"],
                "thread_id": None
            }
        )
        assert intention_response.status_code == 200
        intention_data = intention_response.json()["data"]
        print_schema("intention", intention_data)

        # Observation phase
        print("\nCalling observation phase...")
        observation_response = await client.post(
            f"{BASE_URL}/observation",
            json={
                "content": "What is Choir?",
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
        print_schema("observation", observation_data)

        # Understanding phase
        print("\nCalling understanding phase...")
        understanding_response = await client.post(
            f"{BASE_URL}/understanding",
            json={
                "content": "What is Choir?",
                "action_response": action_data["content"],
                "experience_response": experience_data["content"],
                "intention_response": intention_data["content"],
                "observation_response": observation_data["content"],
                "patterns": [],  # Removed patterns field
                "selected_priors": intention_data["selected_priors"],
                "thread_id": None
            }
        )
        assert understanding_response.status_code == 200
        understanding_data = understanding_response.json()["data"]
        print_schema("understanding", understanding_data)

        # Yield phase
        print("\nCalling yield phase...")
        yield_response = await client.post(
            f"{BASE_URL}/yield",
            json={
                "content": "What is Choir?",
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
        assert yield_response.status_code == 200
        yield_data = yield_response.json()["data"]
        print_schema("yield", yield_data)

if __name__ == "__main__":
    asyncio.run(test_response_schemas())
