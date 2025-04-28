# Choir Notification System

This document describes the Choir notification system, focusing on citation notifications and their integration with the Choir token contract. It covers the architecture, implementation details, and troubleshooting procedures.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Implementation Details](#implementation-details)
4. [Contract Integration](#contract-integration)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)
7. [Future Improvements](#future-improvements)

## System Overview

The Choir notification system tracks and delivers notifications to users when their content is cited by others. These citations are also tied to the reward system, which mints Choir tokens to content creators when their work is cited.

Key features:
- Citation tracking and notification
- Integration with the Choir token contract
- In-app notification display
- Transaction history

## Architecture

The notification system consists of several components:

### Backend Components

1. **NotificationService**: Handles the creation and retrieval of notifications
2. **RewardsService**: Processes citation rewards and triggers notifications
3. **DatabaseClient**: Stores and retrieves notifications from Qdrant
4. **SuiService**: Interacts with the Sui blockchain and Choir contract

### Frontend Components

1. **TransactionService**: Fetches and displays notifications/transactions
2. **NotificationsView**: UI for displaying notifications
3. **WalletManager**: Manages wallet interactions and token transfers

### Data Flow

1. User cites content → Citation detected in yield phase
2. RewardsService processes citation → Issues token rewards
3. NotificationService creates notification → Stored in Qdrant
4. Client fetches notifications → Displayed in TransactionsView

## Implementation Details

### Notification Data Structure

```python
notification = {
    "type": "citation",  # or "self_citation"
    "recipient_wallet_address": author_wallet_address,
    "sender_wallet_address": citing_wallet_address,
    "vector_id": vector_id,
    "read": False,
    "created_at": datetime.now(UTC).isoformat()
}
```

### Database Storage

Notifications are stored in Qdrant with:
- Collection name: `notifications`
- Vector size: Same as message vectors (placeholder vectors used)
- Query filtering: By recipient wallet address

### API Endpoints

- `GET /api/notifications`: Retrieve notifications for a wallet
- `POST /api/notifications/{id}/read`: Mark notification as read

## Contract Integration

The notification system integrates with the Choir token contract through the SuiService:

### Citation Reward Flow

1. Citation detected in `issue_citation_rewards` function
2. SuiService mints tokens to author using:
   ```python
   mint_choir(recipient_address=author_wallet_address, amount=reward_amount)
   ```
3. NotificationService creates citation notification
4. Both operations (minting and notification) are logged

### Contract Dependencies

The notification system depends on:
- Package ID: Current devnet ID is `0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a`
- Treasury Cap ID: Current devnet ID is `0x6eab9c65acf9b4001199ac98813951140417b5feff8a85218eddd14a62d14f37`

When the contract is redeployed, these IDs must be updated in:
- `api/app/services/sui_service.py`
- `Choir/Models/CoinType.swift`

## Testing

### Test Script

The `scripts/test_notifications.py` script tests the end-to-end notification flow:

1. Creates a test message with a wallet address
2. Creates a citation to that message
3. Verifies notification creation
4. Tests notification retrieval
5. Tests citation rewards through RewardsService

### Running Tests

```bash
cd api
source venv/bin/activate
python ../scripts/test_notifications.py
```

### Expected Output

A successful test will show:
- Test message creation
- Citation notification creation
- Notification retrieval
- Citation reward issuance
- Transaction confirmation

## Troubleshooting

### Common Issues

#### 1. Missing Notifications

**Symptoms**: Citations occur but no notifications appear

**Possible Causes**:
- RewardsService not calling NotificationService
- Database connection issues
- Missing wallet metadata in vectors

**Solutions**:
- Check logs for errors in `issue_citation_rewards`
- Verify Qdrant connection and collection existence
- Ensure vectors have `wallet_address` in metadata

#### 2. Contract Mismatch Errors

**Symptoms**: "SuiKit.SuiError error 26" or similar errors

**Possible Causes**:
- Mismatched contract IDs after redeployment
- Incorrect coin type identifier

**Solutions**:
- Update contract IDs in `sui_service.py`
- Update coin type in `CoinType.swift`
- Verify contract exists on the network

#### 3. Database Errors

**Symptoms**: "SortParams not available" or other Qdrant errors

**Possible Causes**:
- Qdrant client version mismatch
- Missing collections
- Query syntax errors

**Solutions**:
- Update Qdrant client or add compatibility code
- Check collection existence and create if missing
- Verify query syntax and parameters

### Debugging Tools

1. **Enhanced Logging**:
   - NotificationService logs notification creation
   - RewardsService logs reward issuance
   - DatabaseClient logs database operations

2. **Test Script**:
   - Use `test_notifications.py` to verify the flow

3. **Manual Verification**:
   - Check Qdrant collections directly
   - Verify Sui transactions on explorer

## Future Improvements

### Short-term Improvements

1. **Batch Processing**:
   - Process multiple notifications in a single operation
   - Reduce database calls

2. **Notification Categories**:
   - Add support for different notification types
   - Implement filtering by type

3. **Read Status Sync**:
   - Sync read status across devices
   - Implement unread count badge

### Long-term Improvements

1. **Push Notifications**:
   - Add optional push notification support
   - Implement device token management

2. **Notification Preferences**:
   - Allow users to customize notification settings
   - Implement notification frequency controls

3. **Rich Notifications**:
   - Add support for rich content in notifications
   - Include preview of cited content

## Conclusion

The Choir notification system is a critical component that connects user interactions with the reward system. By ensuring proper integration with the Choir token contract and maintaining consistent configuration across deployments, the system can reliably deliver notifications and rewards to users.

When deploying to new environments or redeploying the contract, special attention must be paid to updating the contract IDs and testing the end-to-end flow to ensure continued functionality.
