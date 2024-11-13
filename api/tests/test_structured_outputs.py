from litellm import completion
import json
import os
from typing import Dict, Any
from app.models.api import ChorusResponse

def test_structured_outputs():
    """Test structured outputs with different LLM providers."""

    print("\nTesting structured outputs...")

    # Define our schema using Pydantic model
    schema = ChorusResponse.model_json_schema()
    print(f"\nUsing schema:\n{json.dumps(schema, indent=2)}")

    test_message = "What is 2+2?"
    messages = [{"role": "user", "content": test_message}]

    # Test Azure OpenAI
    if os.getenv("AZURE_API_KEY"):
        print("\nTesting Azure OpenAI...")
        try:
            response = completion(
                model="azure/gpt-4o-2024-08-06",
                messages=messages,
                response_format={
                    "type": "json_schema",
                    "json_schema": {
                        "name": "ChorusResponse",
                        "schema": schema
                    }
                }
            )
            print("\nAzure response:")
            print_response(response)
        except Exception as e:
            print(f"Azure error: {str(e)}")

    # Test Anthropic
    if os.getenv("ANTHROPIC_API_KEY"):
        print("\nTesting Anthropic Claude...")
        try:
            response = completion(
                model="anthropic/claude-3-5-haiku-20241022",
                messages=messages,
                tools=[{
                    "type": "function",
                    "function": {
                        "name": "process_response",
                        "description": "Process the response in a structured format",
                        "parameters": schema
                    }
                }],
                tool_choice={"type": "function", "function": {"name": "process_response"}}
            )
            print("\nAnthropic response:")
            print_response(response)
        except Exception as e:
            print(f"Anthropic error: {str(e)}")

def print_response(response):
    """Pretty print the response."""
    message = response.choices[0].message

    # Handle function call responses
    if hasattr(message, 'tool_calls') and message.tool_calls:
        content = message.tool_calls[0].function.arguments
    else:
        content = message.content

    # Parse and print the JSON
    try:
        parsed = json.loads(content)
        print(json.dumps(parsed, indent=2))
    except:
        print(content)

if __name__ == "__main__":
    test_structured_outputs()
