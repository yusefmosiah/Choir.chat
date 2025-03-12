# LLM Provider Performance Matrix

| Provider  | Model Name                       | Status  | Confidence | Notes                                  |
|-----------|----------------------------------|---------|------------|----------------------------------------|
| **OpenAI**|                                  |         |            |                                        |
|           | gpt-4.5-preview                  | ✅      | 1.0        | Consistent formatting                  |
|           | gpt-4o                           | ✅      | 1.0        | Detailed geographical context          |
|           | gpt-4o-mini                      | ✅      | 1.0        | Concise response                       |
|           | o1                               | ✅      | 1.0        | Minimalist answer                      |
|           | o3-mini                          | ✅      | 1.0        | Direct response                        |
| **Anthropic**|                               |         |            |                                        |
|           | claude-3-7-sonnet-latest         | ✅      | 1.0        | Historical context included            |
|           | claude-3-5-haiku-latest          | ✅      | 1.0        | Comprehensive explanation              |
| **Google**|                                  |         |            |                                        |
|           | gemini-2.0-flash                 | ✅      | 0.99       | Verifiable sources cited               |
|           | gemini-2.0-flash-lite            | ✅      | 1.0        | High confidence assertion              |
|           | gemini-2.0-pro-exp-02-05         | ✅      | 1.0        | Historical perspective                 |
|           | gemini-2.0-flash-thinking-exp-01-21 | ❌  | N/A       | Function calling disabled              |
| **Mistral**|                                 |         |            |                                        |
|           | pixtral-12b-2409                 | ✅      | 0.9        | Conservative confidence                |
|           | codestral-latest                 | ❌      | N/A       | Rate limit exceeded                    |
| **Fireworks**|                               |         |            |                                        |
|           | deepseek-v3                      | ✅      | 1.0        | Multi-source verification              |
|           | qwen2p5-coder-32b-instruct       | ⚠️      | N/A       | Returned null response                 |
| **Cohere**|                                  |         |            |                                        |
|           | command-r7b-12-2024              | ✅      | 1.0        | Official designation emphasized        |

## Matrix Summary
- **Total Models Tested**: 16
- **Success Rate**: 81.25% (13/16)
- **Average Confidence**: 0.98 (successful models only)
- **Perfect Scores**: 9 models at 1.0 confidence
- **Common Failure Modes**:
  - Technical Limitations (37.5%)
  - Rate Limits (25%)
  - Null Responses (12.5%)

*Data preserved from original LangGraph-era tests conducted 2025-03-01*
