# Core Economic Model

VERSION core_economics:
invariants: {
"Chain state authority",
"Energy conservation",
"Harmonic distribution"
}
assumptions: {
"Swift concurrency",
"Event-driven flow",
"EVM integration"
}
docs_version: "0.4.2"

## Economic Events

Chain-driven economic events:

```swift
// Economic domain events
enum EconomicEvent: DomainEvent {
    // Stake events (from chain)
    case stakeDeposited(threadId: ThreadID, amount: TokenAmount)
    case stakeWithdrawn(threadId: ThreadID, amount: TokenAmount)

    // Temperature events (from chain)
    case temperatureIncreased(threadId: ThreadID, delta: Float)
    case temperatureDecreased(threadId: ThreadID, delta: Float)

    // Equity events (from chain)
    case equityDistributed(threadId: ThreadID, shares: [Address: Float])
    case equityDiluted(threadId: ThreadID, newShares: [Address: Float])

    // Reward events (from chain)
    case rewardsIssued(amount: TokenAmount, recipients: [Address])
    case treasuryUpdated(newBalance: TokenAmount)

    var id: UUID
    var timestamp: Date
    var metadata: EventMetadata
}
```

## Chain State Authority

EVM as source of truth:

```swift
// Economic state from chain
actor ChainStateManager {
    private let web3: Web3
    private let eventStore: EventStore

    // Get thread economics from chain
    func getThreadEconomics(_ id: ThreadID) async throws -> ThreadEconomics {
        // Get authoritative state from smart contract
        let contract = try await web3.contract(at: threadContractAddress)
        let state = try await contract.method("getThread", parameters: [id]).call()

        return ThreadEconomics(
            temperature: state.temperature,
            energy: state.energy,
            tokenBalance: state.balance,
            equityShares: state.equityMap
        )
    }

    // Submit economic transaction
    func submitTransaction(_ tx: Transaction) async throws {
        // Submit to chain first
        let hash = try await web3.eth.sendRawTransaction(tx)

        // Then emit events based on transaction type
        switch tx.data {
        case .depositStake(let amount):
            try await eventStore.append(.stakeDeposited(
                threadId: tx.threadId,
                amount: amount
            ))

        case .updateTemperature(let delta):
            try await eventStore.append(.temperatureIncreased(
                threadId: tx.threadId,
                delta: delta
            ))

        case .distributeEquity(let shares):
            try await eventStore.append(.equityDistributed(
                threadId: tx.threadId,
                shares: shares
            ))
        }
    }
}
```

## Harmonic Calculations

Pure calculation functions:

```swift
// Economic calculations (pure functions)
struct EconomicCalculator {
    // Base price using harmonic oscillator
    static func calculateBasePrice(
        temperature: Double,
        frequency: Double
    ) -> TokenAmount {
        // P₀ = S₀[1/2 + 1/(exp(ℏω/kT)-1)]
        let baseStake = Constants.baseStakeQuantum
        let reducedPlanck = Constants.reducedPlanck
        let boltzmann = Constants.boltzmann

        let exponent = (reducedPlanck * frequency) / (boltzmann * temperature)
        let occupation = 1.0 / (exp(exponent) - 1.0)

        return baseStake * (0.5 + occupation)
    }

    // Equity share calculation
    static func calculateEquityShare(
        stake: TokenAmount,
        basePrice: TokenAmount,
        coauthorCount: Int
    ) -> Double {
        // E(s) = (1/N) * √(s/P₀)
        let quantumNumber = Double(stake) / Double(basePrice)
        let quantumShare = 1.0 / Double(coauthorCount)
        return quantumShare * sqrt(quantumNumber)
    }
}
```

## Economic Handler

Event-driven economic processing:

```swift
// Economic event handling
actor EconomicHandler: EventHandler {
    private let chain: ChainStateManager
    private let calculator: EconomicCalculator

    func handle(_ event: DomainEvent) async throws {
        guard let economicEvent = event as? EconomicEvent else { return }

        switch economicEvent {
        case .stakeDeposited(let threadId, let amount):
            // Calculate new equity shares
            let thread = try await chain.getThreadEconomics(threadId)
            let basePrice = calculator.calculateBasePrice(
                temperature: thread.temperature,
                frequency: thread.frequency
            )
            let equity = calculator.calculateEquityShare(
                stake: amount,
                basePrice: basePrice,
                coauthorCount: thread.equityShares.count
            )

            // Submit equity distribution to chain
            let tx = Transaction.distributeEquity(
                threadId: threadId,
                shares: [event.author: equity]
            )
            try await chain.submitTransaction(tx)

        case .temperatureIncreased(let threadId, let delta):
            // Update thread temperature on chain
            let tx = Transaction.updateTemperature(
                threadId: threadId,
                delta: delta
            )
            try await chain.submitTransaction(tx)

        // Handle other economic events...
        }
    }
}
```

## Analytics & Monitoring

Economic event tracking:

```swift
// Economic analytics
actor EconomicAnalytics: EventHandler {
    func handle(_ event: DomainEvent) async throws {
        guard let economicEvent = event as? EconomicEvent else { return }

        switch economicEvent {
        case .stakeDeposited(let threadId, let amount):
            try await trackStakeMetric(threadId, amount)

        case .temperatureIncreased(let threadId, let delta):
            try await trackTemperatureMetric(threadId, delta)

        case .equityDistributed(let threadId, let shares):
            try await trackEquityMetric(threadId, shares)

        case .rewardsIssued(let amount, let recipients):
            try await trackRewardMetric(amount, recipients)
        }
    }
}
```

This implementation provides:
1. Chain state authority
2. Event-driven updates
3. Pure calculations
4. Clean analytics
5. Proper event flow

The system ensures:
- Economic integrity
- Harmonic distribution
- Temperature evolution
- Value conservation
- Natural emergence
