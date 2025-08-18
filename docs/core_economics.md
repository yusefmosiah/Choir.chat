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
