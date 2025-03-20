# [DEPRECATED] LangGraph PostChain Iteration Plan

> **DEPRECATION NOTICE**: This document describes Choir's previous graph-based architecture using LangGraph, which has been replaced by the current actor-based architecture. It is preserved for historical reference only and should not be used for new development.
>
> **For current documentation, please refer to:**
>
> - [Actor Model Overview](../1-concepts/actor_model_overview.md)
> - [Architecture Transition Narrative](architecture_transition_narrative.md)
> - [Migration Guide for Developers](../3-implementation/migration_guide_for_developers.md)

---

_The original document content follows below:_

# PostChain LangGraph Implementation Plan

This document outlines our iterative approach to implementing the full PostChain (AEIOU-Y) using LangGraph. We'll build on the existing Action+Experience implementation, gradually adding features while maintaining a working system at each stage, with special attention to SwiftUI frontend integration.

## 📚 Key Reference Files

Before beginning implementation, familiarize yourself with these files:

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/postchain/schemas/state.py` - Pydantic models for state management
- `api/app/routers/postchain.py` - FastAPI router handling PostChain endpoints
- `api/app/langchain_utils.py` - Utility functions for working with language models
- `api/app/config.py` - Configuration settings including model identifiers
- `docs/plan_postchain_migration_checklist.md` - Original migration plan

### Frontend Files

- `Choir/Networking/PostchainAPIClient.swift` - Client for interacting with PostChain API
- `Choir/Protocols/PostchainCoordinator.swift` - Protocol defining PostChain coordination
- `Choir/ViewModels/PostchainViewModel.swift` - ViewModel for PostChain state management
- `Choir/Views/MessageRow.swift` - UI for individual message rows
- `Choir/Views/PostchainView.swift` - UI for displaying PostChain phases

## 🎯 Overall Strategy

We'll follow an incremental approach with these key phases:

1. **Foundation**: Add proper memory management and multiturn support to existing graph
2. **Model Flexibility**: Implement model-agnostic architecture with fallback mechanisms
3. **Integration**: Connect with tools and external systems, prioritizing search results in the Experience phase
4. **Expansion**: Add remaining AEIOU-Y phases one by one
5. **Refinement**: Optimize performance and UX

Each milestone will result in a working system that can be tested with our SwiftUI frontend.

## 📝 AEIOU-Y Phase Requirements

The PostChain consists of these phases, each with distinct responsibilities:

1. **Action**: Initial response to user input

   - Generate direct response based on user query
   - Set context for subsequent phases

2. **Experience**: Enrichment with prior knowledge

   - Augment initial response with search and stored knowledge
   - Use tools to gather supporting information
   - Format and incorporate search results for display in UI

3. **Intention**: Alignment with user intent

   - Analyze and clarify user intention
   - Detect ambiguities or misalignments
   - Prepare for context building

4. **Observation**: Recording semantic connections

   - Identify and record key contextual elements
   - Create associations with prior knowledge
   - Prepare metadata for understanding phase

5. **Understanding**: Decision on continuation

   - Evaluate if further refinement is needed
   - Determine which phase to revisit if necessary
   - Can hand off to ANY previous phase based on needs
   - Decide when to proceed to final output

6. **Yield**: Final response production
   - Format final output for presentation
   - Combine insights from all phases
   - Clean up state and prepare final metadata

The graph will generally flow sequentially, but the Understanding phase can direct execution to any previous phase when needed, allowing flexible, adaptive behavior.

## 🔄 Frontend-Backend Integration

Based on the SwiftUI frontend files, our implementation must support the following requirements:

### Stream Event Format

The `PostchainAPIClient.swift` expects structured events with:

```json
{
  "current_phase": "action|experience|intention|observation|understanding|yield",
  "phase_state": "processing|complete|error",
  "content": "Phase content text",
  "thread_id": "uuid-format-thread-id",
  "error": "Optional error message"
}
```

### UI Requirements

The `PostchainView.swift` displays each AEIOU-Y phase as a separate card, requiring:

- Independent updates for each phase
- Clear phase transition signals
- Visual indicators for processing status
- Human interruption and review capabilities

### Thread Management

The frontend tracks conversation threads and expects:

- Consistent thread_id handling
- Persistence across multiple interactions
- Proper error state propagation
- Phase-specific content storage

## 📋 Implementation Checklist

### Phase 1: Foundation (Memory & Multiturn)

- [ ] **Structured State Management**

  - [ ] Update `PostChainState` Pydantic model in `api/app/postchain/schemas/state.py` to include:
    ```python
    class PostChainState(BaseModel):
        """Structured state model for PostChain."""
        messages: List[BaseMessage] = Field(default_factory=list)
        current_phase: str = Field("action")
        thread_id: Optional[str] = Field(None)
        phase_outputs: Dict[str, str] = Field(default_factory=dict)
        phase_state: Dict[str, str] = Field(default_factory=dict)  # Track processing state
        metadata: Dict[str, Any] = Field(default_factory=dict)
        tools_used: List[str] = Field(default_factory=list)
        search_results: List[Dict[str, Any]] = Field(default_factory=list)
        model_attempts: Dict[str, List[str]] = Field(default_factory=dict)
        summary: Optional[str] = Field(None, description="Summary of conversation history")
        context_window_size: int = Field(10, description="Number of messages to keep in context")
        next_phase: Optional[str] = Field(None, description="Override for next phase to execute")
        error: Optional[str] = Field(None, description="Error message if any")
    ```
  - [ ] Define clear schema for conversation history
  - [ ] Implement phase metadata tracking
  - [ ] Add context window configuration parameters

- [ ] **Stream Event Formatter**

  - [ ] Create a utility function to format state for streaming:
    ```python
    def format_stream_event(state: PostChainState, content: str = None):
        return {
            "current_phase": state.current_phase,
            "phase_state": state.phase_state.get(state.current_phase, "processing"),
            "content": content or state.phase_outputs.get(state.current_phase, ""),
            "thread_id": state.thread_id,
            "error": state.error
        }
    ```
  - [ ] Implement phase state updates in all node handlers
  - [ ] Add phase transition signaling for frontend UI

- [ ] **Persistence Implementation**

  - [ ] Integrate LangGraph's `MemorySaver` for thread-level persistence
  - [ ] Add thread ID validation (UUIDv4 format)
  - [ ] Implement robust state recovery for interrupted conversations
  - [ ] Add explicit checkpointer configuration during graph compilation
  - [ ] Create helper functions for state loading and saving

- [ ] **Multiturn Support**

  - [ ] Modify handlers to properly maintain conversation context
  - [ ] Implement message filtering for context window management
  - [ ] Add sliding window context management (last 10 messages by default)
  - [ ] Implement message attribution with phase metadata

- [ ] **Interrupt Handling**
  - [ ] Implement proper LangGraph interrupt handlers with `InterruptibleGraphCancelled`
  - [ ] Add graceful cancellation across all phases
  - [ ] Create appropriate user feedback for interruptions
  - [ ] Add state recovery for interrupted conversations
  - [ ] Implement human-in-the-loop capabilities using the interrupt function

### Phase 2: Model Flexibility & Resilience

- [ ] **Model-Agnostic Architecture**

  - [ ] Abstract model selection from node implementation in `api/app/postchain/simple_graph.py`
  - [ ] Create model capability detection (tool-compatible vs non-tool models)
  - [ ] Implement phase-specific model selection

- [ ] **Fallback & Retry Mechanisms**

  - [ ] Implement automatic model fallback on failure
  - [ ] Add retry policy with exponential backoff (using LangGraph's `RetryPolicy`)
  - [ ] Create graceful degradation for when preferred models are unavailable
  - [ ] Add context compaction as fallback strategy for model errors

- [ ] **Model Error Handling**
  - [ ] Implement comprehensive error detection for different providers
  - [ ] Add model-specific formatting for prompts
  - [ ] Create robust recovery from failed model invocations
  - [ ] Use prebuilt ToolNode for improved tool error handling
  - [ ] Add automatic error message cleanup

### Phase 3: Tool & External Integration (Prioritized)

- [ ] **Tool Integration for Experience Phase**

  - [ ] Add Qdrant vectorstore connection (see `api/app/tools/qdrant.py`)
  - [ ] Implement web search tools (see `api/app/tools/brave_search.py`, `api/app/tools/tavily_search.py`)
  - [ ] Create search result formatting for Experience phase:

    ```python
    async def experience_with_search(state: PostChainState) -> Dict[str, Any]:
        # Update phase state to processing
        state.phase_state["experience"] = "processing"
        yield format_stream_event(state)

        # Perform search operations
        search_results = await perform_search(state.messages[-1].content)

        # Interrupt for human review if needed
        reviewed_results = interrupt({
            "type": "review_search",
            "original_results": search_results,
            "message": "Please review these search results before proceeding."
        })

        # Use reviewed or original results
        final_results = reviewed_results or search_results

        # Format results and update state
        formatted_output = format_experience_output(final_results)

        # Return updated state
        return {
            "search_results": final_results,
            "phase_outputs": {**state.phase_outputs, "experience": formatted_output},
            "phase_state": {**state.phase_state, "experience": "complete"},
            "current_phase": "intention"  # Move to next phase
        }
    ```

  - [ ] Add calculator and other specialized tools (see `api/app/tools/calculator.py`)
  - [ ] Implement result filtering and prioritization

- [ ] **API Integration for SwiftUI Client**
  - [ ] Add proper streaming for search results in `api/app/routers/postchain.py`
  - [ ] Implement client event handling for displaying search data
  - [ ] Create UI components for displaying search results in Experience phase
  - [ ] Add deep linking to priors and web results
  - [ ] Implement streaming event format with search result sections

### Phase 4: AEIOU-Y Expansion (After Tool Integration)

- [ ] **Intention Phase**

  - [ ] Implement `intention_node` handler based on requirements
  - [ ] Add user intent alignment logic
  - [ ] Create conditional routing based on intent
  - [ ] Implement intent-aware context filtering

- [ ] **Observation Phase**

  - [ ] Implement `observation_node` handler based on requirements
  - [ ] Add semantic connections recording
  - [ ] Integrate context building
  - [ ] Add metadata annotation for important messages

- [ ] **Understanding Phase**

  - [ ] Implement `understanding_node` handler based on requirements
  - [ ] Add continuation decision logic
  - [ ] Create flexible routing to ANY previous phase using agent handoffs:

    ```python
    def understanding_router(state: PostChainState) -> str:
        """Route to the appropriate phase based on understanding evaluation."""
        # Check for explicit next phase in state
        if state.next_phase:
            return state.next_phase

        # Default sequential progression
        if state.current_phase == "understanding":
            # Determine if we need more refinement
            needs_refinement = evaluate_needs_refinement(state)
            if needs_refinement == "action":
                return "action"  # Restart from action
            elif needs_refinement == "experience":
                return "experience"  # Get more information
            elif needs_refinement == "intention":
                return "intention"  # Clarify intent
            elif needs_refinement == "observation":
                return "observation"  # Enhance context
            else:
                return "yield"  # Proceed to final output

        # Fallback to yield
        return "yield"
    ```

  - [ ] Implement conversation summarization

- [ ] **Yield Phase**
  - [ ] Implement `yield_node` handler based on requirements
  - [ ] Add final response formatting
  - [ ] Implement state cleanup
  - [ ] Add summary metadata to final response

### Phase 5: Refinement & Optimization

- [ ] **Context Management**

  - [ ] Implement message deletion mechanisms
  - [ ] Add privacy-preserving message pruning
  - [ ] Implement automatic context compaction
  - [ ] Create automatic compaction tool
  - [ ] Implement summary-augmented memory
  - [ ] Add incremental summarization
  - [ ] Add memory prioritization

- [ ] **Performance Optimization**

  - [ ] Implement parallel processing where appropriate
  - [ ] Add caching for repeated operations
  - [ ] Optimize token usage
  - [ ] Add selective message filtering

- [ ] **Error Handling & Recovery**
  - [ ] Implement comprehensive error states
  - [ ] Add automatic retry logic
  - [ ] Create graceful degradation paths
  - [ ] Add error message cleanup procedures
  - [ ] Implement API endpoints for manual message pruning

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

```
langgraph>=0.0.27
langchain-core>=0.1.27
pydantic>=2.5.0
```

### State Management

We'll update the Pydantic model in `api/app/postchain/schemas/state.py`:

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
    phase_state: Dict[str, str] = Field(default_factory=dict)  # Track processing state
    metadata: Dict[str, Any] = Field(default_factory=dict)
    tools_used: List[str] = Field(default_factory=list)
    search_results: List[Dict[str, Any]] = Field(default_factory=list)
    model_attempts: Dict[str, List[str]] = Field(default_factory=dict)
    summary: Optional[str] = Field(None, description="Summary of conversation history")
    context_window_size: int = Field(10, description="Number of messages to keep in context")
    next_phase: Optional[str] = Field(None, description="Override for next phase to execute")
    error: Optional[str] = Field(None, description="Error message if any")
```

### Stream Event Formatter

To ensure proper frontend integration, we'll add a utility function:

```python
# In api/app/postchain/utils.py
def format_stream_event(state: PostChainState, content: str = None, error: str = None):
    """Format state for streaming to clients."""
    return {
        "current_phase": state.current_phase,
        "phase_state": state.phase_state.get(state.current_phase, "processing"),
        "content": content or state.phase_outputs.get(state.current_phase, ""),
        "thread_id": state.thread_id,
        "error": error or state.error
    }
```

### Persistence Implementation

For thread persistence:

```python
# In api/app/postchain/simple_graph.py
from langgraph.checkpoint.memory import MemorySaver

# Create memory saver with thread ID
memory = MemorySaver(f"postchain_{thread_id}")

# Add to graph builder
builder.set_checkpoint(memory)

# When retrieving a conversation with robust error handling
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

### Context Window Management

```python
# Message filtering for context window management
def filter_messages(state: PostChainState) -> List[BaseMessage]:
    """Filter messages to fit in context window."""
    window_size = state.context_window_size
    if len(state.messages) <= window_size:
        return state.messages

    # Always include system message if present
    system_messages = [m for m in state.messages if isinstance(m, SystemMessage)]

    # Add most recent messages up to window size
    recent_messages = state.messages[-window_size:]

    # If we have a summary, include it as context
    if state.summary:
        summary_message = SystemMessage(content=f"Conversation summary: {state.summary}")
        return system_messages + [summary_message] + recent_messages

    return system_messages + recent_messages
```

### Human-in-the-loop Implementation

```python
# Add to experience phase for human review
from langgraph.types import interrupt

async def experience_with_human_review(state: PostChainState) -> Dict[str, Any]:
    """Experience phase with optional human review of search results."""
    # Update phase state to processing and notify client
    state.phase_state["experience"] = "processing"
    yield format_stream_event(state)

    # First part: gather search results
    search_results = await perform_search(state.messages[-1].content)

    # Interrupt for human review
    reviewed_results = interrupt({
        "type": "review_search",
        "original_results": search_results,
        "message": "Please review these search results before proceeding."
    })

    # Continue with human-reviewed (or original) results
    final_results = reviewed_results or search_results

    # Format the experience output
    formatted_output = format_experience_output(final_results)

    # Update phase state to complete
    return {
        "search_results": final_results,
        "phase_outputs": {**state.phase_outputs, "experience": formatted_output},
        "phase_state": {**state.phase_state, "experience": "complete"},
        "current_phase": "intention"  # Move to next phase
    }
```

### Flexible Phase Routing

```python
# Add to understanding phase
def understanding_router(state: PostChainState) -> str:
    """Route to the appropriate phase based on understanding evaluation."""
    # Check for explicit next phase in state
    if state.next_phase:
        return state.next_phase

    # Default sequential progression
    if state.current_phase == "understanding":
        # Determine if we need more refinement
        needs_refinement = evaluate_needs_refinement(state)
        if needs_refinement == "action":
            return "action"  # Restart from action
        elif needs_refinement == "experience":
            return "experience"  # Get more information
        elif needs_refinement == "intention":
            return "intention"  # Clarify intent
        elif needs_refinement == "observation":
            return "observation"  # Enhance context
        else:
            return "yield"  # Proceed to final output

    # Fallback to yield
    return "yield"
```

### Tool Error Handling

```python
# Using prebuilt ToolNode for better error handling
from langgraph.prebuilt import ToolNode

# Define tools
tools = [search_tool, calculator_tool, qdrant_tool]

# Create tool node with proper error handling
tool_node = ToolNode(tools)

# Add to graph
builder.add_node("tools", tool_node)
```

### Agent Handoffs

```python
# Configure conditional edges for flexible routing
builder.add_conditional_edges(
    "understanding",
    understanding_router,
    ["action", "experience", "intention", "observation", "yield"]
)
```

### Interrupt Handling

```python
# Import in api/app/routers/postchain.py
from langgraph.errors import InterruptibleGraphCancelled
from langgraph.types import Command

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
                    if "__interrupt__" in chunk:
                        # Handle interruption for human review
                        interrupt_data = chunk["__interrupt__"][0].value
                        # Here you would typically wait for human input
                        # For now, we'll just continue with original data
                        resume_value = interrupt_data.get("original_results")
                        # Resume the graph
                        async for resumed_chunk in stream_simple_postchain(
                            Command(resume=resume_value),
                            config=config,
                            thread_id=request.thread_id
                        ):
                            yield f"data: {json.dumps(resumed_chunk)}\n\n"
                        return
                    yield f"data: {json.dumps(chunk)}\n\n"
            except InterruptibleGraphCancelled:
                # Provide informative interruption feedback
                yield f"data: {json.dumps({'status': 'cancelled', 'message': 'Operation was interrupted', 'current_phase': 'yield', 'phase_state': 'error'})}\n\n"

            # End of stream
            yield "data: [DONE]\n\n"

        return StreamingResponse(
            stream_generator(),
            media_type="text/event-stream"
        )
```

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
2. Stream processing displays results appropriately in the phase cards
3. User experience meets expectations with smooth phase transitions
4. Performance is acceptable on real devices
5. System gracefully handles model failures and provider outages
6. Context management keeps token usage optimized
7. Conversation history is properly maintained and summarized
8. Human-in-the-loop interrupts function properly with the frontend

## 📅 Implementation Order

1. Structured state & memory management with persistence
2. Stream event formatting for SwiftUI integration
3. Context window management and message filtering
4. Multiturn support with proper conversation handling
5. Interrupt handling with state recovery
6. Model flexibility & fallback mechanisms
7. Web search & Qdrant integration with Experience phase
8. UI components for displaying search results
9. Message summarization and context optimization
10. Intention phase
11. Observation phase
12. Understanding phase with flexible routing
13. Yield phase
14. Advanced context management (deletion, privacy)
15. Performance optimization

This approach ensures we have a robust, flexible system that integrates seamlessly with the SwiftUI frontend, can work with any model, handle conversation history effectively, and gracefully manage failures before we expand to additional phases.

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Run tests from the api directory** - This ensures correct import paths
3. **Maintain backwards compatibility** - Existing endpoints must continue to work
4. **Gradual deployment** - Each phase should be deployable independently
5. **Error handling is critical** - The system must gracefully handle any failure
6. **Log extensively** - Use the logger to track execution flow for debugging
7. **Manage context window carefully** - Always implement message filtering to prevent token limits
8. **Implement proper state recovery** - Handle interruptions and failures gracefully
9. **Use thread IDs consistently** - Always validate and normalize thread IDs
10. **Consider privacy implications** - Implement message deletion capabilities
11. **Frontend integration is key** - Ensure all state updates are properly streamed to the frontend
12. **Phase state tracking** - Always update phase_state to provide UI feedback
