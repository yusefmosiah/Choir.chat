#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'

# Check for required environment variables
if [ -z "$SUI_PRIVATE_KEY" ]; then
# Start the server in the background
echo "Starting server..."
uvicorn main:app --host 0.0.0.0 --port 8000 &
SERVER_PID=$!

# Wait for server to start
echo "Waiting for server to start..."
sleep 5

# Run the tests
echo "Running tests..."
pytest -v

# Kill the server
echo "Cleaning up..."
kill $SERVER_PID
