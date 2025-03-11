# PostChain LangGraph Implementation Plan - Slice 3: Context Window Management & Multiturn Support

This slice focuses on implementing context window management and multiturn conversation support for the PostChain system, ensuring efficient token usage and maintaining conversation context across interactions.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/postchain/schemas/state.py` - Pydantic models for state management
- `api/app/langchain_utils.py` - Utility functions for working with language models

### Frontend Files

- `Choir/Protocols/PostchainCoordinator.swift` - Protocol defining PostChain coordination
- `Choir/ViewModels/PostchainViewModel.swift` - ViewModel for PostChain state management

## 🎯 Goals for This Slice

1. Implement message filtering to manage context window size
2. Add sliding window context management for long conversations
3. Create conversation summarization capabilities
4. Implement message attribution with phase metadata
5. Ensure proper multiturn conversation handling

## 🔄 Frontend-Backend Integration Context

The frontend expects:

- Conversations to maintain context across multiple interactions
- Messages to be attributed to the correct phases
- Performance to remain consistent even with long conversation histories

## 📋 Implementation Tasks

### 1. Context Window Management

- [ ] Implement message filtering function in `api/app/postchain/utils.py`:

  ```python
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

- [ ] Add token counting utility:

  ```python
  def count_tokens(messages: List[BaseMessage], model_name: str = "gpt-3.5-turbo") -> int:
      """Count tokens in a list of messages."""
      from langchain_core.language_models.utils import get_token_counter

      token_counter = get_token_counter(model_name)
      total_tokens = 0

      for message in messages:
          if hasattr(message, "content") and message.content:
              total_tokens += token_counter(message.content)

      # Add overhead for message formatting
      total_tokens += len(messages) * 4  # Approximate overhead per message

      return total_tokens
  ```

- [ ] Create dynamic window size adjustment:

  ```python
  def adjust_window_size(state: PostChainState, model_name: str, max_tokens: int = 4000) -> int:
      """Dynamically adjust window size based on token count."""
      current_size = state.context_window_size
      all_messages = state.messages

      # Count tokens in all messages
      total_tokens = count_tokens(all_messages, model_name)

      # If under limit, no adjustment needed
      if total_tokens <= max_tokens:
          return current_size

      # Calculate how many messages to keep
      tokens_per_message = total_tokens / len(all_messages) if all_messages else 0
      if tokens_per_message > 0:
          new_size = int(max_tokens / tokens_per_message) - 2  # Buffer
          return max(3, min(new_size, current_size))  # At least 3 messages

      return current_size
  ```

### 2. Conversation Summarization

- [ ] Implement incremental summarization utility:

  ```python
  async def summarize_conversation(
      messages: List[BaseMessage],
      existing_summary: str = None,
      model_name: str = "gpt-3.5-turbo"
  ) -> str:
      """Summarize or update summary of conversation history."""
      from langchain_openai import ChatOpenAI
      from langchain_core.prompts import ChatPromptTemplate

      # Skip if too few messages
      if len(messages) < 3:
          return existing_summary or ""

      # Create LLM
      llm = ChatOpenAI(model_name=model_name, temperature=0)

      # Create prompt based on whether we have an existing summary
      if existing_summary:
          prompt = ChatPromptTemplate.from_template(
              "You are an AI assistant tasked with incrementally updating a conversation summary.\n\n"
              "Previous summary: {existing_summary}\n\n"
              "New messages to incorporate:\n{new_messages}\n\n"
              "Please update the summary to include the key points from the new messages. "
              "Keep the summary concise but comprehensive."
          )

          # Format new messages as string
          new_messages_str = "\n".join([
              f"{msg.type}: {msg.content}" for msg in messages[-3:]
          ])

          # Generate updated summary
          chain = prompt | llm
          result = await chain.ainvoke({
              "existing_summary": existing_summary,
              "new_messages": new_messages_str
          })

          return result.content
      else:
          # Create new summary
          prompt = ChatPromptTemplate.from_template(
              "You are an AI assistant tasked with summarizing a conversation.\n\n"
              "Conversation:\n{messages}\n\n"
              "Please create a concise but comprehensive summary of the key points discussed."
          )

          # Format all messages as string
          messages_str = "\n".join([
              f"{msg.type}: {msg.content}" for msg in messages
          ])

          # Generate summary
          chain = prompt | llm
          result = await chain.ainvoke({
              "messages": messages_str
          })

          return result.content
  ```

- [ ] Add automatic summarization trigger:

  ```python
  async def update_summary_if_needed(state: PostChainState, model_name: str, threshold: int = 10) -> PostChainState:
      """Update conversation summary if message count exceeds threshold."""
      # Only summarize if we have enough messages
      if len(state.messages) >= threshold:
          # Check if we need a new or updated summary
          if not state.summary or len(state.messages) % 5 == 0:  # Update every 5 messages
              state.summary = await summarize_conversation(
                  state.messages,
                  existing_summary=state.summary,
                  model_name=model_name
              )

      return state
  ```

### 3. Message Attribution

- [ ] Add message attribution function:

  ```python
  def attribute_message_to_phase(state: PostChainState, content: str, phase: str) -> None:
      """Add a message with attribution to the specified phase."""
      # Create message with metadata
      message = AIMessage(
          content=content,
          metadata={
              "phase": phase,
              "timestamp": datetime.now().isoformat(),
              "thread_id": state.thread_id
          }
      )

      # Add to messages list
      state.messages.append(message)

      # Also store in phase outputs
      state.phase_outputs[phase] = content
  ```

- [ ] Add phase transition tracking:

  ```python
  def track_phase_transition(state: PostChainState, from_phase: str, to_phase: str) -> None:
      """Track phase transitions in state metadata."""
      transitions = state.metadata.get("phase_transitions", [])

      # Add transition with timestamp
      transitions.append({
          "from": from_phase,
          "to": to_phase,
          "timestamp": datetime.now().isoformat()
      })

      # Update metadata
      state.metadata["phase_transitions"] = transitions

      # Update current phase
      state.current_phase = to_phase
  ```

### 4. Multiturn Support

- [ ] Update node handlers for multiturn context:

  ```python
  async def action_node(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Handle the action phase with multiturn context support."""
      # Set phase to processing
      state.phase_state["action"] = "processing"
      yield format_stream_event(state)

      # Apply context window management
      model_name = config.get("model_name", "gpt-3.5-turbo") if config else "gpt-3.5-turbo"
      max_tokens = config.get("max_tokens", 4000) if config else 4000

      # Adjust window size based on token count
      state.context_window_size = adjust_window_size(state, model_name, max_tokens)

      # Filter messages to fit context window
      filtered_messages = filter_messages(state)

      try:
          # Process using LLM with filtered messages
          user_input = state.messages[-1].content if state.messages else ""

          # Create system message with context
          if state.summary:
              system_content = f"You are a helpful AI assistant. Here's a summary of the conversation so far: {state.summary}"
          else:
              system_content = "You are a helpful AI assistant."

          # Process with context-appropriate messages
          response = await process_with_llm(
              user_input,
              conversation_history=filtered_messages,
              system_message=system_content,
              model_name=model_name
          )

          # Attribute message to phase
          attribute_message_to_phase(state, response, "action")

          # Update summary if needed
          await update_summary_if_needed(state, model_name)

          # Mark phase as complete
          state.phase_state["action"] = "complete"
          yield format_stream_event(state)

          # Track phase transition
          track_phase_transition(state, "action", "experience")

          # Return updated state
          return {
              "phase_outputs": {**state.phase_outputs, "action": response},
              "phase_state": {**state.phase_state, "action": "complete"},
              "current_phase": "experience"  # Move to next phase
          }
      except Exception as e:
          # Error handling...
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
tiktoken>=0.5.0  # For token counting
```

## 🔄 Testing

1. **Token Management Tests**: Create tests for context window management

   ```bash
   # From api directory
   python -m pytest tests/postchain/test_context_management.py -v
   ```

2. **Multiturn Conversation Tests**:

   ```bash
   # Test multiturn with the same thread ID
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Tell me about quantum computing", "thread_id": "test-multiturn"}'

   # Follow-up query
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Continue explaining superconducting qubits", "thread_id": "test-multiturn"}'
   ```

3. **Summarization Tests**: Test summary generation with a long conversation

## 📊 Success Criteria

This slice is complete when:

1. Long conversations are properly managed within token limits
2. Messages are correctly attributed to phases
3. Conversation context is maintained across multiple interactions
4. Summarization triggers at appropriate thresholds
5. Phase transitions are properly tracked in metadata
6. The system maintains performance regardless of conversation length

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Token counting is approximate** - Token counts may vary by model, so include safety margins
3. **Manage context window carefully** - Always implement message filtering to prevent token limits
4. **Balance context vs. efficiency** - Too much context increases costs and latency
5. **Test with real conversations** - Use realistic conversation patterns for testing
