# Understanding Phase Requirements

## Overview

The Understanding phase is responsible for temporal integration of information and context management. It evaluates accumulated information across time to determine what remains relevant and what can be released, embodying the system's ability to discern signal from noise.

## Core Responsibilities

1. Evaluate and filter information based on relevance
2. Implement information "forgetting" through pruning
3. Apply context management operations to maintain optimal context
4. Integrate information across temporal phases
5. Maintain clean and focused context for subsequent cycles

## Temporal Focus: Temporal Integration and Release

The Understanding phase integrates information across time, having sufficient contextual awareness to determine what information remains relevant and what can be released. This phase embodies the wisdom of letting go of less relevant information.

## Input Specification

The Understanding phase accepts:

1. **Primary Content**:

   - Content with semantic connections identified (from Observation)
   - Context with tagged relationships and importance markers

2. **Metadata**:
   - Tags and relationship links
   - Context history across multiple cycles
   - Relevance scores and usage metrics

## Output Specification

The Understanding phase produces:

1. **Primary Content**:

   - Filtered and integrated content
   - Decisions about information retention and release

2. **Metadata**:
   - Context management operations (PRUNE, TRANSFORM, etc.)
   - Rationale for retention/release decisions
   - Context statistics (tokens, messages, etc.)

## Processing Requirements

### Message Evaluation

The Understanding phase should:

- Evaluate each message's relevance to current context
- Track message references and usage across phases
- Calculate information importance based on multiple factors
- Distinguish between user messages and AI-generated content

### Context Management Rules

1. **User Messages**:

   - Preserve by default
   - Request user consent for pruning large messages
   - Offer summarization as an alternative to full retention

2. **AI-Generated Content**:

   - Automatically prune based on relevance assessment
   - Summarize content where appropriate
   - Maintain attribution chains when summarizing

3. **Search Results**:
   - Evaluate continued relevance
   - Prune results not referenced in recent phases
   - Consolidate similar or redundant information

### Context Operations

The Understanding phase should generate appropriate context operations:

- `PRUNE`: Mark messages for removal
- `TRANSFORM`: Suggest summarization or condensing
- `PRIORITIZE`: Adjust importance of information
- `TAG`: Add metadata about information retention

### Error Handling

The Understanding phase should handle:

- Context window limits with graceful degradation
- User override of pruning recommendations
- Preservation of critical content even under constraints

## Performance Requirements

1. **Efficiency**: Complete context evaluation within 1-2 seconds
2. **Context Size Management**: Maintain context within 70% of model limits
3. **Relevance Threshold**: Achieve >85% retention of truly relevant information
4. **User Experience**: Minimize disruption when requesting consent

## Implementation Constraints

1. Maintain clear separation between:
   - User-owned content (requiring consent)
   - AI-generated content (managed automatically)
2. Implement decay functions for information relevance over time
3. Support reversible operations when possible
4. Log all pruning decisions for transparency

## Examples

### Message Evaluation and Pruning

```python
async def evaluate_messages(context: List[Message]) -> List[ContextOperation]:
    """Evaluate messages and return context operations."""
    operations = []

    # Group messages by type
    user_messages = [m for m in context if m.role == "user"]
    ai_messages = [m for m in context if m.role == "assistant"]

    # AI message evaluation
    for message in ai_messages:
        # Skip most recent message
        if message == ai_messages[-1]:
            continue

        relevance = calculate_relevance(message, context)
        if relevance < 0.3:
            operations.append({
                "operation": "PRUNE",
                "target": message.id,
                "data": {"reason": "low_relevance"},
                "metadata": {"relevance": relevance}
            })
        elif relevance < 0.7:
            operations.append({
                "operation": "TRANSFORM",
                "target": message.id,
                "data": {
                    "transformation": "summarize",
                    "parameters": {"max_length": 100}
                },
                "metadata": {"relevance": relevance}
            })

    # User message evaluation (large messages only)
    for message in user_messages:
        if len(message.content) > 1000:
            # Flag for user consent, don't prune automatically
            operations.append({
                "operation": "TRANSFORM",
                "target": message.id,
                "data": {
                    "transformation": "summarize",
                    "parameters": {"max_length": 200}
                },
                "metadata": {
                    "requires_consent": True,
                    "original_length": len(message.content)
                }
            })

    return operations
```

### User Consent Management

```python
async def request_user_consent(
    operations: List[ContextOperation],
    context: List[Message]
) -> List[ContextOperation]:
    """Request user consent for operations requiring it."""
    consent_required = [op for op in operations if op.get("metadata", {}).get("requires_consent")]

    if not consent_required:
        return operations

    # Prepare user-facing message
    consent_message = "To optimize the conversation, I'd like to summarize these earlier messages:\n\n"

    for op in consent_required:
        message = next(m for m in context if m.id == op["target"])
        preview = message.content[:50] + "..." if len(message.content) > 50 else message.content
        consent_message += f"- {preview}\n"

    consent_message += "\nWould you like me to: (1) Keep everything as is, (2) Summarize these messages, or (3) Remove them entirely?"

    # In practice, this would await actual user input
    # Simulated response for example
    user_choice = await request_user_input(consent_message)

    # Apply user choice
    if user_choice == "1":  # Keep
        return [op for op in operations if not op.get("metadata", {}).get("requires_consent")]
    elif user_choice == "2":  # Summarize
        # Keep summarization operations
        return operations
    else:  # Remove
        # Convert TRANSFORM to PRUNE
        for op in consent_required:
            op["operation"] = "PRUNE"
            op["data"] = {"reason": "user_consent"}
        return operations
```

## Interaction with Other Phases

- **Receives from**: Observation phase
- **Sends to**: Yield phase
- **Relationship**: Optimizes context before flow control decisions

## Success Criteria

1. Maintains optimal context size through intelligent pruning
2. Preserves critical information regardless of age
3. Respects user ownership of their messages
4. Provides transparent context operations
5. Improves model performance by reducing noise
