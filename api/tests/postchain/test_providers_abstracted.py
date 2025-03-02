"""
Test script to verify API connectivity with each provider using the abstraction layer.
This is a reimplementation of test_providers.py using the langchain_utils abstraction.
"""

import os
import asyncio
import logging
from typing import Dict, Any, List, Optional, Tuple

from app.config import Config
from app.langchain_utils import abstract_llm_completion

# Import model lists from the original test
from tests.postchain.test_providers import (
    get_openai_models,
    get_anthropic_models,
    get_google_models,
    get_mistral_models,
    get_fireworks_models,
    get_cohere_models
)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AbstractedProviderTester:
    """Test connectivity with various LLM providers using the abstraction layer."""

    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, List[Dict[str, Any]]] = {}
        self.test_message = "Say hello!"

    async def test_model(self, provider: str, model_name: str) -> Dict[str, Any]:
        """Test a specific model using the abstraction layer."""
        try:
            model_id = f"{provider}/{model_name}"
            logger.info(f"Testing {provider} model: {model_name} using abstraction...")

            # Prepare messages
            messages = [{"role": "user", "content": self.test_message}]

            # Use the abstraction layer
            response = await abstract_llm_completion(
                model_name=model_id,
                messages=messages,
                config=self.config
            )

            if response["status"] == "success":
                return {
                    "status": "success",
                    "model": model_name,
                    "response": response["content"],
                    "provider": provider
                }
            else:
                return {
                    "status": "error",
                    "error": response["content"],
                    "model": model_name,
                    "provider": provider
                }
        except Exception as e:
            logger.error(f"{provider} model {model_name} test failed: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "model": model_name,
                "provider": provider
            }

    async def test_openai_models(self) -> List[Dict[str, Any]]:
        """Test OpenAI models using the abstraction layer."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "openai"}]

        results = []
        for model_name in get_openai_models(self.config):
            result = await self.test_model("openai", model_name)
            results.append(result)

        return results

    async def test_anthropic_models(self) -> List[Dict[str, Any]]:
        """Test Anthropic models using the abstraction layer."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "anthropic"}]

        results = []
        for model_name in get_anthropic_models(self.config):
            result = await self.test_model("anthropic", model_name)
            results.append(result)

        return results

    async def test_google_models(self) -> List[Dict[str, Any]]:
        """Test Google models using the abstraction layer."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "google"}]

        results = []
        for model_name in get_google_models(self.config):
            result = await self.test_model("google", model_name)
            results.append(result)

        return results

    async def test_mistral_models(self) -> List[Dict[str, Any]]:
        """Test Mistral models using the abstraction layer."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "mistral"}]

        results = []
        for model_name in get_mistral_models(self.config):
            result = await self.test_model("mistral", model_name)
            results.append(result)

        return results

    async def test_fireworks_models(self) -> List[Dict[str, Any]]:
        """Test Fireworks models using the abstraction layer."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "fireworks"}]

        results = []
        for model_name in get_fireworks_models(self.config):
            # No need to add prefix, abstraction layer handles it
            result = await self.test_model("fireworks", model_name)
            results.append(result)

        return results

    async def test_cohere_models(self) -> List[Dict[str, Any]]:
        """Test Cohere models using the abstraction layer."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "cohere"}]

        results = []
        for model_name in get_cohere_models(self.config):
            result = await self.test_model("cohere", model_name)
            results.append(result)

        return results

    async def run_all_tests(self) -> Dict[str, List[Dict[str, Any]]]:
        """Run all provider tests."""
        test_tasks = [
            self.test_openai_models(),
            self.test_anthropic_models(),
            self.test_google_models(),
            self.test_mistral_models(),
            self.test_fireworks_models(),
            self.test_cohere_models()
        ]

        all_results = await asyncio.gather(*test_tasks)

        self.results = {
            "OpenAI": all_results[0],
            "Anthropic": all_results[1],
            "Google": all_results[2],
            "Mistral": all_results[3],
            "Fireworks": all_results[4],
            "Cohere": all_results[5]
        }

        return self.results

    def print_results(self) -> None:
        """Print test results in a readable format."""
        if not self.results:
            logger.info("No test results available. Run tests first.")
            return

        logger.info("\n" + "="*50)
        logger.info("ABSTRACTED PROVIDER TEST RESULTS")
        logger.info("="*50)

        total_models = 0
        total_success = 0
        total_error = 0
        total_skipped = 0

        for provider, results_list in self.results.items():
            logger.info(f"\n{provider} Models:")
            logger.info("-"*50)

            # Check if the provider was skipped entirely
            if len(results_list) == 1 and results_list[0].get("status") == "skipped":
                logger.info(f"⚠️ {provider}: SKIPPED - {results_list[0].get('reason', 'No reason provided')}")
                total_skipped += 1
                continue

            # Process each model result
            for result in results_list:
                status = result.get("status", "unknown")
                model_name = result.get("model", "unknown")

                if status == "success":
                    logger.info(f"✅ {model_name}: SUCCESS")
                    logger.info(f"   Response: {result.get('response', 'No response')[:100]}...")
                    total_success += 1
                elif status == "skipped":
                    logger.info(f"⚠️ {model_name}: SKIPPED - {result.get('reason', 'No reason provided')}")
                    total_skipped += 1
                else:
                    logger.info(f"❌ {model_name}: ERROR - {result.get('error', 'Unknown error')}")
                    total_error += 1

                total_models += 1

            logger.info("-"*50)

        # Overall summary
        logger.info("\nSummary by Provider:")
        for provider, results_list in self.results.items():
            if len(results_list) == 1 and results_list[0].get("status") == "skipped":
                provider_status = "SKIPPED"
            else:
                success_count = sum(1 for r in results_list if r.get("status") == "success")
                total_count = len(results_list)
                provider_status = f"{success_count}/{total_count} models successful"

            logger.info(f"{provider}: {provider_status}")

        logger.info("\nOverall Summary:")
        logger.info(f"Total Models: {total_models}")
        logger.info(f"Successful: {total_success}")
        logger.info(f"Failed: {total_error}")
        logger.info(f"Skipped: {total_skipped}")
        logger.info("="*50)

        # Compare with original implementation
        logger.info("\nComparison with Original Implementation:")
        logger.info("This test uses the abstraction layer to achieve the same results")
        logger.info("with a simpler, more maintainable implementation.")
        logger.info("="*50)

async def main():
    """Run the provider tests using the abstraction layer."""
    config = Config()
    tester = AbstractedProviderTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())
