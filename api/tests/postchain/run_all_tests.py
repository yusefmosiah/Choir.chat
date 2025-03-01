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
    structured_results = await structured_tester.run_all_tests()
    structured_tester.print_results()
    
    # Test multi-turn conversations
    logger.info("\n\n" + "="*50)
    logger.info("TESTING MULTI-TURN CONVERSATIONS")
    logger.info("="*50)
    multiturn_tester = MultiTurnTester(config)
    multiturn_results = await multiturn_tester.run_all_tests()
    multiturn_tester.print_results()
    
    # Print overall summary
    logger.info("\n\n" + "="*50)
    logger.info("OVERALL TEST SUMMARY")
    logger.info("="*50)
    
    # Count providers with successful API connectivity
    api_success = sum(1 for r in provider_tester.results.values() if r.get("status") == "success")
    api_total = len(provider_tester.results)
    
    # Count models with successful structured output
    structured_success = sum(sum(1 for r in results if r.get("status") == "success") for results in structured_tester.results.values())
    structured_parse_error = sum(sum(1 for r in results if r.get("status") == "parse_error") for results in structured_tester.results.values())
    structured_total = sum(len(results) for results in structured_tester.results.values())
    
    # Count models with successful multi-turn conversations
    multiturn_success = sum(sum(1 for r in results if r.get("status") == "success") for results in multiturn_tester.results.values())
    multiturn_context = sum(sum(1 for r in results if r.get("status") == "success" and r.get("context_maintained", False)) for results in multiturn_tester.results.values())
    multiturn_total = sum(len(results) for results in multiturn_tester.results.values())
    
    logger.info(f"API Connectivity: {api_success}/{api_total} providers successful")
    logger.info(f"Structured Output: {structured_success}/{structured_total} models successful, {structured_parse_error}/{structured_total} parse errors")
    logger.info(f"Multi-turn Conversations: {multiturn_success}/{multiturn_total} models successful, {multiturn_context}/{multiturn_success} maintained context")
    
    # Print provider-specific summary
    logger.info("\nProvider-specific summary:")
    all_providers = set(provider_tester.results.keys()) | set(structured_tester.results.keys()) | set(multiturn_tester.results.keys())
    
    for provider in all_providers:
        api_status_provider = provider_tester.results.get(provider, [])
        structured_status_provider = structured_tester.results.get(provider, [])
        multiturn_status_provider = multiturn_tester.results.get(provider, [])
        
        api_success_provider = sum(1 for r in api_status_provider if r.get("status") == "success")
        api_total_provider = len(api_status_provider)
        structured_success_provider = sum(1 for r in structured_status_provider if r.get("status") == "success")
        structured_parse_error_provider = sum(1 for r in structured_status_provider if r.get("status") == "parse_error")
        structured_total_provider = len(structured_status_provider)
        multiturn_success_provider = sum(1 for r in multiturn_status_provider if r.get("status") == "success")
        multiturn_context_provider = sum(1 for r in multiturn_status_provider if r.get("status") == "success" and r.get("context_maintained", False))
        multiturn_total_provider = len(multiturn_status_provider)

        api_status = f"{api_success_provider}/{api_total_provider} models successful" if api_total_provider > 0 else "Not tested"
        structured_status = f"{structured_success_provider}/{structured_total_provider} models successful, {structured_parse_error_provider}/{structured_total_provider} parse errors" if structured_total_provider > 0 else "Not tested"
        multiturn_status = f"{multiturn_success_provider}/{multiturn_total_provider} models successful, {multiturn_context_provider}/{multiturn_success_provider} maintained context" if multiturn_total_provider > 0 else "Not tested"

        api_icon = "✅" if api_success_provider == api_total_provider and api_total_provider > 0 else "⚠️" if api_total_provider > 0 else " "
        structured_icon = "✅" if structured_success_provider == structured_total_provider and structured_total_provider > 0 else "⚠️" if structured_total_provider > 0 else " "
        multiturn_icon = "✅" if multiturn_success_provider == multiturn_total_provider and multiturn_total_provider > 0 else "⚠️" if multiturn_total_provider > 0 else " "
        context_icon = "✅" if multiturn_context_provider == multiturn_success_provider and multiturn_success_provider > 0 else "⚠️" if multiturn_success_provider > 0 else " "
        
        logger.info(f"{provider}:")
        logger.info(f"  {api_icon} API Connectivity: {api_status}")
        logger.info(f"  {structured_icon} Structured Output: {structured_status}")
        logger.info(f"  {multiturn_icon} Multi-turn Conversation: {multiturn_status}")
        logger.info(f"  {context_icon} Context Maintained: {multiturn_status if multiturn_status == 'Not tested' else f'{multiturn_context_provider}/{multiturn_success_provider} maintained context'}")
    
    logger.info("="*50)

if __name__ == "__main__":
    asyncio.run(run_all_tests())