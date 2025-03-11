# PostChain LangGraph Implementation Plan - Slice 6: Tool Integration for Experience Phase

This slice focuses on implementing tool integration for the Experience phase of the PostChain system, enhancing responses with search results and external knowledge.

## 📚 Key Reference Files

### Backend Files

- `api/app/postchain/simple_graph.py` - Current implementation with Action and Experience phases
- `api/app/tools/qdrant.py` - Qdrant vectorstore connection
- `api/app/tools/brave_search.py` - Brave search tool
- `api/app/tools/tavily_search.py` - Tavily search tool
- `api/app/tools/calculator.py` - Calculator tool

### Frontend Files

- `Choir/Views/PostchainView.swift` - UI for displaying PostChain phases
- `Choir/Views/MessageRow.swift` - UI for individual message rows

## 🎯 Goals for This Slice

1. Integrate search tools (Brave, Tavily) into the Experience phase
2. Connect with Qdrant vectorstore for retrieving prior knowledge
3. Implement calculator and other specialized tools
4. Create search result formatting for frontend display
5. Add result filtering and prioritization

## 🔄 Frontend-Backend Integration Context

The frontend needs:

- Properly formatted search results for display in the Experience phase card
- Clear attribution of information sources
- Visual indicators for search operations
- Deep linking to web results

## 📋 Implementation Tasks

### 1. Search Tool Integration

- [ ] Create a search tool manager in `api/app/postchain/tools.py`:

  ```python
  from typing import Dict, List, Any, Optional
  from langchain_core.tools import BaseTool
  from api.app.tools.brave_search import BraveSearchTool
  from api.app.tools.tavily_search import TavilySearchTool

  class SearchToolManager:
      """Manager for search tools with fallback capabilities."""

      def __init__(self, config: Dict[str, Any] = None):
          """Initialize search tool manager."""
          self.config = config or {}
          self.tools = {}
          self.fallback_order = ["tavily", "brave"]  # Default fallback order

          # Initialize tools
          self._initialize_tools()

      def _initialize_tools(self):
          """Initialize available search tools."""
          # Try to initialize Tavily
          try:
              self.tools["tavily"] = TavilySearchTool()
          except Exception as e:
              logger.warning(f"Failed to initialize Tavily search: {e}")

          # Try to initialize Brave
          try:
              self.tools["brave"] = BraveSearchTool()
          except Exception as e:
              logger.warning(f"Failed to initialize Brave search: {e}")

      async def search(self, query: str, num_results: int = 5) -> List[Dict[str, Any]]:
          """Perform search with fallback capabilities."""
          results = []
          errors = {}

          # Try each tool in fallback order
          for tool_name in self.fallback_order:
              if tool_name not in self.tools:
                  continue

              tool = self.tools[tool_name]

              try:
                  # Perform search
                  tool_results = await tool.asearch(query, num_results=num_results)

                  # Add source attribution
                  for result in tool_results:
                      result["source"] = tool_name

                  results = tool_results
                  break  # Stop if we got results
              except Exception as e:
                  errors[tool_name] = str(e)
                  continue

          # If all tools failed, log errors
          if not results and errors:
              logger.error(f"All search tools failed. Errors: {errors}")

          return results
  ```

- [ ] Implement Qdrant vectorstore connection in `api/app/postchain/tools.py`:

  ```python
  from api.app.tools.qdrant import QdrantRetriever

  class KnowledgeRetriever:
      """Retriever for prior knowledge from vectorstore."""

      def __init__(self, config: Dict[str, Any] = None):
          """Initialize knowledge retriever."""
          self.config = config or {}
          self.retriever = None

          # Initialize retriever
          self._initialize_retriever()

      def _initialize_retriever(self):
          """Initialize vectorstore retriever."""
          try:
              self.retriever = QdrantRetriever()
              logger.info("Initialized Qdrant retriever")
          except Exception as e:
              logger.warning(f"Failed to initialize Qdrant retriever: {e}")

      async def retrieve(self, query: str, num_results: int = 3) -> List[Dict[str, Any]]:
          """Retrieve relevant documents from vectorstore."""
          if not self.retriever:
              logger.warning("Qdrant retriever not available")
              return []

          try:
              # Retrieve documents
              docs = await self.retriever.aretrieve(query, num_results=num_results)

              # Format results
              results = []
              for doc in docs:
                  results.append({
                      "title": doc.metadata.get("title", "No title"),
                      "content": doc.page_content,
                      "source": "knowledge_base",
                      "metadata": doc.metadata
                  })

              return results
          except Exception as e:
              logger.error(f"Error retrieving from Qdrant: {e}")
              return []
  ```

- [ ] Add calculator tool integration:

  ```python
  from api.app.tools.calculator import CalculatorTool

  class ToolRegistry:
      """Registry for specialized tools."""

      def __init__(self):
          """Initialize tool registry."""
          self.tools = {}

          # Initialize tools
          self._initialize_tools()

      def _initialize_tools(self):
          """Initialize available tools."""
          # Calculator tool
          try:
              self.tools["calculator"] = CalculatorTool()
          except Exception as e:
              logger.warning(f"Failed to initialize calculator tool: {e}")

      def get_tool(self, tool_name: str) -> Optional[BaseTool]:
          """Get a tool by name."""
          return self.tools.get(tool_name)

      def get_all_tools(self) -> List[BaseTool]:
          """Get all available tools."""
          return list(self.tools.values())
  ```

### 2. Experience Phase with Search Integration

- [ ] Update the experience phase handler in `api/app/postchain/simple_graph.py`:

  ```python
  async def experience_with_search(state: PostChainState, config: Dict[str, Any] = None) -> Dict[str, Any]:
      """Experience phase with search integration."""
      # Set phase to processing
      state.phase_state["experience"] = "processing"
      yield format_stream_event(state, content="Enhancing with relevant information...")

      try:
          # Get user query from last message
          user_query = state.messages[-1].content if state.messages else ""

          # Get action output
          action_output = state.phase_outputs.get("action", "")

          # Initialize search manager
          search_manager = SearchToolManager(config)

          # Initialize knowledge retriever
          knowledge_retriever = KnowledgeRetriever(config)

          # Perform search
          yield format_stream_event(state, content="Searching for relevant information...")
          search_results = await search_manager.search(user_query, num_results=5)

          # Retrieve from knowledge base
          yield format_stream_event(state, content="Retrieving from knowledge base...")
          knowledge_results = await knowledge_retriever.retrieve(user_query, num_results=3)

          # Combine results
          all_results = search_results + knowledge_results

          # Filter and prioritize results
          filtered_results = filter_and_prioritize_results(all_results, user_query, action_output)

          # Format results for display
          formatted_results = format_search_results(filtered_results)

          # Update state with preliminary results
          state.search_results = filtered_results
          state.phase_outputs["experience"] = formatted_results
          yield format_stream_event(state)

          # Optional: Interrupt for human review
          if config and config.get("enable_human_review", False):
              reviewed_results = interrupt({
                  "type": "review_search",
                  "original_results": filtered_results,
                  "message": "Please review these search results before proceeding.",
                  "phase": "experience"
              })

              # Use reviewed or original results
              final_results = reviewed_results or filtered_results
              state.search_results = final_results
          else:
              final_results = filtered_results

          # Process the results into a coherent response
          yield format_stream_event(state, content="Synthesizing information...")
          experience_content = await enhance_with_search_results(
              action_output,
              final_results,
              config
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
              "current_phase": "intention" if "intention" in state.phase_state else "yield"
          }
      except Exception as e:
          # Handle error
          logger.error(f"Error in experience phase: {e}")

          # Update state
          handle_phase_error(state, "experience", e)

          yield format_stream_event(state, error=str(e))

          # Return error state
          return {
              "phase_outputs": state.phase_outputs,
              "phase_state": {**state.phase_state, "experience": "error"},
              "error": str(e),
              "current_phase": "yield"  # Skip to end on error
          }
  ```

### 3. Result Filtering and Prioritization

- [ ] Implement result filtering and prioritization in `api/app/postchain/utils.py`:

  ```python
  def filter_and_prioritize_results(
      results: List[Dict[str, Any]],
      query: str,
      context: str = None,
      max_results: int = 5
  ) -> List[Dict[str, Any]]:
      """Filter and prioritize search results."""
      if not results:
          return []

      # Remove duplicates based on URL
      unique_results = {}
      for result in results:
          url = result.get("url", result.get("metadata", {}).get("url", f"id:{id(result)}"))
          if url not in unique_results:
              unique_results[url] = result

      # Convert back to list
      filtered_results = list(unique_results.values())

      # Score results based on relevance to query
      scored_results = []
      for result in filtered_results:
          # Basic scoring based on keyword matching
          title = result.get("title", "")
          content = result.get("content", result.get("snippet", ""))

          # Count query terms in title and content
          query_terms = set(query.lower().split())
          title_matches = sum(1 for term in query_terms if term in title.lower())
          content_matches = sum(1 for term in query_terms if term in content.lower())

          # Calculate score
          score = (title_matches * 2) + content_matches

          # Boost knowledge base results
          if result.get("source") == "knowledge_base":
              score += 3

          scored_results.append((score, result))

      # Sort by score (descending)
      scored_results.sort(reverse=True, key=lambda x: x[0])

      # Take top results
      top_results = [result for _, result in scored_results[:max_results]]

      return top_results
  ```

### 4. Search Result Formatting

- [ ] Implement search result formatting in `api/app/postchain/utils.py`:

  ```python
  def format_search_results(results: List[Dict[str, Any]]) -> str:
      """Format search results for display in the UI."""
      if not results:
          return "No relevant information found."

      # Format as markdown
      formatted = "## Relevant Information\n\n"

      for i, result in enumerate(results, 1):
          title = result.get("title", "No title")
          content = result.get("content", result.get("snippet", "No content available"))
          url = result.get("url", result.get("metadata", {}).get("url", "#"))
          source = result.get("source", "unknown")

          # Format based on source
          if source == "knowledge_base":
              formatted += f"### {i}. {title} [Knowledge Base]\n"
          else:
              formatted += f"### {i}. {title}\n"

          # Add content
          formatted += f"{content}\n"

          # Add source link if available
          if url and url != "#":
              formatted += f"Source: [{url}]({url})\n\n"
          else:
              formatted += f"Source: {source}\n\n"

      return formatted
  ```

### 5. Experience Enhancement with Search Results

- [ ] Implement the enhancement function in `api/app/postchain/utils.py`:

  ```python
  async def enhance_with_search_results(
      action_output: str,
      search_results: List[Dict[str, Any]],
      config: Dict[str, Any] = None
  ) -> str:
      """Enhance action output with search results."""
      if not search_results:
          return action_output + "\n\nNo additional information found."

      # Initialize model selector
      model_config = ModelConfig(
          disabled_providers=config.get("disabled_providers", []) if config else [],
          provider_models=config.get("provider_models", {}) if config else {}
      )
      selector = ModelSelector(model_config, logger=logger)

      # Get appropriate model
      try:
          llm = selector.get_model_for_phase("experience", ModelCapability.BASIC, temperature=0)
      except ValueError:
          logger.warning("Failed to get model for experience enhancement. Using action output only.")
          return action_output + "\n\n" + format_search_results(search_results)

      # Prepare search context
      search_context = ""
      for i, result in enumerate(search_results, 1):
          title = result.get("title", "No title")
          content = result.get("content", result.get("snippet", "No content available"))
          source = result.get("source", "unknown")

          search_context += f"Source {i} ({source}): {title}\n{content}\n\n"

      # Create prompt
      prompt = ChatPromptTemplate.from_messages([
          ("system", "You are an AI assistant tasked with enhancing an initial response with additional information from search results. "
                    "Integrate the search information naturally into the response, citing sources appropriately. "
                    "Do not contradict the initial response unless the search results clearly indicate it's incorrect. "
                    "Format your response in markdown."),
          ("user", f"Initial response:\n{action_output}\n\nSearch results:\n{search_context}\n\n"
                  f"Please enhance the initial response with the search results, citing sources appropriately.")
      ])

      # Create chain
      chain = prompt | llm

      try:
          # Generate enhanced response
          response = await chain.ainvoke({})

          # Extract content
          enhanced_content = response.content if hasattr(response, "content") else str(response)

          return enhanced_content
      except Exception as e:
          logger.error(f"Error enhancing with search results: {e}")

          # Fall back to simple concatenation
          return action_output + "\n\n" + format_search_results(search_results)
  ```

### 6. API Integration for Frontend

- [ ] Update the API router in `api/app/routers/postchain.py` to include search results:

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
                          # Handle interrupt as before...
                          pass
                      else:
                          # Normal chunk
                          if isinstance(chunk, dict) and chunk.get("current_phase"):
                              # Add search results to experience phase events if available
                              if chunk.get("current_phase") == "experience" and hasattr(state, "search_results") and state.search_results:
                                  chunk["search_results"] = state.search_results

                              # Stream the event
                              yield f"data: {json.dumps(chunk)}\n\n"
                          else:
                              # Convert to proper format if needed
                              formatted = format_stream_event(chunk)

                              # Add search results if available
                              if formatted.get("current_phase") == "experience" and hasattr(state, "search_results") and state.search_results:
                                  formatted["search_results"] = state.search_results

                              yield f"data: {json.dumps(formatted)}\n\n"

              except Exception as e:
                  # Handle errors as before...
                  pass

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
langchain-community>=0.0.10  # For Qdrant
tavily-python>=0.1.9
qdrant-client>=1.1.1
```

## 🔄 Testing

1. **Search Integration Tests**:

   ```bash
   # Test search integration
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "What are the latest developments in quantum computing?", "stream": true}'
   ```

2. **Knowledge Base Tests**:

   ```bash
   # Test knowledge base integration
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "Tell me about the FQAHO model", "stream": true}'
   ```

3. **Calculator Tool Tests**:
   ```bash
   # Test calculator tool
   curl -X POST http://localhost:8000/postchain/simple \
     -H "Content-Type: application/json" \
     -d '{"user_query": "What is 1234 * 5678?", "stream": true}'
   ```

## 📊 Success Criteria

This slice is complete when:

1. The Experience phase successfully integrates search results
2. Knowledge base retrieval works correctly
3. Search results are properly formatted for frontend display
4. Results are filtered and prioritized effectively
5. The calculator tool works for mathematical queries
6. The frontend displays search results in the Experience phase card

## ⚠️ Important Notes

1. **Always use the existing virtual environment** - Do not install new packages without approval
2. **API keys may be required** - Ensure necessary API keys are configured for search tools
3. **Handle search failures gracefully** - Always provide a fallback when search tools fail
4. **Respect rate limits** - Implement appropriate throttling for external APIs
5. **Format results consistently** - Ensure search results are formatted consistently for the frontend
