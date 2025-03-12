import asyncio
import json
from typing import Any, Dict, List, Optional, Type
import aiosqlite
import numpy as np
from pydantic import BaseModel, Field

from actor_model import ActorState, TursoStorage


class EmbeddingModel:
    """Simplified embedding model for demonstration"""

    async def embed_text(self, text: str) -> List[float]:
        """Generate a simple embedding for the text"""
        # In a real implementation, this would use an actual embedding model
        # For demonstration, we'll just create a random vector
        return list(np.random.rand(384).astype(float))


class EnhancedTursoStorage(TursoStorage):
    """Enhanced Turso storage with RAG capabilities"""

    def __init__(self, connection_string: str):
        super().__init__(connection_string=connection_string)
        self.embedding_model = EmbeddingModel()
        self.db = None

    async def connect(self):
        """Connect to the database"""
        # In a real implementation, this would use libsql directly
        # For demonstration, we'll use aiosqlite as a stand-in
        self.db = await aiosqlite.connect(":memory:")
        await self._create_tables()

    async def close(self):
        """Close the database connection"""
        if self.db:
            await self.db.close()

    async def _create_tables(self):
        """Create necessary tables"""
        if not self.db:
            return

        # Table for actor state
        await self.db.execute("""
        CREATE TABLE IF NOT EXISTS actor_state (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_name TEXT NOT NULL,
            state_json TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        # Table for vector embeddings
        await self.db.execute("""
        CREATE TABLE IF NOT EXISTS embeddings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            embedding BLOB NOT NULL,
            metadata JSON,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        await self.db.commit()

    async def save_state(self, actor_name: str, state: ActorState):
        """Save actor state to the database"""
        if not self.db:
            await self.connect()

        # Convert state to JSON
        state_json = state.model_dump_json()

        # Save to database
        await self.db.execute(
            "INSERT INTO actor_state (actor_name, state_json) VALUES (?, ?)",
            (actor_name, state_json)
        )
        await self.db.commit()

    async def load_state(self, actor_name: str, state_type: Type[ActorState]) -> Optional[ActorState]:
        """Load actor state from the database"""
        if not self.db:
            await self.connect()

        # Get the latest state for this actor
        cursor = await self.db.execute(
            "SELECT state_json FROM actor_state WHERE actor_name = ? ORDER BY created_at DESC LIMIT 1",
            (actor_name,)
        )
        row = await cursor.fetchone()

        if not row:
            return None

        # Convert JSON back to state object
        state_json = row[0]
        return state_type.model_validate_json(state_json)

    async def store_embedding(self, text: str, metadata: Optional[Dict[str, Any]] = None):
        """Store text with its embedding for RAG retrieval"""
        if not self.db:
            await self.connect()

        # Generate embedding
        embedding = await self.embedding_model.embed_text(text)

        # Store in database
        await self.db.execute(
            "INSERT INTO embeddings (text, embedding, metadata) VALUES (?, ?, ?)",
            (text, self._serialize_vector(embedding), json.dumps(metadata or {}))
        )
        await self.db.commit()

    async def perform_rag_query(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Perform a RAG query against the stored data"""
        if not self.db:
            await self.connect()

        # Generate embedding for the query
        query_embedding = await self.embedding_model.embed_text(query)

        # In a real implementation, you would use a vector similarity search
        # For this demo, we'll fetch all embeddings and calculate similarity in Python
        # (In production, you'd use cosine similarity directly in SQL or a dedicated vector DB)
        cursor = await self.db.execute(
            "SELECT id, text, embedding, metadata FROM embeddings"
        )
        rows = await cursor.fetchall()

        results = []
        for row in rows:
            db_id, text, embedding_blob, metadata_json = row
            embedding = self._deserialize_vector(embedding_blob)

            # Calculate cosine similarity
            similarity = self._cosine_similarity(query_embedding, embedding)

            results.append({
                "id": db_id,
                "text": text,
                "similarity": similarity,
                "metadata": json.loads(metadata_json)
            })

        # Sort by similarity and return top matches
        results.sort(key=lambda x: x["similarity"], reverse=True)
        return results[:limit]

    def _serialize_vector(self, vector: List[float]) -> bytes:
        """Serialize vector to bytes for storage"""
        return np.array(vector).tobytes()

    def _deserialize_vector(self, blob: bytes) -> List[float]:
        """Deserialize vector from bytes"""
        return list(np.frombuffer(blob, dtype=float))

    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors"""
        vec1_np = np.array(vec1)
        vec2_np = np.array(vec2)
        return np.dot(vec1_np, vec2_np) / (np.linalg.norm(vec1_np) * np.linalg.norm(vec2_np))


# Example data models for RAG

class ContextualKnowledge(BaseModel):
    """Knowledge item that can be retrieved through RAG"""

    title: str
    content: str
    source: str
    tags: List[str] = Field(default_factory=list)


# Example usage with the Post Chain

async def populate_knowledge_base(storage: EnhancedTursoStorage):
    """Populate the storage with some example knowledge items"""
    knowledge_items = [
        ContextualKnowledge(
            title="Actor Model Basics",
            content="The actor model is a mathematical model of concurrent computation that treats actors as the universal primitives of concurrent computation. In response to a message it receives, an actor can: make local decisions, create more actors, send more messages, and determine how to respond to the next message received.",
            source="Wikipedia",
            tags=["actor model", "concurrency", "distributed systems"]
        ),
        ContextualKnowledge(
            title="Elixir and the Actor Model",
            content="Elixir is built on top of Erlang and the BEAM virtual machine, which implements the actor model for concurrency. In Elixir, every piece of code runs inside an actor (called a process in Erlang/Elixir). These processes are lightweight and isolated, communicating only through message passing.",
            source="Elixir Documentation",
            tags=["elixir", "erlang", "actor model", "BEAM VM"]
        ),
        ContextualKnowledge(
            title="Actor Model vs. Object-Oriented Programming",
            content="While both actors and objects encapsulate state and behavior, actors are fundamentally concurrent and communicate asynchronously through messages. Objects, on the other hand, typically communicate through synchronous method calls and are not inherently designed for concurrency.",
            source="Programming Models Comparison",
            tags=["actor model", "OOP", "concurrency", "programming paradigms"]
        ),
        ContextualKnowledge(
            title="Implementing Actors in Python",
            content="Python's asyncio library provides a foundation for implementing actor-like concurrency models. While Python doesn't have native actors like Erlang, libraries can implement the actor pattern using coroutines and message queues.",
            source="Python Concurrency Patterns",
            tags=["python", "asyncio", "actor model", "implementation"]
        ),
        ContextualKnowledge(
            title="Benefits of Actor Model for AI Systems",
            content="The actor model is particularly well-suited for AI systems due to its natural handling of concurrency, fault isolation, and message-passing semantics. For multi-agent AI systems, actors provide a clean abstraction for agent communication and state encapsulation.",
            source="AI System Architecture Patterns",
            tags=["actor model", "AI systems", "multi-agent", "architecture"]
        ),
    ]

    # Store each knowledge item with its embedding
    for item in knowledge_items:
        text = f"{item.title}\n{item.content}"
        await storage.store_embedding(text, {
            "title": item.title,
            "source": item.source,
            "tags": item.tags
        })


# Integration with the Post Chain

async def enhance_post_chain_with_rag():
    """Demonstrate how the EnhancedTursoStorage integrates with Post Chain"""
    from post_chain_actors import PostChain

    # Initialize the enhanced storage
    storage = EnhancedTursoStorage(connection_string="libsql://example.turso.io")
    await storage.connect()

    # Populate with example knowledge
    await populate_knowledge_base(storage)

    # Create the Post Chain with this storage
    chain = PostChain(storage)

    # Process a user query about the actor model
    response = await chain.process_input("How does the actor model relate to AI systems?")
    print(f"Response: {response}")

    # Demonstrate a RAG query directly
    results = await storage.perform_rag_query("actor model AI benefits")
    print("\nRelevant Knowledge:")
    for result in results:
        print(f"- {result['text'][:100]}... (similarity: {result['similarity']:.4f})")

    # Clean up
    await storage.close()


if __name__ == "__main__":
    asyncio.run(enhance_post_chain_with_rag())
