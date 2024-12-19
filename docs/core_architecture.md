# Core System Architecture

VERSION core_architecture: 6.0

Note: This document describes the core system architecture, with initial focus on TestFlight functionality. More sophisticated event-driven mechanisms described here will be implemented post-funding.

The system operates through coordinated state management and clear authority hierarchies. State changes flow through interconnected services while maintaining system consistency. Each service manages its own state, creating a resilient distributed architecture where consistency emerges through clear authority rather than central control.

At the foundation lies a clear hierarchy of truth. The blockchain serves as the authoritative source for all ownership and economic state - thread ownership, token balances, message hashes, and co-author lists. This ensures that the economic model, with its equity distribution and thread evolution, has an immutable and verifiable foundation.

Alongside the chain, our vector database acts as the authoritative source for all content and semantic relationships. It stores the actual message content, embeddings, and the growing network of citations and semantic links. This separation of concerns allows the system to maintain both economic integrity through the blockchain and rich semantic relationships through the vector database.

State updates coordinate between these components. When a user submits input, the system manages necessary updates across services. The chorus cycle processes input while maintaining state consistency. These updates ensure proper synchronization while preserving data integrity across components.

The economic model uses precise mathematical principles to govern thread evolution and value distribution. Thread temperature rises with rejections and moderates with approvals, creating natural quality barriers. The energy formula E(n) = ℏω(n + 1/2) determines stake requirements, ensuring that participation costs align with thread organization levels. Value flows follow conservation laws, with total system energy remaining constant while redistributing through various state transitions.

State management follows this natural hierarchy of truth. The chain state is authoritative for ownership and economics. The vector state is authoritative for content and semantics. Local state serves only to coordinate UI updates and handle temporary synchronization needs. This clear hierarchy ensures system consistency while enabling responsive user interaction.

All of this manifests through Swift's modern concurrency system. Actors provide thread-safe state isolation. Async/await enables clean asynchronous code. Structured concurrency through task groups ensures proper resource management. The architecture maintains loose coupling between components while ensuring system coherence.

The result is a system that combines economic incentives, semantic knowledge, and natural interaction patterns into a coherent whole. The blockchain provides economic integrity. The vector database enables semantic richness. Swift's concurrency model keeps it all running smoothly and safely.

This architecture enables the system to evolve naturally. The semantic network grows organically through usage. The economic model creates emergent quality barriers. And the whole system maintains consistency through its clear hierarchy of truth and well-defined state management patterns.

The Post Chain sits at the heart of our interaction model. Each user action flows through steps ensuring semantic richness, prior knowledge, and economic alignment.

The integration of SAI (Social AI) further enhances this environment: KYC-verified operators can run AI agents that post, cite priors, and even participate in governance via futarchy. This merges human intent with AI-driven insights, producing a uniquely powerful collective intelligence engine.
