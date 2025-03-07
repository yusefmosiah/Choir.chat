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
- [x] Document API limitations and rate limits
- [x] Create fallback logic between search providers
- [x] Create provider switching logic
- [ ] Implement caching to reduce API calls
- [x] Test provider fallback scenarios
- [x] Implement rate limit handling with exponential backoff

#### Primary Search Implementation (Brave Search)

- [x] Create Brave Search tool interface (`app/tools/brave_search.py`)
- [x] Implement structured result formatting
- [x] Add rate limit handling with retry logic and exponential backoff
- [x] Configure as default search provider due to higher reliability
- [x] Write standalone unit tests
- [x] Document Brave Search API usage & limitations

#### Backup Search Implementations

- [x] Implement DuckDuckGo search (for development/testing)
- [x] Implement Tavily Search as fallback option
- [x] Create provider switching logic with intelligent fallback order
- [x] Test provider fallback scenarios
- [x] Document multi-provider strategy

#### Web Search Provider Strategy

- [x] Default to Brave Search as primary provider (most reliable in testing)
- [x] Fall back to Tavily, then DuckDuckGo if primary provider fails
- [x] Added exponential backoff for rate limit handling (Brave Search)
- [x] Improved error handling for all providers
- [x] Added retry logic with configurable attempts
- [ ] Implement request caching to reduce API usage

#### Search Provider Reliability Assessment

Based on extensive testing, here's our assessment of search providers:

1. **Brave Search**: ★★★★☆

   - Most reliable provider in our testing
   - High-quality results with official API
   - Rate limits can be an issue (1 request/second on free tier)
   - Successfully implemented exponential backoff to handle rate limits
   - Now configured as our default primary provider

2. **Tavily Search**: ★★★☆☆

   - AI-optimized search, but inconsistent reliability
   - Frequent "Expecting value: line 1 column 1 (char 0)" JSON parsing errors
   - Good result quality when working
   - Moved to first fallback position due to reliability issues

3. **DuckDuckGo Search**: ★★☆☆☆
   - No API key required, good for development
   - Frequent rate limit errors (202 Ratelimit)
   - "unsupported value" errors with different backends
   - Used as last resort fallback

Our current strategy ensures maximum reliability by starting with the most consistent provider and falling back as needed. Exponential backoff and retry logic has significantly improved overall search reliability.

#### Web Search Integration Tests

- [x] Create test for web search in multimodel chat thread
- [x] Test different query types and result handling
- [x] Verify context maintenance with search results
- [x] Test search provider fallback
- [x] Document integration patterns

#### Web Search Improvements

- [x] Add timestamp to system prompt to help models understand current date
- [x] Add trust instructions to help models accept search results that contradict training data
- [x] Add usage guidance in search results for events after model training cutoff
- [x] Test handling of search results about "future" events relative to model training
- [x] Document best practices for prompting models with recent events

#### LangGraph Provider Compatibility

- [x] Test web search tool with different providers in LangGraph
- [x] Document provider-specific compatibility issues
- [x] Identify best-performing models for tool usage
- [x] Create detailed test reports for each provider/model

##### Provider Compatibility Findings

1. **OpenAI Models**: ✅ 75% Success

   - ❌ gpt-4o: Failed the test - didn't return the correct score (34-0 instead of 40-22) despite successful tool usage
   - ✅ gpt-4o-mini: Successfully used web search tool and returned correct information
   - ✅ o1: Successfully used web search tool and returned correct information
   - ✅ o3-mini: Successfully used web search tool and returned correct information
   - Implementation note: All models correctly used function calling, but gpt-4o had incorrect information in its response

2. **Anthropic Models**: ✅ 100% Success

   - Claude-3.7-Sonnet: Successfully used web search tool and returned correct information
   - Claude-3.5-Haiku: Successfully used web search tool and returned correct information
   - Consistent function calling format and reliable tool usage

3. **Google Models**: ⚠️ 25% Success (Mixed Results)

   - ✅ gemini-2.0-flash: Successfully used web search tool and returned correct information
   - ❌ gemini-2.0-flash-lite: Failed to use web search tool; responded as if it couldn't access future information
   - ❌ gemini-2.0-pro-exp-02-05: Failed due to "500 Internal error occurred" from Google API
   - ❌ gemini-2.0-flash-thinking-exp-01-21: Failed because "Function calling is not enabled for this model"
   - Implementation note: Only production models reliably support function calling

4. **Cohere Models**: ❌ 0% Success

   - Failed to properly use tools despite claiming compatibility
   - Different tool calling format requires custom implementation
   - Requires direct integration of search results rather than tool-based interaction

5. **Fireworks Models**: ❌ 0% Success

   - deepseek-r1: Failed to make any tool calls; gave a general response without using the tool
   - deepseek-v3: Initially failed to make tool calls but eventually performed a web search using Brave; however, still failed to provide the correct team or score
   - qwen2p5-coder-32b-instruct: Failed to make any tool calls; responded with incorrect information
   - qwen-qwq-32b: Returned a 404 error indicating the model was not found or accessible
   - Implementation note: The models either didn't use tools at all or failed to properly integrate tool results

6. **Mistral Models**: ✅ 100% Success

   - ✅ pixtral-12b-2409: Successfully used web search tool and returned correct information
   - ✅ mistral-small-latest: Successfully used web search tool and returned correct information
   - ✅ pixtral-large-latest: Successfully used web search tool and returned correct information
   - ✅ mistral-large-latest: Successfully used web search tool and returned correct information
   - ✅ codestral-latest: Successfully used web search tool and returned correct information
   - Implementation note: Mistral models show excellent tool usage capabilities, with previous rate limit issues now resolved

7. **Groq Models**: ✅ 40% Success
   - ❌ llama-3.3-70b-versatile: Failed to make any tool calls; gave a general response without using the tool
   - ✅ qwen-qwq-32b: Successfully used web search tool and returned correct information
   - ❌ deepseek-r1-distill-qwen-32b: Failed to make any tool calls; gave a response without using the tool
   - ❌ deepseek-r1-distill-llama-70b-specdec: Failed due to 503 Service Unavailable error
   - ✅ deepseek-r1-distill-llama-70b: Successfully used web search tool and returned correct information
   - Implementation note: Inconsistent results, with some models using tools effectively while others don't attempt tool usage

##### LangGraph Tool Compatibility Matrix

| Provider  | Models Tested | Success Rate | Top Performing Models                       | Common Failure Modes                                          |
| --------- | ------------- | ------------ | ------------------------------------------- | ------------------------------------------------------------- |
| OpenAI    | 4             | 75%          | o1, o3-mini, gpt-4o-mini                    | Incorrect information despite tool usage                      |
| Anthropic | 2             | 100%         | Claude-3.7-Sonnet, Claude-3.5-Haiku         | None observed                                                 |
| Google    | 4             | 25%          | gemini-2.0-flash                            | Function calling not supported, API errors                    |
| Cohere    | Multiple      | 0%           | None                                        | Different tool calling format requiring custom implementation |
| Fireworks | 4             | 0%           | None                                        | No tool usage attempts, 404 errors                            |
| Mistral   | 5             | 100%         | All tested models                           | None (previous rate limiting issues resolved)                 |
| Groq      | 5             | 40%          | qwen-qwq-32b, deepseek-r1-distill-llama-70b | No tool usage, service unavailable errors                     |

##### Comprehensive List of Models with Working Tool Support

Based on our extensive testing, the following models successfully work with tool usage:

**OpenAI Models:**

- o1
- o3-mini
- gpt-4o-mini

**Anthropic Models:**

- Claude-3.7-Sonnet
- Claude-3.5-Haiku

**Google Models:**

- gemini-2.0-flash

**Mistral Models:**

- mistral-small-latest
- mistral-large-latest
- pixtral-12b-2409
- pixtral-large-latest
- codestral-latest

**Groq Models:**

- qwen-qwq-32b
- deepseek-r1-distill-llama-70b

These models successfully:

1. Make appropriate tool calls when presented with queries requiring external information
2. Process tool responses correctly
3. Incorporate tool-provided information into their final responses
4. Return accurate information based on tool results

When implementing tool support in production, we recommend prioritizing models from Anthropic and Mistral for their 100% success rates, followed by selected OpenAI models. For cost-sensitive applications, Mistral's models provide an excellent balance of reliability and performance.

##### Updated Implementation Recommendations

- **For Production**: Use Anthropic or Mistral models for most reliable tool usage; OpenAI's o1, o3-mini, or gpt-4o-mini as alternatives
- **Most Accurate**: Anthropic models maintain their 100% success rate, with Mistral models close behind at 80%
- **Best Performance/Cost**: Mistral's large models and smaller OpenAI models offer good balance of reliability and cost
- **Custom Implementations**: Maintain provider-specific implementations for Cohere and providers with inconsistent tool support
- **Error Handling**: Improve error handling for rate limits, API failures, and service unavailable errors
- **Fallback Strategy**: Implement provider detection and fallback to direct content integration for models lacking function calling
- **Search Provider**: Use Brave Search as primary provider with fallback to Tavily and DuckDuckGo
- **Rate Limiting**: Exponential backoff with retry logic successfully implemented for Brave Search

##### Next Steps for Tool Integration

- Create a unified tool interface that can adapt to provider-specific requirements
- Implement automatic fallback mechanisms for models that don't support function calling
- Add rate limit handling with exponential backoff for providers like Mistral
- Develop robust error handling for API failures and service outages
- Continue testing emerging models and updating compatibility matrix

##### In-Depth Analysis of Successful Tool Usage

Based on the examination of test reports from successful models, we've identified several key factors that contribute to effective tool usage:

1. **Tool Call Format Consistency**: Successful models like Mistral and Groq's `qwen-qwq-32b` consistently format their tool calls in a way that matches the expected OpenAI function calling format.

2. **Query Refinement**: Top-performing models often refine the user's query to create more focused search terms (e.g., "Super Bowl LIX 2025 winner final score" instead of the original query) which leads to more relevant results.

3. **Response Quality**: Successful models not only use the tools correctly but also synthesize the information into coherent, accurate responses that directly answer the user's question.

4. **Error Resilience**: Models that handle search provider errors gracefully (falling back to alternative providers) show better overall performance.

5. **Tool Selection Intelligence**: Many failures stem from models not even attempting to use tools. This suggests we need better tool selection prompting or fallback approaches for these models.

For implementation, we should ensure our tool interface handles these variations by:

- Normalizing tool call formats across different providers
- Providing clear instructions about when and how to use tools
- Implementing fallback mechanisms for models that don't make tool calls
- Monitoring and handling rate limits and API errors proactively

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
search = BraveSearchTool(config=config)
results = await search.run("latest developments in quantum computing")

# With fallback options
search = WebSearchTool(
    primary_provider="brave",  # Now using Brave as primary provider
    fallback_providers=["tavily", "duckduckgo"],
    config=config
)
results = await search.run("news about AI regulations")

# In conversation
conversation = ConversationWithTools(models, tools=[search], config=config)
response = await conversation.process_message(
    "What are the latest developments in quantum computing?"
)
```
