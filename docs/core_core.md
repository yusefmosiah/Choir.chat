# Core System Overview (Qdrant-Sui MVP)

VERSION core_system: 8.0 (Qdrant-Sui MVP Focus)

## Overview

The Choir system, for its Minimum Viable Product (MVP), is architected around a focused stack designed to validate the core concepts of AI-driven conversation analysis and a tokenized reward mechanism. This MVP centers on **Qdrant** as the primary data and vector store and **Sui** as the blockchain layer for the CHIP token, orchestrated by a central **Python API**. While future iterations envision a distributed network of specialized servers, the MVP utilizes a streamlined architecture to accelerate validation.

## Foundational Principles (Informed by Broader Vision)

Even within the MVP's focused scope, Choir is built upon a clear hierarchy of truth and state management, guided by underlying principles:

1.  **Blockchain as Economic Truth (Sui):** The **Sui blockchain** serves as the *authoritative source of truth for the economic state*. In the MVP, this includes the basic existence of the CHIP token and the execution of simplified reward distributions. Ultimately, it will manage thread ownership, full token balances, message hashes, co-author lists, and the governance of the economic model.
2.  **Qdrant as Semantic Truth:** **Qdrant** serves as the *authoritative source for content and semantic relationships*. It stores message content, user/thread data, phase-specific memory, embeddings, and eventually, citation networks.
3.  **AEIOU-Y Post Chain as Interaction Pattern:** The **AEIOU-Y Post Chain** defines the natural interaction pattern for processing user input and generating nuanced AI responses. In the MVP, this pattern is implemented via the LCEL workflow.
4.  **Dynamic Economic Model:** The economic model, based on dynamic principles and the CHIP token, underpins the reward system, even if its full implementation is post-MVP.

## Core Components (Qdrant-Sui MVP)

1.  **Qdrant (Data & Vector Layer):**
    *   **Role:** The authoritative source for persistent data relevant to the AI workflow and reward mechanism. Stores user mappings (linked to Sui addresses), thread metadata, conversation messages (user prompts and final AI responses with embedded phase outputs), and specialized memory collections (`intention_memory`, `observation_memory`).
    *   **Function:** Enables semantic search (priors) for the Experience phase, stores structured outputs, and provides the necessary data inputs (novelty/similarity scores, author/prior linkage) for the reward system.

2.  **Sui Blockchain (via PySUI Service):**
    *   **Role:** Manages the CHIP token (basic contract) and handles reward distribution logic (simplified for MVP). The ultimate source of economic truth.
    *   **Function (MVP):** Provides foundational token infrastructure. The `sui_service.py` within the API backend interacts with Sui (via PySUI) to execute basic reward actions.

3.  **Python API (FastAPI/Uvicorn - Orchestration Layer):**
    *   **Role:** The central orchestrator connecting the client, AI logic, Qdrant, and Sui.
    *   **Function:** Authenticates users (Sui signature), manages the PostChain workflow execution, handles Qdrant interactions, triggers reward calculations via the Sui service, and streams results to the client.

4.  **PostChain Workflow (LCEL Implementation):**
    *   **Role:** The core AI processing engine, implementing the AEIOU-Y pattern.
    *   **Function:** Executes sequentially within the Python API (`langchain_workflow.py`). Phases interact with Qdrant (via `database.py`) for data retrieval/storage. Calculates scores needed for rewards.

5.  **Supporting Technologies:**
    *   **Langchain Utils (`langchain_utils.py`):** LLM abstraction.
    *   **Pydantic:** Data validation.
    *   **Docker:** API containerization.
    *   **SwiftUI & Keychain:** Client UI and secure Sui key storage.
    *   **Python Async/await:** Used within the API and LCEL workflow for efficient concurrent operations.

## MVP Architecture & Data Flow

The Qdrant-Sui MVP operates as follows:

1.  User interacts via **SwiftUI Client**, authenticating using their **Sui** key.
2.  Request hits the **Python API (FastAPI)**.
3.  API orchestrates the **PostChain Workflow (LCEL)**.
4.  PostChain phases interact with **Qdrant** for priors and memory, using **Langchain Utils** for LLM calls. Scores are calculated.
5.  Final AI response (with embedded phase outputs/scores) is persisted in **Qdrant**.
6.  API triggers the **Sui Service** for rewards based on Qdrant data.
7.  API streams results back to the **SwiftUI Client**.

This architecture validates the core loop: **User Input -> API Orchestration -> PostChain (Qdrant Interaction) -> Reward Trigger (Sui Service)**.

## Strategic Focus for MVP

*   **Qdrant Centrality:** Validate Qdrant for storing diverse AI-related data and supporting semantic search.
*   **Sui Integration:** Establish the basic workflow for triggering token rewards based on Qdrant data.
*   **Leveraging Existing Code:** Utilize the current LCEL PostChain implementation.
*   **Simplicity:** Defer complexities like distributed servers, advanced client caching, and TEE deployment.

## The Combined Result (MVP)

The MVP delivers a system combining:

*   **Economic Incentives (CHIP token, Basic Principles):** Managed via Sui and PySUI Service.
*   **Semantic Knowledge (Qdrant):** Stored, accessed, and utilized by the PostChain workflow.
*   **Natural Interaction Patterns (AEIOU-Y Post Chain):** Implemented via the LCEL workflow.
*   **Python Async/await:** Powers the backend API and workflow.

This streamlined MVP architecture focuses on demonstrating the fundamental interplay between semantic data storage (Qdrant) and a blockchain-based reward mechanism (Sui), laying the groundwork for the more complex, distributed, and secure system envisioned in the broader Choir architecture.
