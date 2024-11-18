# LanceDB Migration & Multimodal Support

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Migrate from Qdrant to LanceDB for vector storage and add support for multimodal embeddings (text, images, audio), preparing for future content types.

## Tasks

### 1. LanceDB Setup
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

### 2. Migration Pipeline
```python
class MigrationPipeline:
    def __init__(self):
        self.qdrant = QdrantClient(...)
        self.lancedb = lancedb.connect("choir.lance")
        self.rate_limiter = asyncio.Semaphore(50)

    async def migrate_points(self):
        async for batch in self.scroll_points():
            await self.process_batch(batch)

    async def process_batch(self, points):
        results = []
        for point in points:
            try:
                # Convert point format
                new_point = self.convert_point(point)
                results.append(new_point)
            except Exception as e:
                self.failed_points.append((point.id, str(e)))

        # Batch insert to LanceDB
        if results:
            await self.lancedb.messages.add(results)
```

### 3. Multimodal Support
- Add image embedding generation
- Support audio content processing
- Implement cross-modal search

## Success Criteria
- Successful data migration
- Support for multiple content types
- Maintained search performance
- Clean error handling
