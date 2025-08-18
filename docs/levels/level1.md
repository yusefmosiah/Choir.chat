# Level 1 Documentation



=== File: docs/core_core.md ===



==
core_core
==


# Core System Overview: Infrastructure for the Learning Economy

VERSION core_system: 10.0 (Learning Economy Architecture)

## Overview

Choir provides the technological infrastructure enabling transition from traditional education toward learning economy participation. The platform transforms natural conversation into publication-quality content, making intellectual discourse accessible to anyone regardless of writing skill, technical expertise, or institutional access. Our system architecture implements the **Conductor + Agents** model—where "instruments" are agents with no fixed number—that orchestrates conversation-to-publication workflows through AI-enhanced collaborative intelligence.

## Foundational Principles: Learning Economy Infrastructure

Choir's architecture embodies core principles that enable the transition from credential theater to intellectual contribution:

1.  **Conversation-to-Publication Workflow:** The core experience eliminates barriers between having insights and contributing to collective knowledge. Record conversations about any topic, AI research assistants gather relevant sources, collaborative editing transforms dialogue into citable articles.
2.  **Citation Economics:** When others reference your contributions in their work, you receive ongoing compensation through citation rewards. Original insights generate appreciating assets rather than disappearing posts.
3.  **Collaborative Intelligence:** AI serves as research assistant, writing collaborator, and intellectual partner rather than replacement. Humans provide creativity and judgment while AI handles execution and technical implementation.
4.  **Intellectual Property Rights:** The platform creates genuine intellectual property rights through citation economics, inverting traditional social platforms that provide ephemeral rewards while capturing lasting economic value.

## Core Components: Conductor + Agents Architecture

1.  **The Conductor (Python API):**
    *   **Role:** Central orchestration layer that coordinates all system components and manages the conversation-to-publication workflow.
    *   **Function:** Authenticates users through Sui signatures, orchestrates AI processing phases, manages file input processing (txt, md, pdf, epub, YouTube transcripts), and coordinates between semantic understanding and economic rewards.

2.  **Semantic Engine (Qdrant):**
    *   **Role:** Powers semantic understanding and knowledge discovery through vector storage and retrieval.
    *   **Function:** Stores conversation content and embeddings, enables semantic search for relevant prior knowledge, calculates novelty scores for original contributions, and provides context for AI-enhanced conversations.

3.  **Economic Layer (Sui Blockchain):**
    *   **Role:** Manages CHOIR tokens and implements citation economics for intellectual property rights.
    *   **Function:** Executes reward distributions for quality contributions, manages citation rewards when insights prove foundational for others, and provides economic infrastructure where participants co-own intellectual value.

4.  **AI Processing (Conductor + Agents):**
    *   **Role:** Transforms conversations into publication-quality content through agent specialization (no fixed phases)
    *   **Function:** Conductor orchestrates server agents (Ghostwriter/Publisher/Revision) to plan, research, draft, cite, review, revise, and finalize outputs.

5.  **Content Processing (Multi-Format Input):**
    *   **Role:** Handles diverse input formats to democratize intellectual contribution.
    *   **Function:** Processes text files, PDFs, EPUBs, YouTube transcripts, and audio/video content, automatically switches to high-context models on overflow, and enables text-to-speech for accessibility.

6.  **Publication Infrastructure (Client Interface):**
    *   **Role:** Provides accessible interface for conversation-to-publication workflow.
    *   **Function:** SwiftUI client with secure Sui key storage, real-time collaboration features, and seamless transition from conversation to published content.

7.  **Agents ("Instruments")**
    *   **Ghostwriter (first agent):** Transcribes, structures, and rewards raw thought; focuses on novelty and clarity.
    *   Additional agents will be introduced over time.
## Architecture Flow: From Conversation to Publication

The system creates a flow that transforms natural conversation into publication-quality intellectual contribution:

1.  **Content Input**: User provides conversation, text files, PDFs, EPUBs, or YouTube URLs via **SwiftUI Client** with Sui-based authentication ensuring ownership.
2.  **AI Research & Drafting**: **Conductor** orchestrates **Ghostwriter** to gather sources from **Semantic Engine**, draft, cite, review, and refine outputs.
3.  **Collaborative Enhancement**: **Conductor + Agents** refine dialogue through collaborative editing toward publication‑quality results.
4.  **Quality Assessment**: AI calculates novelty scores and identifies original insights worthy of citation rewards.
5.  **Publication Generation**: Final output becomes citable article with proper attribution and professional presentation.
6.  **Citation Economics**: **Economic Layer** distributes ongoing compensation when others reference the published work.
7.  **Knowledge Commons**: Published content contributes to collective knowledge while generating intellectual property rights for creators.

This architecture validates the core insight: **Natural Conversation -> AI Enhancement -> Publication Quality -> Citation Economics -> Intellectual Property Rights**.

## Strategic Focus: Validating Learning Economy Infrastructure

*   **Conversation-to-Publication:** Validate that AI can transform natural dialogue into publication-quality content accessible to anyone regardless of writing skill.
*   **Citation Economics:** Establish that ongoing compensation for referenced work creates sustainable intellectual property rights and quality incentives.
*   **Collaborative Intelligence:** Demonstrate that AI-human collaboration generates insights neither could achieve independently.
*   **Educational Transformation:** Prove that intellectual contribution can become economic activity, transforming education from credential theater to value creation.

## The Combined Result: Infrastructure for Intellectual Contribution

The system delivers a new paradigm for learning and knowledge creation:

*   **Democratized Publishing (Conversation-to-Publication):** Anyone can contribute to collective knowledge regardless of writing expertise or institutional access.
*   **Intellectual Property Rights (Citation Economics):** Original insights generate appreciating assets through ongoing citation rewards rather than ephemeral social media engagement.
*   **Amplified Intelligence (AI Collaboration):** Human creativity combines with AI execution to produce insights and content impossible for individuals alone.
*   **Learning Economy Participation:** Intellectual contribution becomes immediate economic activity rather than delayed value through credential signaling.

This architecture demonstrates that technology can serve intellectual flourishing rather than exploit psychological vulnerabilities, creating infrastructure where learning becomes economic opportunity and insights gain the recognition they merit.

=== File: docs/core_economics.md ===



==
core_economics
==


# Core Economic Model: Tokenized Ghostwriting, Publication Investment, and Revision Markets

VERSION core_economics: 10.0 (Conductor + Agents Economy)

Choir converts high‑quality communication into economic value through a service‑first model. Users pay for premium compute via credits to invoke the Ghostwriter agent, and may earn CHOIR tokens based on novelty and citations. Publishing requires payment that determines discovery ranking, and revision markets enable collaborative ownership with principled token flows.

## CHOIR Tokens as Compute Options (with Credits)
- CHOIR tokens function as crypto assets representing compute options
- Tokens are not sold via IAP; the app sells centralized credits that gate Ghostwriter invocations (IAP‑compliant)
- When a Ghostwriter call is made using credits, users may earn CHOIR tokens via novelty and citation rewards
- Tokens can be exchanged for credits (policy TBD); initially we may operate without charging credits

## Issuance Scope and Rewards
- Tokens are issued only on Ghostwriter invocations (not per user prompt)
- Novelty Rewards: reuse existing novelty scaling curve and eligibility thresholds
- Citation Rewards: 5 tokens per citation for now; later scaled via Choir Treasury moving averages of daily citations and split‑decision inflows
- No rewards to wallet_address='unknown'

## Publication Investment
- Pay to publish to a permalink: choir.chat/<permalink>
- Explore/search ranking increases with amount paid
- Anonymous publishing can exist separately; identity publishing is wallet‑based

## Revision Markets
- Anyone may stake to propose a revision to a published piece (discoverable via explore/search/autocite/link)
- Acceptance → staked tokens go to the piece; co‑authorship created
- Rejection → author keeps the staked tokens
- Multi‑author rule: acceptance requires unanimity; split decisions count as rejection
- Split‑decision routing: tokens that would have gone to rejecting co‑authors go to the Choir Treasury (hypothetical)

## Choir Treasury (Planned)
- Treasury is not yet deployed
- Receives tokens from split decisions in revision markets
- Redistributes tokens as citation rewards (dynamic scaling once live)

## Data & Providers (Economic Context)
- Vector DB: MVP uses Qdrant; migration path to XTrace (homomorphic encryption) under evaluation; novelty query approach TBD
- Providers: remove Fireworks; add AWS Bedrock

## Why This Works
- Service value first: users see tangible Ghostwriter improvements vs generic AI
- Economic alignment: publishing spend drives discovery ranking; revision markets create shared ownership
- Quality compounding: novelty and citations reward foundational ideas; Treasury links revision dynamics to citation emissions

## Out of Scope (Removed)
- Relationship staking terminology is deprecated; ideas are captured as publication investment and revision markets
- Phase terminology (AEIOU‑Y) and PostChain architecture are deprecated and removed
