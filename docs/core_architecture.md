# Core System Architecture

VERSION core_architecture: 6.0

The system operates through pure event flows. Events ripple through interconnected services, creating waves of state change that propagate across the network. Each service maintains its own event log, creating a resilient distributed architecture where state emerges through consensus rather than central authority.

At the foundation lies a clear hierarchy of truth. The blockchain serves as the authoritative source for all ownership and economic state - thread ownership, token balances, message hashes, and co-author lists. This ensures that the economic model, with its equity distribution and thread evolution, has an immutable and verifiable foundation.

Alongside the chain, our vector database acts as the authoritative source for all content and semantic relationships. It stores the actual message content, embeddings, and the growing network of citations and semantic links. This separation of concerns allows the system to maintain both economic integrity through the blockchain and rich semantic relationships through the vector database.

Events serve as the coordination mechanism between these components. When a user submits input, it triggers a cascade of events that flow through the system. The chorus cycle generates events as it processes the input. These events coordinate UI updates, track system state, and maintain synchronization between components. However, events are not the source of truth - they are merely the means by which the system coordinates updates and maintains consistency.

The economic model uses precise mathematical principles to govern thread evolution and value distribution. Thread temperature rises with rejections and moderates with approvals, creating natural quality barriers. The energy formula E(n) = ℏω(n + 1/2) determines stake requirements, ensuring that participation costs align with thread organization levels. Value flows follow conservation laws, with total system energy remaining constant while redistributing through various state transitions.

State management follows this natural hierarchy of truth. The chain state is authoritative for ownership and economics. The vector state is authoritative for content and semantics. Local state serves only to coordinate UI updates and handle temporary synchronization needs. This clear hierarchy ensures system consistency while enabling responsive user interaction.

All of this manifests through Swift's modern concurrency system. Actors provide thread-safe state isolation. Async/await enables clean asynchronous code. Structured concurrency through task groups ensures proper resource management. The event-driven architecture allows for loose coupling between components while maintaining system coherence.

The result is a system that combines economic incentives, semantic knowledge, and natural interaction patterns into a coherent whole. The blockchain provides economic integrity. The vector database enables semantic richness. Events coordinate the pieces. And Swift's concurrency model keeps it all running smoothly and safely.

This architecture enables the system to evolve naturally. New event types can be added to handle new features. The semantic network grows organically through usage. The economic model creates emergent quality barriers. And the whole system maintains consistency through its clear hierarchy of truth and well-defined patterns of event flow.
