# Migration Plan: PostChain → Conductor + Agents (First Draft)

## Scope
Replace legacy PostChain/AEIOU‑Y documentation and interfaces with Conductor + Agents architecture. Stage code changes after docs and new interface are defined.

## Current State
- Legacy PostChain docs deleted; temporary index: docs/deleted_legacy_docs_index.md
- Code for PostChain still present (to be removed after new interface is live)

## Plan Phases
1) Documentation
- Finish new architecture docs set (overview, agents/tools, rewards, privacy/security, migration)
- Update README links; remove residual PostChain/phase terminology
- Elevate tokenomics in whitepaper (done)

2) New Interface Design (Docs only)
- Define endpoints and streaming (SSE for now); protocol framing/envelope schemas = required decisions
- Describe client‑side Conductor responsibilities vs server agent responsibilities
- Specify tool boundaries (Wordbank, Vector DB/Qdrant→XTrace, Sui, Web Search, File Mgmt)

3) Incremental Implementation
- Add Conductor session route(s) and Ghostwriter call (credit‑gated) without removing old endpoints
- Add Publisher and Revision endpoints
- Wire Sui reward issuance for Ghostwriter calls (reuse novelty scaling, 5/citation)
- Gate publication to choir.chat/<permalink> by spend; rank explore/search by amount
- Logging: private client chats not transmitted; service logs Ghostwriter/publish/revision; strip PII on search

4) Migration of Callers
- Update iOS client to call new Conductor/Ghostwriter endpoints
- Integrate Wordbank (client) for wallet UX; explicit confirmations for tx
- Keep PostChain endpoints operational during transition

5) Deletion
- Remove PostChain code and the temporary deleted_legacy_docs_index.md
- Search and remove any remaining phase terminology

## Risks & Mitigations
- Unknowns with XTrace novelty search → keep Qdrant path for MVP; abstract queries
- Apple IAP constraints → centralized credits gate Ghostwriter; tokens earned on use
- Model/tool provider changes → maintain provider adapter layer; add Bedrock

## Success Criteria
- New docs reflect architecture; no phase terminology remains
- New interface supports Conductor→Ghostwriter (credits) and Publisher/Revision workflows
- Rewards issuance correct (per Ghostwriter invocation)
- Safe deletion of PostChain code with no user‑visible regressions

