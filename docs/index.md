# Choir Documentation

# Choir: Building a Tokenized Marketplace of Ideas (Qdrant-Sui MVP)

## Core Concepts

The Choir platform is a revolutionary system for building collective intelligence, structured around a sophisticated conceptual model. The Minimum Viable Product (MVP) focuses on validating the core data flow and reward mechanism using Qdrant and the Sui blockchain. Explore the foundational concepts:
- [PostChain Temporal Logic](postchain_temporal_logic.md) - The temporal essence of each AEIOU-Y phase, driving dynamic and context-aware AI workflows.
- [FQAHO Model](fqaho_visualization.md) - The Fractional Quantum Anharmonic Oscillator economic model, powering a self-improving token economy that rewards quality and innovation (conceptual basis for MVP rewards).
- [Core Economics](core_economics.md) - The economic principles and tokenomics of CHIP, designed to create a sustainable and equitable ecosystem for knowledge creation.
- [Core State Transitions](core_state_transitions.md) - The carefully defined state transitions that govern the evolution of threads and the flow of value within Choir (principles guiding MVP implementation).
- [Evolution: Naming](evolution_naming.md) - The story behind the evolution of Choir's name, reflecting the project's journey and vision.

## Architecture (Qdrant-Sui MVP)

Choir's MVP technical architecture centers on a Python API orchestrating interactions between Qdrant (data/vector storage) and the Sui blockchain (token/rewards).
- [Core System Overview](core_core.md) - Description of the MVP architecture and components.
- [Stack Argument](stack_argument.md) - The compelling rationale behind the technology choices for the MVP stack.
- [Security Considerations](security_considerations.md) - A deep dive into the security architecture for the MVP's centralized API and data stores.

## Implementation (Qdrant-Sui MVP)

Explore the practical implementation of Choir's MVP architecture:
- [State Management Patterns](state_management_patterns.md) - How state is managed within the central API and persisted in Qdrant for the MVP.

## Context Management in the PostChain Workflow

Choir leverages the AEIOU-Y PostChain workflow to enable sophisticated context management, with each phase playing a specialized role in orchestrating the flow of knowledge within the API backend:

| Phase         | Temporal Focus       | Context Responsibility (within API Workflow) |
| ------------- | -------------------- | -------------------------------------------- |
| Action        | Immediate present    | Initial framing and response.                |
| Experience    | Past knowledge       | Enriching context via Qdrant search (priors). |
| Intention     | Desired future       | Focusing on user goals (using `intention_memory` in Qdrant). |
| Observation   | Future preservation  | Structuring thread knowledge (using `observation_memory` in Qdrant). |
| Understanding | Temporal integration | Deciding what information to prune from memory collections (Qdrant). |
| Yield         | Process completion   | Generating the final response and preparing data for Qdrant/rewards. |

## A Vision for the Future: Personal AI and the Tokenized Marketplace of Ideas

Choir is not just building another AI application; we are building a **transformative platform for the future of AI and human collaboration**:

- **Revolutionizing Consumer Finance:** Empowering users with AI-driven tools to optimize their financial lives and achieve financial freedom.
- **Creating a Live Streaming Home Production Studio:** Transforming home entertainment and content creation with AI-powered tools for interactive and immersive experiences.
- **Building a Tokenized Marketplace of Ideas:** Fostering a new kind of online platform where quality ideas are valued, rewarded, and drive the emergence of collective intelligence.
- **Democratizing AI Training and Ownership:** Enabling users to participate in and benefit from the AI revolution, owning a piece of the AI infrastructure and contributing to a self-improving, community-driven AI ecosystem.

Explore the documentation sections above to understand how Choir's Qdrant-Sui MVP architecture is designed to validate the core concepts needed to realize this ambitious vision.

## Documentation Structure

The documentation is organized into the following sections:

## 1. Core Concepts

Fundamental concepts that remain consistent regardless of the implementation:
- Phases:
    - [Action Requirements](require_action_phase.md)
    - [Experience Requirements](require_experience_phase.md)
    - [Intention Requirements](require_intention_phase.md)
    - [Observation Requirements](require_observation_phase.md)
    - [Understanding Requirements](require_understanding_phase.md)
    - [Yield Requirements](require_yield_phase.md)
- [FQAHO Model](fqaho_visualization.md) - The Fractional Quantum Anharmonic Oscillator economic model
- [Core Economics](core_economics.md) - Economic principles and tokenomics
- [Core State Transitions](core_state_transitions.md) - State transition principles
- [Evolution: Naming](evolution_naming.md) - Naming conventions and evolution

## 2. Architecture (MVP)

Detailed information about the Qdrant-Sui MVP architecture:
- [Core System Overview](core_core.md) - MVP architecture description.
- [Stack Argument](stack_argument.md) - Rationale for the MVP technology stack.
- [Security Considerations](security_considerations.md) - Security architecture for the MVP.

## 3. Implementation (MVP)

Practical guidance for implementing the MVP architecture:
- [State Management Patterns](state_management_patterns.md) - State management in the MVP.

## 4. Integration (MVP)

Information about integrating with external systems for the MVP:
- [Blockchain Integration](blockchain_integration.md) - Integration with Sui blockchain for the MVP.


## 5. Business and Strategy

Business aspects of Choir:
- [Business Model](e_business.md) - Business model and strategy.
- [Evolution Token](evolution_token.md) - Token design and economics.
- [Anonymity by Default](plan_anonymity_by_default.md) - Privacy principles.

## 6. Planning & Future

Documents outlining plans and future directions:
- [Plan: CHIP Materialization (AI Supercomputer Box)](plan_chip_materialization.md) - Long-term hardware vision.

## Development Timeline

- [Changelog](CHANGELOG.md) - Historical development timeline.


## Contributing to Documentation

When contributing to documentation:

1.  Focus documentation updates on the **Qdrant-Sui MVP** scope unless explicitly marked as "Future" or "Post-MVP".
2.  Follow the established folder structure.
3.  Use Markdown for all documentation.
4.  Include diagrams using Mermaid.js where appropriate, reflecting the MVP architecture.
5.  Provide code examples relevant to the MVP implementation.
6.  Update this index when adding or significantly modifying documents.
