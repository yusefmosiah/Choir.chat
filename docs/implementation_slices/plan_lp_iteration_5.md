# PostChain LangGraph Implementation Plan - Slice 5: Model Flexibility & Error Handling

This slice focuses on implementing model-agnostic architecture and robust error handling for the PostChain system, ensuring resilience and adaptability to different LLM providers.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/langchain_utils.py` - Utility functions for working with language models
- `api/app/config.py` - Configuration settings including model identifiers

## 🎯 Goals for This Slice

1. Abstract model selection from node implementation
2. Create model capability detection
3. Implement automatic model fallback mechanisms
4. Add retry policy with exponential backoff
5. Implement comprehensive error detection and handling

## 🔄 Frontend-Backend Integration Context

The frontend requires:

- Graceful degradation when models are unavailable
- Consistent error messaging
- Uninterrupted service despite model failures

## 📋 Implementation Tasks

### 1. Model-Agnostic Architecture

- [ ] Create a model provider abstraction in `api/app/postchain/models.py`:

  ```python
  from enum import Enum
  from typing import Dict, List, Optional, Union
  from langchain_core.language_models import BaseChatModel
  from langchain_core.prompts import ChatPromptTemplate
  from langchain_openai import ChatOpenAI
  from langchain_anthropic import ChatAnthropic
  from langchain_google_vertexai import ChatVertexAI

  class ModelProvider(str, Enum):
      """Enum for supported model providers."""
      OPENAI = "openai"
      ANTHROPIC = "anthropic"
      VERTEXAI = "vertexai"

  class ModelCapability(str, Enum):
      """Enum for model capabilities."""
      BASIC = "basic"  # Basic chat without tool use
      TOOLS = "tools"  # Supports tool calling
      VISION = "vision"  # Supports image input

  # Model configuration
  class ModelConfig:
      """Configuration for model selection and capability detection."""

      def __init__(self,
                   preferred_providers: List[ModelProvider] = None,
                   disabled_providers: List[ModelProvider] = None,
                   provider_models: Dict[ModelProvider, str] = None):
          """Initialize model configuration."""
          self.preferred_providers = preferred_providers or [
              ModelProvider.OPENAI,
              ModelProvider.ANTHROPIC,
              ModelProvider.VERTEXAI
          ]
          self.disabled_providers = disabled_providers or []
          self.provider_models = provider_models or {
              ModelProvider.OPENAI: "gpt-4-turbo",
              ModelProvider.ANTHROPIC: "claude-3-sonnet-20240229",
              ModelProvider.VERTEXAI: "gemini-pro"
          }

      def get_available_providers(self) -> List[ModelProvider]:
          """Get available providers, respecting preferences and disabled status."""
          return [p for p in self.preferred_providers if p not in self.disabled_providers]

      def get_model_for_provider(self, provider: ModelProvider) -> str:
          """Get the model name for a provider."""
          return self.provider_models.get(provider)

      def get_llm(self, provider: ModelProvider, **kwargs) -> BaseChatModel:
          """Get a language model instance for a provider."""
          model_name = self.get_model_for_provider(provider)

          if provider == ModelProvider.OPENAI:
              return ChatOpenAI(model_name=model_name, **kwargs)
          elif provider == ModelProvider.ANTHROPIC:
              return ChatAnthropic(model_name=model_name, **kwargs)
          elif provider == ModelProvider.VERTEXAI:
              return ChatVertexAI(model_name=model_name, **kwargs)
          else:
              raise ValueError(f"Unsupported provider: {provider}")

      def has_capability(self, provider: ModelProvider, capability: ModelCapability) -> bool:
          """Check if a provider has a specific capability."""
          model_name = self.get_model_for_provider(provider)

          # Tool capability check
          if capability == ModelCapability.TOOLS:
              if provider == ModelProvider.OPENAI and model_name in ["gpt-4-turbo", "gpt-3.5-turbo"]:
                  return True
              if provider == ModelProvider.ANTHROPIC and model_name in ["claude-3-opus", "claude-3-sonnet"]:
                  return True
              if provider == ModelProvider.VERTEXAI and "gemini" in model_name:
                  return True

          # Vision capability check
          elif capability == ModelCapability.VISION:
              if provider == ModelProvider.OPENAI and "vision" in model_name:
                  return True
              if provider == ModelProvider.ANTHROPIC and model_name in ["claude-3-opus", "claude-3-sonnet"]:
                  return True
              if provider == ModelProvider.VERTEXAI and "vision" in model_name:
                  return True

          # All models have basic capability
          elif capability == ModelCapability.BASIC:
              return True

          return False
  ```

- [ ] Create a model selector utility in `api/app/postchain/models.py`:

  ```python
  class ModelSelector:
      """Utility for selecting appropriate models based on needed capabilities."""

      def __init__(self,
                   config: ModelConfig,
                   logger=None):
          """Initialize model selector."""
          self.config = config
          self.logger = logger
          self.fallback_attempts = {}  # Track fallback attempts

      def get_model_for_phase(self,
                              phase: str,
                              required_capability: ModelCapability = ModelCapability.BASIC,
                              temperature: float = 0) -> BaseChatModel:
          """Get the appropriate model for a specific phase."""
          # Get available providers
          providers = self.config.get_available_providers()

          # Filter providers with required capability
          capable_providers = [p for p in providers if self.config.has_capability(p, required_capability)]

          if not capable_providers:
              # If no provider with required capability, fall back to basic capability
              if required_capability != ModelCapability.BASIC:
                  self.logger.warning(f"No providers with {required_capability} capability available. "
                                     f"Falling back to basic capability.")
                  return self.get_model_for_phase(phase, ModelCapability.BASIC, temperature)
              else:
                  raise ValueError("No providers available for basic capability")

          # Try to get a model, with fallback
          for provider in capable_providers:
              try:
                  model = self.config.get_llm(
                      provider,
                      temperature=temperature
                  )

                  # Log success
                  if self.logger:
                      self.logger.info(f"Using {provider} model for {phase} phase")

                  # Reset fallback attempts for this phase
                  self.fallback_attempts[phase] = []

                  return model
              except Exception as e:
                  # Track fallback attempt
                  if phase not in self.fallback_attempts:
                      self.fallback_attempts[phase] = []

                  self.fallback_attempts[phase].append({
                      "provider": provider,
                      "error": str(e)
                  })

                  # Log fallback
                  if self.logger:
                      self.logger.warning(f"Failed to initialize {provider} model: {e}. "
                                         f"Trying next provider.")
                  continue

          # If we get here, all providers failed
          raise ValueError(f"All providers failed for {phase} phase. "
                          f"Attempts: {self.fallback_attempts.get(phase, [])}")
  ```

- [ ] Update the phase handlers to use the model selector:

  ```python
  async def action_node(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Handle the action phase with model flexibility."""
      # Set phase to processing
      state.phase_state["action"] = "processing"
      yield format_stream_event(state)

      try:
          # Initialize model selector
          model_config = ModelConfig(
              disabled_providers=config.get("disabled_providers", []),
              provider_models=config.get("provider_models", {})
          )
          selector = ModelSelector(model_config, logger=logger)

          # Get appropriate model for the phase
          try:
              # First try with a model that has tool capability
              llm = selector.get_model_for_phase("action", ModelCapability.TOOLS, temperature=0.7)
          except ValueError:
              # Fall back to a basic model if no tool-capable model is available
              llm = selector.get_model_for_phase("action", ModelCapability.BASIC, temperature=0.7)

          # Track model selection in state
          state.metadata["model_info"] = {
              "action": {
                  "provider": llm.model_name,
                  "capabilities": "tools" if hasattr(llm, "tools") else "basic"
              }
          }

          # Process using the selected model
          user_input = state.messages[-1].content if state.messages else ""

          # Filter messages to fit context window
          filtered_messages = filter_messages(state)

          # Create system message
          system_content = "You are a helpful AI assistant."
          if state.summary:
              system_content += f" Here's a summary of the conversation so far: {state.summary}"

          # Create prompt
          prompt = ChatPromptTemplate.from_messages([
              ("system", system_content),
              *[(m.type, m.content) for m in filtered_messages]
          ])

          # Create chain
          chain = prompt | llm

          # Generate response
          response = await chain.ainvoke({})

          # Extract content from response
          response_content = response.content if hasattr(response, "content") else str(response)

          # Update state
          state.phase_outputs["action"] = response_content
          state.phase_state["action"] = "complete"

          # Add model attempt to state
          if "model_attempts" not in state.metadata:
              state.metadata["model_attempts"] = {}

          state.metadata["model_attempts"]["action"] = [
              {"provider": llm.model_name, "success": True}
          ]

          yield format_stream_event(state)

          # Return updated state
          return {
              "phase_outputs": {**state.phase_outputs, "action": response_content},
              "phase_state": {**state.phase_state, "action": "complete"},
              "current_phase": "experience",  # Move to next phase
              "metadata": state.metadata
          }
      except Exception as e:
          # Log error
          logger.error(f"Error in action phase: {e}")

          # Add error to state
          handle_phase_error(state, "action", e)

          yield format_stream_event(state, error=str(e))

          # Return error state
          return {
              "phase_outputs": state.phase_outputs,
              "phase_state": {**state.phase_state, "action": "error"},
              "error": str(e),
              "current_phase": "yield"  # Skip to end on error
          }
  ```

### 2. Fallback & Retry Mechanisms

- [ ] Implement LangGraph's RetryPolicy in `api/app/postchain/simple_graph.py`:

  ```python
  from langgraph.prebuilt import RetryPolicy

  # Create retry policy with exponential backoff
  def create_retry_policy(max_retries: int = 3, retry_delay_seconds: float = 1.0):
      """Create a retry policy with exponential backoff."""
      return RetryPolicy(
          max_retries=max_retries,
          retry_delay_seconds=retry_delay_seconds,
          exponential_backoff=True
      )

  # Apply retry policy to graph nodes
  def create_graph_with_retries(thread_id: str = None) -> Runnable:
      """Create a PostChain graph with retry mechanisms."""
      thread_id = validate_thread_id(thread_id)

      # Create graph builder
      builder = StateGraph(PostChainState)

      # Create retry policy
      retry_policy = create_retry_policy()

      # Add nodes with retry
      builder.add_node("action", retry_policy.with_fallbacks(action_node))
      builder.add_node("experience", retry_policy.with_fallbacks(experience_node))

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

- [ ] Implement model fallback logic in a utility function:

  ```python
  async def process_with_fallback(
      user_input: str,
      state: PostChainState,
      phase: str,
      config: Dict[str, Any] = None
  ) -> str:
      """Process input with a model, falling back to alternatives if needed."""
      # Initialize model selector
      model_config = ModelConfig(
          disabled_providers=config.get("disabled_providers", []),
          provider_models=config.get("provider_models", {})
      )
      selector = ModelSelector(model_config, logger=logger)

      # Track attempts
      attempts = []

      # Try with each capability level, falling back as needed
      for capability in [ModelCapability.TOOLS, ModelCapability.BASIC]:
          try:
              # Get appropriate model for the phase
              llm = selector.get_model_for_phase(phase, capability, temperature=0.7)

              # Process using the selected model
              prompt = ChatPromptTemplate.from_messages([
                  ("system", "You are a helpful AI assistant."),
                  ("user", user_input)
              ])

              # Create chain
              chain = prompt | llm

              # Generate response
              response = await chain.ainvoke({})

              # Extract content from response
              response_content = response.content if hasattr(response, "content") else str(response)

              # Track successful attempt
              attempts.append({
                  "provider": llm.model_name,
                  "capability": str(capability),
                  "success": True
              })

              # Update model attempts in state
              if "model_attempts" not in state.metadata:
                  state.metadata["model_attempts"] = {}

              state.metadata["model_attempts"][phase] = attempts

              return response_content
          except Exception as e:
              # Track failed attempt
              attempts.append({
                  "provider": getattr(llm, "model_name", "unknown") if 'llm' in locals() else "unknown",
                  "capability": str(capability),
                  "success": False,
                  "error": str(e)
              })

              # Log error
              logger.warning(f"Model error in {phase} phase with {capability} capability: {e}. Trying fallback.")

              # Continue to next capability level
              continue

      # If we get here, all attempts failed
      error_message = f"All model providers failed for {phase} phase."
      logger.error(f"{error_message} Attempts: {attempts}")

      # Update model attempts in state
      if "model_attempts" not in state.metadata:
          state.metadata["model_attempts"] = {}

      state.metadata["model_attempts"][phase] = attempts

      raise ValueError(error_message)
  ```

### 3. Error Handling

- [ ] Create a comprehensive error handling utility in `api/app/postchain/utils.py`:

  ```python
  def handle_phase_error(state: PostChainState, phase: str, error: Exception) -> None:
      """Handle and record errors for a specific phase."""
      # Update phase state
      state.phase_state[phase] = "error"

      # Add error message
      error_message = str(error)
      state.error = error_message

      # Add to metadata for debugging
      if "errors" not in state.metadata:
          state.metadata["errors"] = {}

      state.metadata["errors"][phase] = {
          "message": error_message,
          "timestamp": datetime.now().isoformat(),
          "type": error.__class__.__name__
      }

      # Log error
      logger.error(f"Error in {phase} phase: {error_message}")
  ```

- [ ] Add provider-specific error detection:

  ```python
  def detect_provider_error(error: Exception) -> Dict[str, Any]:
      """Detect and categorize provider-specific errors."""
      error_str = str(error)
      error_type = error.__class__.__name__

      # OpenAI error detection
      if "openai" in error_type.lower():
          if "rate limit" in error_str.lower():
              return {
                  "provider": "openai",
                  "category": "rate_limit",
                  "retry_recommended": True,
                  "fallback_recommended": True
              }
          elif "context length" in error_str.lower():
              return {
                  "provider": "openai",
                  "category": "context_length",
                  "retry_recommended": False,
                  "fallback_recommended": True,
                  "context_compaction_recommended": True
              }

      # Anthropic error detection
      elif "anthropic" in error_type.lower():
          if "rate_limit" in error_str.lower():
              return {
                  "provider": "anthropic",
                  "category": "rate_limit",
                  "retry_recommended": True,
                  "fallback_recommended": True
              }

      # General error categorization
      if "timeout" in error_str.lower():
          return {
              "category": "timeout",
              "retry_recommended": True,
              "fallback_recommended": True
          }
      elif "permission" in error_str.lower() or "auth" in error_str.lower():
          return {
              "category": "authorization",
              "retry_recommended": False,
              "fallback_recommended": True
          }

      # Default categorization
      return {
          "category": "unknown",
          "retry_recommended": True,
          "fallback_recommended": True
      }
  ```

- [ ] Implement context compaction as a fallback strategy:

  ```python
  async def compact_context(state: PostChainState, max_tokens: int = 2000) -> PostChainState:
      """Compact context to fit within token limits."""
      # Check if we need to compact
      messages = state.messages
      tokens = count_tokens(messages)

      if tokens <= max_tokens:
          return state  # No compaction needed

      # First strategy: Summarize conversation
      if len(messages) > 3:
          # Generate or update summary
          state.summary = await summarize_conversation(
              messages,
              existing_summary=state.summary
          )

          # Reduce to essential messages
          system_messages = [m for m in messages if isinstance(m, SystemMessage)]

          # Keep the last 2-3 messages for immediate context
          last_messages = messages[-3:]

          # Create a new message list
          state.messages = system_messages + last_messages

          # Add a system message with the summary
          if state.summary:
              summary_message = SystemMessage(
                  content=f"Conversation summary: {state.summary}"
              )
              state.messages.insert(1, summary_message)

          # Log compaction
          logger.info(f"Compacted context from {len(messages)} messages to {len(state.messages)} messages")

      return state
  ```

### 4. Use LangGraph's ToolNode for Better Error Handling

- [ ] Integrate ToolNode for search tools in `api/app/postchain/simple_graph.py`:

  ```python
  from langgraph.prebuilt import ToolNode

  # Create a ToolNode for search tools
  def create_search_tool_node(tools: List[BaseTool]):
      """Create a ToolNode for search tools with error handling."""
      # Create the tool node
      tool_node = ToolNode(tools)

      # Add custom error handling to the node
      def wrapped_search_tool_node(state: PostChainState):
          try:
              # Extract the search query
              user_query = state.messages[-1].content if state.messages else ""

              # Update phase state
              state.phase_state["search"] = "processing"
              yield format_stream_event(state, content="Searching for information...")

              # Call the tool node
              result = tool_node.invoke({
                  "query": user_query,
                  "metadata": state.metadata
              })

              # Extract and format results
              formatted_results = format_search_results(result.get("results", []))

              # Update state
              state.search_results = result.get("results", [])
              state.phase_outputs["search"] = formatted_results
              state.phase_state["search"] = "complete"

              yield format_stream_event(state)

              return {
                  "search_results": state.search_results,
                  "phase_outputs": {**state.phase_outputs, "search": formatted_results},
                  "phase_state": {**state.phase_state, "search": "complete"}
              }
          except Exception as e:
              # Handle tool error
              error_info = detect_provider_error(e)

              # Log error
              logger.error(f"Error in search tools: {e}")

              # Update state
              handle_phase_error(state, "search", e)

              yield format_stream_event(state, error=str(e))

              return {
                  "phase_outputs": state.phase_outputs,
                  "phase_state": {**state.phase_state, "search": "error"},
                  "error": str(e)
              }

      return wrapped_search_tool_node
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
langchain-openai>=0.0.5
langchain-anthropic>=0.0.5
langchain-google-vertexai>=0.0.2
pydantic>=2.5.0
```

## 🔄 Testing

1. **Model Flexibility Tests**:

   ```bash
   # Test with specific provider disabled
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Tell me about quantum computing", "disabled_providers": ["openai"]}'
   ```

2. **Error Handling Tests**:

   ```bash
   # Test with invalid API key to trigger fallback
   export OPENAI_API_KEY="invalid-key-to-force-error"
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "What is the weather?"}'
   ```

3. **Retry Tests**: Create long-running tests that trigger rate limits

## 📊 Success Criteria

This slice is complete when:

1. The system can work with multiple model providers interchangeably
2. Models are selected based on required capabilities for each phase
3. The system automatically falls back to alternative models when needed
4. Retry mechanisms handle transient errors
5. Context compaction handles token limit errors
6. Error messages are clear and informative

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Provider-specific errors require careful handling** - Different providers have different error patterns
3. **Balance retries with user experience** - Too many retries can lead to poor UX
4. **Log all model selections and fallbacks** - Critical for debugging
5. **Keep track of token usage** - Some providers charge by token
