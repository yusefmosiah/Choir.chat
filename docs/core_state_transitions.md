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
