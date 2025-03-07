# 🔧 Tool Integration Implementation Plan

## 🎯 Core Principles

1. **Test-Driven Development** - Write tests before implementation
2. **Incremental Integration** - Start with simple tools, then advance to complex ones
3. **Dual Testing Approach** - Test tools both standalone and in multimodel chat threads
4. **Minimal Dependencies** - Keep implementations as simple as possible
5. **Clear Interfaces** - Define consistent tool interfaces

## 🏗️ Architecture Considerations

We are currently using a temporary architecture while we iterate on tool implementations:

1. **Current Implementation**: Uses a `ConversationWithTools` wrapper class (`app/tools/conversation.py`) that:

   - Manages conversation state
   - Extracts tool calls using regex
   - Executes tools and manages message history
   - Handles model-specific formatting needs (especially for Mistral models)

2. **Known Limitations**:

   - Duplicates logic that could be in `abstract_llm_completion_stream`
   - Uses regex-based extraction rather than structured tool calling
   - Not integrated with the core Post Chain architecture
   - Different model providers have inconsistent tool calling formats

3. **Future Direction**:
   - Integrate tool support directly into `abstract_llm_completion_stream`
   - Use LangGraph for proper state management in the Post Chain
   - Standardize the tool calling interface across providers

For now, we'll continue with the current approach to make rapid progress, while documenting areas for future improvement.

## ✅ Implementation Checklist

### 1️⃣ Calculator Tool

#### Standalone Calculator Implementation

- [x] Create calculator tool interface (`app/tools/base.py` and `app/tools/calculator.py`)
- [x] Implement basic arithmetic operations
- [x] Add support for complex expressions (using AST-based evaluation)
- [x] Write standalone unit tests (`tests/tools/test_calculator.py`)
- [x] Document calculator API

#### Calculator Integration Tests

- [x] Create test for calculator in multimodel chat thread
- [x] Verify context maintenance across model transitions
- [x] Test error handling for invalid expressions
- [x] Document integration patterns
- [x] Use complex calculations to ensure tool is actually used (`tests/tools/test_multimodel_with_tools.py`)

#### Calculator Implementation Notes

- The calculator uses Python's AST module for secure evaluation
- Implementation verifies operation types for safety
- Tool pattern allows both direct usage and integration with conversation
- Supports both Mistral and non-Mistral models (different message formatting)
- Testing requires complex calculations (10+ digit numbers) to ensure models use the tool

### 2️⃣ Web Search Tool

#### Web Search Setup

- [x] Select web search API providers (DuckDuckGo, Tavily, Brave Search)
- [x] Configure API keys and environment variables
- [ ] Document API limitations and rate limits
- [ ] Create fallback logic between search providers
- [ ] Implement caching to reduce API calls

#### Primary Search Implementation (Tavily)

- [ ] Create Tavily search tool interface (`app/tools/tavily_search.py`)
- [ ] Implement structured result formatting
- [ ] Add image inclusion capabilities
- [ ] Write standalone unit tests (`tests/tools/test_tavily_search.py`)
- [ ] Document Tavily search API usage

#### Backup Search Implementations

- [ ] Implement DuckDuckGo search (for development/testing)
- [ ] Implement Brave Search alternative
- [ ] Create provider switching logic
- [ ] Test provider fallback scenarios
- [ ] Document multi-provider strategy

#### Web Search Integration Tests

- [ ] Create test for web search in multimodel chat thread
- [ ] Test different query types and result handling
- [ ] Verify context maintenance with search results
- [ ] Test search provider fallback
- [ ] Document integration patterns

### 3️⃣ Qdrant Integration

#### Qdrant Setup

- [ ] Verify Qdrant connection settings
- [ ] Configure collections and vector dimensions
- [ ] Test basic connectivity

#### Standalone Qdrant Implementation

- [ ] Create Qdrant search tool interface
- [ ] Implement vector search functionality
- [ ] Add result processing and formatting
- [ ] Write standalone unit tests
- [ ] Document Qdrant search API

#### Qdrant Integration Tests

- [ ] Create test for Qdrant search in multimodel chat thread
- [ ] Test different query types and vector search patterns
- [ ] Verify context maintenance with search results
- [ ] Document integration patterns

## 📝 Testing Frameworks

### Calculator Test Framework

```python
def test_calculator_basic():
    """Test basic calculator operations"""
    calculator = CalculatorTool()

    # Test addition
    assert calculator.calculate("2 + 2") == 4

    # Test subtraction
    assert calculator.calculate("10 - 5") == 5

    # Test multiplication
    assert calculator.calculate("3 * 4") == 12

    # Test division
    assert calculator.calculate("20 / 5") == 4
```

### Calculator Integration Test

```python
@pytest.mark.asyncio
async def test_calculator_in_multimodel_thread():
    """Test calculator tool in a multimodel conversation thread"""
    config = Config()

    # Initialize model list without OpenAI
    models = initialize_model_list(config, disabled_providers={"openai"})

    # Create a conversation with calculator tool
    conversation = ConversationWithTools(models, tools=[CalculatorTool()])

    # Run conversation with calculation request that models would struggle with
    complex_calculation = (
        "I need to verify a complex calculation. What is "
        "1234567890 * 9876543210 / 123456789? "
        "Please use the calculator tool to compute this precisely."
    )

    result = await conversation.process_message(complex_calculation)

    # Check for calculator tool usage
    tool_markers = ["[calculator] input:", "I'll use the calculator tool"]
    assert any(marker in result["content"] for marker in tool_markers)
```

## 🧠 Key Implementation Guidelines

### Tool Interface Pattern

```python
# app/tools/base.py
class BaseTool:
    """Base class for all tools"""
    name: str
    description: str

    async def run(self, input: str) -> str:
        """Execute the tool with the given input"""
        raise NotImplementedError()
```

### Conversation Integration Pattern

```python
# app/tools/conversation.py
class ConversationWithTools:
    """Manages a conversation that supports tool use across multiple models."""

    def __init__(
        self,
        models: List[ModelConfig],
        tools: List[BaseTool],
        config: Optional[Config] = None,
        system_prompt: Optional[str] = None
    ):
        """Initialize with models and tools"""

    async def process_message(self, user_message: str) -> Dict[str, Any]:
        """Process a user message, potentially using tools, and return response"""
```

## 📝 Usage Examples

### Calculator Tool

```python
# Standalone usage
calculator = CalculatorTool()
result = await calculator.run("sqrt(16) + 10")  # Returns "14.0"

# In conversation
conversation = ConversationWithTools(models, tools=[calculator], config=config)
response = await conversation.process_message(
    "What is 1234567890 * 9876543210? This is a complex calculation so please use the calculator."
)
```

### Anticipated Web Search Tool Usage

```python
# Standalone usage
search = TavilySearchTool(config=config)
results = await search.run("latest developments in quantum computing")

# With fallback options (future implementation)
search = WebSearchTool(
    primary_provider="tavily",
    fallback_providers=["duckduckgo", "brave"],
    config=config
)
results = await search.run("news about AI regulations")

# In conversation
conversation = ConversationWithTools(models, tools=[search], config=config)
response = await conversation.process_message(
    "What are the latest developments in quantum computing?"
)
```
