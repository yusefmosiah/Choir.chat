# libSQL Integration Plan for Choir: Expanded Role Across Architecture

## Overview

This document outlines the expanded integration plan for libSQL/Turso within the Choir platform, highlighting its use not only for MCP server-specific state persistence but also for **local data storage within the Swift client application**.  This document clarifies how libSQL/Turso fits into the overall Choir architecture alongside Qdrant (for vector database) and Sui (for blockchain), creating a multi-layered data persistence strategy.

## Core Objectives (Expanded Scope for libSQL/Turso)

1.  **libSQL for Server-Specific State Persistence (MCP Servers):** Utilize libSQL as the primary solution for local persistence of server-specific data within each MCP server (phase server), enabling efficient caching and server-local data management.
2.  **libSQL for Client-Side Data Storage (Swift Client):** Integrate libSQL into the Swift client application (iOS app) to provide **local, on-device data storage** for user data, conversation history, and application settings, enabling offline functionality and improved data management within the mobile client.
3.  **Flexible Schema Across Client and Servers:** Design flexible libSQL schemas that can accommodate the evolving data models in both MCP servers and the Swift client application, ensuring adaptability and maintainability.
4.  **Complementary to Qdrant and Sui:** Clearly define the distinct roles of libSQL/Turso, Qdrant, and Sui within the Choir stack, emphasizing how libSQL/Turso complements these technologies rather than replacing them.
5.  **Simplify for MVP Scope (Focus on Essential Functionalities):** Focus the libSQL integration plan on the essential database functionalities needed for the MVP in both MCP servers and the Swift client, deferring more advanced features like multi-device sync or advanced quantization to later phases.

## Revised Implementation Plan (Expanded libSQL Role)

### 1. libSQL for MCP Server-Specific State Persistence (Detailed)

*   **Embedded libSQL in Each MCP Server (Phase Servers):**  Each MCP server (Action Server, Experience Server, etc.) will embed a lightweight libSQL database instance for managing its *server-specific state*.
*   **Server-Specific State Schema (Flexible and Minimal):** Design a flexible and minimal libSQL schema for server-specific state, focusing on common use cases like caching and temporary data storage.  Example schema (generic cache and server state tables):

    ```sql
    -- Generic cache table for MCP servers (reusable across servers)
    CREATE TABLE IF NOT EXISTS server_cache (
        key TEXT PRIMARY KEY,  -- Cache key (e.g., URI, query parameters)
        value BLOB,          -- Cached data (can be text, JSON, binary)
        timestamp INTEGER     -- Timestamp of cache entry
    );

    -- Server-specific state table (example - Experience Server - customizable per server)
    CREATE TABLE IF NOT EXISTS experience_server_state (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sync_time INTEGER,
        # ... add server-specific state fields as needed ...
    );
    ```

*   **MCP Server SDK Utilities for libSQL Access:**  Provide utility functions and helper classes within the MCP Server SDK (Python, TypeScript, etc.) to simplify common libSQL operations within server code (as outlined in the previous `docs/3-implementation/state_management_patterns.md` update).

### 2. libSQL for Client-Side Data Storage (Swift Client Application)

*   **Embedded libSQL in Swift iOS Client:** Integrate the libSQL Swift SDK directly into the iOS client application. This embedded database will be used for:
    *   **Local Conversation History Persistence:** Storing the full conversation history (messages, user prompts, AI responses) locally on the user's device, enabling offline access to past conversations and a seamless user experience even without a network connection.
    *   **User Settings and Preferences:** Persisting user-specific settings, preferences, and application state locally on the device.
    *   **Client-Side Caching (Optional):**  Potentially using libSQL for client-side caching of resources or data fetched from MCP servers to improve app responsiveness and reduce network traffic (though HTTP caching mechanisms might be more appropriate for HTTP-based resources).
*   **Swift Client-Side Schema (Conversation History and User Data):** Design a libSQL schema within the Swift client application to efficiently store and manage:

    ```sql
    -- Client-Side Conversation History Table
    CREATE TABLE IF NOT EXISTS conversation_history (
        id TEXT PRIMARY KEY,  -- Unique conversation ID
        title TEXT,           -- Conversation title
        created_at INTEGER,   -- Creation timestamp
        updated_at INTEGER    -- Last updated timestamp
    );

    -- Client-Side Messages Table (within each conversation)
    CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT,
        role TEXT,             -- "user" or "assistant"
        content TEXT,          -- Message content
        timestamp INTEGER,     -- Message timestamp
        # ... other message-specific metadata ...
        FOREIGN KEY(conversation_id) REFERENCES conversation_history(id)
    );

    -- Client-Side User Settings Table
    CREATE TABLE IF NOT EXISTS user_settings (
        setting_name TEXT PRIMARY KEY,
        setting_value TEXT     -- Store setting values as TEXT or JSON
    );
    ```

*   **Swift Data Services for libSQL Access:** Create Swift data service classes or modules within the iOS client application to provide clean and abstracted APIs for accessing and manipulating data in the local libSQL database (e.g., `ConversationHistoryService`, `UserSettingsService`).

### 3. Vector Search (Qdrant for Global Knowledge, libSQL - Optional and Limited)

*   **Qdrant Remains the Primary Vector Database (Global Knowledge Base):**  **Qdrant remains the primary vector database solution for Choir**, used for the global knowledge base, semantic search in the Experience phase, and long-term storage of vector embeddings for messages and other content.  Qdrant's scalability, feature richness, and performance are essential for handling the large-scale vector search requirements of the Choir platform.
*   **libSQL Vector Search - *Optional* for Highly Localized Client-Side Features (Consider Sparingly):**  While libSQL offers vector search capabilities, **consider using libSQL vector search *sparingly* and only for *highly localized, client-side features* where a lightweight, embedded vector search is truly beneficial.**  For most vector search needs, especially those related to the global knowledge base and the Experience phase, Qdrant is the more appropriate and scalable solution.  Over-reliance on libSQL vector search could limit scalability and performance in the long run.

### 4. Synchronization Management (Simplified for MVP - Focus on Local Data, Cloud Sync - Future)

*   **No Multi-Device Sync for MVP (Defer):** Multi-device synchronization of conversation history or server state via Turso cloud sync is **explicitly deferred for the MVP**.
*   **Local Persistence as MVP Focus:** The primary goal of libSQL integration for the MVP is to provide **robust local persistence** in both MCP servers and the Swift client application.
*   **Cloud Backup and Sync via Turso - Future Roadmap Item:** Cloud backup and multi-device sync via Turso (or other cloud sync mechanisms) remain valuable **future roadmap items** to be considered in later phases, to enhance user data portability and accessibility across devices.

## Phased Implementation Approach (libSQL Integration - Expanded)

The phased approach to libSQL integration now encompasses both MCP servers and the Swift client:

### Phase 1: Core UX and Workflow (No Database Dependency - Current Focus)

- Continue developing the core UI and PostChain workflow, minimizing dependencies on databases for initial prototyping and UX validation.

### Phase 2: Basic libSQL Integration - Server-Side State Persistence (MVP Phase)

- Implement libSQL integration in MCP servers for server-specific state persistence and caching (as outlined in the previous plan).

### Phase 3: libSQL Integration - Swift Client-Side Persistence (MVP Phase)

- Integrate libSQL into the Swift client application for local conversation history and user settings persistence.
- Create Swift data services to manage client-side libSQL database access.

### Phase 4: (Optional) Vector Search Integration (MVP or Post-MVP - Re-evaluated)

- Re-evaluate the need for vector search in libSQL for the MVP. If deemed essential for a simplified MVP Experience phase, implement basic libSQL vector search.
- Otherwise, defer vector search implementation to post-MVP phases and plan for Qdrant integration for scalable vector search.

### Phase 5: (Future) Advanced libSQL Features and Cloud Sync

- In later phases, explore and implement more advanced libSQL/Turso features, including cloud sync, multi-device support, and potential performance optimizations.

