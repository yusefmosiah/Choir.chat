"""
Test script to verify multi-turn conversation capabilities using LangGraph.
This tests the ability of models to maintain context across multiple turns
using a LangGraph implementation.

The test uses a prompt chain format:
<system><user="hello"><ai><user="the magic number is 1729"><ai><user="whats the magic number"><ai_response_contains~="1729">
"""

import os
import asyncio
import logging
from typing import Dict, Any, List, Optional, TypedDict, Annotated, Literal

# LangGraph imports
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage

# LangChain model imports
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from langchain_cohere import ChatCohere

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

# Define the state schema for our conversation graph
class ConversationState(TypedDict):
    messages: List[Any]  # List of messages in the conversation
    current_turn: int    # Current turn in the conversation
    expected_content: str  # Content we expect to see in the final response
    model_name: str      # Name of the model being tested
    provider: str        # Provider of the model being tested
    final_response: Optional[str]  # The final response from the model

# Define the conversation flow
def create_conversation_graph(model):
    """Create a LangGraph for multi-turn conversation testing."""
    
    # Define the nodes in our graph
    def process_user_message(state: ConversationState) -> ConversationState:
        """Process the user message and update the state."""
        current_turn = state["current_turn"]
        new_state = state.copy()
        
        # We're done if we've processed all turns
        if current_turn >= 3:  # We have 3 user messages in our test
            return new_state
        
        # Add the current user message to the messages list
        if current_turn == 0:
            new_state["messages"].append(HumanMessage(content="hello"))
        elif current_turn == 1:
            new_state["messages"].append(HumanMessage(content="the magic number is 1729"))
        elif current_turn == 2:
            new_state["messages"].append(HumanMessage(content="whats the magic number"))
        
        # Increment the turn counter
        new_state["current_turn"] = current_turn + 1
        
        return new_state
    
    def generate_ai_response(state: ConversationState) -> ConversationState:
        """Generate an AI response using the specified model."""
        new_state = state.copy()
        
        # If we've processed all user messages, we're done
        if state["current_turn"] > 3:
            return new_state
        
        try:
            # Generate a response from the model
            response = model.invoke(state["messages"])
            
            # Add the AI response to the messages
            new_state["messages"].append(response)
            
            # If this is the final turn, check if the response contains the expected content
            if state["current_turn"] == 3:
                new_state["final_response"] = response.content
        except Exception as e:
            logger.error(f"Error generating AI response: {str(e)}")
            # Add an error message as the AI response
            new_state["messages"].append(AIMessage(content=f"Error: {str(e)}"))
            new_state["final_response"] = f"Error: {str(e)}"
        
        return new_state
    
    def should_continue(state: ConversationState) -> Literal["continue", "end"]:
        """Determine if we should continue the conversation or end it."""
        if state["current_turn"] >= 3:
            return "end"
        return "continue"
    
    # Create the graph
    workflow = StateGraph(ConversationState)
    
    # Add nodes
    workflow.add_node("process_user_message", process_user_message)
    workflow.add_node("generate_ai_response", generate_ai_response)
    
    # Add edges
    workflow.add_edge("process_user_message", "generate_ai_response")
    workflow.add_conditional_edges(
        "generate_ai_response",
        should_continue,
        {
            "continue": "process_user_message",
            "end": END
        }
    )
    
    # Set the entry point
    workflow.set_entry_point("process_user_message")
    
    # Compile the graph
    return workflow.compile()

class LangGraphMultiTurnTester:
    """Test multi-turn conversation capabilities using LangGraph."""
    
    def __init__(self, config: Config):
        self.config = config
        self.results: Dict[str, Dict[str, Any]] = {}
        self.system_prompt = "You are a helpful assistant."
        self.expected_content = "1729"
    
    async def test_openai_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific OpenAI model using LangGraph."""
        if not self.config.OPENAI_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing OpenAI multi-turn conversation with {model_name} using LangGraph...")
            
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
            
            # Initialize the conversation with a system message
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Create the conversation graph
            graph = create_conversation_graph(model)
            
            # Run the graph
            result = graph.invoke({
                "messages": messages,
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": "OpenAI",
                "final_response": None
            })
            
            # Check if the expected content is in the final response
            final_response = result["final_response"] or ""
            contains_expected = self.expected_content in final_response
            
            return {
                "status": "success",
                "model": model_name,
                "contains_expected": contains_expected,
                "provider": "OpenAI",
                "final_response": final_response
            }
        except Exception as e:
            logger.error(f"OpenAI LangGraph multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "OpenAI",
                "model": model_name
            }
    
    async def test_openai(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all OpenAI models using LangGraph."""
        if not self.config.OPENAI_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "OpenAI"}]
        
        results = []
        for model_name in get_openai_models(self.config):
            result = await self.test_openai_model(model_name)
            results.append(result)
        
        return results
    
    async def test_anthropic_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Anthropic model using LangGraph."""
        if not self.config.ANTHROPIC_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Anthropic multi-turn conversation with {model_name} using LangGraph...")
            
            model = ChatAnthropic(
                api_key=self.config.ANTHROPIC_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize the conversation with a system message
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Create the conversation graph
            graph = create_conversation_graph(model)
            
            # Run the graph
            result = graph.invoke({
                "messages": messages,
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": "Anthropic",
                "final_response": None
            })
            
            # Check if the expected content is in the final response
            final_response = result["final_response"] or ""
            contains_expected = self.expected_content in final_response
            
            return {
                "status": "success",
                "model": model_name,
                "contains_expected": contains_expected,
                "provider": "Anthropic",
                "final_response": final_response
            }
        except Exception as e:
            logger.error(f"Anthropic LangGraph multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Anthropic",
                "model": model_name
            }
    
    async def test_anthropic(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Anthropic models using LangGraph."""
        if not self.config.ANTHROPIC_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Anthropic"}]
        
        results = []
        for model_name in get_anthropic_models(self.config):
            result = await self.test_anthropic_model(model_name)
            results.append(result)
        
        return results
    
    async def test_google_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Google model using LangGraph."""
        if not self.config.GOOGLE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Google multi-turn conversation with {model_name} using LangGraph...")
            
            model = ChatGoogleGenerativeAI(
                api_key=self.config.GOOGLE_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize the conversation with a system message
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Create the conversation graph
            graph = create_conversation_graph(model)
            
            # Run the graph
            result = graph.invoke({
                "messages": messages,
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": "Google",
                "final_response": None
            })
            
            # Check if the expected content is in the final response
            final_response = result["final_response"] or ""
            contains_expected = self.expected_content in final_response
            
            return {
                "status": "success",
                "model": model_name,
                "contains_expected": contains_expected,
                "provider": "Google",
                "final_response": final_response
            }
        except Exception as e:
            logger.error(f"Google LangGraph multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Google",
                "model": model_name
            }
    
    async def test_google(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Google models using LangGraph."""
        if not self.config.GOOGLE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Google"}]
        
        results = []
        for model_name in get_google_models(self.config):
            result = await self.test_google_model(model_name)
            results.append(result)
        
        return results
    
    async def test_mistral_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Mistral model using LangGraph."""
        if not self.config.MISTRAL_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Mistral multi-turn conversation with {model_name} using LangGraph...")
            
            model = ChatMistralAI(
                api_key=self.config.MISTRAL_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize the conversation with a system message
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Create the conversation graph
            graph = create_conversation_graph(model)
            
            # Run the graph
            result = graph.invoke({
                "messages": messages,
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": "Mistral",
                "final_response": None
            })
            
            # Check if the expected content is in the final response
            final_response = result["final_response"] or ""
            contains_expected = self.expected_content in final_response
            
            return {
                "status": "success",
                "model": model_name,
                "contains_expected": contains_expected,
                "provider": "Mistral",
                "final_response": final_response
            }
        except Exception as e:
            logger.error(f"Mistral LangGraph multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Mistral",
                "model": model_name
            }
    
    async def test_mistral(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Mistral models using LangGraph."""
        if not self.config.MISTRAL_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Mistral"}]
        
        results = []
        for model_name in get_mistral_models(self.config):
            result = await self.test_mistral_model(model_name)
            results.append(result)
        
        return results
    
    async def test_fireworks_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Fireworks model using LangGraph."""
        if not self.config.FIREWORKS_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Fireworks multi-turn conversation with {model_name} using LangGraph...")
            
            # Fireworks models need a prefix
            model_id = f"accounts/fireworks/models/{model_name}"
            
            model = ChatFireworks(
                api_key=self.config.FIREWORKS_API_KEY,
                model=model_id,
                temperature=0
            )
            
            # Initialize the conversation with a system message
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Create the conversation graph
            graph = create_conversation_graph(model)
            
            # Run the graph
            result = graph.invoke({
                "messages": messages,
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": "Fireworks",
                "final_response": None
            })
            
            # Check if the expected content is in the final response
            final_response = result["final_response"] or ""
            contains_expected = self.expected_content in final_response
            
            return {
                "status": "success",
                "model": model_name,
                "contains_expected": contains_expected,
                "provider": "Fireworks",
                "final_response": final_response
            }
        except Exception as e:
            logger.error(f"Fireworks LangGraph multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Fireworks",
                "model": model_name
            }
    
    async def test_fireworks(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Fireworks models using LangGraph."""
        if not self.config.FIREWORKS_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Fireworks"}]
        
        results = []
        for model_name in get_fireworks_models(self.config):
            result = await self.test_fireworks_model(model_name)
            results.append(result)
        
        return results
    
    async def test_cohere_model(self, model_name: str) -> Dict[str, Any]:
        """Test multi-turn conversation capabilities of a specific Cohere model using LangGraph."""
        if not self.config.COHERE_API_KEY:
            return {"status": "skipped", "reason": "API key not configured", "model": model_name}
        
        try:
            logger.info(f"Testing Cohere multi-turn conversation with {model_name} using LangGraph...")
            
            model = ChatCohere(
                api_key=self.config.COHERE_API_KEY,
                model=model_name,
                temperature=0
            )
            
            # Initialize the conversation with a system message
            messages = [SystemMessage(content=self.system_prompt)]
            
            # Create the conversation graph
            graph = create_conversation_graph(model)
            
            # Run the graph
            result = graph.invoke({
                "messages": messages,
                "current_turn": 0,
                "expected_content": self.expected_content,
                "model_name": model_name,
                "provider": "Cohere",
                "final_response": None
            })
            
            # Check if the expected content is in the final response
            final_response = result["final_response"] or ""
            contains_expected = self.expected_content in final_response
            
            return {
                "status": "success",
                "model": model_name,
                "contains_expected": contains_expected,
                "provider": "Cohere",
                "final_response": final_response
            }
        except Exception as e:
            logger.error(f"Cohere LangGraph multi-turn test failed for {model_name}: {str(e)}")
            return {
                "status": "error", 
                "error": str(e), 
                "provider": "Cohere",
                "model": model_name
            }
    
    async def test_cohere(self) -> List[Dict[str, Any]]:
        """Test multi-turn conversation capabilities of all Cohere models using LangGraph."""
        if not self.config.COHERE_API_KEY:
            return [{"status": "skipped", "reason": "API key not configured", "provider": "Cohere"}]
        
        results = []
        for model_name in get_cohere_models(self.config):
            result = await self.test_cohere_model(model_name)
            results.append(result)
        
        return results
    
    async def run_all_tests(self) -> Dict[str, List[Dict[str, Any]]]:
        """Run all multi-turn tests using LangGraph."""
        test_tasks = [
            self.test_openai(),
            self.test_anthropic(),
            self.test_google(),
            self.test_mistral(),
            self.test_fireworks(),
            self.test_cohere()
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
        logger.info("LANGGRAPH MULTI-TURN CONVERSATION TEST RESULTS")
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
    """Run the LangGraph multi-turn tests."""
    config = Config()
    tester = LangGraphMultiTurnTester(config)
    await tester.run_all_tests()
    tester.print_results()

if __name__ == "__main__":
    asyncio.run(main())