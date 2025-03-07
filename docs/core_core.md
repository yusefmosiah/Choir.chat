# Core System Overview

VERSION core_system: 7.0

Note: This document describes the core system architecture, with initial focus on TestFlight functionality. More sophisticated event-driven mechanisms described here will be implemented post-funding.

The Choir system is built around a clear hierarchy of truth and state management. At its foundation, the blockchain serves as the authoritative source for all ownership and economic state – thread ownership, token balances, message hashes, and co-author lists. This ensures that the economic model, with its fractional equity distribution and fractional quantum anharmonic thread evolution (where dynamic parameter modulation is driven by approval/refusal feedback and memory effects), has an immutable and verifiable foundation.

Alongside the blockchain, Qdrant acts as the authoritative source for all content and semantic relationships. It stores the actual message content, embeddings, and the growing network of citations and semantic links. This separation of concerns allows the system to maintain both economic integrity through the blockchain and rich semantic relationships through the vector database.

The AEIOU-Y chorus cycle sits at the heart of the interaction model, processing user input through a series of well-defined steps. The cycle begins with pure response in the Action step, enriches it with prior knowledge in the Experience step, aligns with user intent in the Intention step, records semantic connections in the Observation step, decides on continuation in the Update step, and produces the final response in the Yield step.

State updates flow naturally between these components. When a user submits input, the system coordinates necessary updates across the UI, blockchain, and vector store. The chorus cycle processes the input while maintaining system state consistency. These state changes are carefully managed to maintain data integrity and system coherence.

The economic model employs FQAHO-based dynamics: the system parameters (α, K₀, m) evolve based on thread history and network position. The fractional parameter α captures memory effects and non-local interactions, decreasing from 2 toward 1 as threads mature. The anharmonic coefficient K₀ increases when a thread receives many refusals and decreases with strong approval. The potential order m reflects thread complexity and network depth. This parameter evolution naturally filters quality while accounting for memory effects and non-local interactions.

Equity is distributed according to fractional formulas, ensuring fair value attribution while maintaining mathematical elegance and accounting for memory effects. The distribution follows E(s) = (1/N) \* (s/P₀)^(α/2), balancing co-author count with stake amount and the thread's fractional parameter.

The knowledge system builds a growing semantic network through citations and prior references, with non-local interactions captured by the fractional approach. Each message can reference previous messages as priors, creating a web of semantic relationships with long-range correlations. These relationships are stored in Qdrant and help inform future responses through the Experience step of the chorus cycle.

State management follows the natural hierarchy of truth. The chain state is authoritative for ownership and economics. The vector state is authoritative for content and semantics. Local state serves only to coordinate UI updates and handle temporary synchronization needs. This clear hierarchy ensures system consistency while enabling responsive user interaction.

All of this is implemented using Swift's modern concurrency system. Async/await enables clean asynchronous code. Structured concurrency through task groups ensures proper resource management. The architecture maintains loose coupling between components while ensuring system coherence.

The result is a system that combines economic incentives, semantic knowledge, and natural interaction patterns into a coherent whole. The blockchain provides economic integrity. The vector database enables semantic richness. The chorus cycle creates natural interaction. The fractional quantum approach captures memory effects and non-local interactions. And Swift's concurrency model keeps it all running smoothly and safely.

This architecture enables the system to evolve naturally. The semantic network grows organically through usage with long-range correlations. The economic model creates emergent quality barriers through coupled parameter evolution. And the whole system maintains consistency through its clear hierarchy of truth and well-defined state management patterns.
