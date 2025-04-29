import numpy as np
import math
import matplotlib.pyplot as plt

# Define the target points
similarity = np.array([0.95, 0.90, 0.85, 0.80, 0.75])
rewards = np.array([0.01, 0.1, 1.0, 10.0, 100.0])

# Looking at the pattern, we can see that:
# - Each 0.05 decrease in similarity results in 10x increase in reward
# - This is a classic exponential pattern: reward = base * 10^(k * (0.95 - similarity))
# - We can rewrite this using e: reward = base * e^(ln(10) * k * (0.95 - similarity))

# Let's define a simpler function using natural log properties
def simplified_exp_reward(similarity):
    # We want reward = 0.01 when similarity = 0.95
    # And we want reward to increase by 10x for every 0.05 decrease in similarity
    
    # Constants with clear meaning
    reference_similarity = 0.95  # The reference point where reward = min_reward
    min_reward = 0.01            # Reward at reference similarity
    reward_factor = 10           # How much reward increases per similarity_step
    similarity_step = 0.05       # How much similarity needs to decrease for reward to increase by reward_factor
    
    # Calculate exponent: ln(reward_factor) / similarity_step
    # This gives us how much the exponent changes per unit of similarity
    exponent_factor = math.log(reward_factor) / similarity_step
    
    # Calculate the reward
    reward = min_reward * math.exp(exponent_factor * (reference_similarity - similarity))
    
    return reward

# Print a table of values for the simplified function
print('Table of values (simplified exponential):')
print('| max_similarity | Target Reward | Simplified Reward |')
print('|---------------|--------------|-------------------|')
for sim, target in zip(similarity, rewards):
    reward = simplified_exp_reward(sim)
    print(f'| {sim:.2f} | {target:.4f} | {reward:.4f} |')

# Print the Python code for the simplified reward calculation
print('\nPython code for the simplified reward calculation:')
print('''
def calculate_novelty_reward(max_similarity):
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
    # This gives us how much the exponent changes per unit of similarity
    exponent_factor = math.log(reward_factor) / similarity_step
    
    # Calculate the reward
    reward_multiplier = min_reward * math.exp(exponent_factor * (reference_similarity - max_similarity))
    
    # Cap the reward at 100 CHOIR
    reward_multiplier = min(reward_multiplier, 100.0)
    
    # Convert to smallest units
    scaled_reward = int(base_reward * reward_multiplier)
    
    return scaled_reward
''')

# Let's also print the mathematical formula in a more readable form
print("\nMathematical formula:")
print(f"reward = {min_reward} * e^(ln({reward_factor})/{similarity_step} * (0.95 - similarity))")
print(f"reward = {min_reward} * e^({math.log(reward_factor)/similarity_step:.4f} * (0.95 - similarity))")
