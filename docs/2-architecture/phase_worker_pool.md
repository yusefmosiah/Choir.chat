# Phase Worker Pool Architecture

## Overview

This document describes an extension to the actor-based PostChain architecture, introducing the concepts of Phase Types and Worker Pools. This pattern significantly enhances the flexibility, scalability, and extensibility of the system while maintaining the conceptual clarity of the AEIOU-Y PostChain.

## Core Concepts

### Phase Types vs. Actor Instances

In the extended architecture:

- Each phase of the PostChain (Action, Experience, Intention, Observation, Understanding, Yield) is a **Phase Type**
- Each Phase Type can have multiple specialized **Actor Implementations**
- Actor Implementations are selected based on input modality, domain, or task requirements

### Worker Pool Pattern

The Worker Pool pattern abstracts underlying AI models and resources:

- **Workers**: Represent specific LLM configurations, specialized models, or processing units
- **Worker Pools**: Groups of interchangeable workers that can process similar tasks
- **Dispatchers**: Components that assign tasks to appropriate workers based on capabilities

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                      PostChain Coordinator                             │
└───────────────────────────────┬────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          Phase Types                                   │
│                                                                        │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                          │
│  │ Action   │    │Experience│    │Intention │                          │
│  │ Type     │───▶│  Type    │───▶│  Type    │───┐                      │
│  └──────────┘    └──────────┘    └──────────┘   │                      │
│       ▲                                          │                      │
│       │                                          ▼                      │
│       │                                          │                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐   │                      │
│  │  Yield   │◀───│Understand│◀───│Observe   │◀──┘                      │
│  │  Type    │    │  Type    │    │  Type    │                          │
│  └──────────┘    └──────────┘    └──────────┘                          │
│                                                                        │
└───────┬─────┬────────┬──────────────┬───────────┬─────┬────────────────┘
        │     │        │              │           │     │
        ▼     ▼        ▼              ▼           ▼     ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│Audio     │ │Vision    │ │Text      │ │Multimodal│ │Code      │ │Model     │
│Actors    │ │Actors    │ │Actors    │ │Actors    │ │Actors    │ │Actors    │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
       │            │            │            │           │            │
       └────────────┴────────────┴──────┬─────┴───────────┴────────────┘
                                        │
                                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         Worker Pool Manager                            │
└─────────────────┬──────────────────────────────────────┬───────────────┘
                  │                                      │
         ┌────────▼─────────┐                  ┌─────────▼────────┐
         │  Model Worker    │                  │ Processing Worker │
         │  Pools           │                  │ Pools             │
         └──────────────────┘                  └──────────────────┘
         ┌────────────────────────────────────────────────────────┐
         │ • GPT-4 Workers  • LLaMA Workers   • Mixtral Workers   │
         │ • Claude Workers • Falcon Workers  • Embedder Workers  │
         │ • Gemini Workers • Vision Workers  • Audio Workers     │
         │ • Custom Workers • Code Workers    • Local Workers     │
         └────────────────────────────────────────────────────────┘
```

## Implementation Components

### 1. Phase Type Registry

```python
class PhaseType(Enum):
    ACTION = "action"
    EXPERIENCE = "experience"
    INTENTION = "intention"
    OBSERVATION = "observation"
    UNDERSTANDING = "understanding"
    YIELD = "yield"

class PhaseTypeRegistry:
    def __init__(self):
        self.registry = {phase_type: {} for phase_type in PhaseType}

    def register_actor(self, phase_type: PhaseType, modality: str, actor_class: Type[Actor]):
        """Register an actor implementation for a specific phase type and modality"""
        if phase_type not in self.registry:
            self.registry[phase_type] = {}

        self.registry[phase_type][modality] = actor_class

    def get_actor_class(self, phase_type: PhaseType, modality: str) -> Type[Actor]:
        """Get the appropriate actor implementation for a phase type and modality"""
        if phase_type not in self.registry or modality not in self.registry[phase_type]:
            # Fall back to default implementation if specific one not found
            modality = "default"

        return self.registry[phase_type].get(modality)
```

### 2. Worker Pool Manager

```python
class Worker:
    """Base class for workers that process tasks"""
    def __init__(self, worker_id: str, capabilities: List[str]):
        self.worker_id = worker_id
        self.capabilities = capabilities
        self.busy = False

    async def process(self, task: Any) -> Any:
        """Process a task and return the result"""
        # Implementation depends on worker type
        pass

class ModelWorker(Worker):
    """Worker that wraps an AI model"""
    def __init__(self, worker_id: str, model_name: str, capabilities: List[str]):
        super().__init__(worker_id, capabilities)
        self.model_name = model_name
        # Initialize model client

    async def process(self, task: Any) -> Any:
        """Process a task using the AI model"""
        # Call the underlying model
        return result

class WorkerPool:
    """Pool of workers with similar capabilities"""
    def __init__(self, pool_id: str, worker_type: Type[Worker]):
        self.pool_id = pool_id
        self.worker_type = worker_type
        self.workers: List[Worker] = []

    def add_worker(self, worker: Worker):
        """Add a worker to the pool"""
        if isinstance(worker, self.worker_type):
            self.workers.append(worker)

    async def get_available_worker(self) -> Optional[Worker]:
        """Get an available worker from the pool"""
        for worker in self.workers:
            if not worker.busy:
                return worker
        return None

    async def process_task(self, task: Any) -> Any:
        """Process a task using an available worker"""
        worker = await self.get_available_worker()
        if not worker:
            raise NoAvailableWorkerError(f"No available workers in pool {self.pool_id}")

        worker.busy = True
        try:
            result = await worker.process(task)
            return result
        finally:
            worker.busy = False

class WorkerPoolManager:
    """Manages multiple worker pools"""
    def __init__(self):
        self.pools: Dict[str, WorkerPool] = {}

    def register_pool(self, pool: WorkerPool):
        """Register a worker pool"""
        self.pools[pool.pool_id] = pool

    def get_pool(self, pool_id: str) -> Optional[WorkerPool]:
        """Get a worker pool by ID"""
        return self.pools.get(pool_id)

    async def process_task(self, pool_id: str, task: Any) -> Any:
        """Process a task using a specific worker pool"""
        pool = self.get_pool(pool_id)
        if not pool:
            raise PoolNotFoundError(f"Worker pool {pool_id} not found")

        return await pool.process_task(task)
```

### 3. Modality-Specific Actors

```python
class TextActionActor(Actor[ActionState]):
    """Actor implementation for text-based Action phase"""
    async def process(self, message: Message) -> Any:
        # Text-specific processing
        pass

class AudioActionActor(Actor[AudioActionState]):
    """Actor implementation for audio-based Action phase"""
    async def process(self, message: Message) -> Any:
        # Audio-specific processing
        pass

class VideoActionActor(Actor[VideoActionState]):
    """Actor implementation for video-based Action phase"""
    async def process(self, message: Message) -> Any:
        # Video-specific processing
        pass

class CodeActionActor(Actor[CodeActionState]):
    """Actor implementation for code-based Action phase"""
    async def process(self, message: Message) -> Any:
        # Code-specific processing
        pass
```

### 4. Dynamic Actor Factory

```python
class ActorFactory:
    """Factory for creating appropriate actor instances"""
    def __init__(self, registry: PhaseTypeRegistry, worker_pool_manager: WorkerPoolManager):
        self.registry = registry
        self.worker_pool_manager = worker_pool_manager

    async def create_actor(self, phase_type: PhaseType, modality: str, **kwargs) -> Actor:
        """Create an actor instance for the specified phase type and modality"""
        actor_class = self.registry.get_actor_class(phase_type, modality)
        if not actor_class:
            raise ActorNotFoundError(f"No actor found for {phase_type.value} and {modality}")

        # Create actor with appropriate worker pool
        pool_id = f"{modality}_{phase_type.value}_pool"
        pool = self.worker_pool_manager.get_pool(pool_id)

        # Create actor instance with configured worker pool
        actor = actor_class(worker_pool=pool, **kwargs)
        return actor
```

## Processing Flows

### Input Modality Detection

```python
class ModalityDetector:
    """Detects the modality of input data"""

    async def detect_modality(self, input_data: Any) -> str:
        """Determine the modality of the input data"""
        if isinstance(input_data, str):
            return "text"
        elif self._is_audio(input_data):
            return "audio"
        elif self._is_video(input_data):
            return "video"
        elif self._is_code(input_data):
            return "code"
        elif self._is_model(input_data):
            return "model"
        else:
            return "multimodal"
```

### PostChain Orchestration

```python
class PostChain:
    """Orchestrates the flow through the phase types"""

    def __init__(self,
                 factory: ActorFactory,
                 modality_detector: ModalityDetector):
        self.factory = factory
        self.modality_detector = modality_detector

    async def process(self, input_data: Any) -> Any:
        """Process input through the entire PostChain"""

        # Detect input modality
        modality = await self.modality_detector.detect_modality(input_data)

        # Create phase actors for this modality
        action_actor = await self.factory.create_actor(PhaseType.ACTION, modality)
        experience_actor = await self.factory.create_actor(PhaseType.EXPERIENCE, modality)
        intention_actor = await self.factory.create_actor(PhaseType.INTENTION, modality)
        observation_actor = await self.factory.create_actor(PhaseType.OBSERVATION, modality)
        understanding_actor = await self.factory.create_actor(PhaseType.UNDERSTANDING, modality)
        yield_actor = await self.factory.create_actor(PhaseType.YIELD, modality)

        # Initialize correlation ID
        correlation_id = f"{modality}-{uuid.uuid4()}"

        # Process through the chain
        action_result = await action_actor.process(Message(
            type=MessageType.REQUEST,
            sender="system",
            recipient=action_actor.name,
            content=input_data,
            correlation_id=correlation_id
        ))

        # Continue through other phases...

        return result
```

## Use Cases and Examples

### Multi-Modal Processing

The architecture supports unified processing across modalities:

```python
# Register different actor implementations
registry = PhaseTypeRegistry()
registry.register_actor(PhaseType.ACTION, "text", TextActionActor)
registry.register_actor(PhaseType.ACTION, "audio", AudioActionActor)
registry.register_actor(PhaseType.ACTION, "video", VideoActionActor)
registry.register_actor(PhaseType.ACTION, "code", CodeActionActor)
```

### Model-As-Input

The architecture can handle AI models themselves as inputs:

```python
class ModelActionActor(Actor[ModelActionState]):
    """Process an AI model as input"""

    async def process(self, message: Message) -> Any:
        # Extract model from input
        model = message.content

        # Analyze model architecture, weights, or behavior
        model_analysis = await self.analyze_model(model)

        # Generate insights about the model
        return model_analysis
```

### Specialized Domain Actors

The architecture supports domain-specific processing:

```python
registry.register_actor(PhaseType.EXPERIENCE, "medical", MedicalExperienceActor)
registry.register_actor(PhaseType.EXPERIENCE, "legal", LegalExperienceActor)
registry.register_actor(PhaseType.EXPERIENCE, "financial", FinancialExperienceActor)
```

## Benefits of the Architecture

### Flexibility

- Process various input types through the same conceptual workflow
- Add new modalities without changing the core architecture
- Specialize actors for different domains or tasks

### Scalability

- Scale worker pools independently based on demand
- Add specialized workers for performance-critical tasks
- Balance load across multiple workers

### Performance

- Select optimal model configurations for specific tasks
- Process multiple phases concurrently where appropriate
- Utilize hardware acceleration for specific modalities

### Extensibility

- Add new worker types without modifying existing code
- Implement new modality handlers as needed
- Create specialized actor implementations for emerging use cases

## Implementation Considerations

### Worker Pool Scaling

- Implement auto-scaling based on demand patterns
- Monitor worker utilization and performance
- Create worker lifecycle management policies

### Worker Specialization

- Design model-specific prompts for each worker type
- Optimize context handling for different modalities
- Create specialized pre/post-processing for different input types

### State Management

- Design state objects specific to each modality
- Implement efficient serialization for different data types
- Create modality-specific persistence strategies

## Next Steps

1. Implement core PhaseType registry and WorkerPool manager
2. Create basic actor implementations for text modality
3. Extend to audio and video modalities
4. Implement specialized domain actors
5. Create comprehensive test suite for multi-modal scenarios
6. Benchmark performance across different worker configurations

## Conclusion

The Phase Worker Pool architecture extends the actor model to handle diverse input modalities and specialized processing requirements while maintaining the conceptual clarity of the PostChain. By abstracting AI models as workers and implementing modality-specific actors, the system can adapt to new input types, specialized domains, and evolving AI capabilities without requiring a redesign of the core architecture.
