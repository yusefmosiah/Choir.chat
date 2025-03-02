"""
Test script to verify structured output capabilities using the abstraction layer.
This is a reimplementation of test_structured_output.py using the langchain_utils abstraction.
"""

import os
import asyncio
import logging
import json
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

from app.config import Config
from app.langchain_utils import abstract_llm_structured_output

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

# Define a schema for testing structured output
class ActionResponse(BaseModel):
    """Schema for testing structured output capabilities."""
    proposed_response: str = Field(description="The initial response to the user's query")
    confidence: float = Field(description="A number between 0 and 1 indicating confidence level")
    reasoning: str = Field(description="Brief explanation of the response")

class AbstractedStructuredOutputTester:
    """Test structured output capabilities using the abstraction layer."""

    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, List[Dict[str, Any]]] = {}
        self.test_prompt = "What is the capital of France?"
        self.system_prompt = """
        You are a helpful assistant that provides information in a structured JSON format.
        Please respond to the user's question with your answer, confidence level, and reasoning.
        """

    async def test_model(self, provider: str, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities for a specific model using the abstraction."""
        try:
            model_id = f"{provider}/{model_name}"
            logger.info(f"Testing {provider} structured output with {model_name} using abstraction...")

            # Prepare messages
            messages = [
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": self.test_prompt}
            ]

            # Use the abstraction layer
            response = await abstract_llm_structured_output(
                model_name=model_id,
                messages=messages,
                response_model=ActionResponse,
                config=self.config
            )

            if response["status"] == "success":
                return {
                    "status": "success",
                    "model": model_name,
                    "response": response["content"],
                    "provider": provider,
                    "raw_response": str(response.get("raw_response", ""))
                }
            else:
                return {
                    "status": "parse_error",
                    "error": response["content"],
                    "provider": provider,
                    "model": model_name,
                    "raw_response": str(response.get("raw_response", ""))
                }

        except Exception as e:
            logger.error(f"{provider} structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "provider": provider,
                "model": model_name
            }

    async def test_openai_models(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities for OpenAI models."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "openai"}]

        results = []
        for model_name in get_openai_models(self.config):
            result = await self.test_model("openai", model_name)
            results.append(result)

        return results

    async def test_anthropic_models(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities for Anthropic models."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "anthropic"}]

        results = []
        for model_name in get_anthropic_models(self.config):
            result = await self.test_model("anthropic", model_name)
            results.append(result)

        return results

    async def test_google_models(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities for Google models."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "google"}]

        results = []
        for model_name in get_google_models(self.config):
            result = await self.test_model("google", model_name)
            results.append(result)

        return results

    async def test_mistral_models(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities for Mistral models."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "mistral"}]

        results = []
        for model_name in get_mistral_models(self.config):
            result = await self.test_model("mistral", model_name)
            results.append(result)

        return results

    async def test_fireworks_models(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities for Fireworks models."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "fireworks"}]

        results = []
        for model_name in get_fireworks_models(self.config):
            # No need to add prefix, abstraction layer handles it
            result = await self.test_model("fireworks", model_name)
            results.append(result)

        return results

    async def test_cohere_models(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities for Cohere models."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "cohere"}]

        results = []
        for model_name in get_cohere_models(self.config):
            result = await self.test_model("cohere", model_name)
            results.append(result)

        return results

    async def run_all_tests(self) -> Dict[str, List[Dict[str, Any]]]:
        """Run structured output tests for all providers."""
        tests = [
            self.test_openai_models(),
            self.test_anthropic_models(),
            self.test_google_models(),
            self.test_mistral_models(),
            self.test_fireworks_models(),
            self.test_cohere_models()
        ]

        results = await asyncio.gather(*tests)

        self.results = {
            "OpenAI": results[0],
            "Anthropic": results[1],
            "Google": results[2],
            "Mistral": results[3],
            "Fireworks": results[4],
            "Cohere": results[5]
        }

        return self.results

    def print_results(self) -> None:
        """Print test results in a readable format."""
        if not self.results:
            logger.info("No test results available. Run tests first.")
            return

        logger.info("\n" + "="*50)
        logger.info("ABSTRACTED STRUCTURED OUTPUT TEST RESULTS")
        logger.info("="*50)

        total_models = 0
        total_success = 0
        total_parse_error = 0
        total_error = 0
        total_skipped = 0

        for provider, results_list in self.results.items():
            logger.info(f"\n{provider} Models:")
            logger.info("-"*50)

            # Check if the provider was skipped entirely
            if len(results_list) == 1 and results_list[0].get("status") == "skipped" and "provider" in results_list[0]:
                logger.info(f"⚠️ {provider}: SKIPPED - {results_list[0].get('reason', 'No reason provided')}")
                total_skipped += 1
                continue

            # Process each model result
            for result in results_list:
                status = result.get("status", "unknown")
                model_name = result.get("model", "unknown")

                if status == "success":
                    logger.info(f"✅ {model_name}: SUCCESS")
                    logger.info(f"   Parsed Response: {json.dumps(result.get('response', {}), indent=2)[:200]}...")
                    total_success += 1
                elif status == "parse_error":
                    logger.info(f"⚠️ {model_name}: PARSE ERROR - {result.get('error', 'Unknown error')}")
                    logger.info(f"   Raw Response: {result.get('raw_response', 'No response')[:100]}...")
                    total_parse_error += 1
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
            if len(results_list) == 1 and results_list[0].get("status") == "skipped" and "provider" in results_list[0]:
                provider_status = "SKIPPED"
            else:
                success_count = sum(1 for r in results_list if r.get("status") == "success")
                total_count = len(results_list)
                provider_status = f"{success_count}/{total_count} models successful"

            logger.info(f"{provider}: {provider_status}")

        logger.info("\nOverall Summary:")
        logger.info(f"Total Models: {total_models}")
        logger.info(f"Successful: {total_success}")
        logger.info(f"Parse Errors: {total_parse_error}")
        logger.info(f"Failed: {total_error}")
        logger.info(f"Skipped: {total_skipped}")
        logger.info("="*50)

        # Compare with original implementation
        logger.info("\nComparison with Original Implementation:")
        logger.info("This test uses the abstraction layer to achieve the same results")
        logger.info("with a simpler, more maintainable implementation.")
        logger.info("The abstraction layer handles model-specific details automatically.")
        logger.info("="*50)

async def main():
    """Run the structured output tests using the abstraction layer."""
    config = Config()
    tester = AbstractedStructuredOutputTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())
