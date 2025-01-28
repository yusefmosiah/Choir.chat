# Core Chorus Cycle

VERSION core_chorus: 6.0

Note: This document describes the core chorus cycle functionality, with initial focus on TestFlight implementation. More sophisticated distributed coordination mechanisms described here will be implemented post-funding.

The chorus cycle processes user input through a series of well-defined phases, maintaining state consistency through careful coordination. Each phase of the cycle contributes to the system's collective intelligence through structured state transitions.

The cycle begins with Action - pure response generation without context. This phase focuses on immediate response processing, establishing a clean foundation for subsequent steps. The system captures the generated response and confidence levels as a baseline.

Experience follows, enriching the response with prior knowledge. The system searches for relevant priors, measuring semantic relevance across stored knowledge. This phase connects current insight with accumulated knowledge, strengthening the semantic fabric of the system.

Intention aligns the evolving response with user goals. Through careful analysis of both explicit and implicit signals, this phase ensures that the response serves its purpose. The system learns from each interaction by tracking these alignments.

Observation records the emerging semantic connections. As links form between current insights and prior knowledge, the system captures these relationships. The network of understanding grows stronger with each new connection, citation, and recognized pattern.

Understanding evaluates the system state, deciding whether to continue cycling or move to completion. This critical phase prevents premature convergence while ensuring efficient processing. The system maintains cycle integrity through careful state tracking.

Yield produces the final response, but only when the cycle has truly completed its work. Citations are generated, semantic effects are recorded, and the system prepares for the next interaction. The cycle maintains consistency through proper state management.

Each phase operates through coordinated services. Foundation models process language. Vector stores manage semantic relationships. Embedding services capture meaning. Chain actors maintain state consensus. All of these services work together through clean interfaces and careful state coordination.

The cycle's power lies in its structured approach. No single service controls the process. Instead, collective intelligence emerges through coordinated state transitions and careful phase management. The system maintains coherence while enabling natural evolution.

This is how the chorus cycle enables collective intelligence - not through central control but through carefully structured phases. Each cycle strengthens the system's understanding, builds semantic relationships, and enables natural knowledge growth.
