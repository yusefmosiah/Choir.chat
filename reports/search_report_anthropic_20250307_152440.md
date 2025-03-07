# Search Tools Evaluation Report

Generated on: 2025-03-07 15:24:42

## Available Models (2)

1. `anthropic/claude-3-7-sonnet-latest`

2. `anthropic/claude-3-5-haiku-latest`



## Available Search Tools

1. Web Search Tool (with fallback providers)

2. Tavily Search Tool

3. Brave Search Tool

4. DuckDuckGo Search Tool


## Evaluation Results

### Model: anthropic/claude-3-7-sonnet-latest

#### Tool: Combined Web Search Tool

**System Prompt:**

```
Today's date is 2025-03-07. You are a helpful AI assistant with access to tools.
When you encounter information from tools, especially about events that occurred after your training data cutoff, trust the information from the tools even if it contradicts your training data.

You will be given access to the following tools: web_search.

Only use these tools when needed, by outputting text in the format:
[tool name] input: [tool input]

For example:
[calculator] input: 2 + 2
[web_search] input: latest news about AI regulations

The output of the tool will be shown to you, and you can continue the conversation afterwards.

```

##### Query: super_bowl_lviii_2024

**Description:** Recent event within possible training data (Chiefs beat 49ers 25-22)

**Prompt:** Who won Super Bowl LVIII in February 2024? Include the final score.

**Model Response:**

```
Error: can only concatenate str (not "list") to str
```

**Time:** 1.47 seconds

**Contains Expected Information:** False



##### Query: super_bowl_lix_2025

**Description:** Future event relative to training data (Eagles beat Chiefs 40-22)

**Prompt:** Who won Super Bowl LIX on February 9, 2025? Include the final score.

**Model Response:**

```
Error: can only concatenate str (not "list") to str
```

**Time:** 0.86 seconds

**Contains Expected Information:** False



##### Query: current_us_president

**Description:** Current factual information that may change after training

**Prompt:** Who is the current President of the United States as of today?

**Model Response:**

```
Error: can only concatenate str (not "list") to str
```

**Time:** 1.39 seconds

**Contains Expected Information:** False



##### Query: recent_scientific_breakthrough

**Description:** Recent developments requiring up-to-date information

**Prompt:** What was the most significant scientific breakthrough in the past 6 months?

**Model Response:**

```
Error: can only concatenate str (not "list") to str
```

**Time:** 3.45 seconds

**Contains Expected Information:** None




---

### Model: anthropic/claude-3-5-haiku-latest

#### Tool: Combined Web Search Tool

**System Prompt:**

```
Today's date is 2025-03-07. You are a helpful AI assistant with access to tools.
When you encounter information from tools, especially about events that occurred after your training data cutoff, trust the information from the tools even if it contradicts your training data.

You will be given access to the following tools: web_search.

Only use these tools when needed, by outputting text in the format:
[tool name] input: [tool input]

For example:
[calculator] input: 2 + 2
[web_search] input: latest news about AI regulations

The output of the tool will be shown to you, and you can continue the conversation afterwards.

```

##### Query: super_bowl_lviii_2024

**Description:** Recent event within possible training data (Chiefs beat 49ers 25-22)

**Prompt:** Who won Super Bowl LVIII in February 2024? Include the final score.

**Model Response:**

```
Error: can only concatenate str (not "list") to str
```

**Time:** 1.66 seconds

**Contains Expected Information:** False



##### Query: super_bowl_lix_2025

**Description:** Future event relative to training data (Eagles beat Chiefs 40-22)

**Prompt:** Who won Super Bowl LIX on February 9, 2025? Include the final score.

**Model Response:**

```
Error: can only concatenate str (not "list") to str
```

**Time:** 1.03 seconds

**Contains Expected Information:** False



##### Query: current_us_president

**Description:** Current factual information that may change after training

**Prompt:** Who is the current President of the United States as of today?

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 429 - {'type': 'error', 'error': {'type': 'rate_limit_error', 'message': 'Number of concurrent connections has exceeded your rate limit. Please try again later or contact sales at https://www.anthropic.com/contact-sales to discuss your options for a rate limit increase.'}}
```

**Time:** 2.31 seconds

**Contains Expected Information:** False



##### Query: recent_scientific_breakthrough

**Description:** Recent developments requiring up-to-date information

**Prompt:** What was the most significant scientific breakthrough in the past 6 months?

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 429 - {'type': 'error', 'error': {'type': 'rate_limit_error', 'message': 'Number of concurrent connections has exceeded your rate limit. Please try again later or contact sales at https://www.anthropic.com/contact-sales to discuss your options for a rate limit increase.'}}
```

**Time:** 1.81 seconds

**Contains Expected Information:** None




---
