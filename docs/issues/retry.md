# Postchain Retry Implementation Plan

This document outlines the atomic steps for implementing a safe retry mechanism for postchain phases in Choir. Each step results in a valid build and can be deployed independently.

## Background

Each postchain phase (action, experienceVectors, experienceWeb, intention, observation, understanding, yield) can fail for various reasons. We need to implement automatic retries with model switching and allow users to manually retry specific phases. However, we must ensure that rewards issued in the experienceVectors and yield phases are not double-issued during retries.

## Implementation Steps - Reward-Safety-First Approach

### 1. Reward Transaction ID Generation (Backend)

- Add transaction ID generation for reward operations
- Add transaction ID to reward response JSON
- Add logging of transaction IDs
- No database changes or behavior changes
- **Result**: Backend generates and returns transaction IDs for rewards

### 2. Client Reward Transaction Tracking

- Update client to parse and store transaction IDs from reward responses
- Add transaction IDs to message model
- Add basic UI indicator for rewarded status
- No retry functionality yet
- **Result**: Client displays and stores reward transaction IDs

### 3. Reward Transaction Database (Backend)

- Add database table to track reward transactions
- Modify backend to store transaction IDs
- Add API endpoint to query transaction status
- No changes to reward issuance logic yet
- **Result**: Backend stores transaction IDs for future idempotency

### 4. Transaction Verification API (Backend)

- Add API endpoint to verify if a transaction exists
- Allow client to check if a reward was already issued
- No changes to reward issuance logic yet
- **Result**: Client can verify if rewards were already issued

### 5. Idempotent Novelty Rewards (Backend)

- Modify `issue_novelty_reward()` to check for existing transactions
- Add idempotency keys based on message ID and wallet address
- Update response to indicate if reward was new or existing
- **Result**: Novelty rewards are idempotent

### 6. Idempotent Citation Rewards (Backend)

- Modify `issue_citation_rewards()` to check for existing transactions
- Add idempotency keys for each citation
- Update response to indicate which citations were rewarded
- **Result**: Citation rewards are idempotent

### 7. Retry Context Foundation (Client)

- Implement basic `RetryContext` class focused on reward tracking
- Add to `Message` class but don't use it yet
- Add serialization support for persistence
- **Result**: Client has data structures for tracking retries

### 8. Retry Flag API (Backend)

- Add retry flag parameter to backend API
- Update client to send retry flag
- Backend logs but doesn't use retry flag yet
- **Result**: Backend aware of retry attempts

### 9. Retry-Aware Reward Decisions (Backend)

- Update backend to use retry flag for reward decisions
- Skip reward issuance for retried phases if already issued
- **Result**: Backend makes retry-aware reward decisions

### 10. Basic Automatic Retry (Non-Reward Phases)

- Implement retry logic for non-reward phases
- Skip experienceVectors and yield phases for now
- Add UI indicators for retries
- **Result**: App automatically retries non-reward phases

### 11. Full Automatic Retry

- Extend automatic retry to all phases including reward phases
- Integrate with reward safety mechanisms
- Add UI indicators for all phases
- **Result**: Complete automatic retry with reward safety

### 12. Retry State Persistence

- Update thread persistence to store retry context
- Implement resumption of retries after app restart
- Update background task handling for retries
- **Result**: Persistent retry state across app launches

### 13. Basic Manual Retry UI

- Add retry buttons to phase cards
- Implement manual retry logic
- Add retry status indicators
- **Result**: User can manually retry phases

### 14. Model Performance Tracking

- Add model tracking to retry context
- Update coordinator to record model success/failure
- Add local storage for statistics
- **Result**: App tracks model performance

### 15. Model Selection UI

- Add model selection for manual retries
- Implement UI for choosing models
- **Result**: User can select models for retries

### 16. Automatic Model Switching

- Implement model fallback strategy
- Update automatic retry to try different models
- **Result**: Intelligent model switching

### 17. Advanced Analytics

- Implement backend analytics for model performance
- Add dashboard for statistics
- **Result**: Data-driven model selection

## Alternative Pathways Considered

We considered several alternative implementation pathways:

### UI-First Approach

This approach would prioritize user-visible features earlier:
1. Implement basic retry UI first (buttons and indicators)
2. Add manual retry functionality for non-reward phases
3. Add backend changes later

**Pros**: Earlier user feedback on UI
**Cons**: Delays critical reward safety mechanisms

### Incremental Feature Approach

This approach would balance reward safety with user-visible features:
1. Implement foundational retry context
2. Add phase failure detection
3. Implement reward safety mechanisms
4. Add automatic retry functionality
5. Add manual retry UI

**Pros**: Balanced approach with regular value delivery
**Cons**: Doesn't prioritize reward safety as strongly

## Chosen Approach

We chose the Reward-Safety-First approach because:
1. It addresses the most critical business requirement (reward safety) from the beginning
2. It ensures rewards are not double-issued before implementing any retry functionality
3. Each step still delivers incremental value and results in a valid build
4. It establishes a solid foundation for retry functionality
5. It minimizes business risk while still allowing for incremental development

This approach ensures that the core business logic around rewards is solid before adding retry functionality, while still delivering value incrementally.
