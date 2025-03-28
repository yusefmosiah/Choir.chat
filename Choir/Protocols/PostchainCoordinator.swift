import Foundation
import SwiftUI

@MainActor
protocol PostchainCoordinator {
    // State
    var currentPhase: Phase { get }
    var responses: [Phase: String] { get }
    var isProcessing: Bool { get }
    var isStreaming: Bool { get }

    // Message tracking
    var activeMessageId: UUID? { get set }
    
    // Access to messages
    var messages: [Message] { get }

    // Core processing
    func process(_ input: String) async throws
    func cancel()

    // Thread state
    var currentChoirThread: ChoirThread? { get set }

    // Phase tracking
    func isProcessingPhase(_ phase: Phase) -> Bool

    init()
}

// Simple test implementation for previews and tests
@MainActor
class TestPostchainCoordinator: PostchainCoordinator {
    var currentPhase: Phase = .action
    var responses: [Phase: String] = [:]
    var isProcessing = false
    var isStreaming = false
    var activeMessageId: UUID?
    var currentChoirThread: ChoirThread?
    
    // Implementation of the messages property
    var messages: [Message] {
        return currentChoirThread?.messages ?? []
    }

    required init() {}

    func process(_ input: String) async throws {
        isProcessing = true
        responses[.action] = "Processing \(input)..."
        try await Task.sleep(nanoseconds: 1_000_000_000)
        responses[.action] = "Here's a response to: \(input)"
        isProcessing = false
    }

    func cancel() {
        isProcessing = false
        responses = [:]
    }

    func isProcessingPhase(_ phase: Phase) -> Bool {
        return isProcessing && phase == currentPhase
    }
}
