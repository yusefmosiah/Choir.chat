"""
Test script to verify structured output capabilities of each provider.
This tests the ability of models to follow JSON schema constraints.
"""

import os
import asyncio
import logging
import json
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from langchain_cohere import ChatCohere
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.output_parsers import JsonOutputParser

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

# Define a schema for testing structured output
class ActionResponse(BaseModel):
    """Schema for testing structured output capabilities."""
    proposed_response: str = Field(description="The initial response to the user's query")
    confidence: float = Field(description="A number between 0 and 1 indicating confidence level")
    reasoning: str = Field(description="Brief explanation of the response")

class StructuredOutputTester:
    """Test structured output capabilities of various LLM providers."""
    
    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, Dict[str, Any]] = {}
        self.test_prompt = "What is the capital of France?"
        self.system_prompt = """
        You are a helpful assistant that provides information in a structured format.
        Please respond to the user's question with your answer, confidence level, and reasoning.
        """
    
    async def test_openai_model(self, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities of a specific OpenAI model."""
        if not self.config.OPENAI_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing OpenAI structured output with {model_name}...")
            
            # Special case for o1 and o3-mini models which don't support temperature
            if model_name in [self.config.OPENAI_O1, self.config.OPENAI_O3_MINI]:
                model = ChatOpenAI(
                    api_key=self.config.OPENAI_API_KEY,
                    model=model_name,
                    response_format={"type": "json_object"}
                )
            else:
                model = ChatOpenAI(
                    api_key=self.config.OPENAI_API_KEY,
                    model=model_name,
                    temperature=0,
                    response_format={"type": "json_object"}
                )
            
            messages = [
                SystemMessage(content=self.system_prompt),
                HumanMessage(content=self.test_prompt)
            ]
            
            response = await model.ainvoke(messages)
            
            # Try to parse the response as JSON
            try:
                parsed_response = json.loads(response.content)
                # Validate against our schema
                validated_response = ActionResponse(**parsed_response)
                return {
                    "status": "success",
                    "model": model_name,
                    "response": validated_response.model_dump(),
                    "provider": "OpenAI",
                    "raw_response": response.content
                }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "OpenAI",
                    "model": model_name,
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"OpenAI structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "OpenAI",
                "model": model_name
            }
    
    async def test_openai(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities of all OpenAI models."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "OpenAI"}]
        
        results = []
        for model_name in get_openai_models(self.config):
            result = await self.test_openai_model(model_name)
            results.append(result)
        
        return results
    
    async def test_anthropic_model(self, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities of a specific Anthropic model."""
        if not self.config.ANTHROPIC_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Anthropic structured output with {model_name}...")
            
            model = ChatAnthropic(
                api_key=self.config.ANTHROPIC_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Anthropic requires a different approach for structured output
            structured_system_prompt = f"""
            {self.system_prompt}
            
            You must respond in the following JSON format:
            {{
                "proposed_response": "Your answer to the question",
                "confidence": 0.9,  // A number between 0 and 1
                "reasoning": "Brief explanation of your answer"
            }}
            """
            
            messages = [
                SystemMessage(content=structured_system_prompt),
                HumanMessage(content=self.test_prompt)
            ]
            
            response = await model.ainvoke(messages)
            
            # Try to extract and parse JSON from the response
            try:
                # Look for JSON in the response
                content = response.content
                # Find JSON-like content (between curly braces)
                json_start = content.find('{')
                json_end = content.rfind('}') + 1
                
                if json_start >= 0 and json_end > json_start:
                    json_str = content[json_start:json_end]
                    parsed_response = json.loads(json_str)
                    validated_response = ActionResponse(**parsed_response)
                    return {
                        "status": "success",
                        "model": model_name,
                        "response": validated_response.model_dump(),
                        "provider": "Anthropic",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Anthropic",
                        "model": model_name,
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Anthropic",
                    "model": model_name,
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Anthropic structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Anthropic",
                "model": model_name
            }
    
    async def test_anthropic(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities of all Anthropic models."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Anthropic"}]
        
        results = []
        for model_name in get_anthropic_models(self.config):
            result = await self.test_anthropic_model(model_name)
            results.append(result)
        
        return results
    
    async def test_google_model(self, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities of a specific Google model."""
        if not self.config.GOOGLE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Google structured output with {model_name}...")
            
            model = ChatGoogleGenerativeAI(
                api_key=self.config.GOOGLE_API_KEY,
                model=model_name,
                temperature=0
            )
            
            structured_system_prompt = f"""
            {self.system_prompt}
            
            You must respond in the following JSON format:
            {{
                "proposed_response": "Your answer to the question",
                "confidence": 0.9,  // A number between 0 and 1
                "reasoning": "Brief explanation of your answer"
            }}
            """
            
            messages = [
                SystemMessage(content=structured_system_prompt),
                HumanMessage(content=self.test_prompt)
            ]
            
            response = await model.ainvoke(messages)
            
            # Try to extract and parse JSON from the response
            try:
                content = response.content
                json_start = content.find('{')
                json_end = content.rfind('}') + 1
                
                if json_start >= 0 and json_end > json_start:
                    json_str = content[json_start:json_end]
                    parsed_response = json.loads(json_str)
                    validated_response = ActionResponse(**parsed_response)
                    return {
                        "status": "success",
                        "model": model_name,
                        "response": validated_response.model_dump(),
                        "provider": "Google",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Google",
                        "model": model_name,
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Google",
                    "model": model_name,
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Google structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Google",
                "model": model_name
            }
    
    async def test_google(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities of all Google models."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Google"}]
        
        results = []
        for model_name in get_google_models(self.config):
            result = await self.test_google_model(model_name)
            results.append(result)
        
        return results
    
    async def test_mistral_model(self, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities of a specific Mistral model."""
        if not self.config.MISTRAL_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Mistral structured output with {model_name}...")
            
            model = ChatMistralAI(
                api_key=self.config.MISTRAL_API_KEY,
                model=model_name,
                temperature=0
            )
            
            structured_system_prompt = f"""
            {self.system_prompt}
            
            You must respond in the following JSON format:
            {{
                "proposed_response": "Your answer to the question",
                "confidence": 0.9,  // A number between 0 and 1
                "reasoning": "Brief explanation of your answer"
            }}
            """
            
            messages = [
                SystemMessage(content=structured_system_prompt),
                HumanMessage(content=self.test_prompt)
            ]
            
            response = await model.ainvoke(messages)
            
            # Try to extract and parse JSON from the response
            try:
                content = response.content
                json_start = content.find('{')
                json_end = content.rfind('}') + 1
                
                if json_start >= 0 and json_end > json_start:
                    json_str = content[json_start:json_end]
                    parsed_response = json.loads(json_str)
                    validated_response = ActionResponse(**parsed_response)
                    return {
                        "status": "success",
                        "model": model_name,
                        "response": validated_response.model_dump(),
                        "provider": "Mistral",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Mistral",
                        "model": model_name,
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Mistral",
                    "model": model_name,
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Mistral structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Mistral",
                "model": model_name
            }
    
    async def test_mistral(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities of all Mistral models."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Mistral"}]
        
        results = []
        for model_name in get_mistral_models(self.config):
            result = await self.test_mistral_model(model_name)
            results.append(result)
        
        return results
    
    async def test_fireworks_model(self, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities of a specific Fireworks model."""
        if not self.config.FIREWORKS_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Fireworks structured output with {model_name}...")
            
            # Fireworks models need a prefix
            model_id = f"accounts/fireworks/models/{model_name}"
            
            model = ChatFireworks(
                api_key=self.config.FIREWORKS_API_KEY,
                model=model_id,
                temperature=0
            )
            
            structured_system_prompt = f"""
            {self.system_prompt}
            
            You must respond in the following JSON format:
            {{
                "proposed_response": "Your answer to the question",
                "confidence": 0.9,  // A number between 0 and 1
                "reasoning": "Brief explanation of your answer"
            }}
            """
            
            messages = [
                SystemMessage(content=structured_system_prompt),
                HumanMessage(content=self.test_prompt)
            ]
            
            response = await model.ainvoke(messages)
            
            # Try to extract and parse JSON from the response
            try:
                content = response.content
                json_start = content.find('{')
                json_end = content.rfind('}') + 1
                
                if json_start >= 0 and json_end > json_start:
                    json_str = content[json_start:json_end]
                    parsed_response = json.loads(json_str)
                    validated_response = ActionResponse(**parsed_response)
                    return {
                        "status": "success",
                        "model": model_name,
                        "response": validated_response.model_dump(),
                        "provider": "Fireworks",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Fireworks",
                        "model": model_name,
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Fireworks",
                    "model": model_name,
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Fireworks structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Fireworks",
                "model": model_name
            }
    
    async def test_fireworks(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities of all Fireworks models."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Fireworks"}]
        
        results = []
        for model_name in get_fireworks_models(self.config):
            result = await self.test_fireworks_model(model_name)
            results.append(result)
        
        return results
    
    async def test_cohere_model(self, model_name: str) -> Dict[str, Any]:
        """Test structured output capabilities of a specific Cohere model."""
        if not self.config.COHERE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Cohere structured output with {model_name}...")
            
            model = ChatCohere(
                api_key=self.config.COHERE_API_KEY,
                model=model_name,
                temperature=0
            )
            
            structured_system_prompt = f"""
            {self.system_prompt}
            
            You must respond in the following JSON format:
            {{
                "proposed_response": "Your answer to the question",
                "confidence": 0.9,  // A number between 0 and 1
                "reasoning": "Brief explanation of your answer"
            }}
            """
            
            messages = [
                SystemMessage(content=structured_system_prompt),
                HumanMessage(content=self.test_prompt)
            ]
            
            response = await model.ainvoke(messages)
            
            # Try to extract and parse JSON from the response
            try:
                content = response.content
                json_start = content.find('{')
                json_end = content.rfind('}') + 1
                
                if json_start >= 0 and json_end > json_start:
                    json_str = content[json_start:json_end]
                    parsed_response = json.loads(json_str)
                    validated_response = ActionResponse(**parsed_response)
                    return {
                        "status": "success",
                        "model": model_name,
                        "response": validated_response.model_dump(),
                        "provider": "Cohere",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Cohere",
                        "model": model_name,
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Cohere",
                    "model": model_name,
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Cohere structured output test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Cohere",
                "model": model_name
            }
    
    async def test_cohere(self) -> List[Dict[str, Any]]:
        """Test structured output capabilities of all Cohere models."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Cohere"}]
        
        results = []
        for model_name in get_cohere_models(self.config):
            result = await self.test_cohere_model(model_name)
            results.append(result)
        
        return results
    
    async def run_all_tests(self) -> Dict[str, List[Dict[str, Any]]]:
        """Run structured output tests for all providers."""
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
        logger.info("STRUCTURED OUTPUT TEST RESULTS")
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

async def main():
    """Run the structured output tests."""
    config = Config()
    tester = StructuredOutputTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())