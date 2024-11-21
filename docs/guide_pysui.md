# PySUI Integration Guide

## Overview
This guide documents our learnings from implementing PySUI v0.72.0 to interact with Sui smart contracts. It focuses on the patterns that worked, helping future developers avoid common pitfalls.

## Key Components

### Client Setup
- Use `SuiConfig.default_config()` for network configuration
- Initialize `SuiClient` with the config
- Load and validate signer keypair from environment variables

### Transaction Building
- Create transaction with `SuiTransaction(client=self.client)`
- Use `move_call()` to specify contract interactions
- Properly wrap arguments with scalar types:
  - `ObjectID` for object references (e.g., treasury cap)
  - `SuiU64` for u64 numbers
  - `SuiAddress` for addresses

### Error Handling
- Check `result.is_ok()` for transaction success
- Inspect `effects.status.status` for detailed transaction status
- Log transaction results for debugging
- Return structured responses with success/error info

### Common Pitfalls
1. **Object References**: Must use `ObjectID` for contract objects
2. **Address Formatting**: Always use `SuiAddress` for address parameters
3. **Transaction Status**: Check both RPC success and transaction effects

### Response Format
Success:
json
{
"success": true,
"digest": "tx_digest_here",
"amount": "1.0 CHOIR",
"recipient": "0x..."
}
Error:
json
{
"success": false,
"error": "error_message_here",
"digest": "tx_digest_here" // if available
}

## FastAPI Integration
- Create service class to encapsulate PySUI logic
- Handle errors with FastAPI's HTTPException
- Return structured JSON responses
- Log all operations for debugging

## Environment Setup
Required environment variables:
- `SUI_PRIVATE_KEY`: Deployer's private key

## Version Notes
This guide is specific to PySUI v0.72.0. The API may change in future versions.

## References
- PySUI Documentation: https://github.com/FrankC01/pysui/tree/main/docs
- Sui Documentation: https://docs.sui.io/
