# Level 3 Documentation



=== File: docs/plan_anonymity_by_default.md ===



==
plan_anonymity_by_default
==


==
anonymity_by_default.md
==

# Anonymity by Default: A Core Principle of Choir

VERSION anonymity_by_default: 7.0

Anonymity is not just a feature of Choir; it's a fundamental principle, a design choice that shapes the platform's architecture and informs its values. By making anonymity the default state for all users, Choir prioritizes privacy, freedom of expression, and the creation of a space where ideas are judged on their merits, not on the identity of their author.

**Core Tenets:**

1. **Privacy as a Fundamental Right:** Choir recognizes that privacy is a fundamental human right, essential for individual autonomy and freedom of thought. Anonymity protects users from surveillance, discrimination, and the potential chilling effects of being constantly identified and tracked online.
2. **Freedom of Expression:** Anonymity fosters a space where users can express themselves freely, without fear of judgment or reprisal. This is particularly important for discussing sensitive topics, challenging প্রচলিত norms, or exploring unconventional ideas.
3. **Focus on Ideas, Not Identities:** By separating ideas from their authors, anonymity encourages users to evaluate contributions based on their intrinsic value, rather than on the reputation or status of the contributor. This promotes a more meritocratic and intellectually rigorous environment.
4. **Protection from Bias:** Anonymity can help to mitigate the effects of unconscious bias, such as those based on gender, race, or other personal characteristics. It allows ideas to be judged on their own merits, rather than through the lens of preconceived notions about the author.
5. **Lower Barrier to Entry:** Anonymity makes it easier for new users to join the platform and start contributing, as they don't need to go through a complex verification process or share personal information.

**How Anonymity Works on Choir:**

- **Default State:** All users are anonymous by default upon joining the platform. They can interact, contribute content, and earn CHIP tokens without revealing their real-world identity.
- **Unique Identifiers:** Users are assigned unique, randomly generated identifiers that allow them to build a consistent presence on the platform without compromising their anonymity.
- **No Personal Data Collection:** Choir does not collect or store any personally identifiable information about anonymous users.
- **"Priors" and Anonymity:** The "priors" system, which shows the lineage of ideas, maintains anonymity by design. It reveals the connections between ideas, not the identities of the individuals who proposed them.

**Balancing Anonymity with Accountability:**

- **CHIP Staking:** The requirement to stake CHIP tokens to post new messages acts as a deterrent against spam and malicious behavior, even for anonymous users.
- **Community Moderation:** The platform relies on community moderation to maintain the quality of discourse and address any issues that arise.
- **Reputation Systems:** While users are anonymous by default, they can still build reputations based on the quality of their contributions, as tracked through the "priors" system and potentially through community ratings.

**The Value of Anonymity in a High-Information Environment:**

- **Encourages Honest Discourse:** Anonymity can encourage more honest and open discussions, particularly on sensitive or controversial topics.
- **Promotes Intellectual Risk-Taking:** Users may be more willing to take intellectual risks and explore unconventional ideas when they are not worried about the potential repercussions for their personal or professional lives.
- **Facilitates Whistleblowing and Dissent:** Anonymity can provide a safe space for whistleblowers and those who wish to express dissenting views without fear of retaliation.
- **Protects Vulnerable Users:** Anonymity can be particularly important for users in marginalized or vulnerable communities who may face risks if their identities are revealed.

**Conclusion:**

Anonymity by default is a core design principle of Choir, one that reflects the platform's commitment to privacy, freedom of expression, and the creation of a truly meritocratic space for the exchange of ideas. It's a bold choice in a world where online platforms increasingly demand real-name identification, but it's a choice that has the potential to unlock new levels of creativity, honesty, and collective intelligence. By prioritizing anonymity, Choir is not just building a platform; it's building a new model for online interaction, one that empowers individuals and fosters a more open and equitable exchange of ideas.

=== File: docs/plan_identity_as_a_service.md ===



==
plan_identity_as_a_service
==


# Identity as a Service (IDaaS)

VERSION identity_service: 7.1

Identity on Choir is optional yet valuable. By default, users can participate anonymously, preserving privacy and free expression. However, those who opt into KYC-based verification unlock the ability to participate in binding governance decisions, operate Social AI (SAI) agents under their account, and gain additional social trust signals. This document explains how Identity as a Service (IDaaS) fits into the Choir platform.

---

## Overview

Traditional online platforms typically force users to accept a real-name policy or harvest personal data without explicit consent. Choir takes a different stance:

• **Default Anonymity**: Everyone can read messages, post anonymously, and earn CHIP tokens without providing personal data.
• **Paid Identity**: Those requiring the social or governance benefits of verified status can pay for IDaaS, enabling official KYC-based identity on the platform.

The result is a tiered approach that preserves anonymity for casual or privacy-conscious users, while offering valuable identity features to those who want or need them.

---

## Core Principles

1. **Anonymity First**: No user is required to reveal their personal information to use the basic features of Choir.
2. **Paid Identity**: Identity verification introduces real-world accountability and signals commitment to the community.
3. **Signaling, Not Pay-to-Win**: Verified status does not grant better content visibility—it grants governance participation, the ability to run SAIs, and optional social credibility.
4. **Jurisdictional Compliance**: KYC standards vary globally, so IDaaS is flexible enough to accommodate region-specific regulations.
5. **Privacy Respect**: Despite verification, Choir stores personally identifying information offline and only retains essential proofs on-chain.

---

## Benefits of Verified Identity

- **Governance Participation**: Only verified users can submit binding on-chain votes in futarchy or other proposals.
- **SAI Operator Verification**: KYC ensures that an AI-driven account is mapped to a real individual for accountability.
- **Jurisdictional Compliance**: Verification aligns Choir with relevant regulations, which is critical for the platform’s long-term viability.

Additionally, verified accounts may enjoy intangible benefits like higher reputational trust within the community, though this is a social dynamic rather than a platform-engineered outcome.

---

## IDaaS Workflow

1. **Voluntary Enrollment**: You choose if/when to enroll in IDaaS.
2. **KYC Process**: Provide a government-issued ID or other documentation; a third-party service verifies authenticity.
3. **On-Chain Confirmation**: A non-reversible cryptographic link is posted on-chain (no personally identifying information, just proof of verification).
4. **Subscription or One-Time Fee**: Payment for IDaaS can be structured as recurring or one-time.
5. **Privileges Granted**: The verified user can now vote in binding governance proposals, run SAI agents, and optionally display a verified badge or signal in UI.

---

## Use Cases

- **Governance**: Ensuring that major decisions are made by real individuals with accountability.
- **SAI Execution**: Operating advanced AI software that can influence the platform, under the direct responsibility of a verified user.
- **Enterprise Collaboration**: In corporate settings, having verified internal team members fosters trust and ensures compliance with company or legal requirements.

---

## Monetization and Sustainability

Because IDaaS revenues support the system’s operational costs, they help offset free-tier usage by anonymous participants. This aligns the business model, ensuring that those who need additional capabilities also help fund the platform’s continued growth and stability.

---

## Conclusion

By offering Identity as a Service, Choir establishes a nuanced balance: anonymity remains a core value and default, while verified identity is treated as a premium feature. This approach ensures that governance decisions are accountable, advanced AI operations remain traceable to real individuals, and the platform remains compliant with jurisdictional regulations. Through IDaaS, Choir invites each user to choose the identity model that suits their needs, forging a new path forward for responsible digital communities.

=== File: docs/plan_langgraph.md ===



==
plan_langgraph
==


# Migration Plan: Prompt Chain to LangGraph

## Overview

This document outlines a detailed plan for migrating the current custom prompt chain (Chorus Cycle) implementation to use LangChain and LangGraph. The migration will enable:

1. Using multiple models in the same context with different providers
2. Exposing the prompt chain via API
3. Adding arbitrary tool support (web search, function calling, etc.)
4. Allowing models to dynamically modify the prompt chain

## 1. System Architecture

### Current Architecture

```
┌─────────────────────────────────────────────┐
│                 PromptChain                 │
├─────────────────────────────────────────────┤
│ ┌───────┐ ┌────────────┐ ┌──────────────┐  │
│ │ Link 1 │ │   Link 2   │ │    Link 3    │  │
│ │(Model A)│→│  (Model B) │→│   (Model C)  │  │
│ └───────┘ └────────────┘ └──────────────┘  │
└─────────────────────────────────────────────┘
```

### Target Architecture

```
┌────────────────────────────────────────────────────────────┐
│                  LangGraph Application                     │
├────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐   │
│ │                   StateGraph                         │   │
│ │ ┌───────┐      ┌────────────┐      ┌──────────────┐ │   │
│ │ │Action  │─────▶│Experience  │─────▶│  Intention   │ │   │
│ │ │(Model A)│      │ (Model B)  │      │  (Model C)   │ │   │
│ │ └───────┘      └────────────┘      └──────────────┘ │   │
│ │     ▲                                      │        │   │
│ │     │              ┌──────────────┐        │        │   │
│ │     │              │  Observation │◀───────┘        │   │
│ │     │              │  (Model D)   │                 │   │
│ │     │              └──────────────┘                 │   │
│ │     │                      │                        │   │
│ │     │              ┌──────────────┐                 │   │
│ │     │              │    Update    │                 │   │
│ │     │              │  (Model E)   │                 │   │
│ │     │              └──────────────┘                 │   │
│ │     │                      │                        │   │
│ │     └──────┐       ┌──────▼──────┐                  │   │
│ │            │       │    Yield    │                  │   │
│ │            └───────│  (Model F)  │                  │   │
│ │                    └─────────────┘                  │   │
│ └─────────────────────────────────────────────────────┘   │
│                                                            │
│ ┌─────────────────────┐  ┌───────────────────────────┐    │
│ │     Tool Registry   │  │ Dynamic Chain Modifier    │    │
│ │ ┌─────────────────┐ │  │ ┌─────────────────────┐   │    │
│ │ │  Web Search     │ │  │ │ Add Phase           │   │    │
│ │ ├─────────────────┤ │  │ ├─────────────────────┤   │    │
│ │ │  Function Call  │ │  │ │ Modify Prompt       │   │    │
│ │ ├─────────────────┤ │  │ ├─────────────────────┤   │    │
│ │ │  Data Analysis  │ │  │ │ Change Model        │   │    │
│ │ └─────────────────┘ │  │ └─────────────────────┘   │    │
│ └─────────────────────┘  └───────────────────────────┘    │
│                                                            │
│ ┌────────────────────────────────────────────────────┐    │
│ │                    LangServe API                   │    │
│ └────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────┘
```

## 2. Component Implementation Plan

### 2.1 Core State Graph (AEIOU Cycle)

The existing AEIOU cycle will be implemented as a `StateGraph` in LangGraph:

```python
from langgraph.graph import StateGraph
from typing import TypedDict, List
from langchain_core.messages import BaseMessage

# Define the state schema
class ChorusState(TypedDict):
    messages: List[BaseMessage]
    phase: str
    should_loop: bool
    context: dict

# Create the state graph
graph = StateGraph(ChorusState)

# Add nodes for each phase of the AEIOU cycle
graph.add_node("action", action_handler)
graph.add_node("experience", experience_handler)
graph.add_node("intention", intention_handler)
graph.add_node("observation", observation_handler)
graph.add_node("update", update_handler)
graph.add_node("yield", yield_handler)

# Add edges between phases
graph.add_edge("action", "experience")
graph.add_edge("experience", "intention")
graph.add_edge("intention", "observation")
graph.add_edge("observation", "update")

# Add conditional edge from update (can loop back to action or proceed to yield)
def update_router(state: ChorusState):
    if state["should_loop"]:
        return "action"
    else:
        return "yield"

graph.add_conditional_edges("update", update_router, ["action", "yield"])

# Set entry point
graph.set_entry_point("action")

# Compile the graph
chorus_chain = graph.compile()
```

### 2.2 Multi-Provider Model Integration

Set up handlers for each phase that use different model providers:

```python
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from langchain_cohere import ChatCohere

# Define models with different providers
def setup_models():
    models = {
        "action": ChatMistralAI(
            model="mistral-medium",
            response_format={"type": "json_schema", "schema": SCHEMAS["ACTION"]["schema"]}
        ),
        "experience": ChatGoogleGenerativeAI(
            model="gemini-pro",
            response_format={"type": "json_schema", "schema": SCHEMAS["EXPERIENCE"]["schema"]}
        ),
        "intention": ChatFireworks(
            model="deepseek-chat",
            response_format={"type": "json_schema", "schema": SCHEMAS["INTENTION"]["schema"]}
        ),
        "observation": ChatAnthropic(
            model="claude-3-haiku",
            response_format={"type": "json_schema", "schema": SCHEMAS["OBSERVATION"]["schema"]}
        ),
        "update": ChatFireworks(
            model="deepseek-chat",
            response_format={"type": "json_schema", "schema": SCHEMAS["UPDATE"]["schema"]}
        ),
        "yield": ChatCohere(
            model="command-r",
            response_format={"type": "json_schema", "schema": SCHEMAS["YIELD"]["schema"]}
        )
    }
    return models
```

### 2.3 Node Handlers Implementation

Create handlers for each node in the graph:

```python
from langchain_core.prompts import ChatPromptTemplate

# Example handler for the action phase
def create_action_handler(model, system_prompt):
    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", "{input}")
    ])

    chain = prompt | model

    def action_handler(state: ChorusState):
        # Extract the user input from the messages
        user_input = state["messages"][-1].content if state["messages"] else ""

        # Get model response
        response = chain.invoke({"input": user_input})

        # Update state
        new_state = state.copy()
        new_state["phase"] = "action"
        new_state["context"] = {"action_result": response}

        return new_state

    return action_handler

# Create handlers for each phase
def setup_handlers(models, system_prompts):
    handlers = {}
    for phase in ["action", "experience", "intention", "observation", "update", "yield"]:
        handlers[phase] = create_handler_for_phase(
            phase,
            models[phase],
            system_prompts[phase]
        )
    return handlers
```

### 2.4 Tool Integration

Implement a tool registry and tools for the models to use:

```python
from langchain.tools import Tool
from langchain_community.tools import DuckDuckGoSearchRun
from langchain_core.tools import tool

# Create web search tool
search_tool = DuckDuckGoSearchRun()

# Create custom tool for adding a phase to the chain
@tool
def add_chain_phase(phase_name: str, system_prompt: str, position: str):
    """Add a new phase to the prompt chain.

    Args:
        phase_name: The name of the new phase
        system_prompt: The system prompt for the new phase
        position: Where to add the phase (e.g., "after:observation")
    """
    # Implementation will be handled separately
    return f"Added new phase: {phase_name} at position {position}"

# Register tools
tools = [
    search_tool,
    add_chain_phase
]

# Add tools to models that support function calling
def add_tools_to_models(models, tools):
    for phase, model in models.items():
        if hasattr(model, "bind_tools"):
            models[phase] = model.bind_tools(tools)
    return models
```

### 2.5 Dynamic Chain Modification

Implement the mechanism for dynamically modifying the chain:

```python
class ChainModifier:
    def __init__(self, graph):
        self.graph = graph
        self.compiled_chain = None

    def add_phase(self, phase_name, system_prompt, position):
        # Parse position (e.g., "after:observation")
        position_type, reference_phase = position.split(":")

        # Create new model for this phase
        new_model = ChatOpenAI(
            model="gpt-3.5-turbo-0125",
            response_format={"type": "json"}
        )

        # Create handler for new phase
        new_handler = create_handler_for_phase(
            phase_name,
            new_model,
            system_prompt
        )

        # Add node to graph
        self.graph.add_node(phase_name, new_handler)

        # Update edges based on position
        if position_type == "after":
            # Get the current outgoing edge
            next_phase = self.graph.get_next_node(reference_phase)

            # Remove existing edge
            self.graph.remove_edge(reference_phase, next_phase)

            # Add new edges
            self.graph.add_edge(reference_phase, phase_name)
            self.graph.add_edge(phase_name, next_phase)

        # Recompile the graph
        self.compiled_chain = self.graph.compile()
        return self.compiled_chain
```

### 2.6 API Integration with LangServe

Expose the chain as an API using LangServe:

```python
from fastapi import FastAPI
from langserve import add_routes

# Initialize FastAPI app
app = FastAPI(title="Chorus Chain API")

# Add routes for the chain
add_routes(
    app,
    chorus_chain,
    path="/chorus",
    input_type=ChorusInput,  # Define this pydantic model
    output_type=ChorusOutput, # Define this pydantic model
)

# Add route for modifying the chain
@app.post("/modify_chain")
async def modify_chain(modification: ChainModification):
    result = chain_modifier.add_phase(
        modification.phase_name,
        modification.system_prompt,
        modification.position
    )
    return {"status": "success", "message": f"Added phase: {modification.phase_name}"}
```

## 3. Implementation Phases

### Phase 1: Individual Model Structured Output Testing

- [ ] Set up development environment with LangChain dependencies
- [ ] Create test harness for evaluating individual model capabilities
- [ ] Implement structured output schemas for each phase (action, experience, etc.)
- [ ] Test each provider's models (OpenAI, Anthropic, Google, Mistral, etc.) with the same schemas
- [ ] Document model-specific behaviors, strengths, and limitations
- [ ] Create a compatibility matrix of which models work best for which phases

### Phase 2: Tool Integration & Model-Specific Capabilities

- [ ] Implement core tools (web search, function calls, etc.)
- [ ] Test tool binding with each provider's models
- [ ] Measure response quality and tool usage patterns across providers
- [ ] Implement provider-specific fallback mechanisms
- [ ] Document tool calling capabilities across providers
- [ ] Build adapter patterns to standardize tool interaction patterns

### Phase 3: Basic LangGraph Composition

- [ ] Implement basic StateGraph with fixed AEIOU sequence
- [ ] Create handlers for each phase using the optimal model from Phase 1
- [ ] Build state management system to pass context between models
- [ ] Implement basic error handling and retries
- [ ] Test end-to-end flow with simple prompts
- [ ] Compare performance metrics with current implementation

### Phase 4: Advanced Flow Control

- [ ] Add conditional edges for looping behavior (update → action)
- [ ] Implement router logic to allow models to choose next phases dynamically
- [ ] Create branching capabilities based on content/query types
- [ ] Test with complex multi-turn scenarios
- [ ] Implement cycle detection to prevent infinite loops
- [ ] Measure performance impact of dynamic routing

### Phase 5: Self-Modifying Chains

- [ ] Create specialized tools for prompt engineering and chain modification
- [ ] Allow models to define new graph nodes and edges
- [ ] Implement safety guardrails for model-generated prompts and tools
- [ ] Build validation system for dynamically created components
- [ ] Test various scenarios of chain self-modification
- [ ] Create observability layer to track chain evolution

### Phase 6: API & Integration

- [ ] Integrate into Choir api
- [ ] Create standardized input/output schemas
- [ ] Add authentication and rate limiting
- [ ] Implement logging and telemetry
- [ ] Create admin controls for monitoring chain modifications
- [ ] Build integration examples with common frameworks
- [ ] Document API usage patterns and best practices

## 4. Required Dependencies

```
langchain>=0.1.0
langchain-core>=0.1.0
langgraph>=0.0.15
langserve>=0.0.30
langchain-openai>=0.0.5
langchain-anthropic>=0.1.0
langchain-google-genai>=0.0.5
langchain-mistralai>=0.0.1
langchain-fireworks>=0.1.0
langchain-cohere>=0.0.1
pydantic>=2.0.0
fastapi>=0.104.0
uvicorn>=0.24.0
```

## 5. Compatibility Considerations

### 5.1 LangChain vs Current Implementation

| Feature           | Current Implementation | LangGraph Implementation     |
| ----------------- | ---------------------- | ---------------------------- |
| Multiple Models   | Custom model caller    | Native LangChain integration |
| Structured Output | Custom JSON parsing    | Schema-based validation      |
| Chain Flow        | Linear with loop flag  | True graph with conditionals |
| Tool Support      | Limited                | Extensive built-in tools     |
| Error Handling    | Basic fallbacks        | Robust retry mechanisms      |
| State Management  | Manual                 | Graph-managed state          |

### 5.2 Migration Strategies

1. **Incremental Approach**: Start by migrating one phase at a time, keeping the rest of the system intact
2. **Parallel Development**: Build the new system alongside the old one, gradually shifting traffic
3. **Test-First Migration**: Create comprehensive tests before migration, then ensure equivalence

## 6. Evaluation Metrics

1. **Token Efficiency**: Compare token usage between current and LangGraph implementations
2. **Latency**: Measure end-to-end response time
3. **Error Rates**: Track parsing errors, model failures, and timeouts
4. **Chain Modification Success**: Measure success rate of dynamic chain modifications
5. **Tool Usage Accuracy**: Evaluate correct tool selection and parameter passing

## 7. Future Extensions

1. **Multi-Agent Orchestration**: Expand to multiple cooperating agents
2. **Memory Management**: Add vector database integration for long-term context
3. **Supervised Fine-Tuning**: Create training datasets from successful chain executions
4. **Custom Model Integration**: Add support for self-hosted models
5. **Chain Visualization**: Create a UI for visualizing and modifying the chain

## 8. Conclusion

This migration plan provides a structured approach to convert the existing prompt chain implementation to LangGraph. The resulting system will be more flexible, maintainable, and extensible, while preserving the core AEIOU cycle functionality. The migration can be performed incrementally, ensuring minimal disruption to existing operations.

=== File: docs/plan_langgraph_postchain.md ===



==
plan_langgraph_postchain
==


# LangGraph PostChain Implementation Plan

## Current Implementation Overview

The current Chorus Cycle implementation is a sequence of calls to a single LLM with RAG to a single vector database. The cycle follows the AEIOU-Y pattern:

1. **Action**: Initial response with "beginner's mind"
2. **Experience**: Enrichment with prior knowledge via RAG
3. **Intention**: Analysis of planned actions and consequences
4. **Observation**: Reflection on analysis and intentions
5. **Understanding**: Decision to loop back or proceed to yield
6. **Yield**: Final synthesized response

Each step uses the same model (currently Claude 3.5 Haiku) with different system prompts, and the cycle can loop back from Understanding to Action if needed.

## Migration Goals

1. Implement the Chorus Cycle using LangGraph's StateGraph
2. Create a multi-model workflow where different models handle different steps
3. Add agentic capabilities with tools and dynamic routing
4. Improve observability and debugging
5. Enable dynamic chain modification

## Revised Implementation Approach

Our implementation approach will be highly iterative, focusing on validating each component individually before composition:

1. **Environment Setup**: First, add dependencies and configure API keys for all providers
2. **Individual Model Testing**: Test each model in isolation before integration
3. **Basic LangGraph**: Start with a simple single-node graph before building complexity
4. **Incremental Integration**: Add components one at a time with thorough testing
5. **Feature Tracking**: Use a checklist approach to track progress empirically


## Implementation Checklist

### Phase 0: Environment Setup and Dependency Testing
- [ ] Add LangGraph and related dependencies to requirements.txt
  ```
  langchain>=0.1.0
  langchain-core>=0.1.0
  langgraph>=0.0.15
  langserve>=0.0.30
  langchain-openai>=0.0.5
  langchain-anthropic>=0.1.0
  langchain-google-genai>=0.0.5
  langchain-mistralai>=0.0.1
  langchain-fireworks>=0.1.0
  langchain-cohere>=0.0.1
  ```
- [x] Understanding environment with necessary API keys for all providers
- [x] Create simple test script to verify API connectivity with each provider
- [ ] Document API rate limits and token quotas for each provider

### Phase 1: Individual Model Testing
- [x] Test each model in simple single-turn conversations
- [x] Test each model in multi-turn conversations
  - [x] Verify context window handling
  - [x] Test conversation memory
- [x] Test structured output capabilities of each model
  - [x] JSON schema validation
  - [ ] Error handling for malformed outputs
  - [ ] Consistency across multiple calls
- [ ] Create compatibility matrix documenting strengths/weaknesses of each model

### Phase 2: Basic LangGraph Integration
- [x] Set up project structure for PostChain
- [x] Implement state schema with Pydantic
- [x] Create simple single-node graph with one model
- [ ] Test state transitions and data flow
- [ ] Expand to basic linear chain with 2-3 steps
- [ ] Implement basic error handling and recovery

### Phase 3: Multi-Model Integration
- [ ] Define model configuration for each step
- [ ] Create model selection logic
- [ ] Implement node handlers for each step
- [ ] Test cross-model context preservation
- [ ] Evaluate performance and token usage
- [ ] Optimize prompt templates for each model

### Phase 4: Tool Integration
- [ ] Implement basic tools (web search, retrieval)
- [ ] Test tool compatibility with each model
- [ ] Create tool registry
- [ ] Implement tool usage tracking
- [ ] Test error handling for tool failures
- [ ] Measure tool effectiveness

### Phase 5: Advanced Flow Control
- [ ] Implement conditional edges
- [ ] Create dynamic routing based on model outputs
- [ ] Add web search node
- [ ] Test complex flows with branching
- [ ] Implement cycle detection
- [ ] Create visualization of graph execution

### Phase 6: API Integration
- [ ] Create API endpoints
- [ ] Implement streaming support
- [ ] Add authentication and rate limiting
- [ ] Create client library
- [ ] Test API performance
- [ ] Document API usage

### Phase 7: Observability and Testing
- [ ] Add tracing and logging
- [ ] Create comprehensive test suite
- [ ] Implement performance monitoring
- [ ] Create debugging tools
- [ ] Document troubleshooting procedures
- [ ] Conduct end-to-end testing

## Conclusion

This implementation plan provides a structured approach to migrating the current Chorus Cycle to a multi-model agentic workflow using LangGraph. The resulting system will be more flexible, maintainable, and powerful, while preserving the core AEIOU-Y cycle functionality.

The migration can be performed incrementally, starting with a basic LangGraph implementation and gradually adding more advanced features like multi-model support, tool integration, and dynamic routing. This approach allows for continuous testing and evaluation throughout the development process.

The final system will leverage the strengths of different models for different steps of the cycle, use tools to enhance capabilities, and provide better observability and debugging features. It will also be more extensible, allowing for future enhancements like multi-agent orchestration, memory management, and custom model integration.

=== File: docs/plan_libsql.md ===



==
plan_libsql
==


# libSQL Integration Plan for Choir

## Overview

This document outlines the implementation plan for integrating libSQL/Turso as the local persistence layer for the Choir application. This system will provide both offline functionality and synchronization with our global vector database infrastructure, while supporting the FQAHO model parameters and Post Chain architecture.

## Core Objectives

1. Implement libSQL as the primary local persistence solution
2. Design a flexible schema that can accommodate evolving data models
3. Implement vector search capabilities to support semantic matching in the Experience phase
4. Create a synchronization system between local and global databases
5. Support the FQAHO model parameters (α, K₀, m) in the database schema
6. Enable offline functionality with seamless online synchronization

## Implementation Philosophy

Our approach to database implementation will be guided by these principles:

1. **Core System First** - Focus on getting the core UX and system operational before fully committing to a database schema
2. **Flexibility** - Design the database to be adaptable as our data model evolves
3. **Incremental Implementation** - Add database features in phases, starting with the most essential components
4. **Performance** - Optimize for mobile device constraints and offline-first operation

## Technical Implementation

### 1. Database Setup and Initialization

```swift
import Libsql

class DatabaseService {
    static let shared = try! DatabaseService()

    private let database: Database
    private let connection: Connection

    private init() throws {
        // Get path to document directory for local database
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = documentsDirectory.appendingPathComponent("choir.db").path

        // Initialize database with sync capabilities
        self.database = try Database(
            path: dbPath,
            url: Environment.tursoDbUrl,      // Remote database URL
            authToken: Environment.tursoToken, // Authentication token
            syncInterval: 10000               // Sync every 10 seconds
        )

        self.connection = try database.connect()

        // Initialize schema
        try setupSchema()
    }

    private func setupSchema() throws {
        try connection.execute("""
            -- Users table
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                name TEXT,
                last_active INTEGER
            );

            -- Threads table
            CREATE TABLE IF NOT EXISTS threads (
                id TEXT PRIMARY KEY,
                title TEXT,
                created_at INTEGER,
                updated_at INTEGER,
                k0 REAL,           -- FQAHO parameter K₀
                alpha REAL,        -- FQAHO parameter α (fractional)
                m REAL             -- FQAHO parameter m
            );

            -- Messages table with vector support
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                thread_id TEXT,
                user_id TEXT,
                content TEXT,
                embedding F32_BLOB(1536),  -- Vector embedding for semantic search
                phase TEXT,                -- Post Chain phase identifier
                created_at INTEGER,
                approval_status TEXT,      -- For approval/refusal statistics
                FOREIGN KEY(thread_id) REFERENCES threads(id),
                FOREIGN KEY(user_id) REFERENCES users(id)
            );

            -- Vector index for similarity search in Experience phase
            CREATE INDEX IF NOT EXISTS messages_embedding_idx
            ON messages(libsql_vector_idx(embedding));

            -- Parameter history for FQAHO model tracking
            CREATE TABLE IF NOT EXISTS parameter_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                thread_id TEXT,
                timestamp INTEGER,
                k0 REAL,
                alpha REAL,
                m REAL,
                event_type TEXT,  -- What caused the parameter change
                FOREIGN KEY(thread_id) REFERENCES threads(id)
            );
        """)
    }
}
```

### 2. Thread and Message Operations

```swift
extension DatabaseService {
    // MARK: - Thread Operations

    func createThread(id: String, title: String, k0: Double, alpha: Double, m: Double) throws {
        let now = Int(Date().timeIntervalSince1970)

        try connection.execute("""
            INSERT INTO threads (id, title, created_at, updated_at, k0, alpha, m)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, [id, title, now, now, k0, alpha, m])

        // Record initial parameters
        try connection.execute("""
            INSERT INTO parameter_history (thread_id, timestamp, k0, alpha, m, event_type)
            VALUES (?, ?, ?, ?, ?, ?)
        """, [id, now, k0, alpha, m, "thread_creation"])
    }

    func getThread(id: String) throws -> Thread? {
        let results = try connection.query(
            "SELECT * FROM threads WHERE id = ?",
            [id]
        )

        guard let result = results.first else { return nil }

        return Thread(
            id: result["id"] as! String,
            title: result["title"] as! String,
            createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(result["updated_at"] as! Int)),
            k0: result["k0"] as! Double,
            alpha: result["alpha"] as! Double,
            m: result["m"] as! Double
        )
    }

    func updateThreadParameters(threadId: String, k0: Double, alpha: Double, m: Double, eventType: String) throws {
        let now = Int(Date().timeIntervalSince1970)

        // Update thread
        try connection.execute("""
            UPDATE threads
            SET k0 = ?, alpha = ?, m = ?, updated_at = ?
            WHERE id = ?
        """, [k0, alpha, m, now, threadId])

        // Record parameter change
        try connection.execute("""
            INSERT INTO parameter_history (thread_id, timestamp, k0, alpha, m, event_type)
            VALUES (?, ?, ?, ?, ?, ?)
        """, [threadId, now, k0, alpha, m, eventType])
    }

    // MARK: - Message Operations

    func createMessage(id: String, threadId: String, userId: String, content: String,
                       embedding: [Float], phase: String) throws {
        let now = Int(Date().timeIntervalSince1970)
        let vectorString = "vector32('\(embedding)')"

        try connection.execute("""
            INSERT INTO messages (id, thread_id, user_id, content, embedding, phase, created_at, approval_status)
            VALUES (?, ?, ?, ?, \(vectorString), ?, ?, 'pending')
        """, [id, threadId, userId, content, phase, now])

        // Update thread's last activity
        try connection.execute("""
            UPDATE threads
            SET updated_at = ?
            WHERE id = ?
        """, [now, threadId])
    }

    func updateMessageApprovalStatus(messageId: String, status: String) throws {
        try connection.execute("""
            UPDATE messages
            SET approval_status = ?
            WHERE id = ?
        """, [status, messageId])

        // If we wanted to update FQAHO parameters based on approval/refusal, we could do that here
        if let message = try getMessage(id: messageId),
           let thread = try getThread(id: message.threadId) {

            // Calculate new parameters based on approval/refusal
            let newK0 = calculateNewK0(currentK0: thread.k0, approvalStatus: status)
            let newAlpha = calculateNewAlpha(currentAlpha: thread.alpha, approvalStatus: status)
            let newM = calculateNewM(currentM: thread.m, approvalStatus: status)

            try updateThreadParameters(
                threadId: message.threadId,
                k0: newK0,
                alpha: newAlpha,
                m: newM,
                eventType: "message_\(status)"
            )
        }
    }

    func getMessage(id: String) throws -> Message? {
        let results = try connection.query(
            "SELECT * FROM messages WHERE id = ?",
            [id]
        )

        guard let result = results.first else { return nil }

        return Message(
            id: result["id"] as! String,
            threadId: result["thread_id"] as! String,
            userId: result["user_id"] as! String,
            content: result["content"] as! String,
            phase: result["phase"] as! String,
            createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
            approvalStatus: result["approval_status"] as! String
        )
    }
}
```

### 3. Vector Search for Experience Phase

```swift
extension DatabaseService {
    // Find semantically similar messages for the Experience phase
    func findSimilarExperiences(threadId: String, queryEmbedding: [Float], limit: Int = 5) throws -> [Message] {
        let vectorString = "vector32('\(queryEmbedding)')"

        let results = try connection.query("""
            SELECT m.*
            FROM vector_top_k('messages_embedding_idx', \(vectorString), ?) as v
            JOIN messages m ON m.rowid = v.id
            WHERE m.thread_id = ?
            AND m.approval_status = 'approved'
        """, [limit, threadId])

        return results.map { result in
            Message(
                id: result["id"] as! String,
                threadId: result["thread_id"] as! String,
                userId: result["user_id"] as! String,
                content: result["content"] as! String,
                phase: result["phase"] as! String,
                createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
                approvalStatus: result["approval_status"] as! String
            )
        }
    }

    // Get experiences with prior parameter values (for display in Experience step)
    func getExperiencesWithPriors(threadId: String, limit: Int = 10) throws -> [(Message, ParameterSet)] {
        let results = try connection.query("""
            SELECT m.*, p.k0, p.alpha, p.m
            FROM messages m
            JOIN parameter_history p ON
                m.thread_id = p.thread_id AND
                m.created_at >= p.timestamp
            WHERE m.thread_id = ?
            AND m.phase = 'experience'
            ORDER BY m.created_at DESC
            LIMIT ?
        """, [threadId, limit])

        return results.map { result in
            let message = Message(
                id: result["id"] as! String,
                threadId: result["thread_id"] as! String,
                userId: result["user_id"] as! String,
                content: result["content"] as! String,
                phase: result["phase"] as! String,
                createdAt: Date(timeIntervalSince1970: TimeInterval(result["created_at"] as! Int)),
                approvalStatus: result["approval_status"] as! String
            )

            let parameters = ParameterSet(
                k0: result["k0"] as! Double,
                alpha: result["alpha"] as! Double,
                m: result["m"] as! Double
            )

            return (message, parameters)
        }
    }
}
```

### 4. Synchronization Management

```swift
extension DatabaseService {
    // Trigger manual sync with remote database
    func syncWithRemote() throws {
        try database.sync()
    }

    // Check if a sync is needed
    var needsSync: Bool {
        // Implementation depends on how we track local changes
        // Could check for pending operations or time since last sync
        return true
    }

    // Handle network status changes
    func handleNetworkStatusChange(isOnline: Bool) {
        if isOnline && needsSync {
            do {
                try syncWithRemote()
            } catch {
                print("Sync error: \(error)")
                // Handle sync failure
            }
        }
    }
}
```

### 5. FQAHO Parameter Calculation Functions

```swift
extension DatabaseService {
    // Calculate new K₀ value based on approval/refusal
    private func calculateNewK0(currentK0: Double, approvalStatus: String) -> Double {
        // Implementation of FQAHO model K₀ adjustment
        let adjustment: Double = approvalStatus == "approved" ? 0.05 : -0.08
        return max(0.1, min(10.0, currentK0 + adjustment))
    }

    // Calculate new α value based on approval/refusal
    private func calculateNewAlpha(currentAlpha: Double, approvalStatus: String) -> Double {
        // Implementation of FQAHO model α adjustment
        // Fractional parameter capturing memory effects
        let adjustment: Double = approvalStatus == "approved" ? 0.02 : -0.03
        return max(0.1, min(2.0, currentAlpha + adjustment))
    }

    // Calculate new m value based on approval/refusal
    private func calculateNewM(currentM: Double, approvalStatus: String) -> Double {
        // Implementation of FQAHO model m adjustment
        let adjustment: Double = approvalStatus == "approved" ? -0.01 : 0.02
        return max(0.5, min(5.0, currentM + adjustment))
    }
}
```

## Phased Implementation Approach

Given that UX has more pressing issues and the data model is still evolving, we'll adopt a phased approach to database implementation:

### Phase 1: Core UX Development (Current Focus)

- Continue developing the core UI and interaction flow
- Prioritize UX improvements over database implementation
- Use in-memory or mock data for testing

### Phase 2: Schema Development and Validation

- Finalize initial schema design as the core system stabilizes
- Create prototypes to validate the schema with real usage patterns
- Ensure the schema can adapt to evolving requirements

### Phase 3: Basic Database Implementation

- Implement basic CRUD operations for threads and messages
- Set up the database connection and initialization
- Create simplified data services for the UI to consume

### Phase 4: Vector Search Implementation

- Add vector embedding storage and search
- Connect the Experience phase to vector similarity search
- Optimize for performance and memory usage

### Phase 5: FQAHO Parameter Support

- Implement parameter storage and history tracking
- Add parameter calculation algorithms
- Connect parameter adjustments to the UI

### Phase 6: Synchronization

- Configure embedded replicas
- Implement sync management
- Handle offline/online transitions

## Integration with Post Chain Phases

The libSQL implementation will support all phases of the Post Chain:

1. **Action** - Store user messages and initial parameters
2. **Experience** - Use vector search to find relevant prior experiences
3. **Understanding** - Track message reactions and parameter adjustments
4. **Web Search** - Store search results with vector embeddings for future reference
5. **Tool Use** - Record tool usage patterns and outcomes

## Flexible Schema Design Principles

Since the data model is still evolving, the database schema should follow these principles:

1. **Versioned Schema** - Include version markers in the schema to facilitate future migrations
2. **Nullable Fields** - Use nullable fields where appropriate to accommodate evolving requirements
3. **Isolated Tables** - Keep related concepts in separate tables to minimize the impact of changes
4. **Extensible Records** - Consider using a JSON or blob field for attributes that might change frequently
5. **Minimal Dependencies** - Limit foreign key constraints to essential relationships

## Future Considerations

1. **Multi-device Sync**

   - Ensure consistent user experience across devices
   - Handle conflict resolution

2. **Advanced Vector Quantization**

   - Implement quantization for more efficient storage
   - Optimize for mobile device constraints

3. **Partitioned User Databases**

   - Implement per-user database isolation
   - Support multi-tenancy within the app

4. **Backup and Recovery**

   - Implement regular backup mechanisms
   - Create recovery procedures

5. **Extensions for Multimodal Support**
   - Extend schema for image and audio data
   - Implement multimodal vector embeddings

## Resources

- [Turso Swift Documentation](https://docs.turso.tech/swift)
- [libSQL Swift GitHub Repository](https://github.com/tursodatabase/libsql-swift)
- [Embedded Replicas Documentation](https://docs.turso.tech/embedded-replicas)
- [Vector Search Documentation](https://docs.turso.tech/vector-search)

=== File: docs/plan_postchain_checklist.md ===



==
plan_postchain_checklist
==


# PostChain Implementation Checklist

This checklist provides step-by-step instructions for setting up the PostChain project, implementing the missing `chorus_graph.py`, resolving directory and import issues, and running the test suite. Follow each step carefully to ensure a coherent and functional integration.

---

## 1. Verify and Correct Directory Structure

- [x] Ensure the project directory follows this structure:
  ```
  Choir/
  ├── api/
  │   ├── app/
  │   │   ├── chorus_graph.py    # <-- Ensure this file exists
  │   │   └── postchain/
  │   │       ├── __init__.py
  │   │       └── schemas/
  │   │           ├── __init__.py
  │   │           ├── aeiou.py
  │   │           └── state.py
  │   └── tests/
  │       └── postchain/
  │           ├── __init__.py
  │           ├── test_cases.py
  │           ├── test_framework.py
  │           └── analysis.py
  └── tests/
      └── postchain/
          ├── __init__.py
          ├── test_cases.py
          ├── test_framework.py
          └── analysis.py
  ```
- [x] Consolidate tests into a single directory (at `api/tests/postchain`) to avoid duplication.

---

## 2. Implement the Missing `chorus_graph.py`

- [ ] Create the file `api/app/chorus_graph.py` if it does not exist.
- [ ] Add a minimal implementation with handlers for each phase:
  - `action_handler`
  - `experience_handler`
  - `intention_handler`
  - `observation_handler`
  - `understanding_handler` (includes looping decision logic)
  - `yield_handler`
- [ ] Define edges to connect phases and use conditional edges for looping from `understanding` to either `action` or `yield`.
- [ ] Looping at understanding is to be handled by a looping probability from 0 to 1. each understanding phase is parameterized by this threshhold. the user and the system will be able to pass in their own probabilities to multiply. so a user signal of 0.0 or a system signal of 0.0 is looping: false.

---

## 3. Fix Import Issues in Tests

- [ ] Update import statements in `tests/postchain/test_cases.py` to use absolute paths:
  ```python
  from tests.postchain.test_framework import PostChainTester
  from api.app.chorus_graph import create_chorus_graph
  ```
- [x] Ensure each test directory has an `__init__.py` file.

---

## 4. Ensure PYTHONPATH is Correct

#what is this about??? i dont understand

- [ ] Set the `PYTHONPATH` when running tests:
  ```bash
  PYTHONPATH=. pytest tests/postchain/test_cases.py -v
  ```
- [ ] Alternatively, create a `pytest.ini` at the project root with the following configuration:
  ```ini
  [pytest]
  pythonpath = .
  asyncio_mode = auto
  ```

---

## 5. Verify Dependencies

- [ ] Install all necessary dependencies:
  ```bash
  pip install pytest pytest-asyncio langgraph pandas matplotlib seaborn
  ```
- [ ] Ensure your virtual environment is activated and properly set up.

---

## 6. Run Your Tests

- [ ] Execute the test suite using:
  ```bash
  pytest tests/postchain/test_cases.py -v
  ```

---

## 7. Confirm Coherence

- [ ] Verify that the schemas exist and are correctly defined:
  - `api/app/postchain/schemas/aeiou.py` should define `AEIOUResponse`.
  - `api/app/postchain/schemas/state.py` should define `ChorusState`.
- [ ] Ensure that each phase handler returns a consistent state structure.
- [ ] Confirm all test cases align with the implemented handlers and schemas.

---

## 8. Final Verification and Next Steps

- [ ] Run the tests and confirm they execute without errors.
- [ ] Expand the handlers with real model integrations as required.
- [ ] Implement detailed logging and analysis once the basic test suite is stable.
- [ ] Integrate tool binding and persistence layers in subsequent iterations.

---

## Troubleshooting Tips

- [ ] If you encounter import issues, double-check the `__init__.py` files and PYTHONPATH settings.
- [ ] Verify directory structure carefully to resolve any ambiguity between `api/tests/postchain` and `tests/postchain`.
- [ ] Monitor logs in `tests/postchain_tests.log` for detailed error and event traces.

This checklist serves as a guide to ensure your PostChain implementation and test suite are correctly structured and functional. Follow it step-by-step to address any issues and facilitate smooth integration and testing.

9. Logging and Observability
[ ] Implement structured logging for each phase handler to capture:
Phase name
Input state
Output state
Confidence scores
Reasoning text
Timestamps
[ ] Ensure logs are stored in a structured format (e.g., JSONL) for easy analysis.
[ ] Set up centralized logging infrastructure (optional but recommended for production).
10. Error Handling and Robustness
[ ] Define clear error handling strategies for each phase:
Model API failures
Schema validation errors
Unexpected state transitions
[ ] Implement retry mechanisms with exponential backoff for transient errors.
[ ] Ensure graceful degradation and informative error messages for end-users.
11. Performance and Scalability
[ ] Benchmark the performance of each phase individually and the entire PostChain.
[ ] Identify bottlenecks and optimize critical paths.
[ ] Plan for future scalability (e.g., parallel processing, caching strategies).
12. Documentation and Knowledge Sharing
[ ] Document each phase handler clearly, including:
Purpose and responsibilities
Input/output schemas
Dependencies and external integrations
[ ] Maintain up-to-date conceptual documentation reflecting the current architecture.
[ ] Regularly update the checklist and documentation as the implementation evolves.
