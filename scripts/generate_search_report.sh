#!/bin/bash

# Script to generate a comprehensive search tools evaluation report

# Change to the API directory
cd "$(dirname "$0")/../api"

# Activate virtual environment
source venv/bin/activate

# Run the report generator
python -c "
import asyncio
import sys
sys.path.append('.')
from tests.tools.test_search_tools_report import SearchToolsEvaluator

async def main():
    print('Generating search tools evaluation report...')
    evaluator = SearchToolsEvaluator()
    await evaluator.evaluate_all()
    print(f'Report saved to: {evaluator.report_path}')

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
