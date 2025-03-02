#!/usr/bin/env python3
import asyncio
import argparse
import json
import logging
from pathlib import Path
from test_framework import PostChainTester
from api.app.chorus_graph import create_chorus_graph

async def run_test_suite(test_cases_file, output_dir=None):
    """Run a suite of tests defined in a JSON file"""

    # Configure logging
    logging.basicConfig(level=logging.INFO)

    # Load test cases
    with open(test_cases_file) as f:
        test_cases = json.load(f)

    # Create output directory
    if output_dir:
        Path(output_dir).mkdir(parents=True, exist_ok=True)

    # Run each test case
    results = {}

    for test_id, test_config in test_cases.items():
        logging.info(f"Running test: {test_id}")

        # Create tester
        tester = PostChainTester(create_chorus_graph, test_id)

        # Extract test parameters
        prompt = test_config.get("prompt", "")
        loop_config = test_config.get("loop_config", {})
        max_loops = test_config.get("max_loops", 3)

        # Run the test
        try:
            result = await tester.run_test(
                prompt=prompt,
                loop_config=loop_config,
                max_loops=max_loops
            )

            # Analyze results
            analysis = tester.analyze()

            # Store result
            results[test_id] = {
                "success": True,
                "analysis": analysis
            }

            logging.info(f"Test {test_id} completed successfully")

        except Exception as e:
            logging.error(f"Test {test_id} failed: {str(e)}")

            results[test_id] = {
                "success": False,
                "error": str(e)
            }

    # Write summary report
    if output_dir:
        with open(Path(output_dir) / "summary.json", "w") as f:
            json.dump(results, f, indent=2)

    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run PostChain test suite")
    parser.add_argument("test_file", help="JSON file containing test cases")
    parser.add_argument("--output", help="Output directory for test results")

    args = parser.parse_args()

    results = asyncio.run(run_test_suite(args.test_file, args.output))

    # Print summary
    print("\nTest Summary:")
    for test_id, result in results.items():
        status = "SUCCESS" if result["success"] else f"FAILED: {result['error']}"
        print(f"{test_id}: {status}")
