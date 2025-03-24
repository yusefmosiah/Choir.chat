# libSQL Integration Plan for Choir MCP Architecture

## Overview

This document outlines the revised plan for integrating libSQL/Turso into the Choir platform, specifically within the context of the Model Context Protocol (MCP) architecture.  This plan focuses on leveraging libSQL/Turso for **server-specific state persistence** and explores the *potential* use for managing the "conversation state resource," while prioritizing essential functionalities for the MVP.

## Core Objectives (Revised for MCP Architecture)

1.  **libSQL for Server-Specific State Persistence:** Utilize libSQL as the primary solution for local persistence of server-specific data within MCP servers (phase servers).
2.  **Flexible Schema for Server State:** Design a flexible libSQL schema to accommodate the evolving state requirements of different MCP servers and their tools.
3.  **(Optional) Explore "Conversation State Resource" Management with libSQL (Host-Side):**  Discuss the *option* of using libSQL in the Host application to manage the "conversation state resource," but acknowledge that in-memory management might be sufficient for the MVP.
4.  **Vector Search (If Still Relevant, Focus on Qdrant for MVP):**  Re-evaluate the relevance of vector search within libSQL for the Experience phase.  Acknowledge that Qdrant (or other dedicated vector databases) might be a more scalable and feature-rich solution for vector search in the long term, and that the MVP might initially focus on simpler vector search mechanisms or defer advanced vector search features.
5.  **Simplify for MVP Scope:** Focus the libSQL integration plan on the *essential database functionalities* needed for the MVP, deferring more advanced features like multi-device sync or advanced quantization to later phases.

## Revised Implementation Plan (MCP Architecture Focus)

### 1. libSQL for MCP Server-Specific State Persistence

*   **Embedded libSQL in Each MCP Server:** Each MCP server (Action Server, Experience Server, etc.) will embed a lightweight libSQL database instance. This local database will be used for:
    *   **Caching:** Storing server-side caches (parsed context, API responses, etc.) for performance optimization.
    *   **Server-Local Data:** Persisting any server-specific data that needs to survive server restarts or be managed locally (e.g., server-side logs, temporary data structures).
*   **Simplified Schema for Server State:** Design a flexible and minimal libSQL schema for server-specific state.  This schema should be adaptable to the evolving needs of different phase servers and their tools.  Example schema (simplified):

    ```sql
    -- Generic cache table for MCP servers
    CREATE TABLE IF NOT EXISTS server_cache (
        key TEXT PRIMARY KEY,  -- Cache key (e.g., URI, query parameters)
        value BLOB,          -- Cached data (can be text, JSON, binary)
        timestamp INTEGER     -- Timestamp of cache entry
    );

    -- Server-specific state table (example - Experience Server)
    CREATE TABLE IF NOT EXISTS experience_server_state (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sync_time INTEGER,
        # ... other server-specific state fields ...
    );
    ```

*   **CRUD Operations in MCP Server SDK:**  Provide utility functions or helper classes within the MCP Server SDK (Python, TypeScript, etc.) to simplify common libSQL operations for servers:
    *   `server.cache_get(key: str) -> Optional[bytes]`
    *   `server.cache_set(key: str, value: bytes, expiry_seconds: int = None)`
    *   `server.get_server_state() -> dict`
    *   `server.set_server_state(state: dict)`

### 2. (Optional) "Conversation State Resource" Management in Host Application (libSQL - Considered, but In-Memory Might Be Sufficient for MVP)

*   **Discuss the Option, But Defer for MVP:**  While technically feasible, using libSQL to manage the "conversation state resource" in the Host application adds complexity and might be overkill for the MVP.
*   **In-Memory Management for MVP (Recommended):** For the MVP, it is recommended to manage the "conversation state resource" primarily in-memory within the Host application (e.g., using Python dictionaries or lists). This simplifies the MVP implementation and reduces dependencies.
*   **libSQL for Persistence in Later Phases (Scalability and Persistence):**  In later phases, if you need to handle very large conversation histories, multi-device sync, or more robust persistence for the "conversation state resource," you can *then* consider using libSQL (or a more scalable database) in the Host application to manage the resource.

### 3. Vector Search (Re-evaluate for MVP - Focus on Qdrant or Simpler Mechanisms Initially)

*   **Qdrant for Vector Search (Recommended for Scalability and Features):** For robust and scalable vector search capabilities, especially for the Experience phase's RAG functionality, **Qdrant (or other dedicated vector databases) remains the recommended solution in the long term.**
*   **libSQL Vector Search - Consider for *Simplified* MVP (If Needed):**  libSQL *does* offer basic vector search capabilities.  For a *very simplified MVP*, you *could* consider using libSQL's vector search for basic semantic matching in the Experience phase, *if* you want to minimize external dependencies and keep everything within libSQL for initial prototyping.  However, be aware of the limitations of libSQL's vector search compared to dedicated vector databases like Qdrant (scalability, features, performance).
*   **Defer Advanced Vector Search for MVP (Focus on Core Workflow First):**  For the *initial MVP*, it might be even more pragmatic to **defer advanced vector search features altogether** and focus on getting the *core PostChain workflow and UX* functional and validated first.  You could start with simpler keyword-based search or rule-based context retrieval in the Experience phase for the MVP, and then add more sophisticated vector search capabilities in later iterations.

### 4. Synchronization Management (Simplified for MVP - Focus on Local Persistence)

*   **No Multi-Device Sync for MVP (Defer):**  Multi-device synchronization of the conversation state or server state is **explicitly deferred for the MVP** to simplify the initial implementation and focus on core functionality.
*   **Local Persistence for Data Safety (MVP Goal):**  The primary goal of libSQL integration for the MVP is to provide **local persistence** of server-specific state and (potentially) the conversation history resource to ensure data safety and to allow servers and clients to recover from restarts or disconnections.
*   **Cloud Sync via Turso - Future Roadmap Item:**  Cloud sync via Turso (or other mechanisms) for multi-device access and data backup remains a **future roadmap item** to be considered in later phases, after the core MVP is validated.

## Phased Implementation Approach (libSQL Integration)

Given the focus on MVP and iterative development, the libSQL integration should follow a phased approach:

### Phase 1: Core UX and Workflow (No Database Dependency - Current Focus)

- Continue developing the core UI and PostChain workflow *without* a hard dependency on libSQL.
- Use in-memory data structures or mock data for testing and prototyping.

### Phase 2: Basic libSQL Integration for Server-Specific State (MVP Phase)

- Implement libSQL integration for MCP servers to handle server-specific state persistence and caching.
- Focus on the simplified libSQL schema for server state.
- Create utility functions in the MCP Server SDK to simplify libSQL operations.
- Test basic CRUD operations and server-side caching with libSQL.

### Phase 3: (Optional) Vector Search Integration (MVP or Post-MVP)

- If vector search is deemed essential for the MVP, implement basic vector search using libSQL's vector capabilities (or consider a simpler keyword-based fallback for the MVP).
- If vector search is deferred for the MVP, plan for integration with Qdrant (or other dedicated vector DB) in a post-MVP phase.

### Phase 4: (Future) Advanced libSQL Features and Cloud Sync

- Explore and implement more advanced libSQL features (e.g., embedded replicas, more complex queries) as needed for scalability and performance.
- Consider adding Turso cloud sync capabilities for multi-device access and data backup in a post-MVP phase.

## Conclusion

This revised libSQL integration plan prioritizes a pragmatic and iterative approach, focusing on the essential database functionalities needed for the Choir MVP within the MCP architecture. By leveraging libSQL for server-specific state persistence and deferring more complex features like multi-device sync and advanced vector search for later phases, the plan aims to balance functionality with development efficiency and to ensure a successful MVP launch.
