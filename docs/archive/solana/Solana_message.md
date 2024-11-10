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

# Message Account Management

VERSION message_system:
invariants: {
"Message immutability post-approval",
"Content hash integrity",
"Approval state consistency"
}
assumptions: {
"Account size limits",
"PDA derivation security",
"Rent exemption"
}
docs_version: "0.2.1"

## Message Account Structure

```rust
struct Message {
    // Content identification
    pub content_hash: [u8; 32],
    pub thread_id: String,
    pub author: Pubkey,

    // Timestamps
    pub created_at: i64,
    pub updated_at: i64,

    // State
    pub status: MessageStatus,
    pub approvals: Vec<Approval>,
    pub bump: u8,
}

struct SpecMessage {
    // Base message fields
    pub content_hash: [u8; 32],
    pub thread_id: String,
    pub author: Pubkey,
    pub created_at: i64,
    pub updated_at: i64,

    // Spec-specific fields
    pub stake_amount: u64,
    pub expires_at: i64,
    pub approvals: Vec<Approval>,
    pub bump: u8,
}

struct Approval {
    pub co_author: Pubkey,
    pub approved: bool,
    pub timestamp: i64,
}

enum MessageStatus {
    Pending,
    Approved,
    Rejected,
    Expired,
}
```

## Message Creation

```rust
FUNCTION create_message(
    ctx: Context,
    content_hash: [u8; 32],
    thread_id: String
) -> Result<()> {
    // Validate inputs
    require!(content_hash != [0; 32]);
    require!(thread_exists(thread_id));

    // Derive PDA
    let (pda, bump) = Pubkey::find_program_address(
        &[b"message", content_hash.as_ref()],
        ctx.program_id
    );

    // Initialize message account
    let message = &mut ctx.accounts.message;
    message.content_hash = content_hash;
    message.thread_id = thread_id;
    message.author = ctx.accounts.author.key();
    message.created_at = Clock::get()?.unix_timestamp;
    message.updated_at = message.created_at;
    message.status = MessageStatus::Pending;
    message.bump = bump;

    Ok(())
}
```

## Spec Message Creation

```rust
FUNCTION create_spec_message(
    ctx: Context,
    content_hash: [u8; 32],
    thread_id: String,
    stake_amount: u64
) -> Result<()> {
    // Validate inputs
    require!(stake_amount >= MINIMUM_STAKE);
    require!(!is_co_author(ctx.accounts.author.key(), thread_id));

    // Derive PDA and initialize account
    let (pda, bump) = Pubkey::find_program_address(
        &[b"spec", content_hash.as_ref()],
        ctx.program_id
    );

    // Initialize spec message
    let spec = &mut ctx.accounts.spec_message;
    spec.content_hash = content_hash;
    spec.thread_id = thread_id;
    spec.author = ctx.accounts.author.key();
    spec.created_at = Clock::get()?.unix_timestamp;
    spec.updated_at = spec.created_at;
    spec.stake_amount = stake_amount;
    spec.expires_at = spec.created_at + SPEC_TIMEOUT;
    spec.bump = bump;

    // Transfer stake to escrow
    transfer_stake_to_escrow(ctx, stake_amount)?;

    Ok(())
}
```

## Approval Processing

```rust
FUNCTION process_approval(
    ctx: Context,
    message_hash: [u8; 32],
    decision: bool
) -> Result<()> {
    let message = &mut ctx.accounts.message;
    let thread = &ctx.accounts.thread;

    // Validate
    require!(thread.co_authors.contains(&ctx.accounts.co_author.key()));
    require!(!has_voted(message, ctx.accounts.co_author.key()));
    require!(!is_expired(message));

    // Record approval
    let approval = Approval {
        co_author: ctx.accounts.co_author.key(),
        approved: decision,
        timestamp: Clock::get()?.unix_timestamp,
    };
    message.approvals.push(approval);

    // Check consensus
    if decision && all_approved(message, thread) {
        message.status = MessageStatus::Approved;
        process_approval_success(ctx)?;
    } else if !decision {
        message.status = MessageStatus::Rejected;
        process_approval_failure(ctx)?;
    }

    message.updated_at = Clock::get()?.unix_timestamp;
    Ok(())
}
```

## State Validation

```rust
FUNCTION validate_message_state(message: &Message) -> Result<()> {
    // Basic validation
    require!(message.content_hash != [0; 32]);
    require!(message.created_at > 0);
    require!(message.updated_at >= message.created_at);

    // Status-specific validation
    match message.status {
        MessageStatus::Approved => {
            require!(!message.approvals.is_empty());
            require!(all_approvals_valid(message));
        },
        MessageStatus::Rejected => {
            require!(has_rejection(message));
        },
        MessageStatus::Expired => {
            require!(is_expired(message));
        },
        MessageStatus::Pending => {
            require!(!is_expired(message));
        }
    }

    Ok(())
}
```

## Error Handling

```rust
#[error_code]
pub enum MessageError {
    #[msg("Invalid content hash")]
    InvalidContentHash,

    #[msg("Message already exists")]
    MessageExists,

    #[msg("Insufficient stake amount")]
    InsufficientStake,

    #[msg("Message expired")]
    MessageExpired,

    #[msg("Already voted")]
    AlreadyVoted,

    #[msg("Invalid approval state")]
    InvalidApprovalState
}
```

## Constants

```rust
pub const SPEC_TIMEOUT: i64 = 7 * 24 * 60 * 60; // 7 days in seconds
pub const MINIMUM_STAKE: u64 = 1_000;
pub const MAX_APPROVALS: usize = 10;
```
