# Message Flow Diagrams

This document provides visual representations of the message flows between actors in Choir's actor-based architecture. These diagrams illustrate how actors communicate, the types of messages they exchange, and the sequence of operations in various workflows.

## Table of Contents

1. [Introduction](#introduction)
2. [Message Protocol Overview](#message-protocol-overview)
3. [Basic Message Structure](#basic-message-structure)
4. [PostChain Message Flow](#postchain-message-flow)
5. [System Management Message Flow](#system-management-message-flow)
6. [Data Persistence Message Flow](#data-persistence-message-flow)
7. [Error Handling Message Flow](#error-handling-message-flow)
8. [Integration Message Flows](#integration-message-flows)
9. [Implementation Considerations](#implementation-considerations)

## Introduction

In Choir's actor-based architecture, actors communicate exclusively through message passing. Understanding these message flows is crucial for developers working with the system. This document provides visual representations of the most important message flows in the system.

The diagrams in this document follow these conventions:

- Actors are represented as rectangles
- Messages are represented as arrows between actors
- Message types are labeled on the arrows
- Sequence flows from top to bottom or left to right
- Asynchronous operations are indicated with dashed lines
- Error paths are shown in red

## Message Protocol Overview

All messages in Choir follow a consistent protocol:

```python
class Message:
    def __init__(self, type, data=None, sender=None, receiver=None, id=None):
        self.type = type  # String identifying the message type
        self.data = data or {}  # Dictionary containing message data
        self.sender = sender  # ID of the sending actor
        self.receiver = receiver  # ID of the receiving actor
        self.id = id or str(uuid.uuid4())  # Unique message ID
```

Responses follow a similar structure:

```python
class Response:
    def __init__(self, type, data=None, message_id=None, id=None):
        self.type = type  # String identifying the response type
        self.data = data or {}  # Dictionary containing response data
        self.message_id = message_id  # ID of the message being responded to
        self.id = id or str(uuid.uuid4())  # Unique response ID
```

Error responses are a special type of response:

```python
class ErrorResponse(Response):
    def __init__(self, error_message, error_code=None, message_id=None, id=None):
        super().__init__(
            type="ERROR",
            data={
                "error_message": error_message,
                "error_code": error_code
            },
            message_id=message_id,
            id=id
        )
```

## Basic Message Structure

The following diagram illustrates the basic structure of a message exchange between two actors:

```
┌─────────┐                                  ┌─────────┐
│ Actor A │                                  │ Actor B │
└────┬────┘                                  └────┬────┘
     │                                            │
     │ Message(type="ACTION", data={"key": "value"})
     │ ─────────────────────────────────────────> │
     │                                            │
     │                                            │ Process
     │                                            │ message
     │                                            │
     │ Response(type="ACTION_COMPLETE", data={"result": "success"})
     │ <───────────────────────────────────────── │
     │                                            │
┌────┴────┐                                  ┌────┴────┐
│ Actor A │                                  │ Actor B │
└─────────┘                                  └─────────┘
```

## PostChain Message Flow

The PostChain is Choir's core processing pipeline, implementing the AEIOU-Y framework through a series of actors. The following diagram illustrates the message flow through the PostChain:

```
┌─────────┐     ┌───────────┐     ┌───────────┐     ┌────────────┐     ┌─────────────┐     ┌──────────┐
│ActionActor│     │ExperienceActor│     │IntentionActor│     │ObservationActor│     │UnderstandingActor│     │YieldActor│
└─────┬─────┘     └─────┬─────┘     └─────┬─────┘     └──────┬─────┘     └──────┬──────┘     └────┬─────┘
      │                 │                 │                  │                  │                 │
      │ PROCESS_INPUT   │                 │                  │                  │                 │
      │ ────────────►   │                 │                  │                  │                 │
      │                 │                 │                  │                  │                 │
      │ ACTION_COMPLETE │                 │                  │                  │                 │
      │ ◄────────────   │                 │                  │                  │                 │
      │                 │                 │                  │                  │                 │
      │ PROCESS_ACTION  │                 │                  │                  │                 │
      │ ─────────────────────────────►    │                  │                  │                 │
      │                 │                 │                  │                  │                 │
      │                 │ EXPERIENCE_COMPLETE                │                  │                 │
      │                 │ ◄─────────────  │                  │                  │                 │
      │                 │                 │                  │                  │                 │
      │                 │ PROCESS_EXPERIENCE                 │                  │                 │
      │                 │ ────────────────────────────────► │                  │                 │
      │                 │                 │                  │                  │                 │
      │                 │                 │ INTENTION_COMPLETE                  │                 │
      │                 │                 │ ◄──────────────  │                  │                 │
      │                 │                 │                  │                  │                 │
      │                 │                 │ PROCESS_INTENTION│                  │                 │
      │                 │                 │ ─────────────────────────────────► │                 │
      │                 │                 │                  │                  │                 │
      │                 │                 │                  │ OBSERVATION_COMPLETE               │
      │                 │                 │                  │ ◄───────────────                  │
      │                 │                 │                  │                  │                 │
      │                 │                 │                  │ PROCESS_OBSERVATION                │
      │                 │                 │                  │ ────────────────────────────────► │
      │                 │                 │                  │                  │                 │
      │                 │                 │                  │                  │ UNDERSTANDING_COMPLETE
      │                 │                 │                  │                  │ ◄────────────  │
      │                 │                 │                  │                  │                 │
      │                 │                 │                  │                  │ PROCESS_UNDERSTANDING
      │                 │                 │                  │                  │ ───────────────────►
      │                 │                 │                  │                  │                 │
      │                 │                 │                  │                  │                 │ YIELD_COMPLETE
      │                 │                 │                  │                  │                 │ ◄─────────────
┌─────┴─────┐     ┌─────┴─────┐     ┌─────┴─────┐     ┌──────┴─────┐     ┌──────┴──────┐     ┌────┴─────┐
│ActionActor│     │ExperienceActor│     │IntentionActor│     │ObservationActor│     │UnderstandingActor│     │YieldActor│
└───────────┘     └───────────┘     └───────────┘     └────────────┘     └─────────────┘     └──────────┘
```

### Detailed Message Types

The PostChain uses the following message types:

1. **PROCESS_INPUT**

   - Sent to: ActionActor
   - Data: `{"input": "user input text"}`
   - Response: ACTION_COMPLETE

2. **PROCESS_ACTION**

   - Sent to: ExperienceActor
   - Data: `{"action_output": {...}}`
   - Response: EXPERIENCE_COMPLETE

3. **PROCESS_EXPERIENCE**

   - Sent to: IntentionActor
   - Data: `{"experience_output": {...}}`
   - Response: INTENTION_COMPLETE

4. **PROCESS_INTENTION**

   - Sent to: ObservationActor
   - Data: `{"intention_output": {...}}`
   - Response: OBSERVATION_COMPLETE

5. **PROCESS_OBSERVATION**

   - Sent to: UnderstandingActor
   - Data: `{"observation_output": {...}}`
   - Response: UNDERSTANDING_COMPLETE

6. **PROCESS_UNDERSTANDING**
   - Sent to: YieldActor
   - Data: `{"understanding_output": {...}}`
   - Response: YIELD_COMPLETE

## System Management Message Flow

System management involves messages related to actor lifecycle, supervision, and coordination. The following diagram illustrates the message flow for actor supervision:

```
┌─────────────┐                                  ┌───────────┐                                  ┌───────────┐
│SupervisorActor│                                  │ChildActor1│                                  │ChildActor2│
└──────┬──────┘                                  └─────┬─────┘                                  └─────┬─────┘
       │                                               │                                               │
       │ SUPERVISE                                     │                                               │
       │ ──────────────────────────────────────────►  │                                               │
       │                                               │                                               │
       │ SUPERVISION_STARTED                           │                                               │
       │ ◄──────────────────────────────────────────  │                                               │
       │                                               │                                               │
       │ SUPERVISE                                     │                                               │
       │ ────────────────────────────────────────────────────────────────────────────────────────────►│
       │                                               │                                               │
       │ SUPERVISION_STARTED                           │                                               │
       │ ◄────────────────────────────────────────────────────────────────────────────────────────────│
       │                                               │                                               │
       │ HEARTBEAT                                     │                                               │
       │ ──────────────────────────────────────────►  │                                               │
       │                                               │                                               │
       │ HEARTBEAT_RESPONSE                            │                                               │
       │ ◄──────────────────────────────────────────  │                                               │
       │                                               │                                               │
       │ HEARTBEAT                                     │                                               │
       │ ────────────────────────────────────────────────────────────────────────────────────────────►│
       │                                               │                                               │
       │                                               │                                               │
       │                                               │                                               │
       │                                               │                                               │
       │ ERROR (timeout)                               │                                               │
       │ ◄────────────────────────────────────────────────────────────────────────────────────────────│
       │                                               │                                               │
       │ RESTART                                       │                                               │
       │ ────────────────────────────────────────────────────────────────────────────────────────────►│
       │                                               │                                               │
       │ RESTART_COMPLETE                              │                                               │
       │ ◄────────────────────────────────────────────────────────────────────────────────────────────│
       │                                               │                                               │
┌──────┴──────┐                                  ┌─────┴─────┐                                  ┌─────┴─────┐
│SupervisorActor│                                  │ChildActor1│                                  │ChildActor2│
└─────────────┘                                  └───────────┘                                  └───────────┘
```

### System Management Message Types

1. **SUPERVISE**

   - Sent to: Any actor
   - Data: `{"actor_id": "actor_id"}`
   - Response: SUPERVISION_STARTED

2. **HEARTBEAT**

   - Sent to: Any supervised actor
   - Data: `{}`
   - Response: HEARTBEAT_RESPONSE

3. **RESTART**

   - Sent to: Any actor
   - Data: `{"reason": "reason for restart"}`
   - Response: RESTART_COMPLETE

4. **STOP**
   - Sent to: Any actor
   - Data: `{"reason": "reason for stopping"}`
   - Response: STOP_COMPLETE

## Data Persistence Message Flow

Data persistence involves messages related to storing and retrieving data. The following diagram illustrates the message flow for data persistence:

```
┌─────────────┐                                  ┌─────────────┐
│ProcessingActor│                                  │DatabaseActor│
└──────┬──────┘                                  └──────┬──────┘
       │                                                │
       │ STORE                                          │
       │ ─────────────────────────────────────────────►│
       │                                                │
       │                                                │ Store data
       │                                                │ in database
       │                                                │
       │ STORE_COMPLETE                                 │
       │ ◄─────────────────────────────────────────────│
       │                                                │
       │ RETRIEVE                                       │
       │ ─────────────────────────────────────────────►│
       │                                                │
       │                                                │ Retrieve data
       │                                                │ from database
       │                                                │
       │ RETRIEVE_COMPLETE                              │
       │ ◄─────────────────────────────────────────────│
       │                                                │
       │ QUERY                                          │
       │ ─────────────────────────────────────────────►│
       │                                                │
       │                                                │ Execute query
       │                                                │ on database
       │                                                │
       │ QUERY_COMPLETE                                 │
       │ ◄─────────────────────────────────────────────│
       │                                                │
┌──────┴──────┐                                  ┌──────┴──────┐
│ProcessingActor│                                  │DatabaseActor│
└─────────────┘                                  └─────────────┘
```

### Data Persistence Message Types

1. **STORE**

   - Sent to: DatabaseActor
   - Data: `{"key": "key", "value": {...}}`
   - Response: STORE_COMPLETE

2. **RETRIEVE**

   - Sent to: DatabaseActor
   - Data: `{"key": "key"}`
   - Response: RETRIEVE_COMPLETE with `{"key": "key", "value": {...}}`

3. **QUERY**
   - Sent to: DatabaseActor
   - Data: `{"sql": "SELECT * FROM table", "parameters": [...]}`
   - Response: QUERY_COMPLETE with `{"results": [...]}`

## Error Handling Message Flow

Error handling involves messages related to handling and recovering from errors. The following diagram illustrates the message flow for error handling:

```
┌─────────────┐                                  ┌───────────┐                                  ┌─────────────┐
│ClientActor   │                                  │ProcessingActor│                                  │SupervisorActor│
└──────┬──────┘                                  └─────┬─────┘                                  └──────┬──────┘
       │                                               │                                                │
       │ PROCESS                                       │                                                │
       │ ──────────────────────────────────────────►  │                                                │
       │                                               │                                                │
       │                                               │ Error occurs                                   │
       │                                               │ during processing                              │
       │                                               │                                                │
       │ ERROR                                         │                                                │
       │ ◄──────────────────────────────────────────  │                                                │
       │                                               │                                                │
       │                                               │ ERROR_NOTIFICATION                             │
       │                                               │ ─────────────────────────────────────────────►│
       │                                               │                                                │
       │                                               │                                                │ Log error
       │                                               │                                                │ and decide
       │                                               │                                                │ on action
       │                                               │                                                │
       │                                               │ RESTART                                        │
       │                                               │ ◄─────────────────────────────────────────────│
       │                                               │                                                │
       │                                               │ Restart and                                    │
       │                                               │ reinitialize                                   │
       │                                               │                                                │
       │                                               │ RESTART_COMPLETE                               │
       │                                               │ ─────────────────────────────────────────────►│
       │                                               │                                                │
       │ RETRY                                         │                                                │
       │ ──────────────────────────────────────────►  │                                                │
       │                                               │                                                │
       │                                               │ Process                                        │
       │                                               │ successfully                                   │
       │                                               │                                                │
       │ PROCESS_COMPLETE                              │                                                │
       │ ◄──────────────────────────────────────────  │                                                │
       │                                               │                                                │
┌──────┴──────┐                                  ┌─────┴─────┐                                  ┌──────┴──────┐
│ClientActor   │                                  │ProcessingActor│                                  │SupervisorActor│
└─────────────┘                                  └───────────┘                                  └─────────────┘
```

### Error Handling Message Types

1. **ERROR**

   - Sent from: Any actor
   - Data: `{"error_message": "error message", "error_code": "error_code"}`

2. **ERROR_NOTIFICATION**

   - Sent to: SupervisorActor
   - Data: `{"actor_id": "actor_id", "error_message": "error message", "error_code": "error_code"}`
   - Response: None (or RESTART, STOP, etc.)

3. **RETRY**
   - Sent to: Any actor
   - Data: Same as original message
   - Response: Depends on the original message type

## Integration Message Flows

Integration message flows involve communication with external systems. The following diagram illustrates the message flow for blockchain integration:

```
┌─────────────┐                                  ┌────────────┐                                  ┌─────────┐
│ProcessingActor│                                  │BlockchainActor│                                  │Blockchain│
└──────┬──────┘                                  └──────┬─────┘                                  └────┬────┘
       │                                                │                                              │
       │ SUBMIT_TRANSACTION                             │                                              │
       │ ─────────────────────────────────────────────►│                                              │
       │                                                │                                              │
       │                                                │ Prepare and sign                             │
       │                                                │ transaction                                  │
       │                                                │                                              │
       │                                                │ Submit transaction                           │
       │                                                │ ─────────────────────────────────────────────►
       │                                                │                                              │
       │                                                │                                              │ Process
       │                                                │                                              │ transaction
       │                                                │                                              │
       │                                                │ Transaction receipt                          │
       │                                                │ ◄─────────────────────────────────────────────
       │                                                │                                              │
       │ TRANSACTION_COMPLETE                           │                                              │
       │ ◄─────────────────────────────────────────────│                                              │
       │                                                │                                              │
       │ QUERY_BLOCKCHAIN                               │                                              │
       │ ─────────────────────────────────────────────►│                                              │
       │                                                │                                              │
       │                                                │ Query blockchain                             │
       │                                                │ ─────────────────────────────────────────────►
       │                                                │                                              │
       │                                                │ Query result                                 │
       │                                                │ ◄─────────────────────────────────────────────
       │                                                │                                              │
       │ QUERY_COMPLETE                                 │                                              │
       │ ◄─────────────────────────────────────────────│                                              │
       │                                                │                                              │
┌──────┴──────┐                                  ┌──────┴─────┐                                  ┌────┴────┐
│ProcessingActor│                                  │BlockchainActor│                                  │Blockchain│
└─────────────┘                                  └────────────┘                                  └─────────┘
```

### Integration Message Types

1. **SUBMIT_TRANSACTION**

   - Sent to: BlockchainActor
   - Data: `{"transaction": {...}}`
   - Response: TRANSACTION_COMPLETE

2. **QUERY_BLOCKCHAIN**

   - Sent to: BlockchainActor
   - Data: `{"query": {...}}`
   - Response: QUERY_COMPLETE

3. **API_CALL**
   - Sent to: APIActor
   - Data: `{"endpoint": "endpoint", "method": "GET", "data": {...}, "headers": {...}}`
   - Response: API_RESPONSE

## Implementation Considerations

When implementing message flows, consider the following:

### Message Routing

Messages need to be routed to the appropriate actors. This can be done in several ways:

```python
# Direct actor reference
response = await target_actor.receive(message)

# Actor system lookup
target_actor = await actor_system.get_actor(actor_id)
response = await target_actor.receive(message)

# Message broker
await message_broker.send(message)
```

### Message Serialization

Messages need to be serializable for persistence and transmission:

```python
# Serialize a message
message_dict = {
    "type": message.type,
    "data": message.data,
    "sender": message.sender,
    "receiver": message.receiver,
    "id": message.id
}
serialized_message = json.dumps(message_dict)

# Deserialize a message
message_dict = json.loads(serialized_message)
message = Message(
    type=message_dict["type"],
    data=message_dict["data"],
    sender=message_dict["sender"],
    receiver=message_dict["receiver"],
    id=message_dict["id"]
)
```

### Message Validation

Messages should be validated before processing:

```python
def validate_message(message):
    # Check required fields
    if not message.type:
        raise ValueError("Message type is required")

    # Validate message type
    if message.type not in VALID_MESSAGE_TYPES:
        raise ValueError(f"Invalid message type: {message.type}")

    # Validate message data based on type
    if message.type == "PROCESS_INPUT":
        if "input" not in message.data:
            raise ValueError("PROCESS_INPUT message must contain 'input' field")

    # Additional validation logic
    return True
```

### Asynchronous Message Processing

Messages should be processed asynchronously:

```python
async def process_message(message):
    # Validate the message
    validate_message(message)

    # Get the target actor
    target_actor = await actor_system.get_actor(message.receiver)

    # Send the message to the actor
    response = await target_actor.receive(message)

    # Process the response
    if response.type == "ERROR":
        # Handle error
        await handle_error(response)
    else:
        # Process successful response
        await process_response(response)

    return response
```

## Conclusion

Message flow diagrams provide a visual representation of how actors communicate in Choir's actor-based architecture. By understanding these flows, developers can more easily navigate the codebase, understand component interactions, and implement new functionality that integrates seamlessly with the existing system.

For more detailed information on implementing message flows, refer to the [Message Protocol Reference](../3-implementation/message_protocol_reference.md) and the [Actor Implementation Guide](../3-implementation/actor_implementation_guide.md).
