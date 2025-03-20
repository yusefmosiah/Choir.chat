# Choir Documentation

## Documentation Reorganization: From Graphs to Actors

Choir has undergone a significant architectural pivot from a graph-based to an actor-based architecture. This document explains the documentation reorganization that accompanies this architectural change.

## Why We're Reorganizing

The shift from LangGraph to an actor model represents more than just a technical implementation change—it reflects a fundamental rethinking of how we conceptualize and build AI systems. Our documentation needed to evolve alongside this architectural shift to:

1. **Reflect the actor model paradigm** - Providing mental models that align with actor-based thinking
2. **Organize information coherently** - Creating a logical progression from concepts to implementation
3. **Support both new and existing users** - Making the transition smoother for those familiar with the previous architecture
4. **Enable future extensions** - Building a documentation structure that can grow with the system

## New Documentation Structure

The documentation has been reorganized into a clear, hierarchical structure:

### 1. Core Concepts

Fundamental ideas that remain consistent regardless of implementation:

- [Actor Model Overview](1-concepts/actor_model_overview.md) - Introduction to the actor model
- [Scale-Free Actor Architecture](1-concepts/scale_free_actor_architecture.md) - Fractal patterns in actor systems
- [PostChain Conceptual Model](postchain_actor_model.md) - The core AEIOU-Y framework

### 2. Architecture

Detailed information about the actor-based architecture:

- [Actor System Diagrams](2-architecture/actor_system_diagram.md) - Visual representations of the actor system
- [Architecture Transition Narrative](archive/architecture_transition_narrative.md) - The story of our architectural evolution
- [Stack Argument](stack_argument.md) - Rationale for our technology choices

### 3. Implementation

Practical guidance for implementing actor-based systems:

- [Developer Quickstart](3-implementation/developer_quickstart.md) - Fast onboarding guide
- [Message Protocol Reference](message_protocol_reference.md) - Comprehensive message format documentation
- [State Management Patterns](3-implementation/state_management_patterns.md) - Best practices for actor state

### 4-6. Integration, Operations, Business

Additional sections covering integration with external systems, operational concerns, and business aspects.

## Documentation as Code

Our documentation follows these principles:

1. **Version Control** - Documentation evolves alongside code
2. **Markdown Format** - All documents use Markdown for consistency and readability
3. **Diagrams as Code** - Architecture diagrams use Mermaid.js for maintainability
4. **Clear Hierarchy** - Numbered directories create a logical progression

## Navigation

The primary entry point is [index.md](index.md), which provides links to all major sections.

For a chronological view of Choir's evolution, see the [CHANGELOG.md](CHANGELOG.md).

## The Meta-Story

This documentation reorganization represents more than just moving files—it embodies our shift toward thinking in terms of actors, messages, and encapsulated state. The structure itself reflects the actor model's principles:

- **Isolation** - Each document has a clear, focused purpose
- **Message-Based** - Documents reference each other through explicit links
- **Hierarchy** - Clear organization from abstract concepts to concrete implementation

By reorganizing our documentation in this way, we aim to make the actor model more intuitive and accessible, helping users understand not just how to use the system, but why it's designed this way.

## Contributing to Documentation

If you'd like to contribute to the documentation:

1. Review the [Architecture Reorganization Plan](archive/architecture_reorganization_plan.md)
2. Follow the existing folder structure and naming conventions
3. Use Markdown for all documentation
4. Include diagrams using Mermaid.js where appropriate
5. Submit a pull request with your changes

## Feedback

This documentation reorganization is an ongoing process. If you have suggestions, questions, or feedback about the documentation structure, please open an issue on our GitHub repository.
