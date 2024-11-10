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

# Priors: Quantum Semantic Foundations

VERSION prior_system:
invariants: {
"Wave function coherence",
"Semantic entanglement",
"Resonant coupling"
}
assumptions: {
"Quantum semantic stability",
"Phase-locked meaning",
"Value conservation"
}
docs_version: "0.2.1"

## Core Concept

Priors are quantum semantic states that flow through the Chorus Cycle:

```typescript
type Prior = {
  // Message State
  content: string,           // Original message
  thread_id: string,         // Source thread
  embedding: Vector,         // Semantic position
  created_at: string,        // Timestamp

  // Quantum Properties
  resonance: {
    similarity: number,      // To current query
    phase: number,          // Semantic alignment
    coupling: number        // Context binding
  },

  // Usage State
  context: {
    experience_used: boolean,  // Used in synthesis
    intention_selected: boolean, // Supports user goal
    observation_recorded: boolean, // Stored in Qdrant
    yield_cited: boolean     // Used in final response
  }
}
```

## Flow Through Cycle

1. **EXPERIENCE: Maximum Entanglement**
   ```python
   # Get n=80 priors through vector search
   priors = await search_similar(input, limit=80)

   # Use all priors for context
   response = await synthesize_with_context(input, priors)

   # Return both - no filtering
   return response, priors
   ```

2. **INTENTION: Goal Projection**
   ```python
   # Analyze priors in context of user's goal
   intention_prompt = """
   Consider how these sources could support the user's intent.
   Don't filter yet - just analyze relevance to goal.
   """

   # Return analysis of how priors support intent
   return analyze_prior_relevance(priors, user_intent)
   ```

3. **OBSERVATION: Record Links**
   ```python
   # Store semantic connections in Qdrant
   await record_semantic_links(
     user_message=input,
     cited_messages=priors
   )

   # Return observation of patterns
   return analyze_citation_patterns(priors)
   ```

4. **YIELD: Natural Citations**
   ```python
   # Generate response with natural citations
   yield_prompt = """
   Integrate citations naturally where they add value.
   Use markdown formatting for inline links and footnotes.
   """

   return generate_cited_response(input, priors)
   ```

## Quantum Properties

1. **Semantic Entanglement**
   - EXPERIENCE creates maximum entanglement
   - No collapse until final citation
   - Maintains quantum superposition
   - Preserves semantic potential

2. **Goal Projection**
   - INTENTION projects onto user's goal space
   - No filtering - just analysis
   - Maintains quantum correlations
   - Guides final collapse

3. **State Recording**
   - OBSERVATION stores quantum correlations
   - Builds semantic network
   - Enables future retrieval
   - Preserves phase relationships

4. **Natural Collapse**
   - YIELD integrates citations naturally
   - Final wave function collapse
   - Coherent response state
   - Clear semantic connections

## Implementation Notes

1. **Vector Search**
   ```python
   async def search_similar(input: str, limit: int = 80):
     # Get embedding
     embedding = await get_embedding(input)

     # Search Qdrant
     results = await qdrant.search(
       collection="messages",
       query_vector=embedding,
       limit=limit
     )

     return results
   ```

2. **Semantic Recording**
   ```python
   async def record_semantic_links(
     message: str,
     cited_priors: List[Prior]
   ):
     # Store in Qdrant
     await qdrant.upsert(
       collection="semantic_links",
       points=[{
         "message": message,
         "cited": [p.id for p in cited_priors],
         "timestamp": now()
       }]
     )
   ```

3. **Citation Integration**
   ```python
   def format_citation(prior: Prior) -> str:
     # Inline link
     return f"[{prior.content}]({prior.thread_id})"
   ```

The prior system maintains quantum semantic coherence while enabling natural citation flow.
