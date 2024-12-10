# Level 1 Documentation



=== File: docs/core_architecture.md ===



==
core_architecture
==


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

=== File: docs/core_chorus.md ===



==
core_chorus
==


# Core Chorus Cycle

VERSION core_chorus: 6.0

The chorus cycle operates as a distributed event sequence, coordinating state changes across the network through well-defined transitions. Each phase of the cycle generates specific events that ripple through the system, creating waves of coordinated state change.

The cycle begins with Action - pure response generation without context. Events mark the start of processing, capture the generated response, and record confidence levels. This creates a clean foundation for the rest of the cycle.

Experience follows, enriching the response with prior knowledge. The system searches for relevant priors, measuring semantic relevance across the network. This phase connects current insight with accumulated knowledge, strengthening the semantic fabric of the system.

Intention aligns the evolving response with user goals. Through careful analysis of both explicit and implicit signals, this phase ensures that the response serves its purpose. Events track this alignment process, enabling the system to learn from each interaction.

Observation records the emerging semantic connections. As links form between current insights and prior knowledge, events capture these relationships. The network of understanding grows stronger with each new connection, each citation, each recognized pattern.

Understanding evaluates the system state, deciding whether to continue cycling or move to completion. This critical phase prevents premature convergence while ensuring efficient processing. Events track these decisions, maintaining the integrity of the cycle.

Yield produces the final response, but only when the cycle has truly completed its work. Citations are generated, effects are distributed across the network, and the system prepares for the next interaction. The cycle maintains its integrity through careful event logging and state tracking.

Each phase operates through distributed coordination. Foundation models process language. Vector stores manage semantic relationships. Embedding services capture meaning. Chain actors maintain state consensus. All of these services work together through clean event flows and careful state management.

The cycle's power lies in its distributed nature. No single service controls the process. Instead, collective intelligence emerges through coordinated event flows and careful state transitions. The system maintains coherence while enabling natural evolution.

This is how the chorus cycle enables collective intelligence - not through central control but through carefully coordinated event flows. Each cycle strengthens the network's understanding, builds semantic relationships, and enables natural knowledge growth.

=== File: docs/core_core.md ===



==
core_core
==


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

=== File: docs/core_economics.md ===



==
core_economics
==


# Core Economic Model

VERSION core_economics: 6.0

The economic model operates as a harmonically balanced system, anchored by the Move Virtual Machine as its source of truth. The model orchestrates the flow of value through temperature-mediated stake dynamics and equitable distribution mechanisms.

At its foundation, the system tracks economic events through the blockchain. These events capture stake movements, temperature fluctuations, equity distributions, and reward issuance. Each event carries a unique identifier, precise timestamp, and rich metadata that ensures perfect traceability.

The chain state manager serves as the authoritative bridge between the economic model and the blockchain. It retrieves thread economics directly from smart contracts, maintaining an accurate view of temperature, energy levels, token balances, and equity distributions. All economic transactions flow through this manager, ensuring that on-chain state changes trigger appropriate event cascades throughout the system.

The model's core strength lies in its harmonic calculations. These pure mathematical functions govern the relationship between temperature and value. The base price follows a quantum harmonic oscillator model:

P₀ = S₀[1/2 + 1/(exp(ℏω/kT)-1)]

In this equation, S₀ represents the base stake quantum, while ℏ denotes the reduced Planck constant. The frequency ω interacts with the Boltzmann constant k and temperature T to determine the system's energy state.

Equity distribution follows a square root law that balances stake size with fair co-author allocation:

E(s) = (1/N) * √(s/P₀)

This formula elegantly balances the number of co-authors N with the stake amount s, normalized by the base price P₀, ensuring fair value distribution across participants.

The economic handler processes these events through a carefully orchestrated flow. When stake is deposited, it calculates new equity shares based on the current temperature and frequency. Temperature changes trigger chain updates that maintain the system's thermodynamic balance. Each event flows through the handler, ensuring proper economic state transitions.

Analytics and monitoring provide real-time insight into the economic system's health. The system tracks stake movements, temperature evolution, equity distributions, and reward issuance. This data feeds back into the system, enabling natural price discovery and value distribution.

The economic model's strength emerges from several key principles. The blockchain serves as the immutable source of truth, while value flows follow strict conservation laws. Price discovery emerges naturally through harmonic oscillator patterns, and state changes propagate cleanly through the event-driven system. Most importantly, complex economic behaviors arise organically from these simple underlying rules.

Through this careful balance of blockchain authority, mathematical precision, and natural value flows, the economic model creates a self-sustaining ecosystem for knowledge work. The system's elegance lies in how these principles work together, creating a robust economic framework that adapts and evolves while maintaining fundamental stability.

=== File: docs/core_knowledge.md ===



==
core_knowledge
==


# Core Knowledge Architecture

VERSION core_knowledge: 6.0

The knowledge architecture forms a distributed semantic network, weaving together vector spaces, prior knowledge, and multimodal understanding. This system maintains semantic coherence through network consensus while enabling distributed learning across the collective.

At its foundation lies the vector store, a distributed system that coordinates operations across the network. Vector searches execute with proper concurrency, parallelizing embedding generation and cache checks. The system gracefully handles network searches with built-in cancellation support, ensuring efficient resource management even under load.

Prior management operates with full network awareness. The system processes priors through parallel operations, combining vector searches with network metadata to build a comprehensive understanding. Citation recording maintains perfect synchronization across the network, updating vector indices and storage while ensuring cleanup on cancellation.

The semantic network exists as a distributed knowledge graph, processing links with careful coordination. When new messages enter the system, it updates the network graph, processes citations, and refreshes distributed embeddings in parallel. Graph queries execute with proper cancellation support, finding related content through semantic similarity.

Multimodal support enables the system to process diverse content types across the network. The modality manager handles text, images, and audio through specialized embedding services. These different modalities combine into unified embeddings that maintain semantic coherence across the network.

The implementation follows a progressive enhancement strategy that unfolds in three distinct phases. The first phase establishes the core network foundation through distributed vector storage in Qdrant, coordinated network-wide embeddings, and a robust citation network, all built upon foundational text processing capabilities.

As the system evolves, the second phase introduces enhanced capabilities. Multimodal content processing expands the system's understanding beyond text, while distributed search capabilities enable efficient knowledge retrieval. The citation system scales across the entire network, and a sophisticated knowledge graph emerges from the growing web of connections.

The third phase harnesses powerful network effects. Collective learning emerges as the system recognizes patterns across interactions. Network intelligence develops organically through accumulated knowledge. Cross-modal search capabilities enable natural exploration across different types of content, while pattern recognition spans multiple modalities to surface deeper insights.

The architecture's strength flows from several fundamental principles. Semantic coherence ensures consistent meaning across the network, while network consensus coordinates knowledge distribution. The system enables truly distributed learning, where intelligence emerges from collective interaction. Vector consistency preserves critical embedding relationships, and seamless multimodal integration unifies diverse content types into a coherent whole.

Through this careful orchestration of distributed systems, the knowledge architecture creates a self-organizing network of understanding that grows stronger with each interaction. The system's power lies in how these principles work together, creating an evolving fabric of knowledge that becomes more valuable and insightful over time.

=== File: docs/core_patterns.md ===



==
core_patterns
==


# Core Implementation Patterns

VERSION core_patterns: 6.0

The implementation patterns form a cohesive framework for building reliable distributed systems. These patterns ensure clear sources of truth, coordinate state changes through events, and maintain proper actor isolation throughout the system.

The Source of Truth pattern establishes a clear data authority hierarchy. The blockchain serves as the ultimate arbiter of economic state, managing thread states and token balances through an authoritative interface. Vector stores maintain authority over content and semantic relationships, handling message storage and citation recording. This separation of concerns ensures that each subsystem has clear responsibility for its domain.

Event Coordination weaves the system together through carefully typed events. State synchronization flows through chain state and content storage events. UI coordination happens through view state and loading state updates. Error handling maintains system stability through typed error events and sync failure notifications. This event-driven architecture enables loose coupling while maintaining system coherence.

Actor Isolation creates clean boundaries between system components. Domain-specific actors encapsulate their state and behavior, communicating through well-defined interfaces. Resource management follows structured patterns for acquisition and release, ensuring proper cleanup even under failure conditions. This isolation enables concurrent processing while preventing data races and state corruption.

Error Recovery builds resilience into the system through typed error handling. The system categorizes errors by their source - chain errors, vector errors, and synchronization failures. Recovery strategies adapt to each error type, implementing appropriate retry logic, state resynchronization, and cleanup procedures. This layered approach to error handling maintains system stability even under adverse conditions.

Testing follows a protocol-based approach that enables thorough verification of system behavior. Mock implementations of core protocols allow testing of individual components in isolation. Test scenarios cover the full range of system operations, from basic state synchronization to complex error recovery paths. This comprehensive testing strategy ensures reliable system operation.

The implementation's strength emerges from several key aspects. Source of truth clarity flows from the chain state's authority over economic data and vector stores' mastery of content, creating clean hierarchical data flows and proper state transitions. Event-driven coordination manifests through typed system events, synchronized state changes, coordinated UI patterns, and clear error propagation paths.

Actor isolation maintains system integrity through well-defined domain boundaries and careful resource management. This enables clean concurrent processing while ensuring proper state encapsulation. Error resilience builds from typed error handling through sophisticated recovery strategies and retry mechanisms, culminating in proper state cleanup procedures.

The testing approach ensures system reliability through comprehensive verification. Protocol-based mocking enables isolated component testing, while thorough scenarios verify behavior across the full system. This multi-layered testing strategy catches issues early while ensuring proper integration.

Through these carefully crafted patterns, the system achieves several critical qualities. Each component maintains clear authority over its domain, while state changes flow naturally through the event system. Components operate independently without interference, and the system recovers gracefully from failures. Most importantly, thorough testing verifies behavior at all levels.

This pattern language creates a foundation for building reliable, maintainable, and evolvable distributed systems. The patterns work together harmoniously, enabling the construction of robust systems that can grow and adapt while maintaining fundamental stability and reliability.

=== File: docs/core_state.md ===



==
core_state
==


# Core State Management

VERSION core_state: 6.0

The state management system establishes clear authority hierarchies and coordination patterns across the distributed network. At its core, the system maintains two authoritative sources of truth - the blockchain for economic state and vector stores for content state - while enabling efficient local coordination through event-driven patterns.

The Chain State serves as the ultimate arbiter of economic truth. Through a dedicated actor, it maintains authoritative thread states including co-author lists, token balances, temperature values, frequency measurements, and message hash collections. All state changes must flow through the blockchain first, with local events emitted only after on-chain confirmation. This ensures perfect consistency between the network's economic state and local views.

The Vector State maintains authoritative control over content and semantic relationships. Built on Qdrant, this system provides the source of truth for messages and their embeddings. Content operations follow a strict pattern - store in the vector database first, then emit local events for UI coordination. This maintains semantic coherence while enabling responsive user interfaces.

Local Events enable efficient coordination without claiming authority. The system serves two key purposes in this regard. First, it manages UI updates by notifying interfaces about content loads and chain state changes. Second, it handles synchronization status by tracking progress and managing the offline queue. The event store maintains a clean separation between authoritative state and local coordination, with events flowing to subscribers for UI updates while maintaining proper cleanup of historical events.

UI State Management reacts to authoritative changes through a carefully coordinated view model pattern. The process begins by loading authoritative thread state from the blockchain, then retrieves associated messages from the vector store. The view models subscribe to local events for efficient updates while maintaining clean separation between source data and presentation layers.

The system implements thorough state verification through dedicated verification actors. Chain state integrity verification ensures positive temperature values, valid frequency measurements, proper energy conservation across threads, and consistent token balances. Vector state integrity checks maintain message availability, embedding consistency, citation validity, and content coherence. Cross-state alignment verifies message hash consistency, thread state alignment, citation graph validity, and system-wide coherence.

The state management system's strength emerges from several key aspects. Authority clarity flows from the blockchain's economic authority and vector stores' content mastery, creating clean coordination patterns and clear state ownership. State transitions manifest through atomic chain updates and vector store consistency, enabling local event propagation and seamless UI synchronization.

System coordination maintains stability through careful actor isolation and event-driven updates. This enables efficient local synchronization while ensuring clean error handling throughout the system. The verification patterns provide comprehensive oversight through state consistency checks, cross-system validation, integrity verification, and sophisticated error detection.

Through this careful orchestration of state management patterns, the system maintains perfect consistency while enabling responsive local interactions. The interplay of authority hierarchies, state transitions, and verification systems creates a robust foundation for distributed state management that remains reliable even as the system scales and evolves.

=== File: docs/core_state_transitions.md ===



==
core_state_transitions
==


# Core State Transitions

VERSION core_state_transitions: 6.0

The state transition system orchestrates the evolution of thread states through carefully defined transformations. These transitions follow precise mathematical principles that ensure energy conservation, natural temperature evolution, and frequency coherence across the network.

Thread Creation establishes the initial quantum state. Each new thread begins at ground state energy (E = 0), with an initial temperature T₀ and base frequency ω₀. The creator's address becomes the first co-author, and the thread maintains an empty set of message hashes. This ground state provides a stable foundation for future evolution.

Message Submission follows energy quantization principles. The required stake follows the quantum harmonic oscillator model, where the energy requirement E(n) = ℏω(n + 1/2) depends on both the thread's frequency ω and temperature T. Each message generates a unique hash and carries its quantized energy contribution to the thread.

Approval Processing drives state evolution through three possible outcomes. In the case of rejection, temperature increases while preserving total energy - the stake amount adds to thread energy, and temperature adjusts according to T = E/N where N is the co-author count. For split decisions, energy divides between treasury and thread based on voter distribution. If there are A approvers and D deniers out of V total voters, the treasury receives (stake × A)/V while the thread receives the remainder. When approved, energy distributes to approvers while preserving the total. The author joins as a co-author, temperature rebalances according to the new co-author count, and frequency evolves to reflect the enhanced organizational coherence.

Temperature Evolution follows natural cooling laws. The temperature decay follows T = T₀/√(1 + t/τ), where τ represents the characteristic cooling time (standardized to one day). This ensures that thread temperature naturally stabilizes over time unless perturbed by new activity.

Frequency Management reflects collective organization through coupled oscillators. The thread frequency evolves through three interacting modes: the message mode normalizes activity rate by the square root of co-author count, the value mode applies logarithmic scaling to energy per co-author, and the coupling strength maintains an inverse relationship with co-author count. These modes work together to create natural organizational rhythms.

The reward system operates through precisely defined state transitions. New message rewards follow a time-based decay described by R(t) = R_total × k/(1 + kt)ln(1 + kT), where k represents the decay constant (2.04) and T spans the total time period of four years. Prior citation rewards strengthen thread coupling by drawing from treasury balance based on quality score ratios, expressed as V(p) = B_t × Q(p)/∑Q(i). Citations create frequency coupling between threads, with each thread's frequency increasing by 5% of the other's frequency. Treasury management maintains system solvency through careful balance tracking, where split decisions increase the balance, prior rewards decrease it, and system rewards add to it, all while maintaining a minimum balance for stability.

The system's core properties work together to maintain stability. Energy conservation ensures that total system energy remains constant as it flows between threads and treasury, with all transitions preserving this fundamental quantity. Temperature stability manifests through consistently positive values that reflect the energy per co-author ratio, maintained by natural cooling processes. Frequency coherence emerges as organizational patterns strengthen, with positive frequencies increasing through enhanced coherence and strengthened thread coupling.

Error handling ensures transition validity through multiple safeguards. Energy conservation violations trigger immediate rejection to maintain system integrity. Temperature instability prevents state updates until proper thermal balance is restored. Frequency decoherence blocks transitions that would disrupt organizational patterns. Phase transition failures maintain the previous state to ensure system stability.

Through these precisely defined transitions, the system maintains stability while enabling natural evolution of thread states. The careful balance of energy conservation, temperature evolution, and frequency coherence creates a robust framework for organic growth and adaptation.
