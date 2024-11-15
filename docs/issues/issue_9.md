# State Recovery & Persistence

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread State Management](issue_5.md)
- Related to: [Coordinator Message Flow](issue_3.md)
- Critical for: Chorus Cycle coherence

## Description
Implement state recovery and persistence to maintain Chorus cycle coherence across app lifecycle events (termination, suspension, memory pressure). This isn't just about convenience - it's about preserving the integrity of the cycle's context and phase state.

## Core Requirements
1. Phase State Preservation
   - Save current phase (AEIOU-Y)
   - Preserve phase-specific context
   - Enable clean phase resumption
   - Maintain cycle coherence

2. Thread Context Continuity
   - Save full conversation context
   - Preserve message relationships
   - Maintain semantic connections
   - Enable coherent continuation

3. Cycle Integrity
   - Handle interruptions gracefully
   - Preserve cycle momentum
   - Maintain context relevance
   - Enable natural resumption

## Context Management & Summarization

1. Progressive Summarization
```swift
actor ContextManager {
    // Maintain sliding window of full context
    private var recentMessages: [MessagePoint]
    // Keep compressed summaries of older context
    private var historicalSummaries: [ContextSummary]

    struct ContextSummary: Codable {
        let timespan: DateInterval
        let keyPoints: [String]
        let semanticMarkers: [String: Float]
        let threadState: ThreadStateSnapshot

        // Link to full context if needed
        let archiveReference: String
    }

    func updateContext(_ newMessage: MessagePoint) async throws {
        // Add to recent messages
        recentMessages.append(newMessage)

        // Check if we need to summarize older messages
        if recentMessages.count > Constants.maxRecentMessages {
            try await compressOlderContext()
        }
    }

    private func compressOlderContext() async throws {
        let toCompress = recentMessages.prefix(Constants.compressionBatchSize)

        // Generate summary using AI
        let summary = try await generateContextSummary(toCompress)

        // Archive full messages for potential recovery
        try await archiveMessages(toCompress)

        // Update state
        historicalSummaries.append(summary)
        recentMessages.removeFirst(Constants.compressionBatchSize)
    }
}
```

2. Context Recovery
```swift
extension ContextManager {
    func recoverContext() async throws -> ThreadContext {
        // Start with recent messages
        var context = ThreadContext(messages: recentMessages)

        // Add relevant summaries
        for summary in historicalSummaries.reversed() {
            if await isRelevantToCurrentPhase(summary) {
                context.addSummary(summary)
            }

            // Stop if we have enough context
            if await context.isSufficient {
                break
            }
        }

        // If needed, fetch archived messages
        if !context.isSufficient {
            try await expandContext(context)
        }

        return context
    }

    private func expandContext(_ context: ThreadContext) async throws {
        // Identify gaps that need expansion
        let gaps = await context.findContextGaps()

        // Fetch archived messages for important gaps
        for gap in gaps {
            if await isGapCritical(gap) {
                let archived = try await fetchArchivedMessages(for: gap)
                context.fillGap(gap, with: archived)
            }
        }
    }
}
```

3. Semantic Continuity
```swift
struct SemanticMarker: Codable {
    let concept: String
    let strength: Float
    let firstMention: Date
    let recentMentions: [Date]

    var isActive: Bool {
        // Check if concept is still relevant
        Date().timeIntervalSince(recentMentions.last ?? firstMention) < Constants.conceptTimeout
    }
}

extension ContextManager {
    func maintainSemanticContinuity() async throws {
        // Track key concepts through summarization
        var activeMarkers = [SemanticMarker]()

        for message in recentMessages {
            let concepts = try await extractConcepts(from: message)
            try await updateMarkers(activeMarkers, with: concepts)
        }

        // Ensure summaries preserve important markers
        for marker in activeMarkers where marker.isActive {
            try await ensureMarkerPreserved(marker)
        }
    }
}
```

## Tasks
- [ ] Implement phase state persistence
  ```swift
  struct PhaseState: Codable {
      let phase: Phase
      let context: [MessagePoint]
      let intermediateResults: [String: Any]
      let timestamp: Date

      // Recovery metadata
      let cycleId: UUID
      let continuityMarkers: [String: String]
  }
  ```

- [ ] Add thread state recovery
  ```swift
  actor ThreadRecovery {
      func saveState(_ thread: Thread) async throws {
          let state = ThreadState(
              messages: thread.messages,
              currentPhase: thread.currentPhase,
              phaseState: thread.phaseState,
              contextualLinks: thread.contextualLinks
          )
          try await persistState(state)
      }

      func recoverThread(_ id: ThreadID) async throws -> Thread {
          guard let state = try await loadState(id) else {
              throw RecoveryError.stateNotFound
          }
          return try await rebuildThread(from: state)
      }
  }
  ```

- [ ] Implement cycle recovery logic
  ```swift
  extension ChorusCoordinator {
      func recoverCycle() async throws {
          let state = try await loadPhaseState()

          // Validate cycle integrity
          guard await validateCycleCoherence(state) else {
              throw CycleError.coherenceLost
          }

          // Restore phase context
          currentPhase = state.phase
          phaseContext = state.context

          // Resume cycle
          try await resumeCycle(from: state)
      }
  }
  ```

## Testing Requirements
1. Cycle Coherence
   - Test interruption at each phase
   - Verify context preservation
   - Check semantic continuity
   - Validate cycle resumption

2. State Recovery
   - Test app termination scenarios
   - Verify memory pressure handling
   - Check background task completion
   - Validate state reconstruction

3. User Experience
   - Verify seamless resumption
   - Test context continuity
   - Check interaction flow
   - Validate recovery UX

4. Context Management
   - Test progressive summarization
   - Verify semantic preservation
   - Check marker continuity
   - Validate context recovery
   - Test gap identification and filling

5. Summary Quality
   - Verify information preservation
   - Test semantic marker tracking
   - Check summary relevance
   - Validate compression ratios
   - Test recovery from summaries

## Success Criteria
- Maintains cycle coherence across interruptions
- Preserves semantic context
- Enables natural conversation flow
- Handles lifecycle events gracefully
- Provides seamless user experience
- Maintains semantic continuity through summarization
- Efficiently manages context depth vs. breadth
- Preserves critical information in summaries
- Enables smart context recovery
- Handles context gaps gracefully

## Code Examples
```swift
actor StateManager {
    func saveState() async throws {
        let state = AppState(
            currentThread: currentThread,
            currentMessage: currentMessage,
            phaseResults: phaseResults
        )
        try await persistState(state)
    }

    func recoverState() async throws {
        guard let state = try await loadPersistedState() else {
            return
        }
        // Restore state...
    }
}
