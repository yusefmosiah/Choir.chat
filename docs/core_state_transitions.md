# Core State Transitions

VERSION core_state_transitions:
invariants: {
"Energy conservation",
"Temperature evolution",
"Frequency coherence"
}
assumptions: {
"Thermodynamic transitions",
"Phase stability",
"Heat flow patterns"
}
docs_version: "0.5.1"

## Core State Transitions

### 1. Thread Creation

Initial state creation follows quantum principles:

```swift
struct ThreadState {
    let coAuthors: [Address]
    let energy: UInt256      // Total thread energy
    let temperature: UInt256  // E/N ratio
    let frequency: UInt256    // Organizational coherence
    let messageHashes: [Hash]
    let createdAt: UInt256
}

func createThread(creator: Address) -> ThreadState {
    return ThreadState(
        coAuthors: [creator],
        energy: 0,            // Ground state
        temperature: T0,      // Initial temperature
        frequency: ω0,        // Initial frequency
        messageHashes: [],
        createdAt: timestamp
    )
}
```

### 2. Message Submission

Message submission follows energy quantization:

```swift
func submitMessage(content: String, thread: ThreadState) -> MessageSubmission {
    // Energy Requirements using quantum harmonic oscillator
    let ω = thread.frequency
    let T = thread.temperature
    let requiredStake = calculateStakeRequirement(ω, T)

    // E(n) = ℏω(n + 1/2)
    let messageHash = hash(content)

    return MessageSubmission(
        hash: messageHash,
        stake: requiredStake,
        energy: calculateEnergy(thread.frequency, thread.tokenBalance)
    )
}
```

### 3. Approval Processing

State evolution through approval decisions:

```swift
enum ApprovalOutcome {
    case reject     // Temperature increases
    case split      // Energy splits between treasury and thread
    case approve    // Energy distributes to approvers
}

func processApproval(decision: ApprovalOutcome, thread: inout ThreadState) {
    switch decision {
    case .reject:
        // Temperature increases through energy conservation
        thread.energy += stakeAmount
        thread.temperature = thread.energy / thread.coAuthors.count

    case .split(let approvers, let deniers):
        // Energy splits according to vote distribution
        let totalVoters = approvers.count + deniers.count
        let approverShare = (stakeAmount * approvers.count) / totalVoters
        let denierShare = stakeAmount - approverShare

        // Distribute energy
        treasury += approverShare
        thread.energy += denierShare
        thread.temperature = thread.energy / thread.coAuthors.count

    case .approve:
        // Energy distributes while preserving total
        distributeEnergy(stakeAmount, to: approvers)
        thread.coAuthors.append(author)
        thread.temperature = thread.energy / thread.coAuthors.count
        thread.frequency = calculateNewFrequency(thread)
    }
}
```

### 4. Temperature Evolution

Natural cooling follows thermodynamic principles:

```swift
func evolveTemperature(thread: inout ThreadState, timeDelta: UInt256) {
    // T = T0/√(1 + t/τ)
    let coolingFactor = sqrt(1000 + timeDelta / 86400)
    thread.temperature = (thread.temperature * 1000) / coolingFactor
}
```

### 5. Frequency Management

Frequency evolution through collective organization:

```swift
func updateFrequency(thread: inout ThreadState) {
    let messageMode = thread.messageRate / sqrt(thread.coAuthors.count)
    let valueMode = log(1 + thread.energy / thread.coAuthors.count)
    let coupling = 1.0 / thread.coAuthors.count

    thread.frequency = sqrt(
        (messageMode² + valueMode²) / 2.0 +
        coupling * thread.coAuthors.count
    )
}
```

## Reward State Transitions

### 1. New Message Rewards

Message rewards follow time-based decay:

```swift
func processNewMessageReward(message: Message, timestamp: UInt256) -> TokenAmount {
    // R(t) = R_total × k/(1 + kt)ln(1 + kT)
    let k = 204    // 2.04 scaled by 100
    let t = timestamp - LAUNCH_TIME
    let T = 4 years

    let reward = (TOTAL_SUPPLY * k * log(1 + k * T)) /
        ((1 + k * t) * 1000)

    return TokenAmount(reward)
}
```

### 2. Prior Citation Rewards

Prior rewards strengthen thread coupling:

```swift
func processPriorReward(
    sourceThread: ThreadState,
    targetThread: ThreadState,
    priorHash: Hash,
    qualityScore: UInt256
) -> TokenAmount {
    // Verify citation validity
    require(sourceThread.messageHashes.contains(priorHash))

    // Calculate reward using treasury balance
    // V(p) = B_t × Q(p)/∑Q(i)
    let reward = (treasury.balance * qualityScore) / TOTAL_QUALITY

    // Update thread coupling
    strengthenThreadCoupling(sourceThread, targetThread)

    return TokenAmount(reward)
}

func strengthenThreadCoupling(_ source: inout ThreadState, _ target: inout ThreadState) {
    // Citations strengthen both threads through frequency coupling
    let couplingFactor = 50 // 0.05 in fixed point
    source.frequency += (target.frequency * couplingFactor) / 1000
    target.frequency += (source.frequency * couplingFactor) / 1000
}
```

### 3. Treasury Management

Treasury balance evolution:

```swift
func updateTreasury(event: RewardEvent) {
    switch event {
    case .splitDecision(let approverShare):
        treasury.balance += approverShare

    case .priorReward(let amount):
        treasury.balance -= amount

    case .systemReward(let amount):
        treasury.balance += amount
    }

    // Verify treasury remains solvent
    require(treasury.balance >= MINIMUM_BALANCE)
}
```

## System Properties

### 1. Energy Conservation

```swift
property EnergyConservation {
    invariant: totalSystemEnergy == constant
    where: totalSystemEnergy = threads.sum(\.energy) + treasury
}
```

### 2. Temperature Stability

```swift
property TemperatureStability {
    invariant: thread.temperature > 0
    invariant: thread.temperature == thread.energy / thread.coAuthors.count
}
```

### 3. Frequency Coherence

```swift
property FrequencyCoherence {
    invariant: thread.frequency > 0
    invariant: thread.frequency increases with organization
}
```

## Error Handling

```swift
enum StateTransitionError {
    case energyConservationViolation
    case temperatureInstability
    case frequencyDecoherence
    case phaseTransitionFailure
}

func verifyStateTransition(from: ThreadState, to: ThreadState) throws {
    guard to.energy >= 0 else {
        throw StateTransitionError.energyConservationViolation
    }
    guard to.temperature > 0 else {
        throw StateTransitionError.temperatureInstability
    }
    guard to.frequency > 0 else {
        throw StateTransitionError.frequencyDecoherence
    }
}
```

## Monitoring Points

1. **Thermodynamic Health**
   - Energy conservation across transitions
   - Temperature evolution patterns
   - Frequency stability metrics
   - Phase transition success rates

2. **System Metrics**
   - Heat flow efficiency
   - Organization coherence
   - Value distribution patterns
   - Network effects

This model ensures:
- Pure state transition logic
- Energy conservation
- Natural evolution
- System stability
- Pattern emergence

The system maintains:
- Thermodynamic principles
- Phase relationships
- Value coherence
- Natural selection
- Collective organization
