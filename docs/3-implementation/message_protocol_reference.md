# Message Protocol Reference

## Overview

The actor-based implementation of the PostChain relies on a standardized message protocol between actors. This document defines the message structure, content expectations, and context management operations used throughout the system.

## Message Structure

All messages between actors follow this general structure:

```json
{
  "content": {
    // The primary payload being processed
  },
  "metadata": {
    "phase": "current_phase",
    "sender": "actor_id",
    "timestamp": "iso8601_timestamp",
    "context_operations": [
      // Instructions for context management
    ],
    "recursion_state": {
      "cycle_count": 0,
      "termination_conditions": {}
    }
  }
}
```

### Content Field

The `content` field contains the primary information being processed. Its structure varies depending on the phase but generally includes:

- User input (in the initial message)
- AI-generated content
- Search results or retrieved information
- Structured data relevant to the current processing

### Metadata Fields

#### phase

Indicates which phase of the PostChain produced this message. Valid values:

- `"action"`
- `"experience"`
- `"intention"`
- `"observation"`
- `"understanding"`
- `"yield"`

#### sender

The unique identifier of the actor that sent the message.

#### timestamp

ISO 8601 formatted timestamp indicating when the message was created.

#### context_operations

An array of operations that should be applied to manage the context. See Context Operations section below.

#### recursion_state

Information about the current recursion cycle:

- `cycle_count`: The number of complete cycles completed so far
- `termination_conditions`: Phase-specific conditions that would indicate process completion

## Context Operations

Context operations allow actors to explicitly control how information is managed across the PostChain. Each operation is a structured object:

```json
{
  "operation": "operation_type",
  "target": "target_identifier",
  "data": {},
  "metadata": {}
}
```

### Operation Types

#### ADD

Adds new information to the context.

```json
{
  "operation": "ADD",
  "target": "context",
  "data": {
    "content": "Information to add",
    "source": "Source of information"
  },
  "metadata": {
    "importance": 0.8,
    "lifetime": "medium"
  }
}
```

#### TAG

Tags existing information for future reference or processing.

```json
{
  "operation": "TAG",
  "target": "message_id_or_selector",
  "data": {
    "tags": ["important", "user_intent"]
  },
  "metadata": {
    "confidence": 0.9
  }
}
```

#### PRUNE

Marks information for potential removal from context.

```json
{
  "operation": "PRUNE",
  "target": "message_id_or_selector",
  "data": {
    "reason": "outdated"
  },
  "metadata": {
    "force": false
  }
}
```

#### TRANSFORM

Indicates a transformation that should be applied to information.

```json
{
  "operation": "TRANSFORM",
  "target": "message_id_or_selector",
  "data": {
    "transformation": "summarize",
    "parameters": {
      "max_length": 100
    }
  },
  "metadata": {}
}
```

#### LINK

Creates a semantic connection between pieces of information.

```json
{
  "operation": "LINK",
  "target": "message_id_or_selector",
  "data": {
    "linked_to": "other_message_id",
    "relationship": "supports"
  },
  "metadata": {
    "strength": 0.7
  }
}
```

#### PRIORITIZE

Adjusts the importance of information for context retention.

```json
{
  "operation": "PRIORITIZE",
  "target": "message_id_or_selector",
  "data": {
    "priority": 0.9
  },
  "metadata": {
    "reason": "central_to_user_intent"
  }
}
```

## Message Processing Flow

1. An actor receives a message
2. The actor processes the content according to its phase-specific logic
3. The actor applies any context operations specified in the incoming message
4. The actor adds its own context operations based on its processing
5. The actor sends a new message to the next phase

## Phase-Specific Message Expectations

### Action → Experience

**Content focus**: User input with initial prompt application
**Key metadata**: Initial intent assessment

### Experience → Intention

**Content focus**: Original content enhanced with retrieved information
**Key metadata**: Sources and relevance of added information

### Intention → Observation

**Content focus**: Content focused on user goals
**Key metadata**: Alignment scores with identified intents

### Observation → Understanding

**Content focus**: Content with semantic connections identified
**Key metadata**: Tags and relationship links

### Understanding → Yield

**Content focus**: Filtered and integrated content
**Key metadata**: Context management decisions

### Yield → Action (Recursion)

**Content focus**: Final output with continuation decision
**Key metadata**: Updated recursion state

## Implementation Considerations

1. **Message Immutability**: Once sent, messages should not be modified
2. **Operation vs. Execution**: Context operations express intent but don't guarantee execution
3. **Actor Autonomy**: Actors may choose how to interpret operations based on their own logic
4. **Protocol Versioning**: Include version information in implementations to allow evolution

## Example: Complete Message Flow

Below is an example of how a message might evolve through a complete cycle of the PostChain:

```json
// Initial message to Action
{
  "content": {
    "user_input": "What are the latest developments in quantum computing?"
  },
            "metadata": {
    "phase": "initial",
    "sender": "system",
    "timestamp": "2023-06-15T10:30:00Z"
  }
}

// Action → Experience
{
  "content": {
    "user_input": "What are the latest developments in quantum computing?",
    "initial_assessment": "User is asking for recent advancements in quantum computing technology."
  },
            "metadata": {
    "phase": "action",
    "sender": "action_actor",
    "timestamp": "2023-06-15T10:30:01Z",
    "context_operations": [
      {
        "operation": "ADD",
        "target": "context",
        "data": {
          "content": "User appears to be inquiring about recent technological developments.",
          "source": "intent_analysis"
        }
      }
    ],
    "recursion_state": {
      "cycle_count": 0
    }
  }
}

// Experience → Intention
{
  "content": {
    "user_input": "What are the latest developments in quantum computing?",
    "initial_assessment": "User is asking for recent advancements in quantum computing technology.",
    "search_results": [
      {
        "title": "Breakthrough in quantum error correction achieved",
        "source": "ScienceDaily",
        "date": "2023-05-30"
      },
      {
        "title": "New quantum chip design reduces noise by 75%",
        "source": "QuantumWorld",
        "date": "2023-06-10"
      }
    ]
  },
  "metadata": {
    "phase": "experience",
    "sender": "experience_actor",
    "timestamp": "2023-06-15T10:30:02Z",
    "context_operations": [
      {
        "operation": "ADD",
        "target": "context",
        "data": {
          "content": "Recent developments include error correction breakthroughs and new chip designs.",
          "source": "search_results"
        }
      },
      {
        "operation": "TAG",
        "target": "search_results[0]",
        "data": {
          "tags": ["recent", "significant"]
        }
      }
    ],
    "recursion_state": {
      "cycle_count": 0
    }
  }
}

// Additional phase messages would follow similar patterns
```

This protocol provides a foundation for implementing the temporal logic of the PostChain through explicit, deterministic message passing between actors.
