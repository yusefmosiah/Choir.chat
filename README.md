# Post Chain Actor Model

A modern implementation of the Post Chain (AEIOU-Y Chorus Cycle) pattern using the actor model for multiagent coordination and libsql/turso for persistent storage with RAG capabilities.

## 🌟 Key Features

- **Actor Model Architecture**: Natural fit for multiagent systems, with isolated state and message passing
- **Post Chain Implementation**: Complete AEIOU-Y Chorus Cycle with specialized actors
- **Type Safety**: Pydantic models for message validation and state management
- **Persistence**: State persistence using libsql/turso for reliable operation
- **RAG Integration**: Vector search capabilities for knowledge retrieval
- **Asynchronous Processing**: Non-blocking operations using Python's asyncio

## 🏗️ Architecture Overview

The system implements the Post Chain pattern through a set of specialized actors that communicate via message passing:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐          │
│  │ Action  │    │Experience│    │Intention│          │
│  │ Actor   │───▶│  Actor  │───▶│  Actor  │───┐      │
│  └─────────┘    └─────────┘    └─────────┘   │      │
│       ▲                                       │      │
│       │                                       ▼      │
│       │           POST CHAIN                  │      │
│       │                                       │      │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐   │      │
│  │  Yield  │◀───│Understand│◀───│Observe  │◀──┘      │
│  │  Actor  │    │  Actor   │    │ Actor   │          │
│  └─────────┘    └─────────┘    └─────────┘          │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                       ▲
         │   ┌───────────────┐   │
         └──▶│  libsql/turso │───┘
             │  (SQL + RAG)  │
             └───────────────┘
```

### Post Chain Flow (AEIOU-Y)

1. **Action Actor**: Initial response to user input
2. **Experience Actor**: Enrichment with prior knowledge
3. **Intention Actor**: Alignment with user intent
4. **Observation Actor**: Recording semantic connections
5. **Understanding Actor**: Decision on continuation
6. **Yield Actor**: Final response production

Each actor maintains its own state and communicates through asynchronous message passing, enabling a clean separation of concerns and natural concurrency.

## 🔧 Implementation Components

### Actor Model Core (`actor_model.py`)

- Base `Actor` class with generic type parameters
- Message passing infrastructure
- State management
- Actor system for coordination

### Post Chain Implementation (`post_chain_actors.py`)

- Specialized actors for each phase of the Post Chain
- State definitions for each actor
- Complete chain implementation
- Message handling logic

### Storage Integration (`turso_integration.py`)

- libsql/turso database integration
- Vector storage for embeddings
- RAG query capabilities
- State persistence

### Demo Runner (`run_post_chain.py`)

- Interactive demo mode
- Benchmark mode
- Example interactions

## 🚀 Getting Started

### Prerequisites

- Python 3.8+
- Required packages: `pydantic`, `numpy`, `aiosqlite` (and eventually `libsql` client)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/post-chain-actor-model.git
cd post-chain-actor-model

# Set up a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Running the Demo

```bash
# Run the interactive demo
python run_post_chain.py

# Run with verbose logging
python run_post_chain.py -v

# Run benchmark mode
python run_post_chain.py -b
```

## 📈 Benefits Over Graph-Based Approaches

The actor model approach offers several advantages over graph-based frameworks:

1. **Natural State Management**: Each actor manages its own state, avoiding complex central state management
2. **Fault Isolation**: Errors in one actor don't necessarily affect others
3. **Dynamic Topology**: Actor relationships can evolve at runtime
4. **Simpler Testing**: Actors can be tested in isolation
5. **Better Scaling**: Natural distribution across compute resources
6. **Familiar Programming Model**: Similar to object-oriented programming but with message passing

## 🧠 Design Philosophy

This implementation follows these core principles:

1. **Message-Centric Communication**: All interaction happens through well-defined messages
2. **State Encapsulation**: Actors own and manage their state
3. **Loose Coupling**: Actors know minimal details about each other
4. **Progressive Enhancement**: The system can start simple and evolve
5. **Persistence by Default**: All state changes can be persisted

## 🔄 Migrating from LangGraph

If you're migrating from a LangGraph implementation, consider these mapping patterns:

- LangGraph Nodes → Actors
- LangGraph Edges → Message Pathways
- LangGraph State → Distributed Actor States
- LangGraph Checkpoints → Persisted Actor States

## 📚 Further Reading

- [The Actor Model (Wikipedia)](https://en.wikipedia.org/wiki/Actor_model)
- [Erlang and the Actor Model](https://www.erlang.org/blog/why-erlang-matters/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [libSQL/Turso Documentation](https://turso.tech/libsql)
