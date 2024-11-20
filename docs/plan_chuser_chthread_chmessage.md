# SwiftData and Choir Models Implementation Plan

## Overview
Implement SwiftData persistence with CH-prefixed models, using SUI wallet as the core identity system.

## 1. Core Models
- [ ] Create CHUser model
  - [ ] Wallet address as primary identifier (from wallet.accounts[0].address())
  - [ ] Creation timestamp
  - [ ] Owned threads relationship
  - [ ] Co-authored threads relationship
  - [ ] Created messages relationship

- [ ] Create CHThread model
  - [ ] UUID for local identification
  - [ ] Title and creation timestamp
  - [ ] Owner relationship (CHUser)
  - [ ] Co-authors relationship (Set<CHUser>)
  - [ ] Messages relationship
  - [ ] Message count tracking
  - [ ] Last message timestamp

- [ ] Create CHMessage model
  - [ ] UUID matching Qdrant ID
  - [ ] Content and timestamp
  - [ ] Author relationship (CHUser)
  - [ ] Thread relationship (CHThread)
  - [ ] ChorusResult for AI processing
  - [ ] isUser flag

## 2. Identity Integration
- [ ] Update WalletManager to create/load CHUser
  - [ ] Create CHUser on first wallet creation
  - [ ] Load CHUser when loading existing wallet
  - [ ] Use wallet address as stable identifier
  - [ ] Handle wallet address changes

## 3. ViewModels
- [ ] Create ThreadListViewModel
  - [ ] Load current user's threads (owned + co-authored)
  - [ ] Create new threads with current user as owner
  - [ ] Handle thread selection
  - [ ] Manage thread lifecycle

- [ ] Create ThreadDetailViewModel
  - [ ] Load thread messages
  - [ ] Handle message creation with proper authorship
  - [ ] Process AI responses
  - [ ] Manage co-authors

## 4. Update Existing Views
- [ ] Modify ContentView
  - [ ] Use ThreadListViewModel
  - [ ] Update thread creation with wallet identity
  - [ ] Integrate WalletView
  - [ ] Handle navigation

- [ ] Update ChoirThreadDetailView
  - [ ] Use ThreadDetailViewModel
  - [ ] Show wallet-based author information
  - [ ] Display message history
  - [ ] Handle AI processing

## 5. Prior Support Foundation
- [ ] Enhance CHMessage
  - [ ] Add prior references
  - [ ] Store source thread info
  - [ ] Prepare for navigation
  - [ ] Handle citations

## 6. Testing
- [ ] Model relationship tests
  - [ ] Wallet-user mapping
  - [ ] Thread ownership
  - [ ] Message attribution
  - [ ] Prior references

- [ ] ViewModel tests
  - [ ] Thread loading
  - [ ] Message creation
  - [ ] State management
  - [ ] Error handling

## Success Criteria
- [ ] Data persists between app launches
- [ ] Wallet identity works reliably
- [ ] Messages maintain Qdrant sync
- [ ] UI updates reflect persistence
- [ ] Prior references preserved

## Implementation Order
1. Core models with wallet integration
2. Basic persistence without priors
3. View updates
4. Prior support
5. Testing

## Notes
- Wallet is required for all operations
- Use wallet address as stable identifier
- Maintain ID consistency with Qdrant
- Keep relationships clean and well-defined
