#!/bin/bash

# This script generates a search tools evaluation report for a single provider
# Usage: scripts/generate_single_provider_report.sh [provider]
# Example: scripts/generate_single_provider_report.sh anthropic

if [ $# -eq 0 ]; then
  echo "Usage: $0 provider_name"
  echo "Example: $0 anthropic"
  exit 1
fi

PROVIDER="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="reports/search_report_${PROVIDER}_${TIMESTAMP}.md"

echo "Generating search tools evaluation report for $PROVIDER..."

# Activate virtual environment if it exists
if [ -d "api/venv" ]; then
  source api/venv/bin/activate
fi

# Change to API directory
cd api

# Run the test script targeting the specific provider
python -m tests.tools.test_search_tools_report --provider "$PROVIDER" --output "../$OUTPUT_FILE"

echo "Report saved to: $OUTPUT_FILE"
