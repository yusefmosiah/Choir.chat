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
# New Message Reward Program

VERSION new_message_reward_system:
invariants: {
"Fixed token allocation",
"Logarithmic decay",
"Distribution finality"
}
assumptions: {
"4 year timeline",
"2.5B token allocation",
"Time-based decay"
}
docs_version: "0.2.1"

## Program Account Structure

```rust
pub struct NewMessageRewardState {
    // Program state
    pub start_timestamp: i64,        // Program start time
    pub total_distributed: u64,      // Running total of distributed rewards
    pub remaining_tokens: u64,       // Tokens left to distribute
    pub decay_constant: f64,         // k ≈ 2.04 for target distribution

    // Distribution parameters
    pub base_reward: u64,           // Base reward amount
    pub total_allocation: u64,      // 2.5B tokens
    pub distribution_period: i64,    // 4 years in seconds
}
```

## Core Operations

```rust
FUNCTION calculate_reward(
    current_time: i64,
    message_volume: u32
) -> Result<u64> {
    // Calculate instantaneous reward rate using decay function
    let elapsed = current_time - state.start_timestamp;
    let rate = calculate_decay_rate(elapsed)?;

    // Adjust for message volume
    let reward = rate.checked_div(message_volume as u64)
        .ok_or(ErrorCode::DivisionError)?;

    // Verify against remaining allocation
    require!(reward <= state.remaining_tokens);

    Ok(reward)
}

FUNCTION distribute_reward(
    ctx: Context,
    message_hash: Hash,
    author: Pubkey
) -> Result<()> {
    // Verify message hasn't been rewarded
    require!(!message_already_rewarded(message_hash));

    // Calculate reward amount
    let reward = calculate_reward(
        Clock::get()?.unix_timestamp,
        get_current_message_volume()
    )?;

    // Transfer tokens
    transfer_tokens(ctx, reward, author)?;

    // Update state
    state.total_distributed += reward;
    state.remaining_tokens -= reward;

    Ok(())
}
```

## Distribution Function

The cumulative reward distribution follows:

```math
F(t) = R_total × ln(1 + k × t) / ln(1 + k × T)

Where:
- R_total = 2.5B tokens
- k ≈ 2.04 (decay constant)
- T = 4 years
- t = time since start
```

## Program Properties

1. **Distribution Schedule**

   - 50% distributed in year 1
   - 99% distributed by year 4
   - Smooth logarithmic decay
   - Volume-adjusted rewards

2. **Conservation Properties**

   - Total rewards ≤ 2.5B tokens
   - No double rewards
   - Atomic distribution
   - Verifiable allocation

3. **Security Properties**
   - Time-based decay
   - Volume adjustment
   - Reward finality
   - State consistency

## Error Handling

```rust
#[error_code]
pub enum RewardError {
    #[msg("Message already rewarded")]
    AlreadyRewarded,

    #[msg("Insufficient remaining allocation")]
    InsufficientAllocation,

    #[msg("Invalid time parameter")]
    InvalidTime,

    #[msg("Program ended")]
    ProgramEnded
}
```
