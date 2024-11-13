# Thread Contract Implementation

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: [Thread State Management](issue_5.md)
- Related to: [Message Rewards Implementation](issue_12.md)

## Description
Implement the thread contract that manages thread state evolution, stake requirements, and co-author relationships using the quantum harmonic oscillator model.

## Current State
- Have thread state in Qdrant
- Need stake mechanics
- Need temperature evolution
- Need co-author management

## Tasks
- [ ] Implement thread state
  ```swift
  struct ThreadState {
      let id: UUID
      let coAuthors: Set<PublicKey>
      let tokenBalance: TokenAmount
      let temperature: Float
      let frequency: Float
      let messageHashes: [Hash]
      let createdAt: Date

      // E(n) = ℏω(n + 1/2)
      var stakeRequirement: TokenAmount {
          let n = coAuthors.count
          let ω = frequency
          return TokenAmount(ℏ * ω * (Float(n) + 0.5))
      }
  }
  ```

- [ ] Add temperature evolution
  ```swift
  extension ThreadState {
      // T = T0/√(1 + t/τ)
      mutating func evolveTemperature(timeDelta: TimeInterval) {
          let coolingFactor = sqrt(1000 + timeDelta / 86400)
          temperature = (temperature * 1000) / coolingFactor
      }

      // Update after message approval/denial
      mutating func processApproval(_ approved: Bool) {
          if approved {
              // Distribute energy to co-authors
              temperature = tokenBalance / Float(coAuthors.count)
          } else {
              // Increase thread energy
              temperature += stakeRequirement.amount
          }
      }
  }
  ```

- [ ] Implement co-author management
  ```swift
  extension ThreadState {
      mutating func addCoAuthor(_ publicKey: PublicKey) throws {
          guard tokenBalance >= stakeRequirement else {
              throw ThreadError.insufficientStake
          }
          coAuthors.insert(publicKey)
      }

      func validateMessage(_ message: Message) -> Bool {
          coAuthors.contains(message.authorId)
      }
  }
  ```

## Testing Requirements
- Test state evolution
  - Temperature cooling
  - Stake requirements
  - Co-author management
- Test message validation
  - Author verification
  - Stake verification
  - Temperature effects
- Test error handling
  - Invalid stakes
  - Unauthorized authors
  - State transitions

## Success Criteria
- Clean state management
- Proper stake mechanics
- Reliable temperature evolution
- Type-safe operations
