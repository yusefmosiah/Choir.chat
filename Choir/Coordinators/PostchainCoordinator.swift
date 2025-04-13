import Foundation

/// Protocol defining the core functionality of a Postchain coordinator
@MainActor
protocol PostchainCoordinator: ObservableObject {
    /// Current active phase in the postchain process
    var currentPhase: Phase { get }
    
    /// Responses from the postchain API for each phase
    var responses: [Phase: String] { get }
    
    /// Whether the coordinator is currently processing
    var isProcessing: Bool { get }
    
    /// Current ChoirThread being processed
    var currentChoirThread: ChoirThread? { get }
    
    /// UUID of the active message being processed
    var activeMessageId: UUID? { get }
    
    /// Web search results from the latest request
    var webResults: [SearchResult] { get }
    
    /// Vector search results from the latest request
    var vectorResults: [VectorSearchResult] { get }
    
    /// Process a user query through the postchain
    /// - Parameters:
    ///   - input: User input text
    ///   - modelConfigs: Optional model configurations for each phase
    /// - Throws: Error if processing fails
    func process(_ input: String, modelConfigs: [Phase: ModelConfig]) async throws
    
    /// Process a user query with progress updates
    /// - Parameters:
    ///   - input: User input text
    ///   - modelConfigs: Model configurations for each phase
    ///   - onProgress: Callback for progress updates
    /// - Throws: Error if processing fails
    func processWithProgress(_ input: String, modelConfigs: [Phase: ModelConfig], onProgress: ((String) -> Void)?) async throws
    
    /// Cancel the current processing job
    func cancel()
}