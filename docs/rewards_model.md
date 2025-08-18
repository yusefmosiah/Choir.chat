# Rewards Model (First Draft)

## Purpose
Define when and how CHOIR tokens are issued, clarify novelty and citation rewards, and outline publishing/revision economics.

## Issuance Scope
- Tokens are issued only on Ghostwriter invocations (not per user prompt)
- Ghostwriter calls are credit‑gated (IAP‑compliant centralized credits)
- Initially, we may run without charging credits until user base grows

## Novelty Rewards
- Reuse existing novelty scaling curve
- Same eligibility thresholds as before
- Compute novelty per Ghostwriter call using vector DB similarity (MVP: Qdrant; Roadmap: XTrace HE vector DB); exact query method TBD for XTrace

## Citation Rewards
- 5 tokens per citation for now
- Future: scaled by Choir Treasury based on moving averages of daily citations and split‑decision inflows
- No rewards to wallet_address='unknown'

## Publication Investment
- Pay to publish to choir.chat/<permalink>
- Explore/search ranking increases with paid amount
- Anonymous vs identity publishing (wallet‑based identity)

## Revision Markets
- Anyone may stake to propose a revision to a published piece (found via explore/search/autocite/link)
- Accept → staked tokens go to the piece; co‑authorship is created
- Reject → author keeps the staked tokens
- Multi‑author: acceptance requires unanimity; split decision counts as rejection
- Split‑decision routing: tokens that would have gone to rejecting co‑authors go to the Choir Treasury

## Treasury (Hypothetical)
- Not yet deployed; serves as sink for split decisions
- Redistributes tokens as citation rewards (dynamic emissions later)

## UX Messaging Guidelines
- Avoid implying rewards on every prompt; clarify rewards occur on Ghostwriter calls
- Explain credits vs tokens simply: credits gate Ghostwriter; tokens are earned for value and can be exchanged for credits (policy TBD)
- Make publishing costs and ranking effects explicit and predictable

## Open Items
- Credit↔token exchange policy and rate
- XTrace novelty search design
- Final provider routing and fees

