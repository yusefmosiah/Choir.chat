# PostChain LangGraph Implementation Plan - Slice 2: Stream Event Formatting & Frontend Integration

This slice focuses on implementing the stream event formatting and frontend integration for the PostChain system, ensuring proper communication between the backend and the SwiftUI frontend.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/routers/postchain.py` - FastAPI router handling PostChain endpoints

### Frontend Files

- `Choir/Networking/PostchainAPIClient.swift` - Client for interacting with PostChain API
- `Choir/Views/PostchainView.swift` - UI for displaying PostChain phases

## 🎯 Goals for This Slice

1. Create a utility function for formatting state events for streaming
2. Implement consistent stream event format for all phases
3. Modify the API endpoints to use the new stream event format
4. Ensure proper phase state tracking for frontend UI feedback

## 🔄 Frontend-Backend Integration Context

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

The `PostchainView.swift` displays each AEIOU-Y phase as a separate card, requiring:

- Independent updates for each phase
- Clear phase transition signals
- Visual indicators for processing status

## 📋 Implementation Tasks

### 1. Stream Event Formatter

- [ ] Create utility function in `api/app/postchain/utils.py`:

  ```python
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

- [ ] Add helper function for phase-specific content updates:

  ```python
  def update_phase_content(state: PostChainState, phase: str, content: str, status: str = "processing") -> Dict:
      """Update content for a specific phase and return formatted event."""
      # Update phase content
      state.phase_outputs[phase] = content

      # Update phase state
      state.phase_state[phase] = status

      # Create a custom event with this phase as current
      return {
          "current_phase": phase,
          "phase_state": status,
          "content": content,
          "thread_id": state.thread_id,
          "error": state.error
      }
  ```

### 2. Update Phase Handlers for Streaming

- [ ] Modify the action_node handler to support streaming:

  ```python
  async def action_node(state: PostChainState) -> Dict[str, Any]:
      """Handle the action phase with streaming updates."""
      # Set phase to processing
      state.phase_state["action"] = "processing"
      yield format_stream_event(state)

      # Process using LLM
      user_input = state.messages[-1].content
      response = await process_with_llm(user_input)

      # Update state and yield complete event
      state.phase_outputs["action"] = response
      state.phase_state["action"] = "complete"

      yield format_stream_event(state)

      # Return updated state
      return {
          "phase_outputs": {**state.phase_outputs, "action": response},
          "phase_state": {**state.phase_state, "action": "complete"},
          "current_phase": "experience"  # Move to next phase
      }
  ```

- [ ] Modify the experience_node handler to support streaming:

  ```python
  async def experience_node(state: PostChainState) -> Dict[str, Any]:
      """Handle the experience phase with streaming updates."""
      # Set phase to processing
      state.phase_state["experience"] = "processing"
      yield format_stream_event(state, content="Loading relevant information...")

      # Process experience phase logic
      action_output = state.phase_outputs.get("action", "")
      experience_content = await enhance_with_experience(action_output)

      # Update state incrementally for better UX
      for i, chunk in enumerate(chunk_text(experience_content)):
          # For longer responses, show incremental updates
          current_content = state.phase_outputs.get("experience", "") + chunk
          state.phase_outputs["experience"] = current_content

          # Only yield every few chunks to avoid overwhelming the client
          if i % 3 == 0:
              yield format_stream_event(state)

      # Mark as complete
      state.phase_state["experience"] = "complete"
      yield format_stream_event(state)

      # Return final state update
      return {
          "phase_outputs": {**state.phase_outputs, "experience": experience_content},
          "phase_state": {**state.phase_state, "experience": "complete"},
          "current_phase": "yield"  # For now, we end at experience
      }
  ```

- [ ] Add helper function for chunking text:

  ```python
  def chunk_text(text: str, chunk_size: int = 50) -> List[str]:
      """Split text into smaller chunks for incremental streaming."""
      words = text.split()
      chunks = []
      current_chunk = []

      for word in words:
          current_chunk.append(word)
          if len(current_chunk) >= chunk_size:
              chunks.append(" ".join(current_chunk))
              current_chunk = []

      if current_chunk:
          chunks.append(" ".join(current_chunk))

      return chunks
  ```

### 3. Update FastAPI Router for Streaming

- [ ] Modify `api/app/routers/postchain.py` to use the new event format:

  ```python
  @router.post("/simple")
  async def process_simple_postchain(
      request: SimplePostChainRequest,
      config: Config = Depends(get_config)
  ):
      thread_id = validate_thread_id(request.thread_id)

      if request.stream:
          async def stream_generator():
              try:
                  # Create graph
                  graph = create_postchain_graph(thread_id)

                  # Load or create state
                  state = load_state(thread_id, request.user_query)

                  # Process the graph with streaming
                  async for chunk in graph.astream(state):
                      if isinstance(chunk, dict) and chunk.get("current_phase"):
                          # Format is already correct, stream directly
                          yield f"data: {json.dumps(chunk)}\n\n"
                      else:
                          # Convert to proper format if needed
                          formatted = format_stream_event(chunk)
                          yield f"data: {json.dumps(formatted)}\n\n"

              except Exception as e:
                  logger.error(f"Error in stream: {e}")
                  error_event = {
                      "current_phase": "yield",
                      "phase_state": "error",
                      "content": "An error occurred during processing.",
                      "error": str(e),
                      "thread_id": thread_id
                  }
                  yield f"data: {json.dumps(error_event)}\n\n"

              # End of stream
              yield "data: [DONE]\n\n"

          return StreamingResponse(
              stream_generator(),
              media_type="text/event-stream"
          )
      else:
          # Non-streaming implementation remains unchanged
          # ...
  ```

### 4. Add Error Handling for Frontend Integration

- [ ] Implement comprehensive error handling:

  ```python
  def handle_error(state: PostChainState, error: Exception, phase: str = None) -> Dict:
      """Handle errors and format for frontend consumption."""
      current_phase = phase or state.current_phase
      error_message = str(error)

      # Update state
      state.error = error_message
      state.phase_state[current_phase] = "error"

      # Log the error
      logger.error(f"Error in {current_phase} phase: {error_message}")

      # Return formatted error event
      return {
          "current_phase": current_phase,
          "phase_state": "error",
          "content": state.phase_outputs.get(current_phase, ""),
          "error": error_message,
          "thread_id": state.thread_id
      }
  ```

- [ ] Add try/except blocks to all phase handlers:

  ```python
  async def action_node(state: PostChainState) -> Dict[str, Any]:
      """Handle the action phase with streaming updates and error handling."""
      # Set phase to processing
      state.phase_state["action"] = "processing"
      yield format_stream_event(state)

      try:
          # Process using LLM
          user_input = state.messages[-1].content
          response = await process_with_llm(user_input)

          # Update state and yield complete event
          state.phase_outputs["action"] = response
          state.phase_state["action"] = "complete"

          yield format_stream_event(state)

          # Return updated state
          return {
              "phase_outputs": {**state.phase_outputs, "action": response},
              "phase_state": {**state.phase_state, "action": "complete"},
              "current_phase": "experience"  # Move to next phase
          }
      except Exception as e:
          # Handle and format error
          error_event = handle_error(state, e, "action")
          yield error_event

          # Return error state
          return {
              "phase_outputs": {**state.phase_outputs},
              "phase_state": {**state.phase_state, "action": "error"},
              "error": str(e),
              "current_phase": "yield"  # Skip to end on error
          }
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
fastapi>=0.68.0
```

## 🔄 Testing

1. **Unit Tests**: Create tests for stream event formatting

   ```bash
   # From api directory
   python -m pytest tests/postchain/test_stream_formatting.py -v
   ```

2. **API Testing**: Test streaming with curl

   ```bash
   # Test streaming endpoint
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Tell me about quantum computing", "stream": true}'
   ```

3. **Frontend Integration**: Test with the SwiftUI client to verify the UI displays phase updates correctly

## 📊 Success Criteria

This slice is complete when:

1. The API streams events in the format expected by the SwiftUI frontend
2. Each phase update includes proper phase_state indicators
3. Error handling properly formats errors for frontend consumption
4. The SwiftUI frontend correctly displays phase transitions
5. Incremental updates are visible in the UI for longer responses

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Maintain backwards compatibility** - Existing endpoints must continue to work
3. **Phase state tracking is critical** - Always update phase_state to provide UI feedback
4. **Error handling is essential** - Format errors consistently for frontend display
5. **Avoid overwhelming the client** - Stream updates at reasonable intervals
