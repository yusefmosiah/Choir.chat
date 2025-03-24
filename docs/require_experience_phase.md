# Experience Phase Requirements

## Overview

The Experience phase enriches the conversation context with relevant historical knowledge, search results, and retrieved information. It serves as the system's memory and knowledge acquisition component.

## Core Responsibilities

1. Retrieve relevant information from external sources
2. Enrich context with historical knowledge
3. Add search results and database lookups
4. Tag sources and relevance of added information
5. Maintain connections to knowledge repositories

## Temporal Focus: The Past Knowledge

The Experience phase embodies the system's relationship with past knowledge. It draws upon previously accumulated information, historical context, and external knowledge sources to enrich the current conversation.

## Input Specification

The Experience phase accepts:

1. **Primary Content**:

   - User input with initial Action phase assessment
   - Queries derived from user input

2. **Metadata**:
   - Context from previous phases
   - Search/retrieval parameters
   - Knowledge source configurations

## Output Specification

The Experience phase produces:

1. **Primary Content**:

   - Original content enhanced with retrieved information
   - Search results and knowledge retrievals

2. **Metadata**:
   - Source attribution for added information
   - Relevance scores for retrievals
   - Confidence in information accuracy
   - Context operations for information management

## Processing Requirements

### Knowledge Retrieval

The Experience phase should:

- Execute targeted searches based on user queries
- Perform vector similarity lookups in knowledge bases
- Retrieve relevant documents or snippets
- Filter results based on relevance thresholds

### Context Management

For effective information enrichment:

- Tag all added information with source attribution
- Add relevance scores to retrieved content
- Use ADD context operations for new information
- Use TAG operations to mark information characteristics
- Preserve original queries alongside results

### Error Handling

The Experience phase should handle:

- Failed retrievals with appropriate fallbacks
- Source unavailability with graceful degradation
- Rate limiting with retries and backoff strategies
- Empty result sets with alternative search strategies

## Performance Requirements

1. **Latency**: Complete retrieval operations within 3-5 seconds
2. **Result Quality**: Maintain relevance scores above 0.7 for retrievals
3. **Volume Control**: Limit added context to avoid token limit issues
4. **Source Diversity**: Attempt to retrieve from multiple sources when appropriate

## Implementation Constraints

1. Support multiple retrieval methods:
   - Vector database searches
   - Web search API calls
   - Document retrieval systems
   - Structured database queries
2. Implement caching for frequent retrievals
3. Support asynchronous retrieval operations
4. Maintain provenance tracking for all added information

## Examples

### Web Search Retrieval

```python
async def web_search_retrieval(query: str, context: List[Message]) -> ExperienceResult:
    """Retrieve information from web search."""
    search_results = await web_search_tool.search(query, max_results=3)

    # Add context operations for search results
    context_ops = []
    for result in search_results:
        context_ops.append({
            "operation": "ADD",
            "target": "context",
            "data": {
                "content": result.snippet,
                "source": result.url
            },
            "metadata": {
                "relevance": result.relevance_score,
                "timestamp": result.published_date
            }
        })

    return ExperienceResult(
        content={
            "original_query": query,
            "search_results": search_results
        },
        metadata={
            "context_operations": context_ops,
            "retrieval_method": "web_search"
        }
    )
```

### Vector Database Retrieval

```python
async def vector_db_retrieval(query: str, context: List[Message]) -> ExperienceResult:
    """Retrieve information from vector database."""
    # Convert query to embedding
    embedding = await embeddings_service.embed(query)

    # Retrieve similar documents
    documents = await vector_db.similarity_search(
        embedding,
        top_k=5,
        min_relevance=0.75
    )

    # Add context operations for retrieved documents
    context_ops = []
    for doc in documents:
        context_ops.append({
            "operation": "ADD",
            "target": "context",
            "data": {
                "content": doc.content,
                "source": doc.metadata.source
            },
            "metadata": {
                "relevance": doc.relevance_score,
                "created_at": doc.metadata.created_at
            }
        })

    return ExperienceResult(
        content={
            "original_query": query,
            "retrieved_documents": documents
        },
        metadata={
            "context_operations": context_ops,
            "retrieval_method": "vector_db"
        }
    )
```

## Interaction with Other Phases

- **Receives from**: Action phase
- **Sends to**: Intention phase
- **Relationship**: Provides knowledge enrichment before intention refinement

## Success Criteria

1. Retrieves information relevant to user queries
2. Properly attributes sources of all added information
3. Maintains appropriate balance of detail vs. conciseness
4. Preserves context operations for downstream phases
5. Falls back gracefully when primary sources are unavailable
