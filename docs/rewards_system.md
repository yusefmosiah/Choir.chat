# Choir Rewards System

## Overview

The Choir rewards system incentivizes users to contribute novel prompts and cite valuable information. The system issues CHOIR tokens on the Sui blockchain as rewards for these contributions.

## Reward Types

### 1. Novelty Rewards

Novelty rewards are issued when a user submits a prompt that is semantically different from existing content in the vector database.

- **Calculation**: Novelty is calculated as `1 - max_similarity`, where `max_similarity` is the highest similarity score between the user's prompt and existing vectors.
- **Issuance**: Rewards are issued during the Experience Vectors phase.
- **Amount**: 0.01 to 100.0 CHOIR tokens, scaled exponentially based on the novelty score.

### 2. Citation Rewards

Citation rewards are issued when a user cites vector search results in their conversation.

- **Calculation**: 0.5 CHOIR tokens per citation, up to a maximum of 5 citations.
- **Issuance**: Rewards are issued during the Yield phase.
- **Detection**: Citations are detected using the `#ID` syntax in the model's response.

## Technical Implementation

### Backend (Python)

#### Novelty Rewards Pipeline

1. **Vector Embedding**: User prompts are embedded using an embedding model.
2. **Similarity Search**: The embeddings are compared against existing vectors in the database.
3. **Reward Calculation**: Novelty score is calculated as `1 - max_similarity`.
4. **Reward Issuance**: If the novelty score is high enough, CHOIR tokens are minted to the user's wallet.
5. **Response Enrichment**: Reward information is included in the API response and passed to the LLM.

```python
# Calculate and issue novelty reward
if wallet_address and max_similarity is not None:
    rewards_service = RewardsService()
    reward_result = await rewards_service.issue_novelty_reward(wallet_address, max_similarity)
    novelty_reward = reward_result
```

#### Citation Rewards Pipeline

1. **Citation Detection**: The LLM's response is analyzed to detect citations using the `#ID` syntax.
2. **Reward Calculation**: 0.5 CHOIR tokens per citation, up to 5 citations.
3. **Reward Issuance**: CHOIR tokens are minted to the user's wallet.

```python
# Extract citations and issue rewards
if wallet_address and response.content:
    rewards_service = RewardsService()
    citations = rewards_service.extract_citations(response.content)
    if citations:
        reward_result = await rewards_service.issue_citation_rewards(wallet_address, len(citations))
        citation_reward = reward_result
```

### Frontend (Swift)

#### Reward Display

1. **API Integration**: The Swift client receives reward information in the API response.
2. **UI Display**: Reward information is displayed in the phase card UI.
3. **Alerts**: Successful rewards trigger alert notifications.

```swift
// Process reward information from a phase response
func processPhaseResponse(phase: String, response: [String: Any]) {
    if phase == "experience_vectors", let noveltyRewardDict = response["novelty_reward"] as? [String: Any] {
        let reward = try JSONDecoder().decode(RewardInfo.self, from: jsonData)
        processReward(rewardInfo: reward)
    }
}
```

## LLM Integration

The LLM is instructed to include reward information in its responses:

1. **Novelty Rewards**: The LLM receives information about novelty rewards and includes it in the Experience Vectors phase response.
2. **Citation Rewards**: The LLM is instructed to use the `#ID` syntax when referencing vector search results, which triggers citation rewards.

## Memory System Integration

The rewards system is deeply integrated with Choir's memory system:

1. **Global Memory**: Vector embeddings form a global memory that all users can access.
2. **Per-User Memory**: Each user's wallet has its own collection of threads and rewards.
3. **Per-Thread Memory**: Each thread maintains its own context and citation history.

In the future, this memory system will evolve into hypergraphs of conceptual interrelations, allowing for more sophisticated reward mechanisms based on the value and interconnectedness of contributions.

## Blockchain Integration

Rewards are issued as CHOIR tokens on the Sui blockchain:

1. **Minting**: The `mint_choir` function in `sui_service.py` mints CHOIR tokens to the user's wallet.
2. **Verification**: Transactions are verified on the Sui blockchain.
3. **Balance**: Users can view their CHOIR token balance in the app.

```python
async def mint_choir(self, recipient_address: str, amount: int = 1_000_000_000):
    """Mint CHOIR tokens to recipient (default 1 CHOIR)"""
    txn = SuiTransaction(client=self.client)
    txn.move_call(
        target=f"{self.package_id}::choir::mint",
        arguments=[
            ObjectID(self.treasury_cap_id),
            SuiU64(amount),
            SuiAddress(recipient_address)
        ],
        type_arguments=[]
    )
    result = txn.execute()
    # Process result...
```

## Future Enhancements

1. **Reward Visualization**: Enhanced visualizations of rewards in the UI.
2. **Reward History**: A dedicated view for users to see their reward history.
3. **Community Rewards**: Rewards for community contributions and collaborations.
4. **Conceptual Hypergraphs**: Evolution of the memory system to support more sophisticated reward mechanisms.
