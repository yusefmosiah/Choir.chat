"""
Test script to verify API connectivity with each provider.
Run this script to check if all API keys are properly configured.
"""

import os
import asyncio
import logging
from typing import Dict, Any, List, Optional, Tuple

from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from langchain_cohere import ChatCohere
from langchain_core.messages import HumanMessage

from app.config import Config

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Get models to test from config
def get_openai_models(config: Config) -> List[str]:
    return [
        config.OPENAI_GPT_45_PREVIEW,
        config.OPENAI_GPT_4O,
        config.OPENAI_GPT_4O_MINI,
        config.OPENAI_O1,
        config.OPENAI_O3_MINI
    ]

def get_anthropic_models(config: Config) -> List[str]:
    return [
        config.ANTHROPIC_CLAUDE_37_SONNET,
        config.ANTHROPIC_CLAUDE_35_HAIKU
    ]

def get_google_models(config: Config) -> List[str]:
    return [
        config.GOOGLE_GEMINI_20_FLASH,
        config.GOOGLE_GEMINI_20_FLASH_LITE,
        config.GOOGLE_GEMINI_20_PRO_EXP,
        config.GOOGLE_GEMINI_20_FLASH_THINKING
    ]

def get_mistral_models(config: Config) -> List[str]:
    return [
        config.MISTRAL_PIXTRAL_12B,
        config.MISTRAL_SMALL_LATEST,
        config.MISTRAL_PIXTRAL_LARGE,
        config.MISTRAL_LARGE_LATEST,
        config.MISTRAL_CODESTRAL
    ]

def get_cohere_models(config: Config) -> List[str]:
    return [
        config.COHERE_COMMAND_R7B
    ]

def get_fireworks_models(config: Config) -> List[str]:
    return [
        config.FIREWORKS_DEEPSEEK_R1,
        config.FIREWORKS_DEEPSEEK_V3,
        config.FIREWORKS_QWEN25_CODER
    ]

class ProviderTester:
    """Test connectivity with various LLM providers."""
    
    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, Dict[str, Any]] = {}
    
    async def test_model(self, provider: str, model_name: str, model_class, api_key: str) -> Dict[str, Any]:
        """Test a specific model."""
        try:
            logger.info(f"Testing {provider} model: {model_name}...")
            model = model_class(
                api_key=api_key,
                model=model_name,
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": model_name,
                "response": response.content,
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
        """Test OpenAI models."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "OpenAI"}]
        
        results = []
        for model_name in get_openai_models(self.config):
            result = await self.test_model(
                "OpenAI", 
                model_name, 
                ChatOpenAI, 
                self.config.OPENAI_API_KEY
            )
            results.append(result)
        
        return results
    
    async def test_anthropic_models(self) -> List[Dict[str, Any]]:
        """Test Anthropic models."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Anthropic"}]
        
        results = []
        for model_name in get_anthropic_models(self.config):
            result = await self.test_model(
                "Anthropic", 
                model_name, 
                ChatAnthropic, 
                self.config.ANTHROPIC_API_KEY
            )
            results.append(result)
        
        return results
    
    async def test_google_models(self) -> List[Dict[str, Any]]:
        """Test Google models."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Google"}]
        
        results = []
        for model_name in get_google_models(self.config):
            result = await self.test_model(
                "Google", 
                model_name, 
                ChatGoogleGenerativeAI, 
                self.config.GOOGLE_API_KEY
            )
            results.append(result)
        
        return results
    
    async def test_mistral_models(self) -> List[Dict[str, Any]]:
        """Test Mistral models."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Mistral"}]
        
        results = []
        for model_name in get_mistral_models(self.config):
            result = await self.test_model(
                "Mistral", 
                model_name, 
                ChatMistralAI, 
                self.config.MISTRAL_API_KEY
            )
            results.append(result)
        
        return results
    
    async def test_fireworks_models(self) -> List[Dict[str, Any]]:
        """Test Fireworks models."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Fireworks"}]
        
        results = []
        for model_name in get_fireworks_models(self.config):
            # Fireworks models might need a prefix
            model_id = f"accounts/fireworks/models/{model_name}"
            result = await self.test_model(
                "Fireworks", 
                model_id, 
                ChatFireworks, 
                self.config.FIREWORKS_API_KEY
            )
            results.append(result)
        
        return results
    
    async def test_cohere_models(self) -> List[Dict[str, Any]]:
        """Test Cohere models."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Cohere"}]
        
        results = []
        for model_name in get_cohere_models(self.config):
            result = await self.test_model(
                "Cohere", 
                model_name, 
                ChatCohere, 
                self.config.COHERE_API_KEY
            )
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
        logger.info("PROVIDER TEST RESULTS")
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

async def main():
    """Run the provider tests."""
    config = Config()
    tester = ProviderTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())