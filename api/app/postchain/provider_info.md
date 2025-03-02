# LLM Provider Structured Output Test Results

This document presents the results of structured output capability tests across various LLM providers. The tests evaluate each model's ability to generate responses in a structured JSON format following a specific schema.

## Test Overview

The test asked each model to answer a simple question ("What is the capital of France?") and return the response in a structured format with the following fields:
- `proposed_response`: The answer to the question
- `confidence`: A number between 0 and 1 indicating confidence level
- `reasoning`: Brief explanation of the answer

## Test Results Summary

| Provider  | Success Rate | Notes |
|-----------|--------------|-------|
| OpenAI    | 5/5 (100%)   | All models successfully generated structured output |
| Anthropic | 2/2 (100%)   | All models successfully generated structured output |
| Google    | 3/4 (75%)    | One model failed due to function calling not being enabled |
| Mistral   | 1/2 (50%)    | One model failed due to rate limiting |
| Fireworks | 1/2 (50%)    | One model returned null response |
| Cohere    | 1/1 (100%)   | Successfully generated structured output |

**Overall Success Rate**: 13/16 (81.25%)

## Detailed Results by Provider

### OpenAI Models

| Model | Status | Sample Response |
|-------|--------|----------------|
| gpt-4.5-preview | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "Paris is widely recognized and officially acknowledged as the capital city of France."}` |
| gpt-4o | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "Paris is widely recognized as the capital city of France, and this is a well-established fact in geography."}` |
| gpt-4o-mini | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "Paris is widely recognized as the capital city of France, serving as the political, economic, and cultural center."}` |
| o1 | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "France's capital city, widely known."}` |
| o3-mini | ✅ SUCCESS | `{"proposed_response": "Paris", "confidence": 1.0, "reasoning": "Paris is universally known as the capital of France."}` |

### Anthropic Models

| Model | Status | Sample Response |
|-------|--------|----------------|
| claude-3-7-sonnet-latest | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "This is a well-established geographical fact. Paris has been the capital city of France since 987 CE when Hugh Capet made it the seat of government."}` |
| claude-3-5-haiku-latest | ✅ SUCCESS | `{"proposed_response": "Paris is the capital of France.", "confidence": 1.0, "reasoning": "Paris is well-known as the capital and largest city of France, serving as the country's political, cultural, and economic center."}` |

### Google Models

| Model | Status | Sample Response |
|-------|--------|----------------|
| gemini-2.0-flash | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 0.99, "reasoning": "Paris is widely known as the capital of France, and this information is easily verifiable through numerous reliable sources."}` |
| gemini-2.0-flash-lite | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "The capital of France is a well-known fact and easily accessible information. Therefore, the confidence level is high."}` |
| gemini-2.0-pro-exp-02-05 | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "The capital of France is a well-known fact, easily found through various sources. Paris has served as the capital for centuries."}` |
| gemini-2.0-flash-thinking-exp-01-21 | ❌ ERROR | Function calling is not enabled for this model |

### Mistral Models

| Model | Status | Sample Response |
|-------|--------|----------------|
| pixtral-12b-2409 | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 0.9, "reasoning": "I have high confidence in this answer as it is a well-known fact."}` |
| codestral-latest | ❌ ERROR | Rate limit exceeded |

### Fireworks Models

| Model | Status | Sample Response |
|-------|--------|----------------|
| deepseek-v3 | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "This is a well-known fact and can be confirmed by multiple reliable sources."}` |
| qwen2p5-coder-32b-instruct | ⚠️ PARSE ERROR | Returned null response |

### Cohere Models

| Model | Status | Sample Response |
|-------|--------|----------------|
| command-r7b-12-2024 | ✅ SUCCESS | `{"proposed_response": "The capital of France is Paris.", "confidence": 1.0, "reasoning": "Paris is the official capital of France and is located in the north-central part of the country."}` |

## Implementation Notes

The tests were conducted using LangChain's `with_structured_output()` method, which simplifies the process of generating structured outputs from LLMs. This approach:

1. Takes a Pydantic model as input (in this case, `ActionResponse`)
2. Automatically handles the formatting and parsing of the response
3. Returns an instance of the Pydantic model directly

Example implementation:
```python
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

class ActionResponse(BaseModel):
    proposed_response: str = Field(description="The initial response to the user's query")
    confidence: float = Field(description="A number between 0 and 1 indicating confidence level")
    reasoning: str = Field(description="Brief explanation of the response")

base_model = ChatOpenAI(api_key=api_key, model=model_name)
structured_model = base_model.with_structured_output(ActionResponse)
response = structured_model.invoke("What is the capital of France?")
```

## Conclusions

1. **High Success Rate**: Most models (81.25%) successfully generated structured output in the required format.

2. **Provider Reliability**:
   - OpenAI and Anthropic models had a 100% success rate
   - Google models were mostly successful (75%)
   - Mistral and Fireworks had mixed results (50%)
   - Cohere was successful with its tested model

3. **Failure Patterns**:
   - Function calling limitations (Google's thinking-exp model)
   - Rate limiting issues (Mistral's codestral model)
   - Null responses (Fireworks' qwen model)

4. **Confidence Levels**: Most models reported high confidence (0.9-1.0) for this simple factual question.

5. **Response Quality**: All successful models provided accurate answers with reasonable explanations.

## Recommendations

1. **Preferred Providers**: For applications requiring reliable structured output, OpenAI and Anthropic models demonstrated the highest reliability.

2. **Error Handling**: Implement robust error handling for rate limits and null responses.

3. **Model Selection**: When choosing models for structured output:
   - Verify function calling support for experimental models
   - Consider rate limits for high-volume applications
   - Test models with your specific schema before deployment

4. **Implementation Approach**: Use LangChain's `with_structured_output()` method for a simplified implementation across providers.

*Test conducted on March 1, 2025*