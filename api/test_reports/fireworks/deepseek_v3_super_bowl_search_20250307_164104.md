# Fireworks deepseek-v3 Test Report

**Test:** super_bowl_search
**Date:** 2025-03-07 16:41:04
**Duration:** 2.19 seconds
**Success:** ❌
**Error:** Response incomplete

## Metrics

- **total_tokens:** 0
- **prompt_tokens:** 0
- **completion_tokens:** 0
- **tool_calls:** 0
- **execution_time_ms:** 2188

## Query

```
Who won Super Bowl LIX on February 9, 2025? Include the final score.
```

## Response

```
Super Bowl LIX is scheduled to take place on February 9, 2025. As of today, March 7, 2025, the game has not yet occurred. The teams that will compete and the final score are not known at this time. Please check back after the event for the results.
```

## Event Timeline

- **16:41:04** - initialization
  - message: Configuration initialized
- **16:41:04** - model_setup
  - provider: fireworks
  - model: deepseek-v3
- **16:41:04** - tool_creation
  - tool_name: web_search
- **16:41:04** - implementation
  - type: standard
  - message: Using standard LangGraph implementation
- **16:41:04** - conversation_creation
  - tools: ['web_search']
- **16:41:04** - query_submission
  - query: Who won Super Bowl LIX on February 9, 2025? Include the final score.
- **16:41:04** - graph_node
  - node: agent
  - message_count: 2
- **16:41:06** - response_received
  - response_length: 248
  - execution_time_ms: 2186
- **16:41:06** - response_validation
  - has_correct_team: False
  - has_correct_score: False

## LangGraph Execution Path

- **16:41:04** - Node: agent
  - Messages: 0
