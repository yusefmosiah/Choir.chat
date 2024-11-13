from litellm import completion, get_supported_openai_params
import json
import os
from typing import Dict, Any

def test_model_compatibility(model: str, provider: str = None) -> Dict[str, Any]:
    """Test if a model supports structured outputs with JSON schema."""

    # Get supported parameters
    params = get_supported_openai_params(model=model, custom_llm_provider=provider)
    print(f"\nTesting {model}:")
    print(f"Supported parameters: {params}")

    # Define a simple schema
    json_schema = {
        "type": "object",
        "properties": {
            "step": {"type": "string"},
            "content": {"type": "string"},
            "confidence": {"type": "number"},
            "reasoning": {"type": "string"}
        },
        "required": ["step", "content", "confidence", "reasoning"]
    }

    # Test message
    messages = [
        {"role": "user", "content": "What is 2+2?"}
    ]

    try:
        # Try different formats based on provider
        if "azure" in model:
            print("\nTrying Azure format...")
            response = completion(
                model=model,
                messages=messages,
                response_format={
                    "type": "json_object",
                    "json_schema": json_schema
                }
            )
        elif "anthropic" in model:
            print("\nTrying Anthropic format...")
            response = completion(
                model=model,
                messages=messages,
                tools=[{
                    "type": "function",
                    "function": {
                        "name": "process_response",
                        "description": "Process the response in a structured format",
                        "parameters": json_schema
                    }
                }],
                tool_choice={"type": "function", "function": {"name": "process_response"}}
            )
        else:
            print("\nTrying default format...")
            response = completion(
                model=model,
                messages=messages,
                response_format={"type": "json_object", "schema": json_schema}
            )

        # Log raw response for debugging
        print(f"\nRaw response: {response}")

        # Try to parse the response
        content = json.loads(extract_content(response))
        print("✓ Model supports structured outputs")
        print(f"Sample response:\n{json.dumps(content, indent=2)}")
        return {"success": True, "response": content}

    except Exception as e:
        print(f"✗ Error: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__dict__'):
            print(f"Error attributes: {e.__dict__}")
        return {"success": False, "error": str(e)}

def extract_content(response):
    """Extract content from either standard response or function call response."""
    message = response.choices[0].message
    if message.content:
        return message.content
    elif message.tool_calls:
        return message.tool_calls[0].function.arguments
    else:
        raise ValueError("No content found in response")

if __name__ == "__main__":
    # Test Azure OpenAI
    if os.getenv("AZURE_API_KEY"):
        test_model_compatibility("azure/gpt-4o-2024-08-06")

    # Test Anthropic
    if os.getenv("ANTHROPIC_API_KEY"):
        test_model_compatibility("anthropic/claude-3-5-sonnet-20241022")
        test_model_compatibility("anthropic/claude-3-5-haiku-20241022")
