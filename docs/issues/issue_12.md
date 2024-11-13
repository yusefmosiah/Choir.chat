# Message Rewards Implementation
## THE FORMULAS LOOK DIFFERENT THAN THE ONES IN THE DOCS. THE MATH BETTER BE MATHING.


## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Message Type Reconciliation](issue_1.md)
- Related to: [Thread State Management](issue_5.md)
- Blocks: None

## Description
Implement the message rewards system using the quantum harmonic oscillator model for new messages and prior citations.

## Current State
- Have formulas defined:
  ```
  New Message Rewards:
  R(t) = R_total × k/(1 + kt)ln(1 + kT)

  Prior Value:
  V(p) = B_t × Q(p)/∑Q(i)
  ```
- Need implementation in Swift
- Need integration with thread state

## Tasks
- [ ] Implement reward calculations
  - [ ] New message rewards
  - [ ] Prior citation rewards
  - [ ] Quality scoring
- [ ] Add reward distribution
  - [ ] Treasury management
  - [ ] User balance updates
  - [ ] Transaction logging
- [ ] Integrate with thread state
  - [ ] Track rewards per message
  - [ ] Update thread temperature
  - [ ] Handle stake requirements

## Code Examples
```swift
struct RewardCalculator {
    // Constants
    static let TOTAL_SUPPLY: Double = 2.5e9  // 2.5B total
    static let DECAY_CONSTANT: Double = 2.04
    static let TOTAL_PERIOD: TimeInterval = 4 * 365 * 24 * 3600  // 4 years

    // New message rewards
    func calculateMessageReward(at timestamp: Date) -> Double {
        let t = timestamp.timeIntervalSince(LAUNCH_DATE)
        let k = DECAY_CONSTANT
        let T = TOTAL_PERIOD

        return TOTAL_SUPPLY * (k / (1 + k * t)) * log(1 + k * T)
    }

    // Prior citation rewards
    func calculatePriorValue(
        quality: Double,
        totalQuality: Double,
        treasuryBalance: Double
    ) -> Double {
        return treasuryBalance * (quality / totalQuality)
    }
}

actor RewardManager {
    private let calculator: RewardCalculator
    private var treasuryBalance: Double

    func processNewMessage(_ message: MessagePoint) async throws -> Double {
        let reward = calculator.calculateMessageReward(at: message.createdAt)
        try await distributeReward(reward, to: message.authorId)
        return reward
    }

    func processPriorCitation(
        _ prior: Prior,
        quality: Double,
        totalQuality: Double
    ) async throws -> Double {
        let value = calculator.calculatePriorValue(
            quality: quality,
            totalQuality: totalQuality,
            treasuryBalance: treasuryBalance
        )
        try await distributePriorReward(value, to: prior.authorId)
        return value
    }
}
```

## Testing Requirements
- Test reward calculations
  - Verify formula implementation
  - Test edge cases
  - Check decay over time
- Test distribution
  - Treasury management
  - Balance updates
  - Transaction integrity
- Test integration
  - Thread state updates
  - User balance changes
  - System coherence

## Success Criteria
- Accurate calculations
- Reliable distribution
- Clean integration
- Type-safe implementation
