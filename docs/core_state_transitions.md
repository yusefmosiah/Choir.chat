# Core State Transitions

VERSION core_state_transitions: 7.1 (Reward Clarifications)

The state transition system orchestrates the evolution of thread states through carefully defined transformations. These transitions follow precise fractional mathematical principles that ensure non-local energy conservation, dynamic parameter recalibration, and frequency coherence across the network.

Thread Creation establishes the initial quantum state. Each new thread begins with α = 2 (standard quantum mechanics), baseline anharmonic coefficient (K₀_base), and potential order m = 2. The creator's address becomes the first co-author, and the thread maintains an empty set of message hashes. This initial state provides a foundation for future non-local evolution.

Message Submission follows fractional quantum anharmonic energy principles. The required stake follows E(n) = (2n+1)^(α/2) + (K₀λ)^(α/(m+1)), where α, K₀, and m reflect the thread's history and network position. Each message generates a unique hash and carries its quantized energy contribution to the thread.

Approval Processing drives state evolution through three possible outcomes. In the case of rejection, both the anharmonic coefficient K₀ and the fractional parameter α are adjusted—with K₀ increasing to reflect recent refusals, and α decreasing slightly to capture the memory of this rejection. The system recalculates P₀ using our FQAHO-based formula. For split decisions, energy divides between treasury and thread based on voter distribution while parameters adjust proportionally. When approved, energy distributes to approvers while the fractional parameter α decreases slightly, enhancing non-local effects. The author joins as a co-author, and all parameters recalibrate according to the updated thread characteristics.

Dynamic Parameter Evolution follows principles of fractional quantum mechanics. The fractional parameter α evolves to reflect thread maturity and quality, decreasing from 2 toward 1 as threads develop memory and non-local interactions. The anharmonic coefficient K₀ responds primarily to recent approval/refusal patterns, while maintaining sensitivity to the fractional parameter. The potential order m increases with citation count and co-author network complexity, reflecting deepening interactions.

Frequency Management reflects collective organization through coupled oscillators with fractional damping. The thread frequency evolves through three interacting modes: the message mode normalizes activity rate by the fractional power of co-author count, the value mode applies logarithmic scaling to energy per co-author, and the coupling strength maintains an inverse relationship with co-author count raised to the fractional power. These modes work together to create natural organizational rhythms with long-range correlations.

**Reward System and Token Distribution (Clarified Phase-Specific Rewards):**

The reward system operates through precisely defined state transitions with memory effects. MCP servers, specifically AI models within the **Experience and Yield phases**, algorithmically distribute CHIP tokens based on contribution quality and network effects:

1.  **Novelty Rewards (Issued in the Experience Phase):**
    *   **Purpose:** To incentivize the creation of *novel and original prompts and messages* that expand the knowledge space of the Choir ecosystem.
    *   **Mechanism:** AI models within the **Experience phase** analyze new user prompts and messages for *semantic novelty* compared to existing content in the platform's vector databases.
    *   **Distribution:** CHIP tokens are algorithmically distributed as **novelty rewards** to users who submit prompts and messages that are deemed sufficiently novel and original by the Experience phase AI models.
    *   **Timing:** Novelty rewards are issued **during the Experience phase**, as part of the context enrichment and knowledge retrieval process.

2.  **Citation Rewards (Issued in the Yield Phase):**
    *   **Purpose:** To incentivize users to create *salient and impactful contributions* that are recognized and valued by the community, and to foster the growth of a richly interconnected knowledge network through citations.
    *   **Mechanism:** AI models within the **Yield phase** analyze the citation network and identify messages that have been *cited by other users as "priors"*.
    *   **Distribution:** CHIP tokens are algorithmically distributed as **citation rewards** to users whose messages have been cited, based on the *salience* and *influence* of their cited contributions (as measured by citation metrics and FQAHO parameters).
    *   **Timing:** Citation rewards are issued **during the Yield phase**, as part of the final response rendering and output formatting process, with inline links to citations providing transparent recognition of valuable contributions.

The reward system operates through precisely defined state transitions with memory effects. New message rewards follow a fractional time-based decay described by R(t) = R_total × k/(1 + k·t_period)^(α/2), where k represents the decay constant (2.04), t_period spans the total time period of four years, and α is the thread's fractional parameter. Prior citation rewards strengthen thread coupling by drawing from treasury balance based on quality score ratios, expressed as V(p) = B_t × Q(p)^(α/2)/∑Q(i)^(α/2). Citations create frequency coupling between threads, with each thread's frequency increasing by 5% of the other's frequency, modulated by the fractional parameter. Treasury management maintains system solvency through careful balance tracking, where split decisions increase the balance, prior rewards decrease it, and system rewards add to it, all while maintaining a minimum balance for stability.

The system's core properties maintain stability through:

1. Fractional energy conservation in all transitions
2. Parameter coherence via coupled feedback loops
3. Frequency alignment through fractional organizational coupling
4. Lévy flight-like value propagation through the network

Error handling defines transition validity through multiple safeguards. Fractional energy conservation violations trigger immediate rejection. Parameter instability blocks updates until recalibration completes. Frequency decoherence blocks transitions that would disrupt organizational patterns. Phase transition failures maintain the previous state to ensure system stability.

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
