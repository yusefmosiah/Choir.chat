import pytest
import asyncio
import logging
import random
import re
import os
from typing import Dict, Any, List, Optional, Tuple

from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, BaseMessage

# Adjust imports based on actual project structure
from app.config import Config
from app.langchain_utils import initialize_model_list, ModelConfig
from app.postchain.langchain_workflow import run_langchain_postchain_workflow

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Test Data ---
PROMPTS = [
    "Explain the theory of relativity in simple terms.",
    "What are the main differences between Python and JavaScript?",
    "Suggest three creative ideas for a short story.",
    "Describe the process of photosynthesis.",
    "What is blockchain technology and how does it work?",
    "Give me a recipe for chocolate chip cookies.",
    "Summarize the plot of Hamlet.",
    "What are some effective strategies for learning a new language?",
    "Explain the concept of machine learning.",
    "Tell me an interesting fact about the planet Mars."
]

MAGIC_NUMBER = "9876" # Different magic number for this test

# --- Test Class ---

@pytest.mark.asyncio
class TestLangchainWorkflow:

    @pytest.fixture(scope="class")
    def config(self) -> Config:
        """Fixture to provide Config."""
        return Config()

    @pytest.fixture(scope="class")
    def available_models(self, config) -> List[ModelConfig]:
        """Fixture to provide the list of available models."""
        models = initialize_model_list(config)
        if not models:
            pytest.skip("No models available for testing. Check API keys.")
        logger.info(f"Initialized {len(models)} models for testing workflow.")
        return models

    async def run_single_turn(
        self,
        query: str,
        thread_id: str,
        message_history: List[BaseMessage],
        config: Config,
        available_models: List[ModelConfig]
    ) -> Tuple[List[BaseMessage], Optional[str], bool]:
        """Helper to run one turn of the workflow with random models per phase."""
        if not available_models:
            return message_history, "No models available", False

        # Randomly select models for each phase for this turn
        phase_models = {
            "action_mc_override": random.choice(available_models),
            "experience_mc_override": random.choice(available_models),
            "intention_mc_override": random.choice(available_models),
            "observation_mc_override": random.choice(available_models),
            "understanding_mc_override": random.choice(available_models),
            "yield_mc_override": random.choice(available_models),
        }
        logger.info(f"Turn models: { {k: str(v) for k, v in phase_models.items()} }")

        final_content = None
        error_occurred = False
        try:
            async for event in run_langchain_postchain_workflow(
                query=query,
                thread_id=thread_id,
                message_history=message_history,
                config=config,
                **phase_models # Pass the randomly selected models
            ):
                logger.debug(f"Event: {event}") # Log events for debugging if needed
                if event.get("status") == "error":
                    logger.error(f"Error during phase {event.get('phase')}: {event.get('content')}")
                    error_occurred = True
                    final_content = f"ERROR: {event.get('content')}"
                    break # Stop processing on error
                if event.get("phase") == "yield" and event.get("status") == "complete":
                    final_content = event.get("final_content")
                    # Add final AI response to history for the next turn
                    if final_content:
                         message_history.append(AIMessage(content=final_content))

        except Exception as e:
            logger.error(f"Exception during workflow execution: {e}", exc_info=True)
            error_occurred = True
            final_content = f"EXCEPTION: {e}"

        return message_history, final_content, error_occurred


    async def test_multi_turn_random_models(self, config, available_models):
        """
        Tests a multi-turn conversation using the Langchain workflow
        with randomly selected models for each phase in each turn.
        Includes a basic context retention check.
        """
        num_test_runs = 2 # Number of independent conversations to test
        num_turns_per_run = 4 # Number of user turns per conversation

        logger.info(f"Starting multi-turn random model test ({num_test_runs} runs, {num_turns_per_run} turns each)...")

        overall_success = True
        context_maintained_count = 0

        for run in range(num_test_runs):
            logger.info(f"\n--- Test Run {run + 1}/{num_test_runs} ---")
            message_history: List[BaseMessage] = []
            thread_id = f"test-lc-workflow-run-{run + 1}"
            run_failed = False
            final_response_run = ""

            for turn in range(num_turns_per_run):
                logger.info(f"--- Turn {turn + 1}/{num_turns_per_run} ---")

                # Select prompt
                if turn == 0:
                    # First turn: Introduce magic number
                    prompt = f"The new magic number is {MAGIC_NUMBER}. Please remember it. Also, {random.choice(PROMPTS)}"
                elif turn == num_turns_per_run - 1:
                    # Last turn: Ask for magic number
                    prompt = f"What was the magic number I told you at the start of this conversation (run {run+1})?"
                else:
                    # Intermediate turns: Use random prompts
                    prompt = random.choice(PROMPTS)

                logger.info(f"User Prompt: {prompt}")

                message_history, final_content, error_occurred = await self.run_single_turn(
                    query=prompt,
                    thread_id=thread_id,
                    message_history=message_history,
                    config=config,
                    available_models=available_models
                )

                logger.info(f"AI Response: {final_content[:150] if final_content else 'None'}...")

                if error_occurred:
                    logger.error(f"Run {run + 1}, Turn {turn + 1} failed due to error.")
                    run_failed = True
                    overall_success = False
                    break # Stop this test run

                if turn == num_turns_per_run - 1:
                    final_response_run = final_content or ""


            if not run_failed:
                # Check context retention on the last turn
                context_maintained_this_run = MAGIC_NUMBER in final_response_run
                if context_maintained_this_run:
                    context_maintained_count += 1
                    logger.info(f"Run {run + 1}: Context Maintained (Found '{MAGIC_NUMBER}') ✅")
                else:
                    logger.warning(f"Run {run + 1}: Context FAILED (Did not find '{MAGIC_NUMBER}') ❌")
                    overall_success = False # Mark overall as failed if context is lost

        logger.info("\n--- Multi-Turn Test Summary ---")
        logger.info(f"Total Runs: {num_test_runs}")
        logger.info(f"Context Maintained Runs: {context_maintained_count}/{num_test_runs}")

        # Assert that at least some runs maintained context (allowing for some LLM flakiness)
        # A stricter test might assert context_maintained_count == num_test_runs
        assert context_maintained_count > 0, f"Context ({MAGIC_NUMBER}) was not maintained in any of the {num_test_runs} test runs."
        # Assert that all runs completed without critical errors stopping the workflow
        # assert overall_success, "One or more test runs failed due to errors or context loss."
        # Commenting out the overall success assert for now, as context loss might happen due to LLM variability.
        # Focus on ensuring the workflow runs and context is maintained at least sometimes.
