import Foundation

// Base API response wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

// Request body structs
struct ActionRequestBody: Codable {
    let content: String
}

struct ExperienceRequestBody: Codable {
    let content: String
    let action_response: String
    let thread_id: String?
}

struct IntentionRequestBody: Codable {
    let content: String
    let action_response: String
    let experience_response: String
    let priors: [String: Prior]?
}

struct ObservationRequestBody: Codable {
    let content: String
    let action_response: String
    let experience_response: String
    let intention_response: String
    let selected_priors: [String]
    let priors: [String: Prior]?
    let thread_id: String?
}

struct UnderstandingRequestBody: Codable {
    let content: String
    let action_response: String
    let experience_response: String
    let intention_response: String
    let observation_response: String
    let patterns: [Pattern]
    let selected_priors: [String]
    let thread_id: String?
}

struct YieldRequestBody: Codable {
    let content: String
    let action_response: String
    let experience_response: String
    let intention_response: String
    let observation_response: String
    let understanding_response: String
    let selected_priors: [String]
    let priors: [String: Prior]?
    let thread_id: String?
}

// Base response metadata
struct ResponseMetadata: Codable {
    let reasoning: String?
    let synthesis: String?
    let next_action: String?
    let next_prompt: String?
}

// Phase-specific responses
struct ActionResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let metadata: ResponseMetadata
}

struct ExperienceResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let priors: [String: Prior]
    let metadata: ResponseMetadata
}

struct IntentionResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let selected_priors: [String]
    let metadata: ResponseMetadata
}

struct ObservationResponse: Codable {
    let step: String
    let id: String
    let content: String
    let confidence: Double
    let patterns: [Pattern]
    let metadata: ResponseMetadata
}

struct UnderstandingResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let should_yield: Bool
    let metadata: ResponseMetadata
}

struct YieldResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let citations: [Citation]
    let metadata: ResponseMetadata
}

// Supporting types
struct Prior: Codable {
    let content: String
    let similarity: Double
    let created_at: String
    let thread_id: String
    let role: String
    let step: String
}

struct Pattern: Codable {
    let type: String
    let description: String
}

struct Citation: Codable {
    let prior_id: String
    let content: String
    let context: String
}
