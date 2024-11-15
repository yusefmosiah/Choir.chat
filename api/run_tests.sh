#!/bin/bash

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

