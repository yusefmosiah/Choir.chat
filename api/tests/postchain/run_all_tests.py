"""
Script to run all PostChain tests.
This will test API connectivity, structured output, and multi-turn conversations.
"""

import asyncio
import logging
from typing import Dict, Any, List

from test_providers import ProviderTester
from test_structured_output import StructuredOutputTester
from test_multiturn import MultiTurnTester

from app.config import Config

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def run_all_tests():
    """Run all PostChain tests."""
    config = Config()
    
    # Test API connectivity
    logger.info("\n\n" + "="*50)
    logger.info("TESTING API CONNECTIVITY")
    logger.info("="*50)
    provider_tester = ProviderTester(config)
    await provider_tester.run_all_tests()
    provider_tester.print_results()
    
    # Test structured output
    logger.info("\n\n" + "="*50)
    logger.info("TESTING STRUCTURED OUTPUT")
    logger.info("="*50)
    structured_tester = StructuredOutputTester(config)
    await structured_tester.run_all_tests()
    structured_tester.print_results()
    
    # Test multi-turn conversations
    logger.info("\n\n" + "="*50)
    logger.info("TESTING MULTI-TURN CONVERSATIONS")
    logger.info("="*50)
    multiturn_tester = MultiTurnTester(config)
    await multiturn_tester.run_all_tests()
    multiturn_tester.print_results()
    
    # Print overall summary
    logger.info("\n\n" + "="*50)
    logger.info("OVERALL TEST SUMMARY")
    logger.info("="*50)
    
    # Count providers with successful API connectivity
    api_success = sum(1 for r in provider_tester.results.values() if r.get("status") == "success")
    api_total = len(provider_tester.results)
    
    # Count providers with successful structured output
    structured_success = sum(1 for r in structured_tester.results.values() if r.get("status") == "success")
    structured_total = len(structured_tester.results)
    
    # Count providers with successful multi-turn conversations
    multiturn_success = sum(1 for r in multiturn_tester.results.values() if r.get("status") == "success")
    multiturn_context = sum(1 for r in multiturn_tester.results.values() if r.get("status") == "success" and r.get("context_maintained", False))
    multiturn_total = len(multiturn_tester.results)
    
    logger.info(f"API Connectivity: {api_success}/{api_total} providers successful")
    logger.info(f"Structured Output: {structured_success}/{structured_total} providers successful")
    logger.info(f"Multi-turn Conversations: {multiturn_success}/{multiturn_total} providers successful, {multiturn_context}/{multiturn_total} maintained context")
    
    # Print provider-specific summary
    logger.info("\nProvider-specific summary:")
    all_providers = set(provider_tester.results.keys()) | set(structured_tester.results.keys()) | set(multiturn_tester.results.keys())
    
    for provider in all_providers:
        api_status = provider_tester.results.get(provider, {}).get("status", "not tested")
        structured_status = structured_tester.results.get(provider, {}).get("status", "not tested")
        multiturn_status = multiturn_tester.results.get(provider, {}).get("status", "not tested")
        context_maintained = multiturn_tester.results.get(provider, {}).get("context_maintained", False)
        
        api_icon = "✅" if api_status == "success" else "❌" if api_status == "error" else "⚠️"
        structured_icon = "✅" if structured_status == "success" else "❌" if structured_status == "error" else "⚠️"
        multiturn_icon = "✅" if multiturn_status == "success" else "❌" if multiturn_status == "error" else "⚠️"
        context_icon = "✅" if context_maintained else "❌" if multiturn_status == "success" else "⚠️"
        
        logger.info(f"{provider}:")
        logger.info(f"  {api_icon} API Connectivity: {api_status}")
        logger.info(f"  {structured_icon} Structured Output: {structured_status}")
        logger.info(f"  {multiturn_icon} Multi-turn Conversation: {multiturn_status}")
        logger.info(f"  {context_icon} Context Maintained: {str(context_maintained) if multiturn_status == 'success' else 'N/A'}")
    
    logger.info("="*50)

if __name__ == "__main__":
    asyncio.run(run_all_tests())