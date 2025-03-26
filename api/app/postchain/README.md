# Langchain PostChain Implementation

## Overview
This implements the PostChain workflow using Langchain's LCEL (LangChain Expression Language). It provides a simpler alternative to the LangGraph implementation while maintaining the same core phases.

## Key Components

### Workflow Phases
1. **Action Phase** - Initial response generation
2. **Experience Phase** - Enhanced analysis with tools
3. **Intention Phase** - Goal identification
4. **Observation Phase** - Semantic connections
5. **Understanding Phase** - Information synthesis
6. **Yield Phase** - Final response generation

### Implementation Details
- Uses `RunnableLambda` for each phase
- Supports model overrides per phase
- Maintains conversation context
- Streamable phase outputs

## Testing
Run tests with:
```bash
pytest api/tests/postchain/test_langchain_workflow.py -v
```

Key test cases:
- Single turn conversations
- Multi-turn context retention
- Model override functionality
- Error handling

## Usage
```python
from app.postchain.langchain_workflow import run_langchain_postchain_workflow

async for event in run_langchain_postchain_workflow(
    query="Your question here",
    thread_id="conversation-123",
    message_history=[],
    config=config
):
    print(event)
```

## Configuration
Configure models in `app/config.py`. Ensure API keys are set in your environment.
