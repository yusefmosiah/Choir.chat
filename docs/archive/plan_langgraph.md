# [DEPRECATED] LangGraph Plan

> **DEPRECATION NOTICE**: This document describes Choir's previous graph-based architecture using LangGraph, which has been replaced by the current actor-based architecture. It is preserved for historical reference only and should not be used for new development.
>
> **For current documentation, please refer to:**
>
> - [Actor Model Overview](../1-concepts/actor_model_overview.md)
> - [Architecture Transition Narrative](../architecture_transition_narrative.md)
> - [Migration Guide for Developers](../3-implementation/migration_guide_for_developers.md)

---

_The original document content follows below:_

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

- [x] Set up development environment with LangChain dependencies
- [x] Create test harness for evaluating individual model capabilities
- [x] Implement structured output schemas for each phase (action, experience, etc.)
- [x] Test each provider's models (OpenAI, Anthropic, Google, Mistral, etc.) with the same schemas
- [x] Document model-specific behaviors, strengths, and limitations
- [ ] Create a compatibility matrix of which models work best for which phases

### Phase 2: Tool Integration & Model-Specific Capabilities

- [ ] Implement core tools (web search, function calls, etc.)
- [ ] Test tool binding with each provider's models
- [ ] Measure response quality and tool usage patterns across providers
- [x] Implement provider-specific fallback mechanisms
- [ ] Document tool calling capabilities across providers
- [ ] Build adapter patterns to standardize tool interaction patterns

### Phase 3: Basic LangGraph Composition

- [x] Implement basic StateGraph with fixed AEIOU sequence
- [x] Create handlers for each phase using configurable model selection
- [x] Build state management system to pass context between models
- [x] Implement basic error handling and retries
- [x] Test end-to-end flow with simple prompts
- [x] Compare performance metrics with current implementation

### Phase 4: Advanced Flow Control

- [x] Add conditional edges for looping behavior (understanding → action)
- [x] Implement probability-based router logic for looping
- [x] Create recursion limit mechanism to prevent infinite loops
- [x] Test with complex multi-turn scenarios
- [x] Implement cycle detection to prevent infinite loops
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
- [x] Implement streaming support for real-time updates
- [ ] Create admin controls for monitoring chain modifications
- [ ] Build integration examples with common frameworks
- [ ] Document API usage patterns and best practices

## 4. Implementation Status

### Core Components

| Component           | Status      | Description                                                          |
| ------------------- | ----------- | -------------------------------------------------------------------- |
| State Graph         | ✅ Complete | Successfully implemented full AEIOU-Y graph with all nodes and edges |
| State Schema        | ✅ Complete | Implemented TypedDict for state management with proper annotations   |
| Phase Handlers      | ✅ Complete | Created handlers for all phases with consistent state management     |
| Conditional Routing | ✅ Complete | Implemented probability-based routing with recursion limits          |
| Error Handling      | ✅ Complete | Added comprehensive error handling for various failure cases         |
| Streaming Support   | ✅ Complete | Implemented streaming via astream methods with token callbacks       |

### Advanced Features

| Feature                    | Status         | Description                                                 |
| -------------------------- | -------------- | ----------------------------------------------------------- |
| Multi-Model Support        | 🔄 In Progress | Framework supports multiple models, API integration pending |
| Tool Integration           | 🔄 In Progress | Framework prepared for tools, implementation pending        |
| Dynamic Chain Modification | ⏱️ Planned     | Architecture supports modification, implementation pending  |
| API Endpoints              | ⏱️ Planned     | Design prepared, implementation pending                     |
| Performance Monitoring     | ⏱️ Planned     | Basic logging in place, detailed metrics pending            |

### Testing and Validation

| Test Category    | Status         | Description                                               |
| ---------------- | -------------- | --------------------------------------------------------- |
| Basic Flow       | ✅ Complete    | Verified linear progression through all phases            |
| Looping Behavior | ✅ Complete    | Tested probability-based looping with various thresholds  |
| Error Handling   | ✅ Complete    | Validated graceful recovery from various error conditions |
| Tool Usage       | 🔄 In Progress | Framework prepared, awaiting tool implementation          |
| Performance      | ⏱️ Planned     | Benchmarking framework designed, implementation pending   |

## 5. Required Dependencies

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

## 6. Compatibility Considerations

### 6.1 LangChain vs Current Implementation

| Feature           | Current Implementation | LangGraph Implementation     | Status         |
| ----------------- | ---------------------- | ---------------------------- | -------------- |
| Multiple Models   | Custom model caller    | Native LangChain integration | ✅ Implemented |
| Structured Output | Custom JSON parsing    | Schema-based validation      | ✅ Implemented |
| Chain Flow        | Linear with loop flag  | True graph with conditionals | ✅ Implemented |
| Tool Support      | Limited                | Extensive built-in tools     | 🔄 In Progress |
| Error Handling    | Basic fallbacks        | Robust retry mechanisms      | ✅ Implemented |
| State Management  | Manual                 | Graph-managed state          | ✅ Implemented |

### 6.2 Migration Strategies

1. **Incremental Approach**: Start by migrating one phase at a time, keeping the rest of the system intact
2. **Parallel Development**: Build the new system alongside the old one, gradually shifting traffic
3. **Test-First Migration**: Create comprehensive tests before migration, then ensure equivalence

## 7. Evaluation Metrics

1. **Token Efficiency**: Compare token usage between current and LangGraph implementations
2. **Latency**: Measure end-to-end response time
3. **Error Rates**: Track parsing errors, model failures, and timeouts
4. **Chain Modification Success**: Measure success rate of dynamic chain modifications
5. **Tool Usage Accuracy**: Evaluate correct tool selection and parameter passing

## 8. Next Steps

Based on our current progress, the following tasks are prioritized:

1. **Tool Integration**:

   - Implement web search tool for real-time information retrieval
   - Add function calling capabilities for common tasks
   - Create testing framework for tool usage evaluation

2. **Performance Optimization**:

   - Benchmark token usage across different models and phases
   - Identify bottlenecks in the current implementation
   - Implement caching strategies for frequently accessed content

3. **API Layer**:

   - Complete Langserve integration for API exposure
   - Create proper authentication and rate limiting
   - Design detailed monitoring and observability

4. **Documentation**:
   - Create comprehensive API documentation
   - Document best practices for custom tool development
   - Create tutorials for extending the system

## 9. Conclusion

The migration to LangGraph has made significant progress, with the core architecture successfully implemented and tested. The current implementation provides a robust foundation for the Chorus Cycle, with improved state management, error handling, and flow control. The system is now ready for the next phase of development, focusing on tool integration, performance optimization, and API exposure.

The implementation has validated the benefits of the LangGraph approach, particularly in terms of flexibility, maintainability, and extensibility. The graph-based structure allows for more complex flow patterns and better error recovery, while the standardized state management ensures consistency across phases.

The migration will continue with an incremental approach, focusing on preserving functionality while adding new capabilities. The end result will be a more powerful, flexible, and maintainable implementation of the Chorus Cycle.
