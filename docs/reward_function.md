# Choir Novelty Reward Function

This document explains the mathematical approach used to calculate novelty rewards in the Choir system. We explored different approaches to implement an exponential reward scaling that provides higher rewards for more novel content.

## Reward Scaling Requirements

The novelty reward system needed to meet the following requirements:

1. Scale exponentially from 0.01 to 100.0 CHOIR tokens based on content novelty
2. Provide specific reward amounts at key similarity thresholds:
   - 0.95 similarity → 0.01 CHOIR (minimum novelty)
   - 0.90 similarity → 0.1 CHOIR
   - 0.85 similarity → 1.0 CHOIR
   - 0.80 similarity → 10.0 CHOIR
   - 0.75 similarity → 100.0 CHOIR (maximum novelty)
3. Use a smooth mathematical function that scales predictably
4. Implement using natural mathematical constants rather than magic numbers

## Approach 1: Curve Fitting

Our first approach (`reward_function.py`) used curve fitting to find a mathematical function that precisely matched our target reward points. We used SciPy's `curve_fit` function to fit an exponential function to our data points.

```python
# Define a logarithmic function with parameters to fit
def log_function(x, a, b, c):
    # We want a function that grows exponentially as similarity decreases
    return a * np.exp(b * (c - x))

# Fit the function to our data points
params, _ = curve_fit(log_function, similarity, rewards)

# Extract the fitted parameters
a, b, c = params
# a=0.002489, b=46.051702, c=0.980199

# The resulting function
reward = 0.002489 * np.exp(46.051702 * (0.980199 - max_similarity))
```

This approach produced a perfect fit to our target points but used somewhat arbitrary constants that lacked clear meaning.

## Approach 2: Simplified Exponential Function

Our second approach (`reward_function_simplified.py`) derived a more intuitive exponential function based on the mathematical properties of our reward scaling requirements.

We observed that:
- Each 0.05 decrease in similarity results in a 10x increase in reward
- This is a classic exponential pattern that can be expressed using the natural exponential function (e)

```python
# Constants with clear meaning
reference_similarity = 0.95  # The reference point where reward = min_reward
min_reward = 0.01            # Reward at reference similarity
reward_factor = 10           # How much reward increases per similarity_step
similarity_step = 0.05       # How much similarity needs to decrease for reward to increase by reward_factor

# Calculate exponent: ln(reward_factor) / similarity_step
exponent_factor = math.log(reward_factor) / similarity_step

# Calculate the reward
reward = min_reward * math.exp(exponent_factor * (reference_similarity - similarity))
```

The mathematical formula can be expressed as:
```
reward = min_reward * e^(ln(reward_factor)/similarity_step * (reference_similarity - similarity))
```

This simplified approach:
1. Uses constants with clear semantic meaning
2. Leverages the natural exponential function (e)
3. Produces identical results to the curve-fitted function
4. Is more maintainable and easier to understand

## Implementation in Choir

The simplified exponential function was implemented in `api/app/services/rewards_service.py` as follows:

```python
async def calculate_novelty_reward(self, max_similarity: float) -> int:
    # If max_similarity is close to 1.0, the prompt is not novel
    if max_similarity > 0.95:
        return 0

    # Base reward amount (1 CHOIR = 1_000_000_000 units)
    base_reward = 1_000_000_000
    
    # Constants with clear meaning
    reference_similarity = 0.95  # The reference point where reward = min_reward
    min_reward = 0.01            # Reward at reference similarity
    reward_factor = 10           # How much reward increases per similarity_step
    similarity_step = 0.05       # How much similarity needs to decrease for reward to increase by reward_factor
    
    # Calculate exponent: ln(reward_factor) / similarity_step
    exponent_factor = math.log(reward_factor) / similarity_step
    
    # Calculate the reward using natural exponential function
    reward_multiplier = min_reward * math.exp(exponent_factor * (reference_similarity - max_similarity))
    
    # Cap the reward at 100 CHOIR
    reward_multiplier = min(reward_multiplier, 100.0)
    
    # Convert to smallest units
    scaled_reward = int(base_reward * reward_multiplier)

    return scaled_reward
```

## Reward Table

The following table shows the rewards at different similarity levels:

| max_similarity | novelty_score | Reward (CHOIR) |
|---------------|--------------|----------------|
| 0.95 | 0.05 | 0.01 |
| 0.92 | 0.08 | 0.0316 |
| 0.90 | 0.10 | 0.1 |
| 0.88 | 0.12 | 0.3162 |
| 0.85 | 0.15 | 1.0 |
| 0.82 | 0.18 | 3.1623 |
| 0.80 | 0.20 | 10.0 |
| 0.78 | 0.22 | 31.6228 |
| 0.75 | 0.25 | 100.0 |

## Benefits of Exponential Scaling

The exponential reward scaling provides several benefits:

1. **Incentivizes Novelty**: Provides significantly higher rewards for truly novel content
2. **Dynamic Range**: Covers a wide range of rewards (0.01 to 100.0) to better differentiate content quality
3. **Logarithmic Perception**: Aligns with human perception, which tends to be logarithmic rather than linear
4. **Mathematical Elegance**: Uses a clean mathematical formula based on natural constants

This reward function ensures that users are properly incentivized to contribute novel content to the Choir ecosystem, with rewards that scale exponentially based on the uniqueness of their contributions.
