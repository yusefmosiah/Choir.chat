# Testing Strategy

This guide outlines the testing strategy for Choir's actor-based architecture, covering unit testing, integration testing, and end-to-end testing approaches.

## Table of Contents

1. [Introduction](#introduction)
2. [Testing Principles](#testing-principles)
3. [Test Types](#test-types)
4. [Actor Testing](#actor-testing)
5. [Message Testing](#message-testing)
6. [State Testing](#state-testing)
7. [Integration Testing](#integration-testing)
8. [End-to-End Testing](#end-to-end-testing)
9. [Test Environment](#test-environment)
10. [Continuous Integration](#continuous-integration)

## Introduction

Testing an actor-based system presents unique challenges due to its distributed nature, message-passing architecture, and state encapsulation. This guide provides strategies for effectively testing Choir's actor-based architecture at various levels, from individual actors to the entire system.

## Testing Principles

The testing strategy for Choir's actor-based architecture is guided by the following principles:

1. **Isolation**: Test actors in isolation to ensure they behave correctly independently.
2. **Message-Based Testing**: Focus on testing the behavior of actors in response to messages.
3. **State Verification**: Verify that actor state changes correctly in response to messages.
4. **Integration Testing**: Test interactions between actors to ensure they work together correctly.
5. **End-to-End Testing**: Test complete workflows to ensure the system behaves correctly as a whole.
6. **Determinism**: Tests should be deterministic and repeatable.
7. **Mocking External Dependencies**: Use mocks for external dependencies to ensure tests are isolated.

## Test Types

### Unit Tests

Unit tests focus on testing individual components in isolation:

- Individual actors
- Message handlers
- State management functions
- Utility functions

### Integration Tests

Integration tests focus on testing interactions between components:

- Actor-to-actor communication
- Actor-to-database interactions
- Actor-to-blockchain interactions

### End-to-End Tests

End-to-End tests focus on testing complete workflows:

- PostChain (AEIOU-Y) cycle
- User interactions
- External system integrations

## Actor Testing

### Testing Actor Creation

```python
def test_actor_creation():
    # Create an actor
    actor = MyActor("test_actor")

    # Verify actor properties
    assert actor.id == "test_actor"
    assert actor.state == {}
```

### Testing Actor Message Handling

```python
async def test_actor_message_handling():
    # Create an actor
    actor = MyActor("test_actor")

    # Send a message to the actor
    response = await actor.receive(
        Message(type="TEST_MESSAGE", data={"key": "value"})
    )

    # Verify the response
    assert response.type == "SUCCESS"
    assert response.data["result"] == "expected_value"

    # Verify state changes
    assert actor.state["processed_messages"] == 1
```

### Testing Actor Error Handling

```python
async def test_actor_error_handling():
    # Create an actor
    actor = MyActor("test_actor")

    # Send an invalid message to the actor
    response = await actor.receive(
        Message(type="INVALID_MESSAGE", data={})
    )

    # Verify the error response
    assert response.type == "ERROR"
    assert "Unknown message type" in response.data["error"]
```

## Message Testing

### Testing Message Creation

```python
def test_message_creation():
    # Create a message
    message = Message(type="TEST_MESSAGE", data={"key": "value"})

    # Verify message properties
    assert message.type == "TEST_MESSAGE"
    assert message.data["key"] == "value"
```

### Testing Message Validation

```python
def test_message_validation():
    # Create a valid message
    valid_message = Message(type="TEST_MESSAGE", data={"required_field": "value"})

    # Validate the message
    validation_result = validate_message(valid_message, TEST_MESSAGE_SCHEMA)
    assert validation_result.is_valid

    # Create an invalid message
    invalid_message = Message(type="TEST_MESSAGE", data={})

    # Validate the message
    validation_result = validate_message(invalid_message, TEST_MESSAGE_SCHEMA)
    assert not validation_result.is_valid
    assert "required_field is required" in validation_result.errors
```

### Testing Message Serialization

```python
def test_message_serialization():
    # Create a message
    message = Message(type="TEST_MESSAGE", data={"key": "value"})

    # Serialize the message
    serialized = message.serialize()

    # Deserialize the message
    deserialized = Message.deserialize(serialized)

    # Verify the deserialized message
    assert deserialized.type == message.type
    assert deserialized.data == message.data
```

## State Testing

### Testing State Initialization

```python
def test_state_initialization():
    # Create an actor with initial state
    actor = MyActor("test_actor", initial_state={"counter": 0})

    # Verify the initial state
    assert actor.state["counter"] == 0
```

### Testing State Updates

```python
async def test_state_updates():
    # Create an actor
    actor = MyActor("test_actor")

    # Send a message that updates state
    await actor.receive(
        Message(type="INCREMENT_COUNTER", data={})
    )

    # Verify the state update
    assert actor.state["counter"] == 1

    # Send another message that updates state
    await actor.receive(
        Message(type="INCREMENT_COUNTER", data={})
    )

    # Verify the state update
    assert actor.state["counter"] == 2
```

### Testing State Persistence

```python
async def test_state_persistence():
    # Create an actor
    actor = MyActor("test_actor")

    # Update the actor's state
    actor.state["counter"] = 42

    # Persist the state
    await actor.persist_state()

    # Create a new actor with the same ID
    new_actor = MyActor("test_actor")

    # Load the state
    await new_actor.load_state()

    # Verify the state was loaded
    assert new_actor.state["counter"] == 42
```

## Integration Testing

### Testing Actor-to-Actor Communication

```python
async def test_actor_communication():
    # Create the actor system
    actor_system = ActorSystem()

    # Create actors
    actor_a = ActorA("actor_a")
    actor_b = ActorB("actor_b")

    # Register actors with the system
    actor_system.register(actor_a)
    actor_system.register(actor_b)

    # Send a message from actor_a to actor_b
    response = await actor_a.send(
        actor_b.id,
        Message(type="GREET", data={"greeting": "Hello"})
    )

    # Verify the response
    assert response.type == "GREETING_RECEIVED"
    assert response.data["reply"] == "Hello to you too!"
```

### Testing Actor-to-Database Interaction

```python
async def test_actor_database_interaction():
    # Create a mock database
    mock_db = MockDatabase()

    # Create an actor with the mock database
    actor = DatabaseActor("db_actor", db=mock_db)

    # Send a message to store data
    response = await actor.receive(
        Message(type="STORE", data={"key": "test_key", "value": "test_value"})
    )

    # Verify the response
    assert response.type == "STORE_COMPLETE"

    # Verify the data was stored
    assert mock_db.get("test_key") == "test_value"
```

### Testing Actor-to-Blockchain Interaction

```python
async def test_actor_blockchain_interaction():
    # Create a mock blockchain client
    mock_blockchain = MockBlockchain()

    # Create an actor with the mock blockchain
    actor = BlockchainActor("blockchain_actor", blockchain=mock_blockchain)

    # Send a message to query the blockchain
    response = await actor.receive(
        Message(type="QUERY_BALANCE", data={"address": "0x123"})
    )

    # Verify the response
    assert response.type == "BALANCE_RESULT"
    assert response.data["balance"] == 100
```

## End-to-End Testing

### Testing PostChain Cycle

```python
async def test_post_chain_cycle():
    # Create the PostChain
    post_chain = PostChain()

    # Process user input through the PostChain
    result = await post_chain.process("Hello, world!")

    # Verify the result
    assert "response" in result
    assert result["response"] != ""

    # Verify each phase was executed
    assert "action_phase" in result["phases"]
    assert "experience_phase" in result["phases"]
    assert "intention_phase" in result["phases"]
    assert "observation_phase" in result["phases"]
    assert "understanding_phase" in result["phases"]
    assert "yield_phase" in result["phases"]
```

### Testing User Interactions

```python
async def test_user_interaction():
    # Create the user interaction handler
    handler = UserInteractionHandler()

    # Process a user message
    response = await handler.process_message(
        user_id="user123",
        message="Hello, Choir!"
    )

    # Verify the response
    assert response["status"] == "success"
    assert "message" in response
    assert response["message"] != ""
```

## Test Environment

### Local Test Environment

For local development and testing:

1. Use in-memory databases for state persistence
2. Use mock blockchain clients
3. Use mock external services

```python
@pytest.fixture
def test_environment():
    # Create in-memory database
    db = InMemoryDatabase()

    # Create mock blockchain
    blockchain = MockBlockchain()

    # Create mock external services
    external_services = MockExternalServices()

    # Create the test environment
    env = TestEnvironment(
        db=db,
        blockchain=blockchain,
        external_services=external_services
    )

    return env
```

### Containerized Test Environment

For more realistic testing:

1. Use Docker Compose to create a containerized test environment
2. Use real databases with test data
3. Use blockchain test networks
4. Use mock external services

```yaml
# docker-compose.test.yml
version: "3"
services:
  db:
    image: turso/libsql
    ports:
      - "8080:8080"
    volumes:
      - ./test_data:/data

  blockchain:
    image: sui/sui-node
    ports:
      - "9000:9000"
    command: ["--test-mode"]

  test:
    build:
      context: .
      dockerfile: Dockerfile.test
    depends_on:
      - db
      - blockchain
    environment:
      - DB_URL=http://db:8080
      - BLOCKCHAIN_URL=http://blockchain:9000
```

## Continuous Integration

### CI Pipeline

The CI pipeline for testing the actor-based architecture includes:

1. **Linting**: Check code style and quality
2. **Unit Tests**: Run unit tests for individual components
3. **Integration Tests**: Run integration tests for component interactions
4. **End-to-End Tests**: Run end-to-end tests for complete workflows
5. **Coverage Analysis**: Analyze test coverage
6. **Performance Tests**: Run performance tests for critical paths

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: "3.10"
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      - name: Lint
        run: |
          flake8 .
          black --check .
      - name: Unit tests
        run: |
          pytest tests/unit
      - name: Integration tests
        run: |
          pytest tests/integration
      - name: End-to-end tests
        run: |
          pytest tests/e2e
      - name: Coverage analysis
        run: |
          pytest --cov=. --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v1
```

### Test Reporting

Generate test reports to track test results over time:

1. **Test Results**: JUnit XML reports
2. **Coverage Reports**: Coverage XML reports
3. **Performance Reports**: Performance test reports

```python
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --junitxml=reports/junit.xml --cov=. --cov-report=xml:reports/coverage.xml
```

## Conclusion

This testing strategy provides a comprehensive approach to testing Choir's actor-based architecture. By following these guidelines, you can ensure that the system behaves correctly at all levels, from individual actors to the entire system.

For more detailed information, refer to:

- [Actor Model Overview](../1-concepts/actor_model_overview.md)
- [Message Protocol Reference](../3-implementation/message_protocol_reference.md)
- [State Management Patterns](../3-implementation/state_management_patterns.md)
- [Deployment Guide](deployment_guide.md)
