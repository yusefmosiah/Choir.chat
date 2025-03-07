"""
Test script to verify multi-model conversation capabilities with random model selection and token streaming.
This tests the ability of different models to maintain context across a longer conversation,
showing a clear stream of conversations with multiple random model transitions.

The test runs a multi-turn conversation where a different random model is selected for each turn,
testing if models can maintain context (including a "magic number") across multiple transitions.
"""

import asyncio
import logging
import random
import time
import sys
from typing import Dict, Any, List
from dataclasses import dataclass, field

from app.config import Config
from app.langchain_utils import abstract_llm_completion_stream, initialize_model_list, ModelConfig

from tests.postchain.test_utils import (
    load_prompts,
)

# Configure logging with colors and formatting
class ColoredFormatter(logging.Formatter):
    """Custom formatter with colored output"""
    COLORS = {
        'DEBUG': '\033[94m',      # Blue
        'INFO': '\033[92m',       # Green
        'WARNING': '\033[93m',    # Yellow
        'ERROR': '\033[91m',      # Red
        'CRITICAL': '\033[91m',   # Red
        'RESET': '\033[0m'        # Reset
    }

    def format(self, record):
        log_message = super().format(record)
        level_name = record.levelname
        color = self.COLORS.get(level_name, self.COLORS['RESET'])
        return f"{color}{log_message}{self.COLORS['RESET']}"

# Set up colored logging
handler = logging.StreamHandler()
handler.setFormatter(ColoredFormatter('%(asctime)s - %(message)s'))
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(handler)
logger.propagate = False  # Prevent duplicate logs

class RandomMultiModelStreamTester:
    def __init__(self, config: Config):
        self.config = config
        self.system_prompt = "You are a helpful assistant in a multi-model conversation. Be clear, concise, and build upon previous responses."
        self.magic_number = "137"  # Changed from 1729 to 137 as requested
        self.results = {}
        self.success_count = 0
        self.context_maintained_count = 0
        self.total_count = 0
        self.turns_per_conversation = 5  # Default number of turns
        self.prompts = []  # Will be loaded from random_gen_prompts.md

    async def run_random_conversation(self, models: List[ModelConfig], num_turns: int = None):
        """Run a conversation with random model selection for each turn"""
        if num_turns is None:
            num_turns = self.turns_per_conversation

        # Make sure we have prompts loaded
        if not self.prompts:
            self.prompts = load_prompts()

        self.total_count += 1

        # Print conversation header
        print("\n" + "="*80)
        print(f"RANDOM MULTI-MODEL CONVERSATION TEST ({num_turns} turns)")
        print("="*80)

        # Prepare conversation with system prompt
        messages = [{"role": "system", "content": self.system_prompt}]

        # Track used models and context maintenance
        used_models = []
        response_times = []
        context_checked = False
        context_maintained = False

        # Select random prompts for the conversation
        selected_prompts = random.sample(self.prompts, num_turns) if len(self.prompts) >= num_turns else random.choices(self.prompts, k=num_turns)

        # First user message with the magic number
        user_message = f"The magic number is {self.magic_number}. Please remember this number for the entire conversation. " + selected_prompts[0]
        messages.append({"role": "user", "content": user_message})
        print(f"\n👤 User: {user_message}")

        try:
            for turn in range(num_turns):
                # Randomly select a model for this turn
                model = random.choice(models)
                used_models.append(model)

                # Model response with token streaming
                start_time = time.time()
                full_response = ""
                print(f"\n🤖 Turn {turn+1} | {model}: ", end="", flush=True)

                # Use the streaming function from langchain_utils.py
                async for token in abstract_llm_completion_stream(f"{model}", messages, self.config):
                    print(token, end="", flush=True)
                    full_response += token

                elapsed = time.time() - start_time
                response_times.append(elapsed)
                print(f" ({elapsed:.2f}s)")

                # Add the response to the conversation history
                messages.append({"role": "assistant", "content": full_response})

                # For the last turn, check if the magic number is maintained
                if turn == num_turns - 1:
                    context_maintained = self.magic_number in full_response
                    context_checked = True
                    status = "✅ MAINTAINED" if context_maintained else "❌ LOST"
                    print(f"\n🔍 Context {status}: Magic number {self.magic_number}")

                    if context_maintained:
                        self.context_maintained_count += 1

                # If not the last turn, add another user message
                if turn < num_turns - 1:
                    if turn == num_turns - 2:
                        # For the second-to-last turn, explicitly ask for the magic number
                        next_message = "What was the magic number I mentioned at the beginning of our conversation? Please include it in your response."
                    else:
                        # Use the next prompt from our selected prompts
                        next_message = selected_prompts[turn + 1]

                    messages.append({"role": "user", "content": next_message})
                    print(f"\n👤 User: {next_message}")

            # Record success
            self.success_count += 1

            return {
                "status": "success",
                "models_used": used_models,
                "response_times": response_times,
                "context_maintained": context_maintained if context_checked else None,
                "messages": messages,
                "prompts_used": selected_prompts
            }

        except Exception as e:
            print(f"\n❌ Exception in random conversation: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "models_used": used_models,
                "context_maintained": context_maintained if context_checked else None,
                "prompts_used": selected_prompts
            }

    async def run_multiple_conversations(self, num_conversations: int = 3, turns_per_conversation: int = 5):
        """Run multiple random conversations"""
        self.turns_per_conversation = turns_per_conversation

        # Make sure we have prompts loaded
        if not self.prompts:
            self.prompts = load_prompts()

        # Disable OpenAI models as they're not available
        models = initialize_model_list(self.config, disabled_providers={"openai"})

        if not models:
            logger.error("No models available for testing")
            return

        logger.info(f"Running {num_conversations} random conversations with {turns_per_conversation} turns each")
        logger.info(f"Using {len(models)} models with OpenAI disabled")

        for i in range(num_conversations):
            result = await self.run_random_conversation(models, turns_per_conversation)

            # Store result
            conversation_id = f"conversation-{i+1}"
            self.results[conversation_id] = result

    def print_summary(self):
        """Print a summary of test results"""
        if not self.results:
            logger.info("No results to display")
            return

        print("\n" + "="*80)
        print("RANDOM MULTI-MODEL STREAMING TEST SUMMARY")
        print("="*80)

        # Overall stats
        print(f"\nTotal conversations: {self.total_count}")
        print(f"Successful conversations: {self.success_count} ({self.success_count/self.total_count*100:.1f}%)")
        if self.success_count > 0:
            print(f"Context maintained: {self.context_maintained_count} ({self.context_maintained_count/self.success_count*100:.1f}% of successful conversations)")

        # Model usage stats
        model_usage = {}
        for conv_id, result in self.results.items():
            if result["status"] == "success" and "models_used" in result:
                for model in result["models_used"]:
                    provider = model.provider
                    if provider not in model_usage:
                        model_usage[provider] = 0
                    model_usage[provider] += 1

        if model_usage:
            print("\nModel provider usage:")
            for provider, count in model_usage.items():
                print(f"  {provider}: {count} turns")

        # Print prompt usage summary
        prompt_usage = set()
        for conv_id, result in self.results.items():
            if result["status"] == "success" and "prompts_used" in result:
                for prompt in result["prompts_used"]:
                    short_prompt = prompt[:50] + "..." if len(prompt) > 50 else prompt
                    prompt_usage.add(short_prompt)

        if prompt_usage:
            print(f"\nUnique prompts used: {len(prompt_usage)}")
            if len(prompt_usage) <= 5:  # Only show if there aren't too many
                print("Sample prompts:")
                for i, prompt in enumerate(list(prompt_usage)[:5]):
                    print(f"  {i+1}: {prompt}")

        # Response time stats
        all_times = []
        for conv_id, result in self.results.items():
            if result["status"] == "success" and "response_times" in result:
                all_times.extend(result["response_times"])

        if all_times:
            avg_time = sum(all_times) / len(all_times)
            max_time = max(all_times)
            min_time = min(all_times)
            print(f"\nResponse times: avg={avg_time:.2f}s, min={min_time:.2f}s, max={max_time:.2f}s")

        print("="*80)

def main():
    """Main entry point for the test script"""
    # Get the number of conversations and turns from command-line arguments
    num_conversations = int(sys.argv[1]) if len(sys.argv) > 1 else 3
    turns_per_conversation = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    # Create config and tester
    config = Config()
    tester = RandomMultiModelStreamTester(config)

    # Run the test asynchronously
    asyncio.run(tester.run_multiple_conversations(
        num_conversations=num_conversations,
        turns_per_conversation=turns_per_conversation
    ))

    # Print the summary
    tester.print_summary()

if __name__ == "__main__":
    main()
