# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Effect System & State Transitions

VERSION effect_system:
invariants: {
"Effect completeness",
"State coherence",
"Message integrity"
}
assumptions: {
"WebSocket reliability",
"State synchronization",
"UI consistency"
}
docs_version: "0.2.1"

## Effect System Overview

Effects communicate step results and state changes to the frontend:

```typescript
type Effect = {
  type: "chorus_response" | "error" | "state_update";
  payload: {
    step: ChorusStep;        // Current step in AEIOU-Y
    content: string;         // Step response
    priors?: Prior[];       // Raw priors from EXPERIENCE
  };
}
```

### Effect Generation

Each step generates effects that accumulate:

```python
async def run_chorus_cycle(state: ChorusState, input: str):
    effects = []
    while True:
        # Run step and collect effects
        new_state, step_effects = await run_step(state, input)
        effects.extend(step_effects)

        # Break after YIELD
        if new_state.current_step == StepEnum.YIELD:
            break
    return effects, new_state
```

### Step-Specific Effects

1. **ACTION**
   ```typescript
   {
     step: "action",
     content: "Initial response",
     priors: undefined
   }
   ```

2. **EXPERIENCE**
   ```typescript
   {
     step: "experience",
     content: "Context-enriched response",
     priors: Prior[]  // All 80 priors
   }
   ```

3. **INTENTION**
   ```typescript
   {
     step: "intention",
     content: "Intent analysis",
     priors: undefined
   }
   ```

4. **OBSERVATION**
   ```typescript
   {
     step: "observation",
     content: "Observation analysis",
     priors: undefined
   }
   ```

5. **UPDATE**
   ```typescript
   {
     step: "update",
     content: { loop: boolean, reasoning: string },
     priors: undefined
   }
   ```

6. **YIELD**
   ```typescript
   {
     step: "yield",
     content: "Final response with citations",
     priors: undefined
   }
   ```

## Frontend Effect Handling

```typescript
function handleEffect(effect: Effect) {
  switch (effect.type) {
    case "chorus_response":
      // Update UI based on step
      switch (effect.payload.step) {
        case "experience":
          // Show priors in right panel
          updatePriorPanel(effect.payload.priors);
          break;
        case "yield":
          // Show final response with citations
          updateMessageFlow(effect.payload.content);
          break;
        default:
          // Show step response
          updateStepDisplay(effect.payload);
      }
      break;
    case "error":
      handleError(effect.payload);
      break;
  }
}
```

## Implementation Notes

1. **Effect Flow**
   - Steps generate effects
   - Effects accumulate in cycle
   - WebSocket transmits effects
   - Frontend processes in order

2. **State Management**
   - Effects drive UI updates
   - State changes are atomic
   - Errors are recoverable
   - UI stays synchronized

3. **Prior Handling**
   - EXPERIENCE includes all priors
   - No filtering in effects
   - Frontend shows all priors
   - Citations appear in YIELD

The Effect system maintains coherent state while enabling real-time updates and error recovery.
