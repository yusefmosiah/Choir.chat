# Message Rewards Implementation

## Parent Issue
[Core Client-Side Implementation](issue_0.md)

## Description
Implement the quantum harmonic oscillator model for message rewards and prior citations, ensuring proper token distribution and stake requirements.

## Tasks

### 1. Message Rewards
```swift
struct RewardCalculator {
    // E(n) = ℏω(n + 1/2)
    func calculateStakeRequirement(thread: Thread) -> TokenAmount {
        let n = thread.coAuthors.count
        let ω = thread.frequency
        return TokenAmount(ℏ * ω * (Float(n) + 0.5))
    }

    // R(t) = R_total × k/(1 + kt)ln(1 + kT)
    func calculateMessageReward(timestamp: Date) -> TokenAmount {
        let t = timestamp.timeIntervalSince(LAUNCH_DATE)
        let k = DECAY_CONSTANT
        let T = TOTAL_PERIOD
        return TokenAmount(TOTAL_SUPPLY * (k / (1 + k * t)) * log(1 + k * T))
    }
}
```

### 2. Prior Citations
```swift
func calculatePriorValue(
    quality: Float,
    totalQuality: Float,
    treasuryBalance: TokenAmount
) -> TokenAmount {
    // V(p) = B_t × Q(p)/∑Q(i)
    return TokenAmount(treasuryBalance.value * (quality / totalQuality))
}
```

## Success Criteria
- Rewards calculated correctly
- Prior citations valued properly
- Token distribution working
- State transitions verified
