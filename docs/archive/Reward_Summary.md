# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Rewards Summary

VERSION rewards_system:
invariants: {
"Energy conservation",
"Incentive alignment",
"Sustainable token flow"
}
assumptions: {
"Fixed token supply",
"Thermodynamic principles",
"Adaptive distribution"
}
docs_version: "0.2.1"

## Overview

Choir's reward system incentivizes high-quality content creation and meaningful engagement through two primary reward mechanisms:

1. **New Message Rewards**: Incentivize early participation by rewarding users for contributing new messages during the initial growth phase of the platform.

2. **Priors Rewards** (formerly **Citation Rewards**): Encourage users to reference and build upon existing content, promoting a rich, interconnected knowledge network.

---

## 1. New Message Rewards

### Purpose

- **Incentivize Early Adoption**: Encourage users to contribute new messages during the formative years of the platform.

### Total Allocation

- **Fixed Allocation**: **2.5 billion** CHOIR tokens allocated from the total supply of **10 billion** tokens.

### Distribution Mechanics

1. **Time-Based Decay**

   - **Decay Function**: Rewards decrease logarithmically over four years.
   - **Milestones**:
     - **50%** of the allocated new message rewards distributed after **1 year**.
     - **99%** distributed after **4 years**.

2. **Distribution Factors**

   - **Time (t)**: Primary factor influencing reward size.
   - **Message Volume (M(t))**: The number of messages submitted at time **t** affects per-message rewards.
   - **No Direct Dependence**: Does not directly depend on treasury balance or token velocity.

### Reward Calculation

**Cumulative Reward Function**:

```math
F(t) = R_{\text{total}} \times \frac{\ln(1 + k \times t)}{\ln(1 + k \times T)}
```

- **F(t)**: Total rewards distributed up to time **t**.
- **R_total**: Total tokens allocated for new message rewards (2.5 billion).
- **k**: Decay constant (calculated to meet distribution milestones).
- **T**: Total duration (4 years).

**Instantaneous Reward Rate**:

```math
\frac{dF}{dt} = R_{\text{total}} \times \frac{k}{(1 + k \times t) \times \ln(1 + k \times T)}
```

**Per-Message Reward**:

```math
R(t) = \frac{\frac{dF}{dt}}{M(t)}
```

- **R(t)**: Reward per message at time **t**.
- **M(t)**: Number of messages submitted during the time interval at **t**.

### Key Points

- **Early Incentives**: Higher rewards at the platform's inception.
- **Predictable Decline**: Transparent decrease over time aligns with network growth.
- **Encourages Quality**: As rewards diminish, focus shifts to contributing valuable content that garners engagement.

---

## 2. Priors Rewards (formerly Citation Rewards)

### Purpose

- **Promote Knowledge Interconnectivity**: Encourage users to reference and build upon existing content, creating a rich and cohesive knowledge network.

### Funding Source

- **Treasury-Funded**: Sustained by tokens collected from **split decisions** during the approval process.

### Distribution Mechanics

1. **Treasury Accumulation**

   - **Source**: Tokens from approvers in split decisions flow into the Treasury.
   - **Sustainability**: Continuous inflow ensures perpetual reward funding.

2. **Quality-Weighted Rewards**

   - **Relevance and Impact**: Rewards are based on the relevance and impact of the prior (formerly citation).
   - **AI-Assisted Weighting**: The Chorus Cycle's AI model assigns weights to priors based on semantic analysis.

3. **Adaptive Distribution**

   - **Treasury Health Maintenance**: Adjusts distribution to maintain a healthy Treasury balance.
   - **Dynamic Scaling**: Rewards may increase or decrease based on Treasury inflows and priors' demand.

### Reward Calculation

**Priors Reward Function**:

```math
R_{\text{prior}}(i, t) = B_t \times \frac{Q_p(i)}{\sum_{j=1}^{N(t)} Q_p(j)}
```

- **R_prior(i, t)**: Reward for prior **i** at time **t**.
- **B_t**: Total Treasury balance allocated for priors rewards at time **t**.
- **Q_p(i)**: Quality metric for prior **i** assigned by the AI model.
- **N(t)**: Total number of priors in the period.

### Factors Influencing Priors Rewards

- **Treasury Balance (B_t)**: Determines total rewards available.
- **Quality Metric (Q_p)**: Higher quality priors receive larger rewards.
- **Activity Levels**: Adjusts for the number of priors to sustainably distribute rewards.

### Key Points

- **Continuous Incentives**: Unlike new message rewards, priors rewards continue indefinitely.
- **Quality Emphasis**: Rewards prioritize meaningful and impactful contributions.
- **AI Integration**: Leverages AI to assess and weight priors based on relevance.

---

## 3. Technical Implementation Details

### Decay Function for New Message Rewards

- **Decay Constant (k)**: Calculated to satisfy distribution milestones.

```math
k = \text{Derived from } \frac{\ln(1 + k \times t_1)}{\ln(1 + k \times T)} = \frac{F(t_1)}{R_{\text{total}}}
```

- **t1**: Time at first milestone (1 year).
- **F(t1)**: Reward amount at t1 (50% of R_total).

- **Example Parameters**:

  - **T**: 4 years.
  - **R_total**: 2.5 billion CHOIR tokens.
  - **Calculated k**: Approximately 2.04.

### Adaptive Reward Function for Priors

- **Treasury Allocation**:

  - A percentage of the Treasury balance is allocated periodically for priors rewards.

- **AI Weighting Mechanism**:

  - The AI model in the Chorus Cycle evaluates priors using semantic analysis and assigns a quality score.

- **Sustainable Function**:

  - The reward function adjusts to ensure the Treasury is not depleted, using a natural, sustainable mathematical function (e.g., proportional allocation based on inflow rate).

---

## 4. Additional Considerations

### Circular Token Flow

- **Energy Conservation**: The total token supply remains constant, ensuring energy conservation in the system.
- **Treasury Mechanics**:

  - **Inflows**: From split decisions.
  - **Outflows**: To fund priors rewards.
  - **Balance Maintenance**: Adjusting rewards to maintain equilibrium.

### Incentive Alignment

- **Early Adoption**: New message rewards encourage users to join and contribute early.
- **Ongoing Engagement**: Priors rewards promote continuous interaction and content enhancement.
- **Quality Focus**: Both rewards systems are designed to prioritize high-quality contributions.

---

## 5. Example Scenarios

### New Message Reward Calculation Example

- **At Time t = 1 year**:

  - **Total Messages (M(t))**: 10 million.
  - **Reward per Message (R(t))**:

```math
R(t) = \frac{\frac{dF}{dt}}{M(t)}
```

Calculate **dF/dt** using the decay function and then compute **R(t)**.

### Priors Reward Calculation Example

- **Treasury Balance (B_t)**: 100 million CHOIR tokens.
- **Total Priors (N(t))**: 50,000.
- **Quality Scores (Q_p(i))**: Assigned by AI, ranging from 0.1 to 1.0.
- **Reward for Prior i**:

```math
R_{\text{prior}}(i, t) = B_t \times \frac{Q_p(i)}{\sum_{j=1}^{N(t)} Q_p(j)}
```

Compute the sum of quality scores and allocate rewards proportionally.

---

## 6. Terminology Update

- **Priors**: The term **"Priors"** replaces **"Citations"** or **"Sources"** to better reflect the foundational nature of referenced content in the knowledge network.

---

## 7. Future Developments

- **AI Model Enhancements**:

  - Improve the Chorus Cycle's ability to assess prior relevance and impact, refining the quality metrics used in reward calculations.

- **Governance and Parameters Adjustment**:

  - Introduce community governance mechanisms to adjust reward parameters and ensure the system remains fair and sustainable.

---

## Conclusion

The reward system in Choir is thoughtfully designed to balance incentivizing early adoption with sustaining long-term engagement. By integrating thermodynamic principles and adaptive mechanisms, the platform ensures energy conservation, incentive alignment, and sustainable token flow, fostering a vibrant and collaborative ecosystem.

---
