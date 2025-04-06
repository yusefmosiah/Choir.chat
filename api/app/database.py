from qdrant_client import QdrantClient, models
from qdrant_client.http.exceptions import ApiException, UnexpectedResponse
from typing import List, Dict, Any, Optional
from datetime import datetime, UTC
import uuid
from .config import Config
from .models.api import VectorStoreRequest # Removed UserCreate, ThreadCreate
import logging

logger = logging.getLogger(__name__)

__all__ = ['DatabaseClient'] # Removed 'search_vectors'
class DatabaseClient:
    def __init__(self, config: Config):
        self.config = config
        # Initialize with cloud configuration
        self.client = QdrantClient(
            url=config.QDRANT_URL,
            api_key=config.QDRANT_API_KEY,
            timeout=60,
            https=True
        )
        # Verify collections exist
        # Ensure the prompt index collection exists
        # TODO: Replace "prompt_index" with self.config.PROMPT_INDEX_COLLECTION when added to Config
        self.prompt_index_collection_name = "prompt_index"
        try:
            if not self.client.collection_exists(self.prompt_index_collection_name):
                logger.info(f"Collection '{self.prompt_index_collection_name}' not found. Creating...")
                self.client.recreate_collection(
                    collection_name=self.prompt_index_collection_name,
                    vectors_config=models.VectorParams(
                        size=self.config.VECTOR_SIZE, # Ensure VECTOR_SIZE is defined in Config
                        distance=models.Distance.COSINE # Or adjust as needed
                    )
                )
                logger.info(f"Collection '{self.prompt_index_collection_name}' created successfully.")
            else:
                 logger.info(f"Collection '{self.prompt_index_collection_name}' already exists.")
        except Exception as e:
             logger.error(f"Failed to verify or create collection '{self.prompt_index_collection_name}': {e}", exc_info=True)
             # Depending on requirements, might want to raise error here

        # Ensure payload indexes for the prompt index collection
        try:
            # Index on thread_id (keyword)
            self.client.create_payload_index(
                collection_name=self.prompt_index_collection_name,
                field_name="thread_id",
                field_schema=models.PayloadSchemaType.KEYWORD,
            )
            # Index on timestamp (keyword for ISO strings)
            self.client.create_payload_index(
                collection_name=self.prompt_index_collection_name,
                field_name="timestamp",
                field_schema=models.PayloadSchemaType.KEYWORD,
            )
            logger.info(f"Ensured payload indexes exist for '{self.prompt_index_collection_name}'.")
        except Exception as e:
            # Log warning but don't fail initialization if indexes already exist or minor error occurs
            logger.warning(f"Could not ensure payload indexes for '{self.prompt_index_collection_name}': {e}")

    async def search_similar(self, collection: str, query_vector: List[float], limit: int = 10) -> List[Dict[str, Any]]:
        try:
            # Validate vector size
            if len(query_vector) != self.config.VECTOR_SIZE:
                logger.error(f"Invalid vector size: got {len(query_vector)}, expected {self.config.VECTOR_SIZE}")
                return []

            logger.info(f"Searching with query embedding of length {len(query_vector)}, limit={limit}, collection={collection}")
            search_result = self.client.search(
                collection_name=collection,
                query_vector=query_vector,
                limit=self.config.SEARCH_LIMIT,
                with_payload=True,
                with_vectors=False
            )
            logger.info(f"Search returned {len(search_result)} results")

            return [
                {
                    "id": str(result.id),
                    "content": result.payload.get('content', ''),
                    "thread_id": result.payload.get('thread_id', ''),
                    "created_at": result.payload.get('created_at', ''),
                    "role": result.payload.get('role', ''),
                    "token_value": result.payload.get('token_value', 0),
                    "step": result.payload.get('step', ''),
                    "similarity": result.score
                }
                for result in search_result
            ]
        except Exception as e:
            logger.error(f"Error during search operation: {e}", exc_info=True)
            return []

    # --- Functions removed as per refactoring plan (Client-Side Persistence) ---
    # save_message, get_message_history, search_vectors (wrapper), store_vector (wrapper)
    # create_user, get_user, create_thread, get_thread, get_thread_messages, get_user_threads
    # _add_thread_to_user
    # Standalone search_vectors function

    async def delete_vector(self, vector_id: str, collection: Optional[str] = None) -> Dict[str, str]:
        """Delete a vector from the vector database.

        Args:
            vector_id: The ID of the vector to delete
            collection: Optional collection name (defaults to Config.PROMPT_INDEX_COLLECTION) # TODO: Update config

        Returns:
            Status message with the ID of the deleted vector
        """
        try:
            # Use default collection if not specified
            if collection is None:
                collection = self.prompt_index_collection_name

            # Delete the vector
            result = self.client.delete(
                collection_name=collection,
                points_selector=models.PointIdsList(
                    points=[vector_id]
                )
            )

            # Wait for the result to complete
            if hasattr(result, "wait"):
                result = result.wait()

            return {"status": "success", "id": vector_id}
        except Exception as e:
            logger.error(f"Error deleting vector: {e}")
            return {"status": "error", "message": str(e)}

    async def get_vector(self, vector_id: str, collection: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Get a vector by ID."""
        try:
            # Use default collection if not specified
            if collection is None:
                collection = self.prompt_index_collection_name

            result = self.client.retrieve(
                collection_name=collection,
                ids=[vector_id],
                with_payload=True,
                with_vectors=True
            )
            if result and len(result) > 0:
                point = result[0]
                # Adapt payload based on what's stored in the prompt index
                return {
                    "id": str(point.id),
                    "vector": point.vector,
                    "payload": point.payload, # Return the raw payload
                    # Example specific fields if known:
                    # "user_query": point.payload.get('user_query', ''),
                    # "thread_id": point.payload.get('thread_id', ''),
                    # "timestamp": point.payload.get('timestamp', '')
                }
            return None
        except Exception as e:
            logger.error(f"Error retrieving vector: {e}")
            raise

    async def index_prompt(self, turn_id: str, thread_id: str, user_query: str, vector: List[float], timestamp: str) -> Dict[str, str]:
        """Indexes a user prompt into the dedicated Qdrant collection."""
        try:
            # Validate vector size
            if len(vector) != self.config.VECTOR_SIZE:
                logger.error(f"Invalid vector size for indexing prompt {turn_id}: got {len(vector)}, expected {self.config.VECTOR_SIZE}")
                # Decide how to handle: raise error, return error status, or log and skip?
                # For background task, returning error status might be best.
                return {"status": "error", "message": "Invalid vector size"}

            payload = {
                "thread_id": thread_id,
                "user_query": user_query,
                "timestamp": timestamp
            }
            self.client.upsert(
                collection_name=self.prompt_index_collection_name,
                points=[
                    models.PointStruct(
                        id=turn_id, # Use turn_id as the point ID
                        vector=vector,
                        payload=payload
                    )
                ],
                wait=False # Allow async operation for background tasks
            )
            logger.info(f"Successfully submitted prompt for indexing (turn_id: {turn_id})")
            return {"status": "submitted", "id": turn_id} # Indicate submission, not completion
        except Exception as e:
            logger.error(f"Error indexing prompt for turn {turn_id}: {e}", exc_info=True)
            # Raise the exception so the background task runner can potentially log it
            raise e
