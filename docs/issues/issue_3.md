# Coordinator Message Flow

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [API Client Message Handling](issue_2.md)
- Blocks: [Thread State Management](issue_5.md)
- Related to: [Message Type Reconciliation](issue_1.md)

## Description
Update RESTChorusCoordinator to handle the complete message lifecycle using the new unified type system while maintaining compatibility with the existing chorus cycle phases.

## Current State
- Have working RESTChorusCoordinator
- Using phase-specific response types
- Need to integrate MessagePoint/ThreadMessage
- Need to maintain phase results

## Tasks
- [ ] Update coordinator state
  - [ ] Add MessagePoint handling
  - [ ] Manage ThreadMessage state
  - [ ] Track phase results
- [ ] Implement message lifecycle
  - [ ] Initial message creation
  - [ ] Phase processing
  - [ ] Result accumulation
  - [ ] Final state updates
- [ ] Add thread integration
  - [ ] Thread state updates
  - [ ] Message synchronization
  - [ ] History management
- [ ] Handle errors and cancellation
  - [ ] Phase-specific errors
  - [ ] State cleanup
  - [ ] Graceful cancellation

## Code Examples
```swift
@MainActor
class RESTChorusCoordinator: ChorusCoordinator {
    // State management
    private(set) var currentMessage: ThreadMessage?
    private(set) var currentPhase: Phase = .action
    private(set) var phaseResults: [Phase: BaseResponse] = [:]

    // Process message through phases
    func process(_ input: String) async throws {
        // Create initial message
        let messagePoint = MessagePoint(
            id: UUID().uuidString,
            content: input,
            threadId: threadId,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            role: "user",
            step: Phase.action.rawValue
        )

        // Process through phases
        currentMessage = ThreadMessage(from: messagePoint)

        do {
            // Action phase
            currentPhase = .action
            let actionResponse = try await processAction(input)
            phaseResults[.action] = actionResponse

            // Experience phase with context
            currentPhase = .experience
            let experienceResponse = try await processExperience(
                input,
                context: currentMessage
            )
            phaseResults[.experience] = experienceResponse

            // Continue through phases...

            // Update final state
            currentMessage?.chorusResult = ChorusCycleResult(
                action: phaseResults[.action] as? ActionResponse,
                experience: phaseResults[.experience] as? ExperienceResponseData,
                // ... other phases
            )

            // Store final message
            try await api.storeMessage(messagePoint)

        } catch {
            // Handle errors while maintaining state consistency
            phaseResults[currentPhase] = BaseResponse(
                step: currentPhase.rawValue,
                content: "Error: \(error.localizedDescription)",
                confidence: 0.0,
                reasoning: "Phase failed"
            )
            throw error
        }
    }

    // Support cancellation
    func cancel() {
        // Cleanup state
        currentPhase = .action
        phaseResults.removeAll()
    }
}
```

## Testing Requirements
- Test phase progression
  - State transitions
  - Result accumulation
  - Error handling
- Verify message lifecycle
  - Creation
  - Processing
  - Storage
- Test cancellation
  - State cleanup
  - Resource release
  - Error propagation

## Success Criteria
- Clean state transitions
- Proper error handling
- Type-safe operations
- Reliable cancellation
