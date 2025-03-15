# Actor Debugging Guide

This guide provides comprehensive strategies, tools, and best practices for debugging actor-based systems in Choir. It covers approaches for dealing with the unique challenges of debugging concurrent, message-passing architectures.

## Table of Contents

1. [Introduction](#introduction)
2. [Debugging Challenges in Actor Systems](#debugging-challenges-in-actor-systems)
3. [Logging Strategies](#logging-strategies)
4. [Message Tracing](#message-tracing)
5. [State Inspection](#state-inspection)
6. [Visualizing Actor Systems](#visualizing-actor-systems)
7. [Debugging Tools](#debugging-tools)
8. [Common Issues and Solutions](#common-issues-and-solutions)
9. [Postmortem Analysis](#postmortem-analysis)
10. [Performance Debugging](#performance-debugging)

## Introduction

Debugging actor-based systems presents unique challenges due to their concurrent, message-passing nature. This guide outlines approaches to effectively debug Choir's actor architecture at various levels, from individual actors to complete workflows.

The key principles for debugging actor systems include:

1. **Message-centered debugging**: Focus on message flow rather than function calls
2. **State isolation**: Examine actor state independently from other actors
3. **Temporal reasoning**: Understand message ordering and timing
4. **Supervision awareness**: Debug within the context of the supervision hierarchy
5. **Reproducibility**: Create deterministic scenarios to reproduce issues

## Debugging Challenges in Actor Systems

Actor systems introduce several debugging challenges:

### Concurrency and Non-determinism

Actors operate concurrently, making traditional debugging approaches difficult. Race conditions and timing issues may appear in some runs but not others. The ordering of message processing can vary between executions, making bugs hard to reproduce consistently.

### Message-Passing Complexity

Following the flow of execution through multiple actors requires tracking message paths rather than function call stacks. A single logical operation may involve dozens of messages across many actors, making it difficult to understand the complete flow.

### State Encapsulation

Actors encapsulate their state, making it difficult to observe the global system state at any point in time. Unlike traditional debugging where you can examine the entire application state, actor systems distribute state across many independent entities.

### Error Propagation

Errors can propagate through the supervision hierarchy in complex ways, obscuring the original source of the problem. A failure in a child actor might manifest as unexpected behavior in a seemingly unrelated part of the system.

### Distributed Nature

In distributed actor systems, issues may span multiple processes or machines, adding complexity to debugging. Network partitions, message delivery failures, and latency issues compound the difficulty of diagnosing problems.

## Logging Strategies

Effective logging is foundational for debugging actor systems.

### Actor-Specific Logging

Each actor should include structured logging that captures:

- Actor identity (ID and type)
- Message details (ID, type, sender, receiver)
- Correlation IDs for tracing message chains
- State transitions and significant events
- Error conditions and recovery attempts

### Log Levels

Use appropriate log levels to manage the volume and significance of logging:

1. **ERROR**: For failures that require immediate attention
2. **WARNING**: For concerning situations that don't cause immediate failure
3. **INFO**: For significant state changes and lifecycle events
4. **DEBUG**: For detailed message information and internal state
5. **TRACE**: For extremely detailed debugging information

### Contextual Logging

Include relevant context in logs to make them more useful for debugging:

- Use structured logging formats (like JSON)
- Include actor identifiers and types
- Add correlation IDs to track related messages
- Include timestamp information with sufficient precision
- Log both the receipt and handling of messages

### Correlation IDs

Use correlation IDs to track related messages throughout the system:

- Generate a unique ID for each logical operation
- Propagate the ID to all messages involved in the operation
- Include the ID in all log entries related to the operation
- Use the ID to filter logs and trace message paths

## Message Tracing

Message tracing allows you to follow the path of messages through the actor system.

### Message Tracer Features

A comprehensive message tracer should:

- Record messages sent and received by each actor
- Include timestamp, direction, sender, and receiver information
- Associate messages with correlation IDs
- Provide filtering by time, actor, message type, and correlation ID
- Support visualization of message flows

### Trace Sampling

For high-throughput systems, consider sampling approaches:

- Trace only a percentage of message flows
- Enable comprehensive tracing only for specific correlation IDs
- Allow dynamic adjustment of sampling rates
- Automatically increase sampling when errors occur

### Message Path Analysis

Analyze message paths to identify issues:

- Look for unexpected message sequences
- Identify messages that don't receive responses
- Detect unusual timing patterns
- Spot circular message patterns that might indicate loops

## State Inspection

Inspecting actor state is crucial for debugging.

### State Snapshots

Create a mechanism to capture actor state snapshots:

- Take snapshots at key points in actor lifecycle
- Capture snapshots before and after significant operations
- Store snapshots with timestamps and context information
- Compare snapshots to identify unexpected state changes

### Non-Intrusive State Access

Access actor state without disrupting the system:

- Use dedicated debug interfaces that don't affect production behavior
- Create read-only views of actor state
- Implement state inspection without pausing message processing
- Consider using separate monitoring actors for state inspection

### State Validation

Validate actor state to detect corruption:

- Define invariants that should always hold for actor state
- Check schema compliance for structured state
- Verify relationships between state elements
- Detect inconsistencies that could indicate bugs

## Visualizing Actor Systems

Visualization tools help understand complex actor systems.

### Actor System Visualization

Generate visualizations of the actor system to understand its structure:

- Create graphs showing actors and their relationships
- Highlight message flows between actors
- Visualize actor creation and termination over time
- Show message volumes and patterns

### Supervision Hierarchy Visualization

Visualize the supervision hierarchy to understand error handling:

- Show parent-child relationships between actors
- Illustrate restart strategies for different actor types
- Highlight error propagation paths
- Display actor lifecycle states

### Message Flow Diagrams

Create sequence diagrams of message flows:

- Show the temporal sequence of messages between actors
- Illustrate causal relationships between messages
- Highlight timing patterns and potential bottlenecks
- Identify messaging patterns that might indicate problems

## Debugging Tools

Specialized tools for debugging actor systems.

### Actor System Inspector

An interactive inspector for the actor system should provide:

- Real-time listing of active actors
- State inspection for individual actors
- Message history for specific actors
- Trace visualization for message flows
- Commands to send test messages to actors

### Remote Debugging Interface

Create an API for remote debugging that offers:

- HTTP endpoints for system inspection
- Real-time monitoring via WebSockets
- Secured access for production systems
- Non-intrusive inspection capabilities

### Playback Debugger

Implement a message playback system for debugging:

- Record message sequences during execution
- Replay messages to reproduce issues
- Support step-by-step replay for detailed analysis
- Allow modification of messages during replay for testing fixes

## Common Issues and Solutions

Common issues in actor systems and how to debug them.

### Dead Letters

Messages sent to non-existent actors:

- Implement a dead letter office to capture these messages
- Log detailed information about dead letters
- Identify patterns of dead letters that might indicate bugs
- Check sender logic to understand why messages are being misrouted

### Message Handling Errors

Debugging errors in message handling:

- Log exceptions with full context and stack traces
- Include message details in error reports
- Implement circuit breakers to prevent cascading failures
- Consider message retries for transient errors

### State Corruption

Detecting and recovering from state corruption:

- Implement state validation routines
- Create snapshots before potentially risky operations
- Design recovery mechanisms for corrupted state
- Log state transitions for audit trails

### Message Cycles

Detecting and breaking message cycles:

- Implement cycle detection in the message dispatcher
- Set maximum hop counts for message forwarding
- Add deadlock detection for actors waiting on responses
- Create timeout mechanisms for message processing

## Postmortem Analysis

Analyzing issues after they occur.

### System Snapshots

Create and analyze system snapshots:

- Periodically capture the state of all actors
- Take snapshots when errors occur
- Store snapshots with relevant context
- Compare snapshots over time to identify trends

### Log Analysis

Analyze logs for patterns:

- Aggregate logs from all system components
- Filter logs by correlation ID to follow specific operations
- Look for error patterns and precursors
- Identify timing anomalies that might indicate issues

### Failure Recreation

Reproduce failures for debugging:

- Create test scenarios based on production issues
- Use recorded message sequences to replicate problems
- Implement controlled chaos testing to find edge cases
- Test recovery mechanisms under realistic conditions

## Performance Debugging

Debugging performance issues in actor systems.

### Message Latency Analysis

Analyze message processing latency:

- Measure time from message send to response
- Break down latency by message type and actor
- Identify slow message handlers
- Look for patterns in latency spikes

### Mailbox Monitoring

Monitor actor mailbox sizes to detect bottlenecks:

- Track mailbox growth over time
- Identify actors with consistently large mailboxes
- Look for message types that cause mailbox growth
- Implement backpressure mechanisms for overloaded actors

### Throughput Analysis

Analyze system throughput:

- Measure messages processed per second
- Break down throughput by message type and actor
- Identify throughput bottlenecks
- Look for unexpected drops in throughput

### Resource Utilization

Monitor resource usage in the actor system:

- Track CPU, memory, and I/O usage by actor
- Identify resource-intensive operations
- Look for resource leaks over time
- Correlate resource spikes with message patterns

## Conclusion

Debugging actor-based systems requires specialized approaches that focus on message passing, concurrency, and state management. By following the patterns and practices in this guide, you can effectively debug Choir's actor architecture.

Remember these key principles:

1. Focus on message flow rather than function calls
2. Use correlation IDs to track related messages
3. Capture actor state independently from other actors
4. Understand message ordering and timing
5. Debug within the context of the supervision hierarchy

For practical implementation of these techniques, refer to the debugging utilities in the `choir.debug` module.
