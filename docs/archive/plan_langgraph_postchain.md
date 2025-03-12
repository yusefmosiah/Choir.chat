# LangGraph PostChain Implementation Plan

## Current Implementation Overview

The current Chorus Cycle implementation is a sequence of calls to a single LLM with RAG to a single vector database. The cycle follows the AEIOU-Y pattern:

1. **Action**: Initial response with "beginner's mind"
2. **Experience**: Enrichment with prior knowledge via RAG
3. **Intention**: Analysis of planned actions and consequences
4. **Observation**: Reflection on analysis and intentions
5. **Understanding**: Decision to loop back or proceed to yield
6. **Yield**: Final synthesized response

Each step uses the same model (currently Claude 3.5 Haiku) with different system prompts, and the cycle can loop back from Understanding to Action if needed.

## Migration Goals

1. Implement the Chorus Cycle using LangGraph's StateGraph
2. Create a multi-model workflow where different models handle different steps
3. Add agentic capabilities with integrated tools (Qdrant vector database and web search)
4. Improve observability and debugging
5. Enable dynamic chain modification
6. Provide a unified streaming API endpoint for the entire cycle

## Revised Chorus Cycle Flow

The new Chorus Cycle will be enhanced with integrated tools:

1. **Action**: Initial LLM response to user input (vanilla LLM call)
2. **Experience (Vector)**: Retrieve relevant information from vector database
3. **Experience (Web)**: Retrieve recent information from web search
4. **Intention**: Reflective analysis on prompt, action, and experiences
5. **Observation**: Optional storage of important insights to vector database
6. **Understanding**: Decision to continue or loop back to action
7. **Yield**: Final synthesized response

Each step can be handled by a different model provider, with proper context preservation between transitions.

## Implementation Checklist

### Phase 0: Environment Setup ✅

- [x] Add LangGraph and related dependencies to requirements.txt
  ```
  langchain>=0.1.0
  langchain-core>=0.1.0
  langgraph>=0.0.15
  langserve>=0.0.30
  langchain-openai>=0.0.5
  langchain-anthropic>=0.1.0
  langchain-google-genai>=0.0.5
  langchain-mistralai>=0.0.1
  langchain-fireworks>=0.1.0
  langchain-cohere>=0.0.1
  ```
- [x] Configure environment with necessary API keys for all providers
- [x] Create simple test script to verify API connectivity with each provider
- [x] Document API rate limits and token quotas for each provider

### Phase 1: Individual Model Testing ✅

- [x] Test each model in simple single-turn conversations
- [x] Test each model in multi-turn conversations
  - [x] Verify context window handling
  - [x] Test conversation memory
- [x] Test structured output capabilities of each model
  - [x] JSON schema validation
  - [x] Error handling for malformed outputs
  - [x] Consistency across multiple calls
- [x] Create compatibility matrix documenting strengths/weaknesses of each model

### Phase 2: Basic LangGraph Integration ✅

- [x] Set up project structure for PostChain
- [x] Implement state schema with Pydantic/TypedDict
- [x] Create simple single-node graph with one model
- [x] Test state transitions and data flow
- [x] Expand to basic linear chain with all AEIOU-Y steps
- [x] Implement basic error handling and recovery

### Phase 3: Multi-Model Integration ✅

- [x] Define model configuration for each step
- [x] Create model selection logic (including random model selection)
- [x] Implement node handlers for each step
- [x] Test cross-model context preservation
- [x] Evaluate performance and token usage
- [x] Optimize prompt templates for each model

### Phase 4: Tool Integration 🚧

- [x] Implement Qdrant vector database tools (search, store, delete)
- [x] Implement web search tools
- [x] Test tool compatibility with each model provider
- [x] Create provider compatibility matrix for tool usage
- [x] Implement tool usage tracking in state management
- [x] Test error handling for tool failures
- [x] Measure tool effectiveness across models
- [ ] Create specialized tool nodes for each phase:
  - [ ] Experience (Vector): Vector database querying
  - [ ] Experience (Web): Web search operations
  - [ ] Observation: Vector database storage

### Phase 5: Advanced Flow Control 🚧

- [x] Implement conditional edges for looping
- [x] Create dynamic routing based on probability-based decisions
- [x] Add web search node integration
- [x] Test complex flows with looping
- [x] Implement cycle detection and recursion limits
- [ ] Create visualization of graph execution
- [ ] Implement branching logic for tool selection

### Phase 6: API Integration 🚧

- [x] Create API endpoints
- [x] Implement streaming support
- [ ] Create unified streaming API endpoint for the entire cycle
- [ ] Add authentication and rate limiting
- [ ] Create client library
- [x] Test API performance
- [ ] Document API usage

### Phase 7: Observability and Testing 🚧

- [x] Add tracing and logging throughout the system
- [x] Create comprehensive test suite for behavior verification
- [x] Implement performance monitoring
- [x] Create debugging tools (detailed logging)
- [ ] Document troubleshooting procedures
- [x] Conduct end-to-end testing with various scenarios
- [ ] Test tool usage in real-world scenarios

## Tool Integration Details

### Qdrant Vector Database Tools ✅

The Qdrant vector database tools have been successfully implemented and tested:

1. **Search Tool (`qdrant_search`)**:

   - Retrieves semantically similar information from the vector database
   - Accepts query text and returns formatted results with relevance scores
   - Compatible with all major providers (OpenAI, Anthropic, Mistral)
   - Supports search limit configuration and collection specification

2. **Store Tool (`qdrant_store`)**:

   - Stores new information in the vector database
   - Stores text content with automatically generated embeddings
   - Supports metadata storage for additional context
   - Returns vector IDs for future reference

3. **Delete Tool (`qdrant_delete`)**:
   - Removes vectors from the database by ID
   - Provides confirmation of successful deletion
   - Includes error handling for non-existent vectors


### Web Search Tools ✅

The web search tools enable retrieving up-to-date information:

1. **Web Search Tool**:
   - Performs searches for real-time information
   - Returns relevant snippets and URLs
   - Formats results for easy consumption by LLMs
   - Handles attribution and source tracking

## Implementation Plan for Next Phase

### 1. State Schema Update

The core state schema for our tool-enhanced Chorus Cycle:

```python
class ChorusToolState(TypedDict):
    messages: List[Dict[str, Any]]
    current_phase: str
    loop_count: int
    vector_search_results: Optional[List[Dict[str, Any]]]
    web_search_results: Optional[List[Dict[str, Any]]]
    stored_vector_ids: List[str]
    loop_probability: float
```

### 2. Phase Handlers with Tool Integration

Example of an Experience (Vector) phase handler:

```python
def experience_vector_handler(config: Config):
    """Handler for the vector search experience phase."""
    async def handler(state: ChorusToolState) -> ChorusToolState:
        messages = state["messages"]

        # Get the user prompt and action response
        user_prompt = next((m["content"] for m in messages if m["role"] == "user"), "")
        action_response = next((m["content"] for m in messages if m["role"] == "assistant"
                              and m.get("phase") == "action"), "")

        # Set up the system message for this phase
        system_message = {
            "role": "system",
            "content": (
                "You are the Experience phase of the Chorus Cycle. "
                "Your task is to search the vector database for relevant information "
                "related to the user's query and previous interactions. "
                "You have access to the qdrant_search tool to find semantic matches."
            )
        }

        # Create a message for the model to use the vector search tool
        experience_prompt = {
            "role": "user",
            "content": (
                f"Please search for information relevant to this query: '{user_prompt}'\n\n"
                f"The initial response was: '{action_response}'\n\n"
                "Use the qdrant_search tool to find semantically similar content."
            )
        }

        # Use LangGraph's ToolNode pattern to handle the tool interaction
        model = get_tool_compatible_model(config)
        vector_search_result = await run_tool_interaction(
            model=model,
            tools=[qdrant_search],
            messages=[system_message, experience_prompt]
        )

        # Extract and store the search results
        vector_search_results = extract_search_results(vector_search_result)

        # Update the state
        new_messages = messages + [{
            "role": "assistant",
            "content": vector_search_result["messages"][-1]["content"],
            "phase": "experience_vector"
        }]

        return {
            **state,
            "messages": new_messages,
            "vector_search_results": vector_search_results,
            "current_phase": "experience_vector"
        }

    return handler
```

### 3. Unified API Endpoint

The new unified API endpoint will:

1. Accept a user query
2. Process it through the entire Chorus Cycle with tools
3. Stream the results of each phase as they complete
4. Return the final yield result

```python
@router.post("/chorus", response_model=StreamingResponse)
async def process_chorus_cycle(request: ChorusRequest):
    """Process a complete Chorus Cycle with integrated tools and streaming."""
    config = Config()

    # Initialize the Chorus graph with tools
    graph = create_chorus_tool_graph(config)

    # Create initial state
    initial_state = {
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT_WITH_TIMESTAMP},
            {"role": "user", "content": request.content}
        ],
        "current_phase": "start",
        "loop_count": 0,
        "vector_search_results": None,
        "web_search_results": None,
        "stored_vector_ids": [],
        "loop_probability": 0.0
    }

    # Create streaming response
    return StreamingResponse(
        graph.astream(initial_state),
        media_type="text/event-stream"
    )
```

## Progress Summary

We have made significant progress on the LangGraph PostChain implementation:

1. **Core Graph Implementation**:

   - Successfully implemented the complete AEIOU-Y state graph with proper node connections
   - Implemented a probability-based looping mechanism from understanding to action/yield
   - Added comprehensive state management ensuring state consistency across phases

2. **Error Handling**:

   - Implemented robust error handling in streaming and callback scenarios
   - Ensured graceful recovery from errors with appropriate phase setting
   - Added recursion limit safety to prevent infinite loops

3. **Testing Framework**:

   - Created a comprehensive testing framework that captures interactions
   - Implemented analysis tools to verify phase distribution and transitions
   - Added tools for visualizing and tracking chain behavior

4. **Tool Integration**:

   - Successfully implemented and tested Qdrant vector database tools
   - Verified cross-provider compatibility for tool usage
   - Implemented RandomToolMultiModelTester for comprehensive testing
   - Documented tool compatibility across different model providers

5. **Next Steps**:
   - Integrate tools directly into the Chorus Cycle workflow
   - Split the Experience phase into Vector and Web search components
   - Implement the Observation phase with vector storage capabilities
   - Create a unified streaming API endpoint for the entire cycle

## Conclusion

The implementation of tool-enhanced Chorus Cycle represents a significant advancement over the current design. By integrating Qdrant vector database tools and web search capabilities, we can enhance the cycle's ability to retrieve and store information, improving the quality and relevance of responses.

The revised implementation maintains the core AEIOU-Y structure while adding powerful new capabilities:

1. **Richer Context**: Vector search and web search provide more comprehensive information
2. **Memory Enhancement**: Vector storage allows observations to be persisted for future reference
3. **Multi-Model Flexibility**: Different models can handle different phases of the cycle
4. **Tool Agentic Capabilities**: Models can use tools within the appropriate phases

This plan outlines a clear path forward to implementing a unified, streaming API endpoint that leverages the full power of the PostChain architecture with LangGraph and integrated tools.
