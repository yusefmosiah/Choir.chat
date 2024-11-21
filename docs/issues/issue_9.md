# Message Rewards Implementation

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Implement message rewards using vector similarity for uniqueness calculation and prior citation value, distributed through a Python-controlled SUI wallet. This provides a foundation for testing token economics before implementing smart contracts.

## Tasks

### 1. SUI Wallet Controller
```python
class ChoirWallet:
    def __init__(self, network: str = "devnet"):
        self.client = SuiClient(network=network)
        self.base_reward = 100  # Base SUI reward amount
        self.base_prior_reward = 50  # Base citation reward

    async def calculate_uniqueness_reward(
        self,
        content: str,
        vector_db: QdrantClient
    ) -> float:
        # Get embedding
        embedding = await get_embedding(content)

        # Search for similar content
        similar = await vector_db.search(
            collection_name="messages",
            query_vector=embedding,
            limit=10
        )

        # 1.0 = unique, 0.0 = duplicate
        max_similarity = max(r.score for r in similar) if similar else 0.0
        uniqueness = 1.0 - max_similarity

        return self.base_reward * uniqueness

    async def distribute_rewards(
        self,
        message_content: str,
        author_address: str,
        cited_priors: List[Prior],
        vector_db: QdrantClient
    ):
        # Calculate and send new message reward
        reward = await self.calculate_uniqueness_reward(
            message_content,
            vector_db
        )
        await self.send_sui(author_address, reward)

        # Handle prior citation rewards
        for prior in cited_priors:
            if prior.quality_score > QUALITY_THRESHOLD:
                citation_reward = self.base_prior_reward * prior.quality_score
                await self.send_sui(prior.author_address, citation_reward)
```

### 2. Yield Phase Integration
```python
@router.post("/yield")
async def yield_phase(
    request: YieldRequest,
    choir_wallet: ChoirWallet = Depends(get_choir_wallet),
    vector_db: QdrantClient = Depends(get_vector_db)
):
    # Process yield response
    response = await process_yield(request)

    # Only distribute rewards if message is approved
    if response.approved:
        await choir_wallet.distribute_rewards(
            message_content=request.content,
            author_address=request.author_address,
            cited_priors=response.citations,
            vector_db=vector_db
        )

    return response
```

### 3. Monitoring & Analytics
```python
class RewardMetrics:
    async def log_distribution(
        self,
        message_id: str,
        author_reward: float,
        prior_rewards: Dict[str, float],
        uniqueness_score: float
    ):
        # Log reward distribution for analysis
        # This data will inform smart contract design
        pass

    async def analyze_distribution_patterns(self):
        # Analyze reward patterns to tune parameters
        # Track semantic clustering effects
        # Monitor economic effects
        pass
```

## Success Criteria
- Rewards scale properly with semantic uniqueness
- Prior citations receive appropriate value
- Distribution transactions complete reliably
- System maintains economic stability
- Clear metrics for tuning parameters

## Future Evolution
- Migration path to smart contracts
- Enhanced economic models
- Community governance of parameters
- Integration with thread contracts
- Advanced citation value calculations

## Notes
- Start with conservative base reward values
- Monitor distribution patterns closely
- Gather data for smart contract design
- Focus on semantic value creation
- Build community through fair distribution
