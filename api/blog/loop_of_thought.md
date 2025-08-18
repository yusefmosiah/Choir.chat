# The OODA Loop and Beyond

## Introduction: Powerful Models, Brittle Agents, and the Orientation Gap

The current generation of AI agents showcases impressive abilities, particularly in using tools – calling APIs, running code, querying databases. Powered by models like GPT-4o, Claude 3.5, and Gemini 2.0, the "Act" phase of agency has taken a giant leap forward. Yet, many developers find these agents brittle. They excel at executing pre-defined plans but struggle to adapt when the environment changes, when tools fail, or when tasks require long-term memory and context.

Indeed, we now possess incredibly powerful reasoning engines – models like OpenAI's o1 and o3 series, Anthropic's Claude 3.7 family, Google's Gemini 2.5, and others – that excel as the "Decide" component, capable of complex planning and tool selection when given the right context. We also see the emergence of specialized systems, akin to "Deep Research Agents," tackling parts of the "Observe" function by gathering vast amounts of information. However, the critical bottleneck, the phase often underdeveloped in current agent architectures, is **"Orient."** This crucial step involves making sense of observations, integrating them with memory and goals, and building true situational awareness. As John Boyd emphasized with the OODA loop, winning isn't just about acting faster; it's about *orienting* better – bringing the most salient context to bear on the decision at hand.

## 1. The Temptation and Trouble with "OODA Loop + LLM"

Faced with this orientation gap, a seemingly intuitive idea arises: "Why not just put a powerful LLM inside an OODA loop?" Sense the world (Observe), let the LLM figure it out (Orient), decide the action (Decide), execute (Act), and repeat. It feels like a direct path to adaptive agency.

However, this simple "OODA + LLM" concept quickly runs into practical difficulties:

*   **Monolithic Orientation is Hard:** Expecting a single LLM call to reliably handle all facets of orientation – memory retrieval, context synthesis, goal alignment, world model updates – is often asking too much. It's a complex cognitive workload.
*   **Latency vs. Responsiveness:** A full cycle involving deep orientation can be slow, clashing with user expectations for immediate feedback.
*   **Brittleness:** If the central LLM call fails or hallucinates during Orient/Decide, the entire loop can derail without clear recovery paths.
*   **Integration Complexity:** Managing interactions with databases, APIs, or blockchains within a single, monolithic loop step becomes difficult and error-prone.
*   **Context Management:** Feeding *all* potentially relevant information into one LLM call risks exceeding limits or causing the model to lose focus.

## 2. Beyond OODA: A Pragmatic Conductor + Agents Approach

Rather than building a monolithic phase pipeline, Choir now uses a **Conductor + Agents** architecture. A fast client‑side **Conductor** agent handles responsiveness and privacy‑sensitive operations, escalating substantial work to server‑side agents like **Ghostwriter** (for research/drafting/citation), **Publisher**, and **Revision**. This avoids hardcoding phases while keeping clear integration points for vector search and blockchain rewards.

Key advantages:
*   **Responsiveness:** Conductor gives quick feedback and routes work as needed
*   **Specialization without rigidity:** Ghostwriter can combine/split planning, research, drafting, citation, review, style, and finalization across multiple LLM calls
*   **Deterministic integration points:** Clean boundaries for vector DB (Qdrant → XTrace) and Sui rewards tooling
*   **Transparent economics:** Tokens issued only on Ghostwriter calls; credits gate expensive compute; publishing spend drives ranking; revision markets govern collaboration

## 3. Engineering the System: Building Blocks without Phases

This approach translates into practical engineering components:

*   **Conductor (Client):** Lightweight agent with tool routing (Wordbank wallet, web search, file mgmt); SSE streams; privacy‑sensitive UX
*   **Ghostwriter (Service):** Orchestrates planning, research, drafting, citation, review, revisions (amorphous); issues rewards via Sui tool per invocation
*   **Publisher (Service):** Pay‑to‑publish permalink creation; ranking by spend; responsive web delivery
*   **Revision (Service):** Stake to propose; accept → co‑ownership (unanimity); split decisions route to Treasury for citation emissions
*   **Vector DB:** MVP Qdrant; migration path to XTrace (HE); novelty query method TBD

## 4. Delivering a Richer Experience

*   **Engaging Depth:** Long‑form, cited outputs with verifiable sources
*   **Transparency:** Show when Conductor escalates to Ghostwriter and why
*   **Contextual Coherence:** Maintain thread context through vector recall and source tracking; reward foundations via citations

## 5. Conclusion: Pragmatism over Pipelines

The Conductor + Agents model preserves responsiveness and privacy while enabling robust research, drafting, and economic alignment. It replaces rigid phase pipelines with agent specialization and clear tool boundaries—simpler to reason about, easier to evolve, and better aligned with user value.
