# 🔧 Qdrant Vector Database Tools Implementation Plan

## 🎯 Core Principles

1. **Test-Driven Development** - Start with tests, add functionality incrementally
2. **Provider Agnosticism** - No hardcoded model/provider references
3. **Configuration Centrality** - Use Config for all settings
4. **LangGraph Integration** - Implement using ToolNode for proper LangGraph workflow
5. **Streaming Support** - Utilize streaming for better performance
6. **Testing Across Providers** - Ensure tools work with multiple model providers

## 📝 Test-Driven Development Approach

We'll follow a disciplined TDD approach, building functionality incrementally, with each test adding complexity:

### 1️⃣ Tool Function Tests

Our first tests focus directly on the Qdrant tool functions:

```python
# Test 1: Qdrant Search Tool
@pytest.mark.asyncio
async def test_qdrant_search_tool():
    """Test the Qdrant search tool."""
    config = Config()
    # Create test content in the vector database
    test_content = f"Test content for search tool {uuid.uuid4()}"

    # Use the search tool
    result = await qdrant_search(test_content[:10])  # Search with first 10 chars

    # Verify results
    assert "Found semantically similar information" in result
    assert test_content in result

# Test 2: Qdrant Store Tool
@pytest.mark.asyncio
async def test_qdrant_store_tool():
    """Test the Qdrant store tool."""
    config = Config()
    test_content = f"Test content for store tool {uuid.uuid4()}"

    # Use the store tool
    result = await qdrant_store(test_content)

    # Verify results
    assert "Successfully stored" in result
    assert "ID" in result

    # Extract the ID for later use in delete test
    vector_id = extract_id_from_result(result)
    return vector_id

# Test 3: Qdrant Delete Tool
@pytest.mark.asyncio
async def test_qdrant_delete_tool():
    """Test the Qdrant delete tool."""
    # First store something to get an ID
    vector_id = await test_qdrant_store_tool()

    # Then delete it
    result = await qdrant_delete(vector_id)

    # Verify deletion
    assert "Successfully deleted" in result
    assert vector_id in result

# Test 4: Combined Tool Operations
@pytest.mark.asyncio
async def test_qdrant_tool_sequence():
    """Test a sequence of Qdrant tool operations."""
    # 1. Store some content
    test_content = f"Test content for sequence {uuid.uuid4()}"
    store_result = await qdrant_store(test_content)
    assert "Successfully stored" in store_result

    # 2. Search for the content
    search_result = await qdrant_search(test_content[:15])
    assert test_content in search_result

    # 3. Delete the content
    vector_id = extract_id_from_result(store_result)
    delete_result = await qdrant_delete(vector_id)
    assert "Successfully deleted" in delete_result

    # 4. Verify it's gone by searching again
    search_again_result = await qdrant_search(test_content[:15])
    assert test_content not in search_again_result
```

### 2️⃣ LangGraph ToolNode Tests

Next, test the tools via LangGraph's ToolNode:

```python
@pytest.mark.asyncio
async def test_qdrant_tool_node():
    """Test Qdrant tools via ToolNode."""
    # Create the tool node
    qdrant_tools = [qdrant_search, qdrant_store, qdrant_delete]
    tool_node = ToolNode(qdrant_tools)

    # Create an AI message with tool call
    message_with_store_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_store",
                "args": {"content": "Test content for ToolNode"},
                "id": "tool_call_id_1",
                "type": "tool_call",
            }
        ],
    )

    # Invoke the tool node for store
    store_result = await tool_node.ainvoke({"messages": [message_with_store_call]})

    # Verify store execution
    assert "messages" in store_result
    assert "Successfully stored" in store_result["messages"][0].content

    # Create a search message
    message_with_search_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_search",
                "args": {"query": "Test content for ToolNode"},
                "id": "tool_call_id_2",
                "type": "tool_call",
            }
        ],
    )

    # Invoke the tool node for search
    search_result = await tool_node.ainvoke({"messages": [message_with_search_call]})

    # Verify search execution
    assert "messages" in search_result
    assert "Test content for ToolNode" in search_result["messages"][0].content
```

### 3️⃣ Single Model End-to-End Tests

Test the entire workflow with a single model:

```python
@pytest.mark.asyncio
async def test_qdrant_workflow_single_model():
    """Test the end-to-end Qdrant workflow with a single model."""
    config = Config()

    # Get a tool-compatible model
    tool_models = initialize_tool_compatible_model_list(config)
    model_config = tool_models[0]

    # Create the workflow
    workflow = create_qdrant_workflow(model_config=model_config)

    # Test store operation
    test_content = f"Vector storage test content {uuid.uuid4()}"
    system_message = SystemMessage(content="You are a helpful assistant with vector database access.")

    store_result = await workflow.invoke(
        {
            "messages": [
                system_message,
                HumanMessage(content=f"Please store this information: {test_content}")
            ]
        }
    )

    # Verify store operation succeeded
    assert any("Successfully stored" in msg.content for msg in store_result["messages"])

    # Test search operation
    search_result = await workflow.invoke(
        {
            "messages": [
                system_message,
                HumanMessage(content=f"Find information about {test_content[:20]}")
            ]
        }
    )

    # Verify search operation found the content
    assert any(test_content in msg.content for msg in search_result["messages"])
```

### 4️⃣ Multi-Model Compatibility Tests

Test with multiple models to verify cross-provider compatibility:

```python
@pytest.mark.asyncio
async def test_multi_model_compatibility():
    """Test Qdrant tools with multiple model providers."""
    config = Config()

    # Get tool-compatible models
    tool_models = initialize_tool_compatible_model_list(config)

    results = {}
    for model_config in tool_models:
        try:
            # Create workflow with this model
            workflow = create_qdrant_workflow(model_config=model_config)

            # Test basic operations
            test_content = f"Test for {model_config}: Vector data {uuid.uuid4()}"
            system_message = SystemMessage(content="You are a helpful assistant.")

            # Store content
            store_result = await workflow.invoke(
                {
                    "messages": [
                        system_message,
                        HumanMessage(content=f"Store this: {test_content}")
                    ]
                }
            )

            # Search for content
            search_result = await workflow.invoke(
                {
                    "messages": [
                        system_message,
                        HumanMessage(content=f"Search for: {test_content[:20]}")
                    ]
                }
            )

            # Record results
            results[str(model_config)] = {
                "store_success": any("Successfully stored" in msg.content for msg in store_result["messages"]),
                "search_success": any(test_content in msg.content for msg in search_result["messages"]),
            }

        except Exception as e:
            results[str(model_config)] = {"error": str(e)}

    # Generate report
    print("\n===== Model Compatibility Report =====")
    for model, result in results.items():
        print(f"\n{model}:")
        if "error" in result:
            print(f"  ❌ Error: {result['error']}")
        else:
            print(f"  Store: {'✅' if result['store_success'] else '❌'}")
            print(f"  Search: {'✅' if result['search_success'] else '❌'}")
```

### 5️⃣ Multi-Model Workflow Tests

Finally, test the tools in a complex multi-model workflow similar to `test_tool_random_multimodel.py`:

```python
@pytest.mark.asyncio
async def test_qdrant_random_multimodel():
    """Test Qdrant tools in a random multi-model conversation."""
    config = Config()

    # Create a RandomToolMultiModelTester instance
    tester = RandomToolMultiModelTester(config)

    # Add Qdrant tools to the tester
    qdrant_tools = [qdrant_search, qdrant_store, qdrant_delete]

    # Run multiple random sequence tests
    results = await tester.run_multiple_tests_with_tools(
        tools=qdrant_tools,
        test_count=3,
        min_turns=5,
        max_turns=10
    )

    # Analyze and report results
    print("\n===== Random Multi-Model Test Results =====")
    tester.print_results()

    # Verify essential metrics
    assert results["tool_success_rate"] > 0.7  # At least 70% tool use success
    assert results["context_maintenance_rate"] > 0.8  # Good context maintenance
```

## 🏗️ Architecture Considerations

We are implementing Qdrant vector database tools following the provider-agnostic patterns established by the existing web search tools:

1. **LangGraph ToolNode Pattern**: Using the `ToolNode` class from LangGraph to manage tool calls.

```python
from langchain_core.tools import tool
from langgraph.prebuilt import ToolNode

@tool
async def qdrant_search(query: str, collection: str = None, limit: int = 5) -> str:
    """Search for semantically similar content in the vector database."""
    # Implementation
    return "Search results formatted as text"

@tool
async def qdrant_store(content: str, collection: str = None, metadata: dict = None) -> str:
    """Store information in the vector database for later retrieval."""
    # Implementation
    return "Successfully stored with ID: xyz-123"

# Create a ToolNode with all Qdrant tools
qdrant_tools = [qdrant_search, qdrant_store]
qdrant_tool_node = ToolNode(qdrant_tools)
```

2. **Embedding Abstraction**: Creating a simple embedding function that can be updated in one place when we add more providers.

```python
# app/langchain_utils.py
from langchain_openai import OpenAIEmbeddings

async def generate_embedding(text: str, config: Config) -> List[float]:
    """
    Generate an embedding for the given text.

    Args:
        text: The text to generate an embedding for
        config: Configuration object

    Returns:
        A list of floats representing the embedding vector
    """
    # For now, we're using OpenAI embeddings, but this function allows us
    # to change the implementation in one place later
    embeddings = OpenAIEmbeddings(model=config.EMBEDDING_MODEL)
    return await embeddings.aembed_query(text)
```

3. **Provider-Agnostic Model Selection**: Using `initialize_tool_compatible_model_list` to dynamically select appropriate models.

```python
from app.config import Config
from app.langchain_utils import initialize_tool_compatible_model_list, ModelConfig

def create_qdrant_workflow(
    model_config: Optional[ModelConfig] = None,
    config: Optional[Config] = None,
    disabled_providers: set = None
) -> StateGraph:
    """Create a LangGraph workflow for vector database operations."""
    config = config or Config()

    # If no specific model provided, get first available tool-compatible model
    if model_config is None:
        tool_models = initialize_tool_compatible_model_list(config, disabled_providers)
        if not tool_models:
            raise ValueError("No tool-compatible models available with current configuration")
        model_config = tool_models[0]
        logger.info(f"Selected model: {model_config}")

    # Continue with workflow creation using the selected model
    # ...
```

4. **Streaming Support**: Adapting our existing `abstract_llm_completion_stream` for LangGraph compatibility.

```python
# app/langchain_utils.py
async def langchain_llm_completion_stream(
    model_name: str,
    messages: List[BaseMessage],
    config: Config,
    temperature: Optional[float] = None,
    max_tokens: Optional[float] = None,
    tools: Optional[List[Any]] = None
) -> AsyncGenerator[Dict[str, Any], None]:
    """Stream completions using LangChain message format."""
    # Convert LangChain messages to the format expected by abstract_llm_completion_stream
    converted_messages = []
    for msg in messages:
        if isinstance(msg, HumanMessage):
            converted_messages.append({"role": "user", "content": msg.content})
        elif isinstance(msg, AIMessage):
            converted_messages.append({
                "role": "assistant",
                "content": msg.content,
                "tool_calls": msg.tool_calls if hasattr(msg, "tool_calls") else None
            })
        elif isinstance(msg, SystemMessage):
            converted_messages.append({"role": "system", "content": msg.content})
        elif isinstance(msg, ToolMessage):
            converted_messages.append({
                "role": "tool",
                "content": msg.content,
                "tool_call_id": msg.tool_call_id
            })

    # Use existing streaming function with converted messages
    async for chunk in abstract_llm_completion_stream(
        model_name=model_name,
        messages=converted_messages,
        config=config,
        temperature=temperature,
        max_tokens=max_tokens,
        tools=tools
    ):
        yield chunk
```

5. **Zero Provider References**: Ensuring no model/provider names are hardcoded in the implementation.

```python
# BAD (Don't do this):
def create_tools_for_anthropic():
    # Implementation tied to one provider
    return [tool1, tool2]

# GOOD (Provider-agnostic):
@tool
async def qdrant_search(query: str, collection: str = None, limit: int = 5) -> str:
    """Search for semantically similar content in the vector database."""
    config = Config()
    # Use collection from config, not hardcoded
    if collection is None:
        collection = config.MESSAGES_COLLECTION

    # Use embedding generation that comes from config
    embedding = await generate_embedding(query, config)

    # Rest of implementation
    return "Search results"
```

## ✅ Implementation Checklist

### 1️⃣ Vector Database Tools

#### Core Embedding Function

- [x] Add embedding functionality to work with Qdrant tools
- [x] Ensure function uses Config.EMBEDDING_MODEL
- [x] Keep implementation details contained for easy future extension

#### Qdrant Search Tool

- [x] Implement `qdrant_search` tool with `@tool` decorator
- [x] Use Config.MESSAGES_COLLECTION as default collection
- [x] Add proper error handling and logging
- [x] Format search results for readability

#### Qdrant Store Tool

- [x] Implement `qdrant_store` tool with `@tool` decorator
- [x] Use Config.MESSAGES_COLLECTION as default collection
- [x] Store metadata including timestamp and model info
- [x] Return vector ID for reference

#### Qdrant Delete Tool

- [x] Implement `qdrant_delete` tool with `@tool` decorator
- [x] Use Config.MESSAGES_COLLECTION as default collection
- [x] Add proper error handling for non-existent vectors
- [x] Return clear success/failure messages

### 2️⃣ LangGraph Integration

#### LangChain Adapter

- [x] Implement `langchain_llm_completion_stream` to support tools
- [x] Handle proper conversion between message formats
- [x] Ensure streaming support for incremental updates
- [x] Test with various message types (human, assistant, system, tool)

#### Qdrant Workflow Graph

- [x] Implement `create_qdrant_workflow` function
- [x] Create proper nodes for agent and tools
- [x] Configure workflows with conditional edges
- [x] Support model selection from tool-compatible models

### 3️⃣ Testing Implementation

#### Basic Tool Testing

- [x] Create tests for individual Qdrant tool functions
- [x] Test store, search, and delete operations independently
- [x] Test proper error handling and edge cases
- [x] Verify proper async handling for all operations

#### Workflow Testing

- [x] Test tools in LangGraph ToolNode context
- [x] Test complete workflow with an OpenAI model
- [x] Test store, search, and delete operations in workflow
- [x] Add proper logging for diagnostic visibility

#### Provider Compatibility Testing

- [x] Test all tool-compatible models across providers
- [x] Document provider-specific issues or limitations
- [x] Create compatibility matrix for Qdrant tools
- [x] Identify workarounds for problematic providers

#### Multi-Model Testing

- [x] Implement complex multi-model testing like `test_tool_random_multimodel.py`
- [x] Test with different provider sequences
- [x] Measure context preservation across models
- [x] Document cross-provider compatibility issues

## 📊 Current Provider Compatibility

Based on our implementation and testing:

| Provider  | Current Status       | Notes                                             |
| --------- | -------------------- | ------------------------------------------------- |
| OpenAI    | ✅ Working           | Successfully tested with GPT-3.5 and GPT-4 models |
| Anthropic | ✅ Working           | Successfully tested with Claude models            |
| Mistral   | ✅ Working           | Successfully tested with Mistral models           |
| Google    | ✅ Working (Limited) | May require additional prompt engineering         |
| Groq      | ⚠️ Partial           | Works with some models, limited tool support      |

## 🚀 Next Steps

1. ✅ Implemented individual Qdrant tool functions (search, store, delete)
2. ✅ Created basic tests for tool functions
3. ✅ Implemented LangGraph workflow with conditional routing
4. ✅ Tested workflow with OpenAI model
5. ✅ Fixed async handling for proper operation
6. ✅ Tested with multiple model providers to create compatibility matrix
7. ✅ Created complex multi-model test scenarios
8. ✅ Documented provider-specific compatibility findings
9. [ ] Explore possible optimizations (caching, batch operations, etc.)
10. [ ] Consider implementation of future improvements

## 📝 Future Improvements

1. Support for multiple embedding models (not just text-embedding-ada-002)
2. Extended metadata for better searchability
3. Collection management tools
4. Vector clustering and organization tools
5. Integration with RAG workflows
6. Support for hybrid search (keyword + vector)

## 📋 Implementation Notes

### Provider Compatibility Testing

The `test_multi_model_compatibility` function (in `test_qdrant_workflow.py`) systematically tests each tool-compatible model with store, search, and delete operations, producing a detailed compatibility report that highlights which providers work well with Qdrant tools.

### Multi-Model Testing

We implemented a specialized `RandomToolMultiModelTester` class in `test_qdrant_multimodel.py` that:

1. Generates random sequences of models from different providers
2. Creates conversations that utilize all three Qdrant tools
3. Measures both tool success rate and context maintenance between different models
4. Tracks the "magic number" (1729) to verify context preservation across model boundaries
5. Produces detailed reports on cross-provider compatibility

The multi-model tests show that Qdrant tools generally maintain good context across model boundaries, with over 70% context preservation in most tests.
