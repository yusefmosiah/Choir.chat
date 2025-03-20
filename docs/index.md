# Choir Documentation

## Core Concepts

The Choir platform is built around a sophisticated conceptual model implemented through an MCP-based architecture:
- [PostChain Temporal Logic](1-concepts/postchain_temporal_logic.md) - The temporal essence of each AEIOU-Y phase

## Architecture

Technical architecture and design decisions:

- [Architecture Transition Narrative](2-architecture/architecture_transition_narrative.md) - The story of our architectural evolution
- [Stack Argument](stack_argument.md) - Rationale for our technology choices

## Implementation

Practical guidance for implementation:

- [Developer Quickstart](3-implementation/developer_quickstart.md) - Fast onboarding guide
- [Message Protocol Reference](3-implementation/message_protocol_reference.md) - Comprehensive message format documentation
- [State Management Patterns](3-implementation/state_management_patterns.md) - Best practices for state

## MCP-Based Context Management

Choir's MCP architecture enables sophisticated context management through specialized phase responsibilities:

| Phase         | Temporal Focus       | Context Responsibility               |
| ------------- | -------------------- | ------------------------------------ |
| Action        | Immediate present    | Initial framing and response         |
| Experience    | Past knowledge       | Adding search results and knowledge  |
| Intention     | Desired future       | Focusing on user goals               |
| Observation   | Future preservation  | Tagging and connecting concepts      |
| Understanding | Temporal integration | Deciding what information to release |
| Yield         | Process completion   | Determining cycle continuation       |

## Documentation Roadmap

- **Current Phase**: Architecture refinement and documentation alignment
- **Next Steps**: Implementation guidance and testing framework
- **Open Questions**: Advanced context management strategies and model integration

Explore the documentation sections above to understand how Choir implements an MCP-based architecture to support the PostChain model of AI orchestration.

## Documentation Structure

The documentation is organized into the following sections:

## 1. Core Concepts

Fundamental concepts that remain consistent regardless of the implementation:
- [PostChain (AEIOU-Y) Conceptual Model](postchain_actor_model.md) - The core AEIOU-Y framework
- [FQAHO Model](fqaho_visualization.md) - The Fractional Quantum Anharmonic Oscillator economic model
- [Core Economics](core_economics.md) - Economic principles and tokenomics
- [Core State Transitions](core_state_transitions.md) - State transition principles
- [Evolution: Naming](evolution_naming.md) - Naming conventions and evolution

## 2. Architecture

Detailed information about the MCP-based architecture:
- [Stack Argument](stack_argument.md) - Rationale for the MCP-based technology stack
- [Security Considerations](security_considerations.md) - Security architecture and considerations

## 3. Implementation

Practical guidance for implementing the MCP-based architecture:
- [Developer Quickstart](3-implementation/developer_quickstart.md) - Fast onboarding for new developers
- [Migration Plan](migration_langgraph_to_actor.md) - Step-by-step migration from LangGraph to MCP
- [Message Protocol Reference](message_protocol_reference.md) - Documentation of message formats
- [State Management Patterns](3-implementation/state_management_patterns.md) - Best practices for state management

## 4. Integration

Information about integrating with external systems:

- [libSQL Integration](plan_libsql.md) - Database integration
- [Blockchain Integration](blockchain_integration.md) - Integration with Sui blockchain
- [Identity as a Service](plan_identity_as_a_service.md) - Identity management

## 5. Operations

Documentation for deployment, testing, and operations:

- [Deployment Guide](deployment_guide.md) - Instructions for deploying the MCP-based system
- [Testing Strategy](testing_strategy.md) - Approach to testing MCP-based systems
- [Monitoring and Observability](monitoring_observability.md) - Monitoring the MCP system

## 6. Business and Strategy

Business aspects of Choir:

- [Business Model](e_business.md) - Business model and strategy
- [Evolution Token](evolution_token.md) - Token design and economics
- [Anonymity by Default](plan_anonymity_by_default.md) - Privacy principles

## Archive

Documents preserved for reference but potentially outdated due to the architectural pivot:

- [LangGraph-specific documentation](archive/) - Previous architecture documents

## Development Timeline

- [Changelog](CHANGELOG.md) - Historical development timeline
- [Architecture Reorganization Plan](archive/architecture_reorganization_plan.md) - Plan for documentation updates

## Contributing to Documentation

See the [Architecture Reorganization Plan](archive/architecture_reorganization_plan.md) for information on the documentation structure and contribution guidelines.

When contributing to documentation:

1. Follow the established folder structure
2. Use Markdown for all documentation
3. Include diagrams using Mermaid.js where appropriate
4. Provide code examples for technical concepts
5. Update the index when adding new documents
