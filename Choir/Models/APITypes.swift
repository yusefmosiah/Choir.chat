import Foundation

// MARK: - API Errors

/// Comprehensive error type for all API and networking errors
enum APIError: Error, LocalizedError {
    // Request formation errors
    case invalidURL
    case encodingError

    // Network errors
    case networkError(underlying: Error)
    case timeout(seconds: TimeInterval)
    case serverError(statusCode: Int, message: String?)

    // Response processing errors
    case invalidResponse
    case decodingError(context: String = "")
    case invalidEventData

    // Domain-specific errors
    case inputTooLarge(length: Int, maxAllowed: Int)
    case unauthorized
    case serviceUnavailable
    case resourceNotFound(resource: String)
    case unknown

    // User-friendly error descriptions
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout(let seconds):
            return "Request timed out after \(seconds) seconds"
        case .serverError(let code, let message):
            if let message = message, !message.isEmpty {
                return "Server error (\(code)): \(message)"
            }
            return "Server error (status code: \(code))"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let context):
            return "Failed to decode server response\(context.isEmpty ? "" : ": \(context)")"
        case .invalidEventData:
            return "Invalid event data received from server"
        case .inputTooLarge(let length, let maxAllowed):
            return "Input text is too large (\(length) characters). Maximum allowed is \(maxAllowed)."
        case .unauthorized:
            return "Authentication required"
        case .serviceUnavailable:
            return "Service is temporarily unavailable"
        case .resourceNotFound(let resource):
            return "Resource not found: \(resource)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - API Models

/// Base request protocol for all API requests
protocol APIRequest: Encodable {
    associatedtype Response: Decodable

    var endpoint: String { get }
    var method: HTTPMethod { get }
    var timeoutInterval: TimeInterval { get }
}

/// Default implementation for APIRequest
extension APIRequest {
    var method: HTTPMethod { .post }
    var timeoutInterval: TimeInterval { 60.0 }
}

/// HTTP methods supported by the API
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Generic API response wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?
}

// MARK: - Server-Sent Events

/// Represents a single Server-Sent Event
struct ServerSentEvent {
    let id: String?
    let event: String?
    let data: String?
    let retry: Int?
}

/// Protocol for SSE delegate
protocol SSEDelegate: AnyObject {
    func didReceiveEvent(_ event: ServerSentEvent)
    func didReceiveError(_ error: APIError)
    func didComplete()
}

// MARK: - Postchain Models

/// Main request body for Postchain API
struct PostchainRequest: APIRequest {
    typealias Response = PostchainResponse

    let userQuery: String
    let threadId: String
    let modelConfigs: [String: ModelConfigRequest]?
    var stream: Bool = true

    var endpoint: String { "langchain" }

    enum CodingKeys: String, CodingKey {
        case userQuery = "user_query" // Keep this as snake_case since it's used in API requests
        case threadId = "thread_id" // Keep this as snake_case since it's used in API requests
        case modelConfigs = "model_configs" // Keep this as snake_case since it's used in API requests
        case stream
    }
}

/// Model configuration for requests
struct ModelConfigRequest: Codable {
    let provider: String
    let model_name: String // Using snake_case to match backend API expectations
    let temperature: Double?

    // API Keys
    let openaiApiKey: String?
    let anthropicApiKey: String?
    let googleApiKey: String?
    let mistralApiKey: String?
    let fireworksApiKey: String?
    let cohereApiKey: String?
    let openrouterApiKey: String?
    let groqApiKey: String?

    init(from modelConfig: ModelConfig) {
        self.provider = modelConfig.provider

        // Store model name in model_name field (mapping from ModelConfig.model to model_name)
        self.model_name = modelConfig.model


        self.temperature = modelConfig.temperature
        self.openaiApiKey = modelConfig.openaiApiKey
        self.anthropicApiKey = modelConfig.anthropicApiKey
        self.googleApiKey = modelConfig.googleApiKey
        self.mistralApiKey = modelConfig.mistralApiKey
        self.fireworksApiKey = modelConfig.fireworksApiKey
        self.cohereApiKey = modelConfig.cohereApiKey
        self.openrouterApiKey = modelConfig.openrouterApiKey
        self.groqApiKey = modelConfig.groqApiKey
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case model_name // Keep this as snake_case since it's used in API requests
        case temperature
        case openaiApiKey = "openai_api_key" // Keep this as snake_case since it's used in API requests
        case anthropicApiKey = "anthropic_api_key" // Keep this as snake_case since it's used in API requests
        case googleApiKey = "google_api_key" // Keep this as snake_case since it's used in API requests
        case mistralApiKey = "mistral_api_key" // Keep this as snake_case since it's used in API requests
        case fireworksApiKey = "fireworks_api_key" // Keep this as snake_case since it's used in API requests
        case cohereApiKey = "cohere_api_key" // Keep this as snake_case since it's used in API requests
        case openrouterApiKey = "openrouter_api_key" // Keep this as snake_case since it's used in API requests
        case groqApiKey = "groq_api_key" // Keep this as snake_case since it's used in API requests
    }
}

/// Response from Postchain endpoint
struct PostchainResponse: Decodable {
    let status: String
    let phases: [String: String]?
    let phaseSettings: [String: [String: AnyCodable]]?

    enum CodingKeys: String, CodingKey {
        case status
        case phases
        case phaseSettings = "phase_settings" // Keep this as snake_case since it's used in API responses
    }
}

/// Thread recovery request
struct ThreadRecoveryRequest: APIRequest {
    typealias Response = ThreadRecoveryResponse

    let threadId: String
    var endpoint: String { "recover" }

    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id" // Keep this as snake_case since it's used in API requests
    }
}

/// Thread recovery response
struct ThreadRecoveryResponse: Decodable {
    let status: String
    let threadId: String
    let phaseStates: [String: String]?
    let currentPhase: String?
    let error: String?
    let messageCount: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case threadId = "thread_id" // Keep this as snake_case since it's used in API responses
        case phaseStates = "phase_states" // Keep this as snake_case since it's used in API responses
        case currentPhase = "current_phase" // Keep this as snake_case since it's used in API responses
        case error
        case messageCount = "message_count" // Keep this as snake_case since it's used in API responses
    }
}

/// Empty request for health checks
struct HealthCheckRequest: APIRequest {
    typealias Response = HealthCheckResponse
    var endpoint: String { "health" }
}

/// Health check response
struct HealthCheckResponse: Decodable {
    let status: String
    let message: String
}

// MARK: - Vector Models

/// Model for vector data returned from the API
struct VectorResult: Decodable {
    let id: String
    let content: String
    let vector: [Double]?
    let metadata: [String: Any]?
    let created_at: String?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case vector
        case metadata
        case created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        vector = try container.decodeIfPresent([Double].self, forKey: .vector)
        created_at = try container.decodeIfPresent(String.self, forKey: .created_at)

        // Decode metadata as AnyCodable and convert to [String: Any]
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
}

// MARK: - Streaming Event Models

/// Event received from Postchain streaming endpoint
struct PostchainEvent: Decodable {
    let phase: String
    let status: String
    let content: String?
    let provider: String?
    let modelName: String?
    let webResults: [SearchResult]?
    let vectorResults: [VectorSearchResult]?
    let error: String?
    let noveltyReward: RewardInfo?
    let maxSimilarity: Double?
    let citationReward: [String: Any]?
    let citationExplanations: [String: String]?

    enum CodingKeys: String, CodingKey {
        case phase
        case status
        case content
        case provider
        case modelName = "model_name" // Keep this as snake_case since it's used in API responses
        case webResults = "web_results" // Keep this as snake_case since it's used in API responses
        case vectorResults = "vector_results" // Keep this as snake_case since it's used in API responses
        case error
        case noveltyReward = "novelty_reward" // Keep this as snake_case since it's used in API responses
        case maxSimilarity = "max_similarity" // Keep this as snake_case since it's used in API responses
        case citationReward = "citation_reward" // Keep this as snake_case since it's used in API responses
        case citationExplanations = "citation_explanations" // Keep this as snake_case since it's used in API responses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        phase = try container.decode(String.self, forKey: .phase)
        status = try container.decode(String.self, forKey: .status)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)

        // Enhanced model name decoding with debug logging
        print("PostchainEvent - Available keys: \(container.allKeys.map { $0.stringValue })")

        // Try to decode model_name directly
        do {
            if container.contains(.modelName) {
                print("PostchainEvent - Found modelName key")
                modelName = try container.decodeIfPresent(String.self, forKey: .modelName)
                print("PostchainEvent - Decoded model name: \(modelName ?? "nil")")
            } else {
                print("PostchainEvent - modelName key not found")
                modelName = nil
            }
        } catch {
            print("PostchainEvent - Error decoding model_name: \(error)")
            modelName = nil
        }

        error = try container.decodeIfPresent(String.self, forKey: .error)

        // Decode novelty reward information
        do {
            if container.contains(.noveltyReward) {
                print("PostchainEvent - Found noveltyReward key")
                let rewardData = try container.decodeIfPresent(RewardInfo.self, forKey: .noveltyReward)
                noveltyReward = rewardData
                print("PostchainEvent - Decoded novelty reward: \(rewardData?.formattedAmount ?? "nil")")
            } else {
                noveltyReward = nil
            }
        } catch {
            print("PostchainEvent - Error decoding novelty_reward: \(error)")
            noveltyReward = nil
        }

        // Decode max similarity
        maxSimilarity = try container.decodeIfPresent(Double.self, forKey: .maxSimilarity)

        // Handle the cases where web/vector results might be in a different format
        do {
            webResults = try container.decodeIfPresent([SearchResult].self, forKey: .webResults)
        } catch {
            webResults = nil
        }

        // Attempt to decode vectorResults directly, handling potential errors
        do {
            vectorResults = try container.decodeIfPresent([VectorSearchResult].self, forKey: .vectorResults)
            if let vectors = vectorResults {
                 // Check if any vectors have content
                 let nonEmptyContent = vectors.filter { !$0.content.isEmpty }
                 if nonEmptyContent.isEmpty && vectors.count > 0 {
                 } else if vectors.count > 0 {
                 }
            } else {
                 // Explicitly check contains for logging comparison
                 if !container.contains(.vectorResults) {
                 } else {
                 }
            }
        } catch let decodingError as DecodingError {
             print("Decoding error: \(decodingError)")
             vectorResults = nil // Ensure it's nil on error
        } catch {
            vectorResults = nil // Ensure it's nil on error
        }

        // Decode citation reward
        do {
            if container.contains(.citationReward) {
                print("PostchainEvent - Found citationReward key")

                // Try to decode as AnyCodable and convert to [String: Any]
                if let citationRewardContainer = try? container.decodeIfPresent([String: AnyCodable].self, forKey: .citationReward) {
                    var convertedCitationReward: [String: Any] = [:]
                    for (key, value) in citationRewardContainer {
                        convertedCitationReward[key] = value.value
                    }
                    citationReward = convertedCitationReward
                    print("PostchainEvent - Decoded citation reward")
                } else {
                    citationReward = nil
                }
            } else {
                citationReward = nil
            }
        } catch {
            print("PostchainEvent - Error decoding citation_reward: \(error)")
            citationReward = nil
        }

        // Decode citation explanations
        do {
            if container.contains(.citationExplanations) {
                print("PostchainEvent - Found citationExplanations key")
                citationExplanations = try container.decodeIfPresent([String: String].self, forKey: .citationExplanations)
                print("PostchainEvent - Decoded citation explanations: \(citationExplanations?.count ?? 0) items")
            } else {
                citationExplanations = nil
            }
        } catch {
            print("PostchainEvent - Error decoding citation_explanations: \(error)")
            citationExplanations = nil
        }
    }
}

/// Event for message update
struct PostchainStreamEvent: Codable {
    let phase: String
    let status: String
    let content: String?
    let provider: String?
    let modelName: String?
    let webResults: [SearchResult]?
    let vectorResults: [VectorSearchResult]?
    let noveltyReward: RewardInfo?
    let maxSimilarity: Double?
    let citationReward: [String: Any]?
    let citationExplanations: [String: String]?

    init(phase: String, status: String = "complete", content: String? = nil, provider: String? = nil, modelName: String? = nil, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil, noveltyReward: RewardInfo? = nil, maxSimilarity: Double? = nil, citationReward: [String: Any]? = nil, citationExplanations: [String: String]? = nil) {
        self.phase = phase
        self.status = status
        self.content = content
        self.provider = provider
        self.modelName = modelName
        self.webResults = webResults
        self.vectorResults = vectorResults
        self.noveltyReward = noveltyReward
        self.maxSimilarity = maxSimilarity
        self.citationReward = citationReward
        self.citationExplanations = citationExplanations
    }

    enum CodingKeys: String, CodingKey {
        case phase, status, content, provider
        case modelName = "model_name" // Keep this as snake_case since it's used in API responses
        case webResults = "web_results" // Keep this as snake_case since it's used in API responses
        case vectorResults = "vector_results" // Keep this as snake_case since it's used in API responses
        case noveltyReward = "novelty_reward" // Keep this as snake_case since it's used in API responses
        case maxSimilarity = "max_similarity" // Keep this as snake_case since it's used in API responses
        case citationReward = "citation_reward" // Keep this as snake_case since it's used in API responses
        case citationExplanations = "citation_explanations" // Keep this as snake_case since it's used in API responses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        phase = try container.decode(String.self, forKey: .phase)
        status = try container.decode(String.self, forKey: .status)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)

        // Enhanced model name decoding with debug logging
        print("PostchainStreamEvent - Available keys: \(container.allKeys.map { $0.stringValue })")

        // Try to decode model_name directly
        do {
            if container.contains(.modelName) {
                print("PostchainStreamEvent - Found modelName key")
                modelName = try container.decodeIfPresent(String.self, forKey: .modelName)
                print("PostchainStreamEvent - Decoded model name: \(modelName ?? "nil")")
            } else {
                print("PostchainStreamEvent - modelName key not found")
                modelName = nil
            }
        } catch {
            print("PostchainStreamEvent - Error decoding model_name: \(error)")
            modelName = nil
        }

        // Handle the cases where web/vector results might be in a different format
        do {
            webResults = try container.decodeIfPresent([SearchResult].self, forKey: .webResults)
        } catch {
            webResults = nil
        }

        // Decode novelty reward information
        do {
            if container.contains(.noveltyReward) {
                print("PostchainStreamEvent - Found noveltyReward key")
                let rewardData = try container.decodeIfPresent(RewardInfo.self, forKey: .noveltyReward)
                noveltyReward = rewardData
                print("PostchainStreamEvent - Decoded novelty reward: \(rewardData?.formattedAmount ?? "nil")")
            } else {
                noveltyReward = nil
            }
        } catch {
            print("PostchainStreamEvent - Error decoding novelty_reward: \(error)")
            noveltyReward = nil
        }

        // Decode max similarity
        maxSimilarity = try container.decodeIfPresent(Double.self, forKey: .maxSimilarity)

        // Decode citation reward
        do {
            if container.contains(.citationReward) {
                print("PostchainStreamEvent - Found citationReward key")

                // Try to decode as AnyCodable and convert to [String: Any]
                if let citationRewardContainer = try? container.decodeIfPresent([String: AnyCodable].self, forKey: .citationReward) {
                    var convertedCitationReward: [String: Any] = [:]
                    for (key, value) in citationRewardContainer {
                        convertedCitationReward[key] = value.value
                    }
                    citationReward = convertedCitationReward
                    print("PostchainStreamEvent - Decoded citation reward")
                } else {
                    citationReward = nil
                }
            } else {
                citationReward = nil
            }
        } catch {
            print("PostchainStreamEvent - Error decoding citation_reward: \(error)")
            citationReward = nil
        }

        // Decode citation explanations
        do {
            if container.contains(.citationExplanations) {
                print("PostchainStreamEvent - Found citationExplanations key")
                citationExplanations = try container.decodeIfPresent([String: String].self, forKey: .citationExplanations)
                print("PostchainStreamEvent - Decoded citation explanations: \(citationExplanations?.count ?? 0) items")
            } else {
                citationExplanations = nil
            }
        } catch {
            print("PostchainStreamEvent - Error decoding citation_explanations: \(error)")
            citationExplanations = nil
        }

        do {
            // Add explicit check for vector_results
            if container.contains(.vectorResults) {

                // Try to decode as an array of VectorSearchResult
                vectorResults = try container.decodeIfPresent([VectorSearchResult].self, forKey: .vectorResults)

                // Log success if we get here
                if let vectors = vectorResults {

                    // Check if any vectors have content
                    let nonEmptyContent = vectors.filter { !$0.content.isEmpty }
                    if nonEmptyContent.isEmpty {
                    } else {
                    }
                } else {
                }
            } else {
                vectorResults = nil
            }
        } catch {
            vectorResults = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(phase, forKey: .phase)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(modelName, forKey: .modelName)
        try container.encodeIfPresent(webResults, forKey: .webResults)
        try container.encodeIfPresent(vectorResults, forKey: .vectorResults)
        try container.encodeIfPresent(noveltyReward, forKey: .noveltyReward)
        try container.encodeIfPresent(maxSimilarity, forKey: .maxSimilarity)

        // Handle citationReward ([String: Any]) by converting to [String: AnyCodable]
        if let citationReward = citationReward {
            var encodableCitationReward: [String: AnyCodable] = [:]
            for (key, value) in citationReward {
                encodableCitationReward[key] = AnyCodable(value)
            }
            try container.encodeIfPresent(encodableCitationReward, forKey: .citationReward)
        }

        // citationExplanations is already [String: String] which is Encodable
        try container.encodeIfPresent(citationExplanations, forKey: .citationExplanations)
    }
}
