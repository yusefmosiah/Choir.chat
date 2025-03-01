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

## Models to Test

### OpenAI
- gpt-4.5-preview
- gpt-4o
- gpt-4o-mini
- o1 (Note: Does not support temperature parameter)
- o3-mini (Note: Does not support temperature parameter)

### Anthropic
- claude-3-7-sonnet-latest
- claude-3-5-haiku-latest

### Google
- gemini-2.0-flash
- gemini-2.0-flash-lite
- gemini-2.0-pro-exp-02-05
- gemini-2.0-flash-thinking-exp-01-21

### Mistral
- pixtral-12b-2409 (Free tier)
- ~~mistral-small-latest~~ (Requires paid credits)
- ~~pixtral-large-latest~~ (Requires paid credits)
- ~~mistral-large-latest~~ (Requires paid credits)
- codestral-latest (Free tier)

### Cohere
- command-r7b-12-2024

### Fireworks
- ~~deepseek-r1~~ (Currently failing with internal server error)
- deepseek-v3
- qwen2p5-coder-32b-instruct

## Rate Limits and Quotas

### OpenAI

- **GPT-4.5 Preview**: 
  - Tokens per minute (TPM): 10,000
  - Requests per minute (RPM): 100
  - Context window: 128,000 tokens

- **GPT-4o**:
  - Tokens per minute (TPM): 10,000
  - Requests per minute (RPM): 100
  - Context window: 128,000 tokens

- **GPT-4o-mini**:
  - Tokens per minute (TPM): 60,000
  - Requests per minute (RPM): 500
  - Context window: 128,000 tokens

- **o1**:
  - Tokens per minute (TPM): 10,000
  - Requests per minute (RPM): 100
  - Context window: 128,000 tokens

- **o3-mini**:
  - Tokens per minute (TPM): 60,000
  - Requests per minute (RPM): 500
  - Context window: 128,000 tokens

### Anthropic

- **Claude 3.7 Sonnet**:
  - Requests per minute (RPM): 50
  - Context window: 200,000 tokens

- **Claude 3.5 Haiku**:
  - Requests per minute (RPM): 100
  - Context window: 200,000 tokens

### Google (Gemini)

- **Gemini 2.0 Flash**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

- **Gemini 2.0 Flash Lite**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

- **Gemini 2.0 Pro Exp**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

### Mistral

- **Mistral Small Latest**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

- **Mistral Large Latest**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

- **Pixtral Models**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

- **Codestral Latest**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

### Fireworks

- **Deepseek Models**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

- **Qwen2.5 Coder**:
  - Requests per minute (RPM): 60
  - Context window: 32,768 tokens

### Cohere

- **Command R7B**:
  - Requests per minute (RPM): 100
  - Context window: 128,000 tokens

## Model Capabilities

| Provider  | Model                | JSON Output | Function Calling | Multi-turn | RAG Support |
|-----------|---------------------|-------------|------------------|------------|-------------|
| OpenAI    | GPT-4.5 Preview     | ✅          | ✅               | ✅         | ✅          |
| OpenAI    | GPT-4o              | ✅          | ✅               | ✅         | ✅          |
| OpenAI    | GPT-4o-mini         | ✅          | ✅               | ✅         | ✅          |
| OpenAI    | o1                  | ✅          | ✅               | ✅         | ✅          |
| OpenAI    | o3-mini             | ✅          | ✅               | ✅         | ✅          |
| Anthropic | Claude 3.7 Sonnet   | ✅          | ✅               | ✅         | ✅          |
| Anthropic | Claude 3.5 Haiku    | ✅          | ✅               | ✅         | ✅          |
| Google    | Gemini 2.0 Flash    | ✅          | ✅               | ✅         | ✅          |
| Google    | Gemini 2.0 Flash Lite| ✅         | ✅               | ✅         | ✅          |
| Mistral   | Mistral Small       | ✅          | ✅               | ✅         | ✅          |
| Mistral   | Mistral Large       | ✅          | ✅               | ✅         | ✅          |
| Mistral   | Pixtral Models      | ✅          | ✅               | ✅         | ✅          |
| Mistral   | Codestral           | ✅          | ✅               | ✅         | ✅          |
| Fireworks | Deepseek Models     | ✅          | ❌               | ✅         | ✅          |
| Fireworks | Qwen2.5 Coder       | ✅          | ❌               | ✅         | ✅          |
| Cohere    | Command R7B         | ✅          | ❌               | ✅         | ✅          |

## Cost Information

| Provider  | Model                | Input Cost (per 1M tokens) | Output Cost (per 1M tokens) |
|-----------|---------------------|----------------------------|------------------------------|
| OpenAI    | GPT-4.5 Preview     | $10.00                     | $30.00                       |
| OpenAI    | GPT-4o              | $5.00                      | $15.00                       |
| OpenAI    | GPT-4o-mini         | $0.15                      | $0.60                        |
| OpenAI    | o1                  | $15.00                     | $75.00                       |
| OpenAI    | o3-mini             | $3.00                      | $15.00                       |
| Anthropic | Claude 3.7 Sonnet   | $15.00                     | $75.00                       |
| Anthropic | Claude 3.5 Haiku    | $0.25                      | $1.25                        |
| Google    | Gemini 2.0 Flash    | $0.35                      | $1.05                        |
| Google    | Gemini 2.0 Flash Lite| $0.15                     | $0.45                        |
| Mistral   | Mistral Small       | $1.00                      | $3.00                        |
| Mistral   | Mistral Large       | $2.00                      | $6.00                        |
| Mistral   | Pixtral Models      | $4.00                      | $12.00                       |
| Mistral   | Codestral           | $2.00                      | $6.00                        |
| Fireworks | Deepseek Models     | $0.50                      | $1.50                        |
| Fireworks | Qwen2.5 Coder       | $1.00                      | $3.00                        |
| Cohere    | Command R7B         | $1.00                      | $2.00                        |

## Notes

- This information is current as of March 2024 and may change over time.
- Always check the provider's documentation for the most up-to-date information.
- Some providers may offer free tiers or trial credits.
- Cost information is approximate and may vary based on specific usage patterns.
- Model availability and naming may change; check provider documentation for the latest model names.