from qdrant_client import QdrantClient, models
from qdrant_client.http.exceptions import ApiException, UnexpectedResponse
from typing import List, Dict, Any, Optional
from datetime import datetime, UTC
import uuid
from .config import Config
from .models.api import VectorStoreRequest, UserCreate, ThreadCreate
import logging

logger = logging.getLogger(__name__)

__all__ = ['DatabaseClient', 'search_vectors']

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
        for collection in [
            self.config.MESSAGES_COLLECTION,
            self.config.USERS_COLLECTION,
            self.config.CHAT_THREADS_COLLECTION
        ]:
            if not self.client.collection_exists(collection):
                raise RuntimeError(f"Required collection {collection} does not exist")

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

    async def save_message(self, data: Dict[str, Any]) -> Dict[str, str]:
        """
        Save a message with its vector and metadata to Qdrant.
        Expected fields in data:
            - content (str)
            - vector (List[float])
            - thread_id (str)
            - role (str)
            - timestamp (str, ISO format)
            - phase_outputs (dict, optional)
            - novelty_score (float, optional)
            - similarity_scores (dict or list, optional)
            - cited_prior_ids (list, optional)
            - metadata (dict, optional)
        """
        try:
            point_id = str(uuid.uuid4())
            payload = {
                "content": data["content"],
                "thread_id": data.get("thread_id"),
                "role": data.get("role"),
                "timestamp": data.get("timestamp", datetime.now(UTC).isoformat()),
                "phase_outputs": data.get("phase_outputs"),
                "novelty_score": data.get("novelty_score"),
                "similarity_scores": data.get("similarity_scores"),
                "cited_prior_ids": data.get("cited_prior_ids"),
                "metadata": data.get("metadata", {})
            }
            self.client.upsert(
                collection_name=self.config.MESSAGES_COLLECTION,
                points=[
                    models.PointStruct(
                        id=point_id,
                        vector=data["vector"],
                        payload=payload
                    )
                ]
            )
            return {"id": point_id}
        except Exception as e:
            logger.error(f"Error saving message: {e}")
            raise

    async def get_message_history(self, thread_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Fetch message history for a thread, sorted by timestamp ascending.
        """
        try:
            points = await self.get_thread_messages(thread_id=thread_id, limit=limit)
            # Sort by timestamp ascending
            sorted_points = sorted(points, key=lambda p: p.get("timestamp", ""))
            return sorted_points
        except Exception as e:
            logger.error(f"Error fetching message history: {e}")
            return []

    async def search_vectors(self, query_vector: List[float], limit: int = 10) -> List[Dict[str, Any]]:
        """REST endpoint specific vector search."""
        return await self.search_similar(
            collection=self.config.MESSAGES_COLLECTION,
            query_vector=query_vector,
            limit=limit
        )

    async def store_vector(self, content: str, vector: List[float], metadata: Optional[Dict[str, Any]] = None) -> Dict[str, str]:
        """REST endpoint specific vector storage."""
        message = {
            "content": content,
            "vector": vector,
            "metadata": metadata or {}
        }
        return await self.save_message(message)

    async def delete_vector(self, vector_id: str, collection: Optional[str] = None) -> Dict[str, str]:
        """Delete a vector from the vector database.

        Args:
            vector_id: The ID of the vector to delete
            collection: Optional collection name (defaults to Config.MESSAGES_COLLECTION)

        Returns:
            Status message with the ID of the deleted vector
        """
        try:
            # Use default collection if not specified
            if collection is None:
                collection = self.config.MESSAGES_COLLECTION

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

    async def get_vector(self, vector_id: str) -> Optional[Dict[str, Any]]:
        """Get a vector by ID."""
        try:
            result = self.client.retrieve(
                collection_name=self.config.MESSAGES_COLLECTION,
                ids=[vector_id],
                with_payload=True,
                with_vectors=True
            )
            if result and len(result) > 0:
                point = result[0]
                return {
                    "id": str(point.id),
                    "content": point.payload.get('content', ''),
                    "vector": point.vector,
                    "metadata": point.payload.get('metadata', {}),
                    "created_at": point.payload.get('created_at', '')
                }
            return None
        except Exception as e:
            logger.error(f"Error retrieving vector: {e}")
            raise

    async def create_user(self, user_data: UserCreate) -> Dict[str, Any]:
        """Create a new user."""
        try:
            user_id = str(uuid.uuid4())
            point = models.PointStruct(
                id=user_id,
                vector=[0.0] * self.config.VECTOR_SIZE,  # Placeholder vector
                payload={
                    "public_key": user_data.public_key,
                    "created_at": datetime.now(UTC).isoformat(),
                    "thread_ids": [],
                }
            )

            self.client.upsert(
                collection_name=self.config.USERS_COLLECTION,
                points=[point]
            )

            return {
                "id": user_id,
                "public_key": user_data.public_key,
                "created_at": point.payload["created_at"],
                "thread_ids": []
            }
        except Exception as e:
            logger.error(f"Error creating user: {e}")
            raise

    async def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID."""
        try:
            result = self.client.retrieve(
                collection_name=self.config.USERS_COLLECTION,
                ids=[user_id],
                with_payload=True
            )
            if result and len(result) > 0:
                point = result[0]
                return {
                    "id": str(point.id),
                    "public_key": point.payload["public_key"],
                    "created_at": point.payload["created_at"],
                    "thread_ids": point.payload["thread_ids"]
                }
            return None
        except Exception as e:
            logger.error(f"Error getting user: {e}")
            raise

    async def create_thread(self, thread_data: ThreadCreate) -> Dict[str, Any]:
        """Create a new thread."""
        try:
            thread_id = str(uuid.uuid4())
            point = models.PointStruct(
                id=thread_id,
                vector=[0.0] * self.config.VECTOR_SIZE,  # Placeholder vector
                payload={
                    "name": thread_data.name,
                    "user_id": thread_data.user_id,
                    "created_at": datetime.now(UTC).isoformat(),
                    "co_authors": [thread_data.user_id],
                    "message_count": 0,
                    "last_activity": datetime.now(UTC).isoformat()
                }
            )

            # Create thread
            self.client.upsert(
                collection_name=self.config.CHAT_THREADS_COLLECTION,
                points=[point]
            )

            # Update user's thread_ids
            await self._add_thread_to_user(thread_data.user_id, thread_id)

            # If initial message provided, create it
            if thread_data.initial_message:
                await self.save_message({
                    "content": thread_data.initial_message,
                    "thread_id": thread_id,
                    "user_id": thread_data.user_id,
                    "vector": [0.0] * self.config.VECTOR_SIZE,  # We'll need to generate proper embeddings
                    "created_at": datetime.now(UTC).isoformat()
                })

            return {
                "id": thread_id,
                **point.payload
            }
        except Exception as e:
            logger.error(f"Error creating thread: {e}")
            raise

    async def get_thread(self, thread_id: str) -> Optional[Dict[str, Any]]:
        """Get thread by ID."""
        try:
            result = self.client.retrieve(
                collection_name=self.config.CHAT_THREADS_COLLECTION,
                ids=[thread_id],
                with_payload=True
            )
            if result and len(result) > 0:
                point = result[0]
                return {
                    "id": str(point.id),
                    **point.payload
                }
            return None
        except Exception as e:
            logger.error(f"Error getting thread: {e}")
            raise

    async def get_thread_messages(self, thread_id: str, limit: int = 50, before: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get messages for a thread."""
        try:
            # Build filter
            must_conditions = [
                models.FieldCondition(
                    key="thread_id",
                    match=models.MatchValue(value=thread_id)
                )
            ]

            if before:
                must_conditions.append(
                    models.FieldCondition(
                        key="created_at",
                        range=models.Range(lt=before)
                    )
                )

            search_result = self.client.scroll(
                collection_name=self.config.MESSAGES_COLLECTION,
                scroll_filter=models.Filter(
                    must=must_conditions
                ),
                limit=limit,
                with_payload=True,
                with_vectors=False
            )

            points, _ = search_result
            return [
                {
                    "id": str(point.id),
                    **point.payload
                }
                for point in points
            ]
        except Exception as e:
            logger.error(f"Error getting thread messages: {e}")
            raise

    async def get_user_threads(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all threads for a user."""
        try:
            user = await self.get_user(user_id)
            if not user:
                return []

            thread_ids = user["thread_ids"]
            if not thread_ids:
                return []

            results = self.client.retrieve(
                collection_name=self.config.CHAT_THREADS_COLLECTION,
                ids=thread_ids,
                with_payload=True
            )

            return [
                {
                    "id": str(point.id),
                    **point.payload
                }
                for point in results
            ]
        except Exception as e:
            logger.error(f"Error getting user threads: {e}")
            raise

    async def _add_thread_to_user(self, user_id: str, thread_id: str):
        """Helper method to add thread ID to user's thread list."""
        try:
            user = await self.get_user(user_id)
            if not user:
                raise ValueError(f"User {user_id} not found")

            thread_ids = user["thread_ids"]
            if thread_id not in thread_ids:
                thread_ids.append(thread_id)

                # Use upsert instead of update_payload
                self.client.upsert(
                    collection_name=self.config.USERS_COLLECTION,
                    points=[
                        models.PointStruct(
                            id=user_id,
                            vector=[0.0] * self.config.VECTOR_SIZE,  # Keep existing vector
                            payload={
                                "public_key": user["public_key"],
                                "created_at": user["created_at"],
                                "thread_ids": thread_ids
                            }
                        )
                    ],
                    wait=True
                )
        except Exception as e:
            logger.error(f"Error adding thread to user: {e}")
            raise

async def search_vectors(query_vector: List[float], limit: int = 10) -> List[Dict[str, Any]]:
    """Standalone vector search function for direct use."""
    db = DatabaseClient(Config.from_env())
    return await db.search_vectors(query_vector, limit)
