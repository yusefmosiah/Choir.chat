# Integration of Thread Contract and PostChain Temporal Model

## Overview

Choir's architecture integrates two powerful conceptual frameworks:

1. **The PostChain Temporal Model**: A sequential processing framework where each phase has a specific temporal relationship to information
2. **The Thread Contract Model**: An economic framework for thread ownership, discovery, and contribution

This document explores how these models complement each other and integrate in the Choir architecture to create a coherent system.

## Conceptual Alignment

The PostChain and Thread Contract align at a fundamental level:

| PostChain Aspect        | Thread Contract Aspect    | Integration Point                               |
| ----------------------- | ------------------------- | ----------------------------------------------- |
| Temporal progression    | Thread lifecycle          | Phases operate within thread context            |
| Information persistence | Citable content           | Observation creates discoverable assets         |
| Recursive refinement    | Collaborative improvement | Yield can trigger contribution opportunities    |
| Contextual awareness    | Citation network          | Understanding prunes while preserving citations |
| Experience retrieval    | New message novelty       | Experience phase calculates message rewards     |

## Temporal Flow and Economic Flow

### PostChain: Temporal Information Flow

The PostChain's temporal focus at each phase:

- **Action**: Immediate present (processing)
- **Experience**: Past knowledge (retrieval and novelty assessment)
- **Intention**: Desired future (goal alignment)
- **Observation**: Future preservation (memory persistence)
- **Understanding**: Temporal integration (context filtering)
- **Yield**: Process completion (recursion decisions and reward distribution)

### Thread Contract: Economic Value Flow

The Thread Contract's economic flow:

- **Creation**: Establishing value potential
- **Message Novelty**: Rewarding new information contribution
- **Citation**: Recognition of value through reference
- **Discovery**: Value propagation through visibility
- **Contribution**: Value enhancement through investment
- **Co-ownership**: Value sharing through governance

## Token Economy Integration

The token economy integrates with the PostChain through two primary reward mechanisms:

1. **New Message Reward**: Calculated in the Experience phase based on message novelty
2. **Citation Reward**: Calculated in the Yield phase based on citation impact

These mechanisms create a complete economic cycle where:

- Users earn tokens by contributing novel messages
- Users spend tokens to contribute to valuable threads
- Thread owners earn tokens when their content is cited

## Integration Points

### 1. Experience Phase and Novelty Assessment

The Experience phase now performs two related functions:

- Retrieving relevant information from knowledge sources
- Assessing message novelty to calculate message rewards

```python
async def process_experience(
    content: Dict,
    context: List[Message]
) -> ExperienceResult:
    """Process the Experience phase with novelty assessment and reward calculation."""
    # Retrieve relevant information
    retrieved_info = await retrieve_relevant_information(content, context)

    # For user messages, calculate novelty and reward
    message_reward = None
    if is_user_message(context[-1]):
        # Generate embedding for the message
        message_embedding = await embedding_service.embed(context[-1].content)

        # Retrieve semantically similar content
        similar_content = await vector_db.similarity_search(
            message_embedding,
            top_k=5,
            min_relevance=0.6
        )

        # Calculate novelty score (inverse of similarity)
        novelty_score = calculate_novelty_score(similar_content)

        # Calculate reward based on novelty
        message_reward = await token_service.calculate_message_reward(
            user_id=context[-1].user_id,
            message_id=context[-1].id,
            novelty_score=novelty_score
        )

    return ExperienceResult(
        content={
            "original_content": content,
            "retrieved_information": retrieved_info
        },
        metadata={
            "message_reward": message_reward._asdict() if message_reward else None,
            "retrieval_stats": {
                "sources_retrieved": len(retrieved_info)
            }
        }
    )
```

### 2. Observation Phase and Thread Linking

The Observation phase creates links between threads based on citations:

```python
async def process_thread_links(citations: List[Citation]) -> ObservationResult:
    """Create thread links based on citations and record in knowledge graph."""
    thread_links = []

    for citation in citations:
        # Create thread-to-thread link
        link = await thread_linker.link(
            source_thread_id=citation.source_thread_id,
            target_thread_id=citation.target_thread_id,
            relationship_type="cites",
            metadata={
                "citation_id": citation.id,
                "relevance": citation.relevance_score
            }
        )
        thread_links.append(link)

        # Record in knowledge graph for discovery
        await knowledge_graph.add_relationship(
            source_type="thread",
            source_id=citation.source_thread_id,
            relationship="cites",
            target_type="thread",
            target_id=citation.target_thread_id,
            properties={
                "citation_id": citation.id,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

    return ObservationResult(
        content={
            "thread_links": thread_links
        },
        metadata={
            "link_count": len(thread_links)
        }
    )
```

### 3. Understanding Phase and Citation Preservation

The Understanding phase preserves citation metadata during context pruning:

```python
async def prune_with_citation_preservation(
    context: List[Message]
) -> UnderstandingResult:
    """Prune context while preserving citation information."""
    operations = []

    for message in context:
        # Skip most recent messages
        if is_recent_message(message):
            continue

        # Always preserve citation metadata
        citations = extract_citations(message)
        if citations:
            # If message has citations but is lengthy, summarize while preserving citations
            if len(message.content) > 1000:
                operations.append({
                    "operation": "TRANSFORM",
                    "target": message.id,
                    "data": {
                        "transformation": "summarize_preserve_citations",
                        "parameters": {
                            "max_length": 200,
                            "citations": citations
                        }
                    }
                })
            else:
                # Preserve citation messages even if otherwise low relevance
                operations.append({
                    "operation": "PRIORITIZE",
                    "target": message.id,
                    "data": {
                        "priority": 0.8  # Higher priority to ensure retention
                    },
                    "metadata": {
                        "reason": "contains_citations"
                    }
                })
        elif calculate_relevance(message) < 0.4:
            # Low relevance non-citation message
            operations.append({
                "operation": "PRUNE",
                "target": message.id,
                "data": {"reason": "low_relevance"}
            })

    return UnderstandingResult(
        content={
            "context_operations": operations
        },
        metadata={
            "preserved_citation_count": count_preserved_citations(operations)
        }
    )
```

### 4. Yield Phase and Dual Reward Distribution

The Yield phase now handles both reward types:

```python
async def process_rewards(
    citations: List[Citation],
    final_response: str,
    context: List[Message]
) -> YieldResult:
    """Process both message and citation rewards in the Yield phase."""
    rewards = {
        "citation_rewards": [],
        "message_rewards": []
    }

    # Process citation rewards
    for citation in citations:
        # Check if citation was actually used in final response
        citation_impact = calculate_citation_impact(citation, final_response)

        if citation_impact > 0:
            # Calculate reward based on impact
            reward_amount = CONFIG.CITATION_BASE_REWARD * citation_impact

            # Distribute reward to thread (not individual)
            reward = await thread_contract.distribute_rewards(
                thread_id=citation.target_thread_id,
                reward_amount=reward_amount,
                reward_type="citation"
            )

            rewards["citation_rewards"].append({
                "citation_id": citation.id,
                "thread_id": citation.target_thread_id,
                "reward_amount": reward_amount,
                "impact_score": citation_impact
            })

    # Acknowledge message rewards (calculated in Experience phase)
    for message in context:
        if hasattr(message, "metadata") and message.metadata.get("message_reward"):
            rewards["message_rewards"].append(message.metadata["message_reward"])

    return YieldResult(
        content={
            "final_response": final_response,
            "rewards": rewards
        },
        metadata={
            "total_citation_rewards": sum(r["reward_amount"] for r in rewards["citation_rewards"]),
            "total_message_rewards": sum(r["amount"] for r in rewards["message_rewards"])
        }
    )
```

### 5. Action Phase and Contribution Opportunities

The Action phase presents contribution opportunities based on token balances:

```python
async def present_contribution_opportunities(
    context: List[Message]
) -> ActionResult:
    """Present opportunities to contribute to threads cited in the conversation."""
    # Extract threads cited in the conversation
    cited_threads = extract_cited_threads(context)

    # Get user token balance
    user_id = extract_user_id(context)
    token_balance = await token_service.get_balance(user_id, "user")

    # Only show opportunities if user has sufficient tokens
    contribution_opportunities = []
    if token_balance.available_amount > CONFIG.MIN_CONTRIBUTION_AMOUNT:
        for thread in cited_threads:
            ownership = await thread_contract.get_ownership_shares(thread.id)
            if user_id not in [o.owner_id for o in ownership]:
                # User doesn't own this thread, present as opportunity
                thread_summary = await thread_summarizer.summarize(thread.id)
                contribution_cost = await thread_contract.calculate_min_contribution(thread.id)

                # Only include threads with affordable contribution cost
                if contribution_cost <= token_balance.available_amount:
                    contribution_opportunities.append({
                        "thread_id": thread.id,
                        "thread_summary": thread_summary,
                        "min_token_contribution": contribution_cost,
                        "current_owners": len(ownership)
                    })

    # Format opportunities for presentation
    if contribution_opportunities:
        opportunities_message = format_contribution_opportunities(contribution_opportunities)

        return ActionResult(
            content={
                "message": "I noticed you've engaged with some interesting threads.",
                "contribution_opportunities": opportunities_message,
                "token_balance": token_balance.available_amount
            },
            metadata={
                "opportunity_count": len(contribution_opportunities)
            }
        )
    else:
        return ActionResult(
            content={
                "message": "Let me help you with that."
            },
            metadata={}
        )
```

## Complete Economic Loop

The integration of the PostChain and Thread Contract creates a complete economic loop:

1. **Input Value**:

   - User contributes a message
   - Experience phase assesses novelty
   - User receives tokens based on message novelty

2. **Knowledge Storage**:

   - Observation phase records connections
   - Content becomes discoverable through citations

3. **Output Value**:

   - Other threads cite valuable content
   - Yield phase calculates citation impact
   - Thread owners receive tokens based on citation value

4. **Reinvestment**:
   - Users spend earned tokens to contribute to threads
   - Approved contributions convert to ownership shares
   - New thread co-owners receive future citation rewards

## Architectural Benefits

The integration of these models provides several key benefits:

1. **Aligned Incentives**: Economic incentives align with quality information processing
2. **Self-reinforcing Discovery**: Citations both reward and drive discovery
3. **Shared Context Preservation**: Important information persists through economic incentives
4. **Value Creation Through Processing**: PostChain processing enhances thread value
5. **Novelty Premium**: Higher rewards for truly novel contributions prevent redundancy

## Implementation Approach

To implement this integrated model:

1. **Phase-specific Integration Points**: Each phase implements specific hooks for token economy
2. **Citation Tracking Service**: Cross-cutting service for tracking citations
3. **Reward Distribution Service**: Coordinates reward calculations across phases
4. **Thread Linking Service**: Integrates with Observation for discovery networks
5. **Novelty Assessment Service**: Calculates message novelty in Experience phase

## Cross-Cutting Concerns

Several concerns span both models:

1. **Authentication and Authorization**: Who can access threads and contribute?
2. **Privacy**: How to handle citations to private threads?
3. **Scalability**: How to handle reward distribution at scale?
4. **Versioning**: How to manage thread content changes and citations over time?
5. **Economic Balance**: How to maintain token value and prevent inflation?

## Conclusion

The integration of the PostChain's temporal information processing model with the dual-reward token economy creates a uniquely powerful architecture. By rewarding both input effort (message novelty) and output quality (citation impact), Choir creates aligned incentives at each stage of the information lifecycle. This enables Choir to function as a knowledge economy with self-reinforcing value creation and sustainable growth.
