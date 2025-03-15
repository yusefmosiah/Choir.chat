# Yield Phase Requirements

## Overview

The Yield phase is responsible for process completion decisions and flow control. It determines whether to return a final response or continue processing through another cycle, and which phase to invoke next in the case of recursion.

## Core Responsibilities

1. Evaluate process completion criteria
2. Make recursion decisions
3. Select the next phase to execute (when recursing)
4. Format final output for user consumption
5. Maintain process continuity across cycles

## Temporal Focus: Process Completion

The Yield phase focuses on the completion state of the process. It assesses whether the current cycle has produced sufficient results or whether additional cycles would yield meaningful improvements.

## Input Specification

The Yield phase accepts:

1. **Primary Content**:

   - Filtered and integrated content from Understanding
   - Current cycle's outputs and state

2. **Metadata**:
   - Context management decisions
   - Recursion state (current cycle count)
   - Confidence scores and completion metrics
   - Processing telemetry from previous phases

## Output Specification

The Yield phase produces:

1. **Primary Content**:

   - Final response (if complete)
   - Continuation prompt (if recursing)

2. **Metadata**:
   - Recursion decision (continue/complete)
   - Target phase for next cycle (if continuing)
   - Updated recursion state
   - Rationale for recursion decision

## Processing Requirements

### Completion Evaluation

The Yield phase should evaluate completion based on:

- Convergence of results
- Answer confidence thresholds
- Maximum cycle limits
- Task completion indicators
- User satisfaction metrics

### Recursion Control

When deciding to continue, the Yield phase should:

- Select the most appropriate phase to invoke next
- Initialize proper state for the next cycle
- Formulate the continuation prompt
- Update recursion counters and state

### Next Phase Selection

The Yield phase can select any phase for recursion:

- `action`: For additional processing or tool use
- `experience`: For gathering more information
- `intention`: For refining goals
- `observation`: For storing additional insights
- `understanding`: For context refinement
- Default sequential flow is to `action` phase

### Final Response Formatting

When deciding to complete, the Yield phase should:

- Format the final response for user consumption
- Apply appropriate styling and structure
- Include confidence indicators
- Provide source attributions when relevant

### Error Handling

The Yield phase should handle:

- Recursion loop detection
- Maximum recursion limit enforcement
- Recovery from incomplete or failed phases
- Graceful termination when necessary

## Performance Requirements

1. **Decision Speed**: Complete recursion decisions within 1 second
2. **Recursion Limit**: Enforce configurable maximum recursive cycles
3. **Completion Accuracy**: >90% accuracy in determining when processing is complete
4. **Path Efficiency**: Select optimal next phase to minimize total cycles

## Implementation Constraints

1. Support both automatic and user-directed recursion control
2. Implement cycle counting and maximum limits
3. Maintain recursion history for loop detection
4. Support direct jumps to any phase in the PostChain

## Examples

### Recursion Decision Logic

```python
async def decide_recursion(
    current_state: Dict,
    cycle_count: int,
    max_cycles: int = 5
) -> YieldResult:
    """Determine whether to continue processing or terminate."""

    # Hard limit on recursion
    if cycle_count >= max_cycles:
        return YieldResult(
            continue_processing=False,
            final_response=current_state["content"],
            rationale="Maximum recursion depth reached"
        )

    # Check confidence threshold
    if current_state.get("confidence", 0) > 0.9:
        return YieldResult(
            continue_processing=False,
            final_response=current_state["content"],
            rationale="High confidence threshold met"
        )

    # Check if answer is still converging
    if cycle_count > 1 and calculate_convergence(current_state) < 0.1:
        return YieldResult(
            continue_processing=False,
            final_response=current_state["content"],
            rationale="Answer convergence reached"
        )

    # Decide which phase to invoke next
    if needs_more_information(current_state):
        next_phase = "experience"
        rationale = "Additional information required"
    elif needs_intention_clarification(current_state):
        next_phase = "intention"
        rationale = "Goal refinement needed"
    elif needs_additional_tools(current_state):
        next_phase = "action"
        rationale = "Tool execution required"
    else:
        # Default recursive flow
        next_phase = "action"
        rationale = "Standard recursive cycle"

    return YieldResult(
        continue_processing=True,
        next_phase=next_phase,
        continuation_prompt=generate_continuation_prompt(current_state, next_phase),
        rationale=rationale
    )
```

### Phase Selection Logic

```python
def select_next_phase(current_state: Dict) -> str:
    """Select the next phase to execute."""

    # Extract key indicators from state
    confidence = current_state.get("confidence", 0)
    info_sufficiency = current_state.get("information_sufficiency", 0)
    tool_indicators = current_state.get("needs_tools", False)

    # Decision tree for phase selection
    if info_sufficiency < 0.7:
        return "experience"  # Need more information
    elif "unclear_intent" in current_state.get("flags", []):
        return "intention"  # Need to clarify intent
    elif tool_indicators:
        return "action"  # Need to use tools
    elif len(current_state.get("context", [])) > 10:
        return "understanding"  # Need to clean up context
    else:
        return "action"  # Default recursive entry point
```

## Interaction with Other Phases

- **Receives from**: Understanding phase
- **Sends to**: Any phase (when recursing) or system (when complete)
- **Relationship**: Controls system flow and termination

## Success Criteria

1. Makes appropriate recursion decisions
2. Selects optimal next phase to minimize total cycles
3. Enforces recursion limits to prevent infinite loops
4. Produces properly formatted final responses
5. Maintains logical flow continuity across multiple cycles
