# Privacy & Security Roadmap (First Draft)

## Principles
- Client sovereignty for sensitive data; service operational logging for value‑bearing actions
- Clear separation of agents vs tools; least privilege and explicit consent for value transfer

## Keys & Signing
- Client: Sui wallet on device (Keychain). Wordbank tool mediates NL wallet actions (show address + QR, balances, send). All tx require explicit user confirmation. On‑device signing when applicable
- Server: Sui node and keys for service‑side actions (e.g., reward issuance). Ghostwriter uses Sui tool to issue novelty/citation rewards on eligible calls

## Data Handling & Logging
- Private chats permitted (client privacy). Service logs Ghostwriter invocations, publishing, and revision proposals
- Web search/file processing: strip PII prior to service logging; redact sensitive payloads
- Retention: logs retained for ops; no external sharing of user content without consent

## Runtime Targets
- Conductor: fast model in GPU TEE (target). Transparent tool escalation
- Vector DB: MVP Qdrant; evaluate XTrace (homomorphic encryption) for private vector search; novelty query design TBD

## Roadmap (No Dates)
- MVP
  - Server‑side reward issuance via Sui tool
  - Client Wordbank tool with explicit confirmations
  - SSE streaming; endpoint/protocol framing deferred
- Near‑Term
  - Client‑signed tx flow for value transfers (if not already); tool permission scoping
  - Provider updates: remove Fireworks; add AWS Bedrock
- Future
  - GPU TEE LLM with remote attestation
  - XTrace HE vector DB integration for novelty and recall
  - Choir Treasury contract for citation emissions scaled by moving averages
  - Partitioned logging and PII minimization

## Publishing & Anonymity
- Pay‑to‑publish to choir.chat/<permalink> with responsive web UI
- Minimal anonymity by default; wallet‑based identity option for attributed publishing

