"""
Test script to verify multi-model conversation capabilities with true token-by-token streaming.
This tests the ability of different models to interact with each other in a conversation,
showing a clear stream of conversations between pairs of models with tokens displayed in real-time.

First test: 2-turn conversations between each pair of models across providers,
testing if the second model can recall information (a magic number) provided to the first model.
"""

import asyncio
import logging
import itertools
import time
import sys
from typing import Dict, Any, List
from dataclasses import dataclass, field

from app.config import Config
from app.langchain_utils import abstract_llm_completion_stream, get_model_provider

from tests.postchain.test_providers import (
    get_openai_models,
    get_anthropic_models,
    get_google_models,
    get_mistral_models,
    get_fireworks_models,
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

@dataclass
class ModelConfig:
    provider: str
    model_name: str

    def __str__(self):
        return f"{self.provider}/{self.model_name}"

class SimpleMultiModelStreamTester:
    def __init__(self, config: Config):
        self.config = config
        self.system_prompt = "You are a helpful assistant in a conversation with other AI assistants. Be clear, concise, and build upon previous responses."
        self.magic_number = "1729"
        self.results = {}
        self.success_count = 0
        self.context_maintained_count = 0
        self.total_count = 0

    def initialize_model_list(self) -> List[ModelConfig]:
        models = []
        if self.config.OPENAI_API_KEY:
            models.extend([ModelConfig("openai", m) for m in get_openai_models(self.config)])
        if self.config.ANTHROPIC_API_KEY:
            models.extend([ModelConfig("anthropic", m) for m in get_anthropic_models(self.config)])
        if self.config.GOOGLE_API_KEY:
            models.extend([ModelConfig("google", m) for m in get_google_models(self.config)])
        if self.config.MISTRAL_API_KEY:
            models.extend([ModelConfig("mistral", m) for m in get_mistral_models(self.config)])
        if self.config.FIREWORKS_API_KEY:
            models.extend([ModelConfig("fireworks", m) for m in get_fireworks_models(self.config)])
        logger.info(f"Initialized {len(models)} models for testing")
        return models

    async def test_model_pair(self, model1: ModelConfig, model2: ModelConfig):
        """Test a single conversation between two models with token streaming"""
        self.total_count += 1
        pair_id = f"{model1} ↔ {model2}"

        # Print conversation header
        print("\n" + "="*80)
        print(f"CONVERSATION TEST: {pair_id}")
        print("="*80)

        messages = [{"role": "system", "content": self.system_prompt}]

        # First turn
        user_message = f"The magic number is {self.magic_number}. Explain what makes this number interesting."
        messages.append({"role": "user", "content": user_message})
        print(f"\n👤 User: {user_message}")

        try:
            # First model response (with true token streaming)
            start_time = time.time()
            full_response1 = ""
            print(f"\n🤖 {model1}: ", end="", flush=True)

            # Use the streaming function from langchain_utils.py
            async for token in abstract_llm_completion_stream(f"{model1}", messages, self.config):
                print(token, end="", flush=True)
                full_response1 += token

            elapsed = time.time() - start_time
            print(f" ({elapsed:.2f}s)")

            # Add the response to messages for the next turn
            messages.append({"role": "assistant", "content": full_response1})

            # Second turn
            follow_up = "What was the magic number I mentioned earlier? Please include it in your response."
            messages.append({"role": "user", "content": follow_up})
            print(f"\n👤 User: {follow_up}")

            # Second model response (with true token streaming)
            start_time = time.time()
            full_response2 = ""
            print(f"\n🤖 {model2}: ", end="", flush=True)

            # Use the streaming function from langchain_utils.py
            async for token in abstract_llm_completion_stream(f"{model2}", messages, self.config):
                print(token, end="", flush=True)
                full_response2 += token

            elapsed = time.time() - start_time
            print(f" ({elapsed:.2f}s)")

            # Check if context is maintained
            context_maintained = self.magic_number in full_response2
            status = "✅ MAINTAINED" if context_maintained else "❌ LOST"
            print(f"\n🔍 Context {status}: Magic number {self.magic_number}")

            if context_maintained:
                self.context_maintained_count += 1

            self.success_count += 1
            return {
                "status": "success",
                "context_maintained": context_maintained,
                "responses": [full_response1, full_response2]
            }

        except Exception as e:
            print(f"\n❌ Exception testing {pair_id}: {str(e)}")
            return {
                "status": "error",
                "context_maintained": False,
                "responses": []
            }

    async def run_all_pairs(self, limit_per_provider=1):
        """Run tests for all pairs of models"""
        models = self.initialize_model_list()

        # Limit models per provider if requested
        if limit_per_provider > 0:
            models_by_provider = {}
            for model in models:
                if model.provider not in models_by_provider:
                    models_by_provider[model.provider] = []
                if len(models_by_provider[model.provider]) < limit_per_provider:
                    models_by_provider[model.provider].append(model)

            models = []
            for provider_models in models_by_provider.values():
                models.extend(provider_models)

        # Generate all unique pairs
        model_pairs = list(itertools.combinations(models, 2))
        logger.info(f"Testing {len(model_pairs)} unique model pairs with real-time token streaming")

        # Run tests for each pair
        for model1, model2 in model_pairs:
            result = await self.test_model_pair(model1, model2)

            # Store result
            pair_key = f"{model1.provider}-{model2.provider}"
            if pair_key not in self.results:
                self.results[pair_key] = []
            self.results[pair_key].append({
                "model1": model1,
                "model2": model2,
                "result": result
            })

    def print_summary(self):
        """Print a summary of test results"""
        if not self.results:
            logger.info("No results to display")
            return

        print("\n" + "="*80)
        print("TOKEN STREAMING TEST SUMMARY")
        print("="*80)

        # Overall stats
        print(f"\nTotal tests: {self.total_count}")
        print(f"Successful tests: {self.success_count} ({self.success_count/self.total_count*100:.1f}%)")
        if self.success_count > 0:
            print(f"Context maintained: {self.context_maintained_count} ({self.context_maintained_count/self.success_count*100:.1f}% of successful tests)")

        # Results by provider pair
        print("\nResults by provider pair:")
        for pair_key, tests in self.results.items():
            provider1, provider2 = pair_key.split("-")
            success = sum(1 for t in tests if t["result"]["status"] == "success")
            maintained = sum(1 for t in tests if t["result"]["context_maintained"])
            print(f"  {provider1} ↔ {provider2}: {success}/{len(tests)} successful, {maintained}/{success} maintained context")

        print("="*80)

def run_sync():
    """Run the test synchronously from the command line"""
    config = Config()
    tester = SimpleMultiModelStreamTester(config)
    asyncio.run(tester.run_all_pairs(limit_per_provider=1))
    tester.print_summary()

if __name__ == "__main__":
    # Use true token-by-token streaming
    run_sync()
