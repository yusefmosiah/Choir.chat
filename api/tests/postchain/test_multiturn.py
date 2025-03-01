"""
Test script to verify multi-turn conversation capabilities of each provider.
This tests the ability of models to maintain context across multiple turns.

The test uses a prompt chain format:
<system><user="hello"><ai><user="the magic number is 1729"><ai><user="whats the magic number"><ai_response_contains~="1729">
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
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from app.config import Config
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

class MultiTurnTester:
    """Test multi-turn conversation capabilities of various LLM providers."""
    
    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, Dict[str, Any]] = {}
        self.system_prompt = "You are a helpful assistant."
        self.conversation = [
            {"role": "human", "content": "hello"},
            {"role": "ai", "content": None},  # Will be filled during testing
            {"role": "human", "content": "the magic number is 1729"},
            {"role": "ai", "content": None},  # Will be filled during testing
            {"role": "human", "content": "whats the magic number"},
        ]
        self.expected_content = "1729"
    
    async def test_openai_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific OpenAI model."""
        if not self.config.OPENAI_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing OpenAI multi-turn conversation with {model_name}...")
            
            # Special case for o1 and o3-mini models which don't support temperature
            if model_name in [self.config.OPENAI_O1, self.config.OPENAI_O3_MINI]:
                model = ChatOpenAI(
                    api_key=self.config.OPENAI_API_KEY,
                    model=model_name
                )
            else:
                model = ChatOpenAI(
                    api_key=self.config.OPENAI_API_KEY,
                    model=model_name,
                    temperature=0
                )
            
            # Initialize messages with system prompt
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Run the conversation
            responses = []
            for i, message in enumerate(self.conversation):
                if message["role"] == "human":
                    # Add human message
                    messages.append(HumanMessage(content=message["content"]))
                    
                    # Get AI response
                    response = await model.ainvoke(messages)
                    responses.append(response.content)
                    
                    # Add AI response to messages for context
                    messages.append(AIMessage(content=response.content))
            
            # Get the final response for the last message
            final_response = await model.ainvoke(messages)
            responses.append(final_response.content)
            
            # Check if the expected content is in the final response
            contains_expected = self.expected_content in final_response.content
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "contains_expected": contains_expected,
                "provider": "OpenAI",
                "final_response": final_response.content
            }
        except Exception as e:
            logger.error(f"OpenAI multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "OpenAI",
                "model": model_name
            }
    
    async def test_openai(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all OpenAI models."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "OpenAI"}]
        
        results = []
        for model_name in get_openai_models(self.config):
            result = await self.test_openai_model(model_name)
            results.append(result)
        
        return results
    
    async def test_anthropic_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Anthropic model."""
        if not self.config.ANTHROPIC_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Anthropic multi-turn conversation with {model_name}...")
            
            model = ChatAnthropic(
                api_key=self.config.ANTHROPIC_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize messages with system prompt
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Run the conversation
            responses = []
            for i, message in enumerate(self.conversation):
                if message["role"] == "human":
                    # Add human message
                    messages.append(HumanMessage(content=message["content"]))
                    
                    # Get AI response
                    response = await model.ainvoke(messages)
                    responses.append(response.content)
                    
                    # Add AI response to messages for context
                    messages.append(AIMessage(content=response.content))
            
            # Get the final response for the last message
            final_response = await model.ainvoke(messages)
            responses.append(final_response.content)
            
            # Check if the expected content is in the final response
            contains_expected = self.expected_content in final_response.content
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "contains_expected": contains_expected,
                "provider": "Anthropic",
                "final_response": final_response.content
            }
        except Exception as e:
            logger.error(f"Anthropic multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Anthropic",
                "model": model_name
            }
    
    async def test_anthropic(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Anthropic models."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Anthropic"}]
        
        results = []
        for model_name in get_anthropic_models(self.config):
            result = await self.test_anthropic_model(model_name)
            results.append(result)
        
        return results
    
    async def test_google_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Google model."""
        if not self.config.GOOGLE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Google multi-turn conversation with {model_name}...")
            
            model = ChatGoogleGenerativeAI(
                api_key=self.config.GOOGLE_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize messages with system prompt
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Run the conversation
            responses = []
            for i, message in enumerate(self.conversation):
                if message["role"] == "human":
                    # Add human message
                    messages.append(HumanMessage(content=message["content"]))
                    
                    # Get AI response
                    response = await model.ainvoke(messages)
                    responses.append(response.content)
                    
                    # Add AI response to messages for context
                    messages.append(AIMessage(content=response.content))
            
            # Get the final response for the last message
            final_response = await model.ainvoke(messages)
            responses.append(final_response.content)
            
            # Check if the expected content is in the final response
            contains_expected = self.expected_content in final_response.content
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "contains_expected": contains_expected,
                "provider": "Google",
                "final_response": final_response.content
            }
        except Exception as e:
            logger.error(f"Google multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Google",
                "model": model_name
            }
    
    async def test_google(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Google models."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Google"}]
        
        results = []
        for model_name in get_google_models(self.config):
            result = await self.test_google_model(model_name)
            results.append(result)
        
        return results
    
    async def test_mistral_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Mistral model."""
        if not self.config.MISTRAL_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Mistral multi-turn conversation with {model_name}...")
            
            model = ChatMistralAI(
                api_key=self.config.MISTRAL_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize messages with system prompt
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Run the conversation
            responses = []
            for i, message in enumerate(self.conversation):
                if message["role"] == "human":
                    # Add human message
                    messages.append(HumanMessage(content=message["content"]))
                    
                    # Get AI response
                    response = await model.ainvoke(messages)
                    responses.append(response.content)
                    
                    # Add AI response to messages for context
                    messages.append(AIMessage(content=response.content))
            
            # Get the final response for the last message
            final_response = await model.ainvoke(messages)
            responses.append(final_response.content)
            
            # Check if the expected content is in the final response
            contains_expected = self.expected_content in final_response.content
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "contains_expected": contains_expected,
                "provider": "Mistral",
                "final_response": final_response.content
            }
        except Exception as e:
            logger.error(f"Mistral multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Mistral",
                "model": model_name
            }
    
    async def test_mistral(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Mistral models."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Mistral"}]
        
        results = []
        for model_name in get_mistral_models(self.config):
            result = await self.test_mistral_model(model_name)
            results.append(result)
        
        return results
    
    async def test_fireworks_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Fireworks model."""
        if not self.config.FIREWORKS_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Fireworks multi-turn conversation with {model_name}...")
            
            # Fireworks models need a prefix
            model_id = f"accounts/fireworks/models/{model_name}"
            
            model = ChatFireworks(
                api_key=self.config.FIREWORKS_API_KEY,
                model=model_id,
                temperature=0
            )
            
            # Initialize messages with system prompt
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Run the conversation
            responses = []
            for i, message in enumerate(self.conversation):
                if message["role"] == "human":
                    # Add human message
                    messages.append(HumanMessage(content=message["content"]))
                    
                    # Get AI response
                    response = await model.ainvoke(messages)
                    responses.append(response.content)
                    
                    # Add AI response to messages for context
                    messages.append(AIMessage(content=response.content))
            
            # Get the final response for the last message
            final_response = await model.ainvoke(messages)
            responses.append(final_response.content)
            
            # Check if the expected content is in the final response
            contains_expected = self.expected_content in final_response.content
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "contains_expected": contains_expected,
                "provider": "Fireworks",
                "final_response": final_response.content
            }
        except Exception as e:
            logger.error(f"Fireworks multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Fireworks",
                "model": model_name
            }
    
    async def test_fireworks(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Fireworks models."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Fireworks"}]
        
        results = []
        for model_name in get_fireworks_models(self.config):
            result = await self.test_fireworks_model(model_name)
            results.append(result)
        
        return results
    
    async def test_cohere_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Cohere model."""
        if not self.config.COHERE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Cohere multi-turn conversation with {model_name}...")
            
            model = ChatCohere(
                api_key=self.config.COHERE_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize messages with system prompt
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Run the conversation
            responses = []
            for i, message in enumerate(self.conversation):
                if message["role"] == "human":
                    # Add human message
                    messages.append(HumanMessage(content=message["content"]))
                    
                    # Get AI response
                    response = await model.ainvoke(messages)
                    responses.append(response.content)
                    
                    # Add AI response to messages for context
                    messages.append(AIMessage(content=response.content))
            
            # Get the final response for the last message
            final_response = await model.ainvoke(messages)
            responses.append(final_response.content)
            
            # Check if the expected content is in the final response
            contains_expected = self.expected_content in final_response.content
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "contains_expected": contains_expected,
                "provider": "Cohere",
                "final_response": final_response.content
            }
        except Exception as e:
            logger.error(f"Cohere multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Cohere",
                "model": model_name
            }
    
    async def test_cohere(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Cohere models."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Cohere"}]
        
        results = []
        for model_name in get_cohere_models(self.config):
            result = await self.test_cohere_model(model_name)
            results.append(result)
        
        return results
    
    async def run_all_tests(self) -> Dict[str, List[Dict[str, Any]]]:
        """Run multi-turn conversation tests for all providers."""
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
        logger.info("MULTI-TURN CONVERSATION TEST RESULTS")
        logger.info("="*50)
        
        total_models = 0
        total_success = 0
        total_error = 0
        total_skipped = 0
        total_passed = 0
        
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
                    contains_expected = result.get("contains_expected", False)
                    if contains_expected:
                        logger.info(f"✅ {model_name}: PASSED - Successfully remembered the magic number")
                        total_passed += 1
                    else:
                        logger.info(f"❌ {model_name}: FAILED - Did not remember the magic number")
                        logger.info(f"   Final response: {result.get('final_response', 'No response')[:100]}...")
                    
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
                passed_count = sum(1 for r in results_list if r.get("status") == "success" and r.get("contains_expected", False))
                total_count = len(results_list)
                provider_status = f"{passed_count}/{total_count} models passed"
            
            logger.info(f"{provider}: {provider_status}")
        
        logger.info("\nOverall Summary:")
        logger.info(f"Total Models: {total_models}")
        logger.info(f"Successful API Calls: {total_success}")
        logger.info(f"Passed Memory Test: {total_passed}")
        logger.info(f"Failed API Calls: {total_error}")
        logger.info(f"Skipped: {total_skipped}")
        logger.info("="*50)

async def main():
    """Run the multi-turn conversation tests."""
    config = Config()
    tester = MultiTurnTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())