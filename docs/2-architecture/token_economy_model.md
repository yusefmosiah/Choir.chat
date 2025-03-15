# Token Economy Model

## Overview

Choir implements a dual-reward token economy that incentivizes both content creation and content quality. This model creates a self-sustaining ecosystem where users are rewarded for contributing novel information and for creating content valuable enough to be cited by others.

## Core Reward Mechanisms

The token economy features two primary reward types, each addressing a different aspect of value creation:

1. **New Message Reward**: Compensates users for the value of work input (effort)
2. **Citation Reward**: Compensates thread owners for the value of work results (quality)

This dual-reward structure creates a balanced economy that recognizes both the effort of content creation and the quality of the resulting content.

## New Message Reward

### Mechanism

The new message reward is issued to users when they contribute messages with high information novelty:

- Reward amount is inversely proportional to semantic similarity with existing content
- Highly novel messages (low similarity to prior content) receive larger rewards
- Redundant messages (high similarity to prior content) receive minimal rewards

### Calculation Process

The new message reward is calculated during the Experience phase:

```python
async def calculate_new_message_reward(
    message_content: str,
    context: List[Message]
) -> TokenReward:
    """Calculate reward for a new message based on novelty."""
    # Generate embedding for the message
    message_embedding = await embedding_service.embed(message_content)

    # Retrieve semantically similar content from vector database
    similar_content = await vector_db.similarity_search(
        message_embedding,
        top_k=5,
        min_relevance=0.6
    )

    # Calculate average similarity score
    if similar_content:
        avg_similarity = sum(item.relevance_score for item in similar_content) / len(similar_content)
    else:
        avg_similarity = 0.0

    # Calculate novelty (inverse of similarity)
    novelty = 1.0 - avg_similarity

    # Apply reward function
    # Higher novelty = higher reward, with minimum threshold
    base_reward = CONFIG.MESSAGE_BASE_REWARD
    novelty_multiplier = calculate_novelty_multiplier(novelty)

    reward_amount = max(
        CONFIG.MIN_MESSAGE_REWARD,
        base_reward * novelty_multiplier
    )

    # Create reward record
    reward = await reward_service.create_reward(
        recipient_id=context[-1].user_id,
        amount=reward_amount,
        reason="new_message",
        metadata={
            "message_id": context[-1].id,
            "novelty_score": novelty,
            "similar_content_count": len(similar_content)
        }
    )

    return TokenReward(
        recipient_id=context[-1].user_id,
        amount=reward_amount,
        reason="new_message",
        novelty_score=novelty
    )
```

### Integration with Experience Phase

The new message reward calculation is integrated into the Experience phase:

```python
async def process_experience(
    content: Dict,
    context: List[Message]
) -> ExperienceResult:
    """Process the Experience phase with reward calculation."""
    # Normal Experience phase processing
    retrieved_info = await retrieve_relevant_information(content, context)

    # Calculate message novelty and reward
    if is_user_message(context[-1]):
        message_reward = await calculate_new_message_reward(
            message_content=context[-1].content,
            context=context
        )
    else:
        message_reward = None

    return ExperienceResult(
        content={
            "original_content": content,
            "retrieved_information": retrieved_info
        },
        metadata={
            "message_reward": message_reward._asdict() if message_reward else None
        }
    )
```

## Citation Reward

### Mechanism

The citation reward is issued to thread owners when their thread content is cited by other threads:

- Rewards are distributed to the thread (not individual messages)
- Distribution among thread co-owners follows ownership percentages
- Reward amount is based on the impact and usage of the citation

### Calculation Process

Citation rewards are calculated during the Yield phase:

```python
async def calculate_citation_rewards(
    citations: List[Citation],
    final_response: str
) -> List[TokenReward]:
    """Calculate rewards for citations used in the final response."""
    rewards = []

    for citation in citations:
        # Determine impact of citation on the final response
        citation_impact = calculate_citation_impact(citation, final_response)

        if citation_impact > 0:
            # Calculate reward amount based on impact
            reward_amount = CONFIG.CITATION_BASE_REWARD * citation_impact

            # Create reward record
            reward = await reward_service.create_reward(
                recipient_thread_id=citation.target_thread_id,
                amount=reward_amount,
                reason="citation",
                metadata={
                    "citation_id": citation.id,
                    "impact_score": citation_impact,
                    "source_thread_id": citation.source_thread_id
                }
            )

            rewards.append(TokenReward(
                recipient_id=citation.target_thread_id,
                recipient_type="thread",
                amount=reward_amount,
                reason="citation",
                impact_score=citation_impact
            ))

    return rewards
```

## Token Flow Lifecycle

The token economy creates a full lifecycle of value:

1. **Earning**: Users earn tokens by contributing novel messages
2. **Investment**: Users spend tokens to contribute to valuable threads
3. **Ownership**: Approved contributions convert tokens to ownership shares
4. **Returns**: Thread owners receive citation rewards based on ownership percentages
5. **Reinvestment**: Users can reinvest earned tokens in other threads

## Economic Balance

The token economy is designed to maintain balance through several mechanisms:

### Supply Controls

- **Base Reward Rates**: Configurable base reward amounts
- **Reward Caps**: Maximum rewards per time period
- **Novelty Thresholds**: Minimum novelty requirements for rewards
- **Impact Minimums**: Threshold for citation impact before rewards

### Demand Controls

- **Contribution Minimums**: Minimum token amount for thread contributions
- **Ownership Dilution**: FQAHO model controls dilution rates
- **Token Sinks**: Potential transaction fees or other token sinks

## User Experience

### Reward Visibility

Users can see their rewards through various interface elements:

- **New Message Rewards**: Shown after the Experience phase processes
- **Contribution Opportunities**: Presented after engaging with cited threads
- **Ownership Reports**: Display current thread ownership and reward history
- **Token Balance**: Shows available tokens for contribution

### Examples

**New Message Reward Experience:**

```
"Your message earned 15 tokens due to its high novelty (87% new information)."
```

**Citation Reward Experience:**

```
"Your thread 'Quantum Computing Applications' earned 25 tokens from 3 citations."
```

**Contribution Opportunity:**

```
"You've engaged with the thread 'Machine Learning Ethics'. Contribute to this thread (min. 10 tokens)?"
```

## Technical Implementation

### Token Service API

```python
class TokenService:
    async def issue_reward(
        recipient_id: str,
        recipient_type: str,  # "user" or "thread"
        amount: int,
        reason: str,
        metadata: Dict = None
    ) -> TokenReward:
        """Issue tokens as a reward."""
        pass

    async def process_contribution(
        from_user_id: str,
        to_thread_id: str,
        amount: int,
        contribution_content: str
    ) -> ContributionTransaction:
        """Process a contribution transaction."""
        pass

    async def distribute_thread_rewards(
        thread_id: str,
        amount: int,
        reason: str
    ) -> List[OwnerDistribution]:
        """Distribute rewards to thread owners based on ownership percentages."""
        pass

    async def get_balance(
        entity_id: str,
        entity_type: str  # "user" or "thread"
    ) -> TokenBalance:
        """Get token balance for a user or thread."""
        pass
```

## Cross-Platform Considerations

The token economy must function consistently across platforms:

- **Local Token Cache**: Client-side balance cache for responsive UX
- **Synchronized Ledger**: Backend token ledger for consistency
- **Reward Visualization**: Platform-specific visualizations for rewards
- **Contribution Flow**: Consistent contribution UI across platforms

## Open Questions and Future Directions

1. **Token Utility**: Additional uses for tokens beyond thread contributions?
2. **Economic Stability**: Mechanisms to prevent inflation/deflation over time?
3. **Token Exchange**: Should tokens be exchangeable for other currencies or benefits?
4. **Anti-Gaming Measures**: How to prevent reward exploitation?

## Conclusion

The dual-reward token economy creates a self-reinforcing system of incentives that rewards both the effort of content creation and the quality of content. By issuing new message rewards based on novelty and citation rewards based on impact, Choir establishes a sustainable economy where users are motivated to contribute valuable, unique information while also participating in the collaborative ownership of knowledge.
