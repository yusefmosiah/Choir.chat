# PostChain LangGraph Implementation Plan

This document outlines our iterative approach to implementing the full PostChain (AEIOU-Y) using LangGraph. We'll build on the existing Action+Experience implementation, gradually adding features while maintaining a working system at each stage.

## 📚 Key Reference Files

Before beginning implementation, familiarize yourself with these files:

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/postchain/postchain_graph.py` - Rough sketch of the final AEIOU-Y implementation
- `api/app/routers/postchain.py` - FastAPI router handling PostChain endpoints
- `api/app/langchain_utils.py` - Utility functions for working with language models
- `api/app/config.py` - Configuration settings including model identifiers
- `docs/plan_postchain_migration_checklist.md` - Original migration plan

## 🎯 Overall Strategy

We'll follow an incremental approach with these key phases:

1. **Foundation**: Add proper memory management and multiturn support to existing graph
2. **Model Flexibility**: Implement model-agnostic architecture with fallback mechanisms
3. **Integration**: Connect with tools and external systems, prioritizing search results in the Experience phase
4. **Expansion**: Add remaining AEIOU-Y phases one by one
5. **Refinement**: Optimize performance and UX

Each milestone will result in a working system that can be tested with our SwiftUI frontend.

## 📋 Implementation Checklist

### Phase 1: Foundation (Memory & Multiturn)

- [ ] **Structured State Management**

  - [ ] Create `PostChainState` Pydantic model for type safety in `api/app/postchain/schemas/state.py`
  - [ ] Define clear schema for conversation history
  - [ ] Implement phase metadata tracking

- [ ] **Memory Management**

  - [ ] Integrate LangGraph's `MemorySaver` for persistence
  - [ ] Implement conversation retrieval for continuing threads
  - [ ] Add checkpointing for state recovery

- [ ] **Multiturn Support**

  - [ ] Modify handlers to properly maintain conversation context
  - [ ] Implement proper message threading
  - [ ] Add conversation history summarization for context window management

- [ ] **Interrupt Handling**
  - [ ] Implement proper LangGraph interrupt handlers
  - [ ] Add graceful cancellation across all phases
  - [ ] Create appropriate user feedback for interruptions

### Phase 2: Model Flexibility & Resilience

- [ ] **Model-Agnostic Architecture**

  - [ ] Abstract model selection from node implementation in `api/app/postchain/simple_graph.py`
  - [ ] Create model capability detection (tool-compatible vs non-tool models)
  - [ ] Implement phase-specific model selection

- [ ] **Fallback & Retry Mechanisms**

  - [ ] Implement automatic model fallback on failure
  - [ ] Add retry policy with exponential backoff
  - [ ] Create graceful degradation for when preferred models are unavailable

- [ ] **Model Error Handling**
  - [ ] Implement comprehensive error detection for different providers
  - [ ] Add model-specific formatting for prompts
  - [ ] Create robust recovery from failed model invocations

### Phase 3: Tool & External Integration (Prioritized)

- [ ] **Tool Integration for Experience Phase**

  - [ ] Add Qdrant vectorstore connection (see `api/app/tools/qdrant.py`)
  - [ ] Implement web search tools (see `api/app/tools/brave_search.py`, `api/app/tools/tavily_search.py`)
  - [ ] Create search result formatting for Experience phase
  - [ ] Add calculator and other specialized tools (see `api/app/tools/calculator.py`)

- [ ] **API Integration for SwiftUI Client**

  - [ ] Add proper streaming for search results in `api/app/routers/postchain.py`
  - [ ] Implement client event handling for displaying search data
  - [ ] Create UI components for displaying search results in Experience phase
  - [ ] Add deep linking to priors and web results

### Phase 4: AEIOU-Y Expansion (After Tool Integration)

- [ ] **Intention Phase**

  - [ ] Implement `intention_node` handler (see example in `api/app/postchain/postchain_graph.py`)
  - [ ] Add user intent alignment logic
  - [ ] Create conditional routing based on intent

- [ ] **Observation Phase**

  - [ ] Implement `observation_node` handler (see example in `api/app/postchain/postchain_graph.py`)
  - [ ] Add semantic connections recording
  - [ ] Integrate context building

- [ ] **Understanding Phase**

  - [ ] Implement `understanding_node` handler (see example in `api/app/postchain/postchain_graph.py`)
  - [ ] Add continuation decision logic
  - [ ] Create conditional routing to yield or restart

- [ ] **Yield Phase**
  - [ ] Implement `yield_node` handler (see example in `api/app/postchain/postchain_graph.py`)
  - [ ] Add final response formatting
  - [ ] Implement state cleanup

### Phase 5: Refinement & Optimization

- [ ] **Context Management**

  - [ ] Implement manual context compaction
  - [ ] Create automatic compaction tool
  - [ ] Add memory prioritization

- [ ] **Performance Optimization**

  - [ ] Implement parallel processing where appropriate
  - [ ] Add caching for repeated operations
  - [ ] Optimize token usage

- [ ] **Error Handling & Recovery**
  - [ ] Implement comprehensive error states
  - [ ] Add automatic retry logic
  - [ ] Create graceful degradation paths

## 🛠️ Technical Details

### Environment Setup

Make sure you're working in the correct environment:

```bash
# From project root
cd api
source venv/bin/activate  # IMPORTANT: Always use existing venv
```

### Required Dependencies

All dependencies should be in the existing `requirements.txt`, but key ones include:

## 🔄 Testing Strategy

Our primary testing harness will be the SwiftUI frontend:

1. **SwiftUI Frontend Testing**: Use the actual UI to validate functionality and user experience
2. **Backend API Testing**: Test endpoints with the actual frontend client using Choir iOS app
3. **Manual Testing**: Validate full conversation flows with real user scenarios
4. **API Testing**: You can test directly with curl or Postman:

```bash
# Test simple endpoint with curl
curl -X POST http://localhost:8000/postchain/simple \
  -H "Content-Type: application/json" \
  -d '{"user_query": "Tell me about quantum computing", "stream": true}'
```

5. **Run Python Tests**: Use the existing test framework when needed:

```bash
# From api directory
python -m tests.postchain.test_simple_multimodel
```

## 📊 Success Criteria

Each phase will be considered complete when:

1. The feature works correctly in the SwiftUI frontend (Choir iOS app)
2. Stream processing displays results appropriately
3. User experience meets expectations
4. Performance is acceptable on real devices
5. System gracefully handles model failures and provider outages

## 📅 Implementation Order

1. Structured state & memory management
2. Multiturn support
3. Interrupt handling
4. Model flexibility & fallback mechanisms
5. Web search & Qdrant integration with Experience phase
6. UI components for displaying search results
7. Intention phase
8. Observation phase
9. Understanding phase
10. Yield phase
11. Performance optimization

This approach ensures we have a robust, flexible system that can work with any model and gracefully handle failures before we expand to additional phases.

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Run tests from the api directory** - This ensures correct import paths
3. **Maintain backwards compatibility** - Existing endpoints must continue to work
4. **Gradual deployment** - Each phase should be deployable independently
5. **Error handling is critical** - The system must gracefully handle any failure
6. **Log extensively** - Use the logger to track execution flow for debugging

### State Management

We'll use Pydantic models for state management:

```python
# File: api/app/postchain/schemas/state.py
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from langchain_core.messages import BaseMessage

class PostChainState(BaseModel):
    """Structured state model for PostChain."""
    messages: List[BaseMessage] = Field(default_factory=list)
    current_phase: str = Field("action")
    thread_id: Optional[str] = Field(None)
    phase_outputs: Dict[str, str] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    tools_used: List[str] = Field(default_factory=list)
    search_results: List[Dict[str, Any]] = Field(default_factory=list)
    model_attempts: Dict[str, List[str]] = Field(default_factory=dict)
```

### Model Fallback Implementation

For model flexibility and fallback:

```python
# Add to api/app/postchain/simple_graph.py
from app.langchain_utils import post_llm, is_tool_compatible, ModelConfig
from langchain.graph.state import RetryPolicy

async def try_with_models(
    phase: str,
    messages: List[BaseMessage],
    models: List[ModelConfig],
    config: Config,
    retry_policy: Optional[RetryPolicy] = None
) -> Tuple[Optional[str], Optional[str], List[str]]:
    """
    Try a phase with multiple models, falling back on failure.

    Args:
        phase: The phase name
        messages: Messages to send to the model
        models: Prioritized list of models to try
        config: App configuration
        retry_policy: Optional retry policy

    Returns:
        Tuple of (content, model_used, errors)
    """
    errors = []

    for model in models:
        try:
            # Specific handling for tool-requiring phases
            if phase == "experience" and requires_tools(phase):
                if not is_tool_compatible(str(model), config):
                    errors.append(f"Model {model} not compatible with tools, skipping")
                    continue

            response = await post_llm(str(model), messages, config)
            if response and response.content:
                return response.content, str(model), errors
        except Exception as e:
            errors.append(f"Error with {model}: {str(e)}")

    return None, None, errors
```

### Graph Structure

The complete graph will have this structure:

```
[START] → [action] → [experience] → [intention] → [observation] → [understanding] → [yield] → [END]
                                                                       ↑    ↓
                                                                       └────┘
```

With these conditional edges:

- `understanding` → `action` (for refinement loops)
- `understanding` → `yield` (for completion)

### Interrupt Handling

We'll use LangGraph's built-in interrupt capability:

```python
# Import in api/app/routers/postchain.py
from langgraph.errors import InterruptibleGraphCancelled

# When streaming
@router.post("/simple")
async def process_simple_postchain(
    request: SimplePostChainRequest,
    config: Config = Depends(get_config)
):
    if request.stream:
        async def stream_generator():
            try:
                async for chunk in stream_simple_postchain(
                    user_query=request.user_query,
                    config=config,
                    thread_id=request.thread_id
                ):
                    yield f"data: {json.dumps(chunk)}\n\n"
            except InterruptibleGraphCancelled:
                yield f"data: {json.dumps({'status': 'cancelled'})}\n\n"

            # End of stream
            yield "data: [DONE]\n\n"

        return StreamingResponse(
            stream_generator(),
            media_type="text/event-stream"
        )
```

### Memory Integration

For thread persistence:

```python
# In api/app/postchain/simple_graph.py
from langgraph.checkpoint.memory import MemorySaver

# Create memory saver with thread ID
memory = MemorySaver(f"postchain_{thread_id}")

# Add to graph builder
builder.set_checkpoint(memory)

# When retrieving a conversation
try:
    existing_state = memory.load()
    if existing_state:
        state = existing_state
        # Add the new message from the user
        state.messages.append(HumanMessage(content=user_query))
    else:
        state = initial_state
except Exception as e:
    logger.error(f"Error loading state: {e}")
    state = initial_state
```

## 🔄 Testing Strategy

Our primary testing harness will be the SwiftUI frontend:

1. **SwiftUI Frontend Testing**: Use the actual UI to validate functionality and user experience
2. **Backend API Testing**: Test endpoints with the actual frontend client
3. **Manual Testing**: Validate full conversation flows with real user scenarios
4. **Supplementary Unit Tests**: Create targeted tests for complex logic as needed
5. **Model Compatibility Tests**: Verify functioning across different providers and model types

## 📊 Success Criteria

Each phase will be considered complete when:

1. The feature works correctly in the SwiftUI frontend
2. Stream processing displays results appropriately
3. User experience meets expectations
4. Performance is acceptable on real devices
5. System gracefully handles model failures and provider outages

## 📅 Implementation Order

1. Structured state & memory management
2. Multiturn support
3. Interrupt handling
4. Model flexibility & fallback mechanisms
5. Web search & Qdrant integration with Experience phase
6. UI components for displaying search results
7. Intention phase
8. Observation phase
9. Understanding phase
10. Yield phase
11. Performance optimization

This approach ensures we have a robust, flexible system that can work with any model and gracefully handle failures before we expand to additional phases.
