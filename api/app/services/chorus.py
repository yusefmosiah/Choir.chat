from app.config import Config
from app.utils import structured_chat_completion, get_embedding
from app.models.api import ActionResponse, ExperienceResponse, IntentionResponse, ObservationResponse, UnderstandingResponse, YieldResponse, MessageContext
from app.database import DatabaseClient
from typing import List, Dict, Any, Optional
import logging
import json

logger = logging.getLogger(__name__)

class ChorusService:
    def __init__(self, config: Config):
        self.config = config
        self.db = DatabaseClient(config)

    async def process_action(self, content: str, context: Optional[List[MessageContext]] = None) -> ActionResponse:
        """Process the action phase with proper chat context."""
        try:
            # Start with system message
            messages = [
                {"role": "system", "content": "This is the Action phase of the Chorus Cycle. Provide a direct response to the user's input."}
            ]

            # Add context messages in chronological order
            if context:
                for msg in context:
                    if msg.content != "...":  # Skip placeholder messages
                        role = "user" if msg.is_user else "assistant"
                        messages.append({"role": role, "content": msg.content})

            # Add current user message
            messages.append({"role": "user", "content": content})

            print(f"AAAAction messages with context: {messages}")

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return ActionResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_action: {e}")
            raise

    async def process_experience(
        self,
        content: str,
        action_response: str,
        priors: List[Dict[str, Any]],
        context: Optional[List[MessageContext]] = None
    ) -> ExperienceResponse:
        """Process the experience phase with proper chat context."""
        try:
            # Start with system message
            messages = [
                {"role": "system", "content": "This is the Experience phase of the Chorus Cycle. Review these priors and explain how they might relate to the current context."}
            ]

            # Add context messages
            if context:
                for msg in context:
                    if msg.content != "...":
                        role = "user" if msg.is_user else "assistant"
                        messages.append({"role": role, "content": msg.content})

            experience_prompt = f"""
            Current input: {content}
            Previous action response: {action_response}

            Relevant priors:
            {json.dumps(priors, indent=2)}
            """

            messages.append({"role": "user", "content": experience_prompt})

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
        priors: Dict[str, Dict[str, Any]],
        context: Optional[List[MessageContext]] = None
    ) -> IntentionResponse:
        """Process the intention phase with proper chat context."""
        try:
            # Start with system message
            messages = [
                {"role": "system", "content": "This is the Intention phase of the Chorus Cycle. Analyze intent and select relevant priors."}
            ]

            # Add context messages
            if context:
                for msg in context:
                    if msg.content != "...":
                        role = "user" if msg.is_user else "assistant"
                        messages.append({"role": role, "content": msg.content})

            # Format priors for better prompt readability
            formatted_priors = "\n".join([
                f"ID: {prior_id}\nContent: {prior_data['content']}\nSimilarity: {prior_data['similarity']}"
                for prior_id, prior_data in priors.items()
            ])

            intention_prompt = f"""
            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}

            Available priors:
            {formatted_priors}
            """

            messages.append({"role": "user", "content": intention_prompt})

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return IntentionResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_intention: {e}")
            raise

    async def process_observation(
        self,
        content: str,
        action_response: str,
        experience_response: str,
        intention_response: str,
        selected_priors: Dict[str, Dict[str, Any]],
        context: Optional[List[MessageContext]] = None
    ) -> ObservationResponse:
        """Process the observation phase with proper chat context."""
        try:
            # Start with system message
            messages = [
                {"role": "system", "content": "This is the Observation phase of the Chorus Cycle. Analyze patterns and insights."}
            ]

            # Add context messages
            if context:
                for msg in context:
                    if msg.content != "...":
                        role = "user" if msg.is_user else "assistant"
                        messages.append({"role": role, "content": msg.content})

            # Format selected priors for better prompt readability
            formatted_priors = "\n".join([
                f"ID: {prior_id}\nContent: {prior_data['content']}\nSimilarity: {prior_data['similarity']}"
                for prior_id, prior_data in selected_priors.items()
            ])

            observation_prompt = f"""
            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}
            Intention analysis: {intention_response}

            Selected priors:
            {formatted_priors}

            Please analyze patterns and provide insights based on these responses and priors.
            """

            messages.append({"role": "user", "content": observation_prompt})

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
        selected_priors: List[str],
        context: Optional[List[MessageContext]] = None
    ) -> UnderstandingResponse:
        """Process the understanding phase with proper chat context."""
        try:
            # Start with system message
            messages = [
                {"role": "system", "content": "This is the Understanding phase of the Chorus Cycle. Analyze whether we have sufficient understanding to provide a final response."}
            ]

            # Add context messages
            if context:
                for msg in context:
                    if msg.content != "...":
                        role = "user" if msg.is_user else "assistant"
                        messages.append({"role": role, "content": msg.content})

            understanding_prompt = f"""
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

            messages.append({"role": "user", "content": understanding_prompt})

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return UnderstandingResponse.model_validate(result["content"])

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
        priors: Dict[str, Dict[str, Any]],
        context: Optional[List[MessageContext]] = None
    ) -> YieldResponse:
        """Process the yield phase with proper chat context."""
        try:
            # Start with system message
            messages = [
                {"role": "system", "content": "This is the Yield phase of the Chorus Cycle. Synthesize a final response with citations."}
            ]

            # Add context messages
            if context:
                for msg in context:
                    if msg.content != "...":
                        role = "user" if msg.is_user else "assistant"
                        messages.append({"role": role, "content": msg.content})

            # Format selected priors
            formatted_priors = "\n".join([
                f"ID: {prior_id}\nContent: {prior_data['content']}\nSimilarity: {prior_data['similarity']}"
                for prior_id, prior_data in priors.items()
                if prior_id in selected_priors
            ])

            yield_prompt = f"""
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
            3. Uses markdown citations in format: [cited text](choir://choir.chat/<prior_id>)
            4. Provides clear reasoning for conclusions
            """

            messages.append({"role": "user", "content": yield_prompt})

            result = await structured_chat_completion(
                messages=messages,
                config=self.config
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return YieldResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_yield: {e}")
            raise
