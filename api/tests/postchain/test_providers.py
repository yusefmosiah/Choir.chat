"""
Test script to verify API connectivity with each provider.
Run this script to check if all API keys are properly configured.
"""

import os
import asyncio
import logging
from typing import Dict, Any, List, Optional

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

class ProviderTester:
    """Test connectivity with various LLM providers."""
    
    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, Dict[str, Any]] = {}
    
    async def test_openai(self) -> Dict[str, Any]:
        """Test OpenAI API connectivity."""
        if not self.config.OPENAI_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing OpenAI API...")
            model = ChatOpenAI(
                api_key=self.config.OPENAI_API_KEY,
                model="gpt-3.5-turbo",
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": "gpt-3.5-turbo",
                "response": response.content,
                "provider": "OpenAI"
            }
        except Exception as e:
            logger.error(f"OpenAI API test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "OpenAI"}
    
    async def test_anthropic(self) -> Dict[str, Any]:
        """Test Anthropic API connectivity."""
        if not self.config.ANTHROPIC_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Anthropic API...")
            model = ChatAnthropic(
                api_key=self.config.ANTHROPIC_API_KEY,
                model="claude-3-haiku-20240307",
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": "claude-3-haiku-20240307",
                "response": response.content,
                "provider": "Anthropic"
            }
        except Exception as e:
            logger.error(f"Anthropic API test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Anthropic"}
    
    async def test_google(self) -> Dict[str, Any]:
        """Test Google API connectivity."""
        if not self.config.GOOGLE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Google API...")
            model = ChatGoogleGenerativeAI(
                api_key=self.config.GOOGLE_API_KEY,
                model="gemini-pro",
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": "gemini-pro",
                "response": response.content,
                "provider": "Google"
            }
        except Exception as e:
            logger.error(f"Google API test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Google"}
    
    async def test_mistral(self) -> Dict[str, Any]:
        """Test Mistral API connectivity."""
        if not self.config.MISTRAL_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Mistral API...")
            model = ChatMistralAI(
                api_key=self.config.MISTRAL_API_KEY,
                model="mistral-medium",
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": "mistral-medium",
                "response": response.content,
                "provider": "Mistral"
            }
        except Exception as e:
            logger.error(f"Mistral API test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Mistral"}
    
    async def test_fireworks(self) -> Dict[str, Any]:
        """Test Fireworks API connectivity."""
        if not self.config.FIREWORKS_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Fireworks API...")
            model = ChatFireworks(
                api_key=self.config.FIREWORKS_API_KEY,
                model="accounts/fireworks/models/deepseek-chat",
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": "deepseek-chat",
                "response": response.content,
                "provider": "Fireworks"
            }
        except Exception as e:
            logger.error(f"Fireworks API test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Fireworks"}
    
    async def test_cohere(self) -> Dict[str, Any]:
        """Test Cohere API connectivity."""
        if not self.config.COHERE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Cohere API...")
            model = ChatCohere(
                api_key=self.config.COHERE_API_KEY,
                model="command",
                temperature=0
            )
            
            response = await model.ainvoke([HumanMessage(content="Say hello!")])
            return {
                "status": "success",
                "model": "command",
                "response": response.content,
                "provider": "Cohere"
            }
        except Exception as e:
            logger.error(f"Cohere API test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Cohere"}
    
    async def run_all_tests(self) -> Dict[str, Dict[str, Any]]:
        """Run all provider tests."""
        tests = [
            self.test_openai(),
            self.test_anthropic(),
            self.test_google(),
            self.test_mistral(),
            self.test_fireworks(),
            self.test_cohere()
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
        logger.info("PROVIDER TEST RESULTS")
        logger.info("="*50)
        
        for provider, result in self.results.items():
            status = result.get("status", "unknown")
            
            if status == "success":
                logger.info(f"✅ {provider}: SUCCESS")
                logger.info(f"   Model: {result.get('model', 'unknown')}")
                logger.info(f"   Response: {result.get('response', 'No response')}")
            elif status == "skipped":
                logger.info(f"⚠️ {provider}: SKIPPED - {result.get('reason', 'No reason provided')}")
            else:
                logger.info(f"❌ {provider}: ERROR - {result.get('error', 'Unknown error')}")
            
            logger.info("-"*50)
        
        # Summary
        success_count = sum(1 for r in self.results.values() if r.get("status") == "success")
        skipped_count = sum(1 for r in self.results.values() if r.get("status") == "skipped")
        error_count = sum(1 for r in self.results.values() if r.get("status") == "error")
        
        logger.info(f"Summary: {success_count} successful, {skipped_count} skipped, {error_count} failed")
        logger.info("="*50)

async def main():
    """Run the provider tests."""
    config = Config()
    tester = ProviderTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())