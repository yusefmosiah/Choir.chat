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

# Chorus Cycle Steps

VERSION chorus_steps:
invariants: {
"Step coherence",
"Prior flow",
"Effect accumulation"
}
assumptions: {
"LLM capability",
"Vector stability",
"WebSocket reliability"
}
docs_version: "0.3.0" # Post-alignment vision, Nov 2024

## Step Sequence

1. **ACTION**

```python
async def run_action(input: str):
    """
    Initial response with "beginner's mind".
    No priors, no context - pure response.
    """
    action_prompt = """
    This is step 1, Action: Provide an initial response with "beginner's mind".
    No context or priors - just respond naturally.

    JSON format:
    {
        "proposed_response": str,  // Initial response
        "confidence": float,       // Between 0 and 1
        "reasoning": str          // Why this response
    }
    """
    return response
```

2. **EXPERIENCE**

```python
async def run_experience(input: str):
    """
    Get n=80 priors through vector search.
    Use all priors for context enrichment.
    No filtering at this stage.
    """
    # Get priors
    priors = await search_similar(input, limit=80)

    experience_prompt = """
    This is step 2, Experience: Use these sources to enrich your response.
    Consider all sources but respond naturally.

    JSON format:
    {
        "synthesis": str,         // Enriched response
        "key_insights": List[str], // From sources
        "source_relevance": Dict   // Most helpful sources
    }
    """
    return synthesis, priors  # Return both
```

3. **INTENTION**

```python
async def run_intention(input: str):
    """
    Analyze in context of user's goal.
    Consider how priors support intent.
    No filtering - just analysis.
    """
    intention_prompt = """
    This is step 3, Intention: Consider how sources support user's goal.
    Analyze alignment with intent.

    JSON format:
    {
        "explicit_intent": str,    // Direct goal
        "implicit_intent": str,    // Underlying aims
        "confidence": float       // Between 0 and 1
    }
    """
    return analysis
```

4. **OBSERVATION**

```python
async def run_observation(input: str):
    """
    Record semantic links in Qdrant.
    Store which priors were cited.
    Build knowledge graph.
    """
    # Record links
    await record_semantic_links(input, cited_priors)

    observation_prompt = """
    This is step 4, Observation: Reflect on patterns and connections.
    Record semantic relationships.

    JSON format:
    {
        "patterns": List[str],     // Observed patterns
        "context_analysis": str,    // Situation analysis
        "semantic_links": List[str] // Recorded connections
    }
    """
    return observation
```

5. **UPDATE**

```python
async def run_update(input: str):
    """
    Decide whether to:
    - Loop back to ACTION
    - Proceed to YIELD
    """
    update_prompt = """
    This is step 5, Update: Decide whether to loop or proceed.
    Consider completeness and confidence.

    JSON format:
    {
        "loop": bool,             // True to loop
        "reasoning": str,         // Why this decision
        "confidence": float,      // Between 0 and 1
        "insights": List[str]     // Key realizations
    }
    """
    return decision
```

6. **YIELD**

```python
async def run_yield(input: str):
    """
    Generate final response.
    Integrate citations naturally.
    Use markdown formatting.
    """
    yield_prompt = """
    This is step 6, Yield: Generate final response with citations.
    Integrate sources naturally.

    JSON format:
    {
        "response": str,          // Final response
        "footnotes": Dict[str],   // Citation details
        "confidence": float      // Between 0 and 1
    }
    """
    return response
```

## Effect Generation

Each step generates effects:

```python
Effect = {
    "type": "chorus_response",
    "payload": {
        "step": ChorusStep,
        "content": str,
        "priors": List[Prior]  # Only in EXPERIENCE
    }
}
```

## Prior Flow

1. EXPERIENCE gets priors (n=80)
2. INTENTION analyzes for user goal
3. OBSERVATION records in Qdrant
4. YIELD integrates as citations

## Implementation Notes

1. **Step Independence**

   - Each step has clear role
   - No filtering in EXPERIENCE
   - INTENTION aligns with purpose
   - OBSERVATION builds network
   - YIELD handles presentation

2. **Prior Handling**

   - Wide initial search
   - Purpose-driven analysis
   - Semantic recording
   - Natural integration

3. **State Management**
   - Clear transitions
   - Effect accumulation
   - Error recovery
   - UI synchronization

The Chorus Cycle creates a natural flow from initial response through context integration to final synthesis.
