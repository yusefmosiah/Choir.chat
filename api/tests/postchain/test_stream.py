"""
Test script for debugging streaming functionality of the PostChain.
"""
import asyncio
import json
import sys
import logging
from datetime import datetime

from app.config import Config
from app.postchain.simple_graph import stream_simple_postchain

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("test_stream")

async def test_streaming():
    """Test the streaming functionality of the PostChain."""
    config = Config()
    user_query = "Explain the concept of quantum entanglement"

    logger.info(f"Starting stream test with query: {user_query}")

    # Stream the response and print each chunk as it arrives
    print(f"--- Stream Output {datetime.now().isoformat()} ---")
    print("Request: " + user_query)
    print("-" * 50)

    event_count = 0
    try:
        async for chunk in stream_simple_postchain(user_query, config):
            event_count += 1
            print(f"Event {event_count}: {json.dumps(chunk, indent=2)}")
            print("-" * 30)
            # Force flush to see output immediately
            sys.stdout.flush()
    except Exception as e:
        print(f"Error during streaming: {str(e)}")

    print(f"Total events received: {event_count}")
    print(f"--- End Stream {datetime.now().isoformat()} ---")

if __name__ == "__main__":
    # Run the test directly
    asyncio.run(test_streaming())
