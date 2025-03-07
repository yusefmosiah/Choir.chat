#!/bin/bash

# Script to generate a quick search tools evaluation report with a Cohere model

# Change to the API directory
cd "$(dirname "$0")/../api"

# Activate virtual environment
source venv/bin/activate

# Run the report generator with the Cohere Command R7B model
python -c "
import asyncio
import sys
sys.path.append('.')
from tests.tools.test_search_tools_report import SearchToolsEvaluator
from app.config import Config
from app.langchain_utils import ModelConfig

async def main():
    print('Generating quick search tools evaluation report...')
    evaluator = SearchToolsEvaluator()

    # Find the Cohere model
    cohere_model = None
    for model in evaluator.models:
        if model.provider == 'cohere' and 'command-r7b' in model.model_name:
            cohere_model = model
            break

    if cohere_model:
        # Use only the Cohere model
        evaluator.models = [cohere_model]
        print(f'Using model: {cohere_model}')

        # Modify test queries to explicitly instruct the model to use search
        for query in evaluator.test_queries:
            query['query'] = f\"Please search the web to find the most accurate answer: {query['query']}\"

        await evaluator.evaluate_all()
        print(f'Report saved to: {evaluator.report_path}')
    else:
        print('Cohere Command R7B model not available! Check your API key and config.')

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
