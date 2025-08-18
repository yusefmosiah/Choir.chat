# Conductor + Agents: Architecture Overview (First Draft)

## Purpose
This document introduces Choir's Conductor + Agents architecture that replaces the legacy PostChain/AEIOU‑Y model. It explains the runtime topology, roles, and high‑level data/control flows, and anchors tokenomics interactions at a conceptual level.

## Canonical Principles
- Conductor is a fast client‑side agent that orchestrates work
- Server‑side agents perform heavier tasks (principal: Ghostwriter)
- "Instruments" = agents; no fixed number (Ghostwriter, Publisher, Revision)
- Tools are capabilities agents invoke (Wordbank, Vector DB, Sui, Web Search, File Mgmt)
- Novelty + citation rewards are issued only on Ghostwriter invocations
- Publication investment and revision markets define ranking and collaboration

## High‑Level Topology
- Client
  - Conductor (fast LLM; GPU TEE target)
  - Tools: Wordbank (wallet), Web Search, File Mgmt (client‑scoped)
  - Responsibilities: quick responses, privacy‑sensitive operations, tool routing
- Service
  - Ghostwriter (server agent)
  - Publisher (server agent)
  - Revision (server agent)
  - Tools: Vector DB (Qdrant → XTrace migration TBD), Sui (rewards), Web Search, File Mgmt
  - Responsibilities: research, drafting, citation, reward issuance, publishing, revision workflows

## Agents vs Tools
- Agents: autonomous orchestrators for a responsibility area (Ghostwriter, Publisher, Revision)
- Tools: concrete capabilities that agents call (wallet ops, vector search, Sui txs, web search, file IO)
- Wordbank is a tool (not an agent): natural‑language wallet control (client‑side)

## Ghostwriter Invocation (Conceptual Flow)
1) User asks Conductor for substantial work (e.g., article/analysis)  
2) Conductor decides to invoke Ghostwriter (credit‑gated)  
3) Ghostwriter orchestrates planning, research (web/vector/files/data), drafting, citation, critical review, style revision, final drafting (amorphous: steps may merge/split)  
4) Ghostwriter computes novelty and citations  
5) Sui tool: issue novelty reward (if eligible) and citation rewards (5 per citation for now)  
6) Conductor synthesizes and presents final output

Notes
- Novelty scaling and thresholds: reuse existing design  
- Rewards issuance triggered only on Ghostwriter call (not per prompt)

## Publication Investment & Revision Markets (Conceptual)
- Publish: pay to create choir.chat/<permalink>; higher spend → higher rank in explore/search  
- Revise: anyone may stake to propose revisions (via explore/search/autocite/link)
- Accept: stake goes to the piece; co‑authorship added  
- Reject: author keeps the stake  
- Multi‑author: acceptance requires unanimity; split = rejection  
- Split‑decision flow: tokens that would have gone to rejecting coauthors go to the Choir Treasury (hypothetical) → Treasury redistributes as citation rewards (5 per citation now; later dynamic via moving averages)

## Data & Providers (MVP Reality → Roadmap)
- Vector DB: Qdrant (MVP). Migration path to XTrace (homomorphic encryption) under evaluation; novelty query approach TBD
- LLM Providers: Anthropic, OpenAI, Google, OpenRouter, AWS Bedrock (replace Fireworks)
- Streaming: Server‑Sent Events (SSE) for now; endpoint style and envelope/protocol framing are required decisions (deferred)

## Privacy & Security (Summary)
- Keys: Sui keys on client (wallet) and server (node). Crypto controlled via tool calls  
- Wallet UX: address + QR receive, balances, send; explicit user confirmations  
- Client privacy: private chats possible. Service logs Ghostwriter, publishing, revision proposals. Search strips PII
- GPU TEE target for Conductor; XTrace aligns with privacy roadmap

## Required Decisions (Trackers)
- Endpoint style and protocol framing (session semantics, envelope schemas)  
- XTrace novelty search method and rollout plan  
- Credit↔token exchange policy  
- Final provider roster and model routing rules

## Success Criteria
- Legible, fast UX: responses from Conductor with transparent escalation  
- Reliable research and citation: verifiable references and issuance  
- Clear economics: users understand credits, issuance, publishing, and revisions  
- Privacy posture: client‑side sovereignty with operational logging on service

