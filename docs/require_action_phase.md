# Action Phase Requirements

## Overview

The Action phase is the initial entry point and recursive re-entry point for the PostChain. It is responsible for direct model calls and tool execution based on user input or previous cycle results.

## Core Responsibilities

1. Process immediate user input or recursive prompts
2. Execute simple model inference or tool operations
3. Format results for downstream consumption
4. Maintain minimal context focused on the current request

## Temporal Focus: The Immediate Present

The Action phase operates in the immediate present, with minimal historical context. It focuses on the current moment of engagement, either with user input or the current state of a recursive process.

## Input Specification

The Action phase accepts:

1. **Primary Content**:

   - Initial user input (first cycle)
   - Yield phase forwarded content (recursive cycles)

2. **Metadata**:
   - Recursion state (cycle count, origin)
   - Context management operations from prior cycles
   - Configuration parameters for model selection

## Output Specification

The Action phase produces:

1. **Primary Content**:

   - Direct model responses or tool execution results
   - Initial assessment of user input

2. **Metadata**:
   - Confidence scores
   - Context operations (minimal at this stage)
   - Processing telemetry

## Processing Requirements

### Model Selection

The Action phase should dynamically select appropriate models based on:

- Task complexity
- Required capabilities (e.g., tool use, code generation)
- Performance characteristics from the provider matrix

### Context Management

As the initial phase, Action should:

- Apply minimal context operations
- Format user input appropriately
- Include system prompts relevant to the current request
- Preserve user messages intact

### Error Handling

The Action phase should handle:

- Model unavailability by falling back to alternative providers
- Tool execution failures with appropriate error messages
- Context size limitations with truncation strategies

## Performance Requirements

1. **Latency**: The Action phase should complete within 2-3 seconds for simple requests
2. **Throughput**: Support concurrent processing of multiple threads
3. **Reliability**: Achieve 99.9% success rate for request handling

## Implementation Constraints

1. Use the provider matrix for model selection
2. Support both synchronous and streaming responses
3. Implement clean error boundaries
4. Log all operations for monitoring and debugging

## Examples

### Simple Model Call (action_0)

```python
async def action_0(input_text: str, context: List[Message] = None) -> ActionResult:
    """Execute a simple model inference without tools."""
    model = select_model_provider("action", {"tool_use": False})
    system_prompt = "You are a helpful assistant responding to user queries."

    return await action_agent.run(
        input_text,
        message_history=context,
        system_prompt=system_prompt
    )
```

### Tool-using Action (action_n)

```python
async def action_n(input_text: str, context: List[Message] = None, tools: List[Tool] = None) -> ActionResult:
    """Execute a model call with tool use capabilities."""
    model = select_model_provider("action", {"tool_use": True})
    system_prompt = "You are a helpful assistant with access to tools. Use them when appropriate."

    return await action_agent.run(
        input_text,
        message_history=context,
        system_prompt=system_prompt,
        tools=tools
    )
```

## Interaction with Other Phases

- **Receives from**: Yield phase (in recursive cycles) or system (initial input)
- **Sends to**: Experience phase (sequential flow)
- **Relationship**: Initiates each PostChain cycle

## Success Criteria

1. Correctly interprets user input or recursive prompts
2. Successfully executes model calls or tool operations
3. Provides responses within latency requirements
4. Correctly formats output for downstream consumption
5. Handles errors gracefully with appropriate fallbacks
