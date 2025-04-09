# State Management Patterns in Choir (Qdrant-Sui MVP)

VERSION state_management_patterns: 8.0 (Qdrant-Sui MVP Focus)

## Overview

State management is crucial for the Choir platform. In the Qdrant-Sui MVP, the primary focus is on managing state within the central Python API and persisting core data within Qdrant. This document outlines the state management patterns specific to this MVP architecture. Client-side caching and distributed server state are deferred post-MVP.

## State Management in the Qdrant-Sui MVP

The state is primarily managed in two locations:

1.  **Python API (In-Memory during Request Processing):** The FastAPI application manages the *transient state* of a single PostChain execution cycle for a given user request.
2.  **Qdrant (Persistent State):** Qdrant serves as the **persistent source of truth** for all core data entities required for the AI workflow and the reward system.

## 1. Python API: Orchestration & Transient State

*   **Role:** The Python API acts as the central orchestrator. For each incoming user request, it manages the flow through the PostChain (AEIOU-Y) phases implemented in `langchain_workflow.py`.
*   **Transient State Handling:**
    *   **Workflow Context:** During a single PostChain cycle triggered by a user message, the API holds the intermediate outputs from each phase (Action, Experience, etc.) in memory. This context (including text outputs, calculated scores, potential citations) is passed sequentially from one phase function to the next within the `langchain_workflow.py`.
    *   **Stateless Between Requests:** The API itself aims to be largely stateless *between* distinct user requests/PostChain cycles. All necessary persistent state is fetched from or saved to Qdrant at the beginning or end of the request processing cycle.
    *   **Concurrency:** FastAPI and Python's `asyncio` handle concurrent user requests. Care must be taken within the workflow logic if shared resources (beyond Qdrant/Sui services which handle their own concurrency) are accessed, but the primary state (conversation history, memory) is managed via Qdrant, pushing concurrency control largely to the database/service layer.

## 2. Qdrant: Persistent State Management

*   **Role:** Qdrant is the **authoritative persistent store** for the MVP.
*   **Managed Entities:**
    *   **`users`:** Maps Sui addresses to internal user IDs. Persistent user identity link.
    *   **`chat_threads`:** Stores metadata about conversation threads. Persistent thread context.
    *   **`choir` (Messages):** Stores the core conversational turns (user prompts, final AI responses). Critically, AI responses embed the outputs from *all* internal PostChain phases (`phase_outputs` dictionary), novelty/similarity scores, and citation links (`cited_prior_ids`). This collection is the persistent record of the conversation history and the primary input for reward calculations.
    *   **`intention_memory`:** Persists user-specific goals and preferences across multiple turns and sessions, queryable by the Intention phase. Filtered by `user_id`.
    *   **`observation_memory`:** Persists thread-specific concepts and summaries across multiple turns and sessions, queryable by the Observation phase (and potentially Experience). Filtered by `thread_id`.
*   **Data Integrity & Access:** The Python API (via `database.py`) is responsible for all CRUD operations on Qdrant, ensuring data is structured according to the defined schemas (using Pydantic for validation) before persistence. Access control for user-specific memory (`intention_memory`) is enforced by filtering queries based on the authenticated `user_id`.

## 3. Client (SwiftUI): UI State & Keychain

*   **Role:** Manages the user interface state and secure key storage.
*   **State Handled:**
    *   **UI State:** Current view, input field content, display state of messages and phases (fetched from API).
    *   **Sui Private Key:** Securely stored in the device Keychain. Used for signing authentication messages.
### Update (2025-04-09): iOS Client Local Persistence

As of April 9, 2025, the iOS client **replaced previous persistence methods** (such as SwiftData) with a **local file-based JSON storage** approach:

- Each thread and its associated messages are saved as a **single JSON file** on device storage.
- This improves transparency, simplifies debugging, and enhances offline access.
- The files are managed by the app's `ThreadPersistenceService`, which handles reading/writing JSON representations of threads.
- This approach fully replaces previous CoreData/SwiftData-based persistence.

This change aligns with a simplified, file-centric architecture for local data management on iOS.
*   **No Persistent App Data (MVP):** For the MVP, the client **does not** maintain its own persistent cache of conversation history. It fetches conversation data from the API as needed for display. Offline access is deferred post-MVP.

## State Flow Example (Single Turn)

1.  User sends message via SwiftUI Client. Client signs request hash with Sui Key.
2.  Python API receives request, verifies signature, maps Sui Address to Qdrant User ID (`users` collection). Fetches relevant thread context (`chat_threads`, recent messages from `choir`).
3.  API initiates PostChain workflow (`langchain_workflow.py`) with user message and thread context.
4.  **Phase Execution (Transient State):**
    *   Action phase runs.
    *   Experience phase runs: Queries `choir` (Qdrant) for priors, calculates scores.
    *   Intention phase runs: Queries/updates `intention_memory` (Qdrant).
    *   Observation phase runs: Queries/updates `observation_memory` (Qdrant).
    *   Understanding phase runs: May trigger deletes in `intention_memory`/`observation_memory` (Qdrant).
    *   Yield phase runs: Bundles all phase outputs.
    *   *(Intermediate outputs are held in memory by the API/workflow runner during this sequence)*.
5.  API receives final bundled AI response data from Yield.
6.  API **persists** the new AI message (with embedded `phase_outputs`, scores, citations) to the `choir` collection in Qdrant.
7.  API triggers the Sui Service with relevant data (message ID, author ID, prior IDs, scores) from the persisted Qdrant entry.
8.  API streams phase outputs (potentially fetched back from the newly saved Qdrant entry or held from step 4) back to the Client via SSE.
9.  Client updates UI state based on SSE stream.

## Conclusion (MVP Focus)

The Qdrant-Sui MVP employs a pragmatic state management strategy. Persistent state critical for the AI workflow and reward system resides centrally in Qdrant, managed by the Python API. The API handles transient state during request processing. The client manages UI state and the user's private key. This approach minimizes complexity for the MVP, allowing focus on validating the core Qdrant-Sui data flow and reward mechanism.
