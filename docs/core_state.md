# Core State Management

VERSION core_state: 6.0

Note: This document describes the core state management system, with initial focus on TestFlight functionality. More sophisticated distributed coordination mechanisms described here will be implemented post-funding.

The state management system establishes clear authority hierarchies and coordination patterns across the system. At its core, the system maintains two authoritative sources of truth - the blockchain for economic state and vector stores for content state - while enabling efficient local coordination through careful state synchronization.

The Chain State serves as the ultimate arbiter of economic truth. Through a dedicated actor, it maintains authoritative thread states including co-author lists, token balances, temperature values, frequency measurements, and message hash collections. All state changes must flow through the blockchain first, ensuring perfect consistency between the network's economic state and local views.

The Vector State maintains authoritative control over content and semantic relationships. Built on Qdrant, this system provides the source of truth for messages and their embeddings. Content operations follow a strict pattern - store in the vector database first, then update local state for UI coordination. This maintains semantic coherence while enabling responsive user interfaces.

Local State Management enables efficient coordination without claiming authority. The system serves two key purposes in this regard. First, it manages UI updates by reflecting content loads and chain state changes. Second, it handles synchronization status by tracking progress and managing the offline queue. The system maintains a clean separation between authoritative state and local coordination while ensuring proper cleanup of historical data.

UI State Management reacts to authoritative changes through a carefully coordinated view model pattern. The process begins by loading authoritative thread state from the blockchain, then retrieves associated messages from the vector store. The view models maintain clean separation between source data and presentation layers while enabling efficient updates.

The system implements thorough state verification through dedicated verification actors. Chain state integrity verification ensures positive temperature values, valid frequency measurements, proper energy conservation across threads, and consistent token balances. Vector state integrity checks maintain message availability, embedding consistency, citation validity, and content coherence. Cross-state alignment verifies message hash consistency, thread state alignment, citation graph validity, and system-wide coherence.

The state management system's strength emerges from several key aspects. Authority clarity flows from the blockchain's economic authority and vector stores' content mastery, creating clean coordination patterns and clear state ownership. State transitions manifest through atomic chain updates and vector store consistency, enabling seamless UI synchronization.

System coordination maintains stability through careful actor isolation and structured state updates. This enables efficient local synchronization while ensuring clean error handling throughout the system. The verification patterns provide comprehensive oversight through state consistency checks, cross-system validation, integrity verification, and sophisticated error detection.

Through this careful orchestration of state management patterns, the system maintains perfect consistency while enabling responsive local interactions. The interplay of authority hierarchies, state transitions, and verification systems creates a robust foundation for state management that remains reliable even as the system scales and evolves.
