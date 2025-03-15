# Actor Implementation Guide

This guide provides a step-by-step approach to implementing new actors in Choir's actor-based architecture. It covers patterns, best practices, and common pitfalls when working with the actor model.

## Table of Contents

1. [Introduction](#introduction)
2. [Actor Basics](#actor-basics)
3. [Actor Types](#actor-types)
4. [Implementation Patterns](#implementation-patterns)
5. [Testing Actors](#testing-actors)
6. [Common Pitfalls](#common-pitfalls)
7. [Advanced Patterns](#advanced-patterns)
8. [Examples](#examples)

## Introduction

The actor model provides a powerful abstraction for building concurrent, distributed systems. In Choir, actors are the fundamental building blocks of the PostChain architecture, replacing the previous graph-based approach.

This guide will help you understand how to implement actors that integrate seamlessly with the rest of the system.

## Actor Basics

### Actor Structure

Every actor in Choir follows a common structure:

```python
class MyActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = {}  # Actor-specific state

    async def receive(self, message):
        # Message handling logic
        if message.type == "SOME_MESSAGE_TYPE":
            # Process message
            return Response(...)
        else:
            # Handle unknown message type
            return ErrorResponse("Unknown message type")
```

### Message Handling

Actors communicate exclusively through messages. The `receive` method is the entry point for all message processing:

1. Determine the message type
2. Process the message based on its type
3. Update internal state if necessary
4. Return a response message

### State Management

Actors maintain their own state, which should be:

- Encapsulated within the actor
- Modified only by the actor itself
- Persisted when necessary using the state management patterns

## Actor Types

Choir's architecture includes several specialized actor types:

### 1. Phase Actors

Phase actors implement specific phases of the PostChain (AEIOU-Y) cycle:

- Action Phase Actor
- Experience Phase Actor
- Intention Phase Actor
- Observation Phase Actor
- Understanding Phase Actor
- Yield Phase Actor

### 2. Worker Pool Actors

Worker pool actors manage pools of workers for specific tasks:

- Model Worker Pool Actor
- Vector Database Worker Pool Actor
- Storage Worker Pool Actor

### 3. Service Actors

Service actors provide system-wide services:

- Authentication Actor
- Persistence Actor
- Logging Actor
- Metrics Actor

## Implementation Patterns

### Pattern 1: Message Type Dispatch

Use a dispatch pattern to handle different message types:

```python
async def receive(self, message):
    handlers = {
        "TYPE_A": self._handle_type_a,
        "TYPE_B": self._handle_type_b,
        # ...
    }

    handler = handlers.get(message.type)
    if handler:
        return await handler(message)
    else:
        return ErrorResponse(f"Unknown message type: {message.type}")
```

### Pattern 2: State Persistence

For actors that need to persist state:

```python
async def _persist_state(self):
    # Use the persistence service to store state
    persistence_actor = await self.get_actor("persistence")
    await persistence_actor.send(
        PersistenceMessage(
            type="STORE",
            actor_id=self.id,
            state=self.state
        )
    )
```

### Pattern 3: Actor Supervision

For actors that manage other actors:

```python
async def _create_child_actors(self):
    # Create and supervise child actors
    child_ids = []
    for i in range(5):
        child = await self.create_actor(
            "child_actor_type",
            f"{self.id}_child_{i}"
        )
        child_ids.append(child.id)

    self.state["child_ids"] = child_ids
```

## Testing Actors

### Unit Testing Actors

```python
async def test_my_actor():
    # Create the actor
    actor = MyActor("test_actor")

    # Send a test message
    response = await actor.receive(
        Message(type="TEST_MESSAGE", data={"key": "value"})
    )

    # Assert on the response
    assert response.type == "SUCCESS"
    assert response.data["result"] == "expected_value"
```

### Integration Testing with Multiple Actors

```python
async def test_actor_interaction():
    # Create actors
    actor_a = ActorA("actor_a")
    actor_b = ActorB("actor_b")

    # Register actors with each other
    actor_system.register(actor_a)
    actor_system.register(actor_b)

    # Test interaction
    response = await actor_a.send(
        actor_b.id,
        Message(type="INTERACT", data={})
    )

    # Assert on the response
    assert response.type == "INTERACTION_COMPLETE"
```

## Common Pitfalls

### 1. Shared Mutable State

**Problem**: Sharing mutable state between actors breaks the actor model's isolation.

**Solution**: Pass immutable messages between actors instead of sharing state.

### 2. Blocking Operations

**Problem**: Blocking operations in the `receive` method block the entire actor.

**Solution**: Use asynchronous operations and `await` for I/O-bound tasks.

### 3. Message Cycles

**Problem**: Actors sending messages in a cycle can create infinite loops.

**Solution**: Implement message tracking and cycle detection.

### 4. State Explosion

**Problem**: Actors accumulating state indefinitely.

**Solution**: Implement state pruning and archiving strategies.

## Advanced Patterns

### Pattern 1: Actor Pipelines

Chain actors together to form processing pipelines:

```python
async def process_pipeline(input_data):
    # Create pipeline actors
    stage1 = Stage1Actor("stage1")
    stage2 = Stage2Actor("stage2")
    stage3 = Stage3Actor("stage3")

    # Process through pipeline
    result1 = await stage1.receive(Message(type="PROCESS", data=input_data))
    result2 = await stage2.receive(Message(type="PROCESS", data=result1.data))
    result3 = await stage3.receive(Message(type="PROCESS", data=result2.data))

    return result3
```

### Pattern 2: Actor Pools

Create pools of actors for parallel processing:

```python
class WorkerPoolActor(Actor):
    async def initialize(self, worker_count=5):
        self.workers = []
        for i in range(worker_count):
            worker = await self.create_actor(
                "worker_type",
                f"{self.id}_worker_{i}"
            )
            self.workers.append(worker)

    async def receive(self, message):
        if message.type == "PROCESS_BATCH":
            # Distribute work among workers
            tasks = []
            for i, item in enumerate(message.data["items"]):
                worker_idx = i % len(self.workers)
                tasks.append(
                    self.workers[worker_idx].receive(
                        Message(type="PROCESS_ITEM", data={"item": item})
                    )
                )

            # Collect results
            results = await asyncio.gather(*tasks)
            return Response(type="BATCH_COMPLETE", data={"results": results})
```

## Examples

### Example 1: Phase Actor Implementation

```python
class ActionPhaseActor(Actor):
    async def receive(self, message):
        if message.type == "PROCESS_INPUT":
            user_input = message.data["input"]

            # Process the input
            processed_input = self._process_input(user_input)

            # Return the processed input
            return Response(
                type="ACTION_COMPLETE",
                data={"processed_input": processed_input}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    def _process_input(self, user_input):
        # Implementation-specific processing
        return {"processed": user_input}
```

### Example 2: Service Actor Implementation

```python
class PersistenceActor(Actor):
    async def initialize(self):
        # Connect to database
        self.db_connection = await self._connect_to_db()

    async def receive(self, message):
        if message.type == "STORE":
            # Store data
            actor_id = message.data["actor_id"]
            state = message.data["state"]

            await self._store_state(actor_id, state)

            return Response(type="STORE_COMPLETE")
        elif message.type == "RETRIEVE":
            # Retrieve data
            actor_id = message.data["actor_id"]

            state = await self._retrieve_state(actor_id)

            return Response(
                type="RETRIEVE_COMPLETE",
                data={"state": state}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    async def _connect_to_db(self):
        # Implementation-specific database connection
        pass

    async def _store_state(self, actor_id, state):
        # Implementation-specific state storage
        pass

    async def _retrieve_state(self, actor_id):
        # Implementation-specific state retrieval
        pass
```

## Conclusion

This guide provides a foundation for implementing actors in Choir's architecture. By following these patterns and best practices, you can create actors that integrate seamlessly with the system and take full advantage of the actor model's benefits.

For more detailed information, refer to:

- [Actor Model Overview](../1-concepts/actor_model_overview.md)
- [Message Protocol Reference](message_protocol_reference.md)
- [State Management Patterns](state_management_patterns.md)
