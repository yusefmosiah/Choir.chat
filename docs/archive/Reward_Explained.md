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
# Understanding Choir's Reward System

## Overview

Choir has two main ways of rewarding users:

1. **New Message Rewards**: These rewards encourage early participation but gradually decrease over time.
2. **Priors Rewards**: These are ongoing rewards for referencing existing content, funded by the Treasury.

## New Message Rewards Explained

### What Are They?
- Rewards given for contributing new messages that get approved
- Come from a fixed pool of 2.5 billion CHOIR tokens
- Designed to kickstart the platform and reward early adopters

### How Do They Work?
- Start high and decrease over time
- Half of all new message rewards are given out in the first year
- 99% are given out by the end of year 4
- After that, they effectively stop

### Why This Design?
- Encourages people to join and contribute early
- Creates initial content and activity
- Gradually shifts focus to quality over quantity
- Natural transition to sustainable long-term rewards

## Priors Rewards Explained

### Purpose

- **Reward Past Content Creation**: Authors receive rewards when their past content is referenced in new messages
- **Incentivize Forward-Thinking**: Encourage creating content that will remain relevant and valuable in the future
- **Recognize Foundational Work**: Reward authors whose work becomes the foundation for future discussions

### How They Work

1. **Original Author Rewards**
   - When content is referenced in a new message, the **original author** of that content receives the reward
   - Rewards are proportional to the relevance and impact of their referenced content
   - Multiple references to the same content can generate multiple rewards
   - Authors continue earning from their content as long as it remains relevant

2. **Long-Term Value Creation**
   - Authors are incentivized to create content with lasting value
   - Better to write one foundational piece referenced 100 times than 100 pieces never referenced
   - Quality and foresight are naturally rewarded
   - Creates incentive to "write for the future"

### Funding Source

- **Treasury-Funded**: Sustained by tokens collected from split decisions during the approval process
- **Perpetual Rewards**: Unlike new message rewards, these continue indefinitely
- **Sustainable System**: Treasury continuously replenished through split decisions

### Distribution Mechanics

1. **Reward Calculation**
   ```math
   R_{\text{prior}}(i, t) = B_t \times \frac{Q_p(i)}{\sum_{j=1}^{N(t)} Q_p(j)}
   ```
   Where:
   - **R_prior(i, t)**: Reward paid to the original author of prior **i** at time **t**
   - **B_t**: Treasury balance allocated for priors rewards
   - **Q_p(i)**: Quality/relevance score of the prior use
   - **N(t)**: Total number of priors in the period

2. **Quality Assessment**
   - AI model evaluates how meaningfully the prior content is used
   - Higher rewards for priors that significantly contribute to new discussions
   - Rewards scale with the depth and relevance of the reference

### Example

If Alice writes a message in Year 1:
- Bob references it in Year 2 → Alice receives a reward
- Carol references it in Year 3 → Alice receives another reward
- Dave references it in Year 4 → Alice receives yet another reward

Alice continues earning from her content's value over time, incentivizing the creation of lasting, reusable content.

## The Big Picture

### Early Stage (First 4 Years):
- High rewards for new messages
- Building initial content base
- Establishing community
- Creating valuable content to reference

### Long Term (After 4 Years):
- Focus shifts to priors rewards
- Encourages building on existing knowledge
- Rewards quality connections
- Sustainable through Treasury funding

### Why Two Types?
- New message rewards bootstrap the platform
- Priors rewards maintain it long-term
- Natural evolution from growth to sustainability
- Encourages both creation and connection

## Example

Imagine you join Choir:

1. **In Year 1:**
   - Your approved new messages get significant rewards
   - You can also earn by referencing others' content
   - Both reward types are available

2. **In Year 4:**
   - New message rewards are much smaller
   - But priors rewards are still strong
   - Focus shifts to quality over quantity

3. **After Year 4:**
   - New message rewards effectively end
   - Priors rewards continue indefinitely
   - System maintains itself through Treasury mechanics

## Key Points to Remember

- New message rewards are temporary but significant
- Priors rewards are permanent and sustainable
- The system naturally evolves over time
- Quality and relevance always matter
- The Treasury ensures long-term sustainability

## Tips for Maximizing Rewards

1. **Early Participation:**
   - Join early to benefit from higher new message rewards
   - Build a foundation of quality content
   - Establish yourself in the community

2. **Quality Connections:**
   - Make meaningful references to existing content
   - Focus on relevance and value
   - Build on others' ideas effectively

3. **Long-term Strategy:**
   - Shift focus to priors as new message rewards decrease
   - Build a network of interconnected content
   - Contribute to the platform's knowledge base

Remember: The goal is to create a self-sustaining ecosystem where quality content naturally emerges and evolves. The reward system is designed to support this, not to be gamed or exploited.
