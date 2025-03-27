#!/bin/bash

# API endpoint URL
# API_URL="http://localhost:8000/api/postchain/langchain"
API_URL="https://choir-chat.onrender.com/api/postchain/langchain"
# Generate a UUID for thread_id
THREAD_ID=$(uuidgen)
echo "THREAD_ID: $THREAD_ID"

# --- Turn 1: Set magic number ---
echo "--- Turn 1: Setting magic number ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "The magic number is 137. Please remember it.", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"

# --- Turn 2: Ask about fractional quantum physics ---
echo "\n--- Turn 2: Asking about fractional quantum physics ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "Explain fractional quantum physics.", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"

# --- Turn 3: Ask for magic number ---
echo "\n--- Turn 3: Asking for magic number ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "What was the magic number I told you?", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"


  exit 1
