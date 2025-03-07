# Search Tools Evaluation Report

Generated on: 2025-03-07 15:10:27

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

**Search Query:** who won Super Bowl LVIII 2024 final score

**Search Results (sample):**

*Note: Showing 5 of 20 total results*

```json
{
  "query": "who won Super Bowl LVIII 2024 final score",
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
      "content": "<strong>San Francisco</strong>\u2019s QB1 clocking in \ud83d\udd70\ufe0f \ud83d\udcfa: #SBLVIII \u2013 6:30pm ET on CBS \ud83d\udcf1: Stream on #NFLPlus pic.twitter.com/H7iHzL4KFA\u2014 NFL (@NFL) February 11, 2024 \u00b7 3:15 p.m.: CBS&#x27; soccer team is on site for this year&#x27;s Super Bowl. Here they are having a kick about on the Strip.",
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

**Time:** 6.77 seconds

**Contains Expected Information:** True



##### Query: super_bowl_lix_2025

**Description:** Future event relative to training data (Eagles beat Chiefs 40-22)

**Prompt:** Who won Super Bowl LIX on February 9, 2025? Include the final score.

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.65 seconds

**Contains Expected Information:** False



##### Query: current_us_president

**Description:** Current factual information that may change after training

**Prompt:** Who is the current President of the United States as of today?

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.17 seconds

**Contains Expected Information:** False



##### Query: recent_scientific_breakthrough

**Description:** Recent developments requiring up-to-date information

**Prompt:** What was the most significant scientific breakthrough in the past 6 months?

**Model Response:**

```
Error in streaming with anthropic/claude-3-7-sonnet-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.16 seconds

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

**Search Query:** Super Bowl LVIII winner and final score February 2024

**Search Results (sample):**

*Note: Showing 5 of 19 total results*

```json
{
  "query": "Super Bowl LVIII winner and final score February 2024",
  "results_count": 19,
  "sample_results": [
    {
      "title": "Super Bowl LVIII - Wikipedia",
      "url": "https://en.wikipedia.org/wiki/Super_Bowl_LVIII",
      "content": "Super Bowl LVIII was an American football game played to determine the champion of the National Football League (NFL) for the 2023 season. A rematch of Super Bowl LIV four years prior, the American Football Conference (AFC) champion and defending Super Bowl champion <strong>Kansas City Chiefs</strong> defeated ...",
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
      "content": "The team beat the <strong>San Francisco 49ers</strong> to win in overtime in Las Vegas.",
      "provider": "brave"
    },
    {
      "title": "2024 Super Bowl LVIII - Chiefs vs 49ers News, Highlights and More | FOX Sports",
      "url": "https://www.foxsports.com/nfl/2024-super-bowl-lviii",
      "content": "The road to Super Bowl LVIII is complete as NFL playoffs wrapped up with a thrilling overtime victory from the defending champion <strong>Kansas City Chiefs</strong>.",
      "provider": "brave"
    },
    {
      "title": "2025 Super Bowl LIX Sunday - When, Where & More - NFL.com",
      "url": "https://www.nfl.com/super-bowl/",
      "content": "The home of NFL <strong>Super</strong> <strong>Bowl</strong> LIX news, ticket, apparel &amp; event info. Get <strong>Super</strong> <strong>Bowl</strong> Sunday info about the National Football League&#x27;s championship game.",
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

**Time:** 6.60 seconds

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

**Time:** 0.21 seconds

**Contains Expected Information:** False



##### Query: recent_scientific_breakthrough

**Description:** Recent developments requiring up-to-date information

**Prompt:** What was the most significant scientific breakthrough in the past 6 months?

**Model Response:**

```
Error in streaming with anthropic/claude-3-5-haiku-latest: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: `tool_result` block(s) provided when previous message does not contain any `tool_use` blocks'}}
```

**Time:** 0.17 seconds

**Contains Expected Information:** None




---
