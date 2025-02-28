# Post Chain Specification

## Overview

This document outlines the evolution from the current "Chorus Cycle" to the new "Post Chain" architecture. Post Chain represents a more flexible, modular system that processes user inputs through a series of specialized AI model calls, each optimized for a specific task. The system maintains the original AEIOU-Y pattern while allowing for seamless addition of new phases like web search.

## Core Architecture

### Key Changes

- Replace LiteLLM with direct OpenAI client for more control
- Use OpenRouter instead of multiple API providers
- Implement a different model for each phase
- Add capability for new phases like web search
- Maintain consistent structured output formats across all phases

### Models & Phases

The Post Chain will utilize the following phases, with each potentially assigned a different model:

1. **Action** (A): Initial response to user input

   - Model: Lightweight, fast model (e.g., `anthropic/claude-3-5-haiku`)
   - Purpose: Generate quick initial response

2. **Experience** (E): Find and integrate relevant prior knowledge

   - Model: Context-aware model (e.g., `anthropic/claude-3-5-sonnet`)
   - Purpose: Retrieve and select relevant prior information

3. **Intention** (I): Analyze user intent and select relevant priors

   - Model: Reasoning-focused model (e.g., `openai/gpt-4o`)
   - Purpose: Understand user intent and determine which priors are most relevant

4. **Observation** (O): Identify patterns and insights

   - Model: Analytical model (e.g., `anthropic/claude-3-5-sonnet`)
   - Purpose: Generate insights about patterns in the conversation and priors

5. **Understanding** (U): Determine whether to yield or continue

   - Model: Lightweight decision model (e.g., `anthropic/claude-3-5-haiku`)
   - Purpose: Decide if the current information is sufficient to answer the query

6. **Yield** (Y): Generate final response

   - Model: High-quality output model (e.g., `anthropic/claude-3-5-sonnet`)
   - Purpose: Synthesize final response with citations and reasoning

7. **Web Search** (NEW): Perform web searches for additional information
   - Model: Integrated with search capabilities
   - Purpose: Gather real-time information from the web

## Technical Implementation

### OpenRouter Integration

The system will use the OpenAI client library to connect to OpenRouter:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="OPENROUTER_API_KEY",
    default_headers={
        "HTTP-Referer": "https://choir-collective.onrender.com",
        "X-Title": "Choir"
    }
)
```

### Structured Output Format

All phases will use a consistent schema pattern for structured outputs:

```python
def get_structured_response(model, messages, schema):
    return client.chat.completions.create(
        model=model,
        messages=messages,
        response_format={
            "type": "json_schema",
            "schema": schema
        }
    )
```

### Phase Schema Definitions

Each phase will have a specific JSON schema to ensure consistent outputs:

```python
ACTION_SCHEMA = {
    "type": "object",
    "properties": {
        "step": {"type": "string", "enum": ["action"]},
        "content": {"type": "string", "description": "The main response content"},
        "confidence": {"type": "number", "minimum": 0, "maximum": 1, "description": "Confidence score between 0 and 1"},
        "reasoning": {"type": "string", "description": "Reasoning behind the response"}
    },
    "required": ["step", "content", "confidence", "reasoning"]
}

# Similar schemas for other phases...
```

### Vector Database Integration

The experience phase will continue to use Qdrant for vector search:

```python
async def get_embedding(input_text, model):
    response = client.embeddings.create(
        model=model,
        input=input_text
    )
    return response.data[0].embedding

async def search_vectors(embedding, limit=40):
    # Qdrant search implementation
    # ...
```

### Web Search Integration

A new web search phase will be added:

```python
async def web_search(query):
    # Implementation of web search capability
    # ...
```

## Development Plan

### Phase 1: Core Framework

1. Create a Jupyter notebook implementation (`post_chain0.ipynb`)
2. Implement the basic AEIOU-Y phases with OpenRouter
3. Test with different models for each phase
4. Validate structured output schema

### Phase 2: Enhanced Capabilities

1. Add web search capability
2. Implement additional tools/functions
3. Optimize model selection
4. Enhance error handling

### Phase 3: Integration

1. Integrate with main application
2. Migrate existing threads
3. Implement client-side UI changes
4. Deploy to production

## Data Flow

```
User Query → Action → Experience → Intention → Observation → Understanding
                        ↑                           ↓
                    Vector DB               Continue or Yield
                                                   ↓
                                          (If needed) Web Search
                                                   ↓
                                             Final Response
```

## Next Steps

1. Create initial notebook implementation
2. Test with basic example queries
3. Benchmark performance with different models
4. Refine structured schemas
5. Implement web search capability
