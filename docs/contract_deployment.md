# Choir Contract Deployment Guide

This document outlines the process for deploying the Choir token contract to both devnet and mainnet environments. It provides step-by-step instructions, important considerations, and troubleshooting tips.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Devnet Deployment](#devnet-deployment)
3. [Mainnet Deployment](#mainnet-deployment)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Troubleshooting](#troubleshooting)
6. [Security Considerations](#security-considerations)

## Prerequisites

Before deploying the Choir contract, ensure you have:

- Sui CLI installed (`sui` command available)
- Active Sui wallet with sufficient gas tokens
- Choir contract code in `choir_coin/choir_coin` directory
- Backup of private keys (especially important for mainnet)
- Python virtual environment set up for API updates

## Devnet Deployment

Follow these steps to deploy the Choir contract to Sui devnet:

### 1. Navigate to the Contract Directory

```bash
cd choir_coin/choir_coin
```

### 2. Switch to Devnet Environment

```bash
sui client switch --env devnet
```

### 3. Verify Active Address

```bash
sui client active-address
```

This will display your active wallet address, which will be used for deployment.

### 4. Check Gas Balance

```bash
sui client gas
```

Ensure you have sufficient SUI tokens for deployment (at least 1 SUI recommended).

### 5. Build the Contract

```bash
sui move build
```

This compiles the Move code and prepares it for deployment.

### 6. Publish the Contract

```bash
sui client publish --gas-budget 100000000
```

This command publishes the contract to devnet. The output will contain important information:

- **Package ID**: Identified in the output as "Published to 0x..."
- **Treasury Cap ID**: Found in the "Created Objects" section with type containing "TreasuryCapability"

Example output:
```
Published to 0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a
...
Created Objects:
  ┌──
  │ ID: 0x6eab9c65acf9b4001199ac98813951140417b5feff8a85218eddd14a62d14f37
  │ Owner: Account Address ( 0xe9e9eba13e6868cbb3ab97b5615b2f09459fd6bbac500a251265165febc3073d )
  │ ObjectType: 0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a::choir::TreasuryCapability
  ...
```

### 7. Test Minting Tokens

```bash
sui client call --package <PACKAGE_ID> --module choir --function mint --args <TREASURY_CAP_ID> 1000000000 <RECIPIENT_ADDRESS> --gas-budget 10000000
```

Replace the placeholders with your actual values:
- `<PACKAGE_ID>`: The package ID from step 6
- `<TREASURY_CAP_ID>`: The treasury cap ID from step 6
- `<RECIPIENT_ADDRESS>`: Your wallet address or another test address

Example:
```bash
sui client call --package 0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a --module choir --function mint --args 0x6eab9c65acf9b4001199ac98813951140417b5feff8a85218eddd14a62d14f37 1000000000 0xe9e9eba13e6868cbb3ab97b5615b2f09459fd6bbac500a251265165febc3073d --gas-budget 10000000
```

This mints 1 CHOIR token (1,000,000,000 base units with 9 decimals) to the specified address.

## Mainnet Deployment

The process for mainnet deployment is similar to devnet, but requires additional care and consideration:

### 1. Navigate to the Contract Directory

```bash
cd choir_coin/choir_coin
```

### 2. Switch to Mainnet Environment

```bash
sui client switch --env mainnet
```

### 3. Verify Active Address

```bash
sui client active-address
```

Ensure this is the address you want to use for the mainnet deployment.

### 4. Check Gas Balance

```bash
sui client gas
```

Verify you have sufficient SUI tokens for deployment on mainnet (at least 2-3 SUI recommended).

### 5. Build the Contract

```bash
sui move build
```

### 6. Publish the Contract

```bash
sui client publish --gas-budget 100000000
```

**IMPORTANT**: This will use real SUI tokens and deploy the contract to the mainnet blockchain.

Record the Package ID and Treasury Cap ID from the output, as you did for devnet.

**Mainnet Deployment Results:**
- **Package ID**: `0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898`
- **Treasury Cap ID**: `0x1ee8226165efd8c2cf965199855b40acb0a86c667d64ea5251a06163feeeaa12`
- **Deployer Address**: `0xe9e9eba13e6868cbb3ab97b5615b2f09459fd6bbac500a251265165febc3073d`
- **Transaction Digest**: `EBv5AeY9HPYYrgrkSZNAEkQojjYqYurnHx1T4pydFxLj`

### 7. Test Minting Tokens (Optional)

```bash
sui client call --package <MAINNET_PACKAGE_ID> --module choir --function mint --args <MAINNET_TREASURY_CAP_ID> 1000000000 <RECIPIENT_ADDRESS> --gas-budget 10000000
```

Consider minting a small amount first to verify everything works correctly.

**Initial Token Mint:**
```bash
sui client call --package 0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898 --module choir --function mint --args 0x1ee8226165efd8c2cf965199855b40acb0a86c667d64ea5251a06163feeeaa12 1000000000 0xe9e9eba13e6868cbb3ab97b5615b2f09459fd6bbac500a251265165febc3073d --gas-budget 10000000
```

This minted 1 CHOIR token (1,000,000,000 base units with 9 decimals) to the deployer address. The transaction was successful with digest: `5wCGxiLk9pQjmuMk1Buc3koGCKVjAyYoQ2AFKjn8mVrm`.

## Post-Deployment Configuration

After deploying the contract, you need to update the application configuration:

### 1. Update SUI Service Configuration

Edit `api/app/services/sui_service.py` to update the package ID and treasury cap ID:

```python
# For network-specific configuration
if self.network == "mainnet":
    self.package_id = "0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898"
    self.treasury_cap_id = "0x1ee8226165efd8c2cf965199855b40acb0a86c667d64ea5251a06163feeeaa12"
else:  # devnet
    self.package_id = "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a"
    self.treasury_cap_id = "0x6eab9c65acf9b4001199ac98813951140417b5feff8a85218eddd14a62d14f37"
```

### 2. Update Swift Client Configuration

Edit `Choir/Models/CoinType.swift` to update the coin type identifier:

```swift
static let choir = CoinType(
    coinTypeIdentifier: "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a::choir::CHOIR", // For devnet
    name: "Choir",
    symbol: "CHOIR",
    decimals: 9,
    iconName: "choir-logo"
)

// For mainnet, you would use:
// coinTypeIdentifier: "0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898::choir::CHOIR"
```

For a multi-environment setup, consider implementing environment-specific configurations like:

```swift
#if DEBUG
static let choir = CoinType(
    coinTypeIdentifier: "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a::choir::CHOIR", // Devnet
    name: "Choir",
    symbol: "CHOIR",
    decimals: 9,
    iconName: "choir-logo"
)
#else
static let choir = CoinType(
    coinTypeIdentifier: "0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898::choir::CHOIR", // Mainnet
    name: "Choir",
    symbol: "CHOIR",
    decimals: 9,
    iconName: "choir-logo"
)
#endif
```

### 3. Test the Notification System

After updating the configuration, test the notification system to ensure it works with the new contract:

```bash
cd api
source venv/bin/activate
python ../scripts/test_notifications.py
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "SuiKit.SuiError error 26"

This error often indicates a coin type mismatch. Check:
- The coin type identifier in `CoinType.swift` matches the actual deployed contract
- The package ID in the API configuration matches the deployed contract

#### 2. "No coin objects found for this coin type"

This indicates that the wallet doesn't have any coins of the specified type. Solutions:
- Verify the coin type is correct
- Mint some tokens to the wallet
- Check if the wallet address is correct

#### 3. Transaction Failures

If transactions fail:
- Check gas budget (increase if necessary)
- Verify the treasury cap ID is correct
- Ensure the wallet has sufficient permissions

#### 4. API Connection Issues

If the API can't connect to the Sui network:
- Verify network configuration (devnet vs mainnet)
- Check if the Sui node is accessible
- Verify API keys and authentication

## Security Considerations

### Treasury Cap Management

The treasury cap gives complete control over the token supply. Consider:
- Using a multi-signature wallet for the treasury cap
- Implementing time-locks or governance mechanisms
- Regularly auditing mint/burn operations

### Private Key Security

- Store private keys securely, preferably in hardware wallets
- Use different wallets for development and production
- Consider key rotation strategies

### Contract Upgradability

The current contract is not upgradable. For future versions:
- Consider implementing upgrade mechanisms
- Document the upgrade process
- Test upgrades thoroughly on devnet before mainnet

### Monitoring

- Set up monitoring for contract interactions
- Monitor token supply and large transfers
- Implement alerts for unusual activity

## Conclusion

Deploying the Choir contract requires careful planning and execution. By following this guide, you can ensure a smooth deployment process and minimize potential issues. Always test thoroughly on devnet before proceeding to mainnet, and maintain secure practices for managing the treasury capability.
