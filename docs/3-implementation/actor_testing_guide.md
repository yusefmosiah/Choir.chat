# Actor Testing Guide

This guide provides comprehensive strategies, patterns, and best practices for testing actor-based systems in Choir. It covers unit testing, integration testing, and end-to-end testing approaches specifically tailored for the actor model.

## Table of Contents

1. [Introduction](#introduction)
2. [Testing Challenges in Actor Systems](#testing-challenges-in-actor-systems)
3. [Testing Pyramid for Actor Systems](#testing-pyramid-for-actor-systems)
4. [Unit Testing Actors](#unit-testing-actors)
5. [Integration Testing Actor Systems](#integration-testing-actor-systems)
6. [End-to-End Testing](#end-to-end-testing)
7. [Testing Tools and Frameworks](#testing-tools-and-frameworks)
8. [Test Patterns and Best Practices](#test-patterns-and-best-practices)
9. [Performance Testing](#performance-testing)
10. [Debugging Tests](#debugging-tests)

## Introduction

Testing actor-based systems presents unique challenges due to their concurrent, message-passing nature. This guide outlines approaches to effectively test Choir's actor architecture at various levels, from individual actors to complete workflows.

The key principles for testing actor systems include:

1. **Isolation**: Test actors in isolation before testing interactions
2. **Message-based verification**: Focus on input/output messages rather than internal state
3. **Deterministic testing**: Create reproducible tests despite concurrent execution
4. **Supervision testing**: Verify error handling and supervision strategies
5. **State persistence testing**: Ensure state is correctly saved and recovered

## Testing Challenges in Actor Systems

Actor systems introduce several testing challenges:

### Concurrency and Non-determinism

Actors operate concurrently, which can lead to non-deterministic behavior in tests. Messages may be processed in different orders across test runs, making it difficult to create reproducible tests.

### Message-Passing Complexity

Testing interactions between actors requires capturing, verifying, and sometimes mocking message exchanges, which adds complexity compared to testing direct method calls.

### State Encapsulation

Actors encapsulate their state, making it challenging to verify internal state changes without breaking encapsulation.

### Supervision Hierarchies

Testing supervision strategies and error handling requires simulating failures and verifying recovery behavior.

### Distributed Nature

In distributed actor systems, network partitions and latency add additional testing complexity.

## Testing Pyramid for Actor Systems

The testing pyramid for actor systems follows this structure:

```
    /\
   /  \
  /    \      E2E Tests
 /      \     (Complete PostChain Workflows)
/--------\
/        \    Integration Tests
/          \   (Actor Interactions)
/------------\
/              \  Unit Tests
/                \ (Individual Actors)
------------------
```

### Unit Tests (Base Layer)

- Test individual actors in isolation
- Mock message responses from other actors
- Focus on message handling logic
- Verify correct state transitions

### Integration Tests (Middle Layer)

- Test interactions between small groups of actors
- Verify message flows between actors
- Test supervision strategies
- Focus on actor subsystems (e.g., a Phase Actor and its Agent Manager)

### End-to-End Tests (Top Layer)

- Test complete workflows through the PostChain
- Verify system behavior from external API perspective
- Test thread lifecycle from creation to completion
- Focus on business requirements rather than implementation details

## Unit Testing Actors

Unit testing focuses on testing individual actors in isolation.

### Actor Test Harness

Create a test harness that allows sending messages to an actor and capturing responses:

```python
class ActorTestHarness:
    """Test harness for testing individual actors"""

    def __init__(self, actor_class, initial_state=None):
        """Initialize the test harness with the actor class to test"""
        self.actor = actor_class(initial_state)
        self.sent_messages = []
        self.received_messages = []

    async def send_message(self, message):
        """Send a message to the actor and capture the response"""
        self.sent_messages.append(message)
        response = await self.actor.receive(message)
        self.received_messages.append(response)
        return response

    def verify_message_sent(self, message_type, data=None):
        """Verify that a message of the specified type was sent"""
        for message in self.sent_messages:
            if message.type == message_type:
                if data is None or all(message.data.get(k) == v for k, v in data.items()):
                    return True
        return False

    def verify_response_received(self, response_type, data=None):
        """Verify that a response of the specified type was received"""
        for response in self.received_messages:
            if response.type == response_type:
                if data is None or all(response.data.get(k) == v for k, v in data.items()):
                    return True
        return False
```

### Example Unit Test

```python
import pytest
from choir.actors.phase_actors import ActionPhaseActor
from choir.messages import Message

@pytest.mark.asyncio
async def test_action_phase_actor_processes_message():
    # Arrange
    harness = ActorTestHarness(ActionPhaseActor)

    # Create a test message
    message = Message(
        type="PROCESS_PHASE",
        data={
            "thread_id": "test_thread_123",
            "phase_type": "action",
            "input": "Hello, world!",
            "context": {
                "conversation_history": []
            }
        }
    )

    # Act
    response = await harness.send_message(message)

    # Assert
    assert response.type == "PHASE_PROCESSED"
    assert "output" in response.data
    assert response.data["thread_id"] == "test_thread_123"
    assert response.data["phase_type"] == "action"
```

### Testing State Changes

To test state changes without breaking encapsulation, use the actor's state persistence mechanism:

```python
@pytest.mark.asyncio
async def test_actor_state_changes():
    # Arrange
    initial_state = ActorState(counter=0)
    harness = ActorTestHarness(CounterActor, initial_state)

    # Create a test message
    message = Message(
        type="INCREMENT_COUNTER",
        data={"amount": 5}
    )

    # Act
    response = await harness.send_message(message)

    # Get the actor's state through its persistence mechanism
    saved_state = await harness.actor.save_state()

    # Assert
    assert saved_state.counter == 5
    assert response.type == "COUNTER_INCREMENTED"
    assert response.data["new_value"] == 5
```

## Integration Testing Actor Systems

Integration testing focuses on testing interactions between actors.

### Actor System Test Harness

Create a test harness for testing actor subsystems:

```python
class ActorSystemTestHarness:
    """Test harness for testing actor subsystems"""

    def __init__(self):
        """Initialize the test harness with a test actor system"""
        self.actor_system = TestActorSystem()
        self.actors = {}
        self.messages = []

    async def create_actor(self, actor_id, actor_class, initial_state=None):
        """Create an actor in the test system"""
        actor = await self.actor_system.create_actor(
            actor_id, actor_class, initial_state
        )
        self.actors[actor_id] = actor
        return actor

    async def send_message(self, sender_id, recipient_id, message):
        """Send a message between actors and track it"""
        message.sender = sender_id
        message.receiver = recipient_id
        self.messages.append(message)
        return await self.actor_system.send_message(message)

    async def shutdown(self):
        """Shutdown the test actor system"""
        await self.actor_system.shutdown()
```

### Example Integration Test

```python
@pytest.mark.asyncio
async def test_thread_actor_phase_interaction():
    # Arrange
    harness = ActorSystemTestHarness()

    # Create the actors
    await harness.create_actor("thread_actor", ThreadActor)
    await harness.create_actor("action_phase", ActionPhaseActor)

    # Create a test message to start a thread
    start_message = Message(
        type="START_THREAD",
        data={
            "thread_id": "test_thread_123",
            "input": "Hello, world!"
        }
    )

    # Act
    response = await harness.send_message("test_client", "thread_actor", start_message)

    # Assert
    assert response.type == "THREAD_STARTED"

    # Verify that the thread actor sent a message to the action phase actor
    process_phase_message = next(
        (m for m in harness.messages if m.type == "PROCESS_PHASE" and
         m.sender == "thread_actor" and m.receiver == "action_phase"),
        None
    )
    assert process_phase_message is not None
    assert process_phase_message.data["phase_type"] == "action"

    # Clean up
    await harness.shutdown()
```

### Testing Supervision Strategies

Test how actors handle errors and supervision:

```python
@pytest.mark.asyncio
async def test_supervisor_restarts_failed_actor():
    # Arrange
    harness = ActorSystemTestHarness()

    # Create the actors
    await harness.create_actor("supervisor", SupervisorActor)
    await harness.create_actor("worker", WorkerActor)

    # Create a message that will cause the worker to fail
    fail_message = Message(
        type="TRIGGER_FAILURE",
        data={}
    )

    # Act
    await harness.send_message("test_client", "worker", fail_message)

    # Wait for supervision to occur
    await asyncio.sleep(0.1)

    # Assert
    # Verify that the supervisor sent a restart message
    restart_message = next(
        (m for m in harness.messages if m.type == "RESTART" and
         m.sender == "supervisor" and m.receiver == "worker"),
        None
    )
    assert restart_message is not None

    # Clean up
    await harness.shutdown()
```

## End-to-End Testing

End-to-end testing verifies complete workflows through the system.

### Example End-to-End Test

```python
@pytest.mark.asyncio
async def test_complete_postchain_workflow():
    # Arrange
    # Start a complete actor system
    actor_system = create_production_actor_system()

    # Create a test client
    client = TestClient(actor_system)

    # Act
    # Create and start a thread
    thread_id = await client.create_thread("What is the capital of France?")
    thread_result = await client.wait_for_thread_completion(thread_id)

    # Assert
    # Verify the final response
    assert "Paris" in thread_result.response

    # Verify that all phases were executed
    thread_status = await client.get_thread_status(thread_id)
    assert set(thread_status.phases_completed) == {
        "action", "experience", "intention", "observation", "understanding", "yield"
    }

    # Clean up
    await actor_system.shutdown()
```

## Testing Tools and Frameworks

### Recommended Testing Tools

1. **pytest**: Primary testing framework
2. **pytest-asyncio**: For testing async code
3. **pytest-mock**: For mocking dependencies
4. **pytest-cov**: For measuring test coverage

### Actor-Specific Testing Tools

1. **TestActorSystem**: A simplified actor system for testing
2. **MessageCaptor**: Captures messages between actors
3. **ActorStateSpy**: Allows inspecting actor state for testing
4. **FakeTimeProvider**: Controls time progression in tests

## Test Patterns and Best Practices

### Deterministic Testing

Make tests deterministic despite concurrency:

1. Use controlled message delivery in tests
2. Implement a test-specific scheduler
3. Use synchronous execution mode for tests

```python
class TestActorSystem(ActorSystem):
    """Actor system with deterministic message delivery for testing"""

    def __init__(self):
        super().__init__()
        self.message_queue = []
        self.synchronous_mode = True

    async def send_message(self, message):
        """Send a message with deterministic delivery"""
        self.message_queue.append(message)
        if self.synchronous_mode:
            return await self._process_next_message()
        return None

    async def _process_next_message(self):
        """Process the next message in the queue"""
        if not self.message_queue:
            return None

        message = self.message_queue.pop(0)
        target_actor = self.actors.get(message.receiver)
        if not target_actor:
            raise ValueError(f"Actor not found: {message.receiver}")

        return await target_actor.receive(message)
```

### Test Doubles for Actors

Create test doubles for actors:

1. **Stub Actors**: Return predefined responses
2. **Mock Actors**: Verify message interactions
3. **Fake Actors**: Simplified implementations for testing

```python
class StubActor:
    """Stub actor that returns predefined responses"""

    def __init__(self, responses=None):
        self.responses = responses or {}
        self.received_messages = []

    async def receive(self, message):
        """Return a predefined response based on message type"""
        self.received_messages.append(message)

        # Get the response for this message type
        response_factory = self.responses.get(message.type)
        if response_factory:
            if callable(response_factory):
                return response_factory(message)
            return response_factory

        # Default response
        return Response(
            type=f"{message.type}_RESPONSE",
            data={},
            message_id=message.id
        )
```

### Testing State Persistence

Test state persistence and recovery:

```python
@pytest.mark.asyncio
async def test_actor_state_persistence_and_recovery():
    # Arrange
    # Create an actor with initial state
    initial_state = ThreadActorState(
        thread_id="test_thread_123",
        status="processing",
        current_phase="action"
    )

    storage = InMemoryStateStorage()
    actor = ThreadActor(initial_state, storage)

    # Act
    # Save the actor's state
    await actor.save_state()

    # Create a new actor and load the state
    new_actor = ThreadActor(None, storage)
    await new_actor.load_state("test_thread_123")

    # Assert
    # Verify the state was correctly loaded
    assert new_actor.state.thread_id == "test_thread_123"
    assert new_actor.state.status == "processing"
    assert new_actor.state.current_phase == "action"
```

## Performance Testing

Performance testing focuses on measuring and optimizing actor system performance.

### Throughput Testing

Measure message throughput:

```python
@pytest.mark.performance
async def test_actor_throughput():
    # Arrange
    actor = EchoActor()
    message = Message(type="ECHO", data={"content": "Hello"})

    # Act
    start_time = time.time()
    message_count = 10000

    for _ in range(message_count):
        await actor.receive(message)

    end_time = time.time()
    duration = end_time - start_time

    # Assert
    messages_per_second = message_count / duration
    print(f"Throughput: {messages_per_second:.2f} messages/second")

    # Ensure minimum throughput
    assert messages_per_second > 5000
```

### Latency Testing

Measure message processing latency:

```python
@pytest.mark.performance
async def test_actor_latency():
    # Arrange
    actor = ProcessingActor()
    message = Message(type="PROCESS", data={"content": "Test content"})

    # Act
    latencies = []
    for _ in range(100):
        start_time = time.time()
        await actor.receive(message)
        end_time = time.time()
        latencies.append((end_time - start_time) * 1000)  # Convert to ms

    # Assert
    avg_latency = sum(latencies) / len(latencies)
    p95_latency = sorted(latencies)[int(len(latencies) * 0.95)]

    print(f"Average latency: {avg_latency:.2f} ms")
    print(f"P95 latency: {p95_latency:.2f} ms")

    # Ensure maximum latency
    assert avg_latency < 10  # ms
    assert p95_latency < 20  # ms
```

### Load Testing

Test system behavior under load:

```python
@pytest.mark.performance
async def test_actor_system_under_load():
    # Arrange
    actor_system = create_production_actor_system()
    client = TestClient(actor_system)

    # Act
    # Create multiple concurrent threads
    thread_count = 50
    thread_ids = []

    start_time = time.time()

    for i in range(thread_count):
        thread_id = await client.create_thread(f"Test query {i}")
        thread_ids.append(thread_id)

    # Wait for all threads to complete
    results = await asyncio.gather(*[
        client.wait_for_thread_completion(thread_id)
        for thread_id in thread_ids
    ])

    end_time = time.time()
    duration = end_time - start_time

    # Assert
    # Verify all threads completed successfully
    assert all(result.status == "completed" for result in results)

    # Calculate throughput
    threads_per_second = thread_count / duration
    print(f"System throughput: {threads_per_second:.2f} threads/second")

    # Ensure minimum throughput
    assert threads_per_second > 5

    # Clean up
    await actor_system.shutdown()
```

## Debugging Tests

Strategies for debugging actor tests:

1. **Enable verbose logging**: Set logging level to DEBUG for tests
2. **Message tracing**: Log all messages between actors
3. **State snapshots**: Capture actor state at key points
4. **Visual message flow**: Generate sequence diagrams from test runs

```python
@pytest.fixture
def enable_debug_logging():
    """Enable debug logging for tests"""
    original_level = logging.getLogger("choir").level
    logging.getLogger("choir").setLevel(logging.DEBUG)
    yield
    logging.getLogger("choir").setLevel(original_level)

@pytest.mark.asyncio
async def test_with_debug_logging(enable_debug_logging):
    # Test with debug logging enabled
    # ...
```

### Message Tracing

Implement message tracing for tests:

```python
class MessageTracer:
    """Traces messages between actors for debugging"""

    def __init__(self):
        self.messages = []

    def trace_message(self, message, direction, actor_id):
        """Record a message trace"""
        self.messages.append({
            "timestamp": time.time(),
            "direction": direction,  # "sent" or "received"
            "actor_id": actor_id,
            "message_id": message.id,
            "message_type": message.type,
            "data": message.data
        })

    def generate_sequence_diagram(self):
        """Generate a sequence diagram from traced messages"""
        # Implementation to generate a sequence diagram
        # ...
```

## Conclusion

Testing actor-based systems requires specialized approaches that focus on message passing, concurrency, and state management. By following the patterns and practices in this guide, you can create robust, maintainable tests for Choir's actor architecture.

Remember these key principles:

1. Test actors in isolation before testing interactions
2. Focus on message-based verification rather than internal state
3. Create deterministic tests despite concurrent execution
4. Test supervision strategies and error handling
5. Verify state persistence and recovery

For more detailed examples, refer to the test suite in the `tests/actors` directory.
