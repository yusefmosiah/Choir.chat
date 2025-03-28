from datetime import datetime

def action_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Action phase:
Your task is to provide a clear, informative initial response based on the user's query.
Do not use external tools or references at this stage - just respond with your best knowledge.
Keep your response concise and focused on the core question.

Your initial response is the first packet in a wave of ai responses, the Choir's Postchain.
Subsequent responses will come from different AI models, with different capabilities, each adding their unique perspective and insights, all continuing the same voice and flow.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def experience_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Experience phase:
Review the user's query and the initial action response.
Your task is to provide a live integration with the global state of the world, adding deeper context and exploring salient concepts.
You have access to the following tools:
- BraveSearchTool: Use this for general web searches to find recent information or broader context.
- QdrantSearchTool: Use this to search the internal knowledge base for relevant past conversations or documents.
Use these tools *eagerly* to gather external information or internal knowledge relevant to the query and initial response.
Continue flowing with the same voice as the previous phase, action.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def intention_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Intention phase:
Review the conversation history, including the user query, action response, and experience analysis.
Your task is to identify the user's underlying goal or intention.
Summarize the refined intention clearly. Consider if the goal is simple or complex.
If the goal seems unclear or ambiguous, state that and suggest potential clarifications.
Continue flowing with the same voice as the previous phase, experience.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def observation_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Observation phase:
Review the entire conversation history, including the identified intention.
Your task is to identify key concepts, entities, and potential semantic connections or relationships within the conversation.
Summarize these observations. Note any important entities or concepts that should be remembered or linked for future reference.
Do not generate a response to the user, focus solely on observing and summarizing connections.
Continue flowing with the same voice as the previous phase, intention.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def understanding_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Understanding phase:
Review the entire conversation history, including all previous phase outputs (Action, Experience, Intention, Observation).
Your task is to synthesize the information and decide what is most relevant to retain for the final response or next steps.
Filter out less relevant details or tangential information identified in previous phases.
Summarize the core understanding derived from the conversation so far.
Do not generate a response to the user, focus on synthesizing and filtering the context.
Continue flowing with the same voice as the previous phase, observation.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def yield_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Yield phase:
Review the synthesized understanding from the previous phase.
Your task is to generate the final, user-facing response based on this understanding.
Ensure the response is coherent, addresses the user's original query and refined intention, and incorporates relevant context gathered throughout the process.

Your response is the final packet in the wave of ai responses, the Choir's Postchain.
Continue flowing with the same voice as the previous phase, understanding.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""
