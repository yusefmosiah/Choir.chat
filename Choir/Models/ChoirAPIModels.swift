import Foundation

// Existing API Models (Keep or modify as needed)

// Example: Response structure if backend wraps responses
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

// Example: Thread response structure (Likely obsolete now)
struct ThreadResponse: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let created_at: String
    let user_id: String
    let co_authors: [String]
    let message_count: Int
    let last_activity: String
}

// Example: Turn response structure (Likely obsolete now)
struct TurnResponse: Codable, Identifiable {
     let id: String // Turn ID
     let content: String? // AI response content
     let userQuery: String? // User query for this turn
     let threadId: String?
     let timestamp: String? // ISO 8601 format
     let phaseOutputs: [String: String]? // Dictionary of phase outputs
     let metadata: [String: String]? // Other metadata
     // Add other fields as needed based on actual API response

     enum CodingKeys: String, CodingKey {
         case id
         case content
         case userQuery = "user_query"
         case threadId = "thread_id"
         case timestamp
         case phaseOutputs = "phase_outputs"
         case metadata
     }
 }

// Example: Structure for the list of turns (Likely obsolete now)
struct TurnsAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: TurnsData? // Make data optional

    struct TurnsData: Codable {
        let turns: [TurnResponse]? // Make turns optional
    }
}


// Example: Authentication response
struct VerifyResponse: Codable {
    let success: Bool
    let user_id: String
    let message: String?
}

// --- NEW: Turn Data Structure for Final Event ---

struct TurnData: Codable {
    let turnId: String
    let timestamp: String // Keep as ISO string for simplicity
    let userQuery: String
    let aiResponseContent: String
    let phaseOutputs: [String: String] // Phase name to content string
    let metadata: TurnMetadata // Nested struct for clarity

    enum CodingKeys: String, CodingKey {
        case turnId = "turn_id"
        case timestamp
        case userQuery = "user_query"
        case aiResponseContent = "ai_response_content"
        case phaseOutputs = "phase_outputs"
        case metadata
    }
}

struct TurnMetadata: Codable {
    let actionModel: String
    let experienceModel: String
    let intentionModel: String
    let observationModel: String
    let understandingModel: String
    let yieldModel: String
    let noveltyScore: Double? // Assuming float/double
    let similarityScores: [String: Double]? // Example structure, adjust if needed
    let citedPriorIds: [String]?

     enum CodingKeys: String, CodingKey {
        case actionModel = "action_model"
        case experienceModel = "experience_model"
        case intentionModel = "intention_model"
        case observationModel = "observation_model"
        case understandingModel = "understanding_model"
        case yieldModel = "yield_model"
        case noveltyScore = "novelty_score"
        case similarityScores = "similarity_scores"
        case citedPriorIds = "cited_prior_ids"
    }
}

// --- NEW: Structure for Sending History ---
struct MessageHistoryItem: Codable {
    let role: String // "user" or "assistant"
    let content: String
}


// Define APIError if not already defined elsewhere
enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError(statusCode: Int)
    case networkError(Error)
    case decodingError
    case invalidResponse
    case invalidEventData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL encountered."
        case .serverError(let code): return "Server error with status code: \(code)."
        case .networkError(let err): return "Network error: \(err.localizedDescription)."
        case .decodingError: return "Failed to decode response."
        case .invalidResponse: return "Invalid response structure received."
        case .invalidEventData: return "Invalid data received in server-sent event."
        }
    }
}


// --- Helper for encoding/decoding arbitrary JSON values ---
// Source: https://stackoverflow.com/questions/48035271/how-to-decode-json-with-mixed-types-in-swift
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is Void, is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
