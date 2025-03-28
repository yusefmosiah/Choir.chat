"""Qdrant vector database tools for semantic search and storage.

This module provides tools for interacting with the Qdrant vector database,
allowing models to search for semantically similar content and store new information.
"""

import uuid
from typing import Dict, List, Optional, Any

from langchain_core.tools import tool

from app.config import Config
from app.database import DatabaseClient

# Get database client
config = Config()
db_client = DatabaseClient(config)


@tool
async def qdrant_search(query: str, collection: str = None, limit: int = 5) -> str:
    """Search for semantically similar content in the vector database.

    Args:
        query: The search query text
        collection: Optional collection name (defaults to Config.MESSAGES_COLLECTION)
        limit: Maximum number of results to return (default: 5)

    Returns:
        Text summary of the search results
    """
    from langchain_openai import OpenAIEmbeddings

    # Use default collection if not specified
    if collection is None:
        collection = config.MESSAGES_COLLECTION

    # Generate embedding for the query
    embeddings = OpenAIEmbeddings(model=config.EMBEDDING_MODEL)
    query_vector = await embeddings.aembed_query(query)

    # Search for similar vectors
    results = await db_client.search_vectors(query_vector, limit=limit)

    if not results:
        return f"No semantically similar information found for: '{query}'"

    # Format results
    formatted_results = "Found semantically similar information:\n\n"
    for i, result in enumerate(results, 1):
        content = result.get("content", "No content")
        score = result.get("score", 0)
        formatted_results += f"{i}. (Score: {score:.2f}) {content}\n\n"

    return formatted_results


@tool
async def qdrant_store(content: str, collection: str = None, metadata: Dict[str, Any] = None) -> str:
    """Store information in the vector database for later retrieval.

    Args:
        content: The text content to store
        collection: Optional collection name (defaults to Config.MESSAGES_COLLECTION)
        metadata: Optional metadata to store with the content

    Returns:
        Confirmation message with the ID of the stored content
    """
    from langchain_openai import OpenAIEmbeddings

    # Use default collection if not specified
    if collection is None:
        collection = config.MESSAGES_COLLECTION

    # Generate embedding for the content
    embeddings = OpenAIEmbeddings(model=config.EMBEDDING_MODEL)
    content_vector = await embeddings.aembed_query(content)

    # Prepare metadata
    if metadata is None:
        metadata = {}

    # Store the vector
    result = await db_client.store_vector(content, content_vector, metadata)

    return f"Successfully stored in the vector database with ID: {result['id']}"


@tool
async def qdrant_delete(vector_id: str, collection: str = None) -> str:
    """Delete information from the vector database.

    Args:
        vector_id: The ID of the vector to delete
        collection: Optional collection name (defaults to Config.MESSAGES_COLLECTION)

    Returns:
        Confirmation message about the deletion
    """
    # Use default collection if not specified
    if collection is None:
        collection = config.MESSAGES_COLLECTION

    # Delete the vector
    result = await db_client.delete_vector(vector_id, collection)

    if result["status"] == "success":
        return f"Successfully deleted vector with ID: {result['id']}"
    else:
        return f"Error deleting vector: {result.get('message', 'Unknown error')}"
