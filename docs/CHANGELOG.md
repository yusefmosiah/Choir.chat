# Changelog
## [2025-04-09] - 2025-04-09

### Added

- **iOS Client Persistence:** Implemented local JSON file storage for thread data.
- **Automatic Thread Titles:** Threads now get an auto-generated title based on the first 10 words of the initial AI Action phase response.
- **Close the Loop UI:** When the yield phase finishes downloading, if the user is viewing the action phase, the UI now automatically transitions to display the final response with a smooth wrap-around animation.


## [2025-03-28] - 2025-03-28

### Added

-   **PostChain Sequential Model Execution:** Implemented a prototype version of the PostChain running on a mobile device, successfully executing a sequence of 6 distinct AI models. This demonstrates the feasibility of the multi-phase workflow and shows initial promise for value generation.

### Changed

-   **Architectural Validation:** The sequential model execution validates the core concept of the PostChain flow. Next steps involve implementing background looping, Qdrant database integration for state persistence and memory, and connecting to the Sui service for reward distribution. These are considered tractable integration tasks.

## [2025-03-27] - 2025-03-27

### Changed

-   **Architectural Focus Shift: Qdrant-Sui MVP Prioritized**
    -   Refocused development efforts on a Minimum Viable Product (MVP) centered around **Qdrant** (data/vector store) and **Sui** (blockchain token/rewards).
    *   Adopted a streamlined architecture using the existing **Python API (FastAPI)** as the central orchestrator.
    *   Leveraging the current **LCEL-based PostChain workflow** (`langchain_workflow.py`) for MVP implementation speed.
    *   Defined clear data structures and interactions between the API, PostChain phases, Qdrant collections (`choir`, `users`, `chat_threads`, `intention_memory`, `observation_memory`), and the `sui_service.py`.
    *   Refined core documentation (`core_core.md`, `state_management_patterns.md`, `blockchain_integration.md`, `security_considerations.md`, `stack_argument.md`, `index.md`) to reflect the MVP scope and architecture.

### Deferred (Post-MVP)

-   Implementation of the full Model Context Protocol (MCP) server architecture.
-   Integration of client-side libSQL caching for offline support.
-   Deployment using Phala Network TEEs for confidential computing.
-   Implementation of the full FQAHO dynamic economic model (MVP uses basic rewards).

## [Unreleased] - 2025-03-12

### Changed

-   **Major Architectural Pivot: Shifted from LangGraph to MCP Architecture**
    -   Transitioned to Model Context Protocol (MCP) architecture for the Choir platform.
    -   Adopted a service-oriented architecture with each PostChain phase implemented as a separate MCP server.
    -   Implemented MCP Resources for efficient conversation state management and context sharing.
    -   Leveraged MCP Notifications for real-time updates and communication between Host and Servers.
    -   Replaced LangGraph-based workflow orchestration with a Host-application-centric orchestration model using asynchronous tasks.
    -   Refined the focus on modularity, scalability, and security through the MCP architecture.

### Added

-   **Coherent Technology Stack for MCP Architecture:**
    -   **Model Context Protocol (MCP) Architecture:** Service-oriented architecture for PostChain phases, enabling modularity and scalability.
    -   **PySUI:** Maintained PySUI for blockchain integration and economic actions.
    -   **Pydantic:** Continued use of Pydantic for type safety and message validation in the MCP architecture.
    -   **FastAPI/Uvicorn:** Continued use of FastAPI/Uvicorn for the Python API layer, now orchestrating MCP server interactions.
    -   **Docker:** Maintained Docker for containerization and deployment of MCP servers.
    -   **Phala Network:** Maintained Phala Network for TEE-secured operations and confidential computing for MCP servers.

-   **Enhanced Token Economy and Reward System (RL-Driven CHIP):**
    -   **CHIP Tokens as Training Signals for AI:** Evolved the CHIP token to act as training signals for AI models, driving a self-improving AI ecosystem.
    -   **Novelty and Citation Rewards:** Implemented novelty rewards for original prompts and citation rewards for salient contributions, algorithmically distributed by AI models.
    -   **FQHO Contract as Data Marketplace Foundation:** Defined the FQAHO contract as the basis for a data marketplace within Choir, enabling CHIP-based data access and contribution pricing.
    -   **"AI Supercomputer Box" Vision:** Incorporated the "AI Supercomputer Box" concept as a tangible product embodiment of the Choir platform and CHIP token utility, envisioning a premium, rent-to-own consumer appliance for private, personalized AI and content creation.

### Removed

-   Deprecated LangGraph dependency and graph-based state management due to scalability and maintenance concerns.

## [2025-02-25] - 2025-02-25

### Added

-   Implemented UI carousel to improve user experience
-   Added display of priors in the Experience step
-   Resumed active development after coding hiatus

### Planned

-   API streaming implementation to enhance responsiveness
-   Model reconfiguration for improved performance
-   Go multimodel, then multimodal
-   OpenRouter integration
-   Conceptual evolution from "Chorus Cycle" to "Post Chain"
    -   Representing shift from harmonic oscillator (cycle) to anharmonic oscillator (chain)
    -   Aligning interface terminology with underlying FQAHO model
-   Client-side editable system prompts for customization
-   Additional phases in the Post Chain:
    -   Web search phase for real-time information access
    -   Sandboxed arbitrary tool use phase for enhanced capabilities

## [2025-02-24] - 2025-02-24

### Changed

-   Implemented fractional quantum anharmonic oscillator model for dynamic stake pricing
-   Added fractional parameter α to capture memory effects and non-local interactions
-   Revised parameter modulation formulas for K₀, α, and m to reflect interdependencies
-   Created simulation framework for parameter optimization

## [2025-02-23] - 2025-02-23

### Changed

-   Documented quantum anharmonic oscillator model implementation and dynamic stake pricing mechanism via an effective anharmonic coefficient modulated by approval/refusal statistics.

## [Unreleased]

### Changed

-   Updated all documentation to version 6.0
    -   Transformed structured documentation into fluid prose
    -   Relaxed event-driven architecture requirements for initial TestFlight
    -   Clarified implementation priorities and post-funding features
    -   Maintained theoretical frameworks while focusing on core functionality

### Added

-   Initial Chorus cycle working in iOS simulator
    -   Basic message flow through phases
    -   Response handling
    -   State management

### Documented

-   Created 15 comprehensive issues covering:
    -   Core message system implementation
    -   Type reconciliation with Qdrant
    -   API client updates
    -   Coordinator message flow
    -   User identity management
    -   Thread state management
    -   Integration testing
    -   Error handling strategy
    -   Performance monitoring
    -   State recovery
    -   Thread sheet implementation
    -   Thread contract implementation
    -   Message rewards system
    -   LanceDB migration
    -   Citation visualization

### Architecture

-   Defined clear type system for messages
-   Planned migration to LanceDB
-   Structured multimodal support strategy

### Technical Debt

-   Identified areas needing more specification:
    -   Thread Sheet UI (marked as "AI SLOP")
    -   Reward formulas need verification
    -   Migration pipeline needs careful implementation

## [0.4.2] - 2024-11-09

### Added

-   Development principles with focus on groundedness
-   Basic chat interface implementation
-   SwiftData message persistence // this subsequently became a problem. swiftdata is coupled with swiftui and there was interference between view rendering and data persistence
-   Initial Action step foundation

### Changed

-   Shifted to iterative, ground-up development approach
-   Simplified initial implementation scope
-   Focused on working software over theoretical architecture
-   Adopted step-by-step Chorus Cycle implementation strategy

### Principles

-   Established groundedness as core development principle
-   Emphasized iterative growth and natural evolution
-   Prioritized practical progress over theoretical completeness
-   Introduced flexible, evidence-based development flow

## [0.4.1] - 2024-11-08

### Added

-   Self-creation process
-   Post-training concepts
-   Concurrent processing ideas
-   Democratic framing
-   Thoughtspace visualization

### Changed

-   Renamed Update to Understanding
-   Enhanced step descriptions
-   Refined documentation focus
-   Improved pattern recognition

## [0.4.0] - 2024-10-30

### Added

-   Swift architecture plans
-   Frontend-driven design
-   Service layer concepts
-   Chorus cycle definition

### Changed

-   Enhanced system architecture
-   Refined core patterns

## [0.3.5] - 2024-09-01

-   Choir.chat as a web3 dapp
-   messed around with solana
-   used a lot of time messing with next.js/react/typescript/javascript
-   recognized that browser extension wallet is terrible ux

## [0.3.0] - 2024-03-01

### Added

-   ChoirGPT development from winter 2023 to spring 2024

-   First developed as a ChatGPT plugin, then a Custom GPT
-   The first global RAG system / collective intelligence as a GPT

## [0.2.10] - 2023-04-01

### Added

-   Ahpta development from winter 2022 to spring 2023

## [0.2.9] - 2022-04-01

### Added

-   V10 development from fall 2021 to winter 2022

## [0.2.8] - 2021-04-01

### Added

-   Elevisio development from spring 2020 to spring 2021

## [0.2.7] - 2020-04-01

### Added

-   Bluem development from spring 2019 to spring 2020

## [0.2.6] - 2019-04-01

### Added

-   Blocstar development from fall 2018 to spring 2019

## [0.2.5] - 2018-04-01

### Added

-   Phase4word development from summer 2017 to spring 2018

### Changed

-   Showed Phase4word to ~50 people in spring 2018, received critical feedback
-   Codebase remains in 2018 vintage

## [0.2.0] - 2016-06-20

### Added

-   Phase4 party concept
-   Early democracy technology
-   Initial value systems

### Changed

-   Moved beyond truth measurement framing
-   Refined core concepts

## [0.1.0] - 2015-07-15

### Added

-   Initial simulation hypothesis insight
-   "Kandor"
-   Quantum information concepts
-   Planetary coherence vision
-   Core system ideas
