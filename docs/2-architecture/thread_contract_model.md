# Thread Contract and Co-Ownership Model

## Overview

The Thread Contract is a core architectural component of Choir that governs thread ownership, contribution rights, and reward distribution. Built on the Fractional Quantum Anharmonic Oscillator (FQAHO) model, it transforms threads from individual creations into collectively owned assets through a discovery, contribution, and approval process.

## Core Concepts

### 1. Threads as Assets

Threads in Choir are more than just conversation chains—they are digital assets with:

- **Ownership rights**: Initially belonging to the creator, potentially shared over time
- **Economic value**: Derived from citations, contributions, and content quality
- **Governance mechanisms**: Rules for contribution and ownership changes

### 2. Discovery Through Citation

Citations serve as the primary discovery mechanism for threads:

- When one thread cites another, it creates a navigable link
- Users can explore and discover threads through citation networks
- Citations distribute rewards while also increasing thread visibility
- The citation graph forms a knowledge network of interconnected threads

### 3. Contribution and Co-Ownership

The path from discovery to co-ownership follows a defined process:

1. **Discovery**: User finds a thread through citations or exploration
2. **Contribution Request**: User pays tokens to propose a contribution
3. **Review**: Thread owner(s) review the contribution
4. **Approval/Rejection**: If approved, the contributor becomes a co-owner
5. **Ongoing Participation**: Co-owners share in future rewards and governance

### 4. FQAHO Ownership Distribution

The Fractional Quantum Anharmonic Oscillator model provides a mathematical framework for:

- Calculating fair ownership distribution
- Balancing early vs. late contributions
- Ensuring diminishing returns for subsequent token investments
- Creating economic incentives that align with quality contributions

## Thread Lifecycle

### Initial Creation

Threads begin with sole ownership by the creator:

- The creating user establishes the thread
- Initial content sets the thread's direction
- No token investment is required for the creator

### Citation and Discovery

Citations make threads discoverable to potential contributors:

- Other threads can cite content, creating cross-thread navigation
- Citations generate rewards for the thread owners
- Popular threads appear more frequently in citation networks

### Contribution Requests

Users can request to contribute to discovered threads:

- Token payment is required to submit a contribution request
- Payment amount affects potential ownership share
- Tokens are held in escrow until approval/rejection

### Ownership Expansion

When contributions are approved:

- Contributor receives ownership shares based on FQAHO model
- Original owner's share is diluted according to the model
- Thread becomes jointly owned by multiple participants
- Rewards are subsequently distributed according to ownership percentages

### Ongoing Governance

Co-owners collectively govern the thread:

- Contribution approvals may require consensus or majority
- Reward distribution follows ownership percentages
- Further dilution occurs with additional approved contributors

## Integration with Phase Architecture

The Thread Contract interfaces with the PostChain phases at several points:

### Experience Phase

- Retrieves content from threads based on citations
- Records when content from one thread is used in another

### Observation Phase

- Creates and records thread-to-thread links
- Persists citation relationships to the knowledge graph
- Tracks ownership changes for historical context

### Understanding Phase

- Preserves citation metadata during context pruning
- Maintains attribution chains even when summarizing content

### Yield Phase

- Signals reward distribution for citations
- Calculates reward amounts based on citation impact
- Triggers token transfers to thread contracts

## Technical Implementation

### Thread Contract API

```python
class ThreadContract:
    async def request_contribution(
        thread_id: str,
        contributor_id: str,
        token_amount: int,
        content: str
    ) -> ContributionRequest:
        """Request to contribute to a thread by paying tokens."""
        pass

    async def process_contribution_approval(
        contribution_id: str,
        approved: bool,
        feedback: str = None
    ) -> OwnershipUpdate:
        """Process approval/rejection of a contribution request."""
        pass

    async def distribute_rewards(
        thread_id: str,
        reward_amount: int,
        reward_type: str
    ) -> RewardDistribution:
        """Distribute rewards to thread owners."""
        pass

    async def get_ownership_shares(
        thread_id: str
    ) -> List[OwnershipShare]:
        """Get current ownership distribution for a thread."""
        pass
```

### FQAHO Calculation

The FQAHO model determines ownership shares through a quantum-inspired formula:

```python
def calculate_fqaho_share(
    thread_id: str,
    token_amount: int
) -> float:
    """Calculate ownership share based on FQAHO model."""
    # Get existing investments and ownership distribution
    existing_investments = get_total_investment(thread_id)

    # Apply FQAHO formula
    # Ownership share is non-linear and depends on:
    # - Timing (early vs. late investment)
    # - Amount (diminishing returns for large amounts)
    # - Existing distribution (harder to dilute established threads)

    base_share = token_amount / (token_amount + existing_investments)
    quantum_adjustment = calculate_quantum_adjustment(thread_id, token_amount)

    return base_share * quantum_adjustment
```

### Token Flow

Tokens flow through the system in several ways:

- **Contribution Payments**: From contributors to thread (via escrow)
- **Citation Rewards**: From system to threads based on citations
- **Owner Distributions**: From threads to owners based on ownership shares

## User Experience

### For Thread Creators

- Create threads without initial token investment
- Review and approve/reject contribution requests
- Receive decreasing ownership percentage as more contributors join
- Earn rewards based on thread popularity and citations

### For Contributors

- Discover threads through citations and exploration
- Pay tokens to submit contribution requests
- Receive ownership shares when contributions are approved
- Participate in thread governance and reward distribution

### For Readers

- Navigate the citation network to discover related content
- See attribution and ownership information on threads
- Assess thread quality based on citation frequency
- Choose to become contributors to valuable threads

## Architectural Impact

The Thread Contract model fundamentally reshapes Choir's architecture by:

1. **Creating Economic Alignment**: Aligning economic incentives with content quality
2. **Enabling Collective Ownership**: Transforming threads from individual to collective assets
3. **Building a Discovery Network**: Using citations as both reward mechanism and discovery tool
4. **Supporting Scale-Free Growth**: Allowing organic growth of the knowledge network

## Cross-Platform Considerations

The Thread Contract must function consistently across platforms:

- **iOS/Swift**: Native implementation with local caching
- **Web**: JavaScript implementation with similar interfaces
- **Backend**: Centralized contract logic for consistency
- **Blockchain (optional)**: Potential future integration for trustless operation

## Open Questions and Future Directions

1. **Governance Evolution**: How does governance scale with many co-owners?
2. **Market Dynamics**: How to prevent ownership manipulation or speculation?
3. **Integration with External Systems**: How might this connect to other ownership models?
4. **Privacy Considerations**: How to balance public citation with private threads?

## Conclusion

The Thread Contract and co-ownership model represents a fundamental innovation in collaborative AI systems. By treating threads as jointly-owned assets discovered through citation networks, Choir creates an ecosystem where quality content discovery, contribution, and ownership are aligned in a virtuous cycle.
