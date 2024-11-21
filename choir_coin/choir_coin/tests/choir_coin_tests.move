#[test_only]
module choir::choir_tests {
    use sui::test_scenario;
    use sui::coin::{Self};
    use sui::test_utils::assert_eq;
    use choir::choir::{Self, TreasuryCapability};

    // Test constants
    const ADMIN: address = @0xAD;
    const USER1: address = @0x1;
    const USER2: address = @0x2;

    const ONE_CHOIR: u64 = 1_000_000_000; // 1 CHOIR with 9 decimals
    const MAX_SUPPLY: u64 = 10_000_000_000 * 1_000_000_000; // 10B CHOIR

    #[test]
    fun test_init_creates_treasury_cap() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            choir::test_init(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Verify treasury cap is owned by ADMIN
            assert!(
                test_scenario::has_most_recent_for_sender<TreasuryCapability>(&scenario),
                0
            );
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_mint_creates_coin() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            choir::test_init(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCapability>(
                &scenario
            );
            choir::mint(
                &mut treasury_cap,
                ONE_CHOIR,
                USER1,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_to_sender(&scenario, treasury_cap);
        };
        test_scenario::next_tx(&mut scenario, USER1);
        {
            let coin = test_scenario::take_from_sender<coin::Coin<choir::CHOIR>>(&scenario);
            assert_eq(coin::value(&coin), ONE_CHOIR);
            test_scenario::return_to_sender(&scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_total_supply_tracking() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            choir::test_init(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCapability>(
                &scenario
            );

            // First mint
            choir::mint(
                &mut treasury_cap,
                ONE_CHOIR,
                USER1,
                test_scenario::ctx(&mut scenario)
            );
            assert_eq(
                choir::total_minted(&treasury_cap),
                ONE_CHOIR
            );

            // Second mint
            choir::mint(
                &mut treasury_cap,
                ONE_CHOIR * 2,
                USER2,
                test_scenario::ctx(&mut scenario)
            );
            assert_eq(
                choir::total_minted(&treasury_cap),
                ONE_CHOIR * 3
            );

            test_scenario::return_to_sender(&scenario, treasury_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] //  choir_coin const EMINT_EXCEEDS_CAP: u64 = 0;
    fun test_mint_exceeds_max_supply() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            choir::test_init(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCapability>(
                &scenario
            );
            choir::mint(
                &mut treasury_cap,
                MAX_SUPPLY + 1,
                USER1,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_to_sender(&scenario, treasury_cap);
        };
        test_scenario::end(scenario);
    }
}
