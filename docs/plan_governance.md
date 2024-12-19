# Governance System

VERSION governance: 7.1

Choir’s governance model is designed to ensure that decisions about the platform’s evolution, resource allocation, and high-level direction are made in a transparent, accountable, and participatory manner. This document provides an overview of how verified identities, prediction markets (futarchy), and CHIP-based stakeholder influence come together to form a cohesive governance framework.

---

## Overview

Governance refers to the processes and mechanisms by which a community makes collective decisions. In the context of Choir, governance is essential for maintaining the platform’s integrity, directing crowdfunded resources, and continually refining the underlying protocols.

We believe that governance should remain both transparent and adaptable. Transparent governance is critical for building community trust, while adaptability ensures that the system can evolve with changing needs and priorities.

---

## Core Principles

1. **Transparency**: All proposals, votes, and outcomes are recorded in an auditable manner on the blockchain.
2. **Accountability**: Only KYC-verified users may cast binding votes, tying real-world accountability into critical decisions.
3. **Inclusivity**: While binding votes require verified identity, unverified or anonymous users can still propose ideas and participate in preliminary discussions.
4. **Decentralization**: Power is distributed among participants rather than concentrated in a single entity, limiting the potential for undue influence.
5. **Futarchy-Driven**: Major decisions—particularly around financial/resource allocation—are decided using a futarchy model, leveraging the collective intelligence of the market to predict and adopt the best outcomes.

---

## Key Mechanisms

### Verified Identity Requirement

To participate in binding on-chain votes, users must have a verified on-chain identity (KYC). This ensures governance decisions are made by real individuals with a verifiable stake in the platform and prevents Sybil-style exploits. Anonymous participants are welcome to join discussions and propose ideas, but their votes on final proposals are advisory only.

### CHIP-Weighted Voting

While CHIP holdings matter for economic interactions, futarchy voting power is primarily determined by verified identity status. Each verified user receives a baseline of governance influence, which can be modestly increased by CHIP stakes. This model balances out the need to reward actual participants without enabling large token holders to dominate every decision.

### Futarchy Implementation

For proposals with significant impact on the platform (e.g., changes to fee structures, vast development budgets, major feature rollouts), a futarchy-based approach is used:

• A prediction market is created around each proposal’s potential outcomes.
• Verified users (including authorized AI agents) buy and sell outcome tokens, reflecting their best estimate of future conditions under each scenario.
• Once the market matures (or a predefined deadline is reached), the proposal outcome with the highest-value market prediction is automatically enacted through on-chain execution.

By “reverse delegating” decisions to markets, Choir harnesses the collective intelligence of participants to discover the most beneficial course of action for the platform.

---

## SAI Participation in Governance

Social AI (SAI) agents can contribute their insights within futarchy or other decision-making frameworks, provided they are operated by a KYC-verified user. That ve­rified user remains ultimately accountable for any trades, predictions, or votes made by the AI. This approach augments the intelligence of the system with advanced analytics while anchoring accountability in real-world identities.

---

## Flow of a Governance Proposal

1. **Idea & Discussion**: Any user—anonymous or verified—proposes an idea in the governance discussion space.
2. **Preliminary Consensus**: The community debates the proposal informally. If there is broad agreement that the idea has merit, it moves forward.
3. **Formal Submission**: A KYC-verified user (or group) officially submits the proposal on-chain.
4. **Futarchy Market Creation**: A prediction market is created, offering outcome tokens for the various possible scenarios (e.g., acceptance vs. rejection or Option A vs. Option B).
5. **Market Participation**: Verified governance participants (including SAI) buy and sell these outcome tokens, revealing collective preferences and perceived “best” outcomes.
6. **On-Chain Execution**: After a set duration or once the market stabilizes, the outcome with the most value (highest priced tokens) is automatically enacted via smart contract logic.

---

## Conclusion

Choir’s governance model leverages the futarchy principle, combining KYC-verified identities with the predictive power of collective markets. Verified identities ensure accountability, while outcome-based prediction markets help the community arrive at the most beneficial decisions. This synergy makes Choir’s governance both robust and future-facing—able to adapt as the platform grows while remaining grounded in shared accountability and transparent oversight.
