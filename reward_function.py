import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

# Define the target points
similarity = np.array([0.95, 0.90, 0.85, 0.80, 0.75])
rewards = np.array([0.01, 0.1, 1.0, 10.0, 100.0])

# Define a logarithmic function with parameters to fit
def log_function(x, a, b, c):
    # We want a function that grows exponentially as similarity decreases
    # Using 1-x to invert the relationship (lower similarity -> higher reward)
    return a * np.exp(b * (c - x))

# Fit the function to our data points
params, _ = curve_fit(log_function, similarity, rewards)

# Extract the fitted parameters
a, b, c = params
print(f'Fitted parameters: a={a:.6f}, b={b:.6f}, c={c:.6f}')

# Generate a smooth curve using the fitted function
x_smooth = np.linspace(0.75, 0.95, 100)
y_smooth = log_function(x_smooth, a, b, c)

# Print a table of values
print('\nTable of values:')
print('| max_similarity | Reward (CHOIR) |')
print('|---------------|----------------|')
for sim in np.linspace(0.95, 0.75, 9):
    reward = log_function(sim, a, b, c)
    print(f'| {sim:.2f} | {reward:.4f} |')

# Print the exact function
print(f'\nFunction: reward = {a:.6f} * exp({b:.6f} * ({c:.6f} - max_similarity))')

# Print the Python code for the reward calculation
print('\nPython code for the reward calculation:')
print(f'''
def calculate_novelty_reward(max_similarity):
    if max_similarity > 0.95:
        return 0
    
    # Base reward amount (1 CHOIR = 1_000_000_000 units)
    base_reward = 1_000_000_000
    
    # Calculate reward using fitted exponential function
    reward_multiplier = {a:.6f} * np.exp({b:.6f} * ({c:.6f} - max_similarity))
    
    # Cap the reward at 100 CHOIR
    reward_multiplier = min(reward_multiplier, 100.0)
    
    # Convert to smallest units
    scaled_reward = int(base_reward * reward_multiplier)
    
    return scaled_reward
''')

# Check how well our function matches the target points
print('\nComparison with target points:')
print('| max_similarity | Target Reward | Fitted Reward |')
print('|---------------|--------------|---------------|')
for sim, target in zip(similarity, rewards):
    fitted = log_function(sim, a, b, c)
    print(f'| {sim:.2f} | {target:.4f} | {fitted:.4f} |')

# Let's also try a simpler approach with a direct exponential function
print("\n\nAlternative approach: Direct exponential function")
print("---------------------------------------------------")

def exponential_reward(similarity):
    # Simple exponential function: 10^(20 * (0.95 - similarity))
    # This gives approximately:
    # 0.95 -> 0.01
    # 0.90 -> 0.1
    # 0.85 -> 1
    # 0.80 -> 10
    # 0.75 -> 100
    return 10**(20 * (0.95 - similarity))

# Print a table of values for the direct exponential function
print('\nTable of values (direct exponential):')
print('| max_similarity | Reward (CHOIR) |')
print('|---------------|----------------|')
for sim in np.linspace(0.95, 0.75, 9):
    reward = exponential_reward(sim)
    print(f'| {sim:.2f} | {reward:.4f} |')

# Print the Python code for the direct exponential reward calculation
print('\nPython code for the direct exponential reward calculation:')
print('''
def calculate_novelty_reward(max_similarity):
    if max_similarity > 0.95:
        return 0
    
    # Base reward amount (1 CHOIR = 1_000_000_000 units)
    base_reward = 1_000_000_000
    
    # Calculate reward using direct exponential function
    # 10^(20 * (0.95 - similarity))
    reward_multiplier = 10**(20 * (0.95 - max_similarity))
    
    # Cap the reward at 100 CHOIR
    reward_multiplier = min(reward_multiplier, 100.0)
    
    # Convert to smallest units
    scaled_reward = int(base_reward * reward_multiplier)
    
    return scaled_reward
''')

# Check how well the direct exponential function matches the target points
print('\nComparison with target points (direct exponential):')
print('| max_similarity | Target Reward | Exponential Reward |')
print('|---------------|--------------|---------------------|')
for sim, target in zip(similarity, rewards):
    exp_reward = exponential_reward(sim)
    print(f'| {sim:.2f} | {target:.4f} | {exp_reward:.4f} |')
