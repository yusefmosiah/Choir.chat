# Core System Overview

VERSION core_system:
invariants: {
"System coherence",
"Data authority",
"Event flow"
}
docs_version: "0.4.2"

The Choir system is built around a clear hierarchy of truth and a natural flow of events. At its foundation, the blockchain serves as the authoritative source for all ownership and economic state - thread ownership, token balances, message hashes, and co-author lists. This ensures that the economic model, with its harmonic equity distribution and thermodynamic thread evolution, has an immutable and verifiable foundation.

Alongside the blockchain, Qdrant acts as the authoritative source for all content and semantic relationships. It stores the actual message content, embeddings, and the growing network of citations and semantic links. This separation of concerns allows the system to maintain both economic integrity through the blockchain and rich semantic relationships through the vector database.

The AEIOU-Y chorus cycle sits at the heart of the interaction model, processing user input through a series of well-defined steps. Each step generates events that flow through the system, coordinating state updates and UI feedback. The cycle begins with pure response in the Action step, enriches it with prior knowledge in the Experience step, aligns with user intent in the Intention step, records semantic connections in the Observation step, decides on continuation in the Update step, and produces the final response in the Yield step.

Events serve as the coordination mechanism between these components. When a user submits input, it triggers a cascade of events that flow through the system. The chorus cycle generates events as it processes the input. These events are used to coordinate UI updates, track system state, and maintain synchronization between components. However, these events are not the source of truth - they are merely the means by which the system coordinates updates and maintains consistency.

The economic model uses harmonic principles to govern thread evolution and value distribution. Thread temperature rises with rejections and moderates with approvals, creating natural quality barriers. Equity is distributed according to harmonic formulas, ensuring fair value attribution while maintaining mathematical elegance.

The knowledge system builds a growing semantic network through citations and prior references. Each message can reference previous messages as priors, creating a web of semantic relationships. These relationships are stored in Qdrant and help inform future responses through the Experience step of the chorus cycle.

State management follows the natural hierarchy of truth. The chain state is authoritative for ownership and economics. The vector state is authoritative for content and semantics. Local state serves only to coordinate UI updates and handle temporary synchronization needs. This clear hierarchy ensures system consistency while enabling responsive user interaction.

All of this is implemented using Swift's modern concurrency system. Actors provide thread-safe state isolation. Async/await enables clean asynchronous code. Structured concurrency through task groups ensures proper resource management. The event-driven architecture allows for loose coupling between components while maintaining system coherence.

The result is a system that combines economic incentives, semantic knowledge, and natural interaction patterns into a coherent whole. The blockchain provides economic integrity. The vector database enables semantic richness. The chorus cycle creates natural interaction. Events coordinate the pieces. And Swift's concurrency model keeps it all running smoothly and safely.

This architecture enables the system to evolve naturally. New event types can be added to handle new features. The semantic network grows organically through usage. The economic model creates emergent quality barriers. And the whole system maintains consistency through its clear hierarchy of truth and well-defined patterns of event flow.
