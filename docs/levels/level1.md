# Level 1 Documentation



=== File: docs/core_core.md ===



==
core_core
==


# Core System Overview

VERSION core_system: 6.0

Note: This document describes the core system architecture, with initial focus on TestFlight functionality. More sophisticated event-driven mechanisms described here will be implemented post-funding.

The Choir system is built around a clear hierarchy of truth and state management. At its foundation, the blockchain serves as the authoritative source for all ownership and economic state – thread ownership, token balances, message hashes, and co-author lists. This ensures that the economic model, with its harmonic equity distribution and quantum anharmonic thread evolution (where dynamic stake pricing is driven by approval/refusal feedback), has an immutable and verifiable foundation.

Alongside the blockchain, Qdrant acts as the authoritative source for all content and semantic relationships. It stores the actual message content, embeddings, and the growing network of citations and semantic links. This separation of concerns allows the system to maintain both economic integrity through the blockchain and rich semantic relationships through the vector database.

The AEIOU-Y chorus cycle sits at the heart of the interaction model, processing user input through a series of well-defined steps. The cycle begins with pure response in the Action step, enriches it with prior knowledge in the Experience step, aligns with user intent in the Intention step, records semantic connections in the Observation step, decides on continuation in the Update step, and produces the final response in the Yield step.

State updates flow naturally between these components. When a user submits input, the system coordinates necessary updates across the UI, blockchain, and vector store. The chorus cycle processes the input while maintaining system state consistency. These state changes are carefully managed to maintain data integrity and system coherence.

The economic model employs QAHO-based dynamics: the base stake price increases when a thread receives many refusals (via an uptick in an effective anharmonic coefficient, K₀) and decreases with strong approval—thus naturally filtering quality. Equity is distributed according to harmonic formulas, ensuring fair value attribution while maintaining mathematical elegance.

The knowledge system builds a growing semantic network through citations and prior references. Each message can reference previous messages as priors, creating a web of semantic relationships. These relationships are stored in Qdrant and help inform future responses through the Experience step of the chorus cycle.

State management follows the natural hierarchy of truth. The chain state is authoritative for ownership and economics. The vector state is authoritative for content and semantics. Local state serves only to coordinate UI updates and handle temporary synchronization needs. This clear hierarchy ensures system consistency while enabling responsive user interaction.

All of this is implemented using Swift's modern concurrency system. Async/await enables clean asynchronous code. Structured concurrency through task groups ensures proper resource management. The architecture maintains loose coupling between components while ensuring system coherence.

The result is a system that combines economic incentives, semantic knowledge, and natural interaction patterns into a coherent whole. The blockchain provides economic integrity. The vector database enables semantic richness. The chorus cycle creates natural interaction. And Swift's concurrency model keeps it all running smoothly and safely.

This architecture enables the system to evolve naturally. The semantic network grows organically through usage. The economic model creates emergent quality barriers. And the whole system maintains consistency through its clear hierarchy of truth and well-defined state management patterns.

=== File: docs/core_economics.md ===



==
core_economics
==


# Core Economic Model

VERSION core_economics: 6.0

The economic model operates as a quantum anharmonic system, anchored by the Move Virtual Machine as its source of truth. The model orchestrates value flows through stake dynamics modulated by collective feedback signals.

At its foundation, the system tracks economic events through the blockchain. These events capture stake movements, anharmonic coefficient adjustments, equity distributions, and reward issuance. Each event carries a unique identifier, precise timestamp, and rich metadata that ensures perfect traceability.

The chain state manager serves as the authoritative bridge between the economic model and the blockchain. It retrieves thread economics directly from smart contracts, maintaining an accurate view of stake prices, anharmonic coefficients, token balances, and equity distributions. All economic transactions flow through this manager, ensuring that on-chain state changes trigger appropriate event cascades throughout the system.

The model's core strength lies in its quantum anharmonic calculations. The base price follows a λx²m oscillator model:

P₀ = S₀[(2n+1) + (K₀λ)^{1/(m+1)}]

Where:

- K₀ = Baseline anharmonic coefficient from QAHO theory (e.g. table 1 values), which in practice is modulated by approval/refusal statistics.
  (Higher refusal rates boost the effective K₀, thereby increasing the required stake price.)
- m = Potential order (default quartic: m = 2; sextic m = 3, etc)
- n = Excitation level (capturing thread complexity/activity)

Equity distribution follows a square root law reflecting quantum amplitude principles:

E(s) = (1/N) \* √(s/P₀)

This formula elegantly balances the number of co-authors N with the stake amount s, normalized by the base price P₀, ensuring fair value distribution across participants.

The economic handler processes these events through a carefully orchestrated flow. When stake is deposited, it calculates new equity shares based on the current anharmonic coefficient and organizational frequency. Collective feedback triggers stake price recalculations that maintain system equilibrium. Each event flows through the handler, ensuring proper economic state transitions.

Analytics and monitoring provide real-time insight into the economic system's health. The system tracks stake movements, K₀ adjustments, equity distributions, and reward issuance. This data feeds back into the system, enabling natural price discovery and value distribution.

The economic model's strength emerges from several key principles. The blockchain serves as the immutable source of truth, while value flows follow strict conservation laws. Price discovery emerges naturally through anharmonic eigenvalue patterns, and state changes propagate through quantized energy transitions. Most importantly, complex economic behaviors arise organically from these simple underlying rules.

Through this careful balance of blockchain authority, mathematical precision, and natural value flows, the economic model creates a self-sustaining ecosystem for knowledge work. The system's elegance lies in how these principles work together, creating a robust economic framework that adapts and evolves while maintaining fundamental stability.

=== File: docs/core_state_transitions.md ===



==
core_state_transitions
==


# Core State Transitions

VERSION core_state_transitions: 6.0

The state transition system orchestrates the evolution of thread states through carefully defined transformations. These transitions follow precise mathematical principles that ensure energy conservation, dynamic stake recalibration, and frequency coherence across the network.

Thread Creation establishes the initial quantum state. Each new thread begins at ground state energy (E = 0), with an initial baseline anharmonic coefficient (K₀_base) and base frequency ω₀. The creator's address becomes the first co-author, and the thread maintains an empty set of message hashes. This ground state provides a stable foundation for future evolution.

Message Submission follows quantum anharmonic energy principles. The required stake follows E(n) = (2n+1) + (K₀λ)^(1/(m+1)), where K₀ reflects the thread's approval-refusal history. Each message generates a unique hash and carries its quantized energy contribution to the thread.

Approval Processing drives state evolution through three possible outcomes. In the case of rejection, the effective anharmonic coefficient (and thus the required stake price) increases—the stake amount is incorporated into the thread's "energy" state. The system recalculates P₀ using our QAHO-based formula and a dynamically raised K₀ (reflecting a higher refusal ratio). For split decisions, energy divides between treasury and thread based on voter distribution. If there are A approvers and D deniers out of V total voters, the treasury receives (stake × A)/V while the thread receives the remainder. When approved, energy distributes to approvers while preserving the total. The author joins as a co-author, and the stake parameters recalibrate according to the updated co-author count, while frequency evolves to reflect the enhanced organizational coherence.

Dynamic Stake Evolution follows principles inspired by QAHO behavior. Instead of relying on a passive dissipation mechanism, the required stake price P₀ stabilizes over time as the effective anharmonic coefficient (K₀) is continuously recalibrated based on recent approval/refusal statistics. In this way, threads with sustained high disapproval maintain higher stake thresholds, while well-supported threads see their stake prices relax.

Frequency Management reflects collective organization through coupled oscillators. The thread frequency evolves through three interacting modes: the message mode normalizes activity rate by the square root of co-author count, the value mode applies logarithmic scaling to energy per co-author, and the coupling strength maintains an inverse relationship with co-author count. These modes work together to create natural organizational rhythms.

The reward system operates through precisely defined state transitions. New message rewards follow a time-based decay described by R(t) = R_total × k/(1 + k·t_period), where k represents the decay constant (2.04) and t_period spans the total time period of four years. Prior citation rewards strengthen thread coupling by drawing from treasury balance based on quality score ratios, expressed as V(p) = B_t × Q(p)/∑Q(i). Citations create frequency coupling between threads, with each thread's frequency increasing by 5% of the other's frequency. Treasury management maintains system solvency through careful balance tracking, where split decisions increase the balance, prior rewards decrease it, and system rewards add to it, all while maintaining a minimum balance for stability.

The system's core properties maintain stability through:

1. Energy conservation in all transitions
2. Stake price coherence via K₀ feedback loops
3. Frequency alignment through organizational coupling

Error handling ensures transition validity through multiple safeguards. Energy conservation violations trigger immediate rejection. Stake price instability blocks updates until K₀ recalibration completes. Frequency decoherence blocks transitions that would disrupt organizational patterns. Phase transition failures maintain the previous state to ensure system stability.

Through these precisely defined transitions, the system maintains quantum anharmonic stability while enabling organic evolution of thread states. The careful balance of energy conservation, dynamic stake pricing, and frequency alignment creates a robust framework for organic growth and adaptation.

#### New Consideration: Dynamic Stake & Frequency Evolution

The evolution of the thread's "energy state" is now governed by quantum anharmonic principles:

• The effective stake price P₀ is recalculated via:

P₀ = S₀[(2n+1) + (K₀λ)^(1/(m+1))]

where K₀ is dynamically adjusted based on the ratio of refusals to approvals.

• Likewise, frequency evolution reflects changes in the thread's organizational coherence—adjusting as more energy (stake) is required or released, following a proportional relation akin to:

ω_new = ω_old \* √(1 + ΔE/E_total)

These modifications ensure that energy conservation and dynamic adjustment remain integral while fully dispensing with the outdated thermal metaphor.
