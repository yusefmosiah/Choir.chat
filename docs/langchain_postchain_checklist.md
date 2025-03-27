# Langchain PostChain Implementation Checklist

This checklist outlines the steps to implement the PostChain workflow directly using Langchain on the `langchain-postchain` branch.

- [x] **Branch Creation:** Create a new Git branch named `langchain-postchain` from the current `main` branch.
- [x] **Langchain PostChain Implementation:** Implement the PostChain workflow directly using Langchain.
    - [x] Define Langchain Chains or Agents for each phase (Action, Experience, Intention, Observation, Understanding, Yield).
    - [x] Hardcode specific model choices for each phase.
    - [-] Implement granular control over service calls (Qdrant, Sui, web search, etc.) within the Langchain implementation.
    - [x] Reuse code from the previous LangGraph implementation where applicable, adapting it to a simpler Langchain workflow.
- [ ] **Testing:** Implement basic tests to ensure the Langchain PostChain is functional.
    - [ ] Unit tests for individual phases.
    - [x] Basic integration tests for the overall workflow.
- [x] **Documentation:** Add a basic README or documentation within the `api/app/postchain` directory to describe the Langchain PostChain implementation and its components.
