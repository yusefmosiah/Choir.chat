# Groq deepseek-r1-distill-llama-70b-specdec Test Report

**Test:** super_bowl_search
**Date:** 2025-03-07 16:48:06
**Duration:** 0.25 seconds
**Success:** ❌
**Error:** Response incomplete

## Metrics

- **total_tokens:** 0
- **prompt_tokens:** 0
- **completion_tokens:** 0
- **tool_calls:** 0
- **execution_time_ms:** 246

## Query

```
Who won Super Bowl LIX on February 9, 2025? Include the final score.
```

## Response

```
I encountered an error: Error code: 503 - {'error': {'message': 'Service Unavailable', 'type': 'internal_server_error'}}
```

## Event Timeline

- **16:48:06** - initialization
  - message: Configuration initialized
- **16:48:06** - model_setup
  - provider: groq
  - model: deepseek-r1-distill-llama-70b-specdec
- **16:48:06** - tool_creation
  - tool_name: web_search
- **16:48:06** - implementation
  - type: standard
  - message: Using standard LangGraph implementation
- **16:48:06** - conversation_creation
  - tools: ['web_search']
- **16:48:06** - query_submission
  - query: Who won Super Bowl LIX on February 9, 2025? Include the final score.
- **16:48:06** - graph_node
  - node: agent
  - message_count: 2
- **16:48:06** - response_received
  - response_length: 120
  - execution_time_ms: 244
- **16:48:06** - response_validation
  - has_correct_team: False
  - has_correct_score: False

## LangGraph Execution Path

- **16:48:06** - Node: agent
  - Messages: 0
