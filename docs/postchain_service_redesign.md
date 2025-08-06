# PostChain Service Redesign: Conversation-to-Publication Infrastructure

VERSION postchain_service_redesign: 2.0 (Learning Economy Architecture)

## Current State Analysis

The existing `langchain_workflow.py` requires transformation from a prototype conversation system into production-ready conversation-to-publication infrastructure that serves the learning economy:

### Technical Debt
- **Monolithic structure**: 1591 lines in a single file
- **Conversation-focused design**: Built for chat rather than publication-quality output
- **No publication pipeline**: Missing infrastructure for citable article generation
- **Limited content processing**: Basic text input without multi-format support
- **Provider-specific hacks**: Gemini/OpenAI message preparation scattered throughout
- **Performance bottlenecks**: No intelligent routing based on content complexity

### Missing Learning Economy Features
- **Multi-format input processing**: No support for PDFs, EPUBs, YouTube transcripts
- **Publication-quality output**: No professional formatting or citation management
- **Collaborative editing**: No infrastructure for AI-human content collaboration
- **Research assistance**: Limited source gathering and context integration
- **Citation tracking**: No infrastructure for intellectual property management
- **Educational integration**: No tools for assignment-to-publication workflows

## Redesign Architecture

### Core Principles
1. **Publication Focus**: Transform conversations into citable, professional-quality articles
2. **Multi-Format Input**: Process text, PDFs, EPUBs, YouTube transcripts, and audio/video
3. **Collaborative Intelligence**: AI serves as research assistant and writing collaborator
4. **Citation Economics**: Generate intellectual property with proper attribution and tracking
5. **Educational Integration**: Support assignment-to-publication workflows for institutions

### New Service Structure

```
postchain/
├── core/
│   ├── orchestrator.py          # Main coordination logic
│   ├── router.py                # Intelligent query routing
│   ├── retry_manager.py         # Retry and fallback handling
│   ├── state_manager.py         # Thread state management
│   └── context_manager.py       # Token counting and model switching
├── phases/
│   ├── base_phase.py            # Abstract phase interface
│   ├── action_phase.py          # Fast initial response
│   ├── experience_phase.py      # Vector + web search
│   ├── analysis_phases.py       # I/O/U phases
│   └── yield_phase.py           # Final synthesis
├── providers/
│   ├── base_provider.py         # Abstract LLM provider
│   ├── openai_provider.py       # OpenAI/OpenRouter
│   ├── anthropic_provider.py    # Claude with MCP
│   ├── google_provider.py       # Gemini
│   └── bedrock_provider.py      # AWS Bedrock adapter
├── input/
│   ├── file_processor.py        # Multi-format file processing
│   ├── youtube_processor.py     # YouTube transcript extraction
│   ├── content_chunker.py       # Intelligent content segmentation
│   └── format_handlers/         # Specific format processors
│       ├── text_handler.py      # TXT, MD processing
│       ├── pdf_handler.py       # PDF extraction
│       ├── epub_handler.py      # EPUB processing
│       └── media_handler.py     # Audio/video transcription
├── tools/
│   ├── mcp_client.py            # Model Context Protocol client
│   ├── tool_registry.py         # Dynamic tool discovery
│   └── tool_executor.py         # Safe tool execution
└── config/
    ├── phase_configs.py         # Default phase prompts
    ├── routing_rules.py         # Query complexity routing
    ├── model_configs.py         # Provider configurations
    └── context_configs.py       # Context window management
```

## Intelligent Query Routing

### Complexity Classification
```python
class QueryComplexity(Enum):
    SIMPLE = "simple"        # "What's the weather?"
    MODERATE = "moderate"    # "Explain quantum computing"
    COMPLEX = "complex"      # Novel ideas requiring deep analysis

class QueryRouter:
    async def classify_query(self, query: str, context: List[Message]) -> QueryComplexity:
        # Use fast classifier to determine complexity
        # Factors: length, novelty, specificity, context requirements

    async def route_query(self, query: str, complexity: QueryComplexity) -> ExecutionPlan:
        if complexity == QueryComplexity.SIMPLE:
            return SimpleExecutionPlan()  # Action + Web search only
        elif complexity == QueryComplexity.MODERATE:
            return ModerateExecutionPlan()  # Action + Experience + Yield
        else:
            return ComplexExecutionPlan()  # Full AEIOU-Y with analysis
```

### Execution Plans
```python
@dataclass
class ExecutionPlan:
    phases: List[PhaseConfig]
    max_retries: int
    fallback_models: List[ModelConfig]
    tool_permissions: Set[str]
    reward_multiplier: float

class SimpleExecutionPlan(ExecutionPlan):
    def __init__(self):
        super().__init__(
            phases=[ActionPhase(), WebSearchPhase()],
            max_retries=1,
            fallback_models=[],
            tool_permissions={"web_search"},
            reward_multiplier=0.1  # Lower rewards for simple queries
        )

class ComplexExecutionPlan(ExecutionPlan):
    def __init__(self):
        super().__init__(
            phases=[ActionPhase(), ExperiencePhase(), IntentionPhase(),
                   ObservationPhase(), UnderstandingPhase(), YieldPhase()],
            max_retries=3,
            fallback_models=[GPT4_FALLBACK, CLAUDE_FALLBACK],
            tool_permissions={"web_search", "vector_search", "mcp_tools"},
            reward_multiplier=1.0  # Full rewards for complex analysis
        )
```

## Phase Modularization

### Base Phase Interface
```python
from abc import ABC, abstractmethod

class BasePhase(ABC):
    def __init__(self, config: PhaseConfig):
        self.config = config
        self.retry_manager = RetryManager()

    @abstractmethod
    async def execute(self, state: PostChainState) -> PhaseResult:
        pass

    async def execute_with_retry(self, state: PostChainState) -> PhaseResult:
        return await self.retry_manager.execute_with_retry(
            self.execute, state, max_retries=self.config.max_retries
        )
```

### Client-Side Phase Configuration
```python
@dataclass
class PhaseConfig:
    name: str
    prompt_template: str
    model_config: ModelConfig
    tool_permissions: Set[str]
    max_retries: int
    timeout_seconds: int

    @classmethod
    def from_client_config(cls, client_config: dict) -> 'PhaseConfig':
        # Allow clients to customize phase behavior
        return cls(**client_config)

    def to_shareable_config(self) -> dict:
        # Export config for sharing between users
        return {
            "name": self.name,
            "prompt_template": self.prompt_template,
            "model": self.model_config.to_dict(),
            "tools": list(self.tool_permissions)
        }
```

## AWS Bedrock Integration

### LangChain Adapter
```python
from langchain_aws import BedrockLLM
from langchain_core.language_models import BaseLLM

class BedrockProvider(BaseLLMProvider):
    def __init__(self, config: BedrockConfig):
        self.config = config
        self.client = BedrockLLM(
            model_id=config.model_id,
            region_name=config.region,
            credentials_profile_name=config.profile
        )

    async def generate(self, messages: List[BaseMessage], **kwargs) -> AIMessage:
        # Cost optimization: use cheaper models for simple queries
        if kwargs.get('complexity') == QueryComplexity.SIMPLE:
            model_id = self.config.cheap_model_id
        else:
            model_id = self.config.premium_model_id

        return await self.client.agenerate([messages])

    def estimate_cost(self, messages: List[BaseMessage]) -> float:
        # Calculate estimated cost for budget management
        token_count = self._estimate_tokens(messages)
        return token_count * self.config.cost_per_token
```

## Model Context Protocol (MCP) Integration

### MCP Client Implementation
```python
class MCPClient:
    def __init__(self, server_configs: List[MCPServerConfig]):
        self.servers = {}
        for config in server_configs:
            self.servers[config.name] = MCPServer(config)

    async def discover_tools(self) -> List[MCPTool]:
        tools = []
        for server in self.servers.values():
            server_tools = await server.list_tools()
            tools.extend(server_tools)
        return tools

    async def execute_tool(self, tool_name: str, args: dict) -> ToolResult:
        server = self._find_server_for_tool(tool_name)
        return await server.call_tool(tool_name, args)

class AnthropicMCPProvider(BaseLLMProvider):
    def __init__(self, config: AnthropicConfig):
        super().__init__(config)
        self.mcp_client = MCPClient(config.mcp_servers)

    async def generate_with_tools(self, messages: List[BaseMessage]) -> AIMessage:
        available_tools = await self.mcp_client.discover_tools()

        response = await self.client.generate(
            messages=messages,
            tools=available_tools
        )

        if response.tool_calls:
            tool_results = []
            for tool_call in response.tool_calls:
                result = await self.mcp_client.execute_tool(
                    tool_call.name, tool_call.args
                )
                tool_results.append(result)

            # Continue conversation with tool results
            return await self._continue_with_tool_results(messages, response, tool_results)

        return response
```

## Retry and Forking Mechanisms

### Retry Manager
```python
class RetryManager:
    def __init__(self, config: RetryConfig):
        self.config = config

    async def execute_with_retry(self,
                               func: Callable,
                               *args,
                               max_retries: int = 3) -> Any:
        last_exception = None

        for attempt in range(max_retries + 1):
            try:
                return await func(*args)
            except RetryableError as e:
                last_exception = e
                if attempt < max_retries:
                    await self._handle_retry(e, attempt)
                    continue
                else:
                    break
            except NonRetryableError as e:
                # Don't retry for certain errors
                raise e

        # All retries exhausted
        return await self._handle_final_failure(last_exception)

    async def _handle_retry(self, error: Exception, attempt: int):
        # Exponential backoff
        delay = self.config.base_delay * (2 ** attempt)
        await asyncio.sleep(delay)

        # Model switching on retry
        if isinstance(error, ModelError):
            await self._switch_to_fallback_model()

    async def fork_execution(self,
                           func: Callable,
                           *args,
                           fork_configs: List[dict]) -> List[Any]:
        # Execute multiple versions in parallel
        tasks = []
        for config in fork_configs:
            task = asyncio.create_task(func(*args, **config))
            tasks.append(task)

        results = await asyncio.gather(*tasks, return_exceptions=True)
        return [r for r in results if not isinstance(r, Exception)]
```

## Implementation Phases

### Phase 1: Core Refactoring (Week 1-2)
1. **Extract phase classes** from monolithic workflow
2. **Implement base interfaces** for phases and providers
3. **Create orchestrator** for phase coordination
4. **Add basic retry mechanisms**

### Phase 2: Intelligent Routing (Week 3)
1. **Implement query classifier** for complexity detection
2. **Create execution plans** for different query types
3. **Add reward scaling** based on complexity
4. **Optimize for simple queries**

### Phase 3: Provider Integration (Week 4)
1. **AWS Bedrock adapter** with cost optimization
2. **Enhanced Anthropic provider** with MCP support
3. **Tool registry** for dynamic discovery
4. **Provider fallback chains**

### Phase 4: Client Configuration (Week 5)
1. **Client-side prompt editing** interface
2. **Configuration sharing** between users
3. **Custom execution plans**
4. **A/B testing framework** for prompts

### Phase 5: Advanced Features (Week 6+)
1. **Looping and iteration** capabilities
2. **Multi-model consensus** for critical decisions
3. **Performance monitoring** and optimization
4. **Advanced tool orchestration**

## File Input Processing

### Multi-Format Support
```python
class FileProcessor:
    def __init__(self):
        self.handlers = {
            '.txt': TextHandler(),
            '.md': MarkdownHandler(),
            '.pdf': PDFHandler(),
            '.epub': EPUBHandler(),
            '.docx': DocxHandler(),
            '.html': HTMLHandler()
        }

    async def process_file(self, file_path: str, file_type: str = None) -> ProcessedContent:
        if file_type is None:
            file_type = self._detect_file_type(file_path)

        handler = self.handlers.get(file_type)
        if not handler:
            raise UnsupportedFileTypeError(f"File type {file_type} not supported")

        raw_content = await handler.extract_content(file_path)

        # Intelligent chunking based on content structure
        chunks = await self._chunk_content(raw_content, file_type)

        return ProcessedContent(
            original_content=raw_content,
            chunks=chunks,
            metadata=handler.extract_metadata(file_path),
            file_type=file_type
        )

class PDFHandler(BaseFileHandler):
    async def extract_content(self, file_path: str) -> str:
        # Use PyMuPDF for better text extraction
        import fitz
        doc = fitz.open(file_path)
        text = ""
        for page in doc:
            text += page.get_text()
        return text

    def extract_metadata(self, file_path: str) -> dict:
        doc = fitz.open(file_path)
        return {
            "page_count": doc.page_count,
            "title": doc.metadata.get("title", ""),
            "author": doc.metadata.get("author", ""),
            "creation_date": doc.metadata.get("creationDate", "")
        }

class EPUBHandler(BaseFileHandler):
    async def extract_content(self, file_path: str) -> str:
        import ebooklib
        from ebooklib import epub

        book = epub.read_epub(file_path)
        content = []

        for item in book.get_items():
            if item.get_type() == ebooklib.ITEM_DOCUMENT:
                content.append(item.get_content().decode('utf-8'))

        return '\n\n'.join(content)
```

### YouTube Transcript Processing
```python
class YouTubeProcessor:
    def __init__(self):
        self.transcript_api = YouTubeTranscriptApi()

    async def process_youtube_url(self, url: str) -> ProcessedContent:
        video_id = self._extract_video_id(url)

        try:
            # Try to get transcript
            transcript = self.transcript_api.get_transcript(video_id)
            content = self._format_transcript(transcript)

            # Get video metadata
            metadata = await self._get_video_metadata(video_id)

            # Chunk by timestamp for better context
            chunks = self._chunk_by_timestamp(transcript)

            return ProcessedContent(
                original_content=content,
                chunks=chunks,
                metadata=metadata,
                file_type="youtube_transcript"
            )

        except TranscriptsDisabled:
            # Fallback to audio transcription
            return await self._transcribe_audio(video_id)

    def _format_transcript(self, transcript: List[dict]) -> str:
        formatted = []
        for entry in transcript:
            timestamp = self._format_timestamp(entry['start'])
            text = entry['text']
            formatted.append(f"[{timestamp}] {text}")
        return '\n'.join(formatted)

    async def _transcribe_audio(self, video_id: str) -> ProcessedContent:
        # Use Whisper or similar for audio transcription
        audio_path = await self._download_audio(video_id)
        transcript = await self._whisper_transcribe(audio_path)

        return ProcessedContent(
            original_content=transcript,
            chunks=self._chunk_by_sentences(transcript),
            metadata={"source": "audio_transcription"},
            file_type="audio_transcript"
        )
```

## Context Management System

### Token Counting and Model Selection
```python
class ContextManager:
    def __init__(self):
        self.token_counters = {
            'openai': tiktoken.encoding_for_model,
            'anthropic': AnthropicTokenCounter(),
            'google': GoogleTokenCounter()
        }

        # Model context windows (tokens)
        self.context_limits = {
            'gpt-4': 128_000,
            'gpt-4-turbo': 128_000,
            'gpt-4o': 128_000,
            'claude-3-haiku': 200_000,
            'claude-3-sonnet': 200_000,
            'claude-3-opus': 200_000,
            'claude-3.5-sonnet': 200_000,
            'gemini-1.5-pro': 1_000_000,
            'gemini-1.5-flash': 1_000_000,
            'gpt-4o-mini': 128_000
        }

        # High-context fallback models
        self.high_context_models = {
            'openai': 'gpt-4-turbo',
            'anthropic': 'claude-3.5-sonnet',
            'google': 'gemini-1.5-pro'
        }

    async def check_context_fit(self,
                              messages: List[BaseMessage],
                              model_config: ModelConfig) -> ContextCheckResult:
        token_count = await self._count_tokens(messages, model_config)
        context_limit = self.context_limits.get(model_config.model_name, 128_000)

        # Reserve 20% for response
        usable_limit = int(context_limit * 0.8)

        if token_count <= usable_limit:
            return ContextCheckResult(
                fits=True,
                token_count=token_count,
                limit=context_limit,
                recommended_action=None
            )
        else:
            return ContextCheckResult(
                fits=False,
                token_count=token_count,
                limit=context_limit,
                recommended_action=self._recommend_action(token_count, model_config)
            )

    def _recommend_action(self, token_count: int, model_config: ModelConfig) -> str:
        # Try high-context model first
        high_context_model = self.high_context_models.get(model_config.provider)
        if high_context_model:
            high_context_limit = self.context_limits.get(high_context_model, 128_000)
            if token_count <= int(high_context_limit * 0.8):
                return f"switch_to_high_context:{high_context_model}"

        # If still too large, recommend chunking
        return "chunk_content"

    async def handle_context_overflow(self,
                                    messages: List[BaseMessage],
                                    model_config: ModelConfig,
                                    error: Exception) -> ModelConfig:
        """Handle context overflow by switching to high-context model"""

        if "context" in str(error).lower() or "token" in str(error).lower():
            # This is a context overflow error
            high_context_model = self.high_context_models.get(model_config.provider)

            if high_context_model and high_context_model != model_config.model_name:
                logger.info(f"Context overflow detected. Switching from {model_config.model_name} to {high_context_model}")

                new_config = model_config.copy()
                new_config.model_name = high_context_model

                # Verify the new model can handle the context
                check_result = await self.check_context_fit(messages, new_config)
                if check_result.fits:
                    return new_config
                else:
                    # Even high-context model can't handle it, need chunking
                    raise ContextTooLargeError("Content exceeds even high-context model limits")
            else:
                raise ContextTooLargeError("No high-context fallback available")
        else:
            # Not a context error, re-raise
            raise error

### Intelligent Content Chunking
```python
class ContentChunker:
    def __init__(self, context_manager: ContextManager):
        self.context_manager = context_manager

    async def chunk_for_model(self,
                            content: str,
                            model_config: ModelConfig,
                            overlap_ratio: float = 0.1) -> List[ContentChunk]:

        context_limit = self.context_manager.context_limits.get(
            model_config.model_name, 128_000
        )

        # Use 60% of context for content, 20% for system/user prompts, 20% for response
        chunk_size = int(context_limit * 0.6)
        overlap_size = int(chunk_size * overlap_ratio)

        # Intelligent chunking based on content structure
        if self._has_clear_structure(content):
            return await self._structure_based_chunking(content, chunk_size, overlap_size)
        else:
            return await self._semantic_chunking(content, chunk_size, overlap_size)

    async def _structure_based_chunking(self, content: str, chunk_size: int, overlap_size: int) -> List[ContentChunk]:
        # Split by headers, paragraphs, sentences
        sections = self._split_by_structure(content)
        chunks = []
        current_chunk = ""
        current_tokens = 0

        for section in sections:
            section_tokens = await self._estimate_tokens(section)

            if current_tokens + section_tokens <= chunk_size:
                current_chunk += section
                current_tokens += section_tokens
            else:
                if current_chunk:
                    chunks.append(ContentChunk(
                        content=current_chunk,
                        token_count=current_tokens,
                        chunk_index=len(chunks)
                    ))

                # Start new chunk with overlap
                overlap_content = self._get_overlap(current_chunk, overlap_size)
                current_chunk = overlap_content + section
                current_tokens = await self._estimate_tokens(current_chunk)

        if current_chunk:
            chunks.append(ContentChunk(
                content=current_chunk,
                token_count=current_tokens,
                chunk_index=len(chunks)
            ))

        return chunks

    async def _semantic_chunking(self, content: str, chunk_size: int, overlap_size: int) -> List[ContentChunk]:
        # Use embeddings to find semantic boundaries
        sentences = self._split_into_sentences(content)
        embeddings = await self._get_sentence_embeddings(sentences)

        # Find semantic breaks using cosine similarity
        semantic_breaks = self._find_semantic_breaks(embeddings, threshold=0.7)

        # Create chunks respecting semantic boundaries
        chunks = []
        current_chunk_sentences = []
        current_tokens = 0

        for i, sentence in enumerate(sentences):
            sentence_tokens = await self._estimate_tokens(sentence)

            if (current_tokens + sentence_tokens <= chunk_size and
                i not in semantic_breaks):
                current_chunk_sentences.append(sentence)
                current_tokens += sentence_tokens
            else:
                if current_chunk_sentences:
                    chunk_content = ' '.join(current_chunk_sentences)
                    chunks.append(ContentChunk(
                        content=chunk_content,
                        token_count=current_tokens,
                        chunk_index=len(chunks)
                    ))

                # Start new chunk
                current_chunk_sentences = [sentence]
                current_tokens = sentence_tokens

        return chunks
```

This redesign transforms the postchain from a prototype into a production-ready system that can handle everything from simple weather queries to complex novel analysis of large documents and videos, while intelligently managing context windows and automatically switching to appropriate models when needed.
