#!/usr/bin/env python
"""
Run the tool tests directly.
"""
import os
import sys
import argparse
import asyncio

# Add the parent directory to sys.path to enable importing from app
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
sys.path.insert(0, parent_dir)

from app.config import Config
from tests.tools.test_multimodel_with_tools import MultiModelToolsTester


async def run_calculator_tests(num_conversations: int = 2):
    """Run calculator tool tests."""
    config = Config()
    tester = MultiModelToolsTester(config)

    await tester.run_multiple_conversations(num_conversations=num_conversations)
    tester.print_summary()

    return tester.results


if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Run tool tests")
    parser.add_argument(
        "--num-conversations",
        type=int,
        default=2,
        help="Number of conversations to run"
    )
    args = parser.parse_args()

    # Run tests
    asyncio.run(run_calculator_tests(num_conversations=args.num_conversations))
