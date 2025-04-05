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

*   `id`: Unique UUID for the message point (can be generated on save).
*   `thread_id`: UUID linking the message to a specific conversation thread. (Crucial for retrieval).
*   `role`: String indicating 'user' or 'assistant'.
*   `content`: The primary text content of the message.
*   `timestamp`: ISO 8601 timestamp for ordering.
*   `vector`: Embedding of the `content` (handled by `database.py`).
*   **(For AI messages) phase_outputs**: Dictionary containing the outputs from each AEIOU-Y phase.
*   **(For AI messages) novelty_score**: Float score from Experience phase.
*   **(For AI messages) similarity_scores**: Dictionary or list of scores for priors.
*   **(For AI messages) cited_prior_ids**: List of IDs of messages cited as priors.
*   **(Optional) metadata**: Any other relevant metadata.

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
2.  **Modify/Enhance `save_message(data: Dict[str, Any])` (or create `save_message_turn`)**:
    *   Ensure the function accepts and saves all necessary fields: `thread_id`, `role`, `timestamp`, `content`, and potentially `phase_outputs`, scores, `cited_prior_ids` for AI messages.
    *   Generate embedding for `content` if not provided.
    *   Upsert the point into the `choir` collection.

### 5.2. Modify `api/app/postchain/langchain_workflow.py`

1.  **Remove `conversation_history_store`:** Delete the global dictionary and all logic that reads from or writes to it.
2.  **Load History at Start:**
    *   Inside `run_langchain_postchain_workflow`, before the workflow starts:
        *   Instantiate `DatabaseClient`.
        *   Call `db.get_message_history(thread_id)` to fetch the history from Qdrant.
        *   Convert the retrieved dictionaries into Langchain `BaseMessage` objects (`HumanMessage`, `AIMessage`). Handle potential errors if history is empty. Assign this list to `message_history`.
3.  **Save User Message:**
    *   Immediately after receiving the `query` and before starting the phase loop:
        *   Construct a user message dictionary containing `thread_id`, `role='user'`, `content=query`, `timestamp`.
        *   Call `db.save_message_turn()` (or adapted `save_message`) to persist the user message.
4.  **Save AI Message:**
    *   After the Yield phase completes and returns the final AI message structure (including `content`, `phase_outputs`, scores, citations):
        *   Construct the AI message dictionary containing `thread_id`, `role='assistant'`, `timestamp`, and all relevant data from the Yield output.
        *   Call `db.save_message_turn()` (or adapted `save_message`) to persist the complete AI message turn.
5.  **Context Passing:** Ensure the `message_history` loaded from Qdrant is correctly passed into the phase functions (`run_action_phase`, etc.).

### 5.3. Modify/Remove `api/app/postchain/utils.py`

1.  **Remove File-Based Functions:** Delete `save_state`, `recover_state`, `delete_state`, and the `STATE_STORAGE_DIR` constant.
2.  **Update `format_stream_event` (If Necessary):** Review if this function relies on the old state structure; adapt if needed, though it primarily uses `current_phase` and `phase_state` which might still be managed transiently within the workflow runner.

### 5.4. Modify API Endpoints (`api/app/routers/postchain.py`)

1.  **`/langchain` Endpoint:**
    *   Remove the call to `recover_state`.
    *   The loading of `message_history` will now happen inside `run_langchain_postchain_workflow` as described in step 5.2.
2.  **`/recover` Endpoint:**
    *   This endpoint's purpose needs re-evaluation. It no longer recovers state from files.
    *   **Option A (Remove):** If its only purpose was file recovery, remove it.
    *   **Option B (Repurpose):** Change it to query Qdrant (via `database.py`) to check if a `thread_id` exists and return basic metadata (e.g., message count, last activity timestamp). Update the response model accordingly.

### 5.5. Review Data Models

1.  **`api/app/postchain/schemas/state.py`:** The `PostChainState` model might become less relevant if state is primarily managed via Qdrant message history. Review its usage. The `SearchResult` models remain relevant.
2.  **`api/app/models/api.py`:** Ensure API request/response models align with the changes (e.g., the `/recover` endpoint response).
3.  **Internal Message Structure:** Define clearly (perhaps using Pydantic) the structure of the message dictionary saved to Qdrant, especially for AI messages containing phase outputs and scores.

# Qdrant Persistence Migration Progress (as of 2025-04-04)

## Phase 1: Database Layer (`database.py`)
- [x] Implemented `get_message_history(thread_id, limit)`
- [x] Enhanced `save_message` to handle all required fields
- [x] Qdrant indexing assumed, **not explicitly verified**
- [ ] Unit tests for database functions **(missing)**

## Phase 2: Workflow Integration (`langchain_workflow.py`)
- [x] Removed `conversation_history_store`
- [x] Loads history from Qdrant at start
- [x] Saves user message immediately
- [x] Saves final AI message after Yield phase
- [x] Passes loaded history through workflow
- [ ] Unit tests for workflow changes **(missing)**

## Phase 3: Utilities & API (`utils.py`, `routers/postchain.py`)
- [x] Removed file-based persistence
- [x] Updated `/langchain` endpoint
- [x] Removed `/recover` endpoint
- [ ] Tests for API changes **(missing)**

## Phase 4: Data Models & Testing
- [x] Reviewed Pydantic models
- [ ] Documented message schema in Qdrant **(partial)**
- [ ] Integration testing of `/langchain` endpoint with Qdrant **(missing)**
- [ ] Verify persistence across requests **(partial)**
- [ ] Test edge cases (new thread, empty history, limits) **(missing)**

## iOS Client Integration
- [x] Created `ChoirAPIClient` with `fetchUserThreads`
- [x] Fetches threads on app launch using wallet Sui address
- [x] **Wallet async loading on app launch**
- [x] **Fetch threads *after* wallet loads**
- [ ] **Fetch messages for each thread** **(in progress)**
- [ ] **Display fetched messages in UI** **(missing)**
- [ ] **Save new threads/messages via API** **(partial - thread creation works)**
- [ ] **Autosave new messages during chat** **(missing)**
- [ ] **Handle empty state, errors, loading indicators** **(missing)**

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
- [ ] Message persistence per thread
- [x] Autosave new messages (handled server-side in workflow)
- [ ] Tests

### iOS Client
- [x] Async wallet loading
- [x] Authenticate user, get UUID
- [x] Fetch threads using UUID (confirmed working)
- [ ] Fetch messages per thread
- [x] Autosave new messages (handled server-side)
- [ ] Error handling, loading states
*   **Unit Tests:** Mock the `DatabaseClient` in `langchain_workflow.py` tests to verify history loading/saving calls are made correctly. Test the new `database.py` functions by mocking the `QdrantClient`.
*   **Integration Tests:** Set up a test Qdrant instance (can be local Docker). Write tests that call the `/langchain` API endpoint multiple times for the same `thread_id` and assert that the conversation context is correctly maintained by verifying the history loaded/passed in subsequent calls. Check the Qdrant database directly to confirm messages are saved correctly.

## 8. Conclusion

Migrating state persistence to Qdrant is essential for the stability, scalability, and deployability of the Choir API. By centralizing conversation history in Qdrant and removing the flawed file/memory-based methods, the backend will have a reliable foundation for managing PostChain state. This change aligns with the MVP's focus on leveraging Qdrant as the core data layer.
