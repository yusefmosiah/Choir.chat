import Foundation
import SwiftUI

@MainActor
class MockPostchainCoordinator: PostchainCoordinator, ObservableObject {
    @Published private(set) var currentPhase: Phase = .action
    @Published private(set) var responses: [Phase: String] = [:]
    @Published private(set) var isProcessing = false

    // Response state
    private(set) var actionResponse: ActionResponse?
    private(set) var experienceResponse: ExperienceResponse?
    private(set) var intentionResponse: IntentionResponse?
    private(set) var observationResponse: ObservationResponse?
    private(set) var understandingResponse: UnderstandingResponse?
    private(set) var yieldResponse: YieldResponse?

    private var mockDelay: TimeInterval = 1.0
    weak var viewModel: PostchainViewModel?

    required init() {}

    func process(_ input: String) async throws {
        // Clear state at start
        responses = [:]
        isProcessing = true

        defer {
            isProcessing = false
        }

        do {
            // Action phase
            currentPhase = .action
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let decoder = JSONDecoder()
            let actionJSON = """
            {
                "step": "action",
                "content": "I understand you said: \(input)",
                "confidence": 0.9,
                "reasoning": "The input directly states what the user is saying"
            }
            """.data(using: .utf8)!

            actionResponse = try decoder.decode(ActionResponse.self, from: actionJSON)
            responses[.action] = actionResponse?.content
            viewModel?.updateState()

            // Experience phase
            currentPhase = .experience
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let experienceJSON = """
            {
                "step": "experience",
                "content": "Based on previous interactions...",
                "confidence": 0.85,
                "reasoning": "Several prior conversations show similar patterns",
                "priors": {}
            }
            """.data(using: .utf8)!

            experienceResponse = try decoder.decode(ExperienceResponse.self, from: experienceJSON)
            responses[.experience] = experienceResponse?.content
            viewModel?.updateState()

            // Intention phase
            currentPhase = .intention
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let intentionJSON = """
            {
                "step": "intention",
                "content": "Your intention appears to be...",
                "confidence": 0.8,
                "reasoning": "Based on your phrasing and context",
                "selected_priors": ["id1", "id2"]
            }
            """.data(using: .utf8)!

            intentionResponse = try decoder.decode(IntentionResponse.self, from: intentionJSON)
            responses[.intention] = intentionResponse?.content
            viewModel?.updateState()

            // Observation phase
            currentPhase = .observation
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let observationJSON = """
            {
                "step": "observation",
                "content": "I notice several patterns...",
                "confidence": 0.85,
                "reasoning": "Analyzing the selected priors reveals",
                "patterns": [
                    {"type": "theme", "description": "Recurring interest in..."},
                    {"type": "style", "description": "Tendency to..."}
                ]
            }
            """.data(using: .utf8)!

            observationResponse = try decoder.decode(ObservationResponse.self, from: observationJSON)
            responses[.observation] = observationResponse?.content
            viewModel?.updateState()

            // Understanding phase
            currentPhase = .understanding
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let understandingJSON = """
            {
                "step": "understanding",
                "content": "I now understand that...",
                "confidence": 0.9,
                "reasoning": "The patterns and context indicate",
                "should_yield": true,
                "next_prompt": null
            }
            """.data(using: .utf8)!

            understandingResponse = try decoder.decode(UnderstandingResponse.self, from: understandingJSON)
            responses[.understanding] = understandingResponse?.content
            viewModel?.updateState()

            // Yield phase
            currentPhase = .yield
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            try Task.checkCancellation()

            let yieldJSON = """
            {
                "step": "yield",
                "content": "Here's my synthesized response to: \(input)",
                "confidence": 0.95,
                "reasoning": "Drawing from the analyzed patterns",
                "citations": [
                    {
                        "prior_id": "id1",
                        "content": "relevant prior content",
                        "context": "how this informed the response"
                    }
                ]
            }
            """.data(using: .utf8)!

            yieldResponse = try decoder.decode(YieldResponse.self, from: yieldJSON)
            responses[.yield] = yieldResponse?.content
            viewModel?.updateState()

        } catch is CancellationError {
            responses[currentPhase] = "Cancelled"
            throw APIError.cancelled
        }
    }

    func cancel() {
        isProcessing = false
    }
}
