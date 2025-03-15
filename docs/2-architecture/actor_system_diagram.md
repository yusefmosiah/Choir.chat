# Actor System Architecture Diagrams

This document provides visual representations of Choir's actor-based architecture to help developers understand the system structure, message flow, and component interactions.

## Core Actor System Components

The following diagram shows the primary components of the actor-based architecture:

```mermaid
graph TD
    subgraph "Actor System"
        AS[Actor System] --- SM[State Manager]
        AS --- SC[System Clock]
        AS --- MM[Message Manager]
        AS --- AM[Actor Manager]

        AM --- A1[Action Actor]
        AM --- A2[Experience Actor]
        AM --- A3[Intention Actor]
        AM --- A4[Observation Actor]
        AM --- A5[Understanding Actor]
        AM --- A6[Yield Actor]

        SM --- DB[(libSQL/Turso)]

        MM --- MQ[Message Queue]
        MM --- MT[Message Tracer]
    end

    subgraph "External Systems"
        API[FastAPI] --- AS
        WPM[Worker Pool Manager] --- AM
        BC[Blockchain] --- AS
    end

    subgraph "Worker Pools"
        WPM --- WP1[GPT-4 Pool]
        WPM --- WP2[Claude Pool]
        WPM --- WP3[Gemini Pool]
        WPM --- WP4[Vision Workers]
        WPM --- WP5[Audio Workers]
    end

    style AS fill:#f9f,stroke:#333,stroke-width:2px
    style AM fill:#bbf,stroke:#333,stroke-width:2px
    style SM fill:#bbf,stroke:#333,stroke-width:2px
    style MM fill:#bbf,stroke:#333,stroke-width:2px
    style WPM fill:#bfb,stroke:#333,stroke-width:2px
```

## PostChain Message Flow

This sequence diagram illustrates the message flow through the actor system during a typical PostChain execution:

```mermaid
sequenceDiagram
    participant User
    participant API as FastAPI
    participant AS as Actor System
    participant A1 as Action Actor
    participant A2 as Experience Actor
    participant A3 as Intention Actor
    participant A4 as Observation Actor
    participant A5 as Understanding Actor
    participant A6 as Yield Actor
    participant DB as libSQL/Turso

    User->>API: Send user input
    API->>AS: Create request

    AS->>A1: Process(user_input)
    A1->>DB: Load state
    DB-->>A1: Return state
    A1->>A1: Update state
    A1->>DB: Save state
    A1-->>AS: Return action_result

    AS->>A2: Process(action_result)
    A2->>DB: Load state
    DB-->>A2: Return state
    A2->>DB: Query vector store
    DB-->>A2: Return relevant context
    A2->>A2: Update state with context
    A2->>DB: Save state
    A2-->>AS: Return experience_result

    AS->>A3: Process(experience_result)
    A3->>DB: Load state
    DB-->>A3: Return state
    A3->>A3: Align with intention
    A3->>DB: Save state
    A3-->>AS: Return intention_result

    AS->>A4: Process(intention_result)
    A4->>DB: Load state
    DB-->>A4: Return state
    A4->>A4: Record semantic connections
    A4->>DB: Save state
    A4-->>AS: Return observation_result

    AS->>A5: Process(observation_result)
    A5->>DB: Load state
    DB-->>A5: Return state
    A5->>A5: Make continuation decision
    A5->>DB: Save state
    A5-->>AS: Return understanding_result

    AS->>A6: Process(understanding_result)
    A6->>DB: Load state
    DB-->>A6: Return state
    A6->>A6: Generate final response
    A6->>DB: Save state
    A6-->>AS: Return yield_result

    AS-->>API: Return final response
    API-->>User: Display response
```

## Actor State Lifecycle

This diagram illustrates the lifecycle of an actor's state:

```mermaid
stateDiagram-v2
    [*] --> Initialized: Actor creation
    Initialized --> Active: Process message
    Active --> Updated: State change
    Updated --> Persisted: Save to libSQL
    Persisted --> Active: Process next message
    Active --> Suspended: No messages
    Suspended --> Active: New message
    Active --> Failed: Error
    Failed --> Recovered: Supervisor restarts
    Recovered --> Active: Resume processing
    Active --> Terminated: Actor shutdown
    Terminated --> [*]
```

## Phase Worker Pool Architecture

This diagram shows how the Phase Worker Pool pattern extends the actor model:

```mermaid
graph TD
    subgraph "Phase Types"
        PT1[Action Type]
        PT2[Experience Type]
        PT3[Intention Type]
        PT4[Observation Type]
        PT5[Understanding Type]
        PT6[Yield Type]
    end

    subgraph "Modality-Specific Actors"
        PT1 --> A1T[Text Action Actor]
        PT1 --> A1A[Audio Action Actor]
        PT1 --> A1V[Video Action Actor]
        PT1 --> A1C[Code Action Actor]

        PT2 --> A2T[Text Experience Actor]
        PT2 --> A2A[Audio Experience Actor]
        PT2 --> A2V[Video Experience Actor]
        PT2 --> A2C[Code Experience Actor]

        %% Other actor types would follow the same pattern
    end

    subgraph "Domain-Specific Actors"
        PT2 --> A2M[Medical Experience Actor]
        PT2 --> A2L[Legal Experience Actor]
        PT2 --> A2F[Financial Experience Actor]
    end

    subgraph "Worker Pools"
        WP1[GPT-4 Pool]
        WP2[Claude Pool]
        WP3[Gemini Pool]
        WP4[Vision Pool]
        WP5[Audio Pool]
        WP6[Embedder Pool]
    end

    A1T --> WP1
    A1T --> WP2
    A2T --> WP1
    A2T --> WP3
    A1V --> WP4
    A1A --> WP5
    A2M --> WP1
    A2L --> WP2

    style PT1 fill:#f96,stroke:#333,stroke-width:2px
    style PT2 fill:#f96,stroke:#333,stroke-width:2px
    style PT3 fill:#f96,stroke:#333,stroke-width:2px
    style PT4 fill:#f96,stroke:#333,stroke-width:2px
    style PT5 fill:#f96,stroke:#333,stroke-width:2px
    style PT6 fill:#f96,stroke:#333,stroke-width:2px
```

## Integration Architecture

This diagram shows how the actor system integrates with external systems:

```mermaid
graph LR
    subgraph "Choir Actor System"
        AS[Actor System]
    end

    subgraph "Storage"
        DB1[(libSQL/Turso)]
        VDB[(Vector Storage)]
    end

    subgraph "Blockchain"
        BC1[Sui Move VM]
        BC2[Smart Contracts]
        BC3[CHIP Token]
    end

    subgraph "API Layer"
        API1[FastAPI]
        API2[WebSockets]
        API3[REST Endpoints]
    end

    subgraph "Deployment"
        D1[Docker]
        D2[Phala TEE]
        D3[Worker Nodes]
    end

    subgraph "Client Applications"
        C1[iOS App]
        C2[Web Client]
        C3[Third-party Integrations]
    end

    AS <--> DB1
    AS <--> VDB
    AS <--> BC1
    BC1 <--> BC2
    BC2 <--> BC3

    AS <--> API1
    API1 <--> API2
    API1 <--> API3

    AS --> D1
    D1 --> D2
    D1 --> D3

    API1 <--> C1
    API1 <--> C2
    API1 <--> C3

    style AS fill:#f9f,stroke:#333,stroke-width:2px
    style DB1 fill:#bbf,stroke:#333,stroke-width:2px
    style VDB fill:#bbf,stroke:#333,stroke-width:2px
    style BC1 fill:#bfb,stroke:#333,stroke-width:2px
    style API1 fill:#fbf,stroke:#333,stroke-width:2px
    style D1 fill:#ff9,stroke:#333,stroke-width:2px
```

## Message Structure

This diagram illustrates the structure of messages passed between actors:

```mermaid
classDiagram
    class Message {
        +str id
        +MessageType type
        +str sender
        +str recipient
        +datetime created_at
        +Any content
        +str correlation_id
    }

    class MessageType {
        <<enumeration>>
        REQUEST
        RESPONSE
        ERROR
        EVENT
    }

    Message --> MessageType

    class ActorMessage {
        +Message message
        +bool processed
        +datetime received_at
        +datetime processed_at
    }

    ActorMessage --> Message

    class MessageQueue {
        +List~ActorMessage~ queue
        +enqueue(Message)
        +dequeue() Message
        +peek() Message
    }

    MessageQueue --> ActorMessage
```

These diagrams provide a visual understanding of Choir's actor-based architecture. The diagrams can be rendered using Mermaid.js, which is supported by many Markdown viewers and documentation tools.
