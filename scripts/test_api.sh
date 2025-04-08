#!/bin/bash

  # Simple script to test the /postchain/langchain streaming API endpoint using curl.

  # --- Configuration ---
  API_URL="http://localhost:8000/api/postchain/langchain" # Adjust if your API runs on a different port/host

  # --- Argument Handling ---
  if [ -z "$1" ]; then
    echo "Usage: $0 \"<your query>\" [thread_id]"
    echo "Example: $0 \"What is Choir?\""
    exit 1
  fi

  USER_QUERY="$1"
  # Use provided thread_id or generate a unique one using timestamp

  THREAD_ID=$(uuidgen)


  # --- Helper function to escape JSON strings ---
  escape_json_string() {
    echo "$1" | sed -e 's/\\/\\\\/g' -e 's/\"/\\\"/g' -e 's/\//\\\//g' -e 's/\t/\\t/g' -e 's/\n/\\n/g' -e 's/\r//g'
  }

  # Escape the user query for JSON payload
  ESCAPED_QUERY=$(escape_json_string "$USER_QUERY")

  # --- Prepare JSON Payload ---
  # No model_configs override in this basic test
  JSON_PAYLOAD=$(printf '{"user_query": "%s", "thread_id": "%s"}' "$ESCAPED_QUERY" "$THREAD_ID")

  # --- Output Information ---
  echo "====================================="
  echo " Sending request to PostChain API"
  echo "====================================="
  echo "Endpoint: $API_URL"
  echo "Thread ID: $THREAD_ID"
  echo "Query: $USER_QUERY"
  echo "Payload: $JSON_PAYLOAD"
  echo "-------------------------------------"
  echo " API Response Stream (SSE):"
  echo "-------------------------------------"

  # --- Execute curl command ---
  # -N, --no-buffer    Disable buffering of the output stream. Needed for SSE.
  # -X POST            Specify POST request method.
  # -H                 Headers for JSON content and accepting event stream.
  # -d                 Data payload (request body).
  curl -N -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: text/event-stream" \
    -d "$JSON_PAYLOAD" \
    "$API_URL"

  # Add a newline after the stream potentially ends for cleaner terminal output
  echo ""
  echo "-------------------------------------"
  echo " Stream finished."
  echo "====================================="
