# Blockchain Integration Guide

This guide documents the integration between Choir's actor-based architecture and the Sui blockchain. It covers smart contract interaction patterns, transaction flows, and security considerations.

## Table of Contents

1. [Introduction](#introduction)
2. [Sui Blockchain Overview](#sui-blockchain-overview)
3. [Integration Architecture](#integration-architecture)
4. [Smart Contract Interaction](#smart-contract-interaction)
5. [Transaction Flow](#transaction-flow)
6. [Security Considerations](#security-considerations)
7. [Testing Strategies](#testing-strategies)
8. [Examples](#examples)

## Introduction

Choir integrates with the Sui blockchain to provide:

- Transparent token economics
- Decentralized identity
- Immutable record-keeping
- Value distribution mechanisms

This integration is implemented through a set of actors that interact with the Sui blockchain, providing a clean separation between the application logic and blockchain interactions.

## Sui Blockchain Overview

[Sui](https://sui.io/) is a Layer 1 blockchain designed for high throughput and low latency. Key features relevant to Choir include:

- Object-centric model
- Move programming language
- Parallel transaction execution
- Causal order consensus

Sui's object-centric model aligns well with Choir's actor-based architecture, as both emphasize encapsulation and message passing.

## Integration Architecture

The blockchain integration follows a layered architecture:

1. **Actor Layer**: Blockchain-specific actors that encapsulate blockchain interactions
2. **Protocol Layer**: Message protocols for blockchain operations
3. **Client Layer**: Sui SDK integration for communicating with the blockchain
4. **Contract Layer**: Smart contracts deployed on the Sui blockchain

### Blockchain Actors

The primary actors involved in blockchain integration are:

- `BlockchainActor`: Coordinates all blockchain interactions
- `TokenActor`: Manages token-related operations
- `IdentityActor`: Handles blockchain-based identity
- `TransactionActor`: Processes and monitors transactions

## Smart Contract Interaction

### Contract Structure

Choir's smart contracts on Sui are organized into modules:

- `choir_token`: Core token functionality
- `choir_identity`: Identity management
- `choir_governance`: Governance mechanisms
- `choir_rewards`: Reward distribution

### Interaction Patterns

#### Pattern 1: Read-Only Operations

For querying blockchain state without modifying it:

```python
async def query_balance(address):
    # Create a read-only transaction
    response = await blockchain_actor.send(
        Message(
            type="QUERY",
            data={
                "contract": "choir_token",
                "function": "balance_of",
                "args": [address]
            }
        )
    )

    return response.data["balance"]
```

#### Pattern 2: Transaction Operations

For operations that modify blockchain state:

```python
async def transfer_tokens(from_address, to_address, amount):
    # Create a transaction
    response = await blockchain_actor.send(
        Message(
            type="TRANSACTION",
            data={
                "contract": "choir_token",
                "function": "transfer",
                "args": [from_address, to_address, amount],
                "gas_budget": 2000
            }
        )
    )

    # Return the transaction digest
    return response.data["digest"]
```

#### Pattern 3: Event Monitoring

For monitoring blockchain events:

```python
async def monitor_token_transfers():
    # Subscribe to events
    response = await blockchain_actor.send(
        Message(
            type="SUBSCRIBE",
            data={
                "contract": "choir_token",
                "event": "Transfer",
                "callback_actor": "event_processor"
            }
        )
    )

    return response.data["subscription_id"]
```

## Transaction Flow

### 1. Transaction Creation

```
User/System -> TransactionActor -> BlockchainActor -> Sui SDK
```

1. A user or system component initiates a transaction
2. The TransactionActor prepares the transaction parameters
3. The BlockchainActor creates and signs the transaction
4. The Sui SDK submits the transaction to the blockchain

### 2. Transaction Monitoring

```
Sui Blockchain -> Event Listener -> BlockchainActor -> Event Subscribers
```

1. The transaction is processed on the Sui blockchain
2. The Event Listener detects relevant events
3. The BlockchainActor processes and validates the events
4. Event Subscribers receive notifications about the events

### 3. Transaction Confirmation

```
Sui Blockchain -> BlockchainActor -> TransactionActor -> User/System
```

1. The transaction is confirmed on the Sui blockchain
2. The BlockchainActor detects the confirmation
3. The TransactionActor updates its state
4. The User/System receives confirmation of the transaction

## Security Considerations

### Key Management

Secure management of private keys is critical:

- Use hardware security modules (HSMs) when possible
- Implement proper key rotation procedures
- Separate key management from transaction logic

### Transaction Validation

Always validate transactions before submission:

- Verify sender has sufficient balance
- Check transaction parameters against business rules
- Implement rate limiting to prevent abuse

### Error Handling

Robust error handling for blockchain interactions:

- Handle network failures gracefully
- Implement retry mechanisms with exponential backoff
- Maintain transaction logs for reconciliation

### Audit Trail

Maintain comprehensive audit trails:

- Log all blockchain interactions
- Record transaction parameters and results
- Implement monitoring for suspicious activities

## Testing Strategies

### Unit Testing

Test individual blockchain actors:

```python
async def test_blockchain_actor():
    # Create a mock Sui client
    mock_sui_client = MockSuiClient()

    # Create the blockchain actor with the mock client
    blockchain_actor = BlockchainActor(
        "test_blockchain_actor",
        sui_client=mock_sui_client
    )

    # Test a query operation
    response = await blockchain_actor.receive(
        Message(
            type="QUERY",
            data={
                "contract": "choir_token",
                "function": "balance_of",
                "args": ["0x123"]
            }
        )
    )

    # Assert on the response
    assert response.type == "QUERY_RESULT"
    assert response.data["balance"] == 100
```

### Integration Testing

Test the interaction between blockchain actors and the Sui blockchain:

```python
async def test_token_transfer():
    # Use a test network for integration testing
    sui_client = SuiClient(network="testnet")

    # Create the blockchain actor with the real client
    blockchain_actor = BlockchainActor(
        "test_blockchain_actor",
        sui_client=sui_client
    )

    # Test a transfer operation
    response = await blockchain_actor.receive(
        Message(
            type="TRANSACTION",
            data={
                "contract": "choir_token",
                "function": "transfer",
                "args": ["0x123", "0x456", 10],
                "gas_budget": 2000
            }
        )
    )

    # Assert on the response
    assert response.type == "TRANSACTION_SUBMITTED"
    assert "digest" in response.data

    # Verify the transaction was successful
    transaction_status = await sui_client.get_transaction(response.data["digest"])
    assert transaction_status["status"] == "success"
```

### Local Testing Environment

Set up a local Sui blockchain for development and testing:

1. Use Sui's local development network
2. Deploy test versions of smart contracts
3. Create test accounts with known private keys
4. Automate the setup process for CI/CD

## Examples

### Example 1: Token Transfer

```python
class TokenActor(Actor):
    async def initialize(self, blockchain_actor_id):
        self.blockchain_actor_id = blockchain_actor_id

    async def receive(self, message):
        if message.type == "TRANSFER":
            # Extract parameters
            from_address = message.data["from_address"]
            to_address = message.data["to_address"]
            amount = message.data["amount"]

            # Get the blockchain actor
            blockchain_actor = await self.get_actor(self.blockchain_actor_id)

            # Submit the transfer transaction
            response = await blockchain_actor.send(
                Message(
                    type="TRANSACTION",
                    data={
                        "contract": "choir_token",
                        "function": "transfer",
                        "args": [from_address, to_address, amount],
                        "gas_budget": 2000
                    }
                )
            )

            # Return the transaction digest
            return Response(
                type="TRANSFER_SUBMITTED",
                data={"digest": response.data["digest"]}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")
```

### Example 2: Event Processing

```python
class EventProcessorActor(Actor):
    async def initialize(self, blockchain_actor_id):
        self.blockchain_actor_id = blockchain_actor_id
        self.processed_events = set()

    async def receive(self, message):
        if message.type == "BLOCKCHAIN_EVENT":
            # Extract event data
            event_type = message.data["event_type"]
            event_data = message.data["event_data"]
            event_id = message.data["event_id"]

            # Check if we've already processed this event
            if event_id in self.processed_events:
                return Response(type="EVENT_ALREADY_PROCESSED")

            # Process the event based on its type
            if event_type == "Transfer":
                await self._process_transfer_event(event_data)
            elif event_type == "Mint":
                await self._process_mint_event(event_data)
            elif event_type == "Burn":
                await self._process_burn_event(event_data)

            # Mark the event as processed
            self.processed_events.add(event_id)

            return Response(type="EVENT_PROCESSED")
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    async def _process_transfer_event(self, event_data):
        # Implementation-specific event processing
        from_address = event_data["from"]
        to_address = event_data["to"]
        amount = event_data["amount"]

        # Update local state or trigger other actions
        pass
```

## Conclusion

This guide provides a foundation for integrating Choir's actor-based architecture with the Sui blockchain. By following these patterns and best practices, you can create a secure, reliable, and efficient blockchain integration.

For more detailed information, refer to:

- [Actor Model Overview](../1-concepts/actor_model_overview.md)
- [Message Protocol Reference](../3-implementation/message_protocol_reference.md)
- [Sui Developer Documentation](https://docs.sui.io/)
