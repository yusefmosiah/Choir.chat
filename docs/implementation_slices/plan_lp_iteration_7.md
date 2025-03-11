# PostChain LangGraph Implementation Plan - Slice 7: Intention & Observation Phases

This slice focuses on implementing the Intention and Observation phases of the PostChain system, expanding the AEIOU-Y cycle beyond the existing Action and Experience phases.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/postchain/schemas/state.py` - Pydantic models for state management

### Frontend Files

- `Choir/Views/PostchainView.swift` - UI for displaying PostChain phases
- `Choir/ViewModels/PostchainViewModel.swift` - ViewModel for PostChain state management

## 🎯 Goals for This Slice

1. Implement the Intention phase to analyze and clarify user intent
2. Implement the Observation phase to record semantic connections
3. Update the graph structure to include the new phases
4. Ensure proper phase transitions and state management
5. Integrate with the existing Action and Experience phases

## 🔄 Frontend-Backend Integration Context

The frontend expects:

- Each AEIOU-Y phase to have its own card in the UI
- Phase transitions to be clearly signaled
- Phase-specific content to be properly formatted
- Consistent state management across all phases

## 📋 Implementation Tasks

### 1. Intention Phase Implementation

- [ ] Implement the intention phase handler in `api/app/postchain/simple_graph.py`:

  ```python
  async def intention_node(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Handle the intention phase to analyze and clarify user intent."""
      # Set phase to processing
      state.phase_state["intention"] = "processing"
      yield format_stream_event(state, content="Analyzing intent...")

      try:
          # Get user query from last message
          user_query = state.messages[-1].content if state.messages else ""

          # Get action and experience outputs
          action_output = state.phase_outputs.get("action", "")
          experience_output = state.phase_outputs.get("experience", "")

          # Initialize model selector
          model_config = ModelConfig(
              disabled_providers=config.get("disabled_providers", []) if config else [],
              provider_models=config.get("provider_models", {}) if config else {}
          )
          selector = ModelSelector(model_config, logger=logger)

          # Get appropriate model
          llm = selector.get_model_for_phase("intention", ModelCapability.BASIC, temperature=0)

          # Create prompt for intent analysis
          prompt = ChatPromptTemplate.from_messages([
              ("system", "You are an AI assistant tasked with analyzing user intent. "
                        "Your goal is to identify the core intention behind the user's query, "
                        "detect any ambiguities, and clarify the intent. "
                        "Focus on understanding what the user is truly asking for, "
                        "not just the literal interpretation of their words."),
              ("user", f"User query: {user_query}\n\n"
                      f"Initial response: {action_output}\n\n"
                      f"Enhanced response: {experience_output}\n\n"
                      f"Please analyze the user's intent, identify any ambiguities, "
                      f"and provide a clear statement of what the user is truly asking for.")
          ])

          # Create chain
          chain = prompt | llm

          # Generate intent analysis
          response = await chain.ainvoke({})

          # Extract content
          intent_analysis = response.content if hasattr(response, "content") else str(response)

          # Extract structured intent data
          intent_data = await extract_intent_data(intent_analysis, user_query, llm)

          # Update state
          state.phase_outputs["intention"] = intent_analysis

          # Store intent data in metadata
          if "intent" not in state.metadata:
              state.metadata["intent"] = {}

          state.metadata["intent"] = intent_data

          # Mark phase as complete
          state.phase_state["intention"] = "complete"
          yield format_stream_event(state)

          # Return updated state
          return {
              "phase_outputs": {**state.phase_outputs, "intention": intent_analysis},
              "phase_state": {**state.phase_state, "intention": "complete"},
              "current_phase": "observation",
              "metadata": {**state.metadata, "intent": intent_data}
          }
      except Exception as e:
          # Handle error
          logger.error(f"Error in intention phase: {e}")

          # Update state
          handle_phase_error(state, "intention", e)

          yield format_stream_event(state, error=str(e))

          # Return error state
          return {
              "phase_outputs": state.phase_outputs,
              "phase_state": {**state.phase_state, "intention": "error"},
              "error": str(e),
              "current_phase": "yield"  # Skip to end on error
          }
  ```

- [ ] Implement intent data extraction utility:

  ````python
  async def extract_intent_data(
      intent_analysis: str,
      user_query: str,
      llm: BaseChatModel
  ) -> Dict[str, Any]:
      """Extract structured intent data from intent analysis."""
      # Create prompt for structured extraction
      prompt = ChatPromptTemplate.from_messages([
          ("system", "Extract structured intent data from the intent analysis. "
                    "Return a JSON object with the following fields:\n"
                    "- primary_intent: The main intention of the user\n"
                    "- ambiguities: List of any ambiguous aspects of the query\n"
                    "- clarifications: List of clarifications that would help\n"
                    "- entities: List of key entities mentioned in the query\n"
                    "- sentiment: The emotional tone of the query (neutral, positive, negative, etc.)\n"
                    "- complexity: A rating of query complexity (simple, moderate, complex)"),
          ("user", f"User query: {user_query}\n\n"
                  f"Intent analysis: {intent_analysis}\n\n"
                  f"Extract the structured intent data in JSON format.")
      ])

      # Create chain
      chain = prompt | llm

      try:
          # Generate structured data
          response = await chain.ainvoke({})

          # Extract content
          content = response.content if hasattr(response, "content") else str(response)

          # Parse JSON from content
          # Find JSON block in the response
          import re
          import json

          json_match = re.search(r'```json\n(.*?)\n```', content, re.DOTALL)
          if json_match:
              json_str = json_match.group(1)
          else:
              json_str = re.search(r'{.*}', content, re.DOTALL)
              if json_str:
                  json_str = json_str.group(0)
              else:
                  json_str = content

          # Parse JSON
          try:
              intent_data = json.loads(json_str)
          except json.JSONDecodeError:
              # Fallback to basic structure if JSON parsing fails
              intent_data = {
                  "primary_intent": "unknown",
                  "ambiguities": [],
                  "clarifications": [],
                  "entities": [],
                  "sentiment": "neutral",
                  "complexity": "unknown"
              }

          return intent_data
      except Exception as e:
          logger.error(f"Error extracting intent data: {e}")

          # Return basic structure on error
          return {
              "primary_intent": "unknown",
              "ambiguities": [],
              "clarifications": [],
              "entities": [],
              "sentiment": "neutral",
              "complexity": "unknown",
              "error": str(e)
          }
  ````

### 2. Observation Phase Implementation

- [ ] Implement the observation phase handler in `api/app/postchain/simple_graph.py`:

  ```python
  async def observation_node(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Handle the observation phase to record semantic connections."""
      # Set phase to processing
      state.phase_state["observation"] = "processing"
      yield format_stream_event(state, content="Recording semantic connections...")

      try:
          # Get user query from last message
          user_query = state.messages[-1].content if state.messages else ""

          # Get outputs from previous phases
          action_output = state.phase_outputs.get("action", "")
          experience_output = state.phase_outputs.get("experience", "")
          intention_output = state.phase_outputs.get("intention", "")

          # Get intent data
          intent_data = state.metadata.get("intent", {})

          # Initialize model selector
          model_config = ModelConfig(
              disabled_providers=config.get("disabled_providers", []) if config else [],
              provider_models=config.get("provider_models", {}) if config else {}
          )
          selector = ModelSelector(model_config, logger=logger)

          # Get appropriate model
          llm = selector.get_model_for_phase("observation", ModelCapability.BASIC, temperature=0)

          # Create prompt for semantic connections
          prompt = ChatPromptTemplate.from_messages([
              ("system", "You are an AI assistant tasked with recording semantic connections. "
                        "Your goal is to identify key contextual elements, create associations with prior knowledge, "
                        "and prepare metadata for the understanding phase. "
                        "Focus on the relationships between concepts, entities, and ideas."),
              ("user", f"User query: {user_query}\n\n"
                      f"Action output: {action_output}\n\n"
                      f"Experience output: {experience_output}\n\n"
                      f"Intention output: {intention_output}\n\n"
                      f"Intent data: {json.dumps(intent_data, indent=2)}\n\n"
                      f"Please identify key contextual elements, create associations with prior knowledge, "
                      f"and prepare metadata for the understanding phase.")
          ])

          # Create chain
          chain = prompt | llm

          # Generate semantic connections
          response = await chain.ainvoke({})

          # Extract content
          observation_output = response.content if hasattr(response, "content") else str(response)

          # Extract structured observation data
          observation_data = await extract_observation_data(observation_output, user_query, llm)

          # Update state
          state.phase_outputs["observation"] = observation_output

          # Store observation data in metadata
          if "observation" not in state.metadata:
              state.metadata["observation"] = {}

          state.metadata["observation"] = observation_data

          # Mark phase as complete
          state.phase_state["observation"] = "complete"
          yield format_stream_event(state)

          # Return updated state
          return {
              "phase_outputs": {**state.phase_outputs, "observation": observation_output},
              "phase_state": {**state.phase_state, "observation": "complete"},
              "current_phase": "understanding",
              "metadata": {**state.metadata, "observation": observation_data}
          }
      except Exception as e:
          # Handle error
          logger.error(f"Error in observation phase: {e}")

          # Update state
          handle_phase_error(state, "observation", e)

          yield format_stream_event(state, error=str(e))

          # Return error state
          return {
              "phase_outputs": state.phase_outputs,
              "phase_state": {**state.phase_state, "observation": "error"},
              "error": str(e),
              "current_phase": "yield"  # Skip to end on error
          }
  ```

- [ ] Implement observation data extraction utility:

  ````python
  async def extract_observation_data(
      observation_output: str,
      user_query: str,
      llm: BaseChatModel
  ) -> Dict[str, Any]:
      """Extract structured observation data from observation output."""
      # Create prompt for structured extraction
      prompt = ChatPromptTemplate.from_messages([
          ("system", "Extract structured observation data from the observation output. "
                    "Return a JSON object with the following fields:\n"
                    "- key_concepts: List of key concepts identified\n"
                    "- entities: List of entities with their types\n"
                    "- relationships: List of relationships between concepts/entities\n"
                    "- knowledge_gaps: List of areas where more information is needed\n"
                    "- context_elements: List of important contextual elements\n"
                    "- metadata_tags: List of tags for categorization"),
          ("user", f"User query: {user_query}\n\n"
                  f"Observation output: {observation_output}\n\n"
                  f"Extract the structured observation data in JSON format.")
      ])

      # Create chain
      chain = prompt | llm

      try:
          # Generate structured data
          response = await chain.ainvoke({})

          # Extract content
          content = response.content if hasattr(response, "content") else str(response)

          # Parse JSON from content
          # Find JSON block in the response
          import re
          import json

          json_match = re.search(r'```json\n(.*?)\n```', content, re.DOTALL)
          if json_match:
              json_str = json_match.group(1)
          else:
              json_str = re.search(r'{.*}', content, re.DOTALL)
              if json_str:
                  json_str = json_str.group(0)
              else:
                  json_str = content

          # Parse JSON
          try:
              observation_data = json.loads(json_str)
          except json.JSONDecodeError:
              # Fallback to basic structure if JSON parsing fails
              observation_data = {
                  "key_concepts": [],
                  "entities": [],
                  "relationships": [],
                  "knowledge_gaps": [],
                  "context_elements": [],
                  "metadata_tags": []
              }

          return observation_data
      except Exception as e:
          logger.error(f"Error extracting observation data: {e}")

          # Return basic structure on error
          return {
              "key_concepts": [],
              "entities": [],
              "relationships": [],
              "knowledge_gaps": [],
              "context_elements": [],
              "metadata_tags": [],
              "error": str(e)
          }
  ````

### 3. Update Graph Structure

- [ ] Update the graph structure in `api/app/postchain/simple_graph.py`:

  ```python
  def create_postchain_graph(thread_id: str = None) -> Runnable:
      """Create a PostChain graph with all implemented phases."""
      thread_id = validate_thread_id(thread_id)

      # Create state graph
      builder = StateGraph(PostChainState)

      # Create retry policy
      retry_policy = create_retry_policy()

      # Add nodes with retry
      builder.add_node("action", retry_policy.with_fallbacks(action_node))
      builder.add_node("experience", retry_policy.with_fallbacks(experience_node))
      builder.add_node("intention", retry_policy.with_fallbacks(intention_node))
      builder.add_node("observation", retry_policy.with_fallbacks(observation_node))

      # Add edges for sequential flow
      builder.add_edge("action", "experience")
      builder.add_edge("experience", "intention")
      builder.add_edge("intention", "observation")
      builder.add_edge("observation", END)  # For now, end at observation

      # Set entry point
      builder.set_entry_point("action")

      # Configure persistence
      memory = MemorySaver(f"postchain_{thread_id}")

      # Compile with persistence
      return builder.compile(checkpointer=memory)
  ```

### 4. Intent-Aware Context Filtering

- [ ] Implement intent-aware context filtering in `api/app/postchain/utils.py`:

  ```python
  def filter_messages_with_intent(
      state: PostChainState,
      intent_data: Dict[str, Any] = None
  ) -> List[BaseMessage]:
      """Filter messages based on intent data."""
      # Get basic filtered messages
      filtered_messages = filter_messages(state)

      # If no intent data, return basic filtered messages
      if not intent_data:
          intent_data = state.metadata.get("intent", {})

      if not intent_data:
          return filtered_messages

      # Get complexity from intent data
      complexity = intent_data.get("complexity", "unknown")

      # Adjust window size based on complexity
      if complexity == "simple":
          # For simple queries, we need less context
          window_size = min(state.context_window_size, 5)
      elif complexity == "complex":
          # For complex queries, we need more context
          window_size = state.context_window_size
      else:
          # Default to standard window size
          window_size = state.context_window_size

      # If we have fewer messages than window size, return all
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

### 5. Metadata Annotation for Important Messages

- [ ] Implement metadata annotation in `api/app/postchain/utils.py`:

  ```python
  def annotate_message_with_metadata(
      state: PostChainState,
      content: str,
      phase: str,
      metadata: Dict[str, Any] = None
  ) -> None:
      """Add a message with rich metadata annotation."""
      # Create base metadata
      base_metadata = {
          "phase": phase,
          "timestamp": datetime.now().isoformat(),
          "thread_id": state.thread_id
      }

      # Add phase-specific metadata
      if phase == "intention":
          # Add intent data
          intent_data = state.metadata.get("intent", {})
          if intent_data:
              base_metadata["intent"] = intent_data
      elif phase == "observation":
          # Add observation data
          observation_data = state.metadata.get("observation", {})
          if observation_data:
              base_metadata["observation"] = observation_data

      # Add custom metadata if provided
      if metadata:
          base_metadata.update(metadata)

      # Create message with metadata
      message = AIMessage(
          content=content,
          metadata=base_metadata
      )

      # Add to messages list
      state.messages.append(message)

      # Also store in phase outputs
      state.phase_outputs[phase] = content
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

1. **Intention Phase Tests**:

   ```bash
   # Test intention phase
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "I need information about quantum computing for a presentation", "stream": true}'
   ```

2. **Observation Phase Tests**:

   ```bash
   # Test observation phase
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Compare and contrast different quantum computing architectures", "stream": true}'
   ```

3. **Intent-Aware Context Tests**:
   ```bash
   # Test with complex query
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Explain the relationship between quantum entanglement and quantum teleportation in the context of quantum information theory", "stream": true}'
   ```

## 📊 Success Criteria

This slice is complete when:

1. The Intention phase correctly analyzes and clarifies user intent
2. The Observation phase properly records semantic connections
3. The graph structure includes all implemented phases
4. Phase transitions work correctly
5. Intent-aware context filtering adjusts based on query complexity
6. Metadata annotation enriches messages with phase-specific data
7. The frontend displays all phases correctly

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **Phase transitions are critical** - Ensure each phase correctly updates the current_phase field
3. **Error handling is essential** - Each phase must handle errors gracefully
4. **Metadata enrichment is important** - Properly annotate messages with phase-specific metadata
5. **Frontend integration** - Ensure all phases produce output in the format expected by the frontend
