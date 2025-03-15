# Message Protocol Reference

This document provides a comprehensive reference for the message protocol used in Choir's actor-based architecture. It defines the message types, structures, and flows that enable communication between actors at different levels of the system.

## Table of Contents

1. [Introduction](#introduction)
2. [Message Structure](#message-structure)
3. [Base Message Types](#base-message-types)
4. [Thread Control Messages](#thread-control-messages)
5. [Phase Processing Messages](#phase-processing-messages)
6. [Agent Communication Messages](#agent-communication-messages)
7. [System Management Messages](#system-management-messages)
8. [Error Handling Messages](#error-handling-messages)
9. [Message Flows](#message-flows)
10. [Implementation Guidelines](#implementation-guidelines)

## Introduction

Choir's actor architecture uses a message-passing protocol to facilitate communication between different components of the system. Messages are used to:

- Control the lifecycle of PostChain threads
- Manage processing through AEIOU-Y phases
- Coordinate between Thread Actors and Phase Actors
- Facilitate communication with Pydantic AI agents
- Handle system management and monitoring

This document defines the structure, types, and expected behaviors for all messages in the system.

## Message Structure

All messages in Choir follow a consistent structure, defined as Pydantic models:

```python
from datetime import datetime
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field
from uuid import uuid4

class Message(BaseModel):
    """Base message class for all actor communications"""
    id: str = Field(default_factory=lambda: str(uuid4()))
    type: str
    data: Dict[str, Any] = Field(default_factory=dict)
    sender: Optional[str] = None
    receiver: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    correlation_id: Optional[str] = None

    def get_response_type(self) -> str:
        """Get the expected response type for this message"""
        response_type_map = {
            # Thread Control
            "CREATE_THREAD": "THREAD_CREATED",
            "START_THREAD": "THREAD_STARTED",
            "PAUSE_THREAD": "THREAD_PAUSED",
            "RESUME_THREAD": "THREAD_RESUMED",
            "TERMINATE_THREAD": "THREAD_TERMINATED",
            "GET_THREAD_STATUS": "THREAD_STATUS",

            # Phase Control
            "PROCESS_PHASE": "PHASE_PROCESSED",
            "INITIALIZE_PHASE": "PHASE_INITIALIZED",
            "PREPARE_CONTEXT": "CONTEXT_PREPARED",
            "INVOKE_AGENT": "AGENT_INVOKED",

            # Agent Communication
            "PROCESS_WITH_AGENT": "AGENT_RESPONSE",
            "UPDATE_AGENT_CONFIG": "AGENT_CONFIG_UPDATED",

            # System Management
            "HEARTBEAT": "HEARTBEAT_RESPONSE",
            "SUPERVISE": "SUPERVISION_STARTED",

            # Default fallback
            "ERROR": "ERROR_ACKNOWLEDGED"
        }
        return response_type_map.get(self.type, f"{self.type}_RESPONSE")


class Response(BaseModel):
    """Base response class for all actor communications"""
    id: str = Field(default_factory=lambda: str(uuid4()))
    type: str
    data: Dict[str, Any] = Field(default_factory=dict)
    sender: Optional[str] = None
    receiver: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    correlation_id: Optional[str] = None
    message_id: Optional[str] = None  # ID of the message being responded to


class ErrorResponse(Response):
    """Error response for failed message processing"""
    def __init__(
        self,
        error_message: str,
        error_code: Optional[str] = None,
        message_id: Optional[str] = None,
        **kwargs
    ):
        super().__init__(
            type="ERROR",
            data={
                "error_message": error_message,
                "error_code": error_code
            },
            message_id=message_id,
            **kwargs
        )
```

### Message Validation

All messages are validated using Pydantic's validation capabilities:

```python
def validate_message(message: Message) -> bool:
    """Validate a message against its expected schema"""
    # Basic validation happens automatically through Pydantic

    # Additional validation for specific message types
    if message.type == "PROCESS_PHASE":
        if "phase_type" not in message.data:
            raise ValueError("PROCESS_PHASE message must contain 'phase_type' field")

        valid_phase_types = ["action", "experience", "intention", "observation", "understanding", "yield"]
        if message.data["phase_type"] not in valid_phase_types:
            raise ValueError(f"Invalid phase_type: {message.data['phase_type']}")

    # Additional message-specific validation logic can be added here

    return True
```

## Base Message Types

The following base message types are used throughout the system:

### Message

The `Message` class is used for requests from one actor to another:

- **id**: Unique identifier for the message
- **type**: String identifying the message type
- **data**: Dictionary containing message data
- **sender**: ID of the sending actor
- **receiver**: ID of the receiving actor
- **timestamp**: When the message was created
- **correlation_id**: Optional ID for tracking related messages

### Response

The `Response` class is used for responses to messages:

- **id**: Unique identifier for the response
- **type**: String identifying the response type
- **data**: Dictionary containing response data
- **sender**: ID of the sending actor
- **receiver**: ID of the receiving actor
- **timestamp**: When the response was created
- **correlation_id**: Optional ID for tracking related messages
- **message_id**: ID of the message being responded to

### ErrorResponse

The `ErrorResponse` class is used for error responses:

- Extends the `Response` class
- **type**: Always "ERROR"
- **data**: Contains "error_message" and optional "error_code"

## Thread Control Messages

Thread control messages manage the lifecycle of PostChain threads:

### CREATE_THREAD

Creates a new PostChain thread:

```python
Message(
    type="CREATE_THREAD",
    data={
        "user_id": "user123",
        "initial_input": "Hello, world!",
        "metadata": {
            "source": "web",
            "session_id": "session456"
        }
    }
)
```

Response:

```python
Response(
    type="THREAD_CREATED",
    data={
        "thread_id": "thread789",
        "status": "created"
    },
    message_id="original_message_id"
)
```

### START_THREAD

Starts processing a thread:

```python
Message(
    type="START_THREAD",
    data={
        "thread_id": "thread789"
    }
)
```

Response:

```python
Response(
    type="THREAD_STARTED",
    data={
        "thread_id": "thread789",
        "status": "processing",
        "started_at": "2023-07-15T10:30:00Z"
    },
    message_id="original_message_id"
)
```

### PAUSE_THREAD

Pauses a running thread:

```python
Message(
    type="PAUSE_THREAD",
    data={
        "thread_id": "thread789"
    }
)
```

Response:

```python
Response(
    type="THREAD_PAUSED",
    data={
        "thread_id": "thread789",
        "status": "paused",
        "paused_at": "2023-07-15T10:35:00Z",
        "current_phase": "experience"
    },
    message_id="original_message_id"
)
```

### RESUME_THREAD

Resumes a paused thread:

```python
Message(
    type="RESUME_THREAD",
    data={
        "thread_id": "thread789"
    }
)
```

Response:

```python
Response(
    type="THREAD_RESUMED",
    data={
        "thread_id": "thread789",
        "status": "processing",
        "resumed_at": "2023-07-15T10:40:00Z",
        "current_phase": "experience"
    },
    message_id="original_message_id"
)
```

### TERMINATE_THREAD

Terminates a thread:

```python
Message(
    type="TERMINATE_THREAD",
    data={
        "thread_id": "thread789",
        "reason": "user_request"
    }
)
```

Response:

```python
Response(
    type="THREAD_TERMINATED",
    data={
        "thread_id": "thread789",
        "status": "terminated",
        "terminated_at": "2023-07-15T10:45:00Z",
        "reason": "user_request"
    },
    message_id="original_message_id"
)
```

### GET_THREAD_STATUS

Gets the current status of a thread:

```python
Message(
    type="GET_THREAD_STATUS",
    data={
        "thread_id": "thread789"
    }
)
```

Response:

```python
Response(
    type="THREAD_STATUS",
    data={
        "thread_id": "thread789",
        "status": "processing",
        "current_phase": "intention",
        "created_at": "2023-07-15T10:30:00Z",
        "updated_at": "2023-07-15T10:42:00Z",
        "phases_completed": ["action", "experience"],
        "phases_remaining": ["intention", "observation", "understanding", "yield"]
    },
    message_id="original_message_id"
)
```

## Phase Processing Messages

Phase processing messages manage the execution of individual phases in the PostChain:

### PROCESS_PHASE

Initiates processing for a specific phase:

```python
Message(
    type="PROCESS_PHASE",
    data={
        "thread_id": "thread789",
        "phase_type": "action",
        "input": "Hello, world!",
        "context": {
            "conversation_history": [],
            "user_id": "user123"
        }
    }
)
```

Response:

```python
Response(
    type="PHASE_PROCESSED",
    data={
        "thread_id": "thread789",
        "phase_type": "action",
        "output": {
            "response": "I'll help you with that.",
            "next_phase": "experience",
            "confidence": 0.95
        },
        "processing_time": 0.75
    },
    message_id="original_message_id"
)
```

### INITIALIZE_PHASE

Initializes a phase actor with configuration:

```python
Message(
    type="INITIALIZE_PHASE",
    data={
        "phase_type": "action",
        "config": {
            "model": "openai:gpt-4o",
            "temperature": 0.7,
            "max_tokens": 1000,
            "tools": ["web_search", "calculator"]
        }
    }
)
```

Response:

```python
Response(
    type="PHASE_INITIALIZED",
    data={
        "phase_type": "action",
        "status": "ready",
        "agent_id": "action_agent_123"
    },
    message_id="original_message_id"
)
```

### PREPARE_CONTEXT

Prepares context for a phase execution:

```python
Message(
    type="PREPARE_CONTEXT",
    data={
        "thread_id": "thread789",
        "phase_type": "experience",
        "previous_phase_output": {
            "response": "I'll help you with that.",
            "next_phase": "experience",
            "confidence": 0.95
        },
        "conversation_history": [
            {"role": "user", "content": "Hello, world!"},
            {"role": "assistant", "content": "I'll help you with that."}
        ]
    }
)
```

Response:

```python
Response(
    type="CONTEXT_PREPARED",
    data={
        "thread_id": "thread789",
        "phase_type": "experience",
        "context": {
            "messages": [
                {"role": "system", "content": "You are the experience phase..."},
                {"role": "user", "content": "Hello, world!"},
                {"role": "assistant", "content": "I'll help you with that."}
            ],
            "tools": ["memory_retrieval", "knowledge_base"],
            "metadata": {
                "user_id": "user123",
                "session_id": "session456"
            }
        }
    },
    message_id="original_message_id"
)
```

### INVOKE_AGENT

Invokes a Pydantic AI agent within a phase:

```python
Message(
    type="INVOKE_AGENT",
    data={
        "agent_id": "action_agent_123",
        "input": "Hello, world!",
        "context": {
            "user_id": "user123",
            "metadata": {
                "session_id": "session456"
            }
        },
        "stream": False
    }
)
```

Response:

```python
Response(
    type="AGENT_INVOKED",
    data={
        "agent_id": "action_agent_123",
        "result": {
            "response": "I'll help you with that.",
            "confidence": 0.95,
            "tool_calls": []
        },
        "processing_time": 0.75
    },
    message_id="original_message_id"
)
```

## Agent Communication Messages

Agent communication messages facilitate interaction with Pydantic AI agents:

### PROCESS_WITH_AGENT

Processes a request with a Pydantic AI agent:

```python
Message(
 type="PROCESS_WITH_AGENT",
 data={
     "input": "What is the capital of France?",
     "context": {
         "user_id": "user123",
         "metadata": {
             "session_id": "session456"
         }
     }
 }
)
```

Response:

```python
Response(
    type="AGENT_RESPONSE",
    data={
        "result": {
            "response": "The capital of France is Paris.",
            "confidence": 0.99,
            "tool_calls": []
        },
        "processing_time": 0.5
    },
    message_id="original_message_id"
   )
```

### UPDATE_AGENT_CONFIG

Updates the configuration of a Pydantic AI agent:

```python
Message(
 type="UPDATE_AGENT_CONFIG",
 data={
     "agent_id": "action_agent_123",
     "config": {
         "system_prompt": "You are a helpful assistant...",
         "model": "openai:gpt-4o",
         "temperature": 0.5,
         "tools": ["web_search", "calculator"]
     }
 }
)
```

Response:

```python
Response(
    type="AGENT_CONFIG_UPDATED",
    data={
        "agent_id": "action_agent_123",
        "status": "updated"
    },
    message_id="original_message_id"
   )
```

## System Management Messages

System management messages handle actor lifecycle and supervision:

### HEARTBEAT

Checks if an actor is alive:

```python
Message(
 type="HEARTBEAT",
 data={}
)
```

Response:

```python
Response(
    type="HEARTBEAT_RESPONSE",
    data={
        "status": "alive",
        "uptime": 3600,  # seconds
        "load": 0.5
    },
    message_id="original_message_id"
   )
```

### SUPERVISE

Establishes supervision of an actor:

```python
Message(
 type="SUPERVISE",
 data={
     "actor_id": "action_phase_actor_123"
 }
)
```

Response:

```python
Response(
    type="SUPERVISION_STARTED",
    data={
        "actor_id": "action_phase_actor_123",
        "status": "supervised"
    },
    message_id="original_message_id"
   )
```

### RESTART

Restarts an actor:

```python
Message(
 type="RESTART",
 data={
     "actor_id": "action_phase_actor_123",
     "reason": "error_recovery"
 }
)
```

Response:

```python
Response(
    type="RESTART_COMPLETE",
    data={
        "actor_id": "action_phase_actor_123",
        "status": "restarted",
        "restarted_at": "2023-07-15T11:30:00Z"
    },
    message_id="original_message_id"
   )
```

### STOP

Stops an actor:

```python
Message(
 type="STOP",
 data={
     "actor_id": "action_phase_actor_123",
     "reason": "shutdown"
 }
)
```

Response:

```python
Response(
    type="STOP_COMPLETE",
    data={
        "actor_id": "action_phase_actor_123",
        "status": "stopped",
        "stopped_at": "2023-07-15T12:00:00Z"
    },
    message_id="original_message_id"
)
```

## Error Handling Messages

Error handling messages manage error conditions in the system:

### ERROR

Indicates an error in processing:

```python
ErrorResponse(
    error_message="Failed to process phase",
    error_code="PHASE_PROCESSING_ERROR",
    message_id="original_message_id",
    data={
        "thread_id": "thread789",
        "phase_type": "action",
        "details": "API rate limit exceeded"
    }
   )
```

### ERROR_NOTIFICATION

Notifies a supervisor of an error:

```python
Message(
 type="ERROR_NOTIFICATION",
 data={
     "actor_id": "action_phase_actor_123",
     "error_message": "Failed to process phase",
     "error_code": "PHASE_PROCESSING_ERROR",
     "details": "API rate limit exceeded"
 }
)
```

Response:

```python
Response(
    type="ERROR_ACKNOWLEDGED",
    data={
        "actor_id": "action_phase_actor_123",
        "action_taken": "restart",
        "error_logged": True
    },
    message_id="original_message_id"
)
```

### RETRY

Retries a failed operation:

```python
Message(
    type="RETRY",
    data={
        "original_message_id": "failed_message_id",
        "attempt": 2,
        "max_attempts": 3
    }
)
```

Response depends on the original message type.

## Message Flows

This section outlines common message flows in the system.

### Thread Creation and Execution Flow

```
User/Client -> ThreadActor: CREATE_THREAD
ThreadActor -> User/Client: THREAD_CREATED
User/Client -> ThreadActor: START_THREAD
ThreadActor -> User/Client: THREAD_STARTED
ThreadActor -> ActionPhaseActor: PROCESS_PHASE (phase_type=action)
ActionPhaseActor -> ThreadActor: PHASE_PROCESSED
ThreadActor -> ExperiencePhaseActor: PROCESS_PHASE (phase_type=experience)
ExperiencePhaseActor -> ThreadActor: PHASE_PROCESSED
... continues through all phases ...
ThreadActor -> YieldPhaseActor: PROCESS_PHASE (phase_type=yield)
YieldPhaseActor -> ThreadActor: PHASE_PROCESSED
ThreadActor -> User/Client: Thread result notification (application-specific)
```

### Phase Processing Flow

```
ThreadActor -> PhaseActor: PROCESS_PHASE
PhaseActor -> PhaseActor: PREPARE_CONTEXT (internal)
PhaseActor -> AgentManagerActor: PROCESS_WITH_AGENT
AgentManagerActor -> PydanticAIAgent: Run agent (internal)
PydanticAIAgent -> AgentManagerActor: Agent result (internal)
AgentManagerActor -> PhaseActor: AGENT_RESPONSE
PhaseActor -> PhaseActor: Process agent result (internal)
PhaseActor -> ThreadActor: PHASE_PROCESSED
```

### Error Handling Flow

```
PhaseActor -> AgentManagerActor: PROCESS_WITH_AGENT
AgentManagerActor -> PhaseActor: ERROR (e.g., API error)
PhaseActor -> SupervisorActor: ERROR_NOTIFICATION
SupervisorActor -> AgentManagerActor: RESTART
AgentManagerActor -> SupervisorActor: RESTART_COMPLETE
PhaseActor -> AgentManagerActor: RETRY (with original PROCESS_WITH_AGENT)
AgentManagerActor -> PhaseActor: AGENT_RESPONSE
PhaseActor -> ThreadActor: PHASE_PROCESSED
```

## Implementation Guidelines

This section provides guidelines for implementing the message protocol.

### Message Handling

Actor message handling should follow this pattern:

```python
async def receive(self, message: Message) -> Response:
    """Handle incoming messages"""
    try:
        # Validate the message
        validate_message(message)

        # Handle different message types
        if message.type == "PROCESS_PHASE":
            return await self._process_phase(message)
        elif message.type == "INITIALIZE_PHASE":
            return await self._initialize_phase(message)
        elif message.type == "HEARTBEAT":
            return self._handle_heartbeat(message)
        # ... other message types ...
            else:
            return ErrorResponse(
                error_message=f"Unknown message type: {message.type}",
                message_id=message.id
            )
        except Exception as e:
        # Log the error
        logging.error(f"Error processing message {message.id}: {str(e)}")

        # Notify supervisor if appropriate
        await self._notify_supervisor_of_error(message, e)

        # Return error response
        return ErrorResponse(
            error_message=f"Error processing message: {str(e)}",
            message_id=message.id
        )
```

### Message Serialization

For persistence and transmission, messages should be serializable:

```python
def serialize_message(message: Message) -> str:
    """Serialize a message to JSON"""
    return message.model_dump_json()

def deserialize_message(json_str: str) -> Message:
    """Deserialize a message from JSON"""
    data = json.loads(json_str)
    return Message.model_validate(data)
```

### Message Routing

For routing messages between actors:

```python
async def send_message(message: Message) -> Response:
    """Send a message to its intended receiver"""
    if not message.receiver:
        raise ValueError("Message must have a receiver")

    # Get the target actor
    target_actor = await actor_system.get_actor(message.receiver)

    # Send the message
    response = await target_actor.receive(message)

    return response
```

### Best Practices

1. **Always validate messages** before processing
2. **Use correlation IDs** for related messages
3. **Include appropriate error details** in error responses
4. **Keep message data concise** but complete
5. **Log message flows** for debugging and monitoring
6. **Design for idempotency** where possible
7. **Use appropriate timeouts** for message handling
8. **Handle message retries** gracefully

## Conclusion

This message protocol reference defines the structure and types of messages used in Choir's actor-based architecture. By following this protocol, components can communicate effectively and reliably within the system.

For implementation details, refer to the [Actor Implementation Guide](actor_implementation_guide.md) and [State Management Patterns](state_management_patterns.md) documents.
