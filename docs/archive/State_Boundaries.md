# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# State Distribution Across Systems

VERSION state_boundaries:
invariants: {
"Clear ownership of state",
"Consistent data flow",
"Verifiable boundaries"
}
assumptions: {
"System availability",
"Network reliability",
"Cache coherence"
}
docs_version: "0.2.1"

## 1. Solana State (Source of Truth for Ownership)

TYPE SolanaState = {
thread: {
co_authors: Set<PublicKey>, // Thread ownership
token_balance: u64, // Thread value
content_hashes: Set<Hash>, // Content verification
created_at: i64 // Thread timestamp
},

approvals: {
pending: Map<Hash, Set<PublicKey>>, // Active votes
decisions: Map<Hash, Decision>, // Final outcomes
expiry: Map<Hash, i64> // Timeout tracking
},

tokens: {
stakes: Map<Hash, TokenAmount>, // Locked stakes
thread_balances: Map<ThreadId, TokenAmount>, // Thread energy
treasury: {
balance: TokenAmount, // Treasury reserve
citation_rewards: TokenAmount, // Allocated for citations
new_message_rewards: TokenAmount // Decaying reward pool
}
}
}

## 2. Qdrant State (Source of Truth for Content)

TYPE QdrantState = {
content: {
messages: Map<Hash, String>, // Raw content
embeddings: Map<Hash, Vector>, // Semantic vectors
metadata: Map<Hash, Metadata> // Content properties
},

indices: {
semantic: VectorIndex, // Similarity search
temporal: TimeIndex, // Time-based access
author: AuthorIndex // Creator lookup
},

search: {
filters: Set<Filter>, // Access control
rankings: Map<Hash, Score>, // Relevance scores
cache: Map<Query, Results> // Search optimization
}
}

## 3. Backend State (Session and Cache Management)

TYPE BackendState = {
session: {
connections: Map<ClientId, WebSocket>, // Active clients
subscriptions: Map<ThreadId, Set<ClientId>>, // Room membership
heartbeats: Map<ClientId, Timestamp> // Connection health
},

cache: {
threads: Map<ThreadId, ThreadCache>, // Hot thread data
messages: Map<Hash, MessageCache>, // Recent messages
users: Map<PublicKey, UserCache> // Active user data
},

websocket: {
rooms: Map<ThreadId, Room>, // Chat rooms
events: Queue<Event>, // Message queue
state: Map<ClientId, ClientState> // Connection state
}
}

## 4. Frontend State (UI and Optimistic Updates)

TYPE FrontendState = {
ui: {
threads: Map<ThreadId, ThreadUI>, // Thread display
messages: Map<Hash, MessageUI>, // Message display
notifications: Queue<Notification> // User alerts
},

optimistic: {
pending: Map<Hash, OptimisticUpdate>, // Unconfirmed changes
rollbacks: Map<Hash, RollbackState>, // Recovery data
conflicts: Set<StateConflict> // Sync issues
},

local: {
wallet: WalletState, // Connection state
preferences: UserPreferences, // Settings
drafts: Map<ThreadId, Draft> // Unsent messages
}
}

## State Flow Patterns

1. **Ownership Flow**

   ```
   Solana -> Backend -> Frontend
   PROPERTY: ownership_flow
     solana.thread.co_authors = backend.cache.thread.co_authors
     backend.cache.thread.co_authors = frontend.ui.thread.co_authors
   ```

2. **Content Flow**

   ```
   Frontend -> Backend -> Qdrant
   PROPERTY: content_flow
     frontend.messages[hash].content = backend.cache.messages[hash].content
     backend.cache.messages[hash].content = qdrant.content.messages[hash]
   ```

3. **Token Flow**
   ```
   Solana -> Backend -> Frontend
   PROPERTY: token_flow
     solana.tokens.balances = backend.cache.tokens
     backend.cache.tokens = frontend.ui.balances
   ```

## Token Flow Boundaries

0. **Approval Flow**

   ```
      Stake -> Approvers
   PROPERTY: approval_flow
     // Direct distribution to approvers
     FOR approver IN approvers:
       approver.balance += stake_amount / approvers.len()
     verify_temperature_decrease()
     verify_frequency_increase()
   ```

1. **Rejection Flow**

   ```
      Stake -> Thread Balance
   PROPERTY: rejection_flow
     thread.token_balance += stake_amount
     verify_thread_temperature_update()
   ```

2. **Split Decision Flow**

   ```
      Stake -> {Treasury, Thread}
   PROPERTY: split_decision_flow
     approver_share = (stake * approver_count) / total_voters
     denier_share = stake - approver_share

     treasury.balance += approver_share  // Approvers' share to Treasury
     thread.token_balance += denier_share  // Deniers' share to thread
     verify_energy_conservation()
   ```

3. **New Message Rewards**

   ```
   Treasury -> Authors
   PROPERTY: reward_flow
     // Logarithmic decay over 4 years
     reward = calculate_decaying_reward(time)
     verify_reward_distribution()
   ```

4. **Citation Rewards**
   ```
      Treasury -> Thread
   PROPERTY: prior_reward_flow
     // Quality-weighted thread rewards
     reward = calculate_prior_reward(quality_score, treasury_state)
     thread.token_balance += reward
     verify_thread_resonance_increase()
   ```

## Boundary Enforcement

1. **State Authority**

   ```
   RULE state_ownership:
     ownership_changes MUST originate from Solana
     content_changes MUST flow through Qdrant
     session_state MUST be managed by Backend
     ui_state MUST be managed by Frontend
   ```

2. **Update Propagation**

   ```
   SEQUENCE state_update:
     1. Update authoritative source
     2. Await confirmation
     3. Propagate to dependent systems
     4. Verify consistency
   ```

3. **Conflict Resolution**
   ```
   FUNCTION resolve_conflict(conflict: StateConflict):
     MATCH conflict:
       OwnershipConflict -> use_solana_state()
       ContentConflict -> use_qdrant_state()
       CacheConflict -> rebuild_cache()
       UIConflict -> refresh_frontend()
   ```

## Monitoring and Verification

1. **Health Checks**

   ```
   FUNCTION verify_boundaries():
     check_solana_consistency()
     verify_qdrant_integrity()
     validate_cache_coherence()
     confirm_ui_state()
   ```

2. **Metrics Collection**
   ```
   MEASURE boundary_health:
     state_sync_delay
     propagation_time
     conflict_rate
     recovery_success
   ```
