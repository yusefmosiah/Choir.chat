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
# Prior Flow Through Chorus Cycle

VERSION prior_flow:
invariants: {
"Prior coherence",
"Citation integrity",
"Semantic relevance"
}
assumptions: {
"Vector space stability",
"Prior availability",
"Citation validity"
}
docs_version: "0.2.1"

## Prior Flow Model

Each step has a specific role in prior handling:

```typescript
type PriorState = {
  experience: {
    retrieved: Prior[],     // Raw vector search results (n=80)
    used_in_synthesis: boolean // Whether prior informed response
  },
  intention: {
    selected: Prior[],      // Priors that support user's intent
    usage_context: string   // How they support the goal
  },
  observation: {
    cited_priors: Prior[], // Record which priors were cited
    semantic_links: {      // Store in Qdrant
      user_message: string,
      cited_messages: string[]
    }
  },
  yield: {
    response: string,      // Final response with inline citations
    footnotes: string[]    // Citation details
  }
}
```

## Step-by-Step Flow

1. **EXPERIENCE: Context Integration**
```python
async def run_experience(input: str, messages: List[Message]):
    # Get priors through vector search
    embedding = await get_embedding(input)
    priors = await self.database.search_similar(
        collection=self.config.MESSAGES_COLLECTION,
        query_vector=embedding,
        limit=80
    )

    # Have LLM use priors for context
    experience_prompt = """
    This is step 2 of the Chorus Cycle, Experience: Use these sources to help refine
    the response from step 1. Consider their insights but respond naturally.

    Respond in this JSON format:
    {
        "synthesis": "Your refined response incorporating the context",
        "key_insights": ["List of key insights from the sources"],
        "source_relevance": {
            "most_relevant": ["Source numbers that helped most"],
            "reasoning": "Why these sources were helpful"
        }
    }
    """

    # Return both synthesis and all priors - no filtering
    return result["synthesis"], priors
```

2. **INTENTION: Intent-Based Selection**
```python
async def run_intention(input: str, priors: List[Prior]):
    intention_prompt = """
    This is step 3 of the Chorus Cycle, Intention: Consider which sources would best
    support the user's goal or intent. Think about how they could strengthen the response.

    Respond in this JSON format:
    {
        "explicit_intent": "Direct goal or need",
        "implicit_intent": "Underlying aims or context",
        "selected_sources": ["Sources that support this intent"],
        "usage_context": "How these sources align with user's goal"
    }
    """
    return result
```

3. **OBSERVATION: Record Citations**
```python
async def run_observation(input: str, priors: List[Prior]):
    # Record semantic connections in Qdrant
    await record_semantic_links(
        user_message=input,
        cited_messages=priors
    )

    observation_prompt = """
    This is step 4 of the Chorus Cycle, Observation: Reflect on the analysis and record
    patterns in how sources were used.

    Respond in this JSON format:
    {
        "patterns": ["Observed patterns"],
        "context_analysis": "Situation analysis",
        "semantic_links": ["Recorded connections"]
    }
    """
    return result
```

4. **YIELD: Natural Citation Integration**
```python
async def run_yield(input: str, priors: List[Prior]):
    yield_prompt = """
    This is the final step of the Chorus Cycle, Yield: Generate a response that naturally
    integrates citations where they add value. Use markdown formatting:
    - [text](thread_id) for inline links
    - [^1] for footnotes
    - Include footnotes at end

    Respond in this JSON format:
    {
        "response": "Your response with natural citations",
        "footnotes": {
            "1": "First citation details",
            ...
        }
    }
    """
    return result
```

## Implementation Notes

1. **Prior Flow**
   - EXPERIENCE: Uses all priors for context
   - INTENTION: Selects based on user's goal
   - OBSERVATION: Records semantic links
   - YIELD: Natural citation integration

2. **Citation Quality**
   - Support user's intent
   - Flow naturally in text
   - Add clear value
   - Proper attribution

3. **Semantic Recording**
   - Store in Qdrant
   - Build knowledge graph
   - Enable future retrieval
   - Track usage patterns

The prior flow maintains semantic coherence while building a rich knowledge network.
