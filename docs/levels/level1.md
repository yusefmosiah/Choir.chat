# Level 1 Documentation



=== File: docs/core_core.md ===



==
core_core
==


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

=== File: docs/core_economics.md ===



==
core_economics
==


# Core Economic Model

VERSION core_economics: 7.0

The economic model operates as a fractional quantum anharmonic system, anchored by the Move Virtual Machine as its source of truth. The model orchestrates value flows through stake dynamics modulated by collective feedback signals and non-local memory effects.

At its foundation, the system tracks economic events through the blockchain. These events capture stake movements, parameter adjustments, equity distributions, and reward issuance. Each event carries a unique identifier, precise timestamp, and rich metadata that ensures perfect traceability.

The chain state manager serves as the authoritative bridge between the economic model and the blockchain. It retrieves thread economics directly from smart contracts, maintaining an accurate view of stake prices, model parameters, token balances, and equity distributions. All economic transactions flow through this manager, ensuring that on-chain state changes trigger appropriate event cascades throughout the system.

The model's core strength lies in its fractional quantum anharmonic calculations. The base price follows a modified FQAHO model:

P₀ = S₀[(2n+1)^(α/2) + (K₀λ)^{α/(m+1)}]

Where:

- α = Fractional parameter (1<α≤2) capturing memory effects and non-local interactions
- K₀ = Anharmonic coefficient dynamically modulated by recent approval/refusal statistics
- m = Potential order reflecting thread complexity and network depth
- n = Excitation level (capturing thread activity)

The fractional parameter α evolves according to:

α(t,q) = 2 - δ₁(1-e^(-t/τ)) - δ₂q

Where t represents normalized thread age, q measures quality through approval ratios, τ sets the time constant, and δ₁, δ₂ determine sensitivity.

Equity distribution follows a fractional square root law reflecting quantum amplitude principles:

E(s) = (1/N) \* (s/P₀)^(α/2)

This formula elegantly balances the number of co-authors N with the stake amount s, normalized by the base price P₀, ensuring fair value distribution across participants while accounting for memory effects.

The economic handler processes these events through a carefully orchestrated flow. When stake is deposited, it calculates new equity shares based on the current parameter values and organizational frequency. Collective feedback triggers parameter recalculations that maintain system equilibrium. Each event flows through the handler, ensuring proper economic state transitions.

Analytics and monitoring provide real-time insight into the economic system's health. The system tracks stake movements, parameter adjustments, equity distributions, and reward issuance. This data feeds back into the system, enabling natural price discovery and value distribution.

The economic model's strength emerges from several key principles. The blockchain serves as the immutable source of truth, while value flows follow fractional conservation laws. Price discovery emerges naturally through eigenvalue patterns of the fractional system, and state changes propagate through Lévy flight-like transitions. Most importantly, complex economic behaviors arise organically from these simple underlying rules.

Through this careful balance of blockchain authority, fractional mathematical precision, and natural value flows, the economic model creates a self-sustaining ecosystem for knowledge work. The system's elegance lies in how these principles work together, creating a robust economic framework that adapts and evolves while maintaining fundamental stability.

# Dynamic Parameter Evolution

## Fractional Parameter (α)

α(t,q) = 2 - δ₁(1-e^(-t/τ)) - δ₂q

## Anharmonic Coefficient (K₀)

K₀(r,α) = K₀*base * (1 + γ₁r) \_ (2/α)^γ₂

## Potential Order (m)

m(c,n) = 2 + β₁tanh(c/c₀) + β₂log(1+n/n₀)

## Implementation in Actor Model

```python
class EconomicActor(Actor[EconomicState]):
    async def adjust_parameters(self, thread_state: ThreadState):
        """Update FQAHO parameters based on thread activity"""
        # Calculate new α using memory decay formula
        new_alpha = 2 - self.delta1*(1 - math.exp(-thread_state.age/self.tau))
                      - self.delta2*thread_state.quality_score

        # Update thread parameters
        await self.blockchain_actor.send(
            ParameterUpdate(
                thread_id=thread_state.id,
                alpha=new_alpha,
                k0=calculate_new_k0(thread_state.refusal_rate),
                m=calculate_new_m(thread_state.citation_count)
            )
        )
```

=== File: docs/core_state_transitions.md ===



==
core_state_transitions
==


# Core State Transitions

VERSION core_state_transitions: 7.0

The state transition system orchestrates the evolution of thread states through carefully defined transformations. These transitions follow precise fractional mathematical principles that ensure non-local energy conservation, dynamic parameter recalibration, and frequency coherence across the network.

Thread Creation establishes the initial quantum state. Each new thread begins with α = 2 (standard quantum mechanics), baseline anharmonic coefficient (K₀_base), and potential order m = 2. The creator's address becomes the first co-author, and the thread maintains an empty set of message hashes. This initial state provides a foundation for future non-local evolution.

Message Submission follows fractional quantum anharmonic energy principles. The required stake follows E(n) = (2n+1)^(α/2) + (K₀λ)^(α/(m+1)), where α, K₀, and m reflect the thread's history and network position. Each message generates a unique hash and carries its quantized energy contribution to the thread.

Approval Processing drives state evolution through three possible outcomes. In the case of rejection, both the anharmonic coefficient K₀ and the fractional parameter α are adjusted—with K₀ increasing to reflect recent refusals, and α decreasing slightly to capture the memory of this rejection. The system recalculates P₀ using our FQAHO-based formula. For split decisions, energy divides between treasury and thread based on voter distribution while parameters adjust proportionally. When approved, energy distributes to approvers while the fractional parameter α decreases slightly, enhancing non-local effects. The author joins as a co-author, and all parameters recalibrate according to the updated thread characteristics.

Dynamic Parameter Evolution follows principles of fractional quantum mechanics. The fractional parameter α evolves to reflect thread maturity and quality, decreasing from 2 toward 1 as threads develop memory and non-local interactions. The anharmonic coefficient K₀ responds primarily to recent approval/refusal patterns, while maintaining sensitivity to the fractional parameter. The potential order m increases with citation count and co-author network complexity, reflecting deepening interactions.

Frequency Management reflects collective organization through coupled oscillators with fractional damping. The thread frequency evolves through three interacting modes: the message mode normalizes activity rate by the fractional power of co-author count, the value mode applies logarithmic scaling to energy per co-author, and the coupling strength maintains an inverse relationship with co-author count raised to the fractional power. These modes work together to create natural organizational rhythms with long-range correlations.

The reward system operates through precisely defined state transitions with memory effects. New message rewards follow a fractional time-based decay described by R(t) = R_total × k/(1 + k·t_period)^(α/2), where k represents the decay constant (2.04), t_period spans the total time period of four years, and α is the thread's fractional parameter. Prior citation rewards strengthen thread coupling by drawing from treasury balance based on quality score ratios, expressed as V(p) = B_t × Q(p)^(α/2)/∑Q(i)^(α/2). Citations create frequency coupling between threads, with each thread's frequency increasing by 5% of the other's frequency, modulated by the fractional parameter. Treasury management maintains system solvency through careful balance tracking, where split decisions increase the balance, prior rewards decrease it, and system rewards add to it, all while maintaining a minimum balance for stability.

The system's core properties maintain stability through:

1. Fractional energy conservation in all transitions
2. Parameter coherence via coupled feedback loops
3. Frequency alignment through fractional organizational coupling
4. Lévy flight-like value propagation through the network

Error handling ensures transition validity through multiple safeguards. Fractional energy conservation violations trigger immediate rejection. Parameter instability blocks updates until recalibration completes. Frequency decoherence blocks transitions that would disrupt organizational patterns. Phase transition failures maintain the previous state to ensure system stability.

Through these precisely defined transitions, the system maintains fractional quantum anharmonic stability while enabling organic evolution of thread states. The careful balance of non-local energy conservation, dynamic parameter modulation, and frequency alignment creates a robust framework for organic growth and adaptation with memory effects.

#### Fractional Parameter Evolution

The evolution of thread parameters follows fractional quantum principles:

• The fractional parameter α evolves via:
α(t,q) = 2 - δ₁(1-e^(-t/τ)) - δ₂q

• The anharmonic coefficient adjusts through:
K₀(r,α) = K₀_base _ (1 + γ₁r) _ (2/α)^γ₂

• The potential order develops according to:
m(c,n) = 2 + β₁tanh(c/c₀) + β₂log(1+n/n₀)

These modifications ensure that memory effects, non-local interactions, and network complexity are properly accounted for in the economic model.
