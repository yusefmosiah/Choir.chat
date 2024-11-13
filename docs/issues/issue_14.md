# LanceDB Migration & Multimodal Support


## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Related to: [Thread State Management](issue_5.md)

## Description
Migrate from Qdrant to LanceDB for vector storage and add support for multimodal embeddings (text, images, audio).

## Current State
- Have ~20k message points in Qdrant
- Text-only embeddings
- Need multimodal support
- Need migration strategy

## Tasks
1. LanceDB Setup
   ```python
   # Database setup
   import lancedb

   db = lancedb.connect("choir.lance")
   messages = db.create_table(
       "messages",
       schema={
           "id": "string",
           "content": "string",
           "thread_id": "string",
           "created_at": "string",
           "embedding": "vector[1536]",  # OpenAI embedding size
           "modality": "string",         # text/image/audio
           "media_url": "string",        # for non-text content
           "chorus_result": "json"
       }
   )
   ```

2. Re-Embedding Pipeline
   ```python
   from typing import AsyncIterator
   import asyncio
   from tenacity import retry, stop_after_attempt, wait_exponential

   class MigrationPipeline:
       def __init__(self):
           self.qdrant = QdrantClient(...)
           self.lancedb = lancedb.connect("choir.lance")
           self.openai = OpenAI()
           self.rate_limiter = asyncio.Semaphore(50)  # Control concurrent requests

       async def scroll_points(self, batch_size=100) -> AsyncIterator[List[Point]]:
           """Scroll through Qdrant points with batching."""
           offset = None
           while True:
               points, offset = await self.qdrant.scroll(
                   collection_name="messages",
                   limit=batch_size,
                   offset=offset,
                   with_payload=True,
                   with_vectors=True
               )
               if not points:
                   break
               yield points

       @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=60))
       async def get_embedding(self, content: str) -> List[float]:
           """Rate-limited embedding generation."""
           async with self.rate_limiter:
               response = await self.openai.embeddings.create(
                   model="text-embedding-3-large",
                   input=content
               )
               return response.data[0].embedding

       async def process_batch(self, points: List[Point]):
           """Process a batch of points with error handling."""
           results = []
           for point in points:
               try:
                   # Generate new embedding
                   new_embedding = await self.get_embedding(point.payload["content"])

                   # Compare with original
                   similarity = cosine_similarity(new_embedding, point.vector)
                   if similarity < 0.98:  # Significant difference
                       logger.warning(f"Embedding divergence for {point.id}: {similarity}")

                   results.append({
                       "id": str(point.id),
                       "content": point.payload["content"],
                       "thread_id": point.payload["thread_id"],
                       "created_at": point.payload["created_at"],
                       "embedding": new_embedding,
                       "modality": "text",
                       "original_similarity": similarity,
                       "chorus_result": point.payload.get("chorus_result")
                   })
               except Exception as e:
                   logger.error(f"Error processing point {point.id}: {e}")
                   # Store error for retry
                   self.failed_points.append((point.id, str(e)))

           # Batch insert to LanceDB
           if results:
               await self.lancedb.messages.add(results)

       async def run_migration(self):
           """Run the full migration with progress tracking."""
           total_points = await self.qdrant.count("messages")
           processed = 0

           async for batch in self.scroll_points():
               await self.process_batch(batch)
               processed += len(batch)

               # Progress update
               logger.info(f"Processed {processed}/{total_points} points")

           # Handle failed points
           if self.failed_points:
               logger.warning(f"Failed points: {len(self.failed_points)}")
               # Write failures to file for manual review
               with open("failed_migrations.json", "w") as f:
                   json.dump(self.failed_points, f)
   ```

3. Migration Monitoring
   ```python
   class MigrationMonitor:
       async def check_embedding_quality(self):
           """Compare embeddings between systems."""
           divergent = []
           async for point in self.pipeline.scroll_points():
               lance_point = self.lancedb.messages.get(point.id)
               similarity = cosine_similarity(
                   point.vector,
                   lance_point["embedding"]
               )
               if similarity < 0.98:
                   divergent.append((point.id, similarity))
           return divergent

       async def verify_data_integrity(self):
           """Verify all data migrated correctly."""
           qdrant_count = await self.qdrant.count("messages")
           lance_count = len(self.lancedb.messages)

           assert lance_count >= qdrant_count, "Missing points in LanceDB"

           # Check random samples for payload equality
           for _ in range(100):
               point_id = random.choice(await self.get_all_ids())
               qdrant_point = await self.qdrant.retrieve(point_id)
               lance_point = self.lancedb.messages.get(point_id)

               assert self.payloads_equal(
                   qdrant_point.payload,
                   lance_point
               ), f"Payload mismatch for {point_id}"
   ```

## Testing Requirements
- Migration validation
  - Data integrity
  - Embedding preservation
  - Performance comparison
- Multimodal support
  - Text embeddings
  - Image embeddings
  - Audio embeddings
- Search functionality
  - Cross-modal search
  - Relevance scoring
  - Performance metrics

## Success Criteria
- Clean migration
- Multimodal support
- Improved performance
- Type-safe operations
