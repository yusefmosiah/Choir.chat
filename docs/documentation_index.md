# Choir Documentation Index

## Core Concepts

These documents describe the fundamental concepts that remain consistent regardless of the underlying implementation:

- [PostChain (AEIOU-Y) Conceptual Model](postchain_actor_model.md) - The core AEIOU-Y Chorus Cycle framework
- [FQAHO Model](fqaho_visualization.md) - The Fractional Quantum Anharmonic Oscillator economic model
- [Core Economics](core_economics.md) - Economic principles and tokenomics
- [Core State Transitions](core_state_transitions.md) - State transition principles
- [Evolution: Naming](evolution_naming.md) - Naming conventions and evolution

## Architecture Documentation

These documents describe the new MCP-based architecture:
- [Stack Argument](stack_argument.md) - Rationale for the MCP-based technology stack
- [Security Considerations](security_considerations.md) - Security architecture and considerations

## Migration Documents

These documents guide the transition from LangGraph to the MCP architecture:

- [Migration Plan](migration_langgraph_to_actor.md) - Step-by-step migration plan
- [Migration Checklist](plan_postchain_migration_checklist.md) - (Needs update for MCP architecture)

## Implementation Guidelines

These documents provide practical guidance for implementation:

- [Actor Development Guidelines](actor_development_guidelines.md) - (To be created)
- [Message Protocol Design](message_protocol_design.md) - (To be created)
- [State Persistence Patterns](state_persistence_patterns.md) - (To be created)

## Integration Documentation

These documents cover integration with external systems:

- [libSQL Integration](plan_libsql.md) - Database integration (to be updated for MCP architecture)
- [Blockchain Integration](blockchain_integration.md) - (To be created)
- [Identity as a Service](plan_identity_as_a_service.md) - Identity management

## Testing and Deployment

These documents cover testing, deployment, and operations:

- [Testing Strategy](testing_strategy.md) - (To be created)
- [Deployment Guide](deployment_guide.md) - (To be created)
- [Monitoring and Observability](monitoring_observability.md) - (To be created)

## Business and Strategy

These documents cover business aspects of Choir:

- [Business Model](e_business.md) - Business model and strategy
- [Evolution Token](evolution_token.md) - Token design and economics

## Archive

These documents are preserved for reference but may be outdated due to the architectural pivot:

- [LangGraph PostChain Plan](plan_langgraph_postchain.md) - Previous LangGraph architecture (archived)
- [LangGraph PostChain Iteration](plan_langgraph_postchain_iteration.md) - Previous iteration plan (archived)
- [PostChain Graph API Checklist](plan_postchain_graph_api_checklist.md) - Previous API plans (archived)
- [Tools Qdrant Checklist](plan_tools_qdrant_checklist.md) - Previous vector DB integration (archived)
- [Actor Model Overview](1-concepts/actor_model_overview.md) - Introduction to the actor model (archived)
- [PostChain Actor Model](docs/postchain_actor_model.md) - Technical implementation of PostChain using actors (archived)
- [Scale-Free Actor Architecture](1-concepts/scale_free_actor_architecture.md) - Fractal patterns in actor systems (archived)
- [Phase Worker Pool Architecture](phase_worker_pool_architecture.md) - Extension of the actor model with worker pools (archived)
- [Migration Plan](migration_langgraph_to_actor.md) - Step-by-step LangGraph to Actor migration plan (archived)


## Development Timeline

The changelog tracks the project's evolution:

- [Changelog](CHANGELOG.md) - Historical development timeline

## Document Creation Schedule

| Document                     | Status  | Priority | Target      | Changes Needed          |
| ---------------------------- | ------- | -------- | ----------- | ----------------------- |
| PostChain Actor Model        | Created | High     | Completed   | Archived                |
| Stack Argument               | Created | High     | Completed   | Update to MCP           |
| Migration Plan               | Updated | High     | Completed   | Update to MCP           |
| Security Considerations      | Updated | High     | Completed   | Add TEE integration     |
| Actor Development Guidelines | Created | High     | In progress | Archived                |
| Message Protocol Design      | Planned | High     |             |                         |
| State Persistence Patterns   | Planned | Medium   |             |                         |
| Testing Strategy             | Planned | Medium   |             |                         |
| Deployment Guide             | Planned | Medium   |             |                         |
| Monitoring and Observability | Planned | Low      |             |                         |
| Blockchain Integration       | Planned | Medium   |             |                         |

## Documentation Principles

1. **Clarity First**: Documentation should be clear and accessible
2. **Code as Documentation**: Provide well-commented code examples
3. **Conceptual Consistency**: Maintain consistent terminology across documents
4. **Visual Explanation**: Use diagrams to illustrate complex concepts
5. **Living Documentation**: Update documentation as the system evolves

## Contribution Guidelines

When contributing to documentation:

1. Maintain consistent formatting
2. Update the index when adding new documents
3. Mark superseded documents as archived
4. Include visual diagrams where appropriate
5. Provide code examples for technical concepts
