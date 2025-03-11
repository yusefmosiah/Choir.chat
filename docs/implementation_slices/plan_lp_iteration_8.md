# PostChain LangGraph Implementation Plan - Slice 8: Understanding & Yield Phases

This slice focuses on implementing the final two phases of the AEIOU-Y cycle: Understanding and Yield, completing the full PostChain system.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action, Experience, Intention, and Observation phases
- `api/app/postchain/schemas/state.py` - Pydantic models for state management
- `api/app/postchain/utils.py` - Utility functions for PostChain

### Frontend Files

- `Choir/Views/PostchainView.swift` - UI for displaying PostChain phases
- `Choir/ViewModels/PostchainViewModel.swift` - ViewModel for PostChain state management

## 🎯 Goals for This Slice

1. Implement the Understanding phase to decide on continuation strategy
2. Implement the Yield phase to produce the final response
3. Complete the AEIOU-Y cycle with proper phase transitions
4. Add phase decision logic based on accumulated metadata
5. Create comprehensive state summary for future interactions

## 🔄 Frontend-Backend Integration Context

The frontend expects:

- All six AEIOU-Y phases to be properly implemented and sequenced
- Clear visual indication of the current phase
- Consistent state representation across all phases
- Final response formatting in the Yield phase

## 📋 Implementation Tasks

### 1. Understanding Phase Implementation

- [ ] Implement the understanding phase handler in `api/app/postchain/simple_graph.py`:

  ```python
  async def understanding_node(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Handle the understanding phase to decide on continuation strategy."""
      # Set phase to processing
      state.phase_state["understanding"] = "processing"
      yield format_stream_event(state, content="Analyzing conversation context...")

      try:
          # Get user query from last message
          user_query = state.messages[-1].content if state.messages else ""

          # Get outputs from previous phases
          action_output = state.phase_outputs.get("action", "")
          experience_output = state.phase_outputs.get("experience", "")
          intention_output = state.phase_outputs.get("intention", "")
          observation_output = state.phase_outputs.get("observation", "")

          # Get metadata from previous phases
          intent_data = state.metadata.get("intent", {})
          observation_data = state.metadata.get("observation", {})

          # Initialize model selector
          model_config = ModelConfig(
              disabled_providers=config.get("disabled_providers", []) if config else [],
              provider_models=config.get("provider_models", {}) if config else {}
          )
          selector = ModelSelector(model_config, logger=logger)

          # Get appropriate model
          llm = selector.get_model_for_phase("understanding", ModelCapability.BASIC, temperature=0)

          # Create prompt for understanding analysis
          prompt = ChatPromptTemplate.from_messages([
              ("system", "You are an AI assistant tasked with analyzing the conversation context and deciding on the next steps. "
                        "Your goal is to determine if the current response is sufficient or if additional actions are needed. "
                        "Consider user intent, available information, and potential follow-up actions."),
              ("user", f"User query: {user_query}\n\n"
                      f"Action output: {action_output}\n\n"
                      f"Experience output: {experience_output}\n\n"
                      f"Intention output: {intention_output}\n\n"
                      f"Observation output: {observation_output}\n\n"
                      f"Intent data: {json.dumps(intent_data, indent=2)}\n\n"
                      f"Observation data: {json.dumps(observation_data, indent=2)}\n\n"
                      f"Please analyze the conversation context and decide if the current response is sufficient "
                      f"or if additional actions are needed.")
          ])

          # Create chain
          chain = prompt | llm

          # Generate understanding analysis
          response = await chain.ainvoke({})

          # Extract content
          understanding_analysis = response.content if hasattr(response, "content") else str(response)

          # Extract structured understanding data
          understanding_data = await extract_understanding_data(understanding_analysis, user_query, llm)

          # Update state
          state.phase_outputs["understanding"] = understanding_analysis

          # Store understanding data in metadata
          if "understanding" not in state.metadata:
              state.metadata["understanding"] = {}

          state.metadata["understanding"] = understanding_data

          # Determine next steps based on understanding data
          next_steps = determine_next_steps(state, understanding_data)

          # Mark phase as complete
          state.phase_state["understanding"] = "complete"
          yield format_stream_event(state)

          # Return updated state
          return {
              "phase_outputs": {**state.phase_outputs, "understanding": understanding_analysis},
              "phase_state": {**state.phase_state, "understanding": "complete"},
              "current_phase": "yield",
              "metadata": {**state.metadata, "understanding": understanding_data, "next_steps": next_steps}
          }
      except Exception as e:
          # Handle error
          logger.error(f"Error in understanding phase: {e}")

          # Update state
          handle_phase_error(state, "understanding", e)

          yield format_stream_event(state, error=str(e))

          # Return error state
          return {
              "phase_outputs": state.phase_outputs,
              "phase_state": {**state.phase_state, "understanding": "error"},
              "error": str(e),
              "current_phase": "yield"  # Skip to end on error
          }
  ```

- [ ] Implement understanding data extraction utility:

  ````python
  async def extract_understanding_data(
      understanding_analysis: str,
      user_query: str,
      llm: BaseChatModel
  ) -> Dict[str, Any]:
      """Extract structured understanding data from understanding analysis."""
      # Create prompt for structured extraction
      prompt = ChatPromptTemplate.from_messages([
          ("system", "Extract structured understanding data from the understanding analysis. "
                    "Return a JSON object with the following fields:\n"
                    "- response_completeness: A rating of how complete the current response is (incomplete, partial, complete)\n"
                    "- knowledge_gaps: List of any areas where more information is needed\n"
                    "- suggested_actions: List of recommended next actions (if any)\n"
                    "- follow_up_questions: List of potential follow-up questions\n"
                    "- confidence_level: A rating of confidence in the provided information (low, medium, high)"),
          ("user", f"User query: {user_query}\n\n"
                  f"Understanding analysis: {understanding_analysis}\n\n"
                  f"Extract the structured understanding data in JSON format.")
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
              understanding_data = json.loads(json_str)
          except json.JSONDecodeError:
              # Fallback to basic structure if JSON parsing fails
              understanding_data = {
                  "response_completeness": "unknown",
                  "knowledge_gaps": [],
                  "suggested_actions": [],
                  "follow_up_questions": [],
                  "confidence_level": "unknown"
              }

          return understanding_data
      except Exception as e:
          logger.error(f"Error extracting understanding data: {e}")

          # Return basic structure on error
          return {
              "response_completeness": "unknown",
              "knowledge_gaps": [],
              "suggested_actions": [],
              "follow_up_questions": [],
              "confidence_level": "unknown",
              "error": str(e)
          }
  ````

- [ ] Implement next steps determination:

  ```python
  def determine_next_steps(state: PostChainState, understanding_data: Dict[str, Any]) -> Dict[str, Any]:
      """Determine next steps based on understanding data."""
      next_steps = {
          "requires_follow_up": False,
          "suggested_questions": [],
          "additional_actions": []
      }

      # Check if response is incomplete
      if understanding_data.get("response_completeness") in ["incomplete", "partial"]:
          next_steps["requires_follow_up"] = True

      # Add any knowledge gaps as potential follow-up areas
      knowledge_gaps = understanding_data.get("knowledge_gaps", [])
      if knowledge_gaps:
          next_steps["requires_follow_up"] = True
          next_steps["additional_actions"].append("address_knowledge_gaps")

      # Add suggested actions
      suggested_actions = understanding_data.get("suggested_actions", [])
      if suggested_actions:
          next_steps["additional_actions"].extend(suggested_actions)

      # Add follow-up questions
      follow_up_questions = understanding_data.get("follow_up_questions", [])
      if follow_up_questions:
          next_steps["suggested_questions"] = follow_up_questions

      return next_steps
  ```

### 2. Yield Phase Implementation

- [ ] Implement the yield phase handler in `api/app/postchain/simple_graph.py`:

  ```python
  async def yield_node(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Handle the yield phase to produce the final response."""
      # Set phase to processing
      state.phase_state["yield"] = "processing"
      yield format_stream_event(state, content="Generating final response...")

      try:
          # Get user query from last message
          user_query = state.messages[-1].content if state.messages else ""

          # Get outputs from previous phases
          action_output = state.phase_outputs.get("action", "")
          experience_output = state.phase_outputs.get("experience", "")
          intention_output = state.phase_outputs.get("intention", "")
          observation_output = state.phase_outputs.get("observation", "")
          understanding_output = state.phase_outputs.get("understanding", "")

          # Get metadata from previous phases
          intent_data = state.metadata.get("intent", {})
          observation_data = state.metadata.get("observation", {})
          understanding_data = state.metadata.get("understanding", {})
          next_steps = state.metadata.get("next_steps", {})

          # Initialize model selector
          model_config = ModelConfig(
              disabled_providers=config.get("disabled_providers", []) if config else [],
              provider_models=config.get("provider_models", {}) if config else {}
          )
          selector = ModelSelector(model_config, logger=logger)

          # Get appropriate model
          llm = selector.get_model_for_phase("yield", ModelCapability.ADVANCED, temperature=0)

          # Decide if we should include follow-up suggestions
          include_follow_up = next_steps.get("requires_follow_up", False) and next_steps.get("suggested_questions", [])

          # Create prompt for final response
          prompt = ChatPromptTemplate.from_messages([
              ("system", "You are an AI assistant tasked with producing the final response to the user. "
                        "Your goal is to synthesize all the information gathered in previous phases into a clear, "
                        "comprehensive, and helpful response. "
                        "The response should address the user's intent, provide accurate information, and be well-structured. "
                        f"{'If appropriate, suggest follow-up questions at the end of your response.' if include_follow_up else ''}"),
              ("user", f"User query: {user_query}\n\n"
                      f"Action output: {action_output}\n\n"
                      f"Experience output: {experience_output}\n\n"
                      f"Intention output: {intention_output}\n\n"
                      f"Observation output: {observation_output}\n\n"
                      f"Understanding output: {understanding_output}\n\n"
                      f"Intent data: {json.dumps(intent_data, indent=2)}\n\n"
                      f"Observation data: {json.dumps(observation_data, indent=2)}\n\n"
                      f"Understanding data: {json.dumps(understanding_data, indent=2)}\n\n"
                      f"Next steps: {json.dumps(next_steps, indent=2)}\n\n"
                      f"Please produce the final response to the user that synthesizes all relevant information.")
          ])

          # Create chain
          chain = prompt | llm

          # Generate final response
          response = await chain.ainvoke({})

          # Extract content
          final_response = response.content if hasattr(response, "content") else str(response)

          # Add follow-up suggestions if appropriate
          if include_follow_up and next_steps.get("suggested_questions", []):
              suggested_questions = next_steps["suggested_questions"]

              # Add suggested questions if not already included
              if "follow-up" not in final_response.lower() and "suggested question" not in final_response.lower():
                  final_response += "\n\n**Suggested follow-up questions:**\n"
                  for i, question in enumerate(suggested_questions[:3], 1):
                      final_response += f"{i}. {question}\n"

          # Update state
          state.phase_outputs["yield"] = final_response

          # Mark phase as complete
          state.phase_state["yield"] = "complete"
          yield format_stream_event(state)

          # Attribute message to phase
          attribute_message_to_phase(state, final_response, "yield")

          # Update conversation summary if needed
          await update_summary_if_needed(state, model_name=config.get("model_name", "gpt-3.5-turbo") if config else "gpt-3.5-turbo")

          # Return final state
          return {
              "phase_outputs": {**state.phase_outputs, "yield": final_response},
              "phase_state": {**state.phase_state, "yield": "complete"},
              "current_phase": "complete",
              "summary": state.summary
          }
      except Exception as e:
          # Handle error
          logger.error(f"Error in yield phase: {e}")

          # Update state
          handle_phase_error(state, "yield", e)

          yield format_stream_event(state, error=str(e))

          # Create basic response in case of error
          basic_response = "I apologize, but I encountered an issue while generating the response. " + \
                          "Here's what I can offer based on the information I gathered:\n\n" + \
                          state.phase_outputs.get("action", "")

          # Update state with basic response
          state.phase_outputs["yield"] = basic_response

          # Return error state with basic response
          return {
              "phase_outputs": {**state.phase_outputs, "yield": basic_response},
              "phase_state": {**state.phase_state, "yield": "error"},
              "error": str(e),
              "current_phase": "complete"
          }
  ```

### 3. Complete Graph Structure

- [ ] Update the graph structure in `api/app/postchain/simple_graph.py`:

  ```python
  def create_postchain_graph(thread_id: str = None) -> Runnable:
      """Create a complete PostChain graph with all AEIOU-Y phases."""
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
      builder.add_node("understanding", retry_policy.with_fallbacks(understanding_node))
      builder.add_node("yield", retry_policy.with_fallbacks(yield_node))

      # Add edges for sequential flow
      builder.add_edge("action", "experience")
      builder.add_edge("experience", "intention")
      builder.add_edge("intention", "observation")
      builder.add_edge("observation", "understanding")
      builder.add_edge("understanding", "yield")
      builder.add_edge("yield", END)

      # Set entry point
      builder.set_entry_point("action")

      # Configure persistence
      memory = MemorySaver(f"postchain_{thread_id}")

      # Compile with persistence
      return builder.compile(checkpointer=memory)
  ```

### 4. Phase State Tracking for UI

- [ ] Update the format_stream_event function in `api/app/postchain/utils.py`:

  ```python
  def format_stream_event(state: PostChainState, content: str = None, error: str = None):
      """Format state for streaming to clients with phase status."""
      # Create a map of all phases and their states
      phase_states = {
          "action": state.phase_state.get("action", "pending"),
          "experience": state.phase_state.get("experience", "pending"),
          "intention": state.phase_state.get("intention", "pending"),
          "observation": state.phase_state.get("observation", "pending"),
          "understanding": state.phase_state.get("understanding", "pending"),
          "yield": state.phase_state.get("yield", "pending")
      }

      # Get current phase and its state
      current_phase = state.current_phase
      current_phase_state = state.phase_state.get(current_phase, "processing")

      # Get content for current phase
      phase_content = content or state.phase_outputs.get(current_phase, "")

      return {
          "current_phase": current_phase,
          "phase_state": current_phase_state,
          "all_phase_states": phase_states,
          "content": phase_content,
          "thread_id": state.thread_id,
          "error": error or state.error
      }
  ```

### 5. Comprehensive State Summary

- [ ] Implement comprehensive state summary in `api/app/postchain/utils.py`:

  ```python
  async def create_comprehensive_summary(state: PostChainState, llm: BaseChatModel) -> str:
      """Create a comprehensive summary of the conversation and all phases."""
      # Get all phase outputs
      phase_outputs = state.phase_outputs

      # Get all metadata
      metadata = state.metadata

      # Create prompt for summary
      prompt = ChatPromptTemplate.from_messages([
          ("system", "You are an AI assistant tasked with creating a comprehensive summary of a conversation. "
                    "The summary should include key points from the conversation, important insights gained, "
                    "and any unresolved questions or follow-up items."),
          ("user", f"Please create a comprehensive summary of the following conversation:\n\n"
                  f"User query: {state.messages[-1].content if state.messages else ''}\n\n"
                  f"Action phase: {phase_outputs.get('action', '')}\n\n"
                  f"Experience phase: {phase_outputs.get('experience', '')}\n\n"
                  f"Intention phase: {phase_outputs.get('intention', '')}\n\n"
                  f"Observation phase: {phase_outputs.get('observation', '')}\n\n"
                  f"Understanding phase: {phase_outputs.get('understanding', '')}\n\n"
                  f"Yield phase: {phase_outputs.get('yield', '')}\n\n"
                  f"Intent data: {json.dumps(metadata.get('intent', {}), indent=2)}\n\n"
                  f"Next steps: {json.dumps(metadata.get('next_steps', {}), indent=2)}\n\n"
                  f"The summary should be concise but comprehensive, capturing all important information.")
      ])

      # Create chain
      chain = prompt | llm

      try:
          # Generate summary
          response = await chain.ainvoke({})

          # Extract content
          summary = response.content if hasattr(response, "content") else str(response)

          return summary
      except Exception as e:
          logger.error(f"Error creating comprehensive summary: {e}")

          # Return basic summary on error
          return f"Conversation about: {state.messages[-1].content if state.messages else 'Unknown topic'}"
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

1. **Complete AEIOU-Y Cycle Tests**:

   ```bash
   # Test full AEIOU-Y cycle
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Explain the relationship between quantum entanglement and quantum teleportation in detail", "stream": true}'
   ```

2. **Follow-up Question Tests**:

   ```bash
   # Test with complex query to generate follow-up suggestions
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "What are the ethical implications of using AI in healthcare?", "stream": true}'
   ```

3. **Full State Summary Tests**:
   ```bash
   # Test summary generation
   curl -X POST http://localhost:8000/postchain/summary \
     -H "Content-Type: application/json" \
     -d '{"thread_id": "your-test-thread-id"}'
   ```

## 📊 Success Criteria

This slice is complete when:

1. The Understanding phase correctly analyzes the conversation context
2. The Yield phase produces a comprehensive final response
3. The complete AEIOU-Y cycle works with proper phase transitions
4. Follow-up suggestions are included when appropriate
5. The state summary provides useful context for future interactions
6. The frontend displays all six phases correctly

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **AEIOU-Y completion is critical** - Ensure all phases are properly implemented
3. **Error handling is essential** - Each phase must handle errors gracefully
4. **State summary is important** - Create comprehensive summaries for future context
5. **Frontend integration** - Ensure all phases produce output in the format expected by the frontend
