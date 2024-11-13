# Message Type Reconciliation

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: None
- Blocks: [API Client Message Handling](issue_2.md)
- Related to: [Coordinator Message Flow](issue_3.md)

## Description
Reconcile existing `ChorusModels.swift` response types with Qdrant schema, ensuring backward compatibility with ~20k existing message points while enabling future features.

## Current State
- Have `ChorusModels.swift` with:
  - Base response types
  - Phase-specific responses
  - Supporting types (Prior, Pattern)
- ~20k points in Qdrant
- Need unified message type system

## Tasks
- [ ] Create `MessagePoint` struct matching Qdrant schema
  - [ ] Support all required fields
  - [ ] Handle optional fields
  - [ ] Add chorus result support
- [ ] Implement `ThreadMessage` for UI state
  - [ ] Convert from MessagePoint
  - [ ] Handle UI-specific state
- [ ] Add graceful decoding for legacy points
  - [ ] Default values for missing fields
  - [ ] Validation logic
- [ ] Add conversion tests
  - [ ] Legacy point handling
  - [ ] Full message conversion
  - [ ] Error cases

## Code Examples
```swift
// Message point matching Qdrant schema
struct MessagePoint: Codable {
    let id: String
    let content: String
    let threadId: String
    let createdAt: String
    let role: String?
    let step: String?
    let chorusResult: ChorusCycleResult?

    // Graceful decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        threadId = try container.decode(String.self, forKey: .threadId)
        createdAt = try container.decode(String.self, forKey: .createdAt)

        // Optional fields with empty defaults
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? ""
        step = try container.decodeIfPresent(String.self, forKey: .step) ?? ""
        chorusResult = try container.decodeIfPresent(ChorusCycleResult.self, forKey: .chorusResult)
    }
}
```

## Testing Requirements
- Test decoding of legacy points
  - Missing optional fields
  - Different date formats
  - Invalid data
- Verify conversion to ThreadMessage
  - All fields mapped correctly
  - UI state initialized properly
- Validate chorus result handling
  - All phase responses
  - Missing phases
  - Invalid data

## Success Criteria
- Clean type conversion
- Backward compatibility
- Comprehensive test coverage
- Clear error handling
