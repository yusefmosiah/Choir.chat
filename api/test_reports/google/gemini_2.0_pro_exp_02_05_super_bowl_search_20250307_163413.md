# Google gemini-2.0-pro-exp-02-05 Test Report

**Test:** super_bowl_search
**Date:** 2025-03-07 16:34:13
**Duration:** 4.02 seconds
**Success:** ❌
**Error:** Response incomplete

## Metrics

- **total_tokens:** 0
- **prompt_tokens:** 0
- **completion_tokens:** 0
- **tool_calls:** 0
- **execution_time_ms:** 4020

## Query

```
Who won Super Bowl LIX on February 9, 2025? Include the final score.
```

## Response

```
I encountered an error: 500 Internal error occurred.
```

## Event Timeline

- **16:34:13** - initialization
  - message: Configuration initialized
- **16:34:13** - model_setup
  - provider: google
  - model: gemini-2.0-pro-exp-02-05
- **16:34:13** - tool_creation
  - tool_name: web_search
- **16:34:13** - implementation
  - type: standard
  - message: Using standard LangGraph implementation
- **16:34:13** - conversation_creation
  - tools: ['web_search']
- **16:34:13** - query_submission
  - query: Who won Super Bowl LIX on February 9, 2025? Include the final score.
- **16:34:13** - graph_node
  - node: agent
  - message_count: 2
- **16:34:17** - response_received
  - response_length: 52
  - execution_time_ms: 4010
- **16:34:17** - response_validation
  - has_correct_team: False
  - has_correct_score: False

## LangGraph Execution Path

- **16:34:13** - Node: agent
  - Messages: 0
