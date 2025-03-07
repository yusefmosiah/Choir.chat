# Fireworks qwen-qwq-32b Test Report

**Test:** super_bowl_search
**Date:** 2025-03-07 16:47:09
**Duration:** 0.48 seconds
**Success:** ❌
**Error:** Response incomplete

## Metrics

- **total_tokens:** 0
- **prompt_tokens:** 0
- **completion_tokens:** 0
- **tool_calls:** 0
- **execution_time_ms:** 481

## Query

```
Who won Super Bowl LIX on February 9, 2025? Include the final score.
```

## Response

```
I encountered an error: {'error': 'Model not found, inaccessible, and/or not deployed'}
```

## Event Timeline

- **16:47:09** - initialization
  - message: Configuration initialized
- **16:47:09** - model_setup
  - provider: fireworks
  - model: qwen-qwq-32b
- **16:47:09** - tool_creation
  - tool_name: web_search
- **16:47:09** - implementation
  - type: standard
  - message: Using standard LangGraph implementation
- **16:47:09** - conversation_creation
  - tools: ['web_search']
- **16:47:09** - query_submission
  - query: Who won Super Bowl LIX on February 9, 2025? Include the final score.
- **16:47:09** - graph_node
  - node: agent
  - message_count: 2
- **16:47:09** - response_received
  - response_length: 87
  - execution_time_ms: 479
- **16:47:09** - response_validation
  - has_correct_team: False
  - has_correct_score: False

## LangGraph Execution Path

- **16:47:09** - Node: agent
  - Messages: 0
