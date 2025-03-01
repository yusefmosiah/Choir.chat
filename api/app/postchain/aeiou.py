"""
AEIOU Cycle implementation using LangGraph.

This module implements the AEIOU cycle as described in the LangGraph PostChain plan:
1. Action: Initial response with "beginner's mind"
2. Experience: Enrichment with prior knowledge
3. Intention: Analysis of planned actions and consequences
4. Observation: Reflection on analysis and intentions
5. Update: Decision to loop back or proceed to yield
6. Yield: Final synthesized response
"""

import os
import logging
from typing import Dict, Any, List, Optional, TypedDict, Annotated, Literal, Tuple, Union

# LangGraph imports
from langgraph.graph import StateGraph, END

# LangChain model imports
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from langchain_cohere import ChatCohere
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage
from langchain_core.prompts import ChatPromptTemplate

from app.config import Config

# Configure logging
logger = logging.getLogger(__name__)

# Define the state schema for our AEIOU graph
class AEIOUState(TypedDict):
    messages: List[Any]  # List of messages in the conversation
    phase: str  # Current phase in the AEIOU cycle
    should_loop: bool  # Whether to loop back to Action or proceed to Yield
    context: Dict[str, Any]  # Context information for the conversation
    user_input: str  # The original user input
    final_response: Optional[str]  # The final response to return to the user
    max_loops: int  # Maximum number of loops allowed
    current_loop: int  # Current loop count

# System prompts for each phase
SYSTEM_PROMPTS = {
    "action": """You are in the ACTION phase of the AEIOU cycle.
In this phase, you should provide an initial response to the user's query with a "beginner's mind".
Focus on understanding the query and providing a direct, helpful response without overthinking.
Keep your response concise and focused on the immediate question.""",

    "experience": """You are in the EXPERIENCE phase of the AEIOU cycle.
In this phase, you should enrich your understanding with prior knowledge.
Consider what you know about the topic and how it relates to the user's query.
Identify relevant facts, concepts, and connections that could be helpful.""",

    "intention": """You are in the INTENTION phase of the AEIOU cycle.
In this phase, you should analyze planned actions and their potential consequences.
Consider what you're planning to tell the user and what impact it might have.
Identify any potential misunderstandings or areas where more clarity is needed.""",

    "observation": """You are in the OBSERVATION phase of the AEIOU cycle.
In this phase, you should reflect on your analysis and intentions.
Consider how well your planned response addresses the user's needs.
Identify any gaps or improvements that could be made to your response.""",

    "update": """You are in the UPDATE phase of the AEIOU cycle.
In this phase, you should decide whether to loop back to the Action phase or proceed to Yield.
If you believe your response needs significant improvement, return should_loop=True.
If you believe your response is ready to be delivered, return should_loop=False.

Your response should be in JSON format with a "should_loop" boolean field and a "reasoning" field explaining your decision.""",

    "yield": """You are in the YIELD phase of the AEIOU cycle.
In this phase, you should synthesize all previous thinking into a final response.
Your response should be clear, helpful, and directly address the user's query.
Incorporate insights from all previous phases to provide the best possible answer."""
}

class AEIOUCycle:
    """Implementation of the AEIOU cycle using LangGraph."""
    
    def __init__(self, config: Config, models: Optional[Dict[str, Any]] = None):
        """Initialize the AEIOU cycle.
        
        Args:
            config: The application configuration
            models: Optional dictionary of models to use for each phase
        """
        self.config = config
        self.models = models or self._setup_default_models()
        self.graph = self._create_aeiou_graph()
    
    def _setup_default_models(self) -> Dict[str, Any]:
        """Set up default models for each phase of the AEIOU cycle."""
        
        # Default model (used if a specific phase doesn't have a model)
        default_model = ChatOpenAI(
            api_key=self.config.OPENAI_API_KEY,
            model=self.config.OPENAI_GPT_4O,
            temperature=0
        )
        
        # Phase-specific models
        models = {
            "default": default_model,
            "action": default_model,
            "experience": default_model,
            "intention": default_model,
            "observation": default_model,
            "update": default_model,
            "yield": default_model
        }
        
        return models
    
    def _create_aeiou_graph(self) -> Any:
        """Create a LangGraph for the AEIOU cycle."""
        
        # Define the nodes in our graph
        def action_handler(state: AEIOUState) -> AEIOUState:
            """Handle the Action phase."""
            new_state = state.copy()
            new_state["phase"] = "action"
            
            # Create prompt for this phase
            prompt = ChatPromptTemplate.from_messages([
                ("system", SYSTEM_PROMPTS["action"]),
                ("human", state["user_input"])
            ])
            
            # Get model for this phase
            model = self.models.get("action", self.models.get("default"))
            
            # Create chain and invoke
            chain = prompt | model
            response = chain.invoke({})
            
            # Update state
            new_state["context"]["action_response"] = response.content
            new_state["messages"].append(SystemMessage(content=f"ACTION PHASE: {SYSTEM_PROMPTS['action']}"))
            new_state["messages"].append(HumanMessage(content=state["user_input"]))
            new_state["messages"].append(AIMessage(content=response.content))
            
            return new_state
        
        def experience_handler(state: AEIOUState) -> AEIOUState:
            """Handle the Experience phase."""
            new_state = state.copy()
            new_state["phase"] = "experience"
            
            # Create prompt for this phase
            prompt = ChatPromptTemplate.from_messages([
                ("system", SYSTEM_PROMPTS["experience"]),
                ("human", f"User query: {state['user_input']}\nInitial response: {state['context'].get('action_response', '')}")
            ])
            
            # Get model for this phase
            model = self.models.get("experience", self.models.get("default"))
            
            # Create chain and invoke
            chain = prompt | model
            response = chain.invoke({})
            
            # Update state
            new_state["context"]["experience_response"] = response.content
            new_state["messages"].append(SystemMessage(content=f"EXPERIENCE PHASE: {SYSTEM_PROMPTS['experience']}"))
            new_state["messages"].append(HumanMessage(content=f"User query: {state['user_input']}\nInitial response: {state['context'].get('action_response', '')}"))
            new_state["messages"].append(AIMessage(content=response.content))
            
            return new_state
        
        def intention_handler(state: AEIOUState) -> AEIOUState:
            """Handle the Intention phase."""
            new_state = state.copy()
            new_state["phase"] = "intention"
            
            # Create prompt for this phase
            prompt = ChatPromptTemplate.from_messages([
                ("system", SYSTEM_PROMPTS["intention"]),
                ("human", f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
""")
            ])
            
            # Get model for this phase
            model = self.models.get("intention", self.models.get("default"))
            
            # Create chain and invoke
            chain = prompt | model
            response = chain.invoke({})
            
            # Update state
            new_state["context"]["intention_response"] = response.content
            new_state["messages"].append(SystemMessage(content=f"INTENTION PHASE: {SYSTEM_PROMPTS['intention']}"))
            new_state["messages"].append(HumanMessage(content=f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
"""))
            new_state["messages"].append(AIMessage(content=response.content))
            
            return new_state
        
        def observation_handler(state: AEIOUState) -> AEIOUState:
            """Handle the Observation phase."""
            new_state = state.copy()
            new_state["phase"] = "observation"
            
            # Create prompt for this phase
            prompt = ChatPromptTemplate.from_messages([
                ("system", SYSTEM_PROMPTS["observation"]),
                ("human", f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
Intention analysis: {state['context'].get('intention_response', '')}
""")
            ])
            
            # Get model for this phase
            model = self.models.get("observation", self.models.get("default"))
            
            # Create chain and invoke
            chain = prompt | model
            response = chain.invoke({})
            
            # Update state
            new_state["context"]["observation_response"] = response.content
            new_state["messages"].append(SystemMessage(content=f"OBSERVATION PHASE: {SYSTEM_PROMPTS['observation']}"))
            new_state["messages"].append(HumanMessage(content=f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
Intention analysis: {state['context'].get('intention_response', '')}
"""))
            new_state["messages"].append(AIMessage(content=response.content))
            
            return new_state
        
        def update_handler(state: AEIOUState) -> AEIOUState:
            """Handle the Update phase."""
            new_state = state.copy()
            new_state["phase"] = "update"
            
            # Increment loop counter
            new_state["current_loop"] = state["current_loop"] + 1
            
            # Check if we've reached the maximum number of loops
            if new_state["current_loop"] >= state["max_loops"]:
                logger.info(f"Reached maximum number of loops ({state['max_loops']}). Proceeding to Yield.")
                new_state["should_loop"] = False
                new_state["context"]["update_response"] = f"Maximum loops reached ({state['max_loops']}). Proceeding to Yield."
                return new_state
            
            # Create prompt for this phase
            prompt = ChatPromptTemplate.from_messages([
                ("system", SYSTEM_PROMPTS["update"]),
                ("human", f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
Intention analysis: {state['context'].get('intention_response', '')}
Observation reflection: {state['context'].get('observation_response', '')}
Current loop: {new_state["current_loop"]} of {state["max_loops"]}

Based on the above, should we loop back to the Action phase to improve our response, or proceed to the Yield phase to deliver our final answer?
Respond with a JSON object containing "should_loop" (boolean) and "reasoning" (string).
""")
            ])
            
            # Get model for this phase
            model = self.models.get("update", self.models.get("default"))
            
            # Create chain and invoke
            chain = prompt | model
            response = chain.invoke({})
            
            # Parse the response to determine if we should loop
            response_text = response.content.lower()
            should_loop = "true" in response_text and "should_loop" in response_text
            
            # Update state
            new_state["context"]["update_response"] = response.content
            new_state["should_loop"] = should_loop
            new_state["messages"].append(SystemMessage(content=f"UPDATE PHASE: {SYSTEM_PROMPTS['update']}"))
            new_state["messages"].append(HumanMessage(content=f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
Intention analysis: {state['context'].get('intention_response', '')}
Observation reflection: {state['context'].get('observation_response', '')}
Current loop: {new_state["current_loop"]} of {state["max_loops"]}

Based on the above, should we loop back to the Action phase to improve our response, or proceed to the Yield phase to deliver our final answer?
"""))
            new_state["messages"].append(AIMessage(content=response.content))
            
            return new_state
        
        def yield_handler(state: AEIOUState) -> AEIOUState:
            """Handle the Yield phase."""
            new_state = state.copy()
            new_state["phase"] = "yield"
            
            # Create prompt for this phase
            prompt = ChatPromptTemplate.from_messages([
                ("system", SYSTEM_PROMPTS["yield"]),
                ("human", f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
Intention analysis: {state['context'].get('intention_response', '')}
Observation reflection: {state['context'].get('observation_response', '')}
Update decision: {state['context'].get('update_response', '')}
Total loops completed: {state["current_loop"]} of maximum {state["max_loops"]}

Synthesize all of the above into a final response to the user's query.
""")
            ])
            
            # Get model for this phase
            model = self.models.get("yield", self.models.get("default"))
            
            # Create chain and invoke
            chain = prompt | model
            response = chain.invoke({})
            
            # Update state
            new_state["context"]["yield_response"] = response.content
            new_state["final_response"] = response.content
            new_state["messages"].append(SystemMessage(content=f"YIELD PHASE: {SYSTEM_PROMPTS['yield']}"))
            new_state["messages"].append(HumanMessage(content=f"""
User query: {state['user_input']}
Initial response: {state['context'].get('action_response', '')}
Experience insights: {state['context'].get('experience_response', '')}
Intention analysis: {state['context'].get('intention_response', '')}
Observation reflection: {state['context'].get('observation_response', '')}
Update decision: {state['context'].get('update_response', '')}
Total loops completed: {state["current_loop"]} of maximum {state["max_loops"]}

Synthesize all of the above into a final response to the user's query.
"""))
            new_state["messages"].append(AIMessage(content=response.content))
            
            return new_state
        
        def update_router(state: AEIOUState) -> Literal["action", "yield"]:
            """Route from Update to either Action or Yield based on should_loop."""
            return "action" if state["should_loop"] else "yield"
        
        # Create the graph
        workflow = StateGraph(AEIOUState)
        
        # Add nodes
        workflow.add_node("action", action_handler)
        workflow.add_node("experience", experience_handler)
        workflow.add_node("intention", intention_handler)
        workflow.add_node("observation", observation_handler)
        workflow.add_node("update", update_handler)
        workflow.add_node("yield", yield_handler)
        
        # Add edges
        workflow.add_edge("action", "experience")
        workflow.add_edge("experience", "intention")
        workflow.add_edge("intention", "observation")
        workflow.add_edge("observation", "update")
        
        # Add conditional edge from update
        workflow.add_conditional_edges(
            "update",
            update_router,
            {
                "action": "action",
                "yield": "yield"
            }
        )
        
        # Set the entry point
        workflow.set_entry_point("action")
        
        # Add edge from yield to end
        workflow.add_edge("yield", END)
        
        # Compile the graph
        return workflow.compile()
    
    def process(self, user_input: str, max_loops: int = 2) -> Dict[str, Any]:
        """Process a user input through the AEIOU cycle.
        
        Args:
            user_input: The user's input query
            max_loops: Maximum number of loops to allow (default: 2)
            
        Returns:
            A dictionary containing the final response and other information
        """
        try:
            # Initialize state
            initial_state = {
                "messages": [],
                "phase": "start",
                "should_loop": False,
                "context": {},
                "user_input": user_input,
                "final_response": None,
                "max_loops": max_loops,
                "current_loop": 0
            }
            
            # Run the graph
            logger.info(f"Running AEIOU cycle with input: {user_input}")
            result = self.graph.invoke(initial_state)
            
            # Log the result
            logger.info(f"AEIOU cycle completed. Final phase: {result['phase']}")
            logger.info(f"Loops completed: {result['current_loop']} of maximum {max_loops}")
            
            return {
                "status": "success",
                "final_response": result["final_response"],
                "context": result["context"],
                "phases_visited": [msg.content.split(":")[0].strip() for msg in result["messages"] if isinstance(msg, SystemMessage)],
                "loops_completed": result["current_loop"]
            }
        except Exception as e:
            logger.error(f"Error in AEIOU cycle: {str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }
    
    def setup_multi_provider_models(self) -> None:
        """Set up models from different providers for each phase."""
        try:
            # Default model (used if a specific phase doesn't have a model)
            default_model = ChatOpenAI(
                api_key=self.config.OPENAI_API_KEY,
                model=self.config.OPENAI_GPT_4O,
                temperature=0
            )
            
            # Phase-specific models
            models = {
                "default": default_model
            }
            
            # Action phase model
            if self.config.OPENAI_API_KEY:
                models["action"] = ChatOpenAI(
                    api_key=self.config.OPENAI_API_KEY,
                    model=self.config.OPENAI_GPT_4O_MINI,
                    temperature=0
                )
            
            # Experience phase model
            if self.config.ANTHROPIC_API_KEY:
                models["experience"] = ChatAnthropic(
                    api_key=self.config.ANTHROPIC_API_KEY,
                    model=self.config.ANTHROPIC_CLAUDE_35_HAIKU,
                    temperature=0
                )
            
            # Intention phase model
            if self.config.GOOGLE_API_KEY:
                models["intention"] = ChatGoogleGenerativeAI(
                    api_key=self.config.GOOGLE_API_KEY,
                    model=self.config.GOOGLE_GEMINI_20_FLASH,
                    temperature=0
                )
            
            # Observation phase model
            if self.config.MISTRAL_API_KEY:
                models["observation"] = ChatMistralAI(
                    api_key=self.config.MISTRAL_API_KEY,
                    model=self.config.MISTRAL_PIXTRAL_12B,
                    temperature=0
                )
            
            # Update phase model
            if self.config.FIREWORKS_API_KEY:
                models["update"] = ChatFireworks(
                    api_key=self.config.FIREWORKS_API_KEY,
                    model=f"accounts/fireworks/models/{self.config.FIREWORKS_DEEPSEEK_V3}",
                    temperature=0
                )
            
            # Yield phase model
            if self.config.COHERE_API_KEY:
                models["yield"] = ChatCohere(
                    api_key=self.config.COHERE_API_KEY,
                    model=self.config.COHERE_COMMAND_R7B,
                    temperature=0
                )
            
            self.models = models
            logger.info("Multi-provider models set up successfully")
        except Exception as e:
            logger.error(f"Error setting up multi-provider models: {str(e)}")
            # Fall back to default models
            self.models = self._setup_default_models()