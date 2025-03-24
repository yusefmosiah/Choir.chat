# PostChain Phase Requirements

## Overview

This directory contains detailed Product Requirements Documents (PRDs) for each phase of the PostChain. These specifications define the exact responsibilities, behaviors, inputs, and outputs for each phase actor.

## Temporal Relationship to Information

The PostChain phases embody different temporal relationships to information:

| Phase             | Temporal Focus       | Core Responsibility                       |
| ----------------- | -------------------- | ----------------------------------------- |
| **Action**        | Immediate present    | Model calls and tool execution            |
| **Experience**    | Past knowledge       | Information retrieval and enrichment      |
| **Intention**     | Desired future       | Goal-seeking and focus refinement         |
| **Observation**   | Future preservation  | Memory persistence and connection marking |
| **Understanding** | Temporal integration | Context filtering and information release |
| **Yield**         | Process completion   | Flow control and recursion decisions      |

## Phase Specifications

### [Action Phase](action_phase.md)

The Action phase handles direct model calls and tool execution, operating in the immediate present with minimal historical context. It serves as both the entry point and potential recursive re-entry point for the PostChain.

**Key responsibilities**: Model inference, tool execution, initial response generation

### [Experience Phase](experience_phase.md)

The Experience phase enriches the conversation with retrieved knowledge, serving as the system's memory and knowledge acquisition component. It embodies the system's relationship with past knowledge.

**Key responsibilities**: Information retrieval, context enrichment, knowledge enhancement

### [Intention Phase](intention_phase.md)

The Intention phase refines and focuses information toward user goals, aligning the accumulated context with desired outcomes. It represents the system's orientation toward future objectives.

**Key responsibilities**: Goal identification, priority setting, relevance determination

### [Observation Phase](observation_phase.md)

The Observation phase identifies and persists connections between concepts, creating semantic links for future reference. It manages the preservation of information beyond the current cycle.

**Key responsibilities**: Connection marking, semantic tagging, memory persistence

### [Understanding Phase](../require_understanding_phase.md)

The Understanding phase evaluates accumulated information to determine what remains relevant and what can be released. It embodies the wisdom of letting go of less relevant information.

**Key responsibilities**: Context filtering, information pruning, message evaluation

### [Yield Phase](../require_yield_phase.md)

The Yield phase determines whether to produce a final response or continue processing through another recursive cycle. It controls the flow of the entire PostChain process.

**Key responsibilities**: Recursion decisions, flow control, response formatting

## Implementation Strategy

These phase requirements represent ideal behaviors for a full actor-based implementation. During initial development with PydanticAI, a simplified version may be implemented first, while maintaining alignment with these conceptual responsibilities.

The phase requirements should be used as reference during implementation to ensure that each phase, regardless of the underlying architecture, fulfills its core temporal relationship to information.

## Document Format

Each phase requirement document follows a consistent format:

1. **Overview**: Brief description of the phase and its purpose
2. **Core Responsibilities**: List of primary responsibilities
3. **Temporal Focus**: Relationship to time and information
4. **Input Specification**: Expected inputs and their structure
5. **Output Specification**: Required outputs and their structure
6. **Processing Requirements**: Specific processing behaviors
7. **Performance Requirements**: Expected performance characteristics
8. **Implementation Constraints**: Technical implementation guidelines
9. **Examples**: Code examples showing how the phase might be implemented
10. **Interaction with Other Phases**: How the phase connects to others
11. **Success Criteria**: Measurable success indicators
