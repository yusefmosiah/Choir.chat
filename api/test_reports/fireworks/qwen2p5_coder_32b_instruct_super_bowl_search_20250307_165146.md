# Fireworks qwen2p5-coder-32b-instruct Test Report

**Test:** super_bowl_search
**Date:** 2025-03-07 16:51:46
**Duration:** 1.13 seconds
**Success:** ❌
**Error:** Response incomplete

## Metrics

- **total_tokens:** 0
- **prompt_tokens:** 0
- **completion_tokens:** 0
- **tool_calls:** 0
- **execution_time_ms:** 1125

## Query

```
Who won Super Bowl LIX on February 9, 2025? Include the final score.
```

## Response

```
{"name": "web_search", "arguments": {"query": "Super Bowl LIX winner and final score February 9, 2025"}}
```

## Event Timeline

- **16:51:46** - initialization
  - message: Configuration initialized
- **16:51:46** - model_setup
  - provider: fireworks
  - model: qwen2p5-coder-32b-instruct
- **16:51:46** - tool_creation
  - tool_name: web_search
- **16:51:46** - implementation
  - type: standard
  - message: Using standard LangGraph implementation
- **16:51:46** - conversation_creation
  - tools: ['web_search']
- **16:51:46** - query_submission
  - query: Who won Super Bowl LIX on February 9, 2025? Include the final score.
- **16:51:46** - graph_node
  - node: agent
  - message_count: 2
- **16:51:47** - response_received
  - response_length: 104
  - execution_time_ms: 1122
- **16:51:47** - response_validation
  - has_correct_team: False
  - has_correct_score: False

## LangGraph Execution Path

- **16:51:46** - Node: agent
  - Messages: 0
