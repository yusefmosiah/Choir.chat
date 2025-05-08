# Choir: Building a Tokenized Marketplace of Ideas (Qdrant-Sui MVP)

Choir is a platform designed to amplify collective intelligence through AI-driven conversation analysis and a tokenized reward system. It utilizes the PostChain workflow (AEIOU-Y phases) to process interactions, leveraging multiple LLM providers, Qdrant for semantic storage, and the Sui blockchain for its native CHOIR coin.

## Core Concepts

The Choir platform is a revolutionary system for building collective intelligence, structured around a sophisticated conceptual model. The Minimum Viable Product (MVP) focuses on validating the core data flow and reward mechanism using Qdrant and the Sui blockchain. Explore the foundational concepts:

*   **[PostChain Temporal Logic](docs/postchain_temporal_logic.md):** The temporal essence of each AEIOU-Y phase, driving dynamic and context-aware AI workflows.
*   **[Core Economics](docs/core_economics.md):** The economic principles and tokenomics of CHOIR, designed to create a sustainable and equitable ecosystem for knowledge creation.
*   **[Core State Transitions](docs/core_state_transitions.md):** The carefully defined state transitions that govern the evolution of threads and the flow of value within Choir (principles guiding MVP implementation).
*   **[Evolution: Naming](docs/evolution_naming.md):** The story behind the evolution of Choir's name, reflecting the project's journey and vision.
*   **[Evolution: Token](docs/evolution_token.md):** The evolution of the CHOIR coin concept.

## Architecture (Qdrant-Sui MVP)

Choir's MVP technical architecture centers on a Python API orchestrating interactions between Qdrant (data/vector storage) and the Sui blockchain (token/rewards).

*   **[Core System Overview](docs/core_core.md):** Description of the MVP architecture and components.
*   **[Stack Argument](docs/stack_argument.md):** The compelling rationale behind the technology choices for the MVP stack.
*   **[Security Considerations](docs/security_considerations.md):** A deep dive into the security architecture for the MVP's centralized API and data stores.

## Implementation (Qdrant-Sui MVP)

Explore the practical implementation of Choir's MVP architecture:

*   **[State Management Patterns](docs/state_management_patterns.md):** How state is managed within the central API and persisted in Qdrant for the MVP.
*   **[Blockchain Integration](docs/blockchain_integration.md):** Integration with Sui blockchain for the MVP.

## Context Management in the PostChain Workflow

Choir leverages the AEIOU-Y PostChain workflow to enable sophisticated context management, with each phase playing a specialized role in orchestrating the flow of knowledge within the API backend:

| Phase         | Temporal Focus       | Context Responsibility (within API Workflow)                                 | Requirements                                           |
| ------------- | -------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------ |
| Action        | Immediate present    | Initial framing and response.                                                | [Action Requirements](docs/require_action_phase.md)    |
| Experience    | Past knowledge       | Enriching context via Qdrant search (priors).                                | [Experience Requirements](docs/require_experience_phase.md) |
| Intention     | Desired future       | Focusing on user goals (using `intention_memory` in Qdrant).                 | [Intention Requirements](docs/require_intention_phase.md) |
| Observation   | Future preservation  | Structuring thread knowledge (using `observation_memory` in Qdrant).         | [Observation Requirements](docs/require_observation_phase.md) |
| Understanding | Temporal integration | Deciding what information to prune from memory collections (Qdrant).         | [Understanding Requirements](docs/require_understanding_phase.md) |
| Yield         | Process completion   | Generating the final response and preparing data for Qdrant/rewards.         | [Yield Requirements](docs/require_yield_phase.md)      |

## Business & Strategy

*   **[Business Model](docs/e_business.md):** Business model and strategy.
*   **[Anonymity by Default](docs/plan_anonymity_by_default.md):** Privacy principles.

## Vision & Future

Choir is not just building another AI application; we are building a **transformative platform for the future of AI and human collaboration**:

*   **Revolutionizing Consumer Finance:** Empowering users with AI-driven tools to optimize their financial lives and achieve financial freedom.
*   **Building a Tokenized Marketplace of Ideas:** Fostering a new kind of online platform where quality ideas are valued, rewarded, and drive the emergence of collective intelligence.
*   **Democratizing AI Training and Ownership:** Enabling users to participate in and benefit from the AI revolution, contributing to a self-improving, community-driven AI ecosystem.
*   **Creating a Data Economy:** Developing a marketplace where valuable data can be exchanged using CHOIR coins, with proper attribution and rewards for contributors.

*   **[Plan: CHOIR Materialization (Data Economy)](docs/plan_choir_materialization.md):** Long-term vision for CHOIR coin utility.

Explore the documentation sections above to understand how Choir's Qdrant-Sui MVP architecture is designed to validate the core concepts needed to realize this ambitious vision.

## Directory Structure

*   `api/`: Python backend (FastAPI application, PostChain logic, database interactions, tests).
*   `Choir/`: Swift iOS client application.
*   `choir_coin/`: Sui Move smart contract for the CHOIR coin.
*   `docs/`: Project documentation (including detailed phase requirements, architecture, etc.).
*   `notebooks/`: Jupyter notebooks for experimentation.
*   `scripts/`: Utility scripts.

## Getting Started (API Backend)

1.  **Prerequisites:** Docker, Docker Compose, Python 3.12+, Rust (for `pysui`).
2.  **Environment:** Create a `.env` file in the `api/` directory with necessary API keys (OpenAI, Anthropic, Google, Mistral, Fireworks, Cohere, Groq, OpenRouter, Qdrant, Brave, Tavily) and your `SUI_PRIVATE_KEY`.
3.  **Build & Run (Docker):**
    ```bash
    docker-compose up --build api
    ```
    The API will be available at `http://localhost:8000`. Health check: `http://localhost:8000/health`.

## Running Tests (API)

Ensure necessary API keys are set in your environment.

```bash
cd api
# Optional: Create and activate a virtual environment
# python -m venv venv
# source venv/bin/activate
pip install -r requirements.txt
pytest -v
