# Implementing Qdrant Persistence for PostChain State

VERSION: 1.0 (Qdrant-Sui MVP Focus)
DATE: 2025-03-28

## 1. Overview

This document details the necessary steps to replace the current non-persistent state management (in-memory dictionary and local JSON files) in the Choir API backend with a robust solution using Qdrant. The goal is to ensure conversation history and relevant state are reliably persisted and retrieved for the PostChain workflow.

## 2. Problem Statement

The current implementation in `api/app/postchain/langchain_workflow.py` and `api/app/postchain/utils.py` relies on:

*   An in-memory dictionary (`conversation_history_store`) for message history during workflow execution.
*   Local JSON files (`thread_state/` directory via `save_state`, `recover_state`) for attempting persistence between requests.

This approach has critical flaws:

*   **Data Loss:** In-memory state is lost on API restarts or crashes.
*   **Scalability Issues:** Cannot handle multiple API instances or significant load.
*   **Deployment Complexity:** Local file storage is unsuitable for containerized or serverless deployments.
*   **Inconsistency:** Prone to race conditions and data corruption.

## 3. Proposed Solution: Qdrant Persistence

Leverage the existing Qdrant integration (`api/app/database.py`) as the **single source of truth** for persistent conversation state.

*   **Message History:** Store all user prompts and final AI responses (including embedded phase outputs, scores, citations) as individual points in the Qdrant `choir` collection (or a dedicated `messages` collection if preferred).
*   **State Retrieval:** Load the relevant message history from Qdrant at the beginning of each PostChain workflow execution based on the `thread_id`.
*   **State Saving:** Save new user messages and the final AI message structure to Qdrant upon creation/completion.
*   **Deprecate Old Methods:** Remove the in-memory dictionary and local file-based utility functions.

## 4. Qdrant Schema Considerations (`choir` Collection)

Each point in the `choir` collection representing a message turn should include fields like:

*   `id`: Unique UUID for the turn record (generated on save).
*   `thread_id`: UUID linking the turn to a specific conversation thread.
*   `user_query`: The original text input from the user for this turn.
*   `content`: The final AI response content (e.g., from Yield phase).
*   `timestamp`: ISO 8601 timestamp for ordering the turn.
*   `vector`: Embedding of the AI `content`.
*   `phase_outputs`: Dictionary containing the outputs from each AEIOU-Y phase.
*   `novelty_score`: Float score (placeholder for now).
*   `similarity_scores`: Dictionary or list of scores (placeholder for now).
*   `cited_prior_ids`: List of IDs of messages cited as priors (placeholder for now).
*   `metadata`: Dictionary containing model info, etc.
*   **(Removed)** `role`: No longer needed as the record represents a full turn.

**Indexing:** Ensure `thread_id` and `timestamp` are indexed in Qdrant for efficient filtering and sorting.

## 5. Implementation Steps

### 5.1. Modify `api/app/database.py`

1.  **Add `get_message_history(thread_id: str, limit: int = 50) -> List[Dict[str, Any]]`:**
    *   Query the `choir` collection.
    *   Filter points by `thread_id`.
    *   Sort results by `timestamp` (ascending).
    *   Limit the number of messages retrieved (e.g., last 50 turns).
    *   Return the list of message payloads (dictionaries).
    *   *Consider adding pagination (`before` timestamp) for very long histories.*
2.  **Modify/Enhance `save_message(data: Dict[str, Any])`**:
    *   [x] Accepts and saves all necessary fields for a turn: `thread_id`, `timestamp`, AI `content`, `user_query`, `vector`, `phase_outputs`, `metadata`, placeholders for scores/citations.
    *   [x] Handles missing `vector` by requiring it in the input `data`.
    *   [x] Upserts the single turn point into the `choir` (or `messages`) collection.

### 5.2. Modify `api/app/postchain/langchain_workflow.py`

1.  **Remove `conversation_history_store`:** Delete the global dictionary and all logic that reads from or writes to it.
2.  **Load History at Start:**
    *   [x] Inside `run_langchain_postchain_workflow`, before the workflow starts:
        *   [x] Instantiates `DatabaseClient`.
        *   [x] Calls `db.get_message_history(thread_id)` to fetch turn history.
        *   [x] Converts retrieved turn dictionaries into alternating Langchain `HumanMessage` (from `user_query`) and `AIMessage` (from `content`) for context.
3.  **Save Turn Record:**
    *   [x] **Removed** separate user message saving.
    *   [x] After the Yield phase completes:
        *   [x] Constructs a **single turn payload** dictionary containing `thread_id`, `timestamp`, `user_query`, AI `content`, `phase_outputs`, `vector`, `metadata`.
        *   [x] Calls `db.save_message()` **once** to persist the complete turn record.
4.  **Context Passing:**
    *   [x] Passes the reconstructed `current_messages` (history + current query) into the `_run_single_phase` helper.
    *   [x] Appends the AI response from each phase to `current_messages` to provide context for the *next* phase.

### 5.3. Modify/Remove `api/app/postchain/utils.py`

1.  **Remove File-Based Functions:** Delete `save_state`, `recover_state`, `delete_state`, and the `STATE_STORAGE_DIR` constant.
2.  **`format_stream_event`:** [x] Removed usage; workflow now yields simple dictionaries directly.

### 5.4. Modify API Endpoints (`api/app/routers/postchain.py`)

1.  **`/langchain` Endpoint:**
    *   [x] Removed call to `recover_state`.
    *   [x] History loading happens inside `run_langchain_postchain_workflow`.
2.  **`/recover` Endpoint:**
    *   This endpoint's purpose needs re-evaluation. It no longer recovers state from files.
    *   **Option A (Remove):** If its only purpose was file recovery, remove it.
    *   **Option B (Repurpose):** Change it to query Qdrant (via `database.py`) to check if a `thread_id` exists and return basic metadata (e.g., message count, last activity timestamp). Update the response model accordingly.

### 5.5. Review Data Models

1.  **`api/app/postchain/schemas/state.py`:** The `PostChainState` model might become less relevant if state is primarily managed via Qdrant message history. Review its usage. The `SearchResult` models remain relevant.
2.  **`api/app/models/api.py`:** [x] Updated/Renamed Pydantic models (`TurnResponseModel`, `TurnsDataModel`, `TurnsAPIResponseModel`) to reflect the turn-based structure (added `user_query`, removed `role`).
3.  **Turn Record Structure:** [x] Defined clearly in `TurnResponseModel` and handled in `database.py` and `langchain_workflow.py`.

# Qdrant Persistence Migration Progress (as of 2025-04-06 - Turn-Based Model)

## Phase 1: Database Layer (`database.py`)
- [x] Implemented `get_message_history(thread_id, limit)`
- [x] Enhanced `save_message` to handle turn record fields (`user_query`, no `role`).
- [x] Qdrant indexing assumed for `thread_id`, `timestamp`.
- [ ] Unit tests for database functions **(missing)**

## Phase 2: Workflow Integration (`langchain_workflow.py`)
- [x] Removed `conversation_history_store`
- [x] Loads history from Qdrant at start
- [x] Saves **single turn record** after Yield phase (includes user query, AI content, phases).
- [x] Passes reconstructed history + current query to phases.
- [x] Refactored workflow using `_run_single_phase` helper.
- [ ] Unit tests for workflow changes **(missing)**

## Phase 3: Utilities & API (`utils.py`, `routers/postchain.py`)
- [x] Removed file-based persistence
- [x] Updated `/langchain` endpoint
- [x] `/recover` endpoint removed.
- [ ] Tests for API changes **(missing)**

## Phase 4: Data Models & Testing
- [x] Updated Pydantic models for turn-based structure.
- [x] Documented turn schema in Qdrant (via Pydantic model and DB function docstring).
- [ ] Integration testing of `/langchain` endpoint with Qdrant **(missing)**
- [x] Verified persistence across requests (implicitly via successful history loading).
- [ ] Test edge cases (new thread, empty history, limits) **(missing)**

## iOS Client Integration
- [x] Created `ChoirAPIClient` with `fetchUserThreads`
- [x] Fetches threads on app launch using wallet Sui address
- [x] **Wallet async loading on app launch**
- [x] **Fetch threads *after* wallet loads**
- [x] **Fetch turns for selected thread**
- [x] **Reconstruct and display user/AI messages in UI from turns**
- [x] **Save new threads via API**
- [x] **Autosave new turns during chat** (handled by workflow)
- [x] **Handle empty state, errors, loading indicators** (implemented in `ChoirThreadDetailView`)

## 7. Testing Strategy
## User Authentication & Initialization

- [ ] Implement challenge-response authentication:
  - Backend generates a random challenge string.
  - User signs the challenge with their Sui private key.
  - User sends signature + public key (Sui address).
  - Backend verifies the signature.
- [ ] Map Sui address to a UUID for Qdrant:
  - Hash the Sui address or generate a UUID.
  - Use UUID as Qdrant point ID.
- [ ] Create user record in Qdrant if new.
- [ ] Add `/auth` or `/login` endpoint:
  - Accepts public key + signature.
  - Verifies ownership.
  - Returns user UUID.
- [ ] Update iOS app:
  - Request challenge.
  - Sign challenge.
  - Send signature + public key.
  - Receive user UUID for API calls.

## Updated Progress (as of 2025-04-04)

### User Authentication & Initialization
- [x] Challenge-response endpoints implemented
- [x] UUID mapping and user creation in Qdrant
- [x] UUID returned to client
- [x] Backend expects UUIDs for user endpoints
- [x] iOS app uses UUID for API calls
- [ ] Real signature verification (mocked for now)
- [ ] Full login flow in iOS (partial, mocked)

### Backend Persistence
- [x] Thread persistence by UUID
- [x] User fetch by UUID works (confirmed)
- [x] Turn persistence per thread
- [x] Autosave new turns (handled server-side in workflow)
- [ ] Tests

### iOS Client
- [x] Async wallet loading
- [x] Authenticate user, get UUID
- [x] Fetch threads using UUID (confirmed working)
- [x] Fetch turns per thread
- [x] Autosave new turns (handled server-side)
- [x] Error handling, loading states (implemented)
*   **Unit Tests:** Mock the `DatabaseClient` in `langchain_workflow.py` tests to verify history loading/saving calls are made correctly. Test the new `database.py` functions by mocking the `QdrantClient`.
*   **Integration Tests:** Set up a test Qdrant instance (can be local Docker). Write tests that call the `/langchain` API endpoint multiple times for the same `thread_id` and assert that the conversation context is correctly maintained by verifying the history loaded/passed in subsequent calls. Check the Qdrant database directly to confirm messages are saved correctly.

## 8. Conclusion

Migrating state persistence to Qdrant is essential for the stability, scalability, and deployability of the Choir API. By centralizing conversation history in Qdrant and removing the flawed file/memory-based methods, the backend will have a reliable foundation for managing PostChain state. This change aligns with the MVP's focus on leveraging Qdrant as the core data layer.
