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
    
    /// Process a user query through the postchain
    /// - Parameters:
    ///   - input: User input text
    ///   - modelConfigs: Optional model configurations for each phase
    /// - Throws: Error if processing fails
    func process(_ input: String, modelConfigs: [Phase: ModelConfig]) async throws
    
    /// Cancel the current processing job
    func cancel()
}