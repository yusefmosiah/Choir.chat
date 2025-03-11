# PostChain LangGraph Implementation Plan - Slice 4: Interrupt Handling & Human-in-the-Loop

This slice focuses on implementing interrupt handling and human-in-the-loop capabilities for the PostChain system, allowing for graceful cancellation, human review of content, and proper recovery from interruptions.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/routers/postchain.py` - FastAPI router handling PostChain endpoints

### Frontend Files

- `Choir/Networking/PostchainAPIClient.swift` - Client for interacting with PostChain API
- `Choir/ViewModels/PostchainViewModel.swift` - ViewModel for PostChain state management
- `Choir/Views/PostchainView.swift` - UI for displaying PostChain phases

## 🎯 Goals for This Slice

1. Implement proper interrupt handlers with LangGraph's `interrupt` function
2. Add human review capabilities for search results and generated content
3. Create graceful cancellation mechanisms across all phases
4. Implement state recovery for interrupted conversations
5. Add appropriate user feedback for interruptions

## 🔄 Frontend-Backend Integration Context

The frontend needs mechanisms to:

- Review content before it's considered final
- Cancel ongoing operations
- Receive appropriate feedback when interruptions occur
- Recover gracefully from interruptions

## 📋 Implementation Tasks

### 1. Basic Interrupt Handling

- [ ] Update graph implementation in `api/app/postchain/simple_graph.py` to support interrupts:

  ```python
  from langgraph.errors import InterruptibleGraphCancelled
  from langgraph.types import Command, interrupt

  # Ensure graph is compiled with a checkpointer
  def create_postchain_graph(thread_id: str = None) -> Runnable:
      """Create a PostChain graph with interrupt capabilities."""
      thread_id = validate_thread_id(thread_id)

      # Create graph as before...

      # Configure persistence - required for interrupts
      memory = MemorySaver(f"postchain_{thread_id}")

      # Compile with persistence
      return builder.compile(checkpointer=memory)
  ```

- [ ] Add handling in the API router in `api/app/routers/postchain.py`:

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
                      if "__interrupt__" in chunk:
                          # We've hit an interrupt
                          interrupt_data = chunk["__interrupt__"][0].value

                          # Format interrupt notification for client
                          interrupt_event = {
                              "current_phase": state.current_phase,
                              "phase_state": "interrupt",
                              "content": "Awaiting human input...",
                              "interrupt_data": interrupt_data,
                              "thread_id": thread_id
                          }

                          yield f"data: {json.dumps(interrupt_event)}\n\n"
                          return  # End stream, waiting for resume
                      else:
                          # Normal chunk
                          if isinstance(chunk, dict) and chunk.get("current_phase"):
                              # Format is already correct, stream directly
                              yield f"data: {json.dumps(chunk)}\n\n"
                          else:
                              # Convert to proper format if needed
                              formatted = format_stream_event(chunk)
                              yield f"data: {json.dumps(formatted)}\n\n"

              except InterruptibleGraphCancelled:
                  # Handle cancellation
                  cancel_event = {
                      "current_phase": "yield",
                      "phase_state": "error",
                      "content": "Operation was cancelled",
                      "error": "Operation was cancelled by user",
                      "thread_id": thread_id
                  }
                  yield f"data: {json.dumps(cancel_event)}\n\n"
              except Exception as e:
                  # Handle other errors
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
          # Non-streaming implementation
          # ...
  ```

### 2. Human Review for Search Results

- [ ] Implement experience phase with human review in `api/app/postchain/simple_graph.py`:

  ```python
  async def experience_with_human_review(state: PostChainState) -> Dict[str, Any]:
      """Experience phase with optional human review of search results."""
      # Update phase state to processing
      state.phase_state["experience"] = "processing"
      yield format_stream_event(state)

      # First part: gather search results
      try:
          # Get user query from last message
          user_query = state.messages[-1].content if state.messages else ""

          # Get action output if available
          action_output = state.phase_outputs.get("action", "")

          # Gather search results
          search_results = await perform_search(user_query, action_output)

          # Format preliminary results for display
          formatted_results = format_search_results(search_results)

          # Add preliminary results to state
          state.phase_outputs["experience"] = formatted_results
          yield format_stream_event(state)

          # Interrupt for human review
          reviewed_results = interrupt({
              "type": "review_search",
              "original_results": search_results,
              "message": "Please review these search results before proceeding.",
              "phase": "experience"
          })

          # Use reviewed or original results
          final_results = reviewed_results or search_results

          # Update results in state
          state.search_results = final_results

          # Process the results into a coherent response
          experience_content = await enhance_with_search_results(
              action_output,
              final_results
          )

          # Update phase content
          state.phase_outputs["experience"] = experience_content

          # Mark phase as complete
          state.phase_state["experience"] = "complete"
          yield format_stream_event(state)

          # Return final state update
          return {
              "search_results": final_results,
              "phase_outputs": {**state.phase_outputs, "experience": experience_content},
              "phase_state": {**state.phase_state, "experience": "complete"},
              "current_phase": "intention"  # Move to next phase if implemented, or yield if not
          }
      except Exception as e:
          # Handle error...

  ```

- [ ] Add helper functions for search result formatting:

  ```python
  def format_search_results(results: List[Dict[str, Any]]) -> str:
      """Format search results for display in the UI."""
      formatted = "## Search Results\n\n"

      for i, result in enumerate(results, 1):
          title = result.get("title", "No title")
          snippet = result.get("snippet", "No snippet available")
          url = result.get("url", "#")

          formatted += f"### {i}. {title}\n"
          formatted += f"{snippet}\n"
          formatted += f"Source: {url}\n\n"

      if not results:
          formatted += "No relevant search results found."

      return formatted
  ```

### 3. Human Review for Generated Content

- [ ] Implement content review for action phase:

  ```python
  async def action_node_with_review(state: PostChainState) -> Dict[str, Any]:
      """Action phase with human review of generated content."""
      # Set phase to processing
      state.phase_state["action"] = "processing"
      yield format_stream_event(state)

      try:
          # Process using LLM
          user_input = state.messages[-1].content if state.messages else ""

          # Generate draft response
          draft_response = await process_with_llm(user_input)

          # Update state with draft
          state.phase_outputs["action"] = draft_response

          # Mark as awaiting review
          state.phase_state["action"] = "awaiting_review"
          yield format_stream_event(state)

          # Interrupt for human review
          reviewed_content = interrupt({
              "type": "review_content",
              "original_content": draft_response,
              "message": "Please review this generated content before proceeding.",
              "phase": "action"
          })

          # Use reviewed or original content
          final_content = reviewed_content or draft_response

          # Update state
          state.phase_outputs["action"] = final_content

          # Mark as complete
          state.phase_state["action"] = "complete"
          yield format_stream_event(state)

          # Return final state update
          return {
              "phase_outputs": {**state.phase_outputs, "action": final_content},
              "phase_state": {**state.phase_state, "action": "complete"},
              "current_phase": "experience"  # Move to next phase
          }
      except Exception as e:
          # Handle error...
  ```

### 4. Resume Handling

- [ ] Add endpoint for resuming interrupted conversations:

  ```python
  @router.post("/resume")
  async def resume_postchain(
      request: ResumePostChainRequest,
      config: Config = Depends(get_config)
  ):
      thread_id = validate_thread_id(request.thread_id)

      if request.stream:
          async def stream_generator():
              try:
                  # Create graph
                  graph = create_postchain_graph(thread_id)

                  # Resume with provided value
                  async for chunk in graph.astream(
                      Command(resume=request.resume_value)
                  ):
                      # Handle chunks as in the original endpoint
                      # ...

              except Exception as e:
                  # Handle errors
                  # ...

              # End of stream
              yield "data: [DONE]\n\n"

          return StreamingResponse(
              stream_generator(),
              media_type="text/event-stream"
          )
      else:
          # Non-streaming implementation
          # ...
  ```

- [ ] Create request model for resume in `api/app/schemas/postchain.py`:
  ```python
  class ResumePostChainRequest(BaseModel):
      """Request model for resuming an interrupted PostChain conversation."""
      thread_id: str
      resume_value: Any
      stream: bool = True
  ```

### 5. Cancellation Handling

- [ ] Add endpoint for cancelling ongoing operations:

  ```python
  @router.post("/cancel")
  async def cancel_postchain(
      request: CancelPostChainRequest,
      config: Config = Depends(get_config)
  ):
      thread_id = validate_thread_id(request.thread_id)

      try:
          # Create graph (needed for state access)
          graph = create_postchain_graph(thread_id)

          # Load existing state
          memory = MemorySaver(f"postchain_{thread_id}")
          state = memory.load()

          if state:
              # Mark any processing phases as cancelled
              for phase in state.phase_state:
                  if state.phase_state[phase] == "processing":
                      state.phase_state[phase] = "cancelled"

              # Set error message
              state.error = "Operation cancelled by user"

              # Save updated state
              memory.save(state)

              return {"status": "cancelled", "thread_id": thread_id}
          else:
              return {"status": "not_found", "thread_id": thread_id}

      except Exception as e:
          logger.error(f"Error cancelling operation: {e}")
          return {"status": "error", "error": str(e), "thread_id": thread_id}
  ```

- [ ] Create request model for cancellation:
  ```python
  class CancelPostChainRequest(BaseModel):
      """Request model for cancelling a PostChain operation."""
      thread_id: str
  ```

### 6. State Recovery

- [ ] Implement state recovery after interruptions:

  ```python
  def recover_interrupted_state(thread_id: str) -> Optional[PostChainState]:
      """Recover state after an interruption."""
      thread_id = validate_thread_id(thread_id)
      memory = MemorySaver(f"postchain_{thread_id}")

      try:
          # Load existing state
          state = memory.load()

          if state:
              # Check if any phase is in "awaiting_review" state
              awaiting_review = False
              for phase, status in state.phase_state.items():
                  if status == "awaiting_review":
                      awaiting_review = True
                      break

              if awaiting_review:
                  # State is valid for resuming
                  return state

              # If no phase is awaiting review, state may be corrupted
              # Mark all processing phases as error
              for phase, status in state.phase_state.items():
                  if status == "processing":
                      state.phase_state[phase] = "error"

              state.error = "Conversation was interrupted and could not be recovered"
              return state

          return None

      except Exception as e:
          logger.error(f"Error recovering state: {e}")
          return None
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

1. **Interrupt Testing**:

   ```bash
   # Start a request that will trigger an interrupt
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Search for quantum computing breakthroughs", "thread_id": "test-interrupt"}'

   # Resume with a review decision
   curl -X POST http://localhost:8000/postchain/resume \
     -H "Content-Type: application/json" \
     -d '{"thread_id": "test-interrupt", "resume_value": {"approved": true, "edited_results": null}}'
   ```

2. **Cancellation Testing**:

   ```bash
   # Start a request
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Tell me about quantum computing", "thread_id": "test-cancel"}'

   # Cancel it
   curl -X POST http://localhost:8000/postchain/cancel \
     -H "Content-Type: application/json" \
     -d '{"thread_id": "test-cancel"}'
   ```

3. **Recovery Testing**: Test recovery after a simulated crash

## 📊 Success Criteria

This slice is complete when:

1. The system successfully interrupts for human review of search results
2. Content can be reviewed before being finalized
3. Operations can be cancelled gracefully
4. The system recovers properly from interruptions
5. All interrupt and cancellation events are properly communicated to the frontend
6. The frontend can resume interrupted conversations

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Interrupts require persistence** - Always compile graphs with a checkpointer
3. **Handle timeouts gracefully** - Consider what happens if users don't respond to interrupts
4. **Preserve state integrity** - Ensure state remains valid after interruptions
5. **Log interrupt events** - Track all interrupts and resumptions for debugging
