# Stack Pivot Summary: From LangGraph to MCP Architecture

## Executive Summary

Choir has undergone a significant architectural pivot, moving from a graph-based implementation using LangGraph to an MCP-based architecture. This document summarizes the rationale, advantages, and implementation plan for this transition.

## Key Decisions

1.  **Architectural Pattern**: MCP Architecture instead of Graph Model
2.  **Core Framework**: Model Context Protocol (MCP) for server-based phases
3.  **Database**: libSQL/Turso for SQL+vector capabilities
4.  **Blockchain**: Sui via PySUI
5.  **Type Safety**: Pydantic
6.  **API**: FastAPI/Uvicorn
7.  **Deployment**: Docker on Phala Network

## Rationale for the Pivot

After extensive experimentation with LangGraph, several challenges emerged, and further analysis suggested MCP as a more suitable architecture:

1.  **Memory Management Issues**: Persistent problems with memory usage and state management in LangGraph remained unresolved.
2.  **Debugging Complexity**: Difficulty in tracing and resolving issues in the complex LangGraph workflows.
3.  **Architectural Mismatch**: LangGraph's graph model was not ideally suited for the desired phase-based, service-oriented architecture.
4.  **Scalability Concerns**:  Uncertainties about the scalability of the LangGraph approach for long-term growth.
5.  **Desire for Service Isolation**:  A need for better isolation and modularity between phases, which MCP servers could provide.

## Advantages of MCP Architecture

The MCP architecture provides significant advantages for Choir:

1.  **Service Encapsulation**: Each phase is encapsulated as a separate MCP server, improving modularity and maintainability.
2.  **Clear Tool Boundaries**:  Each phase's MCP server explicitly defines and controls the tools it can access, enhancing security and preventing runaway tool use.
3.  **Improved Isolation**:  Fault isolation is enhanced as phases run in separate server processes.
4.  **Resource Management**: Each MCP server manages its own resources, potentially improving resource utilization and stability.
5.  **Scalability**:  The service-oriented nature of MCP architecture allows for easier scaling and distribution of phases.
6.  **Technology Alignment**: MCP aligns well with the vision of decentralized, service-oriented AI and the use of Phala Network for secure enclaves.

## PostChain as MCP Servers

The AEIOU-Y PostChain maps naturally to specialized MCP servers, with each phase implemented as a separate server:

- **Action Server**: Handles user input and initial response in the Action phase
- **Experience Server**: Implements knowledge retrieval and context enrichment for the Experience phase
- **Intention Server**: Focuses on user intent modeling and goal setting in the Intention phase
- **Observation Server**: Manages semantic connections and information tagging for the Observation phase
- **Understanding Server**: Performs context evaluation and filtering in the Understanding phase
- **Yield Server**: Handles final response generation and process completion in the Yield phase

## Technical Stack Synergy

The components of the new MCP-based stack work together synergistically:

- **MCP + FastAPI/Uvicorn**:  FastAPI provides a robust API layer for interacting with MCP servers.
- **MCP + libSQL/Turso**: Each MCP server can use libSQL for local state persistence if needed.
- **MCP + PySUI**: MCP servers can potentially integrate with PySUI for blockchain interactions in a modular way.
- **Docker + Phala**: MCP servers can be containerized and deployed securely on Phala Network.

## Migration Path

The migration to MCP architecture will follow a structured path:

1.  **Define MCP Server Interfaces**: Clearly define the tool and resource interfaces for each phase's MCP server.
2.  **Implement Core MCP Servers**:  Develop the basic MCP server structure for each of the AEIOU-Y phases.
3.  **Integrate Langchain Utils**:  Incorporate the existing `langchain_utils.py` for model interactions within MCP servers.
4.  **Implement SSE Streaming**: Add SSE streaming capabilities to each MCP server for real-time output.
5.  **Orchestrate with Python API**: Update the Python API to orchestrate calls to the new MCP servers and handle SSE streams.
6.  **Deploy and Test**:  Deploy the MCP-based architecture in a local Docker environment and then on Phala Network for testing and validation.

## Security Benefits of MCP Architecture

The MCP architecture enhances security in several dimensions:

1.  **Tool Control**:  Strict control over tools available to each phase, reducing the risk of unintended actions.
2.  **Service Isolation**:  Phases run in separate server processes, limiting the impact of potential vulnerabilities in one phase.
3.  **Clear Interfaces**:  Well-defined interfaces between phases (MCP protocol) improve system understanding and security analysis.
4.  **Minimal Tool Exposure**:  Phases only expose necessary tools, reducing the attack surface.
5.  **Phala Integration**:  Deployment on Phala Network provides confidential computing guarantees for sensitive operations within MCP servers.

## Documentation Updates

The documentation will be updated to reflect the new MCP architecture:

1.  Updated: Stack Pivot Summary document to reflect MCP architecture
2.  Updated: Documentation index and navigation to remove actor-model specific content
3.  To be added: MCP architecture diagrams and descriptions
4.  To be added: MCP server implementation guidelines

## Conclusion

The pivot from LangGraph to the MCP architecture represents a strategic evolution for Choir.  By adopting MCP, we gain a more modular, scalable, and secure architecture that aligns better with the project's goals of decentralized, service-oriented AI. This transition positions Choir for long-term growth and innovation while maintaining the core AEIOU-Y PostChain conceptual framework.
