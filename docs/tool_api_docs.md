# Tool API Documentation

## Web Search Tools

### Tavily Search

#### API Limitations & Rate Limits

Tavily provides web search capabilities optimized for AI applications. At the time of writing:

- **Free Tier**: 1,000 searches per month
- **Paid Plans**: Tiered pricing based on search volume
- **Rate Limit**: 10 requests per second (soft limit)
- **Response Time**: Typically 1-3 seconds per search
- **Content Freshness**: Results are generally up-to-date (within days)

#### Usage in Our Implementation

The `TavilySearchTool` implementation in `app/tools/tavily_search.py`:

1. Uses [LangChain's Tavily integration](https://python.langchain.com/docs/integrations/tools/tavily_search/)
2. Formats results in a structured way that includes:
   - Result titles
   - Content snippets
   - Source URLs
3. Limits the total response size to avoid overwhelming models
4. Supports image inclusion (disabled by default)
5. Handles asynchronous operation

#### Environment Configuration

Configure via environment variables:

- `TAVILY_API_KEY`: Direct API key
- `TAVILY_API_KEY_PATH`: Path to a file containing the API key

#### Sample Usage

```python
from app.tools.tavily_search import TavilySearchTool
from app.config import Config

# Direct initialization
search = TavilySearchTool(
    config=Config(),
    include_images=False,
    k=40  # Number of results
)

# Example search
results = await search.run("latest developments in quantum computing")
```

### DuckDuckGo Search

DuckDuckGo provides a non-commercial API that doesn't require authentication, making it suitable for development and testing.

#### API Limitations & Rate Limits

- **Authentication**: None required for non-commercial use
- **Rate Limits**: Not explicitly defined, but excessive usage may lead to IP blocking
- **Response Time**: Generally fast (< 1 second)
- **Content Freshness**: Results are up-to-date
- **Commercial Use**: Not permitted without explicit permission

#### Implementation Notes

DuckDuckGo implementation will serve as a backup search provider when:

- Tavily API limits are reached
- Results from Tavily are insufficient

### Brave Search

Brave Search is a privacy-focused search engine that offers an API for developers.

#### API Limitations & Rate Limits

- **Authentication**: Requires an API key
- **Free Tier**: Limited to 2,000 searches per month
- **Rate Limits**: 60 requests per minute (much higher than most alternatives)
- **Response Time**: Fast (< 1 second typically)
- **Content Freshness**: Excellent, updated continuously

#### Implementation Notes

Our `BraveSearchTool` implementation in `app/tools/brave_search.py`:

1. Uses the official Brave Search API
2. Returns structured results with title, URL, and content
3. Supports optional parameters:
   - Country code for localized results
   - Language code
   - Default returns 40 results (increased from 5)

#### Environment Configuration

Configure via environment variables:

- `BRAVE_API_KEY`: Direct API key
- `BRAVE_API_KEY_PATH`: Path to a file containing the API key

#### Sample Usage

```python
from app.tools.brave_search import BraveSearchTool
from app.config import Config

# Direct initialization
search = BraveSearchTool(
    config=Config(),
    max_results=40,
    country="us",
    search_lang="en"
)

# Example search
results = await search.run("latest developments in quantum computing")
```

## Fallback Strategy

The web search tools are designed to support graceful fallback:

1. **Primary**: Tavily (when API key is available)
2. **Fallback 1**: DuckDuckGo (for non-commercial/development use)
3. **Fallback 2**: Brave Search (if configured)

This ensures search functionality remains available even if a particular provider is unavailable or rate-limited.

## Best Practices for Web Search Tool

### Handling Events After Model Training Cutoff

When using the web search tool, especially for events that occurred after a model's training data cutoff, follow these best practices:

1. **Include Current Date Context**: The system includes the current date in both system prompts and search results to help models understand temporal context.

2. **Use Trust Instructions**: The system includes explicit instructions for models to trust search results even when they contradict training data.

3. **Be Specific in Queries**: When asking about recent events, include specific dates to help the model contextualize the information.

4. **Quote Search Results**: When discussing sensitive or potentially contradictory information, quote specific search results to reinforce the source.

5. **Provide Temporal Anchors**: Relate recent events to well-known events within the model's training data to help it build a mental timeline.

### Common Issues and Solutions

1. **Model Rejection of Future Events**: Models may be reluctant to accept information about events they "know" haven't happened yet based on their training data. The timestamp and trust instructions help mitigate this issue.

2. **Inconsistent Information**: When search results contain contradictory information, the model may struggle to determine which is correct. In these cases, prefer official sources and most recent information.

3. **Confabulation**: Without proper guidance, models may blend their training data with search results, potentially confabulating details. The trust instructions and usage guidance help reduce this behavior.

4. **Search Provider Failures**: The fallback mechanism ensures that even if one search provider fails, others can still provide results. This makes the system more robust to API issues.

These patterns are automatically applied in the latest implementation of the `WebSearchTool` and `ConversationWithTools` classes.

### Known Issues

1. **Tavily Connection Issues**: Tavily search may occasionally return a "Expecting value: line 1 column 1 (char 0)" error, which indicates JSON parsing issues with the API response. The system will automatically fall back to other providers when this occurs.

2. **DuckDuckGo Instability**: The DuckDuckGo tool may return "unsupported value" errors. This is related to the unofficial nature of the API wrapper and rate limiting. Again, the fallback mechanism ensures continuous operation even when this provider fails.

3. **Search Result Quality**: Search providers are vulnerable to SEO manipulation and spam. With the default of 40 results (increased from 5), the system has a better chance of finding authoritative information amidst potential disinformation. The increased result count helps overcome cases where less reliable sources appear at the top of search results.

4. **Result Diversity**: Different search providers may return completely different results for the same query. By increasing the number of results and potentially combining from multiple providers, we get a more diverse set of sources, which helps the model make better-informed responses.
