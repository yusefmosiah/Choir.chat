#!/bin/bash

# Script to generate separate search tools evaluation reports for each provider

# Change to the API directory
cd "$(dirname "$0")/../api"

# Activate virtual environment
source venv/bin/activate

# Run the report generator for each provider separately
python -c "
import asyncio
import sys
sys.path.append('.')
from tests.tools.test_search_tools_report import SearchToolsEvaluator
from app.config import Config
from app.langchain_utils import ModelConfig

async def main():
    print('Generating search tools evaluation reports for each provider...')
    evaluator = SearchToolsEvaluator()

    # Get all unique providers
    providers = set(model.provider for model in evaluator.models)

    # Remove OpenAI provider if present (as requested)
    if 'openai' in providers:
        providers.remove('openai')

    print(f'Found {len(providers)} providers: {sorted(providers)}')

    # Process each provider
    for provider in sorted(providers):
        try:
            # Get models for this provider
            provider_models = [model for model in evaluator.models if model.provider == provider]

            if not provider_models:
                print(f'No models available for provider: {provider}')
                continue

            print(f'\nGenerating report for {provider} with {len(provider_models)} models...')

            # Modify test queries to explicitly instruct models to use search
            for query in evaluator.test_queries:
                query['query'] = f\"Please search the web to find the most accurate answer: {query['query']}\"

            # Create a new evaluator with just this provider's models
            provider_evaluator = SearchToolsEvaluator()
            provider_evaluator.models = provider_models
            provider_evaluator.report_path = provider_evaluator.reports_dir / f\"search_report_{provider}_{provider_evaluator.timestamp}.md\"

            await provider_evaluator.evaluate_all()
            print(f'Report saved to: {provider_evaluator.report_path}')
        except Exception as e:
            print(f'Error generating report for {provider}: {str(e)}')

    print('\nAll provider reports completed!')

if __name__ == '__main__':
    asyncio.run(main())
"

# Open the reports directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open ../reports
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open ../reports &> /dev/null
fi
