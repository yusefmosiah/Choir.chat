"""Qdrant vector database tools for semantic search and storage.

This module provides tools for interacting with the Qdrant vector database,
allowing models to search for semantically similar content and store new information.
"""

import uuid
import logging
from typing import Dict, List, Optional, Any

from langchain_core.tools import tool

from app.config import Config
from app.database import DatabaseClient

# Get database client
config = Config()
db_client = DatabaseClient(config)

# Configure logging
logger = logging.getLogger("qdrant_tool")


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



    unique_results_list = []
    seen_content = set()
    for r in results:
        content = r.get("content")
        if content is not None and content not in seen_content:
            unique_results_list.append({
                "content": content,
                "score": r.get("score", 0.0),
                "metadata": r.get("metadata", {}),
                "provider": "qdrant" # Add provider field
            })
            seen_content.add(content)

    # Return results as a JSON string, even if empty
    json_output = json.dumps(unique_results_list)
    if unique_results_list:
        logger.info(f"Qdrant search returning {len(unique_results_list)} results as JSON.")
    else:
        logger.info(f"Qdrant search returning no unique results for query: '{query}'")
    # logger.debug(f"Qdrant JSON output: {json_output[:500]}...") # Optional: Log output snippet
    return json_output


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
