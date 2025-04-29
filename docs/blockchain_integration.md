# Blockchain Integration in Choir (Qdrant-Sui MVP)

VERSION blockchain_integration: 8.0 (Qdrant-Sui MVP Focus)

## Overview

This document outlines the blockchain integration strategy for the Choir Qdrant-Sui MVP. This approach centralizes blockchain interactions within the main Python API backend, specifically using a dedicated service module (`sui_service.py`) to interact with the Sui blockchain via the PySUI SDK.

## Core Blockchain Integration Goals

The core goals of blockchain integration for the MVP and beyond remain:

1.  **Immutable Record of Economic Actions:** Utilize the Sui blockchain for a transparent record of key economic events, primarily simplified token rewards for the MVP.
2.  **Decentralized and Verifiable Token Economy:** Implement the basic CHIP token using a Sui smart contract (`choir_coin.move`).
3.  **Secure and Transparent Reward Distribution:** Ensure that CHIP token rewards (simplified for MVP) are distributed verifiably on-chain.
4.  **(Future)** Enable On-Chain Governance: Lay the groundwork for future on-chain governance by CHIP token holders.

## MVP Blockchain Integration Architecture: Centralized API Service

In the Qdrant-Sui MVP architecture, blockchain integration is handled by the **Python API backend** via its `sui_service.py` module. This service acts as the *sole interface* between the Choir application logic and the Sui blockchain.

**Key Components:**

*   **Python API Backend (FastAPI/Uvicorn):**
    *   **Orchestrates Workflow:** Manages the PostChain workflow execution.
    *   **Contains Blockchain Logic:** Includes the `sui_service.py` module responsible for all Sui interactions.
    *   **Triggers Rewards:** After the PostChain workflow completes (Yield phase), the API calls functions within `sui_service.py` to process rewards based on data stored in Qdrant.

*   **`sui_service.py` (within API Backend):**
    *   **PySUI Integration (Encapsulated):** The PySUI SDK for interacting with the Sui blockchain is exclusively used within this service module.
    *   **Handles Transactions:** Constructs, signs (using keys managed by the API's environment/secrets), and submits transactions to the Sui network.
    *   **Exposes Service Functions:** Provides functions (e.g., `record_reward`, `get_balance`) called internally by the API's orchestration logic.

*   **PostChain Workflow (LCEL - within API Backend):**
    *   **No Direct Blockchain Interaction:** The AEIOU-Y phase logic **does not directly interact with the Sui blockchain or PySUI.**
    *   **Provides Reward Inputs:** The workflow (specifically data gathered by Experience and finalized by Yield) provides the necessary inputs (author ID, prior IDs, scores) for the API to trigger the reward calculation in `sui_service.py`.

*   **Sui Blockchain:**
    *   **Hosts CHIP Token Contract:** Runs the `choir_coin.move` smart contract defining the basic CHIP token.
    *   **Records Transactions:** Stores the history of token transfers/mints executed by `sui_service.py`.

**Architecture Diagram (Qdrant-Sui MVP):**

```mermaid
graph LR
    A[Client (SwiftUI)] --> B{Python API (FastAPI)};
    B --> C[PostChain Workflow (LCEL)];
    C -- Interacts via database.py --> D[(Qdrant)];
    C -- Returns final data --> B;
    B -- Triggers reward --> E[sui_service.py];
    E -- Uses PySUI --> F[(Sui Blockchain)];
    B -- Streams results --> A;

    style B fill:#ccf,stroke:#333,stroke-width:2px;
    style C,E fill:#f9f,stroke:#333,stroke-width:2px;
    style D,F fill:#bfc,stroke:#333,stroke-width:2px;

    subgraph API Backend Container
        B
        C
        E
    end

    Communication Flow for Blockchain Operations (MVP):

PostChain Completion: The PostChain workflow (running within the API) completes its final (Yield) phase. It returns the final AI message structure, including author ID, cited prior IDs, novelty score, and similarity scores.

API Trigger: The main API logic receives the completed PostChain data.

Data Persistence: The API saves the final AI message to the choir collection in Qdrant.

Call Sui Service: The API calls the appropriate function within sui_service.py (e.g., process_rewards), passing the relevant data fetched from the newly saved Qdrant message (or held from the workflow result).

Sui Service Execution: The sui_service.py function:

Performs the (simplified for MVP) reward calculation.

Looks up recipient Sui addresses if necessary (using Qdrant users collection via database.py).

Uses PySUI to construct and sign the necessary Sui transaction(s) (e.g., calling a basic mint_reward function in the choir_coin contract).

Submits the transaction to the Sui blockchain.

Result Handling: The sui_service.py function returns the transaction result (e.g., digest, success/failure) to the main API logic. The API logs this result. (Note: For MVP, the result might not be directly propagated back to the client UI).

Service Functions Exposed by sui_service.py (MVP):

The sui_service.py module exposes internal functions called by the API orchestrator. Key functions for the MVP include:

process_rewards(message_id, author_user_id, cited_prior_ids, novelty_score, similarity_scores): Calculates (simplified) rewards and calls the mint/transfer function.

_call_sui_mint(recipient_address, amount): Internal helper to interact with the Sui contract's mint function.

get_balance(sui_address): Queries the SUI balance (primarily for testing/diagnostics in MVP). (Already implemented)

(Future) get_chip_balance(sui_address): Queries the CHIP token balance.

(Future) get_thread_stake_price(thread_id): Fetches economic state from potential future contract.

Security Considerations (MVP):

With blockchain interactions centralized in the API backend's sui_service.py:

API Key Management: The primary security concern is protecting the Sui private key used by the API backend. This key must be managed securely using environment variables, platform secrets management (e.g., Render secrets), or a dedicated secrets manager. It must not be hardcoded.

Input Validation: The API must rigorously validate all data passed to sui_service.py functions, especially recipient addresses and amounts, to prevent manipulation or unintended transactions.

Service Isolation (Logical): While not physically isolated like a separate server/TEE, sui_service.py provides logical isolation. All blockchain interaction code is contained within this module, making it easier to audit and secure compared to scattering PySUI calls throughout the codebase.

Standard API Security: General API security practices (authentication, authorization, rate limiting, HTTPS) are essential to protect the endpoints that trigger the workflows leading to blockchain interactions.

Deployment Considerations (MVP):

API Container Deployment: The Python API, including sui_service.py and its PySUI dependency, is deployed as a single Docker container (e.g., on Render).

Secure Key Provisioning: The Sui private key required by sui_service.py must be securely provisioned to the deployed container's environment (e.g., using Render's secret management).

Conclusion (MVP Focus)
The Qdrant-Sui MVP utilizes a centralized approach for blockchain integration, embedding the logic within the main Python API backend via the sui_service.py module. This simplifies the architecture for the MVP, allowing focus on the core Qdrant data structures and the basic reward triggering mechanism. While deferring the complexities of distributed servers and TEEs, this approach provides a clear path to validating the fundamental interaction between AI-analyzed data in Qdrant and the Sui blockchain-based token economy. Secure management of the API's Sui key is paramount in this model.
