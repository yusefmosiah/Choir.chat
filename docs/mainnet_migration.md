# Choir Mainnet Migration Guide

This document outlines the process for migrating the Choir application from devnet to mainnet. It covers all aspects of the migration, including contract deployment, API configuration, client updates, and testing procedures.

## Table of Contents

1. [Migration Overview](#migration-overview)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Contract Deployment](#contract-deployment)
4. [API Configuration](#api-configuration)
5. [Client Configuration](#client-configuration)
6. [Testing Procedures](#testing-procedures)
7. [Rollout Strategy](#rollout-strategy)
8. [Rollback Plan](#rollback-plan)
9. [Post-Migration Monitoring](#post-migration-monitoring)

## Migration Overview

The migration from devnet to mainnet involves several key steps:

1. Deploying the Choir token contract to Sui mainnet
2. Updating API configurations to support both devnet and mainnet
3. Updating client configurations to use the mainnet contract
4. Testing the end-to-end flow on mainnet
5. Gradually rolling out to users

This process requires careful coordination and thorough testing to ensure a smooth transition.

## Pre-Migration Checklist

Before beginning the migration, ensure:

- [ ] All devnet features are stable and working correctly
- [ ] Contract code has been audited and reviewed
- [ ] Sufficient SUI tokens are available for mainnet deployment
- [ ] Backup of all private keys and mnemonics
- [ ] Team members are assigned specific migration tasks
- [ ] Rollback plan is in place
- [ ] Monitoring tools are set up
- [ ] Communication plan for users is prepared

## Contract Deployment

### 1. Prepare the Deployment Wallet

```bash
# Switch to mainnet
sui client switch --env mainnet

# Verify active address
sui client active-address

# Check gas balance
sui client gas
```

Ensure the deployment wallet has at least 5 SUI for gas fees and is properly secured.

### 2. Deploy the Contract

```bash
# Navigate to contract directory
cd choir_coin/choir_coin

# Build the contract
sui move build

# Publish to mainnet
sui client publish --gas-budget 100000000
```

### 3. Record Contract IDs

From the deployment output, record:

- Package ID: `0x...`
- Treasury Cap ID: `0x...`

Store these values securely as they will be needed for API and client configuration.

### 4. Initial Token Minting

Mint an initial supply of tokens to the treasury wallet:

```bash
sui client call --package <MAINNET_PACKAGE_ID> --module choir --function mint --args <MAINNET_TREASURY_CAP_ID> 1000000000000 <TREASURY_WALLET_ADDRESS> --gas-budget 10000000
```

This mints 1,000 CHOIR tokens (with 9 decimals) to the treasury wallet.

## API Configuration

### 1. Update SUI Service

Modify `api/app/services/sui_service.py` to support both environments:

```python
def __init__(self, network=None):
    # Initialize network from parameter or environment variable
    self.network = network or os.getenv("SUI_NETWORK", "devnet")
    
    # Configure RPC client based on network
    if self.network == "mainnet":
        self.client = SuiClient(config=ClientConfig(url="https://fullnode.mainnet.sui.io"))
        self.package_id = "0x..." # Mainnet package ID
        self.treasury_cap_id = "0x..." # Mainnet treasury cap ID
        logger.info(f"Initialized SuiService for mainnet")
    else:
        self.client = SuiClient(config=ClientConfig(url="https://fullnode.devnet.sui.io"))
        self.package_id = "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a"
        self.treasury_cap_id = "0x6eab9c65acf9b4001199ac98813951140417b5feff8a85218eddd14a62d14f37"
        logger.info(f"Initialized SuiService for devnet")
```

### 2. Update Config Module

Modify `api/app/config.py` to include network configuration:

```python
class Config:
    # Existing configuration...
    
    # SUI network configuration
    SUI_NETWORK: str = os.getenv("SUI_NETWORK", "devnet")
    
    @classmethod
    def from_env(cls):
        # Existing code...
        network = os.getenv("SUI_NETWORK", "devnet")
        return cls(
            # Existing parameters...
            network=network,
        )
```

### 3. Update Deployment Configuration

Create environment-specific deployment configurations:

```bash
# For devnet
export SUI_NETWORK=devnet

# For mainnet
export SUI_NETWORK=mainnet
```

## Client Configuration

### 1. Update CoinType.swift

Modify `Choir/Models/CoinType.swift` to support both environments:

```swift
#if DEBUG
// Devnet configuration
static let choir = CoinType(
    coinTypeIdentifier: "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a::choir::CHOIR",
    name: "Choir",
    symbol: "CHOIR",
    decimals: 9,
    iconName: "choir-logo"
)
#else
// Mainnet configuration
static let choir = CoinType(
    coinTypeIdentifier: "0x<MAINNET_PACKAGE_ID>::choir::CHOIR",
    name: "Choir",
    symbol: "CHOIR",
    decimals: 9,
    iconName: "choir-logo"
)
#endif
```

### 2. Update WalletManager.swift

Ensure the `WalletManager` uses the correct network connection:

```swift
init() {
    #if DEBUG
    print("Using devnet connection")
    restClient = SuiProvider(connection: DevnetConnection())
    faucetClient = FaucetClient(connection: DevnetConnection())
    #else
    print("Using mainnet connection")
    restClient = SuiProvider(connection: MainnetConnection())
    faucetClient = FaucetClient(connection: MainnetConnection())
    #endif
    
    // Load all wallets
    Task {
        await loadAllWallets()
    }
}
```

### 3. Update API Configuration

Modify `Choir/Networking/APIClient.swift` to use the correct API endpoints:

```swift
#if DEBUG
static let baseURL = URL(string: "https://api-dev.choir.io")!
#else
static let baseURL = URL(string: "https://api.choir.io")!
#endif
```

## Testing Procedures

### 1. API Testing

Test the API with mainnet configuration:

```bash
# Set environment to mainnet
export SUI_NETWORK=mainnet

# Activate virtual environment
cd api
source venv/bin/activate

# Run notification test
python ../scripts/test_notifications.py
```

### 2. End-to-End Testing

Perform these tests on the mainnet configuration:

1. **Authentication**: Test wallet authentication with mainnet wallets
2. **Wallet Balance**: Verify correct display of mainnet CHOIR tokens
3. **Sending Tokens**: Test sending CHOIR tokens between wallets
4. **Citation Rewards**: Test the citation reward flow
5. **Notifications**: Verify citation notifications are received

### 3. Performance Testing

Test the performance of mainnet transactions:

1. **Transaction Speed**: Measure transaction confirmation times
2. **API Response Time**: Measure API response times with mainnet configuration
3. **Load Testing**: Simulate multiple concurrent users

## Rollout Strategy

### 1. Phased Approach

1. **Internal Testing**: Deploy to mainnet and test with internal team (1 week)
2. **Beta Testers**: Invite select users to test mainnet version (2 weeks)
3. **Gradual Rollout**: Roll out to 10%, 25%, 50%, then 100% of users

### 2. Feature Flags

Implement feature flags to control access to mainnet features:

```swift
// Example feature flag implementation
let useMainnet = UserDefaults.standard.bool(forKey: "useMainnet") || isInBetaGroup
```

### 3. Communication Plan

1. **Pre-Migration**: Inform users about upcoming migration
2. **During Migration**: Provide status updates
3. **Post-Migration**: Announce completion and new features

## Rollback Plan

In case of critical issues:

### 1. API Rollback

```bash
# Switch API back to devnet
export SUI_NETWORK=devnet
```

### 2. Client Rollback

Release an emergency update reverting to devnet configuration.

### 3. Data Recovery

If necessary, implement a plan to reconcile any data discrepancies between devnet and mainnet.

## Post-Migration Monitoring

### 1. Transaction Monitoring

Monitor:
- Transaction success rates
- Transaction confirmation times
- Token balances and transfers

### 2. Error Tracking

Track:
- API errors
- Client-side errors
- Contract interaction errors

### 3. User Feedback

Collect and respond to user feedback about the mainnet experience.

## Conclusion

Migrating from devnet to mainnet is a significant milestone for the Choir application. By following this guide and thoroughly testing each component, you can ensure a smooth transition with minimal disruption to users. Remember that mainnet operations involve real assets, so proceed with caution and prioritize security at every step.
