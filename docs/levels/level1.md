# Level 1 Documentation



=== File: docs/core_core.md ===



==
core_core
==


# Core System Overview

VERSION core_system: 7.0

Note: This document describes the core system architecture, with initial focus on TestFlight functionality. More sophisticated event-driven mechanisms described here will be implemented post-funding.

The Choir system, in its MCP architecture, is structured around a clear hierarchy of truth and state management, now implemented as a network of interconnected **Model Context Protocol (MCP) servers**.

At the foundation, the **blockchain** (Sui) remains the authoritative source of truth for economic state, managing thread ownership, token balances (CHIP), message hashes, and co-author lists. **This entire economic framework is governed by the FQAHO (Fractional Quantum Anharmonic Oscillator) model and the CHIP token economy.** This ensures the FQAHO-based economic model's integrity and verifiability.

**libSQL/Turso databases** are used by each MCP server for local persistence of phase-specific state and data, including vector embeddings. This distributed database approach enhances scalability and fault isolation.

**Qdrant** continues to serve as the authoritative source for content and semantic relationships, storing message content, embeddings, and citation networks, now accessed by the Experience phase MCP server.

The **AEIOU-Y Post Chain** is now realized as a sequence of specialized **MCP servers** (Action, Experience, Intention, Observation, Understanding, Yield), each responsible for a distinct phase of the user interaction cycle.  User input is processed sequentially through these servers, each contributing to the evolving conversation state.

**MCP clients** within each server facilitate communication with other phase-servers, using a standardized message protocol over SSE streams for efficient, asynchronous communication and streaming responses.

State updates are managed within each MCP server's local libSQL/Turso database, with the "conversation state resource" being managed by the Host application and accessible to servers as needed. This distributed state management approach enhances scalability and resilience.

The economic model, based on FQAHO dynamics and the CHIP token, is now integrated into the MCP architecture, with economic actions triggered and recorded via PySUI interactions with the Sui blockchain from within MCP servers.

This MCP architecture enables a more modular, scalable, and secure Choir system. Each phase, as an independent MCP server, encapsulates its logic and state, improving maintainability and fault isolation. The use of Phala Network for deployment further enhances security and confidentiality.

The result is a distributed, service-oriented system that combines:

- **Economic Incentives (CHIP token, FQAHO)**: Managed on-chain via Sui and PySUI.
- **Semantic Knowledge (Qdrant)**: Accessed and utilized by the Experience phase server.
- **Natural Interaction Patterns (AEIOU-Y Post Chain)**: Implemented as a sequence of specialized MCP servers.
- **Fractional Quantum Dynamics (FQAHO)**: Encapsulated within the economic model and parameter evolution logic.
- **Swift Concurrency (replaced by Python Async/await in MCP servers)**:  Each MCP server leverages Python's async/await for efficient concurrent operations.
- **libSQL/Turso**: Provides local persistence and vector search for each MCP server, enabling efficient state and knowledge management within phases.
- **Phala Network**: Provides confidential computing environment for secure and private operations.

This architecture enables the Choir system to evolve into a truly scalable, robust, and secure platform for building a tokenized marketplace of ideas and upgrading human financial decision-making.

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

## The FQAHO Contract: Governing a Dynamic Data Marketplace

The Fractional Quantum Anharmonic Oscillator (FQAHO) contract, implemented on the Sui blockchain, is the **economic heart of the Choir data marketplace**. It provides a dynamic and nuanced mechanism for:

*   **Stake Pricing and Value Discovery:** The FQAHO model dynamically determines the stake price for contributing to threads, reflecting the evolving value of knowledge and user attention within the ecosystem.
*   **Data Access and Contribution Pricing:** The FQAHO contract governs the "price of data" within each thread. Users "pay" CHIP tokens (stake) to contribute to threads, and this contribution can be seen as a *price for accessing and adding value to the data within that thread*.
*   **Incentivizing Quality and Salience:** The FQAHO contract, through its integration with the novelty and citation reward mechanisms, incentivizes users and AI agents to create *high-quality, novel, and salient contributions* that are valuable for AI training and knowledge building.
*   **Decentralized Governance and Economic Evolution:** The FQAHO contract is designed to be *governed by CHIP token holders*, allowing the community to democratically shape the rules of the data marketplace and evolve the economic model over time.

## Reward Mechanisms: Fueling the AI Data Engine

The CHIP token economy is driven by two key reward mechanisms, algorithmically distributed by AI models within the Choir platform:

1.  **Novelty Rewards (Experience Phase - Driving Data Diversity):**
    *   **Purpose:** To incentivize the creation of *novel and original prompts and messages*, ensuring a diverse and ever-expanding dataset for AI training.
    *   **Mechanism:** AI models in the Experience Phase analyze new user contributions for semantic novelty compared to existing data in the platform's vector databases.
    *   **Distribution:** CHIP tokens are algorithmically distributed as novelty rewards to users who submit contributions deemed sufficiently novel, encouraging exploration of new ideas and knowledge domains.

2.  **Citation Rewards (Yield Phase - Driving Predictive Salience and Data Quality):**
    *   **Purpose:** To incentivize users to create *salient and impactful contributions* that are recognized and valued by the community, and to reward the creation of high-quality, human-labeled training data through citations.
    *   **Mechanism:** AI models in the Yield Phase analyze the citation network, identifying messages that have been cited as valuable "priors" by other users.
    *   **Distribution:** CHIP tokens are algorithmically distributed as citation rewards to users whose messages have been cited, based on the *salience* and *influence* of their contributions, as measured by citation metrics and FQAHO parameters.

These reward mechanisms are not just about distributing tokens; they are **direct training signals for AI models within Choir**.  AI models learn to identify and reward the very data that is most valuable for their own improvement and for the growth of the collective intelligence of the platform.

## Data Marketplace Dynamics: CHIP as Data Purchase Power

The CHIP token economy creates a dynamic **data marketplace** within Choir, where:

*   **CHIP Tokens are the Currency of Data Access:** AI companies, researchers, developers, and even individual users who want to access the high-quality, human-generated data within Choir must **purchase CHIP tokens** to participate in the data marketplace.
*   **Data is "Sold" at a "Quantum Level" (Thread-Specific Contracts):** Data access and contribution pricing are governed by the FQAHO contract at a granular, thread-specific level. Each thread effectively has its own "data contract" that determines the terms of data access and contribution within that thread.
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

The core economic model of Choir, centered around the CHIP token and the FQAHO contract, is designed to create a **self-improving, data-driven AI ecosystem** where:

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

Approval Processing drives state evolution through three possible outcomes. In the case of rejection, both the anharmonic coefficient K₀ and the fractional parameter α are adjusted—with K₀ increasing to reflect recent refusals, and α decreasing slightly to capture the memory of this rejection. The system recalculates P₀ using our FQAHO-based formula. For split decisions, energy divides between treasury and thread based on voter distribution while parameters adjust proportionally. When approved, energy distributes to approvers while the fractional parameter α decreases slightly, enhancing non-local effects. The author joins as a co-author, and all parameters recalibrate according to the updated thread characteristics.

Dynamic Parameter Evolution follows principles of fractional quantum mechanics. The fractional parameter α evolves to reflect thread maturity and quality, decreasing from 2 toward 1 as threads develop memory and non-local interactions. The anharmonic coefficient K₀ responds primarily to recent approval/refusal patterns, while maintaining sensitivity to the fractional parameter. The potential order m increases with citation count and co-author network complexity, reflecting deepening interactions.

Frequency Management reflects collective organization through coupled oscillators with fractional damping. The thread frequency evolves through three interacting modes: the message mode normalizes activity rate by the fractional power of co-author count, the value mode applies logarithmic scaling to energy per co-author, and the coupling strength maintains an inverse relationship with co-author count raised to the fractional power. These modes work together to create natural organizational rhythms with long-range correlations.

**Reward System and Token Distribution (Clarified Phase-Specific Rewards):**

The reward system operates through precisely defined state transitions with memory effects. MCP servers, specifically AI models within the **Experience and Yield phases**, algorithmically distribute CHIP tokens based on contribution quality and network effects:

1.  **Novelty Rewards (Issued in the Experience Phase):**
    *   **Purpose:** To incentivize the creation of *novel and original prompts and messages* that expand the knowledge space of the Choir ecosystem.
    *   **Mechanism:** AI models within the **Experience phase** analyze new user prompts and messages for *semantic novelty* compared to existing content in the platform's vector databases.
    *   **Distribution:** CHIP tokens are algorithmically distributed as **novelty rewards** to users who submit prompts and messages that are deemed sufficiently novel and original by the Experience phase AI models.
    *   **Timing:** Novelty rewards are issued **during the Experience phase**, as part of the context enrichment and knowledge retrieval process.

2.  **Citation Rewards (Issued in the Yield Phase):**
    *   **Purpose:** To incentivize users to create *salient and impactful contributions* that are recognized and valued by the community, and to foster the growth of a richly interconnected knowledge network through citations.
    *   **Mechanism:** AI models within the **Yield phase** analyze the citation network and identify messages that have been *cited by other users as "priors"*.
    *   **Distribution:** CHIP tokens are algorithmically distributed as **citation rewards** to users whose messages have been cited, based on the *salience* and *influence* of their cited contributions (as measured by citation metrics and FQAHO parameters).
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
