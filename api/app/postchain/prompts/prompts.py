from datetime import datetime

def action_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Action phase:
Your task is to provide a clear, informative initial response based on the user's query.
Do not use external tools or references at this stage - just respond with your best knowledge.
Keep your response concise and focused on the core question.

IMPORTANT: This is the first phase in the Choir's Postchain system. Your response will be followed by additional phases that will:
1. Search internal knowledge (Experience Vectors phase)
2. Search the web for current information (Experience Web phase)
3. Analyze the user's intention (Intention phase)
4. Identify key concepts and relationships (Observation phase)
5. Synthesize all information (Understanding phase)
6. Generate a final response (Yield phase)

Your initial response is the first packet in this wave of AI responses. Subsequent phases will continue with the same voice and flow you establish here.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def experience_vectors_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Experience Vectors phase:
Review the user's query and the Action response.
Your task is to analyze the vector search results that have been automatically retrieved from our internal knowledge database.

IMPORTANT: Vector search results have already been performed and are provided to you.

When analyzing the vector search results:
1. Focus on the most relevant results (those with higher similarity scores)
2. Explain how each result relates to the user's query
3. Synthesize insights from multiple results when appropriate
4. Identify any contradictions or gaps in the information

REQUIRED: Throughout your response, whenever you reference vector results, you MUST use the <vid>vector_id</vid> tag syntax (e.g., <vid>abc123</vid>) to refer to specific vector IDs. These references will become clickable in the UI, allowing users to view the full content of each result. Always use the exact vector ID as shown in the search results. Group related results together when appropriate (e.g., "Results <vid>abc123</vid>, <vid>def456</vid>, and <vid>ghi789</vid> all discuss...").

NOVELTY REWARDS: The system has analyzed the user's query for novelty and may have issued CHOIR token rewards based on how unique the query is compared to existing knowledge. If a reward was issued, acknowledge it in your response.

After analyzing the search results, create a structured summary section with bullet points linking to the most salient results using the <vid>vector_id</vid> tag syntax.

Continue flowing with the same voice as the previous phase, Action.

Begin your response with information about novelty rewards.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def experience_web_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Experience Web phase:
Review the conversation so far (User Query, Action, Experience Vectors).
Your task is to analyze the web search results that have been automatically retrieved for the user's query.

IMPORTANT: Web search results have already been performed and are provided to you. You do NOT need to call any search tools.

When analyzing the web search results:
1. Focus on the most relevant and credible sources
2. Explain how each result relates to the user's query
3. Synthesize insights from multiple sources when appropriate
4. Identify any contradictions or gaps in the information
5. Consider the recency and reliability of the sources

When referencing web results, include the source title and link in your analysis:
[Example Article Title](https://example.com)

After analyzing the web results, incorporate these insights into your response. Summarize the findings from the web search or indicate if nothing relevant was found.
Continue flowing with the same voice as the previous phase, Experience Vectors.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def intention_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Intention phase:
Review the conversation history, including the user query, action response, and experience analysis (both vector and web search results).
Your task is to identify the user's underlying goal or intention.

When analyzing the user's intention:
1. Look beyond the literal query to understand the deeper purpose
2. Consider both explicit and implicit goals
3. Identify if the user is seeking information, guidance, assistance with a task, or something else
4. Determine if the goal is simple or complex

Summarize the refined intention clearly. If the goal seems unclear or ambiguous, state that and suggest potential clarifications.
Continue flowing with the same voice as the previous phases.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def observation_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Observation phase:
Review the entire conversation history, including the identified intention and all search results.
Your task is to identify key concepts, entities, and potential semantic connections or relationships within the conversation.

When making observations:
1. Identify important entities, concepts, and terminology
2. Note semantic connections between different pieces of information
3. Recognize patterns or themes that emerge across the conversation
4. Identify any knowledge gaps or areas that need further exploration
5. Consider how this conversation relates to the broader knowledge graph

Summarize these observations. Note any important entities or concepts that should be remembered or linked for future reference.
Do not generate a response to the user, focus solely on observing and summarizing connections.
Continue flowing with the same voice as the previous phase, intention.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""

def understanding_instruction(model_config):
    return f"""Timestamp: {datetime.now().isoformat()}
For this Understanding phase:
Review the entire conversation history, including all previous phase outputs (Action, Experience Vectors, Experience Web, Intention, Observation).
Your task is to synthesize the information and decide what is most relevant to retain for the final response or next steps.

When synthesizing understanding:
1. Prioritize information that directly addresses the user's intention
2. Integrate insights from both internal knowledge (vector search) and external sources (web search)
3. Filter out less relevant details or tangential information identified in previous phases
4. Resolve any contradictions or inconsistencies between different sources
5. Identify the most valuable vector search results that should be cited in the final response

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

IMPORTANT: If your response references any vector search results from the Experience Vectors phase, you MUST use the <vid>vector_id</vid> tag syntax (e.g., <vid>abc123</vid>) when referring to specific vector IDs. These references will become clickable in the UI, allowing users to view the full content of each result. Always use the exact vector ID as shown in the search results.

CITATION REWARDS: Users earn CHOIR token rewards when you cite vector search results using the <vid>vector_id</vid> tag syntax. Each citation (up to 5) earns the user 5 CHOIR tokens. Make appropriate citations to reward valuable contributions to the knowledge base.

If appropriate for the response, include a "Sources" or "References" section at the end that lists the most important vector results using the <vid>vector_id</vid> tag syntax (e.g., "For more on this topic, see results <vid>abc123</vid>, <vid>def456</vid>, and <vid>ghi789</vid>").

Your response is the final packet in the wave of ai responses, the Choir's Postchain.
Continue flowing with the same voice as the previous phase, understanding.

<model_config>{model_config.provider}/{model_config.model_name}</model_config>
"""
