# Level 1 Documentation



=== File: docs/core_core.md ===



==
core_core
==


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

=== File: docs/core_economics.md ===



==
core_economics
==


# Core Economic Model: Fueling a Self-Improving AI Ecosystem with CHIP Tokens

VERSION core_economics: 8.0 (RL-Driven Data Economy)

The economic model of Choir is not just about transactions and value exchange; it's about creating a **self-sustaining engine for AI improvement and a thriving marketplace for valuable human data.**  The CHIP token is at the heart of this engine, acting as both the fuel and the training signal for a revolutionary AI ecosystem.

## CHIP: Beyond a Utility Token - A Training Signal and Data Currency

The CHIP token transcends the limitations of a traditional utility token. It is designed to be:

*   **A Representation of Contribution and Ownership:** CHIP tokens represent a stake in the collective intelligence of Choir, acknowledging and rewarding user contributions to the platform's knowledge base.
*   **A Training Signal for AI Models:** CHIP tokens, distributed as novelty and citation rewards, act as *direct training signals* for AI models within the Choir ecosystem, guiding them to optimize for desired behaviors and high-quality content generation.
*   **The Currency of a Data Marketplace:** CHIP tokens are the *exclusive currency* for accessing and transacting with the valuable, human-generated data within the Choir platform, creating a demand-driven data marketplace.
*   **A Driver of Network Effects and Value Accrual:** The CHIP token economy is designed to create powerful network effects, driving user engagement, data creation, AI improvement, and sustainable token value accrual.

## The Dynamic Contract: Governing a Data Marketplace

The dynamic contract, implemented on the Sui blockchain, is the **economic heart of the Choir data marketplace**. It provides a dynamic and nuanced mechanism for:

*   **Stake Pricing and Value Discovery:** The model dynamically determines the stake price for contributing to threads, reflecting the evolving value of knowledge and user attention within the ecosystem.
*   **Data Access and Contribution Pricing:** The contract governs the "price of data" within each thread. Users "pay" CHIP tokens (stake) to contribute to threads, and this contribution can be seen as a *price for accessing and adding value to the data within that thread*.
*   **Incentivizing Quality and Salience:** The contract, through its integration with the novelty and citation reward mechanisms, incentivizes users and AI agents to create *high-quality, novel, and salient contributions* that are valuable for AI training and knowledge building.
*   **Decentralized Governance and Economic Evolution:** The contract is designed to be *governed by CHIP token holders*, allowing the community to democratically shape the rules of the data marketplace and evolve the economic model over time.

## Reward Mechanisms: Fueling the AI Data Engine

The CHIP token economy is driven by two key reward mechanisms, algorithmically distributed by AI models within the Choir platform:

1.  **Novelty Rewards (Experience Phase - Driving Data Diversity):**
    *   **Purpose:** To incentivize the creation of *novel and original prompts and messages*, ensuring a diverse and ever-expanding dataset for AI training.
    *   **Mechanism:** AI models in the Experience Phase analyze new user contributions for semantic novelty compared to existing data in the platform's vector databases.
    *   **Distribution:** CHIP tokens are algorithmically distributed as novelty rewards to users who submit contributions deemed sufficiently novel, encouraging exploration of new ideas and knowledge domains.

2.  **Citation Rewards (Yield Phase - Driving Predictive Salience and Data Quality):**
    *   **Purpose:** To incentivize users to create *salient and impactful contributions* that are recognized and valued by the community, and to reward the creation of high-quality, human-labeled training data through citations.
    *   **Mechanism:** AI models in the Yield Phase analyze the citation network, identifying messages that have been cited as valuable "priors" by other users.
    *   **Distribution:** CHIP tokens are algorithmically distributed as citation rewards to users whose messages have been cited, based on the *salience* and *influence* of their contributions, as measured by citation metrics and model parameters.

These reward mechanisms are not just about distributing tokens; they are **direct training signals for AI models within Choir**.  AI models learn to identify and reward the very data that is most valuable for their own improvement and for the growth of the collective intelligence of the platform.

## Data Marketplace Dynamics: CHIP as Data Purchase Power

The CHIP token economy creates a dynamic **data marketplace** within Choir, where:

*   **CHIP Tokens are the Currency of Data Access:** AI companies, researchers, developers, and even individual users who want to access the high-quality, human-generated data within Choir must **purchase CHIP tokens** to participate in the data marketplace.
*   **Data is "Sold" at a Granular Level (Thread-Specific Contracts):** Data access and contribution pricing are governed by the contract at a granular, thread-specific level. Each thread effectively has its own "data contract" that determines the terms of data access and contribution within that thread.
*   **Data Scarcity and Privacy Drive Value:** The deliberate emphasis on **data scarcity and user privacy** within Choir is a key driver of CHIP token value.  By limiting data sales and prioritizing user control, Choir creates a marketplace for *premium, high-quality, and ethically sourced data*, which is increasingly valuable in the AI age.
*   **CHIP Holder Governance of Data Marketplace Terms:** CHIP token holders have **governance rights to shape the rules and policies of the data marketplace**, ensuring that it remains aligned with the community's values and long-term interests.

## Business Sustainability and the "Pays for Itself" Model

The CHIP token economy is designed to create a **self-sustaining ecosystem** where value flows naturally and benefits all participants.  The "AI Supercomputer Box" and the IDaaS premium features are key components of the business model, designed to:

*   **Drive CHIP Token Demand and Utility:**  Create tangible use cases for CHIP tokens, increasing their demand and utility beyond just platform-internal rewards.
*   **Generate Revenue to Support Platform Operations:**  Revenue from "AI Supercomputer Box" sales/rent-to-own and IDaaS subscriptions will fund the ongoing development, maintenance, and operational costs of the Choir platform and the token economy.
*   **"Pays for Itself" Value Proposition for Users:**  The "AI Supercomputer Box" is designed to be a valuable asset that "pays for itself" over time through:
    *   **Financial Optimization and Savings (AI Household Assistant Features).**
    *   **Token Earning for Background Compute Work.**
    *   **Access to a Thriving Data Marketplace and Future AI-Powered Services.**

## Conclusion: Building a Self-Improving, Data-Driven AI Ecosystem

The core economic model of Choir, centered around the CHIP token and the dynamic contract, is designed to create a **self-improving, data-driven AI ecosystem** where:

*   **Human Ingenuity and AI Intelligence are Synergistically Combined:**  The platform leverages the unique strengths of both human users and AI models to create a powerful engine for knowledge creation and problem-solving.
*   **Data is Recognized and Valued as a Core Asset:**  User data contributions are explicitly recognized as valuable assets and are rewarded through the CHIP token economy.
*   **Value Flows Naturally and Incentives are Aligned:**  The token economy is designed to align the incentives of users, AI agents, and the platform itself, creating a virtuous cycle of growth, quality, and value creation.
*   **CHIP Tokens Fuel a Self-Improving AI Engine:**  CHIP tokens are not just a currency; they are the *fuel and the training signals* that drive the continuous improvement and evolution of the Choir AI ecosystem, creating a truly revolutionary and sustainable model for the future of AI and online collaboration.

=== File: docs/core_state_transitions.md ===



==
core_state_transitions
==


# Core State Transitions

VERSION core_state_transitions: 7.1 (Reward Clarifications)

The state transition system orchestrates the evolution of thread states through carefully defined transformations. These transitions follow precise fractional mathematical principles that ensure non-local energy conservation, dynamic parameter recalibration, and frequency coherence across the network.

Thread Creation establishes the initial quantum state. Each new thread begins with α = 2 (standard quantum mechanics), baseline anharmonic coefficient (K₀_base), and potential order m = 2. The creator's address becomes the first co-author, and the thread maintains an empty set of message hashes. This initial state provides a foundation for future non-local evolution.

Message Submission follows fractional quantum anharmonic energy principles. The required stake follows E(n) = (2n+1)^(α/2) + (K₀λ)^(α/(m+1)), where α, K₀, and m reflect the thread's history and network position. Each message generates a unique hash and carries its quantized energy contribution to the thread.

Approval Processing drives state evolution through three possible outcomes. In the case of rejection, model parameters are adjusted to reflect recent refusals and to capture the memory of this rejection. The system recalculates pricing using our formula. For split decisions, energy divides between treasury and thread based on voter distribution while parameters adjust proportionally. When approved, energy distributes to approvers while parameters are adjusted to enhance effects. The author joins as a co-author, and all parameters recalibrate according to the updated thread characteristics.

Dynamic Parameter Evolution follows principles of fractional quantum mechanics. The fractional parameter α evolves to reflect thread maturity and quality, decreasing from 2 toward 1 as threads develop memory and non-local interactions. The anharmonic coefficient K₀ responds primarily to recent approval/refusal patterns, while maintaining sensitivity to the fractional parameter. The potential order m increases with citation count and co-author network complexity, reflecting deepening interactions.

Frequency Management reflects collective organization through coupled oscillators with fractional damping. The thread frequency evolves through three interacting modes: the message mode normalizes activity rate by the fractional power of co-author count, the value mode applies logarithmic scaling to energy per co-author, and the coupling strength maintains an inverse relationship with co-author count raised to the fractional power. These modes work together to create natural organizational rhythms with long-range correlations.

**Reward System and Token Distribution (Clarified Phase-Specific Rewards):**

The reward system operates through precisely defined state transitions with memory effects. AI models within the **Experience and Yield phases**, algorithmically distribute CHIP tokens based on contribution quality and network effects:

1.  **Novelty Rewards (Issued in the Experience Phase):**
    *   **Purpose:** To incentivize the creation of *novel and original prompts and messages* that expand the knowledge space of the Choir ecosystem.
    *   **Mechanism:** AI models within the **Experience phase** analyze new user prompts and messages for *semantic novelty* compared to existing content in the platform's vector databases.
    *   **Distribution:** CHIP tokens are algorithmically distributed as **novelty rewards** to users who submit prompts and messages that are deemed sufficiently novel and original by the Experience phase AI models.
    *   **Timing:** Novelty rewards are issued **during the Experience phase**, as part of the context enrichment and knowledge retrieval process.

2.  **Citation Rewards (Issued in the Yield Phase):**
    *   **Purpose:** To incentivize users to create *salient and impactful contributions* that are recognized and valued by the community, and to foster the growth of a richly interconnected knowledge network through citations.
    *   **Mechanism:** AI models within the **Yield phase** analyze the citation network and identify messages that have been *cited by other users as "priors"*.
    *   **Distribution:** CHIP tokens are algorithmically distributed as **citation rewards** to users whose messages have been cited, based on the *salience* and *influence* of their cited contributions (as measured by citation metrics and model parameters).
    *   **Timing:** Citation rewards are issued **during the Yield phase**, as part of the final response rendering and output formatting process, with inline links to citations providing transparent recognition of valuable contributions.

The reward system operates through precisely defined state transitions with memory effects. New message rewards follow a fractional time-based decay described by R(t) = R_total × k/(1 + k·t_period)^(α/2), where k represents the decay constant (2.04), t_period spans the total time period of four years, and α is the thread's fractional parameter. Prior citation rewards strengthen thread coupling by drawing from treasury balance based on quality score ratios, expressed as V(p) = B_t × Q(p)^(α/2)/∑Q(i)^(α/2). Citations create frequency coupling between threads, with each thread's frequency increasing by 5% of the other's frequency, modulated by the fractional parameter. Treasury management maintains system solvency through careful balance tracking, where split decisions increase the balance, prior rewards decrease it, and system rewards add to it, all while maintaining a minimum balance for stability.

The system's core properties maintain stability through:

1. Fractional energy conservation in all transitions
2. Parameter coherence via coupled feedback loops
3. Frequency alignment through fractional organizational coupling
4. Lévy flight-like value propagation through the network

Error handling defines transition validity through multiple safeguards. Fractional energy conservation violations trigger immediate rejection. Parameter instability blocks updates until recalibration completes. Frequency decoherence blocks transitions that would disrupt organizational patterns. Phase transition failures maintain the previous state to ensure system stability.

Through these precisely defined transitions, the system maintains fractional quantum anharmonic stability while enabling organic evolution of thread states. The careful balance of non-local energy conservation, dynamic parameter modulation, and frequency alignment creates a robust framework for organic growth and adaptation with memory effects.

#### Fractional Parameter Evolution

The evolution of thread parameters follows fractional quantum principles:

• The fractional parameter α evolves via:
α(t,q) = 2 - δ₁(1-e^(-t/τ)) - δ₂q

• The anharmonic coefficient adjusts through:
K₀(r,α) = K₀_base _ (1 + γ₁r) _ (2/α)^γ₂

• The potential order develops according to:
m(c,n) = 2 + β₁tanh(c/c₀) + β₂log(1+n/n₀)

These modifications ensure that memory effects, non-local interactions, and network complexity are properly accounted for in the economic model.
