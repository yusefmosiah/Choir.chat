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
    
    async def test_openai(self) -> Dict[str, Any]:
        """Test OpenAI structured output capabilities."""
        if not self.config.OPENAI_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing OpenAI structured output...")
            model = ChatOpenAI(
                api_key=self.config.OPENAI_API_KEY,
                model="gpt-3.5-turbo",
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
                    "model": "gpt-3.5-turbo",
                    "response": validated_response.model_dump(),
                    "provider": "OpenAI",
                    "raw_response": response.content
                }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "OpenAI",
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"OpenAI structured output test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "OpenAI"}
    
    async def test_anthropic(self) -> Dict[str, Any]:
        """Test Anthropic structured output capabilities."""
        if not self.config.ANTHROPIC_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Anthropic structured output...")
            model = ChatAnthropic(
                api_key=self.config.ANTHROPIC_API_KEY,
                model="claude-3-haiku-20240307",
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
                        "model": "claude-3-haiku-20240307",
                        "response": validated_response.model_dump(),
                        "provider": "Anthropic",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Anthropic",
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Anthropic",
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Anthropic structured output test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Anthropic"}
    
    # Similar methods for other providers...
    async def test_google(self) -> Dict[str, Any]:
        """Test Google structured output capabilities."""
        if not self.config.GOOGLE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            logger.info("Testing Google structured output...")
            model = ChatGoogleGenerativeAI(
                api_key=self.config.GOOGLE_API_KEY,
                model="gemini-pro",
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
                        "model": "gemini-pro",
                        "response": validated_response.model_dump(),
                        "provider": "Google",
                        "raw_response": content
                    }
                else:
                    return {
                        "status": "parse_error",
                        "error": "Could not find JSON in response",
                        "provider": "Google",
                        "raw_response": content
                    }
            except Exception as parse_error:
                return {
                    "status": "parse_error",
                    "error": str(parse_error),
                    "provider": "Google",
                    "raw_response": response.content
                }
                
        except Exception as e:
            logger.error(f"Google structured output test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Google"}
    
    async def run_all_tests(self) -> Dict[str, Dict[str, Any]]:
        """Run structured output tests for all providers."""
        tests = [
            self.test_openai(),
            self.test_anthropic(),
            self.test_google(),
            # Add other providers as needed
        ]
        
        results = await asyncio.gather(*tests)
        
        self.results = {
            "OpenAI": results[0],
            "Anthropic": results[1],
            "Google": results[2],
            # Add other providers as needed
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
        
        for provider, result in self.results.items():
            status = result.get("status", "unknown")
            
            if status == "success":
                logger.info(f"✅ {provider}: SUCCESS")
                logger.info(f"   Model: {result.get('model', 'unknown')}")
                logger.info(f"   Parsed Response: {json.dumps(result.get('response', {}), indent=2)}")
            elif status == "parse_error":
                logger.info(f"⚠️ {provider}: PARSE ERROR - {result.get('error', 'Unknown error')}")
                logger.info(f"   Raw Response: {result.get('raw_response', 'No response')}")
            elif status == "skipped":
                logger.info(f"⚠️ {provider}: SKIPPED - {result.get('reason', 'No reason provided')}")
            else:
                logger.info(f"❌ {provider}: ERROR - {result.get('error', 'Unknown error')}")
            
            logger.info("-"*50)
        
        # Summary
        success_count = sum(1 for r in self.results.values() if r.get("status") == "success")
        parse_error_count = sum(1 for r in self.results.values() if r.get("status") == "parse_error")
        skipped_count = sum(1 for r in self.results.values() if r.get("status") == "skipped")
        error_count = sum(1 for r in self.results.values() if r.get("status") == "error")
        
        logger.info(f"Summary: {success_count} successful, {parse_error_count} parse errors, {skipped_count} skipped, {error_count} failed")
        logger.info("="*50)

async def main():
    """Run the structured output tests."""
    config = Config()
    tester = StructuredOutputTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())