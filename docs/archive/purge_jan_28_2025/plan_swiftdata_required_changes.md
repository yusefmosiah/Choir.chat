VERSION swiftdata_implementation: 6.0

The SwiftData implementation for Choir builds upon our existing architecture's foundation of REST API integration, wallet management, in-memory message handling, and chorus cycle visualization. Our current REST coordinator successfully manages phased responses with distinct types for each chorus cycle stage (action, experience, etc.), patterns we must carefully preserve in our SwiftData schema design.

Core Models & Migration (Chunk 1):
The implementation begins with the definition of our foundational models. The CHUser model encapsulates wallet integration with fields for address, balance tracking, and transaction history. CHThread manages message organization with properties for title, ownership, and activity timestamps. CHMessage stores content, user attribution, and timestamps while maintaining relationships to both threads and chorus results. The CHChorusResult model evolves from a simple key-value phase storage to a structured approach, with dedicated CHPhase entities for each chorus stage. The CHPhase model includes type identification, content storage, confidence metrics, and phase-specific fields like prior references for experience and yield decisions for understanding phases.

ViewModel Architecture (Chunk 2):
The view model layer adopts SwiftData's patterns through two key components. ThreadListViewModel manages CRUD operations via ModelContext, implementing thread creation, deletion, and asynchronous loading with SwiftData queries replacing our current state management. ThreadDetailViewModel handles the complex interaction between message processing and the ChorusCoordinator, managing message persistence and chorus result creation while maintaining thread state consistency.

View Layer Updates (Chunk 3):
The view layer transformation focuses on three critical components. ContentView transitions from @State-based thread management to @Query-based SwiftData integration. ThreadDetailView maintains our existing chorus cycle visualization while adding persistent message state management. MessageRow components adapt to the CHMessage model while preserving our current UI patterns and interaction models.

Wallet Integration (Chunk 4):
The wallet subsystem requires careful integration with SwiftData persistence. The WalletManager gains capabilities for state persistence, maintaining synchronized user records with wallet addresses and balances. Transaction history support expands through a dedicated CHTransaction model, enabling comprehensive financial state tracking while maintaining consistency with blockchain state.

Testing & Performance (Chunk 5):
The testing strategy encompasses three critical areas. Migration validation ensures complete data preservation and relationship integrity across the transition. Performance optimization focuses on query efficiency, batch loading strategies, and memory usage patterns. Error handling verification covers network failure recovery, data consistency maintenance, and wallet operation resilience. Each area includes specific metrics and success criteria, with particular attention to chorus phase relationship preservation and wallet state consistency.

The chorus result model architecture deserves special attention. Each phase exists as a distinct CHPhase entity with specific requirements: action phases maintain response content and confidence metrics, experience phases track prior references and similarity scores, intention phases manage selected priors and reasoning chains, observation phases record meta-cognitive notes and pattern recognition results, understanding phases handle yield decisions and next prompts, and yield phases store final content with formatting metadata. This structured approach enables type-safe phase management while supporting the complex relationships inherent in our chorus cycle implementation.
