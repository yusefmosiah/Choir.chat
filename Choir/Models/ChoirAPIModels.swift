import Foundation

// MARK: - API Error Enum
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case encodingError
    case networkError(Error)
    case serverError(statusCode: Int)
    case invalidEventData
    case unknown
}

// MARK: - Server-Sent Events (SSE)
struct ServerSentEvent {
    let id: String?
    let event: String?
    let data: String?
    let retry: Int?
}

protocol SSEDelegate: AnyObject {
    func didReceiveEvent(_ event: ServerSentEvent)
    func didReceiveError(_ error: APIError)
}

// MARK: - Generic API Response Wrapper
// Kept for endpoints that might not fit the specific Turn/Thread structures yet
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

// MARK: - Threads List Endpoint Models (/users/{user_id}/threads)
struct ThreadsAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: ThreadsData?
}

struct ThreadsData: Codable {
    let threads: [ThreadResponse]?
}

// MARK: - Single Thread Info & Create Endpoint Models (/threads, /threads/{thread_id})
// Also used within ThreadsData
struct ThreadResponse: Codable, Identifiable {
    let id: String
    let name: String
    let created_at: String // Keep as String, parse when needed
    let user_id: String
    let co_authors: [String]
    let message_count: Int
    let last_activity: String // Keep as String, parse when needed
}

// MARK: - Turns (Messages) List Endpoint Models (/threads/{thread_id}/messages)
struct TurnsAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: TurnsData?
}

struct TurnsData: Codable {
    let turns: [TurnResponse]? // Maps to JSON "turns" key

    enum CodingKeys: String, CodingKey {
        case turns // JSON key is "turns"
    }
}

// Represents a single turn record fetched from the API
struct TurnResponse: Codable, Identifiable {
    let id: String
    let content: String? // AI response content
    let userQuery: String? // User input for this turn
    let threadId: String? // Make optional for robustness
    let timestamp: String? // Keep as String from API
    let phaseOutputs: [String: String]?
    let noveltyScore: Double?
    let similarityScores: [Double]? // Assuming array of doubles
    let citedPriorIds: [String]?
    let metadata: [String: String]? // Assuming simple dictionary

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case userQuery = "user_query"
        case threadId = "thread_id" // Map from snake_case
        case timestamp
        case phaseOutputs = "phase_outputs"
        case noveltyScore = "novelty_score"
        case similarityScores = "similarity_scores"
        case citedPriorIds = "cited_prior_ids"
        case metadata
    }
}

// MARK: - Authentication Endpoint Model (/auth/verify)
struct VerifyResponse: Codable {
    let user_id: String
}

// MARK: - Other Supporting Models

/// Simplified Prior model for display purposes only
struct Prior: Codable, Hashable {
    let id: String
    let content: String
    let similarity: Double
    let createdAt: String?
    let threadID: String?
    let role: String? // Role might still be relevant here if priors have roles
    let step: String?

    init(content: String, similarity: Double = 1.0, id: String = UUID().uuidString) {
        self.id = id
        self.content = content
        self.similarity = similarity
        self.createdAt = nil
        self.threadID = nil
        self.role = nil
        self.step = nil
    }
}

/// Simple request body for the streaming PostChain API
struct SimplePostchainRequestBody: Codable {
    let userQuery: String
    let threadID: String?
    var stream: Bool = true

    enum CodingKeys: String, CodingKey {
        case userQuery = "user_query"
        case threadID = "thread_id"
        case stream
    }
}

/// Represents a streaming event from the PostChain API with consistent structure
struct PostchainStreamEvent: Codable {
    let currentPhase: String
    let phaseState: String
    let content: String
    let error: String?
    let metadata: [String: Any]? // Keep Any for flexibility
    let threadId: String?

    enum CodingKeys: String, CodingKey {
        case currentPhase = "current_phase"
        case phaseState = "phase_state"
        case content, error, metadata
        case threadId = "thread_id"
    }

    // Custom init/encode needed if using [String: Any] directly
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         currentPhase = try container.decode(String.self, forKey: .currentPhase)
         phaseState = try container.decode(String.self, forKey: .phaseState)
         content = try container.decode(String.self, forKey: .content)
         error = try container.decodeIfPresent(String.self, forKey: .error)
         threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
         // Decode metadata using AnyCodable helper
         if let metadataContainer = try? container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata) {
             var convertedMetadata: [String: Any] = [:]
             for (key, value) in metadataContainer {
                 convertedMetadata[key] = value.value
             }
             metadata = convertedMetadata
         } else {
             metadata = nil
         }
     }

     func encode(to encoder: Encoder) throws {
         var container = encoder.container(keyedBy: CodingKeys.self)
         try container.encode(currentPhase, forKey: .currentPhase)
         try container.encode(phaseState, forKey: .phaseState)
         try container.encode(content, forKey: .content)
         try container.encodeIfPresent(error, forKey: .error)
         try container.encodeIfPresent(threadId, forKey: .threadId)
         // Encode metadata using AnyCodable helper
         if let metadata = metadata {
             var encodableMetadata: [String: AnyCodable] = [:]
             for (key, value) in metadata {
                 encodableMetadata[key] = AnyCodable(value)
             }
             try container.encode(encodableMetadata, forKey: .metadata)
         }
     }
}

// Helper struct to encode/decode Any values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() { value = NSNull() }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map { $0.value } }
        else if let dictionary = try? container.decode([String: AnyCodable].self) { value = dictionary.mapValues { $0.value } }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull: try container.encodeNil()
        case let bool as Bool: try container.encode(bool)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let string as String: try container.encode(string)
        case let array as [Any]: try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]: try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable cannot encode \(type(of: value))")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
