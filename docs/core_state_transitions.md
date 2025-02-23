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
