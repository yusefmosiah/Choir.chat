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
    let threadID: String?
    let context: [MessageContext]?

    enum CodingKeys: String, CodingKey {
        case content
        case threadID = "thread_id"
        case context
    }
}

struct ExperienceRequestBody: Codable {
    let content: String
    let actionResponse: String
    let threadID: String?
    let context: [MessageContext]?

    enum CodingKeys: String, CodingKey {
        case content
        case actionResponse = "action_response"
        case threadID = "thread_id"
        case context
    }
}

struct IntentionRequestBody: Codable {
    let content: String
    let actionResponse: String
    let experienceResponse: String
    let priors: [String: Prior]
    let threadID: String?
    let context: [MessageContext]?

    enum CodingKeys: String, CodingKey {
        case content
        case actionResponse = "action_response"
        case experienceResponse = "experience_response"
        case priors
        case threadID = "thread_id"
        case context
    }
}

struct ObservationRequestBody: Codable {
    let content: String
    let actionResponse: String
    let experienceResponse: String
    let intentionResponse: String
    let selectedPriors: [String]
    let priors: [String: Prior]
    let threadID: String?
    let context: [MessageContext]?

    enum CodingKeys: String, CodingKey {
        case content
        case actionResponse = "action_response"
        case experienceResponse = "experience_response"
        case intentionResponse = "intention_response"
        case selectedPriors = "selected_priors"
        case priors
        case threadID = "thread_id"
        case context
    }
}

struct UnderstandingRequestBody: Codable {
    let content: String
    let actionResponse: String
    let experienceResponse: String
    let intentionResponse: String
    let observationResponse: String
    let patterns: [Pattern]
    let selectedPriors: [String]
    let threadID: String?
    let context: [MessageContext]?

    enum CodingKeys: String, CodingKey {
        case content
        case actionResponse = "action_response"
        case experienceResponse = "experience_response"
        case intentionResponse = "intention_response"
        case observationResponse = "observation_response"
        case patterns
        case selectedPriors = "selected_priors"
        case threadID = "thread_id"
        case context
    }
}

struct YieldRequestBody: Codable {
    let content: String
    let actionResponse: String
    let experienceResponse: String
    let intentionResponse: String
    let observationResponse: String
    let understandingResponse: String
    let selectedPriors: [String]
    let priors: [String: Prior]
    let threadID: String?
    let context: [MessageContext]?

    enum CodingKeys: String, CodingKey {
        case content
        case actionResponse = "action_response"
        case experienceResponse = "experience_response"
        case intentionResponse = "intention_response"
        case observationResponse = "observation_response"
        case understandingResponse = "understanding_response"
        case selectedPriors = "selected_priors"
        case priors
        case threadID = "thread_id"
        case context
    }
}

// Base response type for all phases
struct BaseResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
}

// Phase-specific responses
struct ActionResponse: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
}

struct ExperienceResponseData: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
    let priors: [String: Prior]
}

struct IntentionResponseData: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
    let selectedPriors: [String]?

    enum CodingKeys: String, CodingKey {
        case step
        case content
        case confidence
        case reasoning
        case selectedPriors = "selected_priors"
    }
}

struct ObservationResponseData: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
}

struct UnderstandingResponseData: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
    let shouldYield: Bool?
    let nextPrompt: String?

    enum CodingKeys: String, CodingKey {
        case step
        case content
        case confidence
        case reasoning
        case shouldYield = "should_yield"
        case nextPrompt = "next_prompt"
    }
}

struct YieldResponseData: Codable {
    let step: String
    let content: String
    let confidence: Double
    let reasoning: String
}

// Supporting types
struct Prior: Codable {
    let content: String
    let similarity: Double
    let createdAt: String?
    let threadID: String?
    let role: String?
    let step: String?

    enum CodingKeys: String, CodingKey {
        case content
        case similarity
        case createdAt = "created_at"
        case threadID = "thread_id"
        case role
        case step
    }
}

struct Pattern: Codable {
    let type: String
    let description: String
}

// Add context model
struct MessageContext: Codable {
    let content: String
    let isUser: Bool
    let timestamp: String
    let postchainResult: [String: String]?

    enum CodingKeys: String, CodingKey {
        case content
        case isUser = "is_user"
        case timestamp
        case postchainResult = "postchain_result"
    }

    init(from message: Message) {
        self.content = message.content
        self.isUser = message.isUser
        self.timestamp = ISO8601DateFormatter().string(from: message.timestamp)
        self.postchainResult = message.chorusResult?.phases.reduce(into: [String: String]()) { dict, pair in
            dict[pair.key.rawValue] = pair.value
        }
    }
}

// Type aliases for clearer API response handling
typealias ActionAPIResponse = APIResponse<ActionResponse>
typealias ExperienceResponse = ExperienceResponseData
typealias ExperienceAPIResponse = APIResponse<ExperienceResponseData>
typealias IntentionResponse = IntentionResponseData
typealias IntentionAPIResponse = APIResponse<IntentionResponseData>
typealias ObservationResponse = ObservationResponseData
typealias ObservationAPIResponse = APIResponse<ObservationResponseData>
typealias UnderstandingResponse = UnderstandingResponseData
typealias UnderstandingAPIResponse = APIResponse<UnderstandingResponseData>
typealias YieldResponse = YieldResponseData
typealias YieldAPIResponse = APIResponse<YieldResponseData>
