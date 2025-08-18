# Agents and Tools (First Draft)

## Purpose
Define agents (autonomous responsibility domains) and tools (capabilities invoked by agents), clarifying boundaries and safety behaviors.

## Agents
- Conductor (client)
  - Role: Fast, chat‑speed orchestrator; privacy‑sensitive ops; tool selection; synthesis
  - Calls: Ghostwriter, Publisher, Revision (server agents)
- Ghostwriter (service)
  - Role: Planning, research (web/vector/files/data), drafting, citation, critical review, style revision, final drafting (amorphous, merge/split steps)
  - Tools: Vector DB (Qdrant → XTrace TBD), Web Search, File Mgmt, Sui (reward issuance)
- Publisher (service)
  - Role: Pay‑to‑publish permalink creation; ranking based on spend; expose explore/search; serve responsive choir.chat/<permalink>
  - Tools: Payment/credits system, Web UI delivery, indexing
- Revision (service)
  - Role: Stake to propose edits; accept/reject; co‑authorship creation; unanimity requirement; split‑decision routing to Treasury
  - Tools: Payment/credits, Sui accounting (stake and distribution), versioning

## Tools
- Wordbank (client)
  - Role: Natural‑language wallet control (show address + QR, balances, send)
  - Safety: All tx require explicit user confirmation; on‑device signing if applicable
- Vector DB
  - MVP: Qdrant; Roadmap: XTrace (HE vector DB) under evaluation
  - Purpose: novelty search, context recall, citation grounding
- Sui Tool (service)
  - Role: Issue novelty rewards (per Ghostwriter invocation), citation rewards (5 per citation now), manage stakes, Treasury allocations
- Web Search
  - Role: multi‑provider search; PII stripping before service logging
- File Management
  - Role: ingest txt, md, pdf, epub; YouTube transcripts; dataset adapters; safe uploads

## Safety and Permissions
- Principle of least privilege for tools
- Confirmation gates for any value transfer (Wordbank, Revision stakes)
- Logging policy: client minimal; service logs Ghostwriter/publish/revision operations
- Data policy: strip PII on search/query payloads; redact sensitive content in logs

## Notes
- Agents may gain additional tools over time; tools are shared across agents when safe
- Conductor remains client‑side; Ghostwriter/Publisher/Revision remain server‑side

