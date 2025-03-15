# Migration Guide for Developers

This guide provides a step-by-step approach for migrating code from Choir's previous graph-based architecture (LangGraph) to the new actor-based architecture. It includes code transformation examples, pattern comparisons, and testing strategies.

## Table of Contents

1. [Introduction](#introduction)
2. [Architectural Differences](#architectural-differences)
3. [Migration Strategy](#migration-strategy)
4. [Code Transformation Patterns](#code-transformation-patterns)
5. [Testing Migration](#testing-migration)
6. [Performance Considerations](#performance-considerations)
7. [Migration Checklist](#migration-checklist)
8. [Examples](#examples)

## Introduction

Choir has undergone a significant architectural pivot from a graph-based implementation using LangGraph to an actor-based architecture. This guide is designed to help developers migrate existing code and understand the new architectural patterns.

The migration process is not just about rewriting code—it's about adopting a new mental model for building AI systems. The actor model provides several advantages over the graph-based approach, including:

- Better isolation and fault tolerance
- More natural scaling
- Clearer state management
- More flexible message passing
- Easier extension with new capabilities

This guide will walk you through the process of migrating your code to take advantage of these benefits.

## Architectural Differences

### Graph-Based Architecture (LangGraph)

In the graph-based architecture:

- **Nodes** represent processing steps
- **Edges** define explicit flow between nodes
- **State** is centrally managed and passed between nodes
- **Execution** follows a predetermined path
- **Error handling** is managed at the graph level

```python
# Example LangGraph code
from langgraph.graph import StateGraph

# Define the state
class GraphState(TypedDict):
    input: str
    action_output: str
    experience_output: str
    intention_output: str
    observation_output: str
    understanding_output: str
    yield_output: str

# Create the graph
graph = StateGraph(GraphState)

# Add nodes
graph.add_node("action", action_node)
graph.add_node("experience", experience_node)
graph.add_node("intention", intention_node)
graph.add_node("observation", observation_node)
graph.add_node("understanding", understanding_node)
graph.add_node("yield", yield_node)

# Add edges
graph.add_edge("action", "experience")
graph.add_edge("experience", "intention")
graph.add_edge("intention", "observation")
graph.add_edge("observation", "understanding")
graph.add_edge("understanding", "yield")

# Compile the graph
chain = graph.compile()
```

### Actor-Based Architecture

In the actor-based architecture:

- **Actors** are independent entities with their own state
- **Messages** are passed between actors
- **State** is encapsulated within each actor
- **Execution** is message-driven and can be dynamic
- **Error handling** is localized to each actor

```python
# Example Actor code
class ActionActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = {}

    async def receive(self, message):
        if message.type == "PROCESS_INPUT":
            # Process the input
            result = self._process_input(message.data["input"])

            # Return the result
            return Response(
                type="ACTION_COMPLETE",
                data={"result": result}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    def _process_input(self, input_data):
        # Implementation-specific processing
        return {"processed": input_data}
```

## Migration Strategy

The recommended migration strategy follows these steps:

1. **Understand the Actor Model**: Familiarize yourself with actor model concepts
2. **Identify Actors**: Map graph nodes to potential actors
3. **Define Messages**: Design the message protocol between actors
4. **Implement Actors**: Create actor classes for each component
5. **Refactor State Management**: Move from centralized to encapsulated state
6. **Implement Message Flows**: Replace explicit edges with message passing
7. **Test and Validate**: Ensure the migrated code behaves correctly

### Incremental Migration

For large codebases, consider an incremental migration approach:

1. **Create Actor Wrappers**: Wrap existing graph nodes in actors
2. **Migrate One Component at a Time**: Start with leaf nodes
3. **Use Adapter Patterns**: Create adapters between graph and actor components
4. **Gradually Replace Graph Components**: Replace graph nodes with actors over time

## Code Transformation Patterns

### Pattern 1: Node to Actor Transformation

Transform graph nodes into actors:

**Before (Graph Node):**

```python
def action_node(state: GraphState) -> dict:
    input_text = state["input"]

    # Process the input
    result = process_input(input_text)

    # Return the updated state
    return {"action_output": result}
```

**After (Actor):**

```python
class ActionActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = {}

    async def receive(self, message):
        if message.type == "PROCESS_INPUT":
            input_text = message.data["input"]

            # Process the input
            result = self._process_input(input_text)

            # Return the result
            return Response(
                type="ACTION_COMPLETE",
                data={"result": result}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    def _process_input(self, input_text):
        # Same implementation as the original process_input
        return process_input(input_text)
```

### Pattern 2: Edge to Message Transformation

Transform graph edges into message passing:

**Before (Graph Edges):**

```python
# Define the conditional edge
def should_continue(state):
    return "continue" if state["understanding_output"]["continue"] else "end"

# Add edges
graph.add_edge("action", "experience")
graph.add_edge("experience", "intention")
graph.add_edge("intention", "observation")
graph.add_edge("observation", "understanding")
graph.add_edge("understanding", should_continue)
graph.add_edge("understanding", "yield", condition=lambda s: should_continue(s) == "continue")
graph.add_edge("understanding", "end", condition=lambda s: should_continue(s) == "end")
```

**After (Message Passing):**

```python
class UnderstandingActor(Actor):
    async def receive(self, message):
        if message.type == "PROCESS_OBSERVATION":
            # Process the observation
            result = self._process_observation(message.data["observation"])

            # Determine the next step
            if result["continue"]:
                # Send message to the yield actor
                yield_actor = await self.get_actor("yield_actor")
                await yield_actor.send(
                    Message(
                        type="PROCESS_UNDERSTANDING",
                        data={"understanding": result}
                    )
                )
            else:
                # End the process
                end_actor = await self.get_actor("end_actor")
                await end_actor.send(
                    Message(
                        type="END_PROCESS",
                        data={"understanding": result}
                    )
                )

            # Return the result
            return Response(
                type="UNDERSTANDING_COMPLETE",
                data={"result": result}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")
```

### Pattern 3: State Transformation

Transform centralized state to encapsulated state:

**Before (Centralized State):**

```python
# Define the state
class GraphState(TypedDict):
    input: str
    action_output: str
    experience_output: str
    intention_output: str
    observation_output: str
    understanding_output: str
    yield_output: str

# Access state in a node
def experience_node(state: GraphState) -> dict:
    action_output = state["action_output"]

    # Process the action output
    result = process_action_output(action_output)

    # Return the updated state
    return {"experience_output": result}
```

**After (Encapsulated State):**

```python
class ExperienceActor(Actor):
    def __init__(self, actor_id=None):
        super().__init__(actor_id)
        self.state = {
            "processed_messages": 0,
            "last_action_output": None
        }

    async def receive(self, message):
        if message.type == "PROCESS_ACTION":
            # Update state
            self.state["processed_messages"] += 1
            self.state["last_action_output"] = message.data["action_output"]

            # Process the action output
            result = self._process_action_output(message.data["action_output"])

            # Return the result
            return Response(
                type="EXPERIENCE_COMPLETE",
                data={"result": result}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")

    def _process_action_output(self, action_output):
        # Same implementation as the original process_action_output
        return process_action_output(action_output)
```

### Pattern 4: Error Handling Transformation

Transform graph-level error handling to actor-level error handling:

**Before (Graph Error Handling):**

```python
try:
    result = chain.invoke({"input": "Hello, world!"})
except Exception as e:
    print(f"Error in graph execution: {e}")
    # Handle the error at the graph level
```

**After (Actor Error Handling):**

```python
class ActionActor(Actor):
    async def receive(self, message):
        try:
            if message.type == "PROCESS_INPUT":
                # Process the input
                result = self._process_input(message.data["input"])

                # Return the result
                return Response(
                    type="ACTION_COMPLETE",
                    data={"result": result}
                )
            else:
                return ErrorResponse(f"Unknown message type: {message.type}")
        except Exception as e:
            # Handle the error at the actor level
            self.log_error(f"Error processing message: {e}")
            return ErrorResponse(f"Error processing message: {str(e)}")
```

## Testing Migration

### Unit Testing

Test individual actors:

```python
async def test_action_actor():
    # Create the actor
    actor = ActionActor("test_action_actor")

    # Send a test message
    response = await actor.receive(
        Message(
            type="PROCESS_INPUT",
            data={"input": "Hello, world!"}
        )
    )

    # Verify the response
    assert response.type == "ACTION_COMPLETE"
    assert "result" in response.data
    assert response.data["result"]["processed"] == "Hello, world!"
```

### Integration Testing

Test interactions between actors:

```python
async def test_action_experience_integration():
    # Create the actors
    action_actor = ActionActor("action_actor")
    experience_actor = ExperienceActor("experience_actor")

    # Register actors with the system
    actor_system.register(action_actor)
    actor_system.register(experience_actor)

    # Send a message to the action actor
    action_response = await action_actor.receive(
        Message(
            type="PROCESS_INPUT",
            data={"input": "Hello, world!"}
        )
    )

    # Send the action result to the experience actor
    experience_response = await experience_actor.receive(
        Message(
            type="PROCESS_ACTION",
            data={"action_output": action_response.data["result"]}
        )
    )

    # Verify the experience response
    assert experience_response.type == "EXPERIENCE_COMPLETE"
    assert "result" in experience_response.data
```

### End-to-End Testing

Test the complete workflow:

```python
async def test_post_chain():
    # Create the PostChain
    post_chain = PostChain()

    # Process input through the PostChain
    result = await post_chain.process("Hello, world!")

    # Verify the result
    assert "response" in result
    assert result["response"] != ""
```

### Comparison Testing

Compare the results of the graph-based and actor-based implementations:

```python
async def test_migration_equivalence():
    # Create the graph-based implementation
    graph = create_graph()

    # Create the actor-based implementation
    post_chain = PostChain()

    # Process the same input through both implementations
    graph_result = graph.invoke({"input": "Hello, world!"})
    actor_result = await post_chain.process("Hello, world!")

    # Verify that the results are equivalent
    assert graph_result["yield_output"] == actor_result["response"]
```

## Performance Considerations

### Performance Comparison

When migrating from graphs to actors, consider these performance aspects:

1. **Latency**: Actor-based systems may have different latency characteristics
2. **Throughput**: Actor-based systems can often achieve higher throughput
3. **Scalability**: Actor-based systems scale more naturally
4. **Resource Usage**: Actor-based systems may have different resource usage patterns

### Performance Testing

Implement performance tests to compare the graph-based and actor-based implementations:

```python
async def benchmark_performance():
    # Create the implementations
    graph = create_graph()
    post_chain = PostChain()

    # Benchmark the graph-based implementation
    graph_start_time = time.time()
    for i in range(100):
        graph.invoke({"input": f"Test input {i}"})
    graph_time = time.time() - graph_start_time

    # Benchmark the actor-based implementation
    actor_start_time = time.time()
    for i in range(100):
        await post_chain.process(f"Test input {i}")
    actor_time = time.time() - actor_start_time

    # Compare the results
    print(f"Graph-based implementation: {graph_time:.2f} seconds")
    print(f"Actor-based implementation: {actor_time:.2f} seconds")
    print(f"Performance difference: {(graph_time - actor_time) / graph_time * 100:.2f}%")
```

## Migration Checklist

Use this checklist to track your migration progress:

- [ ] **Preparation**

  - [ ] Understand the actor model concepts
  - [ ] Identify actors in your system
  - [ ] Design the message protocol
  - [ ] Create a migration plan

- [ ] **Implementation**

  - [ ] Create actor base classes
  - [ ] Implement individual actors
  - [ ] Implement message passing
  - [ ] Refactor state management
  - [ ] Implement error handling

- [ ] **Testing**

  - [ ] Write unit tests for actors
  - [ ] Write integration tests for actor interactions
  - [ ] Write end-to-end tests for workflows
  - [ ] Compare results with the original implementation
  - [ ] Benchmark performance

- [ ] **Deployment**
  - [ ] Update deployment scripts
  - [ ] Configure monitoring for actors
  - [ ] Implement logging for actors
  - [ ] Deploy the migrated system
  - [ ] Monitor performance and behavior

## Examples

### Example 1: PostChain Migration

This example shows the migration of the PostChain from a graph-based to an actor-based implementation:

**Before (Graph-Based PostChain):**

```python
from langgraph.graph import StateGraph

# Define the state
class PostChainState(TypedDict):
    input: str
    action_output: str
    experience_output: str
    intention_output: str
    observation_output: str
    understanding_output: str
    yield_output: str

# Create the graph
graph = StateGraph(PostChainState)

# Add nodes
graph.add_node("action", action_node)
graph.add_node("experience", experience_node)
graph.add_node("intention", intention_node)
graph.add_node("observation", observation_node)
graph.add_node("understanding", understanding_node)
graph.add_node("yield", yield_node)

# Add edges
graph.add_edge("action", "experience")
graph.add_edge("experience", "intention")
graph.add_edge("intention", "observation")
graph.add_edge("observation", "understanding")
graph.add_edge("understanding", "yield")

# Compile the graph
post_chain = graph.compile()

# Use the PostChain
result = post_chain.invoke({"input": "Hello, world!"})
print(result["yield_output"])
```

**After (Actor-Based PostChain):**

```python
class PostChain:
    def __init__(self):
        # Create the actor system
        self.actor_system = ActorSystem()

        # Create the actors
        self.action_actor = ActionActor("action_actor")
        self.experience_actor = ExperienceActor("experience_actor")
        self.intention_actor = IntentionActor("intention_actor")
        self.observation_actor = ObservationActor("observation_actor")
        self.understanding_actor = UnderstandingActor("understanding_actor")
        self.yield_actor = YieldActor("yield_actor")

        # Register the actors
        self.actor_system.register(self.action_actor)
        self.actor_system.register(self.experience_actor)
        self.actor_system.register(self.intention_actor)
        self.actor_system.register(self.observation_actor)
        self.actor_system.register(self.understanding_actor)
        self.actor_system.register(self.yield_actor)

    async def process(self, input_text):
        # Process the input through the PostChain
        action_response = await self.action_actor.receive(
            Message(
                type="PROCESS_INPUT",
                data={"input": input_text}
            )
        )

        experience_response = await self.experience_actor.receive(
            Message(
                type="PROCESS_ACTION",
                data={"action_output": action_response.data["result"]}
            )
        )

        intention_response = await self.intention_actor.receive(
            Message(
                type="PROCESS_EXPERIENCE",
                data={"experience_output": experience_response.data["result"]}
            )
        )

        observation_response = await self.observation_actor.receive(
            Message(
                type="PROCESS_INTENTION",
                data={"intention_output": intention_response.data["result"]}
            )
        )

        understanding_response = await self.understanding_actor.receive(
            Message(
                type="PROCESS_OBSERVATION",
                data={"observation_output": observation_response.data["result"]}
            )
        )

        yield_response = await self.yield_actor.receive(
            Message(
                type="PROCESS_UNDERSTANDING",
                data={"understanding_output": understanding_response.data["result"]}
            )
        )

        # Return the final result
        return {
            "response": yield_response.data["result"],
            "phases": {
                "action_phase": action_response.data["result"],
                "experience_phase": experience_response.data["result"],
                "intention_phase": intention_response.data["result"],
                "observation_phase": observation_response.data["result"],
                "understanding_phase": understanding_response.data["result"],
                "yield_phase": yield_response.data["result"]
            }
        }
```

### Example 2: Conditional Flow Migration

This example shows the migration of conditional flow logic:

**Before (Graph Conditional Flow):**

```python
# Define the conditional edge
def should_continue(state):
    return "continue" if state["understanding_output"]["continue"] else "end"

# Add conditional edges
graph.add_edge("understanding", "yield", condition=lambda s: should_continue(s) == "continue")
graph.add_edge("understanding", "end", condition=lambda s: should_continue(s) == "end")
```

**After (Actor Conditional Flow):**

```python
class UnderstandingActor(Actor):
    async def receive(self, message):
        if message.type == "PROCESS_OBSERVATION":
            # Process the observation
            result = self._process_observation(message.data["observation_output"])

            # Determine the next step based on the result
            if result["continue"]:
                # Send message to the yield actor
                yield_actor = await self.get_actor("yield_actor")
                await yield_actor.send(
                    Message(
                        type="PROCESS_UNDERSTANDING",
                        data={"understanding_output": result}
                    )
                )
            else:
                # Send message to the end actor
                end_actor = await self.get_actor("end_actor")
                await end_actor.send(
                    Message(
                        type="END_PROCESS",
                        data={"understanding_output": result}
                    )
                )

            # Return the result
            return Response(
                type="UNDERSTANDING_COMPLETE",
                data={"result": result}
            )
        else:
            return ErrorResponse(f"Unknown message type: {message.type}")
```

## Conclusion

Migrating from a graph-based to an actor-based architecture requires a shift in thinking, but the benefits are substantial. By following this guide, you can successfully migrate your code and take advantage of the actor model's benefits.

For more detailed information, refer to:

- [Actor Model Overview](1-concepts/actor_model_overview.md)
- [Architecture Transition Narrative](architecture_transition_narrative.md)
- [Message Protocol Reference](3-implementation/message_protocol_reference.md)
- [State Management Patterns](3-implementation/state_management_patterns.md)
- [Actor Implementation Guide](3-implementation/actor_implementation_guide.md)
