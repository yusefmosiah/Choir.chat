module choir::choir {
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::object::{Self, UID};
    use std::option;

    /// One-time witness type for coin initialization
    public struct CHOIR has drop {}

    /// Treasury capability with supply tracking
    public struct TreasuryCapability has key, store {
        id: UID,
        cap: TreasuryCap<CHOIR>,
        total_minted: u64
    }

    /// Maximum supply constant: 10B tokens with 9 decimals
    const MAX_SUPPLY: u64 = 10_000_000_000 * 1_000_000_000;

    /// Error codes
    const EMINT_EXCEEDS_CAP: u64 = 0;

    fun init(witness: CHOIR, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9, // decimals
            b"CHOIR",
            b"Choir",
            b"Token for collective intelligence",
            option::none(),
            ctx
        );

        // Create treasury capability with supply tracking
        let cap = TreasuryCapability {
            id: object::new(ctx),
            cap: treasury_cap,
            total_minted: 0
        };

        // Transfer capability to deployer
        transfer::transfer(cap, tx_context::sender(ctx));
        // Freeze metadata
        transfer::public_freeze_object(metadata);
    }

    /// Mint new tokens, enforcing the 10B supply cap
    public fun mint(
        treasury: &mut TreasuryCapability,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // Check if mint would exceed cap
        assert!(
            treasury.total_minted + amount <= MAX_SUPPLY,
            EMINT_EXCEEDS_CAP
        );

        // Update total supply
        treasury.total_minted = treasury.total_minted + amount;

        // Mint and transfer coins
        let coins = coin::mint(&mut treasury.cap, amount, ctx);
        transfer::public_transfer(coins, recipient);
    }

    /// View total minted supply
    public fun total_minted(treasury: &TreasuryCapability): u64 {
        treasury.total_minted
    }

    // ======= Test-only functions =======
    // not deployed to the devnet

    #[test_only]
    /// Test-only initialization function that creates a new instance of the currency
    /// This is needed because the real init() can only be called once during publishing
    public fun test_init(ctx: &mut TxContext) {
        init(CHOIR {}, ctx)
    }
}
