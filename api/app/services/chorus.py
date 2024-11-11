from app.config import Config
from app.utils import structured_chat_completion
from app.models.api import ActionResponse, ExperienceResponse
from typing import List, Dict, Any
import logging
import json

logger = logging.getLogger(__name__)

class ChorusService:
    def __init__(self, config: Config):
        self.config = config

    async def process_action(self, content: str) -> ActionResponse:
        """Process the action phase - pure response without context."""
        try:
            action_prompt = """
            This is the Action phase of the Chorus Cycle. Provide an immediate, direct response
            to the user's input with "beginner's mind" - without overthinking or gathering context.
            """

            messages = [
                {"role": "system", "content": action_prompt},
                {"role": "user", "content": content}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config,
                response_format=ActionResponse
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return ActionResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_action: {e}")
            raise

    async def process_experience(self, content: str, action_response: str, priors: List[Dict[str, Any]]) -> ExperienceResponse:
        """Process the experience phase - analyze provided priors."""
        try:
            experience_prompt = f"""
            This is the Experience phase of the Chorus Cycle. Review these {len(priors)} priors
            and explain how they might relate to the current context.

            Current input: {content}
            Previous action response: {action_response}

            Your response must follow this exact format:
            {{
                "response": "Your analysis of how these priors relate to the query",
                "confidence": 0.0 to 1.0,
                "synthesis": "Your synthesis of how these priors connect to the current context"
            }}

            Relevant priors:
            {json.dumps(priors, indent=2)}
            """

            messages = [
                {"role": "system", "content": experience_prompt},
                {"role": "user", "content": "Please analyze these priors and provide your JSON response."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config,
                response_format={"type": "json_object"}
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return ExperienceResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_experience: {e}")
            raise
