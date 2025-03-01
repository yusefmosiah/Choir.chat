# LLM Provider Information

This document tracks API keys, rate limits, and other important information for each LLM provider used in the PostChain implementation.

## Environment Variables

The following environment variables need to be set in your `.env` file:

```
# OpenAI
OPENAI_API_KEY=your_openai_api_key

# Anthropic
ANTHROPIC_API_KEY=your_anthropic_api_key

# Google
GOOGLE_API_KEY=your_google_api_key

# Mistral
MISTRAL_API_KEY=your_mistral_api_key

# Fireworks
FIREWORKS_API_KEY=your_fireworks_api_key

# Cohere
COHERE_API_KEY=your_cohere_api_key
```

## Rate Limits and Quotas

### OpenAI

- **GPT-3.5 Turbo**: 
  - Tokens per minute (TPM): 60,000
  - Requests per minute (RPM): 500
  - Context window: 16,385 tokens

- **GPT-4o**:
  - Tokens per minute (TPM): 10,000
  - Requests per minute (RPM): 100
  - Context window: 128,000 tokens

### Anthropic

- **Claude 3.5 Haiku**:
  - Requests per minute (RPM): 100
  - Context window: 200,000 tokens

- **Claude 3.5 Sonnet**:
  - Requests per minute (RPM): 50
  - Context window: 200,000 tokens

### Google (Gemini)

- **Gemini Pro**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

### Mistral

- **Mistral Medium**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

### Fireworks

- **Deepseek Chat**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

### Cohere

- **Command**:
  - Requests per minute (RPM): 100
  - Context window: 4,096 tokens

## Model Capabilities

| Provider  | Model           | JSON Output | Function Calling | Multi-turn | RAG Support |
|-----------|-----------------|-------------|------------------|------------|-------------|
| OpenAI    | GPT-3.5 Turbo   | ✅          | ✅               | ✅         | ✅          |
| OpenAI    | GPT-4o          | ✅          | ✅               | ✅         | ✅          |
| Anthropic | Claude 3.5 Haiku| ✅          | ✅               | ✅         | ✅          |
| Anthropic | Claude 3.5 Sonnet| ✅         | ✅               | ✅         | ✅          |
| Google    | Gemini Pro      | ✅          | ✅               | ✅         | ✅          |
| Mistral   | Mistral Medium  | ✅          | ✅               | ✅         | ✅          |
| Fireworks | Deepseek Chat   | ✅          | ❌               | ✅         | ✅          |
| Cohere    | Command         | ✅          | ❌               | ✅         | ✅          |

## Cost Information

| Provider  | Model           | Input Cost (per 1M tokens) | Output Cost (per 1M tokens) |
|-----------|-----------------|----------------------------|------------------------------|
| OpenAI    | GPT-3.5 Turbo   | $0.50                      | $1.50                        |
| OpenAI    | GPT-4o          | $5.00                      | $15.00                       |
| Anthropic | Claude 3.5 Haiku| $0.25                      | $1.25                        |
| Anthropic | Claude 3.5 Sonnet| $3.00                     | $15.00                       |
| Google    | Gemini Pro      | $0.35                      | $1.05                        |
| Mistral   | Mistral Medium  | $2.00                      | $6.00                        |
| Fireworks | Deepseek Chat   | $0.50                      | $1.50                        |
| Cohere    | Command         | $1.00                      | $2.00                        |

## Notes

- This information is current as of March 2024 and may change over time.
- Always check the provider's documentation for the most up-to-date information.
- Some providers may offer free tiers or trial credits.
- Cost information is approximate and may vary based on specific usage patterns.