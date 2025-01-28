VERSION getting_started: 6.0

The Choir development environment begins with a carefully structured Xcode project setup. Using Xcode 16.1, create a new iOS App project named "Choir" targeting iOS 17.0, leveraging SwiftUI for the interface and Swift as the primary language. The project should include test targets to ensure robust development practices.

The project architecture follows a clean, modular structure. At its core, the system relies on key dependencies, particularly the web3.swift package for blockchain integration. The project organization separates concerns into distinct layers: App for application entry points, Core for fundamental system components, Features for specific functionality modules, Services for network and storage operations, and Tests for comprehensive testing coverage.

The Core layer houses the event system, actor-based coordination, and fundamental models. Events are categorized into AI, vector, and chain operations, while actors manage foundation model coordination, embedding generation, vector operations, and blockchain interactions. Core models define the basic data structures for messages, threads, and effects.

The event store serves as a central coordination point, using SwiftData for persistent event logging while managing network synchronization. It coordinates with AI, vector, and chain services to distribute events throughout the system. Network services are implemented through dedicated actors that handle foundation model interactions, vector store operations, and blockchain coordination, each maintaining its own event logging and state management.

Testing follows a comprehensive approach using the Swift Testing framework. Network integration tests verify the interaction between different system components, with separate test cases for AI service integration and vector service operations. The development workflow moves through clear phases: initial setup, development in Cursor, testing in Xcode, and continuous iteration to maintain system coherence.

This architecture enables sophisticated distributed processing, seamless network coordination, event-driven updates, and comprehensive service integration, all while supporting natural system evolution. The careful separation of concerns and robust testing practices ensure the system remains maintainable and reliable as it grows in complexity.
