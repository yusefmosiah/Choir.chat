<!-- Okay, this is a significant and well-defined architectural shift towards making Qdrant the core engine for contextual memory and retrieval within the PostChain workflow. Let's break down how to structure this refactoring effort and create a guide for an AI coding agent.

Core Idea: Transition from Qdrant as an optional "tool" to an integral, programmatic component of the PostChain, driving context retrieval in specific phases and ensuring persistent message history.

High-Level Plan:

Database Layer (database.py): Enhance Qdrant interaction capabilities.

Workflow Logic (postchain_alpha.py): Create the new workflow integrating programmatic Qdrant calls.

API Layer (routers/postchain.py, routers/threads.py): Adapt API endpoints to use the new workflow and handle Qdrant-based history.

Tool Removal: Deprecate and remove the Qdrant Langchain tool.

Client Considerations: Outline necessary adjustments for the Swift client.

Here's a breakdown of the suggested guide structure and content for prompting an AI coding agent:

Guide for AI Coding Agent: Integrating Qdrant Programmatically into PostChain (Qdrant-Sui MVP)

Goal: Refactor the api backend to deeply integrate Qdrant for message persistence and semantic search within a new PostChain workflow (postchain_alpha.py), replacing the existing langchain_workflow.py and removing the Qdrant Langchain tool.

Phase 1: Enhance Database Layer (app/database.py)

Add Embedding Functionality:

Implement or integrate an asynchronous function get_embedding(text: str) -> List[float] using the configured Config.EMBEDDING_MODEL (likely via langchain_openai.OpenAIEmbeddings or similar). Ensure it handles potential API errors gracefully.

Refine save_message:

Modify save_message(data: Dict[str, Any]) to always expect a vector field.

Ensure it saves essential fields to the Config.MESSAGES_COLLECTION: user_id, thread_id, role (user/assistant), content, vector, timestamp, phase_outputs (dictionary to store intermediate phase results), cited_prior_ids (list of message IDs cited in the final response).

Return the generated point_id (message ID).

Implement Filtered Similarity Search:

Create a new asynchronous function search_similar_filtered(collection: str, query_vector: List[float], filter_conditions: models.Filter, limit: int) -> List[Dict[str, Any]].

This function should perform a Qdrant search using both query_vector and filter_conditions.

The filter_conditions will be used for phase-specific searches (e.g., filtering by user_id or thread_id). Use qdrant_client.models.Filter and conditions like FieldCondition, MatchValue.

Ensure the results include id, payload (content, role, user_id, thread_id, timestamp), and score.

Implement History Fetching:

Create an asynchronous function get_thread_history(thread_id: str, limit: int = 50, before_timestamp: Optional[str] = None) -> List[Dict[str, Any]].

This function should retrieve messages from the Config.MESSAGES_COLLECTION filtered by thread_id.

It should sort results by timestamp (descending).

Implement pagination using before_timestamp if needed for longer histories.

Return messages including id, role, content, timestamp, user_id, thread_id, phase_outputs, cited_prior_ids.

Phase 2: Create New Workflow Logic (app/postchain/postchain_alpha.py)

Create postchain_alpha.py: This file will contain the new workflow logic.

Define Workflow Function Signature:

async def run_postchain_alpha_workflow(query: str, thread_id: str, user_id: str, config: Config, db: DatabaseClient) -> AsyncIterator[Dict[str, Any]]:

Initialization Steps (Inside the workflow function):

Fetch History: Call db.get_thread_history(thread_id) to retrieve the conversation history. Convert this into Langchain BaseMessage objects if needed for LLM calls, but keep the raw Qdrant message dictionaries (with IDs and scores) available.

Embed User Query: Asynchronously call db.get_embedding(query).

Save User Message: Call db.save_message with user query details (user_id, thread_id, role='user', content=query, vector, timestamp, etc.). Store the returned user_message_id.

Initial Similarity Search (for Experience): Asynchronously call db.search_similar_filtered using the user query vector. Search the Config.MESSAGES_COLLECTION. No filter initially (search all messages), limit to ~20 results. Store these results as experience_priors.

Prepare Initial Messages for LLM: Combine fetched history and the new user query into a list suitable for the first LLM call (Action phase).

Sequential Phase Execution:

Action Phase:

Input: LLM message list.

Process: Call LLM (using langchain_utils.get_base_model and ainvoke).

Output: action_response (AIMessage).

State Update: Add action_response to the in-memory message list for subsequent phases. Yield event.

Experience Phase:

Input: experience_priors (from initialization step).

Process: No LLM call. Format the experience_priors into a readable string or structure (e.g., list of summaries with scores).

Output: experience_output (dictionary containing formatted priors, potentially the raw list too).

State Update: Add experience_output (or a reference) to the context for subsequent phases (perhaps in additional_kwargs of a placeholder message). Yield event including the structured priors.

Intention Phase:

Input: LLM message list (including Action output), user query vector.

Process:

Perform Qdrant search: Call db.search_similar_filtered using the user query vector, but add a filter_conditions to match user_id. Limit results.

Call LLM with history and the user-filtered search results appended to the prompt/context.

Output: intention_response (AIMessage).

State Update: Add intention_response to the in-memory message list. Yield event.

Observation Phase:

Input: LLM message list (including Intention output), user query vector.

Process:

Perform Qdrant search: Call db.search_similar_filtered using the user query vector, but add a filter_conditions to match thread_id. Limit results.

Call LLM with history and the thread-filtered search results appended to the prompt/context.

Output: observation_response (AIMessage).

State Update: Add observation_response to the in-memory message list. Yield event.

Understanding Phase:

Input: experience_priors (the original list from initialization), potentially context from Observation/Intention.

Process: No LLM call (or optional simple LLM call for ranking). Implement logic to filter/prune the experience_priors list down to the top 7-10 most relevant results based on score or other heuristics.

Output: understanding_output (dictionary containing the pruned list of prior message dictionaries/IDs/content).

State Update: Store understanding_output for the Yield phase. Yield event.

Yield Phase:

Input: LLM message list (including Understanding output/metadata), understanding_output (pruned priors).

Process:

Construct the final prompt for the LLM, instructing it to generate the response and incorporate citations.

Format the pruned priors from understanding_output into markdown links (e.g., [Prior 1](choir://thread/{thread_id}/message/{message_id})). Include these formatted citations in the prompt for the LLM to potentially use.

Call LLM to generate the final_response_content (string).

(Optional but recommended): Post-process the LLM response to ensure the markdown links are correctly formatted if the LLM didn't generate them perfectly.

Extract the list of cited_prior_ids from the understanding_output's pruned list.

Output: final_response_content (string), cited_prior_ids (list of strings).

State Update: Prepare the final AI message structure. Yield event with final_content.

Persistence:

After Yield completes, construct the final AI message dictionary including: user_id (of the original prompter), thread_id, role='assistant', content=final_response_content, vector (embed final_response_content), timestamp, phase_outputs (dictionary containing outputs from Action, Experience, Intention, Observation, Understanding), and cited_prior_ids.

Asynchronously call db.save_message to persist this final AI message.

Streaming: Yield phase results (phase, status, content, provider, model_name, web_results (empty for now), vector_results (only for Experience phase initially)) throughout the process using yield. Send [DONE] event at the end.

Phase 3: Adapt API Layer (app/routers/postchain.py, app/routers/threads.py, app/routers/users.py)

Update /postchain/langchain (or create /postchain/alpha):

Change the endpoint function signature to accept user_id.

Remove recover_state call.

Instantiate DatabaseClient.

Extract user_id from the authenticated request (assuming authentication provides this).

Call the new run_postchain_alpha_workflow, passing query, thread_id, user_id, config, and the db client instance.

Stream the results back as SSE.

Update Thread/User Endpoints:

Ensure endpoints like GET /threads/{thread_id}/messages use db.get_thread_history for fetching messages from Qdrant.

Ensure user creation/retrieval correctly interacts with the users collection in Qdrant via database.py.

Phase 4: Tool Removal

Delete app/tools/qdrant.py.

Remove Qdrant tool imports and usage from app/tools/__init__.py and any workflow/test files that might still reference it (especially langchain_workflow.py if not deleted yet).

Remove Qdrant tool usage from app/postchain/langchain_workflow.py's Experience phase. (This file will be replaced by postchain_alpha.py anyway).

Phase 5: Client-Side Considerations (SwiftUI)

Fetch History: On app launch or when opening a thread, the client needs to call an API endpoint (e.g., GET /threads/{thread_id}/messages) to fetch message history from Qdrant.

Display Citations: Implement rendering for the new markdown links (choir://thread/...) within the final AI message content, allowing users to potentially navigate to the cited message/thread.

API Call Update: Ensure the client calls the updated /postchain/alpha (or modified /langchain) endpoint.

Phase 6: State Management Consolidation

Deprecate File-Based State: Remove the save_state, recover_state, delete_state functions and the STATE_STORAGE_DIR constant from app/postchain/utils.py. Ensure no part of the active codebase relies on this file-based persistence. Qdrant is now the source of truth for history.

Review In-Memory State: The primary in-memory state should be the transient context passed between phases within a single execution of run_postchain_alpha_workflow. Ensure no unintended state persists between different requests in the API layer itself.

Testing Strategy:

Unit Tests: Test the new database.py functions (embedding, saving, filtered search, history fetching) with mocked Qdrant interactions.

Integration Tests: Test the postchain_alpha.py workflow by mocking LLM calls but using a real (or test instance) Qdrant database to verify search and persistence logic.

End-to-End Tests: Test the API endpoint (/postchain/alpha) by sending requests and verifying the streamed output and the data persisted in Qdrant. Check if citations are correctly included.

Key Considerations:

Asynchronicity: Pay close attention to async/await usage, especially for embedding, Qdrant calls, and LLM interactions, to avoid blocking.

Error Handling: Implement robust error handling in the workflow and database interactions.

Performance: Embedding and searching Qdrant adds latency. Monitor performance and consider optimizations (e.g., batching embeddings if applicable, optimizing Qdrant indexing).

Qdrant Schema: Ensure the messages collection schema in Qdrant is correctly defined with appropriate indexing for user_id, thread_id, and timestamp.

Citation Linking: The choir:// link format is a placeholder; the exact implementation on the client will determine how navigation works.

This guide provides a detailed roadmap for the AI agent. It breaks down the changes file by file and outlines the new logic required for the postchain_alpha.py workflow and the enhanced database.py module. Remember to provide the existing code files as context to the AI agent. -->


# Checklist: Integrating Qdrant Programmatically into PostChain (Qdrant-Sui MVP)

**Goal:** Refactor the `api` backend to deeply integrate Qdrant for message persistence and semantic search within a new PostChain workflow (`postchain_alpha.py`), replacing the existing `langchain_workflow.py` and removing the Qdrant Langchain tool.

---

## Phase 1: Enhance Database Layer (`app/database.py`)

-   [ ] **Implement Embedding Function:**
    -   [ ] Create `async def get_embedding(text: str) -> List[float]`.
    -   [ ] Use `Config.EMBEDDING_MODEL` (e.g., via `langchain_openai.OpenAIEmbeddings`).
    -   [ ] Implement error handling for embedding API calls.
-   [ ] **Refine `save_message` Function:**
    -   [ ] Ensure `save_message` always expects a `vector` field in input `data`.
    -   [ ] Verify it saves required fields to `Config.MESSAGES_COLLECTION`: `user_id`, `thread_id`, `role`, `content`, `vector`, `timestamp`.
    -   [ ] Add saving of `phase_outputs: Dict[str, Any]` (intermediate phase results).
    *   [ ] Add saving of `cited_prior_ids: List[str]` (list of cited message IDs).
    -   [ ] Ensure it returns the generated Qdrant `point_id`.
-   [ ] **Implement Filtered Similarity Search:**
    -   [ ] Create `async def search_similar_filtered(collection: str, query_vector: List[float], filter_conditions: models.Filter, limit: int) -> List[Dict[str, Any]]`.
    -   [ ] Implement Qdrant search using both `query_vector` and `filter_conditions`.
    -   [ ] Use `qdrant_client.models.Filter`, `FieldCondition`, `MatchValue` for filtering.
    -   [ ] Ensure results include `id`, `payload` (content, role, user_id, thread_id, timestamp), and `score`.
-   [ ] **Implement History Fetching:**
    -   [ ] Create `async def get_thread_history(thread_id: str, limit: int = 50, before_timestamp: Optional[str] = None) -> List[Dict[str, Any]]`.
    -   [ ] Filter messages from `Config.MESSAGES_COLLECTION` by `thread_id`.
    -   [ ] Sort results by `timestamp` (descending).
    -   [ ] Implement optional pagination using `before_timestamp`.
    -   [ ] Return messages including `id`, `role`, `content`, `timestamp`, `user_id`, `thread_id`, `phase_outputs`, `cited_prior_ids`.
-   [ ] **Review Qdrant Schema/Indexing:**
    -   [ ] Ensure `messages` collection schema includes all new fields (`phase_outputs`, `cited_prior_ids`).
    -   [ ] Verify appropriate indexing on `user_id`, `thread_id`, `timestamp`.

---

## Phase 2: Create New Workflow Logic (`app/postchain/postchain_alpha.py`)

-   [ ] **Create `postchain_alpha.py` file.**
-   [ ] **Define Workflow Function:**
    -   [ ] Create `async def run_postchain_alpha_workflow(query: str, thread_id: str, user_id: str, config: Config, db: DatabaseClient) -> AsyncIterator[Dict[str, Any]]`.
-   [ ] **Implement Initialization Steps:**
    -   [ ] Call `db.get_thread_history` to fetch history.
    -   [ ] (Optional) Convert history to `BaseMessage` objects if needed for LLMs.
    -   [ ] Call `db.get_embedding(query)` asynchronously.
    -   [ ] Call `db.save_message` for the user's query, store `user_message_id`.
    -   [ ] Call `db.search_similar_filtered` (no filter) for initial Experience priors, store as `experience_priors`.
    -   [ ] Prepare initial LLM message list (history + user query).
-   [ ] **Implement Action Phase:**
    -   [ ] Call LLM with initial message list.
    *   [ ] Store `action_response`.
    -   [ ] Add `action_response` to in-memory message list.
    -   [ ] Yield SSE event.
-   [ ] **Implement Experience Phase:**
    -   [ ] **No LLM call.**
    -   [ ] Format `experience_priors` into a readable structure.
    -   [ ] Store formatted priors as `experience_output`.
    -   [ ] Add `experience_output` reference to context.
    -   [ ] Yield SSE event including structured priors (`vector_results`).
-   [ ] **Implement Intention Phase:**
    -   [ ] Perform Qdrant search filtered by `user_id` using query vector.
    -   [ ] Call LLM with history and user-filtered search results.
    *   [ ] Store `intention_response`.
    -   [ ] Add `intention_response` to in-memory message list.
    -   [ ] Yield SSE event.
-   [ ] **Implement Observation Phase:**
    -   [ ] Perform Qdrant search filtered by `thread_id` using query vector.
    -   [ ] Call LLM with history and thread-filtered search results.
    *   [ ] Store `observation_response`.
    -   [ ] Add `observation_response` to in-memory message list.
    -   [ ] Yield SSE event.
-   [ ] **Implement Understanding Phase:**
    -   [ ] **No LLM call (or optional simple ranking LLM).**
    -   [ ] Implement logic to filter/prune `experience_priors` list (top 7-10).
    -   [ ] Store pruned list as `understanding_output`.
    -   [ ] Yield SSE event.
-   [ ] **Implement Yield Phase:**
    -   [ ] Construct final LLM prompt including instructions for citations.
    -   [ ] Format pruned priors from `understanding_output` into markdown links (`choir://...`).
    -   [ ] Include formatted citations in the LLM prompt.
    -   [ ] Call LLM to generate `final_response_content`.
    -   [ ] (Optional) Post-process LLM response to fix citation formatting.
    -   [ ] Extract `cited_prior_ids` from the pruned list in `understanding_output`.
    -   [ ] Prepare final AI message structure.
    -   [ ] Yield SSE event with `final_content`.
-   [ ] **Implement Final Persistence:**
    -   [ ] Construct final AI message dictionary (including `content`, `vector`, `phase_outputs`, `cited_prior_ids`, etc.).
    -   [ ] Embed `final_response_content` asynchronously.
    -   [ ] Call `db.save_message` asynchronously to save the final AI message.
-   [ ] **Implement Streaming:**
    -   [ ] Ensure `yield` is used after each phase to send SSE events.
    -   [ ] Include `phase`, `status`, `content`, `provider`, `model_name` in events.
    -   [ ] Include `vector_results` in the Experience phase event.
    -   [ ] Yield `[DONE]` event at the very end.

---

## Phase 3: Adapt API Layer (`app/routers/*`)

-   [ ] **Update Postchain Endpoint:**
    -   [ ] Modify `/postchain/langchain` or create `/postchain/alpha`.
    -   [ ] Update function signature to accept/retrieve `user_id`.
    -   [ ] **Remove call to `recover_state` (file-based).**
    -   [ ] Instantiate `DatabaseClient`.
    -   [ ] Call `run_postchain_alpha_workflow` with required arguments (`user_id`, `db`, etc.).
    -   [ ] Ensure SSE streaming works correctly.
-   [ ] **Update Thread Endpoints (`app/routers/threads.py`):**
    -   [ ] Modify `GET /threads/{thread_id}/messages` to use `db.get_thread_history`.
    -   [ ] Ensure thread creation/retrieval uses `database.py` correctly.
-   [ ] **Update User Endpoints (`app/routers/users.py`):**
    -   [ ] Ensure user creation/retrieval uses `database.py` and interacts with the Qdrant `users` collection.

---

## Phase 4: Tool Removal

-   [ ] **Delete `app/tools/qdrant.py` file.**
-   [ ] **Remove Qdrant tool imports** from `app/tools/__init__.py`.
-   [ ] **Remove Qdrant tool usage** from `app/postchain/langchain_workflow.py` (if not already deleted/replaced).
-   [ ] **Search codebase** for any remaining references to the Qdrant Langchain tool and remove them.

---

## Phase 5: Client-Side Considerations (SwiftUI)

*(These are notes for the client team, not direct coding tasks for the backend agent)*

-   [ ] **Fetch History:** Client needs to call `GET /threads/{thread_id}/messages` on load.
-   [ ] **Display Citations:** Client needs to parse and render `choir://...` markdown links in AI messages.
-   [ ] **API Endpoint:** Client needs to call the new/updated Postchain API endpoint.
-   [ ] **Experience Phase Display:** Client needs to handle and display the `vector_results` provided in the Experience phase SSE event.

---

## Phase 6: State Management Consolidation

-   [ ] **Deprecate File State:** Remove `save_state`, `recover_state`, `delete_state` functions from `app/postchain/utils.py`.
-   [ ] **Remove `STATE_STORAGE_DIR` constant** from `app/postchain/utils.py`.
-   [ ] **Verify No File State Usage:** Ensure no active code calls the removed file state functions.
-   [ ] **Review API State:** Confirm API endpoints are stateless between requests, relying on Qdrant for persistence.

---

## Phase 7: Testing Strategy

-   [ ] **Unit Tests (`database.py`):**
    -   [ ] Test `get_embedding`.
    -   [ ] Test `save_message` (with new fields).
    -   [ ] Test `search_similar_filtered` with various filters.
    -   [ ] Test `get_thread_history`.
    -   [ ] Use mocked Qdrant client.
-   [ ] **Integration Tests (`postchain_alpha.py`):**
    -   [ ] Mock LLM calls.
    -   [ ] Use a real (or test instance) Qdrant database.
    -   [ ] Verify Qdrant searches are performed correctly in Experience, Intention, Observation.
    -   [ ] Verify message persistence (user and final AI) occurs correctly.
    -   [ ] Verify `phase_outputs` and `cited_prior_ids` are saved.
-   [ ] **End-to-End Tests (API):**
    -   [ ] Call the `/postchain/alpha` endpoint.
    -   [ ] Verify the streamed SSE events (including Experience priors).
    -   [ ] Verify the final `[DONE]` event.
    -   [ ] Inspect Qdrant database to confirm user and AI messages were saved correctly.
    -   [ ] Verify citation links appear in the final streamed content.

---
