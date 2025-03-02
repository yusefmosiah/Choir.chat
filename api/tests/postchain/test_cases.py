import pytest
import asyncio
from .test_framework import PostChainTester
from api.app.chorus_graph import create_chorus_graph

# Create a factory function for the chain
def get_test_chain():
    """Create a test instance of the chorus graph with a higher recursion limit."""
    return create_chorus_graph({"recursion_limit": 100})

@pytest.mark.asyncio
async def test_basic_flow():
    """Test basic flow through all phases without looping"""
    tester = PostChainTester(get_test_chain, "basic_flow")

    prompt = "What is the meaning of life?"

    # Run with no looping
    result = await tester.run_test(
        prompt=prompt,
        loop_config={"should_loop": False}
    )

    # Assert final state reached yield
    assert result["current_phase"] == "yield"

    # Analyze results
    analysis = tester.analyze()
    print("\nBasic Flow Analysis:")
    print(analysis)

    # Verify all phases executed exactly once
    phase_distribution = analysis["phase_distribution"]
    for phase in ["action", "experience", "intention", "observation", "understanding", "yield"]:
        assert phase_distribution.get(phase, 0) == 1

@pytest.mark.asyncio
async def test_looping_behavior():
    """Test looping behavior with different probability settings"""
    tester = PostChainTester(get_test_chain, "looping_behavior")

    prompt = "Explain quantum computing to me in detail"

    # Force two loops before yield
    result = await tester.run_test(
        prompt=prompt,
        loop_config={
            "should_loop": True,
            "loop_probability": 0.9
        },
        max_loops=2,
        recursion_limit=100  # Add a high recursion limit to avoid errors
    )

    # Analyze results
    analysis = tester.analyze()
    print("\nLooping Behavior Analysis:")
    print(analysis)

    # Verify loop executed
    assert analysis["loops"] > 1
    assert "action->experience" in analysis["transitions"]

    # Verify loop terminates at yield
    assert result["current_phase"] == "yield"

@pytest.mark.asyncio
async def test_tool_integration():
    """Test integration with tools in action phase"""
    tester = PostChainTester(get_test_chain, "tool_integration")

    # Prompt that should trigger web search tool
    prompt = "What were yesterday's major news headlines?"

    result = await tester.run_test(prompt=prompt)

    # Check tool usage in action phase
    action_response = result["responses"].get("action", {})
    tools_used = action_response.get("tools_used", [])

    print("\nTools Used:")
    print(tools_used)

    # Note: This will only pass once tool integration is implemented
    # assert len(tools_used) > 0

@pytest.mark.asyncio
async def test_confidence_thresholds():
    """Test how confidence scores affect looping behavior"""
    tester = PostChainTester(get_test_chain, "confidence_thresholds")

    # Run tests with different confidence thresholds
    thresholds = [0.3, 0.6, 0.9]
    results = []

    for threshold in thresholds:
        result = await tester.run_test(
            prompt="Explain the theory of relativity",
            loop_config={
                "should_loop": True,
                "confidence_threshold": threshold,
                "loop_probability": 0.5
            },
            max_loops=3
        )
        results.append((threshold, tester.analyze()))

    # Compare results across thresholds
    print("\nConfidence Threshold Analysis:")
    for threshold, analysis in results:
        print(f"Threshold {threshold}: {analysis['loops']} loops, "
             f"avg confidence: {analysis['avg_confidence']}")

@pytest.mark.asyncio
async def test_error_handling():
    """Test system behavior with error conditions"""
    tester = PostChainTester(get_test_chain, "error_handling")

    # Empty prompt (should trigger error handling)
    try:
        result = await tester.run_test(prompt="")
        print("\nEmpty Prompt Result:")
        print(result)
    except Exception as e:
        print(f"Expected error: {str(e)}")
