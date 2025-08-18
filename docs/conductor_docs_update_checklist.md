# Conductor + Agents Documentation Update Checklist

## Overview
This checklist covers the complete transformation from PostChain/AEIOU-Y legacy system to the new Conductor + Agents architecture. It addresses all issues identified in `docs/to_rectify.tmp.md`.

## Canon Established
- PostChain and AEIOU-Y are deprecated and will be removed next week
- New runtime: client-side Conductor agent orchestrates; calls server-side agents (principally Ghostwriter)
- Wordbank is a tool (not an agent) for client-side wallet control via natural language
- Ghostwriter has tools: vector DB + Sui (for novelty/citation rewards). Both sides have web search and file mgmt tools
- Novelty rewards are issued per Ghostwriter invocation (not per user prompt)
- No canonical stages; Ghostwriter architecture is amorphous (planning, research, drafting, citation, review, style, final drafting - may be combined/split per implementation)
- Do not change code yet. Order: rectify docs → write "how to change code" → new interface → remove old code
- Publisher and Revision are additional agents ("instruments")
- Publishing requires payment to obtain a permalink (choir.chat/<...>); explore/search ranking increases with more paid
- Users can submit revisions to any published piece (via explore/search/autocite/direct link)
- Revision outcomes:
  - Accept → staked tokens go to the published piece which becomes co-owned by coauthors
  - Reject → author keeps the staked tokens
- Multi-coauthor rule: acceptance requires unanimity; split decision counts as rejection
- Split-decision token flow: tokens that would have gone to rejecting coauthors go to the Choir Treasury
- Citation rewards are funded by Treasury distributions from split decisions (not issued ex nihilo)
- Token issuance only on Ghostwriter calls (not on every user prompt)
- Monetization: sell centralized credits via IAP; Ghostwriter consumes credits and may earn CHOIR tokens; tokens↔credits exchange deferred
- Novelty scaling: reuse existing curve; citation rewards = 5 per citation (later scaled by Treasury moving averages)
- Same eligibility thresholds as before; initially run without charging credits until user base grows

---

## A) DELETE LEGACY POSTCHAIN DOCS (remove files; do not change code yet)

- Create a temporary index file: `docs/deleted_legacy_docs_index.md` listing all deleted docs that still have working code. Remove this index once old code is removed.
- Remove the following documentation files now:

#### Core PostChain Architecture Docs
- [ ] docs/postchain_temporal_logic.md
- [ ] docs/postchain_service_redesign.md
- [ ] docs/postchain_ui_redesign.md
- [ ] docs/postchain_ui_refactor_vertical_scroll_with_virtual_pages_checklist.md

#### Phase Requirements Docs
- [ ] docs/require_phase_requirements_index.md
- [ ] docs/require_action_phase.md
- [ ] docs/require_yield_phase.md
- [ ] Any other AEIOU-Y phase requirement docs

#### System Architecture Docs with PostChain References (delete or rewrite to remove PostChain sections)
- [ ] docs/state_management_patterns.md
- [ ] docs/stack_argument.md
- [ ] docs/security_considerations.md
- [ ] docs/blockchain_integration.md
- [ ] docs/data_engine_model.md

#### Content and Marketing Docs (rewrite to remove PostChain mentions)
- [ ] docs/e_concept.md
- [ ] api/content/support.md (remove "PostChain" FAQ)
- [ ] api/blog/loop_of_thought.md (remove AEIOU-Y PostChain section)
- [ ] api/content/marketing.md
- [ ] api/content/landing.md

#### Code Documentation (mark legacy path only in the temporary index)
- [ ] api/app/postchain/README.md

#### Historical/Changelog (note legacy in temporary index)
- [ ] docs/CHANGELOG.md

### README.md Updates
- [ ] Remove/replace PostChain Temporal Logic link
- [ ] Replace "Context Management in the PostChain Workflow" section
- [ ] Update AEIOU-Y table to point to new architecture
- [ ] Replace PostChain logic references in directory structure

### Rewards Documentation Updates
- [ ] docs/rewards_system.md - clarify "per Ghostwriter invocation, not per user prompt"
- [ ] docs/reward_function.md - update issuance semantics
- [ ] Update any "per prompt" language across all docs

---

## B) PLAN NEW DOCS TO CREATE

### 1. Architecture Overview
**File**: `docs/conductor_agents_overview.md`
**Purpose**: High-level system overview
**Outline**:
- Conductor + Agents (instruments = agents; no fixed number)
- Client-side Conductor agent orchestration model
- Server-side agents registry, principal: Ghostwriter
- Agents vs tools: definitions and relationships
- No fixed "stages"; Ghostwriter architecture is amorphous

### 2. Agents and Tools
**File**: `docs/agents_and_tools.md`
**Outline**:
- Conductor (client-side agent)
  - Tools: Wordbank (wallet control via NL), web search, file mgmt
- Ghostwriter (server-side agent)
  - Tools: vector DB, Sui (novelty and citation rewards), web search, file mgmt
- Future agents TBD
- Tool capability boundaries and permissions

### 3. Ghostwriter Agent Spec
**File**: `docs/agent_ghostwriter_spec.md`
**Outline**:
- Responsibilities: planning, research (web/vector/files/data), drafting, citation, critical review, style revision, final drafting
- Amorphous orchestration: steps may be merged/split across LLM calls; TBD by implementation
- Inputs/outputs contracts (conceptual; not code schemas yet)
- Reward hooks: where novelty/citation assessments occur

### 4. Client–Server Interaction
**File**: `docs/client_conductor_to_server_agents.md`
**Outline**:
- Client-side invocation of Conductor (runtime model)
- Server-side agent dispatch and tool execution
- Streaming semantics and auth (high-level)
- Failure/retry considerations (conceptual)
- Privacy considerations for both sides

### 5. Rewards Model (Updated)
**File**: `docs/rewards_model.md`
**Outline**:
- Novelty rewards per Ghostwriter invocation (not per prompt)
- Citation rewards model remains; base units (no floats); exclude wallet_address='unknown'
- Strategic notes: when novelty is considered; measuring similarity; no per-prompt issuance
- UX messaging guidelines (avoid implying per-prompt rewards)

### 6. Privacy and Security Roadmap
**File**: `docs/privacy_security_roadmap.md`
**Outline**:
- Keys: Sui keys exist both on client (wallet) and server (node); crypto is controlled via tool calls
- Wallet UX: show address + QR to receive, display balances, send with explicit user confirmation for all txs
- Data handling/logging: client aims for maximum privacy; service logs as much as possible; private chats possible; Ghostwriter/publishing/revision proposals are logged; search strips PII
- MVP reality: server-side transaction execution and keys for expedience
- Roadmap to TEE-first (GPU TEE), on-device sensitive ops
- Wordbank tool: client-side wallet control via NL with safety prompts
- Vector DB path: migrating from Qdrant → XTrace (HE vector DB) under evaluation; novelty query approach TBD

### 7. Migration Plan
**File**: `docs/migration_plan_postchain_to_conductor.md`
**Outline**:
- Deletion plan for PostChain docs and code
- New interface plan (replace PostChain endpoints and flows)
- Incremental steps: docs → new interface → move callers → remove old code
- Communication plan for contributors

### 8. UI Concepts (Conductor UI)
**File**: `docs/conductor_ui_design.md`
**Outline**:
- Keep vertical pagination form factor and page snapping preferences
- Remove "PostChain UI" terminology
- Page behaviors, accessibility, haptics, page indicators, internal vs external scroll
- Thread title/display choices
- Publishing: minimal anonymity by default

### 9. Glossary
**File**: `docs/glossary.md`
**Outline**: Conductor, agent, tool, Ghostwriter, Wordbank, novelty reward (per invocation), citation reward, publication investment, revision markets, Choir Treasury (hypothetical)

### 10. Implementation Guide
**File**: `docs/implementation_guide_new_interface.md`
**Outline**:
- How to change the code: new service endpoints (SSE for now), request/response envelopes (TBD), auth boundaries (TBD)
- Conductors' client-side responsibilities vs server agent responsibilities
- Test strategy proposal
- Required decisions: endpoint style, protocol framing, envelope schema

---

## C) ADDITIONAL ISSUES FROM to_rectify.tmp.md

### Issue #2: Economic Models - "Compute Options" vs "Relationship Staking"
**Status**: Needs canonical decision
**Files to address**:
- [ ] docs/core_economics.md (complete rewrite needed)
- [ ] docs/relationship_staking.md (deprecate entirely?)
- [ ] Any other relationship staking references

**Questions for canon**:
- Confirm: CHOIR tokens are "crypto assets representing compute options" (whitepaper model)
- Deprecate: "Relationship Staking" and "Currency of Meaningful Relationships" model
- Primary function: users purchase and spend tokens for Ghostwriter calls (B2C service model)

### Issue #3: Token Purpose - Asset to Spend vs Reward to Earn
**Status**: Needs canonical decision
**Files to address**:
- [ ] docs/evolution_token_economics.md
- [ ] Any docs emphasizing earning over spending

**Questions for canon**:
- Primary loop: customer spending tokens or contributor earning them?
- Relationship between paying for services vs earning through rewards
- Frame "compute options" as primary utility, rewards as secondary incentive layer?

### Issue #4: Technical Implementation Plans
**Status**: Needs canonical decision
**Files to address**:
- [ ] Update or abstract away "Qdrant-Sui MVP" specifics
- [ ] Deprecate abandoned architecture docs (LangGraph, pure MCP server)

**Questions for canon**:
- Vector DB: Document migration path Qdrant → XTrace (HE vector DB) as TBD; keep Qdrant in MVP until XTrace stabilized?
- Providers: Remove Fireworks; add AWS Bedrock as LLM provider
- Streaming: Keep SSE for now (endpoint style and envelope/protocol framing = required decisions, deferred)
- Docs handling: Fully delete PostChain docs now; add a single temporary index listing deleted docs that still have working code; delete that index once old code is removed
- Terminology: Remove all phase terminology throughout docs
- Providers: remove Fireworks; add AWS Bedrock
- Streaming: keep SSE for now; endpoint style and envelope/protocol = required decisions (deferred)

### Issue #5: Privacy and Security Model
**Status**: Needs canonical decision
**Files to address**:
- [ ] docs/security_considerations.md
- [ ] docs/blockchain_integration.md
- [ ] docs/wallet_languification.md

**Questions for canon**:
- MVP: server-side transaction model for expedience?
- Roadmap: TEE-first and on-device model as future goal?
- Clear staging of privacy evolution?

---

## D) ORDER OF OPERATIONS

### Phase 1: Deprecation and Canon Clarification
1. [ ] Add DEPRECATED banners to all listed PostChain docs
2. [ ] Update README.md to remove PostChain references
3. [ ] Clarify canonical decisions for Issues #2-5 with user
4. [ ] Update rewards documentation for "per Ghostwriter invocation"

### Phase 2: New Documentation Creation
1. [ ] Create empty stubs for new docs with section headings
2. [ ] Fill in Architecture Overview and Agents/Tools docs first
3. [ ] Complete Rewards Model and Migration Plan docs
4. [ ] Address economic model conflicts (Issues #2-3)
5. [ ] Address technical and privacy roadmap (Issues #4-5)

### Phase 3: Implementation Planning (After docs approved)
1. [ ] Draft implementation guide for code changes
2. [ ] Create new interface specifications
3. [ ] Plan migration strategy for existing callers
4. [ ] Schedule removal of PostChain code and deprecated docs

---

## E) VALIDATION CHECKLIST

### Documentation Consistency
- [ ] All PostChain references either deprecated or updated
- [ ] All AEIOU-Y references either deprecated or removed
- [ ] Consistent "Conductor + Agents" terminology throughout
- [ ] Novelty rewards consistently described as "per Ghostwriter invocation"
- [ ] Economic model consistently reflects canonical decisions
- [ ] Privacy roadmap clearly stages MVP vs future goals

### Completeness
- [ ] All issues from to_rectify.tmp.md addressed
- [ ] New architecture fully documented
- [ ] Migration path clearly defined
- [ ] Implementation guidance provided
- [ ] Glossary covers all new terminology

### User Experience
- [ ] Clear deprecation notices guide users to new docs
- [ ] New docs are accessible to both technical and business audiences
- [ ] Migration timeline is realistic and well-communicated
- [ ] No broken internal links after updates
