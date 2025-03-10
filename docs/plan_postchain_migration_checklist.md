# PostChain Migration Checklist - REVISED

This document outlines a revised radical approach for migrating the SwiftUI client application from the Chorus Cycle to the PostChain Streaming API. After initial incremental attempts, we've determined that a more decisive cutting approach is needed to eliminate legacy patterns.

## Migration Philosophy - REVISED

- **ELIMINATE ALL LEGACY CODE**: Aggressively remove Chorus Cycle patterns and dead code
- **SIMPLIFY ARCHITECTURE**: Focus on a clean, direct streaming implementation
- **SINGLE MODEL**: Use one consistent data model for phases instead of separate response types
- **DELETE TEST CLUTTER**: Remove all test views/files that are not helping the migration
- **FOCUS ON CORE FLOW**: Prioritize the main user flow over edge cases

## 1. Consistent Naming Migration

- [x] Rename all Chorus Cycle components to PostChain consistently
  - [x] Update `ChorusModels.swift` to `PostchainModels.swift`
  - [x] Rename `ChorusCoordinator.swift` to `PostchainCoordinator.swift`
  - [x] Update `RESTChorusCoordinator.swift` to `RESTPostchainCoordinator.swift`
  - [x] Rename `MockChorusCoordinator.swift` to `MockPostchainCoordinator.swift`
  - [x] Update `ChorusAPIClient.swift` to `PostchainAPIClient.swift`
  - [x] Rename `ChorusViewModel.swift` to `PostchainViewModel.swift`
  - [x] Update `ChorusCycleView.swift` to `PostchainView.swift`
- [x] Update references throughout the codebase
  - [x] Refactor import statements
  - [x] Update class/protocol references
  - [x] Fix function calls and property references
- [x] Update comments and documentation
  - [x] Replace "Chorus Cycle" terminology with "PostChain"
  - [x] Update method and property documentation
- [ ] Ensure all tests pass after renaming

## 2. Backend Structured Outputs

- [x] Create simple_graph.py for initial PostChain implementation
- [x] Define Pydantic data models for PostChain streaming format
  - [x] Create PostchainStreamEvent model with consistent structure
  - [x] Use same field names and structure for client/server compatibility
- [x] Update langchain_utils.py for structured outputs
  - [x] Create new `post_llm` function
  - [x] Add support for structured outputs with response_model parameter
  - [x] Ensure streaming mode works with structured outputs
- [x] Ensure consistent JSON structure in API responses
  - [x] Implement model_dump() for consistent JSON serialization
  - [x] Match Swift client expectations for decoding

## 3. Data Model Adaptation

- [x] Enhance existing models to support streaming
  - [ ] Update `ChoirThread.swift` to handle both traditional and streaming data
  - [x] Enhance `PostchainModels.swift` with streaming-compatible structures
  - [x] Modify `Phase.swift` to accommodate streaming phases
- [x] Add extension methods for conversion between models
  - [x] Create methods to transform streaming data to existing model formats
  - [x] Add backwards-compatibility layers for phase content

## 4. API Client Enhancements

- [x] Enhance `PostchainAPIClient.swift` to support streaming
  - [x] Add streaming endpoint support
  - [x] Implement SSE connection handling
  - [x] Create unified error handling for both approaches
  - [x] Add connection management capabilities for streaming
- [x] Fix streaming issues with structured outputs
  - [x] Update client to decode new structured event format
  - [x] Ensure proper token rendering on client
  - [x] Fix direct viewModel updates for all phases

## 5. Coordinator Layer Updates

- [x] Extend `PostchainCoordinator.swift` protocol
  - [x] Add streaming-specific methods
  - [x] Keep existing methods for backwards compatibility
- [x] Update `RESTPostchainCoordinator.swift` with streaming capability
  - [x] Implement stream processing logic
  - [x] Add state management for continuous updates
  - [x] Maintain phase-based approach as fallback
- [ ] Enhance `MockPostchainCoordinator.swift` for testing
  - [ ] Add streaming simulation capabilities
- [x] Fix content update issues in UI layer
  - [x] Add direct viewModel phase updates in API client
  - [x] Ensure phase transitions are properly tracked

## 6. Backend Cleanup & Consolidation

- [ ] Archive deprecated graph implementations
  - [ ] Move `chorus_graph.py` to archive
  - [ ] Move `postchain_graph.py` to archive
  - [ ] Move `graph.py` to archive
- [ ] Consolidate on simple_graph.py approach
  - [ ] Make simple_graph.py the main implementation
  - [ ] Ensure backward compatibility with existing endpoints
- [ ] Update API documentation to reflect new structure

## 7. ViewModel Refactoring

- [x] Incrementally update `PostchainViewModel.swift`
  - [x] Add streaming state management
  - [x] Implement content buffering for streaming
  - [x] Create methods for continuous updates
  - [x] Maintain phase-based methods for compatibility
  - [x] Fix phase storage to preserve empty phases

## 8. View Layer Adaptation

- [x] Update views to properly render streaming content
  - [x] Fix message rendering in `ChoirThreadDetailView.swift`
  - [x] Ensure proper token streaming in `MessageRow.swift`
  - [x] Fix phase card display in PostchainView
  - [x] Update thread components for streaming:
    - [x] Add phase visibility control in MessageRow
    - [ ] Provide streaming controls in `ThreadInputBar.swift`

## 9. Testing Strategy

- [ ] Create tests for streaming functionality
  - [ ] Test structured output compatibility
  - [ ] Verify client decoding of server responses
- [ ] Implement comprehensive backend tests for simple_graph
  - [ ] Ensure consistent data contract is maintained
  - [ ] Test error handling and edge cases

## 10. Incremental Deployment Phases

### Phase 1: Consistent Naming (COMPLETED)

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

### Phase 2: Backend & Structured Outputs (COMPLETED)

- [x] Create simple_graph.py implementation
- [x] Define data contract with PostchainStreamEvent
- [x] Implement client-side model for structured outputs
- [x] Create post_llm function with structured output support

### Phase 3: Client Streaming Fixes (IN PROGRESS)

- [x] Update PostchainModels.swift to handle structured responses
- [x] Update API client to process structured events
- [x] Fix experience phase display issues
  - [x] Identify empty phase content handling issue in PostchainView
  - [x] Fix phase card rendering conditions
  - [x] Add phase transition logging
  - [x] Add auto-selection of experience phase
  - [x] Fix message storing of phase content
- [ ] Remaining issues:
  - [ ] Ensure phase carousel UI is consistent across all device sizes
  - [ ] Test with more complex streaming scenarios

### Phase 4: Backend Consolidation

- [ ] Archive deprecated files
- [ ] Consolidate on simple_graph.py
- [ ] Update API documentation

### Phase 5: Testing & Optimization

- [ ] Comprehensive testing across devices
- [ ] Performance profiling
- [ ] Refine streaming experience

### Phase 6: Progressive Rollout

- [ ] Enable by default for development
- [ ] Gradual production rollout
- [ ] Monitor for issues and iterate

## 11. RADICAL CUTTING PHASE - HIGHEST PRIORITY

### 11.1 Delete All Test Views (Step 1)

- [x] Remove experimental views that don't help with migration:
  - [x] `/Choir/Views/Thread/Components/SimplePhaseStreamingView.swift` - Delete entirely
  - [x] `/Choir/Views/Thread/Components/PhaseDisplayTestView.swift` - Delete entirely
  - [x] `/Choir/Views/Thread/Components/TokenByTokenView.swift` - Delete entirely
  - [x] `/Choir/Views/Thread/Components/RealTimeStreamingView.swift` - Delete entirely
  - [x] `/Choir/Views/StreamingTestsView.swift` - Delete entirely
  - [x] `/Choir/Views/StreamingSSEView.swift` - Delete if exists

### 11.2 Purge Legacy Models (Step 2)

- [x] Clean up `/Choir/Models/PostchainModels.swift`:
  - [x] Delete all structs ending with `ResponseData` (ExperienceResponseData, etc.)
  - [x] Delete all `RequestBody` types (ActionRequestBody, ExperienceRequestBody, etc.)
  - [x] Delete all old response type aliases (ActionAPIResponse, ExperienceAPIResponse, etc.)
  - [x] Keep only the new PostchainStreamEvent and related structures
  - [x] Keep SimplePostchainRequestBody but simplify it

### 11.3 Simplify Coordinator (Step 3)

- [x] Clean up `/Choir/Coordinators/RESTPostchainCoordinator.swift`:
  - [x] Delete all individual phase handling methods
  - [x] Remove all phase-specific response objects
  - [x] Simplify to focus only on streaming response path
  - [x] Remove redundant code between phases
  - [x] Ensure single path for processing phase responses

### 11.4 Clean API Client (Step 4)

- [x] Simplify `/Choir/Networking/PostchainAPIClient.swift`:
  - [x] Enhance streaming API implementation
  - [x] Improve SSE event handling
  - [x] Make phase parsing more robust
  - [x] Add detailed logging
  - [x] Fix direct view model updates

### 11.5 Fix Core Streaming Issues (Step 5)

- [x] Implement clear streaming path from server to UI:
  - [x] Fix phase transitions in UI
  - [x] Make SSE event parsing more robust
  - [x] Fix handling of empty phase content
  - [x] Add consistent flow tracing with logging
  - [x] Debug multi-phase transitions

## 12. Core Streaming Implementation Plan

Recent fixes have addressed many of the core streaming implementation issues:

### 12.1 Backend Foundation

- [x] Verify `simple_graph.py` in API correctly sends both phases:
  - [x] Generate action phase content and send structured events
  - [x] Generate experience phase content and send structured events
  - [x] Add clear transition markers between phases
  - [x] Log all content and events sent to client

### 12.2 API Client Implementation

- [x] Enhance streaming handler in PostchainAPIClient.swift:
  - [x] Fix direct viewModel updates for all phases
  - [x] Ensure proper SSE event handling with clean buffer management
  - [x] Handle phase transitions correctly with explicit events
  - [x] Map phase strings to Phase enum consistently
  - [x] Add comprehensive logging for debugging

### 12.3 Coordinator Simplification

- [x] Improve RESTPostchainCoordinator:
  - [x] Fix phase transition handling
  - [x] Add better phase state tracking
  - [x] Update UI immediately when phase content changes

### 12.4 Direct UI Updates

- [x] Show both phases in PostchainView:
  - [x] Fix empty phase content handling
  - [x] Make phase cards consistently visible
  - [x] Fix phase selection to prioritize experience phase
  - [x] Add logging to track phase visibility issues

## 13. Known Issues & Next Steps

### 13.1 Current Issues

- [x] Experience phase card visibility issues:
  - [x] Debug: Empty phase content is not displayed correctly
  - [x] Debug: Experience phase card may not appear even when data is present
  - [x] Fix: Rendering conditions in PostchainView
  - [x] Fix: Phase tracking in MessageRow
  - [x] Fix: Empty content preservation in Message

### 13.2 Next Steps

- [ ] Refine phase transitions in carousel:
  - [ ] Add subtle animation when switching phases
  - [ ] Improve indicator for available phases
  - [ ] Consider adding swipe hints for users
- [ ] Optimize message storage:
  - [ ] Review Message model structure for efficiency
  - [ ] Consider lazy-loading phase content
- [ ] Cleanup code post-fixes:
  - [ ] Remove redundant debugging statements
  - [ ] Extract consistent logging patterns
  - [ ] Document new patterns for future reference

## 14. SwiftUI Architecture Improvements

### 14.1 Core Architecture Problems

- [x] Identified critical architecture issues:
  - [x] Multiple sources of truth (duplicated state)
  - [x] Manual UI refreshes with objectWillChange.send()
  - [x] Cyclical dependencies (coordinator/viewModel)
  - [x] Fighting against SwiftUI's reactive system

### 14.2 Proper SwiftUI Architecture Plan

- [ ] Implement a clean SwiftUI-native architecture:
  - [ ] **Single Source of Truth**: Create PostchainService to replace coordinator
  - [ ] **Repository Pattern**: Implement ThreadRepository for persistence (libSQL-ready)
  - [ ] **Simplified Data Flow**: Remove circular dependencies
  - [ ] **Leverage SwiftUI Reactivity**: Use @Published properties properly

### 14.3 Implementation Steps

- [ ] Create PostchainService as single source of truth:
  - [ ] Move API client into service as dependency
  - [ ] Use @Published properties for phase state
  - [ ] Implement clean async/await processing
- [ ] Create ThreadRepository for persistence:
  - [ ] Build for future libSQL integration
  - [ ] Manage thread and message storage
  - [ ] Handle message updates through clear interfaces
- [x] Update view layer:
  - [x] Use @ObservedObject and @StateObject consistently
  - [x] Remove manual refresh mechanisms
  - [x] Let SwiftUI's reactivity handle UI updates
- [ ] Use proper dependency injection:
  - [ ] Pass dependencies through constructors
  - [ ] Use environment objects for global state

### 14.4 libSQL Integration Plan

- [ ] Lay groundwork for libSQL persistence:
  - [ ] Add libSQL Swift package dependency to project
  - [ ] Create database schema design document
  - [ ] Implement database models (threads, messages, phases)
- [ ] Create data access layer:
  - [ ] Build repository interfaces for each entity type
  - [ ] Implement CRUD operations with async/await
  - [ ] Add query capabilities for thread history
- [ ] Implement persistence service:
  - [ ] Ensure proper threading/async patterns for database access
  - [ ] Add migration support for schema evolution
  - [ ] Create caching layer for performance
- [ ] Connect to SwiftUI layer:
  - [ ] Maintain reactive updates with database changes
  - [ ] Implement pagination for message history
  - [ ] Add offline support with sync capabilities

## Success Criteria - REVISED

- [x] Both action AND experience phases display correctly
- [ ] Smooth experience with real-time updates across phases
- [x] Clean, maintainable code with minimal duplication
- [x] Single consistent data model for all phases
- [x] Clear streaming path from server to UI
