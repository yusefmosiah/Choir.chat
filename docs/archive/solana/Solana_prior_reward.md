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
# Prior Reward Program (Thread-Centric)

VERSION prior_reward_system:
invariants: {
"Treasury funding",
"Message verification",
"Thread resonance"
}
assumptions: {
"Treasury inflow",
"Public messages only",
"Thread-based rewards"
}
docs_version: "0.2.1"

## Program Account Structure

```rust
pub struct PriorRewardState {
    // Program state
    pub treasury: Account<TokenAccount>,
    pub total_distributed: u64,
    pub current_period: u32,

    // Distribution parameters
    pub base_reward: u64,
    pub reward_cap: u64,      // Maximum reward per prior
    pub cooldown_period: i64  // Minimum time between rewards for same prior
}

pub struct PriorRecord {
    pub message_hash: Hash,     // Hash of the referenced message
    pub source_thread: String,  // Thread containing the prior
    pub last_reward: i64,      // Last reward timestamp
    pub total_rewards: u64      // Total rewards given for this prior
}
```

## Core Operations

```rust
FUNCTION process_prior_reward(
    ctx: Context,
    prior_hash: Hash,
    source_thread_id: String,
    quality_score: f64,  // Provided by backend
    target_thread: Account<Thread>  // Thread receiving the reward
) -> Result<()> {
    // Verify prior exists in source thread
    let source_thread = get_thread_account(source_thread_id)?;
    require!(source_thread.messages.contains(&prior_hash));

    // Verify message is public
    require!(is_message_public(prior_hash, source_thread_id)?);

    // Check cooldown period
    let prior_record = get_prior_record(prior_hash)?;
    require!(
        Clock::get()?.unix_timestamp - prior_record.last_reward
        >= state.cooldown_period
    );

    // Calculate reward
    let reward = calculate_reward(
        quality_score,
        ctx.accounts.treasury.amount
    )?;

    // Transfer from treasury to target thread
    transfer_from_treasury(ctx, reward, target_thread.key())?;

    // Update state
    update_prior_record(prior_hash, reward)?;
    state.total_distributed += reward;

    Ok(())
}
```

## Security Properties

1. **Message Verification**

   ```rust
   PROPERTY message_verification:
     FORALL reward IN prior_rewards:
       exists_in_thread(reward.prior_hash) AND
       is_public_message(reward.prior_hash) AND
       cooldown_respected(reward.prior_hash)
   ```

2. **Thread Resonance**
   ```rust
   PROPERTY thread_resonance:
     FORALL distribution IN distributions:
       increases_thread_energy(distribution) AND
       maintains_phase_coherence(distribution) AND
       strengthens_resonant_cavity(distribution)
   ```

## Error Handling

```rust
#[error_code]
pub enum PriorRewardError {
    #[msg("Prior not found in thread")]
    PriorNotFound,

    #[msg("Message not public")]
    NotPublicMessage,

    #[msg("Cooldown period not elapsed")]
    CooldownActive,

    #[msg("Invalid thread account")]
    InvalidThread
}
```

## Implementation Notes

Key aspects:

1. Rewards flow to threads, not individual authors
2. Strengthens thread as resonant cavity
3. Creates collective value accumulation
4. Maintains quantum harmonic properties
5. Scales rewards based on treasury balance
6. Enforces cooldown periods between rewards

The backend still calculates quality scores, but rewards accumulate in thread token balances, strengthening the thread-centric model.
