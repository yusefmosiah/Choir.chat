# State Management Patterns in Choir MCP Architecture

## Overview

State management is a critical aspect of building robust and scalable AI systems, especially in a distributed architecture like Choir's Model Context Protocol (MCP) implementation. This document outlines the key state management patterns employed within the Choir MCP architecture, focusing on how state is handled in MCP servers and the Host application.

## Key State Management Challenges in Distributed AI Systems

In distributed AI systems like Choir, state management presents unique challenges:

*   **Concurrency:** Multiple clients and servers may interact concurrently, requiring mechanisms to manage shared state and prevent race conditions.
*   **Scalability:** State management solutions must scale efficiently as the number of users, conversations, and servers grows.
*   **Persistence:**  State often needs to be persisted across sessions and server restarts to maintain conversation history and system context.
*   **Data Integrity:** Ensuring data consistency and integrity across distributed components is crucial, especially for critical state information.
*   **Performance:** State management operations should be performant and minimize latency to maintain a responsive user experience.

## State Management in MCP Servers (Phase Servers)

MCP servers in Choir are designed to be modular and relatively stateless with respect to the *global conversation state*. However, they do manage **server-specific state** for performance optimization and internal operations.

### Server-Specific State: Caching and Local Persistence

*   **Purpose:**  MCP servers utilize server-specific state primarily for **caching** frequently accessed data and **local persistence** of temporary or server-specific information.
*   **Caching Strategies:**
    *   **In-Memory Caching:** Servers can use in-memory caches (e.g., dictionaries, hash maps) to store parsed context, API responses, or database query results that are likely to be reused within the same turn or across rapid consecutive turns.
    *   **Cache Invalidation:**  Implement cache invalidation strategies (e.g., time-based expiration, event-driven invalidation) to ensure cached data remains reasonably fresh and consistent.
*   **Local Persistence with libSQL/Turso:**
    *   **Purpose:** For server-specific state that needs to persist across server restarts or for larger datasets that don't fit in memory, servers can leverage **libSQL/Turso for local persistence.**
    *   **Use Cases:**  Caching large resources segments, storing server-local indexes or data structures, logging server-specific events.
    *   **Embedded libSQL:**  Each MCP server can embed a lightweight libSQL database instance for local persistence, ensuring data is stored close to the compute.
    *   **Turso Sync (Optional):**  For certain server-specific state, you *could* potentially leverage Turso's cloud sync capabilities for backup or limited state sharing between server instances (though this is less common for server-specific state, which is typically meant to be isolated).
*   **Stateless with Respect to Global Conversation State:**  Crucially, MCP servers are designed to be **stateless with respect to the *global conversation state***. They do not persistently store or manage the overall conversation history. This responsibility is delegated to the Host application.

### Accessing the "Conversation State Resource" from Servers

MCP servers access the global conversation state through the **"conversation state resource"** provided by the Host application.

*   **Pull-Based Resource Fetching:** Servers use the `exchange.readResource(ReadResourceRequest)` method (provided by the MCP Client SDK) to *pull* the "conversation state resource" from the Host *when needed*.
*   **Resource URI as Context Pointer:** The Host application provides the URI of the "conversation state resource" (e.g., `conversation://current-history`) to servers in each `callTool` request (typically as a tool argument).
*   **On-Demand Fetching:** Servers only fetch the resource content *when their tool logic requires access to the conversation state*. They don't need to maintain a persistent, live connection to the conversation state.
*   **Efficient Resource Access:**  The MCP resource mechanism is designed to be relatively efficient for data transfer, especially for text-based resources like conversation histories.

### Host Application Management of the "Conversation State Resource"

The Host application (Python API) plays a central role in managing the **"conversation state resource"**:

*   **Authoritative Source of Truth:** The Host application is the **single source of truth** for the global conversation state. It maintains the canonical version of the conversation history, user messages, AI responses, and other relevant data.
*   **Dynamic Resource Updates:** The Host application is responsible for **dynamically updating the "conversation state resource"** as the conversation progresses. This includes:
    *   Adding new user messages.
    *   Adding AI responses from each PostChain phase.
    *   Updating conversation metadata (e.g., timestamps, user intents, annotations).
*   **Exposing the Resource via URI:** The Host application exposes the "conversation state resource" via a well-defined URI (e.g., `conversation://current-history`) that MCP servers can use to access it.
*   **Potential Persistence of "Conversation State Resource" (Host-Side):**  For persistence of the *global conversation history* across client sessions, the Host application *can* choose to persist the "conversation state resource" data in a client-side database (like libSQL/Turso embedded in the Host application) or in a separate centralized database.  However, for the MVP, in-memory management of the "conversation state resource" might be sufficient.

### Concurrency Control and Thread Safety (Brief Overview)

In a concurrent MCP system, both the Host application and MCP servers need to consider concurrency control and thread safety:

*   **Host Application (Concurrent Workflow Orchestration):** The Host application, as the orchestrator of concurrent PostChain workflows, needs to be thread-safe when managing the "conversation state resource" and handling concurrent requests from users and servers.  Python's `asyncio` and appropriate locking mechanisms can be used for concurrency control in the Host application.
*   **MCP Servers (Concurrent Request Handling):** MCP servers, when handling concurrent requests from the Host, need to ensure thread safety in their internal state management and tool implementations.  Asynchronous programming and thread-safe data structures are key for building concurrent MCP servers.

## (Optional) Code Examples (Conceptual Python)

**(Conceptual Example - Server-Side Caching in Python MCP Server):**

```python
class ExperienceServer(Server):
    def __init__(self, ...):
        super().__init__(...)
        self.context_cache = {}  # In-memory cache for conversation context

    @app.call_tool("get_enriched_context")
    async def get_enriched_context(self, exchange: ServerExchange, arguments: dict):
        conversation_history_uri = arguments.get("conversation_history_uri")

        # Check if context is in cache
        if conversation_history_uri in self.context_cache:
            conversation_history = self.context_cache[conversation_history_uri]
            print("Using cached context for:", conversation_history_uri)
        else:
            # Fetch context resource from Host
            read_resource_request = mcp_types.ReadResourceRequest(uri=conversation_history_uri)
            read_resource_result = await exchange.read_resource(read_resource_request)
            conversation_history = read_resource_result.contents[0].text
            # Cache the fetched context
            self.context_cache[conversation_history_uri] = conversation_history
            print("Fetched and cached context for:", conversation_history_uri)

        # ... (rest of tool logic using conversation_history) ...
Use code with caution.
Markdown
(Conceptual Example - Host-Side "Conversation State Resource" Update in Python MCP Client):

class ChoirHostClient(Client):
    def __init__(self, ...):
        super().__init__(...)
        self.conversation_history = [] # In-memory list for conversation history

    async def handle_user_prompt(self, user_prompt):
        self.conversation_history.append({"role": "user", "content": user_prompt})
        await self.update_conversation_resource() # Update the resource

        # ... (call PostChain phases) ...

    async def update_conversation_resource(self):
        # Update the "conversation history resource" content
        self.setResourceContent(
            "conversation://current-history",
            mimeType="application/json",
            text=json.dumps(self.conversation_history) # Serialize to JSON
        )
