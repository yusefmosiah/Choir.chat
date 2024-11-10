# Economic Theory

VERSION theory_economics:
invariants: {
"Energy conservation",
"Value coherence",
"Pattern stability"
}
assumptions: {
"Event-driven flow",
"Network dynamics",
"Chain authority"
}
docs_version: "0.4.1"

## Quantum Value Model

At its foundation, the system's economic model is built on quantum harmonic principles. Value behaves like energy in a quantum system, with discrete levels and natural resonances.

### Energy Levels (Physics)

```
E(n) = ℏω(n + 1/2)

where:
- E(n): energy of quantum level n
- n: quantum number
- ω: natural frequency
- ℏ: reduced Planck constant
```

This fundamental formula from quantum mechanics describes the discrete energy levels of a harmonic oscillator. Just as electrons in an atom can only occupy specific energy levels, we use this principle to quantize thread stake levels.

### Thread Stake Pricing (Implemented)

```
E(n) = ℏω(n + 1/2)

where:
- n: quantum number (stake level)
- ω: thread frequency (organization level)
- ℏ: reduced Planck constant
```

This direct implementation determines stake requirements for thread participation. Higher frequency threads (more organized, more valuable) require more energy to participate in, creating natural quality barriers.

## Carnot Efficiency and Optimal Value Flow

By turning content creation into an asset, Choir provides higher incentives than competitors, aligning with the concept of **Carnot efficiency**. In thermodynamics, the Carnot cycle represents the most efficient possible engine between two heat reservoirs. Similarly, Choir's economic model aims for optimal efficiency in value creation and distribution.

### Content as Asset Creation

In Choir, content creation is directly linked to asset creation. Each contribution enhances the thread's value, and co-authors share in that value through equitable stake distribution. This creates a unified liquidity type—the **CHOIR token**—streamlining value flow and avoiding fragmentation.

This approach contrasts with systems that use NFTs or memecoins, which can fracture liquidity and scatter user attention across numerous tokens. In such systems, users might spend effort trading tokens and speculating on volatile price actions, detracting from focusing on the quality and specialness of content from the collective perspective.

### Maximizing Collective Value

From the perspective of **free energy minimization** or **predictive coding**, the optimal system transforms the environment of other agents to minimize their aggregate uncertainty (or "action-cone"). By providing maximal value to others, the system operates at peak efficiency.

Choir's model ensures:

- **Maximized Incentives**: By turning content into an asset, users have strong incentives to contribute quality content.
- **Unified Value Flow**: Consolidating liquidity into the CHOIR token ensures that value flows efficiently throughout the network.
- **Reduced Friction**: Users engage in high-stakes decisions and content creation without the distraction of managing multiple tokens.
- **Focus on Collective Growth**: Users concentrate on the special qualities of content and the collective perspective rather than individual speculative gains.

This approach aligns with Carnot efficiency by optimizing the system to provide the greatest possible value with minimal waste, mirroring the most efficient energy conversion in thermodynamic systems. By avoiding the pitfalls of fragmented liquidity and speculative distractions, Choir fosters an environment where value creation is harmonized, and collective intelligence thrives.

## Thermodynamic Flow

Temperature evolution through events follows thermodynamic principles:

### Thread Temperature

```
T(E,N) = E/N

where:
- T: thread temperature
- E: thread energy from events
- N: co-author count
```

This model helps us understand how thread "temperature" (activity level and quality barriers) evolves. Denials increase energy (E), raising temperature and making future participation require more stake. Approvals distribute energy among co-authors (N), moderating temperature.

### Energy Flow

```
dE/dt = ∑ᵢ δ(t - tᵢ)eᵢ - γE

where:
- eᵢ: energy from event i
- tᵢ: event timestamp
- γ: natural cooling rate
```

This describes how thread energy changes over time. Each event (eᵢ) adds energy, while natural cooling (-γE) gradually reduces it, creating a dynamic equilibrium.

## Event-Driven Value

Value state transitions through events:

### Stake Events

```swift
enum StakeEvent: Event {
    case deposited(amount: TokenAmount)
    case withdrawn(amount: TokenAmount)
    case distributed(shares: [PublicKey: Float])
}
```

These events track the flow of stake through the system, with each transition preserving total value.

### Temperature Events

```swift
enum TempEvent: Event {
    case increased(delta: Float)
    case decreased(delta: Float)
    case equilibrated(temp: Float)
}
```

These events track thread temperature changes, which affect stake requirements and participation dynamics.

## Value Conservation

The system maintains strict value conservation:

### Total Value

```
V_total = V_chain + V_threads + V_treasury

where:
- V_total: total system value
- V_chain: tokens in wallets
- V_threads: tokens in threads
- V_treasury: tokens in treasury
```

Like energy in a physical system, value cannot be created or destroyed, only transformed.

### Flow Conservation

```
dV_total/dt = 0

// All value transitions preserve total
```

This ensures economic integrity across all operations.

## Metastable States

Value crystallizes in metastable states, following quantum principles:

### Energy Barriers

```
ΔE = kT * ln(ω_high / ω_low)

where:
- ΔE: barrier height
- k: Boltzmann constant
- ω_high / ω_low: frequency ratio
```

This describes the energy required to transition between thread states, creating stability while enabling evolution.

### State Transitions

```
P(transition) = A * exp(-ΔE / kT)

where:
- P(transition): probability of state transition
- A: attempt frequency
- ΔE: barrier height
```

This governs how likely threads are to evolve to new states, balancing stability with adaptability.

---

Through these mechanisms, the economic system achieves:

1. **Natural Quality Barriers**
2. **Dynamic Equilibrium**
3. **Value Conservation**
4. **Pattern Stability**
5. **Organic Evolution**

The genius lies in how these principles work together:

- Quantum mechanics provides natural discretization.
- Thermodynamics governs system evolution.
- Conservation laws ensure integrity.
- Metastability enables growth.

This creates an economy that works like nature—no artificial reputation systems or arbitrary rules, just natural selection through energy flows and quantum transitions.
