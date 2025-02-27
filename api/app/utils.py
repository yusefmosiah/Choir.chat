import logging
from typing import List, Dict, Any, Optional
from .config import Config
from litellm import completion, embedding
import litellm
import json
from .models.api import (
    ChorusResponse,
    ActionResponse,
    ExperienceResponse,
    IntentionResponse,
    ObservationResponse,
    UnderstandingResponse,
    YieldResponse
)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Enable verbose logging for litellm
# litellm.set_verbose = True

async def get_embedding(input_text: str, model: str) -> List[float]:
    try:
        # Chunk the input text
        chunks = chunk_text(input_text, chunk_size=4000, overlap=200)
        config = Config()  # Instantiate Config

        # Get embeddings for each chunk
        chunk_embeddings = []
        for chunk in chunks:
            response = embedding(
                model=f"azure/{model}",
                input=chunk,
                api_key=config.AZURE_API_KEY,
                api_base=config.AZURE_API_BASE,
                api_version=config.AZURE_API_VERSION
            )
            embedding_vector = response['data'][0]['embedding']
            # Validate vector size
            if len(embedding_vector) != config.VECTOR_SIZE:
                logger.error(f"Embedding vector size mismatch: got {len(embedding_vector)}, expected {config.VECTOR_SIZE}")
                continue
            chunk_embeddings.append(embedding_vector)

        # Average the embeddings if there are multiple chunks
        if len(chunk_embeddings) > 1:
            averaged_embedding = [sum(x) / len(chunk_embeddings) for x in zip(*chunk_embeddings)]
            return averaged_embedding
        elif len(chunk_embeddings) == 1:
            return chunk_embeddings[0]
        else:
            logger.error("No valid embeddings generated")
            return [0.0] * config.VECTOR_SIZE  # Return zero vector as fallback
    except Exception as e:
        logger.error(f"Error getting embedding: {e}", exc_info=True)
        return [0.0] * Config().VECTOR_SIZE  # Return zero vector as fallback

async def chat_completion(messages: List[Dict[str, str]], model: str, max_tokens: int, temperature: float) -> str:
    try:
        response = completion(
            model=model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature
        )
        if response and response.choices:
            return response.choices[0].message.content or ""
        else:
            logger.error("No choices returned in chat completion response")
            return "error"
    except Exception as e:
        logger.error(f"Error during chat completion: {e}")
        return "error"

def chunk_text(text: str, chunk_size: int, overlap: int) -> List[str]:
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

async def structured_chat_completion(
    messages: List[Dict[str, str]],
    config: Config,
    response_format: Optional[Any] = None
) -> Dict[str, Any]:
    try:
        # Get the appropriate response model based on the phase
        phase = messages[0]["content"].split()[3].lower()  # Extract phase from "This is the X phase..."
        response_models = {
            "action": ActionResponse,
            "experience": ExperienceResponse,
            "intention": IntentionResponse,
            "observation": ObservationResponse,
            "understanding": UnderstandingResponse,
            "yield": YieldResponse
        }
        model = response_models.get(phase, ChorusResponse)

        # Get schema from pydantic model
        schema = model.model_json_schema()
        logger.info(f"Using schema for {phase} phase: {json.dumps(schema, indent=2)}")

        # Make the API call with function calling format
        # this is an anthropic flavored way to do json structured output with function calling
        # it's the first way i could get working
        # in future, we should support other ai model providers
        response = completion(
            model=config.OPENROUTER_CLAUDE_3_5_HAIKU,
            messages=messages,
            tools=[{
                "type": "function",
                "function": {
                    "name": "process_response",
                    "description": f"Process the response for {phase} phase",
                    "parameters": schema
                }
            }],
            tool_choice={"type": "function", "function": {"name": "process_response"}}
        )

        # Debug log the response
        logger.info(f"Raw response: {response}")

        # Extract content from function call
        content = json.loads(response.choices[0].message.tool_calls[0].function.arguments)
        logger.info(f"Parsed content: {content}")

        return {
            "status": "success",
            "content": content
        }

    except Exception as e:
        logger.error(f"Error in structured chat completion: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "content": f"An error occurred: {str(e)}"
        }

__all__ = ['get_embedding', 'chat_completion', 'chunk_text', 'structured_chat_completion']
