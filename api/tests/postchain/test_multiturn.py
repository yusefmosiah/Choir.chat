"""
Test script to verify multi-turn conversation capabilities of each provider.
This tests the ability of models to maintain context across multiple turns.
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
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

from app.config import Config

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class MultiTurnTester:
    """Test multi-turn conversation capabilities of various LLM providers."""
    
    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, Dict[str, Any]] = {}
        self.system_prompt = """
        You are a helpful assistant that engages in multi-turn conversations.
        Be concise but informative in your responses.
        """
        self.conversation = [
            {"role": "human", "content": "Hello! I'd like to plan a trip to France."},
            {"role": "ai", "content": None},  # Will be filled during testing
            {"role": "human", "content": "What's the best time of year to visit Paris?"},
            {"role": "ai", "content": None},  # Will be filled during testing
            {"role": "human", "content": "What are the must-see attractions there?"},
        ]
    
    async def test_openai(self) -> Dict[str, Any]:
        """Test OpenAI multi-turn conversation capabilities."""
        if not self.config.OPENAI_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            # Use GPT-4o from config
            model_name = self.config.OPENAI_GPT_4O
            logger.info(f"Testing OpenAI multi-turn conversation with {model_name}...")
            
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
            
            # Check if the last response references information from earlier in the conversation
            context_maintained = any(
                "Paris" in responses[-1] or 
                "France" in responses[-1] or 
                "trip" in responses[-1].lower()
            )
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "context_maintained": context_maintained,
                "provider": "OpenAI"
            }
        except Exception as e:
            logger.error(f"OpenAI multi-turn test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "OpenAI"}
    
    async def test_anthropic(self) -> Dict[str, Any]:
        """Test Anthropic multi-turn conversation capabilities."""
        if not self.config.ANTHROPIC_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            # Use Claude 3.5 Haiku from config
            model_name = self.config.ANTHROPIC_CLAUDE_35_HAIKU
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
            
            # Check if the last response references information from earlier in the conversation
            context_maintained = any(
                "Paris" in responses[-1] or 
                "France" in responses[-1] or 
                "trip" in responses[-1].lower()
            )
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "context_maintained": context_maintained,
                "provider": "Anthropic"
            }
        except Exception as e:
            logger.error(f"Anthropic multi-turn test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Anthropic"}
    
    async def test_google(self) -> Dict[str, Any]:
        """Test Google multi-turn conversation capabilities."""
        if not self.config.GOOGLE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured"}
        
        try:
            # Use Gemini 2.0 Flash from config
            model_name = self.config.GOOGLE_GEMINI_20_FLASH
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
            
            # Check if the last response references information from earlier in the conversation
            context_maintained = any(
                "Paris" in responses[-1] or 
                "France" in responses[-1] or 
                "trip" in responses[-1].lower()
            )
            
            return {
                "status": "success",
                "model": model_name,
                "responses": responses,
                "context_maintained": context_maintained,
                "provider": "Google"
            }
        except Exception as e:
            logger.error(f"Google multi-turn test failed: {str(e)}")
            return {"status": "error", "error": str(e), "provider": "Google"}
    
    async def run_all_tests(self) -> Dict[str, Dict[str, Any]]:
        """Run multi-turn conversation tests for all providers."""
        tests = [
            self.test_openai(),
            self.test_anthropic(),
            self.test_google(),
            # We're only testing multi-turn with the main providers
            # that have the best multi-turn capabilities
        ]
        
        results = await asyncio.gather(*tests)
        
        self.results = {
            "OpenAI": results[0],
            "Anthropic": results[1],
            "Google": results[2],
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
        
        for provider, result in self.results.items():
            status = result.get("status", "unknown")
            
            if status == "success":
                context_maintained = result.get("context_maintained", False)
                context_status = "✅" if context_maintained else "❌"
                
                logger.info(f"✅ {provider}: SUCCESS")
                logger.info(f"   Model: {result.get('model', 'unknown')}")
                logger.info(f"   Context Maintained: {context_status}")
                
                # Print conversation
                responses = result.get("responses", [])
                logger.info("   Conversation:")
                for i, message in enumerate(self.conversation):
                    if message["role"] == "human":
                        logger.info(f"   Human: {message['content']}")
                        if i < len(responses):
                            logger.info(f"   AI: {responses[i]}")
            elif status == "skipped":
                logger.info(f"⚠️ {provider}: SKIPPED - {result.get('reason', 'No reason provided')}")
            else:
                logger.info(f"❌ {provider}: ERROR - {result.get('error', 'Unknown error')}")
            
            logger.info("-"*50)
        
        # Summary
        success_count = sum(1 for r in self.results.values() if r.get("status") == "success")
        context_maintained_count = sum(1 for r in self.results.values() if r.get("status") == "success" and r.get("context_maintained", False))
        skipped_count = sum(1 for r in self.results.values() if r.get("status") == "skipped")
        error_count = sum(1 for r in self.results.values() if r.get("status") == "error")
        
        logger.info(f"Summary: {success_count} successful, {context_maintained_count} maintained context, {skipped_count} skipped, {error_count} failed")
        logger.info("="*50)

async def main():
    """Run the multi-turn conversation tests."""
    config = Config()
    tester = MultiTurnTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())