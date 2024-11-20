# SwiftData and Choir Models Implementation Plan

## Overview
Implement SwiftData persistence with CH-prefixed models, maintaining clean separation between Choir's core functionality and blockchain integration.

## 1. Core Models
- [ ] Create CHUser model
  - [ ] UUID for local identification
  - [ ] Optional wallet address (keeps blockchain optional)
  - [ ] Owned threads relationship
  - [ ] Co-authored threads relationship
  - [ ] Created messages relationship

- [ ] Create CHThread model
  - [ ] UUID for local identification
  - [ ] Title and creation timestamp
  - [ ] Owner relationship (CHUser)
  - [ ] Co-authors relationship (Set<CHUser>)
  - [ ] Messages relationship
  - [ ] Optional blockchain fields (onChainId, etc.)

- [ ] Create CHMessage model
  - [ ] UUID matching Qdrant ID
  - [ ] Content and timestamp
  - [ ] Author relationship (CHUser)
  - [ ] Thread relationship (CHThread)
  - [ ] ChorusResult for AI processing
  - [ ] isUser flag

## 2. Identity Integration
- [ ] Update WalletManager to work with CHUser
  - [ ] Keep wallet management separate from user identity
  - [ ] Link wallet address to CHUser when available
  - [ ] Support users without wallets
  - [ ] Handle wallet linking/unlinking

## 3. ViewModels
- [ ] Create ThreadListViewModel
  - [ ] Load user's threads (owned + co-authored)
  - [ ] Create new threads
  - [ ] Handle thread selection
  - [ ] Manage thread lifecycle

- [ ] Create ThreadDetailViewModel
  - [ ] Load thread messages
  - [ ] Handle message creation
  - [ ] Process AI responses
  - [ ] Manage co-authors

## 4. Update Existing Views
- [ ] Modify ContentView
  - [ ] Use ThreadListViewModel
  - [ ] Update thread creation
  - [ ] Keep wallet integration optional
  - [ ] Handle navigation

- [ ] Update ChoirThreadDetailView
  - [ ] Use ThreadDetailViewModel
  - [ ] Show author information
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
  - [ ] User-thread ownership
  - [ ] Thread co-authorship
  - [ ] Message attribution
  - [ ] Prior references

- [ ] ViewModel tests
  - [ ] Thread loading
  - [ ] Message creation
  - [ ] State management
  - [ ] Error handling

## Success Criteria
- [ ] Data persists between app launches
- [ ] Optional wallet integration works smoothly
- [ ] Messages maintain Qdrant sync
- [ ] UI updates reflect persistence
- [ ] Prior references preserved

## Future Considerations
- Blockchain integration remains optional
- Multi-device sync
- Prior navigation
- Citation visualization

## Notes
- Keep models blockchain-agnostic
- Focus on core Choir functionality first
- Maintain ID consistency with Qdrant
- Keep wallet integration optional
