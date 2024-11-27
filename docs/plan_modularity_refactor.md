# Choir Modularity Refactor Plan

## Goals
- Break monolithic architecture into clear modules
- Simplify state management
- Maintain existing functionality
- Create foundation for future enhancements

## Phase 1: Core Domain Models
- [ ] Create MessageStore module
  - [ ] Define MessageStore protocol
  - [ ] Create basic in-memory implementation
  - [ ] Add message CRUD operations
  - [ ] Add thread management
  - [ ] Add observation/subscription capabilities

- [ ] Create ChorusService module
  - [ ] Define ChorusService protocol
  - [ ] Extract chorus cycle logic from RESTChorusCoordinator
  - [ ] Create clean async API for phase processing
  - [ ] Add proper error handling
  - [ ] Add logging/debugging support

## Phase 2: Network Layer
- [ ] Refactor APIClient
  - [ ] Create APIClient protocol
  - [ ] Simplify request/response handling
  - [ ] Add proper error types
  - [ ] Add request/response logging
  - [ ] Add retry logic
  - [ ] Add request cancellation

- [ ] Create NetworkModels
  - [ ] Separate API models from domain models
  - [ ] Create clear mapping layer
  - [ ] Add validation
  - [ ] Add proper Codable implementations

## Phase 3: State Management
- [ ] Create AppState module
  - [ ] Define core state container
  - [ ] Add thread state management
  - [ ] Add message state management
  - [ ] Add UI state management
  - [ ] Add proper state observation

- [ ] Create StateContainer
  - [ ] Implement observable state pattern
  - [ ] Add state update middleware
  - [ ] Add state persistence hooks
  - [ ] Add state restoration

## Phase 4: ViewModels
- [ ] Create ThreadViewModel
  - [ ] Move thread logic from ChorusViewModel
  - [ ] Add thread state management
  - [ ] Add message handling
  - [ ] Add UI state

- [ ] Create MessageViewModel
  - [ ] Move message logic from ChorusViewModel
  - [ ] Add message state management
  - [ ] Add phase handling
  - [ ] Add UI state

- [ ] Create ChorusViewModel
  - [ ] Simplify to pure UI state
  - [ ] Remove coordinator dependency
  - [ ] Add proper state binding
  - [ ] Add error handling

## Phase 5: Views
- [ ] Refactor MessageRow
  - [ ] Remove direct state management
  - [ ] Use view model exclusively
  - [ ] Simplify UI updates
  - [ ] Add proper animations

- [ ] Refactor ChorusCycleView
  - [ ] Remove direct state management
  - [ ] Use view model exclusively
  - [ ] Improve phase transitions
  - [ ] Add proper animations

- [ ] Refactor ThreadDetailView
  - [ ] Remove direct state management
  - [ ] Use view model exclusively
  - [ ] Improve message handling
  - [ ] Add proper scroll behavior

## Phase 6: Testing
- [ ] Add MessageStore tests
  - [ ] Test CRUD operations
  - [ ] Test thread management
  - [ ] Test state updates
  - [ ] Test error cases

- [ ] Add ChorusService tests
  - [ ] Test phase processing
  - [ ] Test error handling
  - [ ] Test cancellation
  - [ ] Test edge cases

- [ ] Add ViewModel tests
  - [ ] Test state management
  - [ ] Test user interactions
  - [ ] Test error handling
  - [ ] Test edge cases

## Phase 7: Integration
- [ ] Create DependencyContainer
  - [ ] Add service registration
  - [ ] Add proper initialization
  - [ ] Add state restoration
  - [ ] Add proper cleanup

- [ ] Update App initialization
  - [ ] Use dependency injection
  - [ ] Add proper state setup
  - [ ] Add error handling
  - [ ] Add logging

## Phase 8: Cleanup
- [ ] Remove old coordinator pattern
  - [ ] Migrate remaining functionality
  - [ ] Update dependencies
  - [ ] Remove unused code
  - [ ] Update documentation

- [ ] Final testing
  - [ ] End-to-end testing
  - [ ] Performance testing
  - [ ] UI testing
  - [ ] Documentation review

## Success Criteria
1. Clear module boundaries
2. Simplified state management
3. Improved testability
4. Maintained functionality
5. Better error handling
6. Improved performance
7. Clear upgrade path

## Notes
- Each phase should be completed and tested before moving to next
- Keep existing functionality working throughout refactor
- Add proper logging/debugging support
- Document architectural decisions
- Create migration guides for each phase
