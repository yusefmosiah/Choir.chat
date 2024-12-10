# Chorus Cycle Refactoring Plan

## Overview
This document outlines the plan to refactor the Chorus Cycle implementation to improve its concurrency model, state management, and error handling. The refactoring will be done in phases to maintain stability.

## Phase 1: Actor Model Implementation
### Goals
- Convert `RESTChorusCoordinator` from a class to an actor
- Implement proper actor isolation
- Remove `@Published` properties in favor of actor state

### Changes Required
1. `ChorusCoordinator.swift`:
```swift
protocol ChorusCoordinator: Actor {
    // Async properties
    var currentPhase: Phase { get async }
    var responses: [Phase: String] { get async }
    var isProcessing: Bool { get async }

    // Async sequences for live updates
    var currentPhaseSequence: AsyncStream<Phase> { get }
    var responsesSequence: AsyncStream<[Phase: String]> { get }
    var isProcessingSequence: AsyncStream<Bool> { get }

    // Core processing
    func process(_ input: String) async throws
    func cancel()
}
```

2. `RESTChorusCoordinator.swift`:
```swift
actor RESTChorusCoordinator: ChorusCoordinator {
    private let api: ChorusAPIClient
    private var state: ChorusState

    // Stream management
    private let phaseStream: AsyncStream<Phase>
    private let responsesStream: AsyncStream<[Phase: String]>
    private let processingStream: AsyncStream<Bool>

    // Stream continuations
    private var phaseContinuation: AsyncStream<Phase>.Continuation?
    private var responsesContinuation: AsyncStream<[Phase: String]>.Continuation?
    private var processingContinuation: AsyncStream<Bool>.Continuation?
}
```

## Phase 2: State Management
### Goals
- Extract state management into a dedicated type
- Implement proper state transitions
- Add state validation

### Changes Required
1. Create `ChorusState.swift`:
```swift
actor ChorusState {
    private(set) var currentPhase: Phase
    private(set) var responses: [Phase: String]
    private(set) var isProcessing: Bool
    private(set) var phaseResponses: PhaseResponses

    struct PhaseResponses {
        var action: ActionResponse?
        var experience: ExperienceResponse?
        var intention: IntentionResponse?
        var observation: ObservationResponse?
        var understanding: UnderstandingResponse?
        var yield: YieldResponse?
    }

    func transition(to phase: Phase) async
    func updateResponse(_ response: String, for phase: Phase) async
    func setProcessing(_ isProcessing: Bool) async
}
```

## Phase 3: API Client Refactoring
### Goals
- Convert `ChorusAPIClient` to an actor
- Implement proper error handling
- Add request/response logging
- Add retry logic for transient failures

### Changes Required
1. Update `ChorusAPIClient.swift`:
```swift
actor ChorusAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let retryPolicy: RetryPolicy

    func post<T: Codable, R: Codable>(
        endpoint: String,
        body: T,
        retries: Int = 3
    ) async throws -> R
}
```

## Phase 4: Error Handling
### Goals
- Implement structured error types
- Add error recovery mechanisms
- Improve error reporting

### Changes Required
1. Create `ChorusError.swift`:
```swift
enum ChorusError: Error {
    case networkError(URLError)
    case cancelled
    case phaseError(Phase, Error)
    case invalidState(String)
    case apiError(APIError)

    var isRetryable: Bool
    var shouldResetState: Bool
}
```

## Phase 5: Testing Infrastructure
### Goals
- Add unit tests for actor behavior
- Add integration tests for state transitions
- Add stress tests for concurrency

### Changes Required
1. Create new test files:
- `ChorusCoordinatorTests.swift`
- `ChorusStateTests.swift`
- `ChorusAPIClientTests.swift`
- `ConcurrencyStressTests.swift`

## Implementation Order
1. Phase 1: Actor Model Implementation
   - This is the foundation for all other changes
   - Requires careful migration to maintain existing functionality

2. Phase 2: State Management
   - Build on actor model to implement proper state handling
   - Can be done incrementally while maintaining backward compatibility

3. Phase 3: API Client Refactoring
   - Improve network layer reliability
   - Can be done in parallel with state management

4. Phase 4: Error Handling
   - Implement once new architecture is stable
   - Add recovery mechanisms for each type of failure

5. Phase 5: Testing Infrastructure
   - Add tests as each component is refactored
   - Final comprehensive test suite

## Migration Strategy
1. Create new actor-based implementations alongside existing code
2. Gradually migrate functionality, one phase at a time
3. Use feature flags to control rollout
4. Maintain backward compatibility until migration is complete
5. Remove old implementation once new system is proven stable

## Validation Criteria
- All existing functionality must work as before
- Performance metrics must be maintained or improved
- Error handling must be more robust
- Test coverage must be comprehensive
- Documentation must be updated to reflect new architecture
