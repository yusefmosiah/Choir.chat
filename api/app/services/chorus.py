from app.config import Config
from app.utils import structured_chat_completion, get_embedding
from app.models.api import ActionResponse, ExperienceResponse, IntentionResponse, ObservationResponse, UnderstandingResponse, YieldResponse
from app.database import DatabaseClient
from typing import List, Dict, Any
import logging
import json

logger = logging.getLogger(__name__)

class ChorusService:
    def __init__(self, config: Config):
        self.config = config
        self.db = DatabaseClient(config)

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
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            # Convert dict to Pydantic model
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

            Relevant priors:
            {json.dumps(priors, indent=2)}
            """

            messages = [
                {"role": "system", "content": experience_prompt},
                {"role": "user", "content": "Please analyze these priors."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return ExperienceResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_experience: {e}")
            raise

    async def process_intention(
        self,
        content: str,
        action_response: str,
        experience_response: str,
        priors: Dict[str, Dict[str, Any]]
    ) -> IntentionResponse:
        """Process the intention phase - analyze intent and select relevant priors."""
        try:
            # Format priors for better prompt readability
            formatted_priors = "\n".join([
                f"ID: {prior_id}\nContent: {prior_data['content']}\nSimilarity: {prior_data['similarity']}"
                for prior_id, prior_data in priors.items()
            ])

            intention_prompt = f"""
            This is the Intention phase of the Chorus Cycle. Analyze the user's intent and select
            the most relevant priors that could help inform a response.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}

            Available priors:
            {formatted_priors}

            Select the most relevant priors by their IDs and explain your reasoning.
            """

            messages = [
                {"role": "system", "content": intention_prompt},
                {"role": "user", "content": "Please analyze the intent and select relevant priors."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            # Ensure selected_priors is included in the response
            response_data = result["content"]
            if "selected_priors" not in response_data:
                response_data["selected_priors"] = []

            # Ensure step is set correctly
            response_data["step"] = "intention"

            # Validate and return the response
            return IntentionResponse.model_validate(response_data)

        except Exception as e:
            logger.error(f"Error in process_intention: {e}")
            raise

    async def process_observation(
        self,
        content: str,
        action_response: str,
        experience_response: str,
        intention_response: str,
        selected_priors: Dict[str, Dict[str, Any]]
    ) -> ObservationResponse:
        """Process the observation phase - analyze patterns and insights."""
        try:
            # Format selected priors for better prompt readability
            formatted_priors = "\n".join([
                f"ID: {prior_id}\nContent: {prior_data['content']}\nSimilarity: {prior_data['similarity']}"
                for prior_id, prior_data in selected_priors.items()
            ])

            observation_prompt = f"""
            This is the Observation phase of the Chorus Cycle. Analyze patterns and insights
            from the selected priors and previous responses.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}
            Intention analysis: {intention_response}

            Selected priors:
            {formatted_priors}

            Please analyze patterns and provide insights based on these responses and priors.
            """

            messages = [
                {"role": "system", "content": observation_prompt},
                {"role": "user", "content": "Please analyze patterns and provide insights."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            # Validate and return the response
            return ObservationResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_observation: {e}")
            raise

    async def process_understanding(
        self,
        content: str,
        action_response: str,
        experience_response: str,
        intention_response: str,
        observation_response: str,
        patterns: List[Dict[str, str]],
        selected_priors: List[str]
    ) -> UnderstandingResponse:
        """Process the understanding phase - decide whether to yield or loop back."""
        try:
            understanding_prompt = f"""
            This is the Understanding phase of the Chorus Cycle. Analyze whether we have sufficient
            understanding to provide a final response, or if we need another iteration.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}
            Intention analysis: {intention_response}
            Observation response: {observation_response}

            Selected priors: {len(selected_priors)} priors were used
            Patterns identified: {json.dumps(patterns, indent=2)}

            Based on these responses and analyses:
            1. Determine if we have sufficient understanding to provide a final response
            2. If not, specify what additional information or analysis is needed
            3. Provide reasoning for the decision
            """

            messages = [
                {"role": "system", "content": understanding_prompt},
                {"role": "user", "content": "Please analyze our understanding and decide whether to yield or iterate."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            # Ensure required fields are present
            response_data = result["content"]
            if "should_yield" not in response_data:
                response_data["should_yield"] = True
            if not response_data["should_yield"] and "next_prompt" not in response_data:
                response_data["next_prompt"] = "Please provide more information."

            return UnderstandingResponse.model_validate(response_data)

        except Exception as e:
            logger.error(f"Error in process_understanding: {e}")
            raise

    async def process_yield(
        self,
        content: str,
        action_response: str,
        experience_response: str,
        intention_response: str,
        observation_response: str,
        understanding_response: str,
        selected_priors: List[str],
        priors: Dict[str, Dict[str, Any]]
    ) -> YieldResponse:
        """Process the yield phase - synthesize final response with citations."""
        try:
            # Filter and format selected priors
            selected_prior_data = {
                prior_id: prior_data
                for prior_id, prior_data in priors.items()
                if prior_id in selected_priors
            }

            formatted_priors = "\n".join([
                f"ID: {prior_id}\nContent: {prior_data['content']}\nSimilarity: {prior_data['similarity']}"
                for prior_id, prior_data in selected_prior_data.items()
            ])

            yield_prompt = f"""
            This is the Yield phase of the Chorus Cycle. Synthesize a final response that
            incorporates insights from all previous phases and selected priors.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}
            Intention analysis: {intention_response}
            Observation response: {observation_response}
            Understanding response: {understanding_response}

            Selected priors:
            {formatted_priors}

            Please provide a comprehensive final response that:
            1. Synthesizes insights from all phases
            2. Incorporates relevant information from selected priors
            3. Provides clear reasoning for conclusions
            4. Maintains high confidence in the accuracy of the response

            IMPORTANT: When citing priors, use markdown links in this format:
            [cited text](choir://choir.chat/<prior_id>)

            For example, if citing text from prior ID "dfd2bf18-9a54-07c0-540b-1f61c62588a7", write:
            [This is the cited text](choir://choir.chat/dfd2bf18-9a54-07c0-540b-1f61c62588a7)

            Make sure to:
            - Include citations for key insights and quotes
            - Use the exact prior IDs provided
            - Keep cited text concise and relevant
            - Integrate citations naturally into the response

            Ensure the response includes:
            - step: "yield"
            - content: your synthesized response with citations
            - confidence: a float between 0 and 1
            - reasoning: explanation of your synthesis
            """

            messages = [
                {"role": "system", "content": yield_prompt},
                {"role": "user", "content": "Please synthesize the final response with citations."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            # Ensure the step is correctly set
            response_data = result["content"]
            if "step" not in response_data or response_data["step"].lower() != "yield":
                response_data["step"] = "yield"

            return YieldResponse.model_validate(response_data)

        except Exception as e:
            logger.error(f"Error in process_yield: {e}")
            raise
