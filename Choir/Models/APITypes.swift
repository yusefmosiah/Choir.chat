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
        case userQuery = "user_query"
        case threadId = "thread_id"
        case modelConfigs = "model_configs"
        case stream
    }
}

/// Model configuration for requests
struct ModelConfigRequest: Codable {
    let provider: String
    let model_name: String
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
        case model_name
        case temperature
        case openaiApiKey = "openai_api_key"
        case anthropicApiKey = "anthropic_api_key"
        case googleApiKey = "google_api_key"
        case mistralApiKey = "mistral_api_key"
        case fireworksApiKey = "fireworks_api_key"
        case cohereApiKey = "cohere_api_key"
        case openrouterApiKey = "openrouter_api_key"
        case groqApiKey = "groq_api_key"
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
        case phaseSettings = "phase_settings"
    }
}

/// Thread recovery request
struct ThreadRecoveryRequest: APIRequest {
    typealias Response = ThreadRecoveryResponse

    let threadId: String
    var endpoint: String { "recover" }

    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
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
        case threadId = "thread_id"
        case phaseStates = "phase_states"
        case currentPhase = "current_phase"
        case error
        case messageCount = "message_count"
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

    enum CodingKeys: String, CodingKey {
        case phase
        case status
        case content
        case provider
        case modelName = "model_name"
        case webResults = "web_results"
        case vectorResults = "vector_results"
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        phase = try container.decode(String.self, forKey: .phase)
        status = try container.decode(String.self, forKey: .status)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        modelName = try container.decodeIfPresent(String.self, forKey: .modelName)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        // Handle the cases where web/vector results might be in a different format
        do {
            webResults = try container.decodeIfPresent([SearchResult].self, forKey: .webResults)
        } catch {
            print("⚠️ Failed to decode webResults as [SearchResult]: \(error)")
            webResults = nil
        }

        // Attempt to decode vectorResults directly, handling potential errors
        do {
            vectorResults = try container.decodeIfPresent([VectorSearchResult].self, forKey: .vectorResults)
            if let vectors = vectorResults {
                 print("🔴 VECTOR: Successfully decoded \(vectors.count) vector results using decodeIfPresent")
                 // Check if any vectors have content
                 let nonEmptyContent = vectors.filter { !$0.content.isEmpty }
                 if nonEmptyContent.isEmpty && vectors.count > 0 {
                     print("🔴 VECTOR: WARNING - All decoded vectors have empty content!")
                 } else if vectors.count > 0 {
                     print("🔴 VECTOR: \(nonEmptyContent.count) decoded vectors have non-empty content")
                 }
            } else {
                 print("🔴 VECTOR: decodeIfPresent returned nil for vector_results (key might be missing or value is null)")
                 // Explicitly check contains for logging comparison
                 if !container.contains(.vectorResults) {
                     print("🔴 VECTOR: Confirmed: container.contains also returns false.")
                 } else {
                     print("🔴 VECTOR: Anomaly: container.contains returns true, but decodeIfPresent returned nil. JSON value might be null.")
                 }
            }
        } catch let decodingError as DecodingError {
             print("🔴 VECTOR: DecodingError while decoding vectorResults: \(decodingError)")
             // Log detailed context for the decoding error
             switch decodingError {
                case .typeMismatch(let type, let context):
                    print("   Type '\(type)' mismatch:", context.debugDescription)
                    print("   codingPath:", context.codingPath.map { $0.stringValue })
                case .valueNotFound(let type, let context):
                    print("   Value '\(type)' not found:", context.debugDescription)
                    print("   codingPath:", context.codingPath.map { $0.stringValue })
                case .keyNotFound(let key, let context):
                    print("   Key '\(key)' not found:", context.debugDescription)
                    print("   codingPath:", context.codingPath.map { $0.stringValue })
                case .dataCorrupted(let context):
                    print("   Data corrupted:", context.debugDescription)
                    print("   codingPath:", context.codingPath.map { $0.stringValue })
                @unknown default:
                    print("   Other decoding error: \(decodingError)")
             }
             vectorResults = nil // Ensure it's nil on error
        } catch {
            print("🔴 VECTOR: Unexpected error while decoding vectorResults: \(error)")
            vectorResults = nil // Ensure it's nil on error
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

    init(phase: String, status: String = "complete", content: String? = nil, provider: String? = nil, modelName: String? = nil, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil) {
        self.phase = phase
        self.status = status
        self.content = content
        self.provider = provider
        self.modelName = modelName
        self.webResults = webResults
        self.vectorResults = vectorResults
    }

    enum CodingKeys: String, CodingKey {
        case phase, status, content, provider
        case modelName = "model_name"
        case webResults = "web_results"
        case vectorResults = "vector_results"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        phase = try container.decode(String.self, forKey: .phase)
        status = try container.decode(String.self, forKey: .status)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        modelName = try container.decodeIfPresent(String.self, forKey: .modelName)

        // Handle the cases where web/vector results might be in a different format
        do {
            webResults = try container.decodeIfPresent([SearchResult].self, forKey: .webResults)
        } catch {
            print("⚠️ Failed to decode webResults as [SearchResult]: \(error)")
            webResults = nil
        }

        do {
            // Add explicit check for vector_results
            if container.contains(.vectorResults) {
                print("🔴 VECTOR STREAM: Found vector_results key in response")

                // Try to decode as an array of VectorSearchResult
                vectorResults = try container.decodeIfPresent([VectorSearchResult].self, forKey: .vectorResults)

                // Log success if we get here
                if let vectors = vectorResults {
                    print("🔴 VECTOR STREAM: Successfully decoded \(vectors.count) vector results")

                    // Check if any vectors have content
                    let nonEmptyContent = vectors.filter { !$0.content.isEmpty }
                    if nonEmptyContent.isEmpty {
                        print("🔴 VECTOR STREAM: WARNING - All vectors have empty content!")
                    } else {
                        print("🔴 VECTOR STREAM: \(nonEmptyContent.count) vectors have non-empty content")
                    }
                } else {
                    print("🔴 VECTOR STREAM: No vector results after successful decoding")
                }
            } else {
                print("🔴 VECTOR STREAM: vector_results key NOT found in response")
                vectorResults = nil
            }
        } catch {
            print("⚠️ Failed to decode vectorResults as [VectorSearchResult]: \(error)")
            print("🔴 VECTOR STREAM: Unable to parse raw vector data")
            vectorResults = nil
        }
    }
}
