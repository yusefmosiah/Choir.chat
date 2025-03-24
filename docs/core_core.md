# Core System Overview

VERSION core_system: 7.0

Note: This document describes the core system architecture, with initial focus on TestFlight functionality. More sophisticated event-driven mechanisms described here will be implemented post-funding.

The Choir system, in its MCP architecture, is structured around a clear hierarchy of truth and state management, now implemented as a network of interconnected **Model Context Protocol (MCP) servers**.

At the foundation, the **blockchain** (Sui) remains the authoritative source of truth for economic state, managing thread ownership, token balances (CHIP), message hashes, and co-author lists. **This entire economic framework is governed by the FQAHO (Fractional Quantum Anharmonic Oscillator) model and the CHIP token economy.** This ensures the FQAHO-based economic model's integrity and verifiability.

**libSQL/Turso databases** are used by each MCP server for local persistence of phase-specific state and data, including vector embeddings. This distributed database approach enhances scalability and fault isolation.

**Qdrant** continues to serve as the authoritative source for content and semantic relationships, storing message content, embeddings, and citation networks, now accessed by the Experience phase MCP server.

The **AEIOU-Y Post Chain** is now realized as a sequence of specialized **MCP servers** (Action, Experience, Intention, Observation, Understanding, Yield), each responsible for a distinct phase of the user interaction cycle.  User input is processed sequentially through these servers, each contributing to the evolving conversation state.

**MCP clients** within each server facilitate communication with other phase-servers, using a standardized message protocol over SSE streams for efficient, asynchronous communication and streaming responses.

State updates are managed within each MCP server's local libSQL/Turso database, with the "conversation state resource" being managed by the Host application and accessible to servers as needed. This distributed state management approach enhances scalability and resilience.

The economic model, based on FQAHO dynamics and the CHIP token, is now integrated into the MCP architecture, with economic actions triggered and recorded via PySUI interactions with the Sui blockchain from within MCP servers.

This MCP architecture enables a more modular, scalable, and secure Choir system. Each phase, as an independent MCP server, encapsulates its logic and state, improving maintainability and fault isolation. The use of Phala Network for deployment further enhances security and confidentiality.

The result is a distributed, service-oriented system that combines:

- **Economic Incentives (CHIP token, FQAHO)**: Managed on-chain via Sui and PySUI.
- **Semantic Knowledge (Qdrant)**: Accessed and utilized by the Experience phase server.
- **Natural Interaction Patterns (AEIOU-Y Post Chain)**: Implemented as a sequence of specialized MCP servers.
- **Fractional Quantum Dynamics (FQAHO)**: Encapsulated within the economic model and parameter evolution logic.
- **Swift Concurrency (replaced by Python Async/await in MCP servers)**:  Each MCP server leverages Python's async/await for efficient concurrent operations.
- **libSQL/Turso**: Provides local persistence and vector search for each MCP server, enabling efficient state and knowledge management within phases.
- **Phala Network**: Provides confidential computing environment for secure and private operations.

This architecture enables the Choir system to evolve into a truly scalable, robust, and secure platform for building a tokenized marketplace of ideas and upgrading human financial decision-making.
