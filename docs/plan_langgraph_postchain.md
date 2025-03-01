# LangGraph PostChain Implementation Plan

## Current Implementation Overview

The current Chorus Cycle implementation is a sequence of calls to a single LLM with RAG to a single vector database. The cycle follows the AEIOU-Y pattern:

1. **Action**: Initial response with "beginner's mind"
2. **Experience**: Enrichment with prior knowledge via RAG
3. **Intention**: Analysis of planned actions and consequences
4. **Observation**: Reflection on analysis and intentions
5. **Update**: Decision to loop back or proceed to yield
6. **Yield**: Final synthesized response

Each step uses the same model (currently Claude 3.5 Haiku) with different system prompts, and the cycle can loop back from Update to Action if needed.

## Migration Goals

1. Implement the Chorus Cycle using LangGraph's StateGraph
2. Create a multi-model workflow where different models handle different steps
3. Add agentic capabilities with tools and dynamic routing
4. Improve observability and debugging
5. Enable dynamic chain modification

## Implementation Plan

### Phase 1: Basic LangGraph Migration

#### 1.1 Setup Project Structure

```
api/
  app/
    postchain/
      __init__.py
      graph.py        # Main LangGraph implementation
      nodes/          # Node handlers for each step
        __init__.py
        action.py
        experience.py
        intention.py
        observation.py
        update.py
        yield.py
      schemas/        # Pydantic schemas for structured outputs
        __init__.py
        state.py      # State schema
        responses.py  # Response schemas for each step
      tools/          # Tool implementations
        __init__.py
        search.py
        retrieval.py
      models.py       # Model configurations
      config.py       # Configuration
```

#### 1.2 Define State Schema

```python
# schemas/state.py
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from langchain_core.messages import BaseMessage

class PostChainState(BaseModel):
    """State for the PostChain graph."""
    messages: List[BaseMessage] = Field(default_factory=list)
    current_step: str = "action"
    thread_id: Optional[str] = None
    error_state: Optional[Dict[str, Any]] = None
    priors: Optional[List[Dict[str, Any]]] = None
    responses: Dict[str, Any] = Field(default_factory=dict)
    should_loop: bool = False
    tools_used: List[Dict[str, Any]] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)
```

#### 1.3 Implement Basic Graph

```python
# graph.py
from langchain_core.messages import HumanMessage
from langgraph.graph import StateGraph
from .schemas.state import PostChainState
from .nodes.action import run_action
from .nodes.experience import run_experience
from .nodes.intention import run_intention
from .nodes.observation import run_observation
from .nodes.update import run_update
from .nodes.yield_step import run_yield

def create_postchain_graph():
    # Create the graph
    graph = StateGraph(PostChainState)
    
    # Add nodes
    graph.add_node("action", run_action)
    graph.add_node("experience", run_experience)
    graph.add_node("intention", run_intention)
    graph.add_node("observation", run_observation)
    graph.add_node("update", run_update)
    graph.add_node("yield", run_yield)
    
    # Add edges
    graph.add_edge("action", "experience")
    graph.add_edge("experience", "intention")
    graph.add_edge("intention", "observation")
    graph.add_edge("observation", "update")
    
    # Add conditional edge from update
    def update_router(state: PostChainState):
        return "action" if state.should_loop else "yield"
    
    graph.add_conditional_edges("update", update_router, ["action", "yield"])
    
    # Set entry point
    graph.set_entry_point("action")
    
    # Compile the graph
    return graph.compile()

# Create a function to run the graph
async def run_postchain(input_text: str, thread_id: str = None):
    graph = create_postchain_graph()
    
    # Initialize state
    initial_state = PostChainState(
        messages=[HumanMessage(content=input_text)],
        thread_id=thread_id
    )
    
    # Run the graph
    result = graph.invoke(initial_state)
    return result
```

#### 1.4 Implement Node Handlers

Example for the Action node:

```python
# nodes/action.py
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from ..schemas.state import PostChainState
from ..schemas.responses import ActionResponse
from ..config import Config

def run_action(state: PostChainState) -> PostChainState:
    """Run the Action step of the PostChain."""
    config = Config()
    
    # Get the input text from the last message
    input_text = state.messages[-1].content if state.messages else ""
    
    # Create the model
    model = ChatAnthropic(
        model=config.CLAUDE_3_5_HAIKU,
        temperature=0.7,
        max_tokens=4000
    )
    
    # Create the prompt
    action_prompt = """
    This is the Chorus Cycle, a decision-making model that turns the OODA loop on its head.
    Rather than accumulating data before acting, you act with "beginner's mind"/emptiness,
    then reflect on your "System 1" action.
    This is step 1, Action: Provide an initial response to the user's prompt to the best of your ability.

    Respond in this JSON format:
    {
        "proposed_response": "Your initial response here",
        "confidence": 0.8,  // A number between 0 and 1
        "reasoning": "Brief explanation of your response"
    }
    """
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", action_prompt),
        ("human", "{input}")
    ])
    
    # Run the model
    chain = prompt | model
    result = chain.invoke({"input": input_text})
    
    # Parse the result
    try:
        content = result.content
        # Store the response in the state
        new_state = state.model_copy()
        new_state.responses["action"] = content
        new_state.current_step = "experience"
        return new_state
    except Exception as e:
        # Handle errors
        new_state = state.model_copy()
        new_state.error_state = {"message": str(e), "step": "action"}
        return new_state
```

### Phase 2: Multi-Model Integration

#### 2.1 Define Model Configuration

```python
# models.py
from langchain_anthropic import ChatAnthropic
from langchain_openai import ChatOpenAI
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_mistralai import ChatMistralAI
from langchain_fireworks import ChatFireworks
from .config import Config

def get_models(config: Config):
    """Get the models for each step of the PostChain."""
    return {
        "action": ChatMistralAI(
            model="mistral-medium",
            temperature=0.7,
            max_tokens=4000
        ),
        "experience": ChatGoogleGenerativeAI(
            model="gemini-pro",
            temperature=0.7,
            max_tokens=4000
        ),
        "intention": ChatAnthropic(
            model="claude-3-haiku-20241022",
            temperature=0.7,
            max_tokens=4000
        ),
        "observation": ChatOpenAI(
            model="gpt-4o",
            temperature=0.7,
            max_tokens=4000
        ),
        "update": ChatFireworks(
            model="deepseek-chat",
            temperature=0.7,
            max_tokens=4000
        ),
        "yield": ChatAnthropic(
            model="claude-3-sonnet-20241022",
            temperature=0.7,
            max_tokens=4000
        )
    }
```

#### 2.2 Update Node Handlers to Use Different Models

```python
# nodes/action.py (updated)
from ..models import get_models
from ..config import Config
from ..schemas.state import PostChainState

def run_action(state: PostChainState) -> PostChainState:
    """Run the Action step of the PostChain."""
    config = Config()
    models = get_models(config)
    
    # Get the model for this step
    model = models["action"]
    
    # Rest of the implementation...
```

### Phase 3: Tool Integration

#### 3.1 Implement Basic Tools

```python
# tools/search.py
from langchain_community.tools import DuckDuckGoSearchRun
from langchain_core.tools import tool

@tool
def web_search(query: str) -> str:
    """Search the web for information about the query."""
    search = DuckDuckGoSearchRun()
    return search.invoke(query)
```

```python
# tools/retrieval.py
from langchain_core.tools import tool
from ..config import Config
from typing import List, Dict, Any

@tool
async def retrieve_similar_documents(query: str, limit: int = 10) -> List[Dict[str, Any]]:
    """Retrieve documents similar to the query from the vector database."""
    config = Config()
    # Implementation to search the vector database
    # This would use the existing database client
    # ...
    return [{"content": "Example document", "metadata": {}}]
```

#### 3.2 Integrate Tools with Models

```python
# nodes/experience.py (updated)
from langchain_core.prompts import ChatPromptTemplate
from ..schemas.state import PostChainState
from ..models import get_models
from ..config import Config
from ..tools.retrieval import retrieve_similar_documents

def run_experience(state: PostChainState) -> PostChainState:
    """Run the Experience step of the PostChain."""
    config = Config()
    models = get_models(config)
    
    # Get the input text from the last message
    input_text = state.messages[-1].content if state.messages else ""
    
    # Get the action response
    action_response = state.responses.get("action", "")
    
    # Retrieve similar documents
    priors = retrieve_similar_documents(input_text, limit=config.SEARCH_LIMIT)
    
    # Format priors for context
    context = "\n".join([f"Source {i+1}: {prior['content']}" for i, prior in enumerate(priors)])
    
    # Create the model with tools
    model = models["experience"]
    
    # Create the prompt
    experience_prompt = """
    This is step 2 of the Chorus Cycle, Experience: Search your memory for relevant context that could help refine the response from step 1.

    Respond in this JSON format:
    {
        "synthesis": "Your refined response incorporating the context",
        "key_insights": ["List of key insights from the sources"],
        "source_relevance": {
            "most_relevant": ["Source numbers of most relevant sources"],
            "reasoning": "Why these sources were most relevant"
        }
    }
    """
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", experience_prompt),
        ("human", f"Sources:\n{context}\n\nAction response: {action_response}\n\nUser query: {input_text}")
    ])
    
    # Run the model
    chain = prompt | model
    result = chain.invoke({"input": input_text})
    
    # Update state
    new_state = state.model_copy()
    new_state.responses["experience"] = result.content
    new_state.priors = priors
    new_state.current_step = "intention"
    
    # Record tool usage
    new_state.tools_used.append({
        "step": "experience",
        "tool": "retrieve_similar_documents",
        "query": input_text,
        "result_count": len(priors)
    })
    
    return new_state
```

### Phase 4: Advanced Flow Control

#### 4.1 Implement Dynamic Routing

```python
# graph.py (updated)
from langgraph.graph import StateGraph
from .schemas.state import PostChainState
from .nodes.action import run_action
from .nodes.experience import run_experience
from .nodes.intention import run_intention
from .nodes.observation import run_observation
from .nodes.update import run_update
from .nodes.yield_step import run_yield
from .nodes.web_search import run_web_search

def create_postchain_graph():
    # Create the graph
    graph = StateGraph(PostChainState)
    
    # Add nodes
    graph.add_node("action", run_action)
    graph.add_node("experience", run_experience)
    graph.add_node("intention", run_intention)
    graph.add_node("observation", run_observation)
    graph.add_node("update", run_update)
    graph.add_node("yield", run_yield)
    graph.add_node("web_search", run_web_search)
    
    # Add dynamic routing from action
    def action_router(state: PostChainState):
        # Check if the action response indicates a need for web search
        action_response = state.responses.get("action", {})
        if isinstance(action_response, dict) and action_response.get("needs_web_search", False):
            return "web_search"
        return "experience"
    
    graph.add_conditional_edges("action", action_router, ["experience", "web_search"])
    
    # Connect web_search back to experience
    graph.add_edge("web_search", "experience")
    
    # Add standard edges
    graph.add_edge("experience", "intention")
    graph.add_edge("intention", "observation")
    graph.add_edge("observation", "update")
    
    # Add conditional edge from update
    def update_router(state: PostChainState):
        return "action" if state.should_loop else "yield"
    
    graph.add_conditional_edges("update", update_router, ["action", "yield"])
    
    # Set entry point
    graph.set_entry_point("action")
    
    # Compile the graph
    return graph.compile()
```

#### 4.2 Implement Web Search Node

```python
# nodes/web_search.py
from langchain_core.prompts import ChatPromptTemplate
from ..schemas.state import PostChainState
from ..models import get_models
from ..config import Config
from ..tools.search import web_search

def run_web_search(state: PostChainState) -> PostChainState:
    """Run a web search to gather information."""
    config = Config()
    models = get_models(config)
    
    # Get the input text from the last message
    input_text = state.messages[-1].content if state.messages else ""
    
    # Get the action response
    action_response = state.responses.get("action", "")
    
    # Create a search query
    model = models["action"]  # Reuse the action model for query generation
    
    search_prompt = """
    Based on the user's query, generate a concise search query for a web search engine.
    Focus on the key information needs and use search-friendly syntax.
    
    User query: {input}
    
    Search query:
    """
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", search_prompt),
        ("human", input_text)
    ])
    
    # Generate search query
    chain = prompt | model
    search_query_result = chain.invoke({"input": input_text})
    search_query = search_query_result.content.strip()
    
    # Perform web search
    search_results = web_search(search_query)
    
    # Update state
    new_state = state.model_copy()
    new_state.metadata["web_search"] = {
        "query": search_query,
        "results": search_results
    }
    
    # Record tool usage
    new_state.tools_used.append({
        "step": "web_search",
        "tool": "web_search",
        "query": search_query,
        "result_length": len(search_results)
    })
    
    return new_state
```

### Phase 5: Integration with API

#### 5.1 Create API Endpoint

```python
# routers/postchain.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
from ..postchain.graph import run_postchain

router = APIRouter()

class PostChainRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class PostChainResponse(BaseModel):
    thread_id: str
    responses: Dict[str, Any]
    final_response: str
    tools_used: List[Dict[str, Any]]
    metadata: Dict[str, Any]

@router.post("/postchain", response_model=PostChainResponse)
async def process_postchain(request: PostChainRequest):
    try:
        result = await run_postchain(
            input_text=request.content,
            thread_id=request.thread_id
        )
        
        return PostChainResponse(
            thread_id=result.thread_id,
            responses=result.responses,
            final_response=result.responses.get("yield", ""),
            tools_used=result.tools_used,
            metadata=result.metadata
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

#### 5.2 Add Streaming Support

```python
# routers/postchain.py (updated)
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
from ..postchain.graph import create_postchain_graph
from ..postchain.schemas.state import PostChainState
from langchain_core.messages import HumanMessage
import json
import asyncio

router = APIRouter()

class PostChainRequest(BaseModel):
    content: str
    thread_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

@router.post("/postchain/stream")
async def stream_postchain(request: PostChainRequest):
    try:
        # Create the graph with tracing
        graph = create_postchain_graph()
        
        # Initialize state
        initial_state = PostChainState(
            messages=[HumanMessage(content=request.content)],
            thread_id=request.thread_id,
            metadata=request.metadata or {}
        )
        
        # Create streaming response
        async def event_generator():
            # Get the stream
            stream = graph.stream(initial_state)
            
            # Process each step
            async for chunk in stream:
                if chunk.get("intermediate_steps"):
                    step = chunk["intermediate_steps"][-1]
                    
                    # Send step information
                    yield f"data: {json.dumps({'step': step[0], 'state': step[1].dict()})}\n\n"
                    
                    # Add a small delay to avoid overwhelming the client
                    await asyncio.sleep(0.1)
            
            # Send final state
            yield f"data: {json.dumps({'step': 'complete', 'state': chunk['final_output'].dict()})}\n\n"
        
        return StreamingResponse(event_generator(), media_type="text/event-stream")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### Phase 6: Observability and Debugging

#### 6.1 Add Tracing

```python
# postchain/graph.py (updated)
from langchain_core.tracers import ConsoleCallbackHandler
from langchain_core.callbacks import CallbackManager
from langgraph.graph import StateGraph
from .schemas.state import PostChainState

def create_postchain_graph(debug: bool = False):
    # Create callback manager
    callbacks = []
    if debug:
        callbacks.append(ConsoleCallbackHandler())
    
    callback_manager = CallbackManager(callbacks)
    
    # Create the graph with callbacks
    graph = StateGraph(PostChainState)
    
    # Add nodes with callbacks
    for node_name, node_fn in [
        ("action", run_action),
        ("experience", run_experience),
        ("intention", run_intention),
        ("observation", run_observation),
        ("update", run_update),
        ("yield", run_yield),
        ("web_search", run_web_search)
    ]:
        graph.add_node(node_name, node_fn, callback_manager=callback_manager)
    
    # Rest of the implementation...
```

#### 6.2 Add Logging

```python
# postchain/nodes/base.py
import logging
from ..schemas.state import PostChainState
from typing import Callable, Any

logger = logging.getLogger(__name__)

def with_logging(step_name: str, handler_fn: Callable[[PostChainState], PostChainState]):
    """Wrap a node handler with logging."""
    def wrapped_handler(state: PostChainState) -> PostChainState:
        logger.info(f"Starting {step_name} step")
        try:
            result = handler_fn(state)
            logger.info(f"Completed {step_name} step")
            return result
        except Exception as e:
            logger.error(f"Error in {step_name} step: {str(e)}", exc_info=True)
            new_state = state.model_copy()
            new_state.error_state = {"message": str(e), "step": step_name}
            return new_state
    
    return wrapped_handler
```

### Phase 7: Testing and Evaluation

#### 7.1 Create Test Suite

```python
# tests/test_postchain.py
import pytest
from app.postchain.graph import create_postchain_graph
from app.postchain.schemas.state import PostChainState
from langchain_core.messages import HumanMessage

@pytest.fixture
def graph():
    return create_postchain_graph(debug=True)

@pytest.mark.asyncio
async def test_basic_flow(graph):
    """Test the basic flow of the PostChain."""
    # Initialize state
    initial_state = PostChainState(
        messages=[HumanMessage(content="What is the capital of France?")]
    )
    
    # Run the graph
    result = graph.invoke(initial_state)
    
    # Check that all steps were executed
    assert "action" in result.responses
    assert "experience" in result.responses
    assert "intention" in result.responses
    assert "observation" in result.responses
    assert "update" in result.responses
    assert "yield" in result.responses
    
    # Check that the final response is present
    assert result.responses["yield"] is not None

@pytest.mark.asyncio
async def test_web_search_flow(graph):
    """Test the flow with web search."""
    # Initialize state with a query that likely needs web search
    initial_state = PostChainState(
        messages=[HumanMessage(content="What were the latest developments in the Israel-Hamas conflict?")]
    )
    
    # Run the graph
    result = graph.invoke(initial_state)
    
    # Check that web search was used
    assert any(tool["tool"] == "web_search" for tool in result.tools_used)
    
    # Check that the final response is present
    assert result.responses["yield"] is not None
```

## Implementation Timeline

1. **Week 1**: Basic LangGraph Migration
   - Set up project structure
   - Implement state schema
   - Create basic graph with fixed flow
   - Implement node handlers for each step

2. **Week 2**: Multi-Model Integration
   - Define model configuration
   - Update node handlers to use different models
   - Test model compatibility and performance

3. **Week 3**: Tool Integration
   - Implement basic tools (web search, retrieval)
   - Integrate tools with models
   - Test tool usage and effectiveness

4. **Week 4**: Advanced Flow Control
   - Implement dynamic routing
   - Add web search node
   - Test complex flows with branching

5. **Week 5**: API Integration
   - Create API endpoints
   - Add streaming support
   - Test API performance and reliability

6. **Week 6**: Observability and Testing
   - Add tracing and logging
   - Create comprehensive test suite
   - Evaluate system performance

## Conclusion

This implementation plan provides a structured approach to migrating the current Chorus Cycle to a multi-model agentic workflow using LangGraph. The resulting system will be more flexible, maintainable, and powerful, while preserving the core AEIOU-Y cycle functionality.

The migration can be performed incrementally, starting with a basic LangGraph implementation and gradually adding more advanced features like multi-model support, tool integration, and dynamic routing. This approach allows for continuous testing and evaluation throughout the development process.

The final system will leverage the strengths of different models for different steps of the cycle, use tools to enhance capabilities, and provide better observability and debugging features. It will also be more extensible, allowing for future enhancements like multi-agent orchestration, memory management, and custom model integration.