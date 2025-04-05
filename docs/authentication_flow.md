# Choir Authentication Flow and User ID Persistence

## Overview

Choir uses Sui blockchain identities for authentication. Each user's Sui wallet address is deterministically mapped to a UUID that is used consistently throughout the application. This document explains the process and implementation details.

## Sui Address to UUID Mapping

The UUID for a user is derived from their Sui address using SHA-256 hashing. This ensures:

1. The same Sui address always maps to the same UUID
2. UUIDs are unique for each Sui address
3. The mapping is deterministic and reproducible

The backend uses this algorithm to derive the UUID:
```python
user_uuid = str(uuid.UUID(hashlib.sha256(sui_address.encode()).hexdigest()[0:32]))
```

## Authentication Flow

1. **Challenge Request**:
   - Client sends the Sui address to `/auth/request_challenge`
   - Server generates a random challenge and stores it with the address

2. **Challenge Signing**:
   - Client signs the challenge with the user's Sui wallet private key
   - This proves ownership of the wallet

3. **Verification**:
   - Client sends the address and signature to `/auth/verify`
   - Server verifies the signature against the challenge
   - Server derives the UUID from the address and returns it
   - UUID is stored in Qdrant if it's a new user

4. **Client Storage**:
   - The client stores the UUID in:
     - Memory for the current session
     - UserDefaults with address as context for future sessions
   - This avoids unnecessary re-verification if the app is restarted

## Implementation Details

### Server-Side (Python)

The auth router (`/api/app/routers/auth.py`) handles challenge generation, signature verification, and UUID derivation. The UUID is deterministically generated from the Sui address ensuring consistency.

### Client-Side (Swift)

The `ChoirAPIClient` provides methods for:
- `requestChallenge`: Gets a challenge for a Sui address
- `verifyUser`: Verifies signature and gets UUID
- `getCachedUserId`: Gets cached UUID for an address

In `ContentView`, we:
1. Check for a cached UUID first
2. If not found, go through the full challenge-response flow
3. Store the UUID with the address as context

## Importance

Using deterministic UUIDs:
- Ensures users always see their threads
- Prevents multiple user identities for the same wallet
- Allows persistent storage of conversation history
- Enables thread sharing between devices logged in with the same wallet

## Security Considerations

- Challenge expiry is set to 5 minutes
- Real signature verification is implemented on the backend
- UUIDs are derived cryptographically from addresses

## Future Improvements

- Implement real Sui signature verification on client
- Add refresh token mechanism for long sessions
- Cache thread list locally with the UUID to improve offline experience
