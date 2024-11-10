# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Choir System Diagrams

## System Architecture

graph TD
subgraph Solana
S1[Thread PDAs]
S2[Token Accounts]
S3[Approval State]
end

    subgraph Qdrant
        Q1[Message Content]
        Q2[Embeddings]
        Q3[Search Index]
    end

    subgraph Backend
        B1[FastAPI]
        B2[WebSocket]
        B3[Cache]
        B4[Chorus Cycle]
    end

    subgraph Frontend
        F1[Next.js]
        F2[Wallet]
        F3[UI State]
    end

    F1 --> B2
    F2 --> S1
    B1 --> Q1
    B1 --> S1
    B2 --> B4
    B4 --> Q2

## State Flow

sequenceDiagram
participant User
participant Frontend
participant Backend
participant Solana
participant Qdrant

    User->>Frontend: Submit Message
    Frontend->>Backend: Send Content
    Backend->>Qdrant: Store Content
    Backend->>Backend: Generate Hash
    Backend->>Solana: Record Hash
    Solana-->>Backend: Confirm
    Backend-->>Frontend: Update State
    Frontend-->>User: Show Success

## Token Flow

graph LR
subgraph Submission
A[User] -->|Stake| B[Escrow]
end

    subgraph Approval
        B -->|Approve| C[Thread]
        B -->|Deny| D[Deniers]
        B -->|Mixed| E[Treasury]
    end

    subgraph Divestment
        C -->|Share| F[Co-author]
    end

## Message Lifecycle

stateDiagram-v2
[*] --> Draft
Draft --> Submitted
Submitted --> Pending
Pending --> Published: All Approve
Pending --> Rejected: Any Deny
Pending --> Expired: Timeout
Published --> [*]
Rejected --> [*]
Expired --> [*]

## Thread Ownership

graph TD
A[Thread] -->|owns| B[Token Balance]
A -->|has| C[Co-authors]
A -->|contains| D[Messages]
C -->|approve| E[Specs]
E -->|becomes| C
C -->|divest from| A

## Privacy Model

graph TD
A[Content] -->|Public| B[Searchable + Visible]
A -->|Premium| C[Not Searchable + Visible]
A -->|ThreadOnly| D[Not Searchable + Co-authors Only]
B --> E[AI Summary]
C --> E
D --> E

## State Synchronization

sequenceDiagram
participant Solana
participant Backend
participant Qdrant
participant Frontend

    Solana->>Backend: State Change
    Backend->>Backend: Validate
    Backend->>Qdrant: Update Content
    Backend->>Frontend: Notify
    Frontend->>Frontend: Update UI
