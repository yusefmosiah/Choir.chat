#!/usr/bin/env python
"""
Post Chain with Actor Model - Demo Runner

This script demonstrates the complete Post Chain implementation
using the actor model architecture with libsql/turso integration.
"""

import asyncio
import logging
from typing import List, Dict, Any
import sys
import argparse

from post_chain_actors import PostChain
from turso_integration import EnhancedTursoStorage, populate_knowledge_base


# Set up logging
def setup_logging(verbose: bool = False):
    """Set up logging for the application"""
    log_level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)]
    )


# Demo interactions
DEMO_INTERACTIONS = [
    "Tell me about the actor model",
    "How does the actor model relate to AI systems?",
    "How does Elixir implement the actor model?",
    "Can I implement actors in Python?",
    "What's the difference between actors and objects?",
]


async def run_interactive_demo():
    """Run the Post Chain in interactive demo mode"""
    print("\n🌟 Welcome to the Post Chain Actor Model Demo 🌟\n")
    print("Initializing Post Chain system...")

    # Initialize storage with RAG capabilities
    storage = EnhancedTursoStorage(connection_string="libsql://example.turso.io")
    await storage.connect()

    print("Populating knowledge base...")
    await populate_knowledge_base(storage)

    # Create the Post Chain
    chain = PostChain(storage)

    # Start the chain processing in the background
    chain_task = asyncio.create_task(chain.run())

    try:
        print("\n✅ Post Chain ready for input\n")
        print("Example queries:")
        for i, query in enumerate(DEMO_INTERACTIONS, 1):
            print(f"  {i}. {query}")
        print("  q. Quit\n")

        while True:
            user_input = input("🔍 Enter your query (or a number for an example, q to quit): ")

            if user_input.lower() in ['q', 'quit', 'exit']:
                break

            # Handle numbered examples
            if user_input.isdigit() and 1 <= int(user_input) <= len(DEMO_INTERACTIONS):
                user_input = DEMO_INTERACTIONS[int(user_input) - 1]
                print(f"Selected: {user_input}")

            print("\n⏳ Processing through Post Chain...\n")

            # Process through Post Chain
            response = await chain.process_input(user_input)

            print("\n🔄 Post Chain Response:")
            print(f"  {response}\n")

            # Show the RAG context that influenced the response
            results = await storage.perform_rag_query(user_input, limit=2)
            if results:
                print("📚 Knowledge context used:")
                for i, result in enumerate(results, 1):
                    metadata = result.get("metadata", {})
                    print(f"  {i}. {metadata.get('title', 'Unknown')} ({metadata.get('source', 'Unknown')})")
                    text = result["text"].split("\n", 1)[1]  # Skip the title line
                    print(f"     \"{text[:100]}...\"\n")

    except KeyboardInterrupt:
        print("\nInterrupted by user. Shutting down...")
    finally:
        # Clean up
        print("Saving state...")
        await chain.save_state()

        print("Closing storage connection...")
        await storage.close()

        # Cancel the chain background task
        chain_task.cancel()
        try:
            await chain_task
        except asyncio.CancelledError:
            pass

        print("\n👋 Thank you for trying the Post Chain Actor Model Demo!")


async def run_benchmark():
    """Run a benchmark of the Post Chain processing"""
    print("\n⚡ Running Post Chain Benchmark ⚡\n")

    # Initialize storage
    storage = EnhancedTursoStorage(connection_string="libsql://example.turso.io")
    await storage.connect()
    await populate_knowledge_base(storage)

    # Create the Post Chain
    chain = PostChain(storage)

    # Process each example query and measure time
    results = []
    for query in DEMO_INTERACTIONS:
        print(f"Processing: {query}")
        start_time = asyncio.get_event_loop().time()
        response = await chain.process_input(query)
        end_time = asyncio.get_event_loop().time()

        # Record result
        results.append({
            "query": query,
            "time": end_time - start_time,
            "response_length": len(response)
        })

    # Display results
    print("\n📊 Benchmark Results:\n")
    print("| Query | Time (s) | Response Length |")
    print("|-------|----------|-----------------|")
    for result in results:
        print(f"| {result['query'][:20]}... | {result['time']:.4f}s | {result['response_length']} chars |")

    # Calculate averages
    avg_time = sum(r["time"] for r in results) / len(results)
    print(f"\nAverage processing time: {avg_time:.4f}s")

    # Clean up
    await storage.close()


async def main():
    """Main entry point for the demo"""
    parser = argparse.ArgumentParser(description="Post Chain Actor Model Demo")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    parser.add_argument("-b", "--benchmark", action="store_true", help="Run benchmark instead of interactive demo")
    args = parser.parse_args()

    # Set up logging
    setup_logging(args.verbose)

    if args.benchmark:
        await run_benchmark()
    else:
        await run_interactive_demo()


if __name__ == "__main__":
    asyncio.run(main())
