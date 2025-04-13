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
    let finalContent: String?
    let provider: String?
    let modelName: String?
    let webResults: [SearchResult]?
    let vectorResults: [VectorSearchResult]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case phase
        case status
        case content
        case finalContent = "final_content"
        case provider
        case modelName = "model_name"
        case webResults = "web_results"
        case vectorResults = "vector_results"
        case error
    }
}

/// Event for message update
struct PostchainStreamEvent: Codable {
    let phase: String
    let status: String
    let content: String?
    let finalContent: String?
    let provider: String?
    let modelName: String?
    let webResults: [SearchResult]?
    let vectorResults: [VectorSearchResult]?
    
    init(phase: String, status: String = "complete", content: String? = nil, provider: String? = nil, modelName: String? = nil, webResults: [SearchResult]? = nil, vectorResults: [VectorSearchResult]? = nil, finalContent: String? = nil) {
        self.phase = phase
        self.status = status
        self.content = content
        self.provider = provider
        self.modelName = modelName
        self.webResults = webResults
        self.vectorResults = vectorResults
        self.finalContent = finalContent
    }
    
    enum CodingKeys: String, CodingKey {
        case phase, status, content, provider
        case modelName = "model_name"
        case finalContent = "final_content"
        case webResults = "web_results"
        case vectorResults = "vector_results"
    }
}