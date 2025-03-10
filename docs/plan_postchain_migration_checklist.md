# PostChain Migration Checklist

This document outlines a gradual, surgical approach for migrating the SwiftUI client application from the Chorus Cycle to the PostChain Streaming API. Instead of creating a separate parallel implementation, we'll incrementally refactor the existing codebase while maintaining functionality.

## Migration Philosophy

- Make targeted changes to existing components rather than creating parallel implementations
- Maintain backwards compatibility where possible
- Implement changes in small, testable increments
- Focus on one component at a time to minimize disruption

## 1. Consistent Naming Migration

- [ ] Rename all Chorus Cycle components to PostChain consistently
  - [ ] Update `ChorusModels.swift` to `PostchainModels.swift`
  - [ ] Rename `ChorusCoordinator.swift` to `PostchainCoordinator.swift`
  - [ ] Update `RESTChorusCoordinator.swift` to `RESTPostchainCoordinator.swift`
  - [ ] Rename `MockChorusCoordinator.swift` to `MockPostchainCoordinator.swift`
  - [ ] Update `ChorusAPIClient.swift` to `PostchainAPIClient.swift`
  - [ ] Rename `ChorusViewModel.swift` to `PostchainViewModel.swift`
  - [ ] Update `ChorusCycleView.swift` to `PostchainView.swift`
- [ ] Update references throughout the codebase
  - [ ] Refactor import statements
  - [ ] Update class/protocol references
  - [ ] Fix function calls and property references
- [ ] Update comments and documentation
  - [ ] Replace "Chorus Cycle" terminology with "PostChain"
  - [ ] Update method and property documentation
- [ ] Ensure all tests pass after renaming

## 2. Foundation & Planning

- [ ] Analyze API differences between old implementation and PostChain streaming
  - [ ] Document endpoint changes
  - [ ] Identify data structure differences
  - [ ] Map out streaming vs. phase-based architecture differences
- [ ] Create feature flag system for gradual rollout
  - [ ] Add `isStreamingEnabled` toggle in environment/app configuration
  - [ ] Ensure all new code checks this flag

## 3. Data Model Adaptation

- [ ] Enhance existing models to support streaming
  - [ ] Update `ChoirThread.swift` to handle both traditional and streaming data
  - [ ] Enhance `PostchainModels.swift` with streaming-compatible structures
  - [ ] Modify `Phase.swift` to accommodate streaming phases
- [ ] Add extension methods for conversion between models
  - [ ] Create methods to transform streaming data to existing model formats
  - [ ] Add backwards-compatibility layers

## 4. API Client Enhancements

- [ ] Enhance `PostchainAPIClient.swift` to support streaming
  - [ ] Add streaming endpoint support
  - [ ] Implement SSE connection handling
  - [ ] Create unified error handling for both approaches
  - [ ] Add connection management capabilities for streaming

## 5. Coordinator Layer Updates

- [ ] Extend `PostchainCoordinator.swift` protocol
  - [ ] Add streaming-specific methods
  - [ ] Keep existing methods for backwards compatibility
- [ ] Update `RESTPostchainCoordinator.swift` with streaming capability
  - [ ] Implement stream processing logic
  - [ ] Add state management for continuous updates
  - [ ] Maintain phase-based approach as fallback
- [ ] Enhance `MockPostchainCoordinator.swift` for testing
  - [ ] Add streaming simulation capabilities

## 6. ViewModel Refactoring

- [ ] Incrementally update `PostchainViewModel.swift`
  - [ ] Add streaming state management
  - [ ] Implement content buffering for streaming
  - [ ] Create methods for continuous updates
  - [ ] Maintain phase-based methods for compatibility

## 7. View Layer Adaptation

- [ ] Update views to support both traditional and streaming approaches
  - [ ] Enhance `ChoirThreadDetailView.swift` for streaming
  - [ ] Modify `MessageRow.swift` to handle partial content
  - [ ] Update thread components for streaming:
    - [ ] Enhance `ThreadInputBar.swift` with streaming controls
    - [ ] Adapt `ThreadMessageList.swift` for continuous updates

## 8. Testing Strategy

- [ ] Create tests for streaming functionality
  - [ ] Test traditional phase-based approach
  - [ ] Test streaming implementation
  - [ ] Verify backward compatibility
- [ ] Implement feature flag tests
  - [ ] Test functionality with flags enabled/disabled
  - [ ] Verify seamless switching between modes

## 9. Incremental Deployment Phases

### Phase 1: Consistent Naming
- [x] Rename all Chorus Cycle components to PostChain
  - [x] Update `ChorusModels.swift` to `PostchainModels.swift`
  - [x] Rename `ChorusCoordinator.swift` to `PostchainCoordinator.swift`
  - [x] Update `RESTChorusCoordinator.swift` to `RESTPostchainCoordinator.swift`
  - [x] Rename `MockChorusCoordinator.swift` to `MockPostchainCoordinator.swift`
  - [x] Update `ChorusAPIClient.swift` to `PostchainAPIClient.swift`
  - [x] Rename `ChorusViewModel.swift` to `PostchainViewModel.swift`
  - [x] Update `ChorusCycleView.swift` to `PostchainView.swift`
- [x] Update references throughout codebase
  - [x] Updated ContentView.swift
  - [x] Updated ChoirThreadDetailView.swift
  - [x] Updated MessageRow.swift
  - [x] Updated ThreadMessageList.swift
  - [x] Updated tests
- [ ] Ensure all tests pass with renamed components

### Phase 2: Foundation & Models
- [ ] Implement feature flags
- [ ] Enhance data models for streaming compatibility 
- [ ] Create initial tests for dual-mode functionality

### Phase 3: API Layer Enhancement
- [ ] Update API client with streaming support
- [ ] Enhance coordinator layer
- [ ] Add connection management and error handling

### Phase 4: ViewModel & View Layer Adaptation  
- [ ] Refactor ViewModel for streaming
- [ ] Update views for continuous content
- [ ] Add streaming-specific UI elements

### Phase 5: Testing & Optimization
- [ ] Comprehensive testing across devices
- [ ] Performance profiling
- [ ] Refine streaming experience

### Phase 6: Progressive Rollout
- [ ] Enable by default for development
- [ ] Gradual production rollout
- [ ] Monitor for issues and iterate

## 10. Final Consolidation

- [ ] Once streaming is proven stable:
  - [ ] Remove feature flag checks
  - [ ] Clean up any legacy code
  - [ ] Remove backward compatibility layers
  - [ ] Optimize for streaming-only operation

## Success Criteria

- [ ] Seamless transition from phase-based to streaming implementation
- [ ] Improved performance with streaming approach
- [ ] Better user experience with real-time updates
- [ ] No regression in existing functionality
- [ ] Clean, maintainable code structure