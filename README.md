# Choir: Collaborative Intelligence Infrastructure

Choir transforms AI output into collaborative intelligence infrastructure, building the economic foundation for the learning economy. We invert digital economics: instead of extracting value from users, we reward intellectual contribution through token economics and enable anonymous high-stakes coordination for knowledge creation.

## The Learning Economy Revolution

As AI generates infinite content at zero marginal cost, the attention economy collapses. New scarcities emerge: genuine insight, quality curation, collaborative synthesis, and intellectual courage. Choir creates economic incentives around these new scarcities, transforming AI from a replacement for human intelligence into infrastructure for collaborative intelligence.

## The Conductor Architecture

Choir operates through a **single AI Conductor** that orchestrates five specialized instruments, providing users with seamless access to collaborative intelligence capabilities:

### The Five Instruments

1. **Ghostwriter Instrument**: Listens to raw thoughts and rewards novelty with CHOIR tokens. No judgment on grammar or polish—focus on genuine insights that transform into structured, citable knowledge.

2. **Publisher Instrument**: Manages private-to-public publishing workflow with two paths:
   - **Anonymous Publishing**: Zero cost, zero social risk, joins the commons
   - **Identity Publishing**: Requires token staking, enables reputation building

3. **Revision Instrument**: Creates collaborative improvement markets where others stake tokens to propose improvements, creating co-owned intellectual property.

4. **Citation Instrument**: Tracks intellectual property usage across the platform, calculating ongoing royalties for foundational work and managing attribution networks.

5. **Wallet Instrument**: Provides seamless crypto infrastructure with invisible token operations, built-in mixing for anonymity, and balance management.

## Core Concepts

Explore the foundational concepts that drive Choir's collaborative intelligence:

*   **[PostChain Temporal Logic](docs/postchain_temporal_logic.md):** The temporal essence of each AEIOU-Y phase, driving dynamic and context-aware AI workflows.
*   **[Core Economics](docs/core_economics.md):** The economic principles and tokenomics of CHOIR, designed to create a sustainable and equitable ecosystem for knowledge creation.
*   **[Core State Transitions](docs/core_state_transitions.md):** The carefully defined state transitions that govern the evolution of threads and the flow of value within Choir.
*   **[Evolution: Naming](docs/evolution_naming.md):** The story behind the evolution of Choir's name, reflecting the project's journey and vision.
*   **[Evolution: Token](docs/evolution_token.md):** The evolution of the CHOIR coin concept.

## Economic Engine

Choir fundamentally inverts traditional platform economics:

### Traditional Platforms vs. Choir

- **Traditional**: Extract value from user data while charging for tools
- **Choir**: Earn tokens for sharing anonymous context, invest tokens to attach identity to refined ideas, receive ongoing income from citations

### Token Flow Mechanics

1. **Context Rewards**: Incentivize intellectual exploration through tokens for novel insights
2. **Publication Stakes**: Create quality filters through conviction-based curation
3. **Citation Income**: Reward foundational thinking with ongoing royalties
4. **Revision Markets**: Enable collaborative improvement with shared ownership
5. **Curation Compensation**: Reward quality control by paying for rejecting bad edits

### Anti-Slop Economics

Natural immunity to AI-generated low-quality content through:
- Token stakes making mass production expensive
- Citation requirements forcing grounding in existing knowledge
- Revision markets enabling rapid quality improvement
- Anonymous publishing removing performative content incentives

## Technical Architecture

*   **[Core System Overview](docs/core_core.md):** Description of the current architecture and components.
*   **[Stack Argument](docs/stack_argument.md):** The compelling rationale behind the technology choices.
*   **[Security Considerations](docs/security_considerations.md):** Security architecture for centralized API and data stores.

## Anonymous Publishing & Privacy Infrastructure

Choir enables true anonymity while maintaining economic accountability:

### Core Privacy Features

- **Centralized Mixing Network**: Users never interact directly, only through Choir
- **Anonymous Intellectual Property**: Economic benefits without surveillance
- **Cryptographic Intermediation**: Users contract with Choir, Choir contracts with others
- **Matching Only on Approval**: Anonymity until explicit collaboration consent

### Publishing Workflows

- **Anonymous Publishing**: Zero cost, zero social risk, joins commons
- **Identity Publishing**: Requires token staking, enables reputation building
- **Collaborative Approval**: Anonymous users become co-authors through approval
- **Discovery Ranking**: Stake amount drives visibility, not engagement

## Implementation

*   **[State Management Patterns](docs/state_management_patterns.md):** How state is managed within the central API and data persistence.
*   **[Blockchain Integration](docs/blockchain_integration.md):** Integration with Sui blockchain for token economics.

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

## Educational Revolution

Choir transforms education from consumption to contribution:

### From Skill Training to IP Creation

- Student assignments become cited resources earning ongoing income
- Every insight generates appreciating intellectual property
- Graduates have portfolios of appreciating assets, not just transcripts
- Real economic returns provide authentic motivation for learning

### Classroom as Knowledge Factory

- Students earn tokens for genuine insights regardless of age/credentials
- Anonymous publishing enables intellectual risk-taking without social pressure
- Citation networks reveal how ideas influence each other
- Collaborative revision teaches the true nature of knowledge creation

### B2B Education Strategy

**Market Opportunity**: Global EdTech $348B market, with institutional pricing:
- **Elementary**: $100/student/year (500 students = $50K/year)
- **High School**: $150/student/year (1K students = $150K/year)
- **University**: $100/student/year (5K students = $500K/year)
- **Premium Services**: $50K-$500K implementation consulting

## Business & Strategy

*   **[Business Model](docs/e_business.md):** Business model and strategy.
*   **[Anonymity by Default](docs/plan_anonymity_by_default.md):** Privacy principles.

## Strategic Development Path

### Phase 1: Choir App (Launching)
Intimate single-player experience bridging to multiplayer collaboration:
- Curious teenagers earning first income from creative interpretations
- Adult learners discovering their insights have value
- Experts monetizing accumulated knowledge
- Intellectuals seeking anonymous discourse without surveillance

### Phase 2: MCP Integration
Model Context Protocol server brings Choir capabilities to existing platforms:
- Access Conductor through Claude, ChatGPT, any MCP-compatible client
- Massive onboarding funnel meeting users where they are
- Graduate from free tier to full app as users discover value

### Phase 3: Institutional Adoption
Educational institutions discover Choir transforms learning:
- Schools license institutional tokens for student use
- Curricula integrate intellectual property creation
- Assessment shifts from grades to citation metrics
- Institutions compete on knowledge creation rather than prestige

### Phase 4: Essential Infrastructure
Participation becomes mandatory for competitive existence:
- Professionals need IP portfolios for career advancement
- Companies require citation metrics for thought leadership
- Anonymous commons becomes humanity's primary knowledge resource

## Alignment Solution: Economic Truth-Seeking

Choir solves AI alignment through economic incentives rather than technical constraints:
- Hallucinations can't generate citation income
- Ungrounded claims get rapidly revised away
- Quality improvements earn more than quantity production
- Collaborative building beats destructive critique

Economic rewards for clear thinking create training data with transparent reasoning chains. AI systems trained on this data develop interpretable structures because they learn from humans economically rewarded for interpretable thinking.

*   **[Plan: CHOIR Materialization (Data Economy)](docs/plan_choir_materialization.md):** Long-term vision for CHOIR coin utility.

## Directory Structure

*   `api/`: Python backend (FastAPI application, PostChain logic, database interactions, tests).
*   `Choir/`: Swift iOS client application.
*   `choir_coin/`: Sui Move smart contract for the CHOIR coin.
*   `docs/`: Project documentation (including detailed phase requirements, architecture, etc.).
*   `notebooks/`: Jupyter notebooks for experimentation.
*   `scripts/`: Utility scripts.

## Getting Started

### API Backend

1.  **Prerequisites:** Docker, Docker Compose, Python 3.12+, [uv](https://docs.astral.sh/uv/) (Python package manager).
2.  **Environment:** Create a `.env` file in the `api/` directory with necessary API keys (OpenAI, Anthropic, Google, Mistral, Groq, OpenRouter, Qdrant, Brave, Tavily) and your `SUI_PRIVATE_KEY`.
3.  **Local Development:**
    ```bash
    cd api
    uv sync                           # Install dependencies
    uv run uvicorn main:app --reload  # Start development server
    ```
4.  **Build & Run (Docker):**
    ```bash
    docker-compose up --build api
    ```
    The API will be available at `http://localhost:8000`. Health check: `http://localhost:8000/health`.

### iOS App

The Choir iOS app provides the primary user interface for the collaborative intelligence platform:

1. **Prerequisites:** Xcode 15+, iOS 17+ target
2. **Setup:** Open `Choir/Choir.xcodeproj` in Xcode
3. **Configuration:** Update API endpoints in app configuration for local development
4. **Run:** Build and run on simulator or device

## Running Tests

### API Tests

Ensure necessary API keys are set in your environment.

```bash
cd api
uv sync      # Install dependencies
uv run pytest -v
```

### iOS Tests

Run tests from Xcode or command line:

```bash
cd Choir
xcodebuild test -scheme Choir -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

Choir represents infrastructure for humanity's transition from the attention economy to the learning economy. We welcome contributions that advance:

- **Collaborative Intelligence**: AI orchestration and multi-agent coordination
- **Economic Mechanism Design**: Token economics and incentive alignment
- **Privacy Infrastructure**: Anonymous coordination and cryptographic systems
- **Educational Transformation**: Learning-to-earning workflows and IP creation
- **User Experience**: Seamless interfaces for complex collaborative workflows

See our documentation for detailed technical requirements and architectural decisions.
