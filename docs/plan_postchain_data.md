# Postchain Data Architecture Refactoring Plan

**Core Goal:** Evolve Postchain from a purely LLM-driven tool-using workflow to a more structured process with programmatic data handling (vectorization, storage), integrated reward mechanisms, and advanced data representations (hypergraphs), while also enabling flexible model selection.

**Priorities (Re-ordered):**

1.  **Programmatic Vectorization & Storage:** Embed/store every message in Qdrant with metadata.
2.  **SUI Rewards:** Implement Novelty and Citation rewards.
3.  **Experience Phase Refactor:** Split into Qdrant search then Web search.
4.  **Hypergraph Integration:** Use `hypernetx` for user/thread graphs.
5.  **Client Model Config:** Allow SwiftUI client to select models/providers via API.

---

## Detailed Plan

### Priority 1: Programmatic Vectorization & Storage

*   **Objective:** Automatically embed and store every user query and AI response (from all phases) in Qdrant with detailed metadata (thread_id, author_id, phase, model, provider, timestamp).
*   **Rationale:** Ensures all conversational steps are captured for context retrieval, analysis, and reward calculation, independent of LLM tool calls.
*   **Diagram:**
    ```mermaid
    sequenceDiagram
        participant WF as Workflow Manager
        participant LU as Langchain Utils
        participant DB as DatabaseClient
        participant Q as Qdrant

        WF->>LU: get_embedding(text)
        LU-->>WF: vector
        WF->>DB: save_message(content, vector, metadata)
        DB->>Q: upsert(point with payload including metadata)
        Q-->>DB: Success
        DB-->>WF: Success (ID)
    ```
*   **Implementation Steps:**
    1.  **Embedding Utility:**
        *   In `api/app/langchain_utils.py`, create a reusable async function `get_embedding(text: str, config: Config) -> List[float]`.
        *   This function should initialize `OpenAIEmbeddings(model=config.EMBEDDING_MODEL)` and call `aembed_query(text)`.
    2.  **Workflow Integration:**
        *   In `api/app/postchain/langchain_workflow.py`:
            *   Ensure a `DatabaseClient` instance is available within `run_langchain_postchain_workflow`.
            *   **User Query:** Before the Action phase, call `get_embedding` on the input `query`. Call `db_client.save_message` with the vector and metadata: `{ "thread_id": thread_id, "author_id": "user", "phase": "input", "timestamp": datetime.now(UTC).isoformat() }`.
            *   **AI Responses:** In *each* phase function (`run_action_phase`, `run_experience_phase`, etc.), after receiving a valid `AIMessage` response:
                *   Call `get_embedding` on `response.content`.
                *   Construct metadata: `{ "thread_id": thread_id, "author_id": "ai", "phase": "<phase_name>", "model": model_config.model_name, "provider": model_config.provider, "timestamp": datetime.now(UTC).isoformat() }`.
                *   Call `db_client.save_message` with the content, vector, and metadata.
                *   Add error handling for the save operation.
    3.  **Metadata Retrieval (Enhancement):**
        *   In `api/app/database.py`, modify `DatabaseClient.search_similar` to return the full nested `metadata` dictionary from the Qdrant payload.
        *   Consider adding parameters to `search_similar` or creating new search methods (e.g., `search_with_filter`) to allow filtering points based on metadata fields like `thread_id`, `phase`, `author_id`. This will be useful for rewards and context retrieval.

### Priority 2: SUI Rewards

*   **Objective:** Implement Novelty (semantic similarity-based) and Citation rewards using SUI tokens minted via `SuiService`.
*   **Rationale:** Incentivizes valuable contributions within the conversation flow.
*   **Diagram:**
    ```mermaid
    graph TD
        A[AI Message Saved in Qdrant] --> B{Calculate Novelty}
        B --> C[Search Qdrant for Similar in Thread]
        C --> D[Calculate Score (1 - max_sim)]
        D --> E[Determine Reward Amount]
        E --> F[Get User Wallet Address]
        F --> G[Mint Novelty Reward via SuiService]

        H[Experience Phase Completes w/ Tools] --> I{Calculate Citation Reward}
        I --> J[Determine Reward Amount (Default 1)]
        J --> K[Get User Wallet Address]
        K --> L[Mint Citation Reward via SuiService]

        M[DatabaseClient] --> C
        N[SuiService] --> G
        N --> L
    ```
*   **Implementation Steps:**
    1.  **Workflow Integration:**
        *   In `api/app/postchain/langchain_workflow.py`:
            *   Ensure `SuiService` and `DatabaseClient` instances are available.
            *   Define a helper function `get_user_wallet(user_id: str) -> Optional[str]` (implementation TBD - needs user data source).
    2.  **Novelty Reward:**
        *   After the `db_client.save_message` call for an AI response (from Priority 1):
            *   Use the response's vector to call `db_client.search_similar` (or the enhanced version with filtering) to find the most similar message *within the same `thread_id`* excluding the message just saved.
            *   Calculate `novelty_score = 1.0 - result[0].score` if results exist, else `1.0`.
            *   Define `NOVELTY_BASE_REWARD` (e.g., 1 CHOIR = 1_000_000_000).
            *   `reward_amount = int(NOVELTY_BASE_REWARD * novelty_score)`.
            *   Get `recipient_address = await get_user_wallet(user_id)` (Need to determine `user_id` context).
            *   If address found and `reward_amount > 0`, call `await sui_service.mint_choir(recipient_address, reward_amount)`.
            *   Log the reward transaction details or errors.
    3.  **Citation Reward:**
        *   In `run_experience_phase`, after the final LLM call:
            *   Check if `web_results` or `vector_results` in the `ExperiencePhaseOutput` are non-empty.
            *   If yes, define `CITATION_REWARD_AMOUNT` (e.g., 1 CHOIR = 1_000_000_000).
            *   Get `recipient_address = await get_user_wallet(user_id)`.
            *   If address found, call `await sui_service.mint_choir(recipient_address, CITATION_REWARD_AMOUNT)`.
            *   Log the reward transaction details or errors.
    4.  **User Wallet Mapping:** Implement the `get_user_wallet` function. This likely involves querying the `USERS_COLLECTION` via `DatabaseClient` assuming the user's SUI address is stored there. Update `database.py` (`create_user`, `get_user`) if necessary to include a wallet address field.

### Priority 3: Experience Phase Refactor

*   **Objective:** Modify the Experience phase to deterministically run Qdrant search first, then Web search, and feed results to the LLM for synthesis.
*   **Rationale:** Provides more structured context gathering than relying on LLM tool selection.
*   **Diagram:**
    ```mermaid
    sequenceDiagram
        participant EP as run_experience_phase
        participant LU as Langchain Utils
        participant DB as DatabaseClient
        participant WS as WebSearchTool
        participant LLM as post_llm

        EP->>LU: get_embedding(qdrant_query)
        LU-->>EP: query_vector
        EP->>DB: search_similar(query_vector)
        DB-->>EP: qdrant_results
        EP->>WS: arun(web_query)
        WS-->>EP: web_results_str
        EP->>EP: Format qdrant_results & web_results
        EP->>LLM: Invoke with Action Response + Formatted Results
        LLM-->>EP: experience_response (AIMessage)
        EP-->>WF: ExperiencePhaseOutput(experience_response, web_results, vector_results)

    ```
*   **Implementation Steps:**
    1.  **Modify `run_experience_phase` (`langchain_workflow.py`):**
        *   Remove the `tools` parameter from the `post_llm` call. Remove the tool execution loop.
        *   Instantiate `DatabaseClient` and `BraveSearchTool` (or preferred web tool).
        *   **Qdrant Search:**
            *   Determine the query text (e.g., from `last_user_msg.content`).
            *   Call `get_embedding` to get the vector.
            *   Call `await db_client.search_similar(...)` using the vector. Store the results (`vector_results`).
        *   **Web Search:**
            *   Determine the query text.
            *   Call `await web_search_tool.arun(...)`. Store the results (`web_results`). Parse if necessary (e.g., if JSON).
        *   **LLM Synthesis:**
            *   Update the `EXPERIENCE_INSTRUCTION` prompt to instruct the LLM to synthesize the `Initial Action Response` using the *provided* Qdrant and Web search results.
            *   Format the `vector_results` and `web_results` into a readable string format.
            *   Inject the formatted results into the message list passed to the *single* `post_llm` call for this phase.
            *   Ensure the `ExperiencePhaseOutput` object is populated correctly with the `experience_response` and the structured `web_results` and `vector_results` lists.

### Priority 4: Hypergraph Integration

*   **Objective:** Use `hypernetx` library to create, update, and utilize hypergraphs representing user context (Intention phase) and thread context (Observation phase).
*   **Rationale:** Provides a structured way to capture and reason about complex relationships and concepts within the conversation.
*   **Implementation Steps:**
    1.  **Dependency:** Add `hypernetx` to `api/requirements.txt`.
    2.  **Hypergraph Manager:**
        *   Create a new file, e.g., `api/app/hypergraph_manager.py`.
        *   Implement a class `HypergraphManager` with methods like:
            *   `__init__(self, graph_id: str, storage_path: str = "/path/to/graphs")`: Loads graph if exists, else creates new. `graph_id` could be `user:<user_id>` or `thread:<thread_id>`.
            *   `load()`: Loads graph from storage (e.g., Pickle file, JSON).
            *   `save()`: Saves graph to storage.
            *   `add_node(node_id, attributes=None)`.
            *   `add_edge(edge_id, nodes, attributes=None)`.
            *   `get_text_representation() -> str`: Generates a summary string for LLM prompts.
            *   `update_from_llm_suggestions(suggestions: str)`: Parses LLM output to add nodes/edges (requires careful prompting and parsing).
    3.  **Intention Phase (`run_intention_phase` in `langchain_workflow.py`):**
        *   Instantiate `manager = HypergraphManager(f"user:{user_id}")`.
        *   Get `graph_text = manager.get_text_representation()`.
        *   Modify `INTENTION_INSTRUCTION` prompt: Include `graph_text` and ask the LLM to identify the user's intention *and* suggest updates (new concepts as nodes, relationships as edges) to the user's hypergraph based on the conversation.
        *   After the `post_llm` call, parse the `response.content` for suggested updates.
        *   Call `manager.update_from_llm_suggestions(parsed_suggestions)`.
        *   Call `manager.save()`.
    4.  **Observation Phase (`run_observation_phase` in `langchain_workflow.py`):**
        *   Instantiate `manager = HypergraphManager(f"thread:{thread_id}")`.
        *   Get `graph_text = manager.get_text_representation()`.
        *   Modify `OBSERVATION_INSTRUCTION` prompt: Include `graph_text` and ask the LLM to identify key concepts/entities from the *current turn* and suggest new nodes/edges representing their connections within the thread context.
        *   After the `post_llm` call, parse suggestions.
        *   Call `manager.update_from_llm_suggestions(parsed_suggestions)`.
        *   Call `manager.save()`.

### Priority 5: Client Model Configuration

*   **Objective:** Allow the SwiftUI client to specify the desired LLM provider and model name for the Postchain workflow via the API.
*   **Rationale:** Provides user flexibility and allows leveraging different model capabilities.
*   **Implementation Steps (Backend):**
    1.  **API Router (`routers/postchain.py`):**
        *   Modify `SimplePostChainRequest` model to include:
            ```python
            model_identifier: Optional[str] = Field(None, description="Optional model identifier (e.g., 'anthropic/claude-3-5-haiku-latest', 'openrouter/google/gemini-flash-1.5')")
            ```
        *   In the `/langchain` endpoint function, extract `request.model_identifier`.
        *   Pass `model_identifier` to the `run_langchain_postchain_workflow` call.
    2.  **Workflow (`langchain_workflow.py`):**
        *   Modify `run_langchain_postchain_workflow` signature to accept `model_identifier: Optional[str] = None`.
        *   Inside the function, determine the `ModelConfig` to use for *all* phases:
            *   If `model_identifier` is provided, parse it using `get_model_provider` from `langchain_utils.py` to create the `ModelConfig`.
            *   If not provided, fall back to default models defined in `Config` (e.g., `config.CHAT_MODEL`).
        *   Pass this single determined `ModelConfig` to each phase function (`run_action_phase(..., model_config=determined_mc)` etc.).
        *   Remove the per-phase `*_mc_override` parameters from the workflow signature (unless specifically needed for internal testing).
*   **Implementation Steps (Frontend - High Level):**
    1.  **UI:** Add controls (e.g., `Picker` or `Menu`) in SwiftUI views (`PostchainView.swift` or settings view) to select provider/model. Fetch available models from a new API endpoint if needed.
    2.  **ViewModel (`PostchainViewModel.swift`):** Add `@Published` properties to store the user's selection.
    3.  **API Client (`RESTPostchainAPIClient.swift`):** Modify the function that calls `/api/postchain/langchain` to include the selected `model_identifier` in the request body.

---
