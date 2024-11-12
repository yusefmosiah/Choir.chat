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

    async def process_intention(
        self,
        content: str,
        action_response: str,
        experience_response: str,
        priors: Dict[str, Dict[str, Any]]
    ) -> IntentionResponse:
        """Process the intention phase - analyze intent and select relevant priors."""
        try:
            intention_prompt = f"""
            This is the Intention phase of the Chorus Cycle. Analyze the user's intent and select
            the most relevant priors that could help inform a response.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}

            Your json-formatted response must follow this exact format:
            {{
                "reasoning": "Why you selected these priors",
                "selected_priors": ["id1", "id2", ...],  # IDs of up to 10 most relevant priors
                "response": "Your analysis of the user's intent",
                "confidence": 0.0 to 1.0,
            }}

            Available priors:
            {json.dumps(priors, indent=2)}
            """

            messages = [
                {"role": "system", "content": intention_prompt},
                {"role": "user", "content": "Please analyze the intent and select relevant priors."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config,
                response_format={"type": "json_object"}
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
        selected_priors: Dict[str, Dict[str, Any]]
    ) -> ObservationResponse:
        """Process the observation phase - analyze patterns and store insights."""
        try:
            observation_prompt = f"""
            This is the Observation phase of the Chorus Cycle. Analyze patterns and insights
            from the selected priors and previous responses.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}
            Intention analysis: {intention_response}

            Your json-formatted response must follow this exact format:
            {{
                "reasoning": "Your analysis of patterns and insights",
                "patterns": [
                    {{"type": "theme|insight|connection", "description": "Pattern description"}},
                    // Add more patterns...
                ],
                "response": "Your synthesis of observations",
                "confidence": 0.0 to 1.0
            }}

            Selected priors:
            {json.dumps(selected_priors, indent=2)}
            """

            messages = [
                {"role": "system", "content": observation_prompt},
                {"role": "user", "content": "Please analyze patterns and provide your JSON response."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config,
                response_format={"type": "json_object"}
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            observation_data = result["content"]

            # Store the observation in the vector database
            observation_text = f"""
            Query: {content}
            Observation: {observation_data['response']}
            Patterns: {json.dumps(observation_data['patterns'])}
            """

            # Get embedding for the observation
            embedding = await get_embedding(observation_text, self.config.EMBEDDING_MODEL)

            # Store in database with metadata
            save_result = await self.db.save_message({
                "content": observation_text,
                "vector": embedding,
                "metadata": {
                    "type": "observation",
                    "patterns": observation_data["patterns"],
                    "confidence": observation_data["confidence"],
                    "reasoning": observation_data["reasoning"],
                    "selected_priors": list(selected_priors.keys())
                }
            })

            # Add ID to observation data and create response
            observation_data["id"] = save_result["id"]
            return ObservationResponse.model_validate(observation_data)

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
        patterns: List[Dict[str, Any]],
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

            Patterns identified:
            {json.dumps(patterns, indent=2)}

            Selected priors: {len(selected_priors)} priors

            Your json-formatted response must follow this exact format:
            {{
                "reasoning": "Your analysis of whether we have sufficient understanding",
                "should_yield": true/false,  # Whether to proceed to yield or loop back
                "confidence": 0.0 to 1.0,
                "next_action": null or "description of what to explore next",
                "next_prompt": null or "specific prompt for next action phase"  # This will be used directly in next iteration
            }}

            If should_yield is false, you MUST provide both next_action and next_prompt.
            The next_prompt will be used verbatim as the input for the next action phase,
            so make it clear and specific.
            """

            messages = [
                {"role": "system", "content": understanding_prompt},
                {"role": "user", "content": "Please analyze our understanding and decide whether to yield or iterate."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config,
                response_format={"type": "json_object"}
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
        selected_priors: Dict[str, Dict[str, Any]]
    ) -> YieldResponse:
        """Process the yield phase - synthesize final response with citations."""
        try:
            yield_prompt = f"""
            This is the Yield phase of the Chorus Cycle. Synthesize a final response that
            incorporates insights from the selected priors and previous responses.

            Current input: {content}
            Action response: {action_response}
            Experience analysis: {experience_response}
            Intention analysis: {intention_response}
            Observation response: {observation_response}
            Understanding response: {understanding_response}

            Your json-formatted response must follow this exact format:
            {{
                "reasoning": "How you incorporated priors and insights",
                "citations": [
                    {{
                        "prior_id": "id of cited prior",
                        "content": "relevant content from prior",
                        "context": "how this prior informed the response"
                    }}
                ],
                "response": "Final synthesized response with inline citations [1], [2], etc.",
                "confidence": 0.0 to 1.0
            }}

            Selected priors:
            {json.dumps(selected_priors, indent=2)}

            Make sure to:
1. Cite specific priors using [1], [2] etc. in the response
2. Explain how each citation informed the response
3. Maintain coherent flow while incorporating citations
            """

            messages = [
                {"role": "system", "content": yield_prompt},
                {"role": "user", "content": "Please synthesize the final response with citations."}
            ]

            result = await structured_chat_completion(
                messages=messages,
                config=self.config,
                response_format={"type": "json_object"}
            )

            if result["status"] == "error":
                raise Exception(result["content"])

            return YieldResponse.model_validate(result["content"])

        except Exception as e:
            logger.error(f"Error in process_yield: {e}")
            raise
