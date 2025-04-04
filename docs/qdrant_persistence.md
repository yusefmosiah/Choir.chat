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
*   **(For AI messages) phase_outputs`: Dictionary containing the outputs from each AEIOU-Y phase.
*   **(For AI messages) novelty_score`: Float score from Experience phase.
*   **(For AI messages) similarity_scores`: Dictionary or list of scores for priors.
*   **(For AI messages) cited_prior_ids`: List of IDs of messages cited as priors.
*   **(Optional) metadata`: Any other relevant metadata.

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

## 6. Implementation Checklist

**Phase 1: Database Layer (`database.py`)**

*   [ ] Implement `get_message_history(thread_id, limit)` function to fetch ordered messages from Qdrant.
*   [ ] Ensure `save_message` (or new `save_message_turn`) handles all required fields (`thread_id`, `role`, `timestamp`, `content`, AI-specific fields).
*   [ ] Verify Qdrant indexing on `thread_id` and `timestamp`.
*   [ ] Add unit tests for new/modified database functions (mocking Qdrant client).

**Phase 2: Workflow Integration (`langchain_workflow.py`)**

*   [ ] Remove `conversation_history_store` global dictionary and related logic.
*   [ ] Add code to call `db.get_message_history` at the start of `run_langchain_postchain_workflow`.
*   [ ] Implement conversion from Qdrant dictionary results to Langchain `BaseMessage` objects.
*   [ ] Add code to call `db.save_message_turn` for the incoming user message.
*   [ ] Add code to call `db.save_message_turn` for the final AI message after Yield phase.
*   [ ] Ensure loaded `message_history` is correctly passed through the workflow.
*   [ ] Add unit tests for workflow logic changes (mocking `database.py` functions).

**Phase 3: Utilities & API (`utils.py`, `routers/postchain.py`)**

*   [ ] Remove `save_state`, `recover_state`, `delete_state` from `utils.py`.
*   [ ] Remove `STATE_STORAGE_DIR` constant from `utils.py`.
*   [ ] Update `/langchain` endpoint to remove `recover_state` call.
*   [ ] Decide fate of `/recover` endpoint (remove or repurpose to query Qdrant).
*   [ ] Update `/recover` implementation and response model if repurposed.
*   [ ] Add/update tests for API endpoint changes.

**Phase 4: Data Models & Testing**

*   [ ] Review and update Pydantic models (`schemas/state.py`, `models/api.py`) if necessary.
*   [ ] Define and document the structure of message points stored in Qdrant.
*   [ ] Perform integration testing: Run the `/langchain` endpoint against a real (or test instance) Qdrant database.
*   [ ] Verify that conversation history is correctly loaded across multiple requests to the same `thread_id`.
*   [ ] Verify that user and AI messages are correctly persisted in Qdrant.
*   [ ] Test edge cases (new thread, empty history, history limit).

## 7. Testing Strategy

*   **Unit Tests:** Mock the `DatabaseClient` in `langchain_workflow.py` tests to verify history loading/saving calls are made correctly. Test the new `database.py` functions by mocking the `QdrantClient`.
*   **Integration Tests:** Set up a test Qdrant instance (can be local Docker). Write tests that call the `/langchain` API endpoint multiple times for the same `thread_id` and assert that the conversation context is correctly maintained by verifying the history loaded/passed in subsequent calls. Check the Qdrant database directly to confirm messages are saved correctly.

## 8. Conclusion

Migrating state persistence to Qdrant is essential for the stability, scalability, and deployability of the Choir API. By centralizing conversation history in Qdrant and removing the flawed file/memory-based methods, the backend will have a reliable foundation for managing PostChain state. This change aligns with the MVP's focus on leveraging Qdrant as the core data layer.
