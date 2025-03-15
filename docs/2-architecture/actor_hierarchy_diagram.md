# Actor Hierarchy Diagram

This document provides a visual representation of the actor hierarchy in Choir's architecture, showing the relationships, inheritance patterns, and communication flows between different actors in the system.

## Table of Contents

1. [Introduction](#introduction)
2. [Actor Hierarchy Overview](#actor-hierarchy-overview)
3. [Core Actor Types](#core-actor-types)
4. [PostChain Actors](#postchain-actors)
5. [System Actors](#system-actors)
6. [Integration Actors](#integration-actors)
7. [Actor Relationships](#actor-relationships)
8. [Implementation Considerations](#implementation-considerations)

## Introduction

The actor hierarchy diagram visualizes the organization of actors within Choir's architecture. This hierarchy helps developers understand the relationships between different actors, their responsibilities, and how they interact with each other.

Actors in Choir are organized in a hierarchical structure that reflects their functional roles, inheritance patterns, and supervision relationships. This document provides both high-level and detailed views of this hierarchy.

## Actor Hierarchy Overview

```
                                ┌─────────────┐
                                │  BaseActor  │
                                └──────┬──────┘
                                       │
                 ┌───────────────┬─────┴─────┬───────────────┐
                 │               │           │               │
        ┌────────┴────────┐     │     ┌─────┴─────┐   ┌─────┴─────┐
        │  ProcessingActor│     │     │SystemActor│   │StorageActor│
        └────────┬────────┘     │     └─────┬─────┘   └─────┬─────┘
                 │              │           │               │
    ┌────────────┼──────────┐   │   ┌───────┼───────┐ ┌────┴────┐
    │            │          │   │   │       │       │ │         │
┌───┴───┐  ┌─────┴────┐ ┌───┴───┴┐ ┌┴───────┴┐ ┌────┴─┐ ┌───────┴────┐
│ActionA│  │ExperienceA│ │IntentionA│ │SupervisorA│ │LoggerA│ │DatabaseActorA│
└───────┘  └──────────┘ └─────────┘ └──────────┘ └──────┘ └────────────┘
```

The diagram above shows the high-level actor hierarchy in Choir. The `BaseActor` serves as the foundation for all actors in the system, with specialized actor types inheriting from it.

## Core Actor Types

### BaseActor

The `BaseActor` is the foundational class for all actors in the system. It provides:

- Basic message handling capabilities
- Actor lifecycle management
- State management primitives
- Error handling mechanisms
- Logging and monitoring hooks

```python
class BaseActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = {}

    async def receive(self, message):
        # Basic message handling logic
        pass

    async def before_receive(self, message):
        # Pre-processing hooks
        pass

    async def after_receive(self, message, response):
        # Post-processing hooks
        pass

    def log(self, level, message):
        # Logging functionality
        pass
```

### ProcessingActor

The `ProcessingActor` extends `BaseActor` to provide specialized functionality for processing data and transforming it. These actors form the core of Choir's processing pipeline.

```python
class ProcessingActor(BaseActor):
    async def process(self, data):
        # Processing logic
        pass

    async def receive(self, message):
        if message.type == "PROCESS":
            result = await self.process(message.data)
            return Response(type="PROCESS_COMPLETE", data=result)
        else:
            return await super().receive(message)
```

### SystemActor

The `SystemActor` provides system-level functionality such as supervision, coordination, and management of other actors.

```python
class SystemActor(BaseActor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.supervised_actors = {}

    async def supervise(self, actor_id):
        # Supervision logic
        pass

    async def receive(self, message):
        if message.type == "SUPERVISE":
            await self.supervise(message.data["actor_id"])
            return Response(type="SUPERVISION_STARTED", data={"actor_id": message.data["actor_id"]})
        else:
            return await super().receive(message)
```

### StorageActor

The `StorageActor` specializes in data persistence and retrieval operations.

```python
class StorageActor(BaseActor):
    async def store(self, key, value):
        # Storage logic
        pass

    async def retrieve(self, key):
        # Retrieval logic
        pass

    async def receive(self, message):
        if message.type == "STORE":
            await self.store(message.data["key"], message.data["value"])
            return Response(type="STORE_COMPLETE", data={"key": message.data["key"]})
        elif message.type == "RETRIEVE":
            value = await self.retrieve(message.data["key"])
            return Response(type="RETRIEVE_COMPLETE", data={"key": message.data["key"], "value": value})
        else:
            return await super().receive(message)
```

## PostChain Actors

The PostChain actors implement the AEIOU-Y framework in the actor model. Each actor corresponds to a phase in the PostChain processing pipeline.

### ActionActor

The `ActionActor` processes input and initiates the PostChain sequence.

```python
class ActionActor(ProcessingActor):
    async def process(self, data):
        # Action processing logic
        pass
```

### ExperienceActor

The `ExperienceActor` processes the output from the `ActionActor` and applies experiential context.

```python
class ExperienceActor(ProcessingActor):
    async def process(self, data):
        # Experience processing logic
        pass
```

### IntentionActor

The `IntentionActor` processes the output from the `ExperienceActor` and determines the intention.

```python
class IntentionActor(ProcessingActor):
    async def process(self, data):
        # Intention processing logic
        pass
```

### ObservationActor

The `ObservationActor` processes the output from the `IntentionActor` and makes observations.

```python
class ObservationActor(ProcessingActor):
    async def process(self, data):
        # Observation processing logic
        pass
```

### UnderstandingActor

The `UnderstandingActor` processes the output from the `ObservationActor` and develops understanding.

```python
class UnderstandingActor(ProcessingActor):
    async def process(self, data):
        # Understanding processing logic
        pass
```

### YieldActor

The `YieldActor` processes the output from the `UnderstandingActor` and produces the final result.

```python
class YieldActor(ProcessingActor):
    async def process(self, data):
        # Yield processing logic
        pass
```

## System Actors

System actors provide infrastructure and support for the application actors.

### SupervisorActor

The `SupervisorActor` monitors and manages other actors, handling failures and ensuring system stability.

```python
class SupervisorActor(SystemActor):
    async def handle_failure(self, actor_id, error):
        # Failure handling logic
        pass

    async def restart_actor(self, actor_id):
        # Actor restart logic
        pass
```

### LoggerActor

The `LoggerActor` centralizes logging for the entire actor system.

```python
class LoggerActor(SystemActor):
    async def log(self, level, message, metadata=None):
        # Logging logic
        pass
```

### MetricsActor

The `MetricsActor` collects and reports metrics about the actor system.

```python
class MetricsActor(SystemActor):
    async def record_metric(self, name, value, tags=None):
        # Metrics recording logic
        pass

    async def get_metrics(self, names=None, tags=None):
        # Metrics retrieval logic
        pass
```

## Integration Actors

Integration actors connect the Choir system with external services and systems.

### DatabaseActor

The `DatabaseActor` provides an interface to the database system (libSQL/Turso).

```python
class DatabaseActor(StorageActor):
    async def query(self, sql, parameters=None):
        # Database query logic
        pass

    async def execute(self, sql, parameters=None):
        # Database execution logic
        pass
```

### BlockchainActor

The `BlockchainActor` interfaces with blockchain systems (e.g., Sui).

```python
class BlockchainActor(StorageActor):
    async def submit_transaction(self, transaction):
        # Transaction submission logic
        pass

    async def query_blockchain(self, query):
        # Blockchain query logic
        pass
```

### APIActor

The `APIActor` provides an interface for external API communication.

```python
class APIActor(ProcessingActor):
    async def call_api(self, endpoint, method, data=None, headers=None):
        # API call logic
        pass
```

## Actor Relationships

The following diagram illustrates the communication patterns between actors in the system:

```
┌─────────┐     ┌───────────┐     ┌───────────┐     ┌────────────┐     ┌─────────────┐     ┌──────────┐
│ActionActor│────►ExperienceActor│────►IntentionActor│────►ObservationActor│────►UnderstandingActor│────►YieldActor│
└─────────┘     └───────────┘     └───────────┘     └────────────┘     └─────────────┘     └──────────┘
     │                │                 │                  │                   │                 │
     │                │                 │                  │                   │                 │
     ▼                ▼                 ▼                  ▼                   ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                        SupervisorActor                                               │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
     ▲                ▲                 ▲                  ▲                   ▲                 ▲
     │                │                 │                  │                   │                 │
     │                │                 │                  │                   │                 │
┌──────────┐    ┌──────────┐     ┌─────────────┐    ┌────────────┐     ┌─────────────┐    ┌───────────┐
│LoggerActor│    │MetricsActor│     │DatabaseActor│    │BlockchainActor│     │   APIActor   │    │Other Actors│
└──────────┘    └──────────┘     └─────────────┘    └────────────┘     └─────────────┘    └───────────┘
```

### Supervision Hierarchy

The supervision hierarchy defines how actors are monitored and managed:

1. The `SupervisorActor` sits at the top of the supervision hierarchy
2. It monitors all processing actors (PostChain actors)
3. It also monitors system and integration actors
4. When an actor fails, the supervisor can:
   - Restart the actor
   - Replace the actor with a new instance
   - Escalate the failure to a higher-level supervisor

### Message Flow

The primary message flow in the PostChain follows this sequence:

1. `ActionActor` receives input and processes it
2. `ActionActor` sends the result to `ExperienceActor`
3. `ExperienceActor` processes and sends to `IntentionActor`
4. `IntentionActor` processes and sends to `ObservationActor`
5. `ObservationActor` processes and sends to `UnderstandingActor`
6. `UnderstandingActor` processes and sends to `YieldActor`
7. `YieldActor` produces the final result

## Implementation Considerations

When implementing actors according to this hierarchy, consider the following:

### Actor Creation and Registration

Actors should be created and registered with the actor system in a way that reflects the hierarchy:

```python
# Create the actor system
actor_system = ActorSystem()

# Create and register system actors
supervisor_actor = SupervisorActor("supervisor")
logger_actor = LoggerActor("logger")
metrics_actor = MetricsActor("metrics")

actor_system.register(supervisor_actor)
actor_system.register(logger_actor)
actor_system.register(metrics_actor)

# Create and register PostChain actors
action_actor = ActionActor("action")
experience_actor = ExperienceActor("experience")
# ... other PostChain actors

actor_system.register(action_actor)
actor_system.register(experience_actor)
# ... register other actors

# Set up supervision relationships
await supervisor_actor.receive(Message(type="SUPERVISE", data={"actor_id": "action"}))
await supervisor_actor.receive(Message(type="SUPERVISE", data={"actor_id": "experience"}))
# ... supervise other actors
```

### Actor Communication

Actors should communicate through well-defined message types:

```python
# Example of actor communication
action_response = await action_actor.receive(
    Message(
        type="PROCESS",
        data={"input": "Hello, world!"}
    )
)

experience_response = await experience_actor.receive(
    Message(
        type="PROCESS",
        data={"action_output": action_response.data}
    )
)
```

### State Management

Each actor should manage its own state:

```python
class ExampleActor(BaseActor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = {
            "processed_count": 0,
            "last_processed_time": None,
            "error_count": 0
        }

    async def receive(self, message):
        if message.type == "PROCESS":
            # Update state
            self.state["processed_count"] += 1
            self.state["last_processed_time"] = time.time()

            try:
                # Process the message
                result = await self.process(message.data)
                return Response(type="PROCESS_COMPLETE", data=result)
            except Exception as e:
                # Update error count
                self.state["error_count"] += 1
                return ErrorResponse(f"Error processing message: {str(e)}")
```

## Conclusion

The actor hierarchy in Choir provides a structured approach to organizing the system's components. By understanding this hierarchy, developers can more easily navigate the codebase, understand component relationships, and implement new actors that integrate seamlessly with the existing system.

For more detailed information on implementing actors, refer to the [Actor Implementation Guide](../3-implementation/actor_implementation_guide.md).
