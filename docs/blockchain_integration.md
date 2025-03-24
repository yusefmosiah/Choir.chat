# Blockchain Integration in Choir: Dedicated Blockchain Service Server with MCP

## Overview

This document outlines the blockchain integration strategy for Choir, now implemented with a dedicated **Blockchain Service Server** within the Model Context Protocol (MCP) architecture. This revised approach enhances modularity, security, and maintainability by centralizing all blockchain interactions within a single, TEE-protected MCP server.

## Core Blockchain Integration Goals (No Changes)

The core goals of blockchain integration remain the same:

1.  **Immutable Record of Economic Actions:**  Utilize the Sui blockchain to create an immutable and transparent record of key economic events within Choir, such as token rewards, stake transactions, and governance decisions.
2.  **Decentralized and Verifiable Token Economy:**  Implement the CHIP token economy using Sui smart contracts, enabling decentralized token distribution, governance, and value exchange.
3.  **Secure and Transparent Reward Distribution:**  Ensure that CHIP token rewards for novelty and citations are distributed fairly, transparently, and verifiably on-chain.
4.  **Enable On-Chain Governance:**  Empower CHIP token holders to participate in the decentralized governance of the Choir platform through on-chain voting and proposal mechanisms.

## Revised Blockchain Integration Architecture: Dedicated Blockchain Service Server

In the MCP architecture, blockchain integration is now handled by a **dedicated Blockchain Service Server**, which acts as the *sole interface* between the Choir platform and the Sui blockchain.

**Key Components of the Revised Architecture:**

*   **Blockchain Service Server (New MCP Server):**
    *   **Dedicated MCP Server:** A new, specialized MCP server is introduced, specifically designed to handle all blockchain interactions.
    *   **PySUI Integration (Encapsulated):** The PySUI SDK for interacting with the Sui blockchain is *exclusively integrated within this server*. No other phase servers or the Host application directly include PySUI.
    *   **TEE Deployment (Phala Network):** The Blockchain Service Server is deployed within a Phala Network Trusted Execution Environment (TEE), ensuring the secure isolation and protection of Sui private keys.
    *   **MCP Tool Provider:** The Blockchain Service Server exposes MCP tools that encapsulate various blockchain operations (recording citations, fetching thread state, transferring tokens, etc.).

*   **MCP Phase Servers (Action, Experience, Yield, etc.):**
    *   **No Direct Blockchain Interaction:** Phase servers (Action, Experience, Yield, Intention, Observation, Understanding) **no longer directly interact with the Sui blockchain or PySUI.**
    *   **Blockchain Interaction via MCP Tools:** When phase servers need to perform blockchain operations (e.g., Yield Server recording citation rewards), they do so by making **MCP tool calls to the Blockchain Service Server**.
    *   **Simplified Logic and Focus:** Phase servers are simplified and focused on their core AI workflow logic, without the added complexity of blockchain integration.

*   **Host Application (Python API):**
    *   **Orchestrates MCP Servers:** The Host application continues to orchestrate the PostChain workflow and manage communication between MCP servers.
    *   **No Direct Blockchain Interaction (Typically):** The Host application *typically does not directly interact with the Sui blockchain* in this architecture.  Blockchain interactions are encapsulated within the Blockchain Service Server.  In some advanced scenarios, the Host *could* potentially call tools on the Blockchain Service Server if needed, but direct PySUI integration in the Host is avoided.

**Architecture Diagram (MCP with Dedicated Blockchain Service Server):**

```mermaid
graph LR
    A[Host Application (Python API)] --> B(Action Server)
    B --> C(Experience Server)
    C --> D(Intention Server)
    D --> E(Observation Server)
    E --> F(Understanding Server)
    F --> G(Yield Server)
    G --> A

    style A fill:#ccf,stroke:#333,stroke-width:2px
    style B,C,D,E,F,G fill:#f9f,stroke:#333,stroke-width:2px

    subgraph PostChain MCP Servers
        B
        C
        D
        E
        F
        G
    end

    H[Blockchain Service Server (TEE)] --> Sui[Sui Blockchain]
    style H fill:#bfc,stroke:#333,stroke-width:2px

    YieldServer --> H
    ExperienceServer --> H
    subgraph Dedicated MCP Servers
        H
    end

    linkStyle 0,1,2,3,4,5,6 stroke-dasharray: 5 5;
    ```

    Communication Flow for Blockchain Operations
When a phase server (e.g., Yield Server) needs to perform a blockchain operation:

Phase Server (MCP Client Role) Initiates Tool Call: The phase server (acting as an MCP client) sends a callTool request to the Blockchain Service Server.

Tool Selection and Parameters: The callTool request specifies the appropriate tool for the blockchain operation (e.g., record_citation, get_thread_state) and includes the necessary parameters (e.g., cited_message_id, citing_message_id, citation_value).

Blockchain Service Server (Tool Execution within TEE): The Blockchain Service Server receives the callTool request and executes the corresponding tool logic within its secure TEE environment. This tool logic includes:

Using PySUI (securely encapsulated within the TEE) to construct and sign a Sui blockchain transaction.

Interacting with the Sui blockchain to submit the transaction.

Blockchain Service Server Returns Result: The Blockchain Service Server sends a CallToolResult back to the requesting phase server, indicating the outcome of the blockchain operation (success or failure) and potentially including transaction details.

MCP Tools Exposed by the Blockchain Service Server
The Blockchain Service Server exposes a set of MCP tools to encapsulate various blockchain operations. Examples include:

record_citation(cited_message_id, citing_message_id, citation_value): Records a citation event on the Sui blockchain, distributing CHIP token rewards.

get_thread_state(thread_id): Fetches the current economic state (stake price, FQAHO parameters) of a thread from the Sui smart contract.

transfer_tokens(recipient_address, amount): Initiates a CHIP token transfer from the treasury or a designated account to a recipient address.

get_treasury_balance(): Queries the current CHIP token balance of the treasury smart contract.

get_verified_user_status(user_id): Checks if a user is KYC-verified and has a verified identity on the blockchain (for future IDaaS integration).

submit_governance_vote(proposal_id, vote_choice): Allows verified users (or AI agents acting on their behalf) to submit votes in on-chain governance proposals.

The specific set of tools exposed by the Blockchain Service Server can be extended and customized as needed to support the evolving blockchain integration requirements of the Choir platform.

Security Benefits of the Dedicated Blockchain Service Server
This revised architecture with a dedicated Blockchain Service Server provides significant security advantages:

Centralized and Isolated Key Management: Private keys for Sui blockchain operations are centralized and isolated within a single, TEE-protected service. This drastically reduces the attack surface and simplifies key management.

Reduced Attack Surface for Phase Servers: Phase servers (Action, Experience, Yield, etc.) no longer need to handle any blockchain-related code or private keys. This significantly reduces their attack surface and simplifies their security profile.

Clear Security Boundary: The Blockchain Service Server acts as a clear security boundary for all blockchain interactions. Security audits and vulnerability assessments can be focused on this single, critical component, rather than needing to examine every phase server for potential blockchain security issues.

Enhanced Auditability and Monitoring: All blockchain operations are now channeled through the Blockchain Service Server, making it easier to monitor and audit blockchain interactions and detect any suspicious activity.

Simplified Security Policies: Security policies and access controls for blockchain operations can be集中管理 and enforced at the level of the Blockchain Service Server, simplifying overall system security management.

Deployment Considerations
Docker Compose for Local Development: In a local development environment using Docker Compose, the Blockchain Service Server can be deployed as a separate Docker container alongside other MCP servers and the Host application.

Phala Network TEE Deployment (Production): For production deployments on Phala Network, the Blockchain Service Server's Docker container should be specifically configured to be deployed to a Phala TEE worker. The other phase servers and the Host application can be deployed to standard Phala workers or other infrastructure.

Secure Key Provisioning to TEE Container: The deployment process must include a secure mechanism for provisioning the Sui private keys to the Blockchain Service Server container within the Phala TEE environment, ensuring that keys are never exposed outside the secure enclave.

Conclusion
The dedicated Blockchain Service Server architecture provides a more modular, secure, and maintainable approach to blockchain integration within the Choir MCP system. By centralizing and isolating blockchain operations and key management within a TEE-protected service, this architecture enhances the overall security, scalability, and robustness of the Choir platform, paving the way for secure and scalable blockchain integration.
