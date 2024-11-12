# SwiftUI Chorus Integration Plan

## 1. Models & Types

- [ ] Create Codable models matching API responses
  - [ ] `ChorusResponse` with phase-specific fields
  - [ ] `APIResponse<T>` wrapper type
  - [ ] Phase-specific response models (Action, Experience, etc.)
  - [ ] Error response models

## 2. API Client Layer

- [ ] Create base API client with error handling
  - [ ] Configure URLSession with appropriate timeouts
  - [ ] Handle common HTTP errors
  - [ ] Add retry logic for transient failures
- [ ] Add endpoints for each Chorus phase
  - [ ] `/chorus/action`
  - [ ] `/chorus/experience`
  - [ ] `/chorus/intention`
  - [ ] `/chorus/observation`
  - [ ] `/chorus/understanding`
  - [ ] `/chorus/yield`

## 3. Concurrency & State Management

- [ ] Create MessageActor for high-level message handling
  - [ ] Support immediate cancellation
  - [ ] Track current phase
  - [ ] Handle task lifecycle
- [ ] Create ChorusActor for Chorus cycle management
  - [ ] Process phases sequentially
  - [ ] Support cancellation between phases
  - [ ] Handle phase transitions
  - [ ] Support looping from understanding phase

## 4. UI Components

- [ ] Update ChorusResponse view
  - [ ] Show current phase
  - [ ] Display intermediate responses
  - [ ] Add progress indicators
  - [ ] Show citations in yield phase
- [ ] Add cancellation button
  - [ ] Visual feedback during cancellation
  - [ ] Graceful state reset

## 5. Error Handling & Recovery

- [ ] Add error states to UI
  - [ ] Network errors
  - [ ] API errors
  - [ ] Timeout handling
- [ ] Implement retry mechanisms
  - [ ] Automatic retry for transient failures
  - [ ] Manual retry for user-initiated recovery

## 6. Progress & Feedback

- [ ] Add phase progress indicators
  - [ ] Visual phase transitions
  - [ ] Loading states
  - [ ] Cancellation states
- [ ] Improve response visualization
  - [ ] Incremental updates
  - [ ] Phase-specific formatting
  - [ ] Citation highlighting

## 7. Testing

- [ ] Unit tests for models
- [ ] Integration tests for API client
- [ ] UI tests for cancellation
- [ ] End-to-end flow tests

## 8. Performance Optimization

- [ ] Configure appropriate timeouts
- [ ] Implement response caching
- [ ] Optimize state updates
- [ ] Profile memory usage

## 9. Documentation

- [ ] Add inline documentation
- [ ] Document error handling
- [ ] Add usage examples
- [ ] Document testing approach

## Implementation Order

1. Models & API Client
2. Basic Concurrency
3. Simple UI Updates
4. Cancellation
5. Error Handling
6. Progress Indicators
7. Testing
8. Polish & Optimization

## Notes

- Keep Python backend stateless
- Handle all state in Swift
- Support immediate cancellation
- Show meaningful progress
- Graceful error recovery
