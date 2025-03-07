# Search Tools Evaluation Report

Generated on: 2025-03-07 14:54:53

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

**Search Query:** Who won Super Bowl LVIII 2024 final score

**Search Results (sample):**

*Note: Showing 5 of 20 total results*

```json
{
  "query": "Who won Super Bowl LVIII 2024 final score",
  "results_count": 20,
  "sample_results": [
    {
      "title": "Super Bowl LVIII - Wikipedia",
      "url": "https://en.wikipedia.org/wiki/Super_Bowl_LVIII",
      "content": "A rematch of Super Bowl LIV four years prior, the American Football Conference (AFC) champion and defending Super Bowl champion <strong>Kansas City Chiefs</strong> defeated the National Football Conference (NFC) champion San Francisco 49ers 25\u201322 in overtime. The Chiefs became the first NFL team since the ...",
      "provider": "brave"
    },
    {
      "title": "Who won the Super Bowl 2024? Final score, results as Patrick Mahomes, Chiefs defeat 49ers in OT for repeat title | Sporting News",
      "url": "https://www.sportingnews.com/us/nfl/news/super-bowl-2024-live-score-49ers-chiefs-results-highlights/0c440aa7145b809ed174d8ff",
      "content": "The Sporting News tracked live <strong>scoring</strong> updates and highlights for <strong>Super</strong> <strong>Bowl</strong> 58 between the Chiefs and 49ers on Sunday.",
      "provider": "brave"
    },
    {
      "title": "2025 Super Bowl LIX - News, Highlights and More | FOX Sports",
      "url": "https://www.foxsports.com/nfl/super-bowl",
      "content": "The home of <strong>Super</strong> <strong>Bowl</strong> 2025. Get <strong>Super</strong> <strong>Bowl</strong> LIX news, highlights and in-depth analysis of the NFL playoffs.",
      "provider": "brave"
    },
    {
      "title": "2025 Super Bowl LIX Sunday - When, Where & More - NFL.com",
      "url": "https://www.nfl.com/super-bowl/",
      "content": "The home of NFL <strong>Super</strong> <strong>Bowl</strong> LIX news, ticket, apparel &amp; event info. Get <strong>Super</strong> <strong>Bowl</strong> Sunday info about the National Football League&#x27;s championship game.",
      "provider": "brave"
    },
    {
      "title": "How the Chiefs and Patrick Mahomes defeated the 49ers in the 2024 Super Bowl - The Athletic",
      "url": "https://www.nytimes.com/athletic/live-blogs/49ers-vs-chiefs-super-bowl-live-score-updates-game-summary/s1iecqQvbh5m/",
      "content": "<strong>Kansas City</strong> won the championship for the second consecutive year and third time in five, cementing its status as the NFL&#x27;s new dynasty.",
      "provider": "brave"
    }
  ],
  "providers_used": [
    "brave"
  ]
}
```

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 5.84 seconds

**Contains Expected Information:** True



##### Query: super_bowl_lix_2025

**Description:** Future event relative to training data (Eagles beat Chiefs 40-22)

**Prompt:** Who won Super Bowl LIX on February 9, 2025? Include the final score.

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.17 seconds

**Contains Expected Information:** False



##### Query: current_us_president

**Description:** Current factual information that may change after training

**Prompt:** Who is the current President of the United States as of today?

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.16 seconds

**Contains Expected Information:** False



##### Query: recent_scientific_breakthrough

**Description:** Recent developments requiring up-to-date information

**Prompt:** What was the most significant scientific breakthrough in the past 6 months?

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.19 seconds

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

**Search Query:** Super Bowl LVIII winner and final score 2024

**Search Results (sample):**

*Note: Showing 5 of 20 total results*

```json
{
  "query": "Super Bowl LVIII winner and final score 2024",
  "results_count": 20,
  "sample_results": [
    {
      "title": "Super Bowl LVIII - Wikipedia",
      "url": "https://en.wikipedia.org/wiki/Super_Bowl_LVIII",
      "content": "A rematch of Super Bowl LIV four years prior, the American Football Conference (AFC) champion and defending Super Bowl champion <strong>Kansas City Chiefs</strong> defeated the National Football Conference (NFC) champion San Francisco 49ers 25\u201322 in overtime. The Chiefs became the first NFL team since the ...",
      "provider": "brave"
    },
    {
      "title": "2025 Super Bowl LIX - News, Highlights and More | FOX Sports",
      "url": "https://www.foxsports.com/nfl/super-bowl",
      "content": "The home of <strong>Super</strong> <strong>Bowl</strong> 2025. Get <strong>Super</strong> <strong>Bowl</strong> LIX news, highlights and in-depth analysis of the NFL playoffs.",
      "provider": "brave"
    },
    {
      "title": "Super Bowl 2024 Winner",
      "url": "https://www.hollywoodreporter.com/news/general-news/super-bowl-2024-winner-1235822266/",
      "content": "The team beat the San Francisco 49ers to win Super Bowl LVIII in overtime Sunday with a final score of <strong>25-22.</strong> It was only the second time in NFL history that a Super Bowl game has gone into overtime, following Super Bowl LI in 2017, when the New England Patriots beat the Atlanta Falcons.",
      "provider": "brave"
    },
    {
      "title": "Who won the Super Bowl 2024? Final score, results as Patrick Mahomes, Chiefs defeat 49ers in OT for repeat title | Sporting News",
      "url": "https://www.sportingnews.com/us/nfl/news/super-bowl-2024-live-score-49ers-chiefs-results-highlights/0c440aa7145b809ed174d8ff",
      "content": "The Sporting News tracked live <strong>scoring</strong> updates and highlights for <strong>Super</strong> <strong>Bowl</strong> 58 between the Chiefs and 49ers on Sunday.",
      "provider": "brave"
    },
    {
      "title": "How the Chiefs and Patrick Mahomes defeated the 49ers in the 2024 Super Bowl - The Athletic",
      "url": "https://www.nytimes.com/athletic/live-blogs/49ers-vs-chiefs-super-bowl-live-score-updates-game-summary/s1iecqQvbh5m/",
      "content": "<strong>Kansas City</strong> won the championship for the second consecutive year and third time in five, cementing its status as the NFL&#x27;s new dynasty.",
      "provider": "brave"
    }
  ],
  "providers_used": [
    "brave"
  ]
}
```

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 7.71 seconds

**Contains Expected Information:** True



##### Query: super_bowl_lix_2025

**Description:** Future event relative to training data (Eagles beat Chiefs 40-22)

**Prompt:** Who won Super Bowl LIX on February 9, 2025? Include the final score.

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.16 seconds

**Contains Expected Information:** False



##### Query: current_us_president

**Description:** Current factual information that may change after training

**Prompt:** Who is the current President of the United States as of today?

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.16 seconds

**Contains Expected Information:** False



##### Query: recent_scientific_breakthrough

**Description:** Recent developments requiring up-to-date information

**Prompt:** What was the most significant scientific breakthrough in the past 6 months?

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.16 seconds

**Contains Expected Information:** None




---
