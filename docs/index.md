# Choir Documentation

Welcome to the Choir documentation. This documentation has been reorganized to reflect the architectural pivot from LangGraph to the Actor Model.

## Documentation Structure

The documentation is organized into the following sections:

## 1. Core Concepts

Fundamental concepts that remain consistent regardless of the implementation:

- [Actor Model Overview](1-concepts/actor_model_overview.md) - Introduction to the actor model architecture
- [PostChain (AEIOU-Y) Conceptual Model](postchain_actor_model.md) - The core AEIOU-Y framework
- [FQAHO Model](fqaho_visualization.md) - The Fractional Quantum Anharmonic Oscillator economic model
- [Core Economics](core_economics.md) - Economic principles and tokenomics
- [Core State Transitions](core_state_transitions.md) - State transition principles
- [Evolution: Naming](evolution_naming.md) - Naming conventions and evolution

## 2. Architecture

Detailed information about the actor-based architecture:

- [Actor System Diagrams](2-architecture/actor_system_diagram.md) - Visual representations of the actor system
- [Stack Argument](stack_argument.md) - Rationale for the actor-based technology stack
- [PostChain Actor Model](postchain_actor_model.md) - Technical implementation of PostChain using actors
- [Phase Worker Pool Architecture](phase_worker_pool_architecture.md) - Extension of the actor model with worker pools
- [Security Considerations](security_considerations.md) - Security architecture and considerations

## 3. Implementation

Practical guidance for implementing the actor-based architecture:

- [Developer Quickstart](3-implementation/developer_quickstart.md) - Fast onboarding for new developers
- [Migration Plan](migration_langgraph_to_actor.md) - Step-by-step migration from LangGraph to Actor Model
- [Actor Implementation Guide](actor_implementation_guide.md) - Detailed guidelines for implementing actors
- [Message Protocol Reference](message_protocol_reference.md) - Documentation of message formats
- [State Management Patterns](3-implementation/state_management_patterns.md) - Best practices for actor state management

## 4. Integration

Information about integrating with external systems:

- [libSQL Integration](plan_libsql.md) - Database integration
- [Blockchain Integration](blockchain_integration.md) - Integration with Sui blockchain
- [Identity as a Service](plan_identity_as_a_service.md) - Identity management

## 5. Operations

Documentation for deployment, testing, and operations:

- [Deployment Guide](deployment_guide.md) - Instructions for deploying the actor-based system
- [Testing Strategy](testing_strategy.md) - Approach to testing actor-based systems
- [Monitoring and Observability](monitoring_observability.md) - Monitoring the actor system

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
- [Architecture Reorganization Plan](architecture_reorganization_plan.md) - Plan for documentation updates

## Contributing to Documentation

See the [Architecture Reorganization Plan](architecture_reorganization_plan.md) for information on the documentation structure and contribution guidelines.

When contributing to documentation:

1. Follow the established folder structure
2. Use Markdown for all documentation
3. Include diagrams using Mermaid.js where appropriate
4. Provide code examples for technical concepts
5. Update the index when adding new documents
