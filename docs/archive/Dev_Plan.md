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
docs_version: "0.3.0" # Post-alignment vision, Nov 2024

# Development Plan

VERSION dev_plan:
invariants: {
"Prior flow integrity",
"Effect coherence",
"Semantic recording"
}
assumptions: {
"Vector space stability",
"WebSocket reliability",
"LLM capability"
}
docs_version: "0.3.0" # Post-alignment vision, Nov 2024

## Current Status

### Backend Progress

- FastAPI application setup ✓
- WebSocket handler ready ✓
- Qdrant integration ✓
- Basic chorus cycle ✓
- Vector search working ✓

### Frontend Progress

- Three-panel layout ✓
- WebSocket connection ✓
- Message display ✓
- Step visualization ✓
- Prior panel structure ✓

## Implementation Schedule

### Phase 1: Prior Flow (Oct 29)

1. **Vector Search**

   ```python
   # Get n=80 priors
   priors = await search_similar(input, limit=80)
   ```

2. **Semantic Recording**

   ```python
   # Record in Qdrant
   await record_semantic_links(
     message=input,
     cited_priors=priors
   )
   ```

3. **Citation Integration**
   ```python
   # Natural citations
   return generate_response_with_citations(input, priors)
   ```

### Phase 2: Effect System (Oct 30)

1. **Effect Types**

   ```typescript
   type Effect = {
     type: "chorus_response" | "error" | "state_update";
     payload: {
       step: ChorusStep;
       content: string;
       priors?: Prior[]; // Only in EXPERIENCE
     };
   };
   ```

2. **Effect Accumulation**
   ```python
   effects = []
   while True:
       new_state, step_effects = await run_step(state, input)
       effects.extend(step_effects)
       if new_state.current_step == StepEnum.YIELD:
           break
   ```

### Phase 3: Step Processing (Oct 31)

1. **Step Prompts**

   - ACTION: Beginner's mind
   - EXPERIENCE: Context integration
   - INTENTION: Goal analysis
   - OBSERVATION: Semantic recording
   - UPDATE: Loop decision
   - YIELD: Citation integration

2. **State Transitions**
   ```python
   if step == UPDATE:
       if response["loop"]:
           next_step = ACTION
       else:
           next_step = YIELD
   else:
       next_step = steps[current_index + 1]
   ```

## Testing Strategy

1. **Prior Flow Tests**

   ```python
   def test_prior_flow():
       # Test vector search
       priors = search_similar(input)
       assert len(priors) == 80

       # Test semantic recording
       record_semantic_links(input, priors)
       verify_links_recorded()

       # Test citation integration
       response = generate_with_citations(input, priors)
       verify_citations_natural(response)
   ```

2. **Effect Tests**

   ```typescript
   test("effect accumulation", () => {
     const effects = [];
     // Run cycle
     expect(effects).toMatchPattern({
       experience: { priors: expect.arrayLength(80) },
       yield: { citations: expect.any(Array) },
     });
   });
   ```

3. **Step Tests**
   ```python
   def test_step_sequence():
       state = run_chorus_cycle(input)
       verify_step_sequence(state.effects)
       verify_prior_flow(state.effects)
       verify_semantic_recording(state)
   ```

## Implementation Notes

1. **Prior Flow**

   - Keep EXPERIENCE simple
   - No filtering until citations
   - Record semantic links
   - Natural integration

2. **Effect System**

   - Clean effect types
   - Proper accumulation
   - UI synchronization
   - Error handling

3. **Step Processing**
   - Clear step roles
   - Proper transitions
   - State coherence
   - Effect generation

Through this approach, we'll build a system that:

- Maintains prior flow integrity
- Preserves effect coherence
- Builds semantic knowledge
- Enables natural citations
