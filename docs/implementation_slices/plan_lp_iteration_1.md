# PostChain LangGraph Implementation Plan - Slice 1: State Management & Persistence

This slice focuses on implementing the foundational state management and persistence infrastructure for the PostChain system, setting up the building blocks for subsequent development.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/postchain/schemas/state.py` - Pydantic models for state management
- `api/app/routers/postchain.py` - FastAPI router handling PostChain endpoints

### Frontend Files

- `Choir/Networking/PostchainAPIClient.swift` - Client for interacting with PostChain API
- `Choir/Protocols/PostchainCoordinator.swift` - Protocol defining PostChain coordination
- `Choir/ViewModels/PostchainViewModel.swift` - ViewModel for PostChain state management

## 🎯 Goals for This Slice

1. Update the state model to support frontend integration requirements
2. Implement persistence with thread-level management
3. Set up proper thread ID validation and handling
4. Create foundation for state recovery

## 🔄 Frontend-Backend Integration Context

The PostChain system must integrate with a SwiftUI frontend that displays each AEIOU-Y phase as a separate card. The frontend expects:

- Consistent thread_id handling
- Phase-specific content storage
- Proper error state propagation

## 📋 Implementation Tasks

### 1. Structured State Management

- [ ] Update `PostChainState` Pydantic model in `api/app/postchain/schemas/state.py`:

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

- [ ] Update all relevant imports in files that use the state model
- [ ] Update existing code that accesses state to use the new model structure
- [ ] Add validation for phase_state values to ensure they are one of: "processing", "complete", "error"

### 2. Persistence Implementation

- [ ] Integrate LangGraph's `MemorySaver` for thread-level persistence:

  ```python
  # In api/app/postchain/simple_graph.py
  from langgraph.checkpoint.memory import MemorySaver

  # Create memory saver with thread ID
  memory = MemorySaver(f"postchain_{thread_id}")

  # Add to graph builder
  builder.set_checkpoint(memory)
  ```

- [ ] Add thread ID validation (UUIDv4 format):

  ```python
  import uuid
  import re

  def validate_thread_id(thread_id: str) -> str:
      """Validate and normalize thread ID."""
      if not thread_id:
          return str(uuid.uuid4())

      # Check if valid UUID format
      try:
          uuid_obj = uuid.UUID(thread_id)
          return str(uuid_obj)
      except ValueError:
          # If not valid UUID, generate new one
          logger.warning(f"Invalid thread ID format: {thread_id}. Generating new UUID.")
          return str(uuid.uuid4())
  ```

- [ ] Create helper functions for state loading and saving:

  ```python
  def load_state(thread_id: str, user_query: str = None) -> PostChainState:
      """Load existing state or create new one."""
      thread_id = validate_thread_id(thread_id)
      memory = MemorySaver(f"postchain_{thread_id}")

      try:
          existing_state = memory.load()
          if existing_state:
              # Add the new message if provided
              if user_query:
                  existing_state.messages.append(HumanMessage(content=user_query))
              return existing_state
      except Exception as e:
          logger.error(f"Error loading state for thread {thread_id}: {e}")

      # Create new state if loading failed or no existing state
      initial_state = PostChainState(
          thread_id=thread_id,
          messages=[SystemMessage(content="You are a helpful AI assistant.")]
      )

      if user_query:
          initial_state.messages.append(HumanMessage(content=user_query))

      return initial_state
  ```

- [ ] Implement robust state recovery for interrupted conversations:

  ```python
  def recover_state(thread_id: str) -> Optional[PostChainState]:
      """Attempt to recover state from interrupted conversation."""
      thread_id = validate_thread_id(thread_id)
      memory = MemorySaver(f"postchain_{thread_id}")

      try:
          existing_state = memory.load()
          if existing_state:
              # Mark any "processing" phases as "error" to indicate interruption
              for phase in existing_state.phase_state:
                  if existing_state.phase_state[phase] == "processing":
                      existing_state.phase_state[phase] = "error"
                      existing_state.error = "Conversation was interrupted"

              return existing_state
      except Exception as e:
          logger.error(f"Error recovering state for thread {thread_id}: {e}")
          return None
  ```

### 3. Graph Compilation with Persistence

- [ ] Update graph compilation to use thread-specific persistence:

  ```python
  def create_postchain_graph(thread_id: str = None) -> Runnable:
      """Create a PostChain graph with thread-specific persistence."""
      thread_id = validate_thread_id(thread_id)

      # Create state graph
      builder = StateGraph(PostChainState)

      # Add nodes for each phase
      builder.add_node("action", action_node)
      builder.add_node("experience", experience_node)

      # Add edges
      builder.add_edge("action", "experience")
      builder.add_edge("experience", END)

      # Set entry point
      builder.set_entry_point("action")

      # Configure persistence
      memory = MemorySaver(f"postchain_{thread_id}")

      # Compile with persistence
      return builder.compile(checkpointer=memory)
  ```

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

## 🔄 Testing

1. **Unit Tests**: Create tests for thread ID validation and state recovery

   ```bash
   # From api directory
   python -m pytest tests/postchain/test_state_management.py -v
   ```

2. **API Testing**: Test thread persistence with curl

   ```bash
   # First request with new thread
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Tell me about quantum computing", "thread_id": "new-test-thread"}'

   # Second request with same thread
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Continue our discussion", "thread_id": "new-test-thread"}'
   ```

## 📊 Success Criteria

This slice is complete when:

1. The updated state model is implemented and used throughout the codebase
2. Thread IDs are properly validated and normalized
3. Conversations can be continued across multiple requests using the same thread ID
4. Interrupted conversations can be recovered with appropriate error states
5. The implementation passes all unit tests

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Maintain backwards compatibility** - Existing endpoints must continue to work
3. **Log extensively** - Use the logger to track execution flow for debugging
4. **Use thread IDs consistently** - Always validate and normalize thread IDs
5. **State recovery is critical** - Ensure proper error states for interrupted conversations
