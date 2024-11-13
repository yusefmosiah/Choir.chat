# Core Message System Implementation

## Overview
Implement the foundational message system that reconciles our Swift types with Qdrant storage, enables user identity, and manages thread state. Focus on clean type system that supports existing ~20k message points while enabling future features.

## Sub-Issues
1. [Message Type Reconciliation](issue_1.md) - Reconcile ChorusModels with Qdrant
2. [API Client Message Handling](issue_2.md) - Update client for new types
3. [Coordinator Message Flow](issue_3.md) - Handle message lifecycle
4. [User Identity Implementation](issue_4.md) - Basic key management
5. [Thread State Management](issue_5.md) - Local state with sync
6. [Integration Testing Suite](issue_6.md) - End-to-end validation

## Dependencies
- Existing Qdrant setup (~20k message points)
- Current `ChorusModels.swift` with response types
- Python API endpoints
- Working collections (messages, users, threads)

## Architecture Decisions
1. Message Storage
   - Points stored in Qdrant with vectors
   - Full message history in payload
   - Support for legacy points

2. State Management
   - Local thread state in Swift
   - Sync with Qdrant as source of truth
   - Clean type conversion

3. Identity System
   - Public keys as user IDs
   - UserDefaults for development
   - Simple key management

4. API Design
   - Stateless endpoints
   - Type-safe requests/responses
   - Graceful error handling

## Success Metrics
1. Type System
   - Clean conversion between Swift/Qdrant
   - Support for legacy points
   - Type-safe operations

2. Message Flow
   - Reliable message handling
   - Proper state management
   - Error resilience

3. Testing
   - Comprehensive test suite
   - Performance validation
   - Error scenario coverage
