#!/bin/bash

# API endpoint URL
API_URL="https://choir-chat.onrender.com/api/postchain/langchain"
# Generate a UUID for thread_id
THREAD_ID=$(uuidgen)
echo "THREAD_ID: $THREAD_ID"

echo "--- Turn 1: tell me about sqlite performance characteristics and scaling potential ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "Tell me about sqlite performance characteristics and scaling potential.", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"

echo "\n--- Turn 2: Research that with sources ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "research it with sources.", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"

echo "\n--- Turn 3: what did qdrant say? ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "What did Qdrant say?", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"

echo "\n--- Turn 4: ask for sources ---"
curl -N -X POST -H "Content-Type: application/json" -d '{"user_query": "What did the web search say?", "thread_id": "'"$THREAD_ID"'"}' "$API_URL"


  exit 1
