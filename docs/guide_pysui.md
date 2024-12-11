# PySUI Integration Guide

## Overview

This guide documents our implementation of PySUI for interacting with Sui smart contracts, specifically for the CHIP token. Based on our deployment experience, we'll focus on working patterns and known issues.

## Key Components

### Client Setup

```python
# Initialize with devnet RPC
self.config = SuiConfig.user_config(
    rpc_url="https://fullnode.devnet.sui.io:443",
    prv_keys=[deployer_key]
)
self.client = SuiClient(config=self.config)
self.signer = keypair_from_keystring(deployer_key)
```

### Transaction Building (CHOIR Minting)

```python
# Create transaction
txn = SuiTransaction(client=self.client)

# Add move call with proper argument types
txn.move_call(
    target=f"{package_id}::choir::mint",
    arguments=[
        ObjectID(treasury_cap_id),
        SuiU64(amount),
        SuiAddress(recipient_address)
    ],
    type_arguments=[]
)

# Execute and check result
result = txn.execute()
```

### Balance Checking

```python
# Using GetAllCoinBalances builder
builder = GetAllCoinBalances(
    owner=SuiAddress(address)
)
result = self.client.execute(builder)
```

### Error Handling Pattern

```python
if result.is_ok():
    # Check transaction effects
    effects = result.result_data.effects
    if effects and hasattr(effects, 'status'):
        if effects.status.status != 'success':
            # Handle failure
    else:
        # Handle success
else:
    # Handle RPC error
```

### Common Pitfalls

1. **Builder Pattern Required**: Use builders like `GetAllCoinBalances` for queries
2. **Transaction Effects**: Always check both `is_ok()` and effects status
3. **Type Wrapping**: Must wrap arguments with proper types (`ObjectID`, `SuiU64`, `SuiAddress`)
4. **Environment Setup**: Ensure Rust toolchain is available for `pysui` installation

## Docker Deployment Notes

- Requires Rust toolchain for building `pysui`
- Consider splitting pip install steps for better caching
- Virtual environment recommended for isolation

## Environment Variables

Required:

- `SUI_PRIVATE_KEY`: Deployer's private key
- Contract IDs (can be hardcoded or env vars):
  - `package_id`
  - `treasury_cap_id`

## Current Limitations

- Balance checking API may change between versions
- Long build times due to Rust compilation
- Limited error details from transaction effects

## References

- [PySUI Documentation](https://github.com/FrankC01/pysui)
- [Sui JSON-RPC API](https://docs.sui.io/sui-jsonrpc)
