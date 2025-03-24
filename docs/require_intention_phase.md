# Intention Phase Requirements

## Overview

The Intention phase refines and focuses information toward user goals, aligning the accumulated context with desired outcomes. It serves as the bridge between retrieved knowledge and effective decision-making by identifying what matters most.

## Core Responsibilities

1. Identify and clarify user goals and intentions
2. Prioritize information based on relevance to goals
3. Filter noise and tangential information
4. Align system responses with user objectives
5. Maintain focus on the desired future state

## Temporal Focus: The Desired Future

The Intention phase orients toward future objectives and desired outcomes. It represents the system's relationship with where the process needs to go, focusing information toward goal achievement rather than just accumulation.

## Input Specification

The Intention phase accepts:

1. **Primary Content**:

   - Original content with retrieved information (from Experience)
   - Search results and knowledge retrievals

2. **Metadata**:
   - Source attributions
   - Relevance scores for retrievals
   - Context from previous phases

## Output Specification

The Intention phase produces:

1. **Primary Content**:

   - Goal-oriented content with prioritized information
   - Clarified user intent statements

2. **Metadata**:
   - Alignment scores with identified intents
   - Priority markers for information
   - Context operations for focusing information
   - Goal certainty metrics

## Processing Requirements

### Intent Identification

The Intention phase should:

- Extract explicit and implicit user goals
- Disambiguate between multiple possible intentions
- Rank intentions by priority and likelihood
- Track intent evolution across conversation history

### Information Prioritization

For effective goal alignment:

- Score information relevance to identified goals
- Apply PRIORITIZE context operations to relevant content
- Use TRANSFORM operations to focus verbose content
- Identify information gaps needed for goal achievement

### Goal Refinement

To clarify ambiguous intentions:

- Generate goal hypotheses when intent is unclear
- Identify conflicting goals for resolution
- Decompose complex goals into manageable components
- Abstract specific requests to underlying intentions

### Error Handling

The Intention phase should handle:

- Ambiguous or contradictory user intentions
- Missing context for intent resolution
- Goal shifts during conversation
- Misalignment between user goals and available information

## Performance Requirements

1. **Intent Recognition Accuracy**: >85% accuracy in identifying correct user intent
2. **Processing Time**: Complete intent analysis within 1-2 seconds
3. **Relevance Threshold**: Achieve >80% precision in information prioritization
4. **Goal Stability**: Maintain consistent goal tracking across conversation turns

## Implementation Constraints

1. Maintain goal state across conversation turns
2. Support nested and hierarchical goal structures
3. Implement efficient goal-based relevance scoring
4. Track goal evolution and refinement over time

## Examples

### Intent Extraction and Prioritization

```python
async def extract_and_prioritize_intent(content: Dict, context: List[Message]) -> IntentionResult:
    """Extract user intent and prioritize information accordingly."""
    # Extract intent from user input and context
    intent_analysis = await intent_analyzer.analyze(
        content["original_query"],
        conversation_history=context
    )

    # Score relevance of information to intent
    scored_information = []
    for item in content.get("search_results", []):
        relevance_to_intent = calculate_relevance_to_intent(
            item,
            intent_analysis.primary_intent
        )

        scored_information.append({
            "item": item,
            "relevance_score": relevance_to_intent,
            "aligned_with_intent": relevance_to_intent > 0.7
        })

    # Generate context operations based on intent alignment
    context_ops = []
    for idx, info in enumerate(scored_information):
        if info["aligned_with_intent"]:
            context_ops.append({
                "operation": "PRIORITIZE",
                "target": f"search_results[{idx}]",
                "data": {
                    "priority": info["relevance_score"]
                },
                "metadata": {
                    "reason": "aligned_with_intent",
                    "intent": intent_analysis.primary_intent
                }
            })
        elif info["relevance_score"] < 0.3:
            context_ops.append({
                "operation": "TAG",
                "target": f"search_results[{idx}]",
                "data": {
                    "tags": ["low_relevance"]
                },
                "metadata": {
                    "reason": "not_aligned_with_intent"
                }
            })

    return IntentionResult(
        content={
            "original_content": content,
            "extracted_intent": intent_analysis.primary_intent,
            "intent_confidence": intent_analysis.confidence,
            "alternative_intents": intent_analysis.alternative_intents,
            "scored_information": scored_information
        },
        metadata={
            "context_operations": context_ops,
            "intent_extraction_method": "semantic_analysis"
        }
    )
```

### Goal Decomposition

```python
def decompose_complex_goal(primary_intent: str) -> Dict:
    """Break down a complex goal into subgoals."""
    # Analyze intent complexity
    complexity = measure_intent_complexity(primary_intent)

    if complexity < 0.5:  # Simple intent
        return {
            "is_complex": False,
            "primary_goal": primary_intent,
            "subgoals": []
        }

    # For complex intents, break down into components
    subgoals = []

    # Extract component goals through model call
    model = select_model_provider("intention", {"reasoning": True})
    system_prompt = "Break down this complex user goal into simpler component goals."

    decomposition_result = intent_model.run_sync(
        primary_intent,
        system_prompt=system_prompt
    )

    # Parse the decomposition
    subgoals = parse_subgoals(decomposition_result.data)

    return {
        "is_complex": True,
        "primary_goal": primary_intent,
        "subgoals": subgoals,
        "dependencies": identify_subgoal_dependencies(subgoals)
    }
```

## Interaction with Other Phases

- **Receives from**: Experience phase
- **Sends to**: Observation phase
- **Relationship**: Focuses information before semantic connection marking

## Success Criteria

1. Correctly identifies user intentions even when implicit
2. Successfully prioritizes information relevant to goals
3. Improves response relevance by filtering noise
4. Maintains consistent goal tracking across conversation
5. Adapts to evolving user intentions over time
