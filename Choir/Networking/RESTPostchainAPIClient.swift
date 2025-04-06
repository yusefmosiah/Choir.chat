import Foundation
import SwiftUI

// MARK: - REST Postchain API Client
class RESTPostchainAPIClient {
    #if DEBUG && targetEnvironment(simulator)
    // Use localhost for simulator
    private let baseURL = "http://localhost:8000/api/postchain"
    #else
    // Use public URL for physical devices and release builds
    private let baseURL = "https://choir-chat.onrender.com/api/postchain"
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Removed viewModel property to simplify scope issues for now
    // var viewModel: PostchainViewModel?

    init(timeout: TimeInterval = 120) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        #if DEBUG
        print("📱 RESTPostchainAPIClient initialized with baseURL: \(baseURL)")
        #if targetEnvironment(simulator)
        print("📱 Running in simulator")
        #else
        print("📱 Running on device")
        #endif
        #endif
    }

    // Regular POST request for non-streaming endpoints
    func post<T: Codable, R: Codable>(endpoint: String, body: T) async throws -> R {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError(statusCode: 0)
            }

            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 API Response: \(responseString)")
            }
            #endif

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }

            // Try to decode directly first
            do {
                return try decoder.decode(R.self, from: data)
            } catch {
                // If direct decoding fails, try wrapped response
                let apiResponse = try decoder.decode(APIResponse<R>.self, from: data)
                guard let responseData = apiResponse.data else {
                    throw APIError.invalidResponse
                }
                return responseData
            }

        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch let error as DecodingError {
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error)
        }
    }

    // Streaming POST request for langchain endpoint
    func streamLangchain(
        query: String,
        threadId: String,
        recentHistory: [MessageHistoryItem], // Added recent history parameter
        modelConfigs: [Phase: ModelConfig]? = nil,
        onPhaseUpdate: @escaping (String, String, String, String?, String?) -> Void, // Simplified: phase, status, content, provider, modelName
        onTurnComplete: @escaping (TurnData) -> Void, // NEW: Callback for final turn data
        onComplete: @escaping () -> Void, // Keep for stream end signal
        onError: @escaping (Error) -> Void
    ) {
        #if DEBUG
        print("📱 RESTPostchainAPIClient.streamLangchain called with query: \(query.prefix(20))..., threadId: \(threadId)")
        if let configs = modelConfigs {
            print("📱 Using custom model configs: \(configs.count) phases configured")
        }
        #endif

        guard let url = URL(string: "\(baseURL)/langchain") else {
            print("❌ Invalid URL: \(baseURL)/langchain")
            onError(APIError.invalidURL)
            return
        }

        // Convert model configs if provided
        var modelConfigsDict: [String: ModelConfigRequest]?
        if let configs = modelConfigs {
            modelConfigsDict = [:]
            for (phase, config) in configs {
                modelConfigsDict![phase.rawValue] = ModelConfigRequest(from: config)
            }
        }

        // Create request body
        let requestBody = LangchainRequestBody(
            userQuery: query,
            threadId: threadId,
            recentHistory: recentHistory, // Pass recent history
            modelConfigs: modelConfigsDict
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            onError(APIError.decodingError)
            return
        }

        // Create a URLSession with a delegate
        let config = URLSessionConfiguration.default
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1

        // Create the custom delegate first
        class CustomSSEDelegate: NSObject, URLSessionDataDelegate, SSEDelegate {
            private let eventHandler: (String) -> Void
            private let errorHandler: (Error) -> Void
            private var buffer = ""

            init(onEventReceived: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
                self.eventHandler = onEventReceived
                self.errorHandler = onError
                super.init()
            }

            // SSEDelegate protocol methods
            func didReceiveEvent(_ event: ServerSentEvent) {
                if let data = event.data {
                    eventHandler(data)
                }
            }

            func didReceiveError(_ error: APIError) {
                errorHandler(error)
            }

            // URLSessionDataDelegate methods
            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
                if let text = String(data: data, encoding: .utf8) {
                    buffer += text

                    // Process any complete events in the buffer
                    while let eventEndIndex = buffer.range(of: "\n\n")?.upperBound {
                        let eventString = String(buffer[..<eventEndIndex])
                        buffer.removeSubrange(..<eventEndIndex)

                        // Parse SSE format
                        var id: String?
                        var event: String?
                        var data: String?
                        var retry: Int?

                        for line in eventString.split(separator: "\n") {
                            if line.starts(with: "id:") {
                                id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                            } else if line.starts(with: "event:") {
                                event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                            } else if line.starts(with: "data:") {
                                data = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                            } else if line.starts(with: "retry:") {
                                retry = Int(String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces))
                            }
                        }

                        let serverEvent = ServerSentEvent(id: id, event: event, data: data, retry: retry)
                        didReceiveEvent(serverEvent)
                    }
                }
            }

            func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                if let error = error {
                    didReceiveError(.networkError(error))
                }
            }
        }

        let sseDelegate = CustomSSEDelegate(
            onEventReceived: { eventData in
                // Check for stream end marker first
                if eventData == "[DONE]" {
                     DispatchQueue.main.async {
                         onComplete() // Signal stream finished
                     }
                    return
                }

                do {
                    // Try to parse the JSON data
                    guard let jsonData = eventData.data(using: .utf8) else {
                        Task { @MainActor in
                            onError(APIError.invalidEventData)
                        }
                        return
                    }

                    // Parse the event data
                    // Decode the generic JSON event
                    let event = try self.decoder.decode(PostchainLangchainEvent.self, from: jsonData)

                    // Check if this is the final completion event containing turn_data
                    if event.phase == "complete" && event.status == "complete", let turnData = event.turnData {
                         Task { @MainActor in
                             onTurnComplete(turnData) // Call the new callback
                         }
                    } else if event.phase != "complete" { // Process regular phase updates
                         Task { @MainActor in
                             // Call the simplified onPhaseUpdate
                             onPhaseUpdate(
                                 event.phase,
                                 event.status,
                                 event.content ?? "", // Use content, ignore finalContent here
                                 event.provider,
                                 event.modelName
                                 // Removed webResults, vectorResults from this callback
                             )
                         }
                    }
                    // Ignore the "complete" event if it doesn't have turn_data (shouldn't happen with new backend)
                } catch {
                    Task { @MainActor in
                        onError(APIError.decodingError)
                    }
                }
            },
            onError: { error in
                Task { @MainActor in
                    onError(error)
                }
            }
        )

        // Create a session with the delegate
        let session = URLSession(configuration: config, delegate: sseDelegate, delegateQueue: delegateQueue)

        // Create and start the task
        let task = session.dataTask(with: request)

        #if DEBUG
        print("📱 Starting URLSession task for \(baseURL)/langchain")
        #endif

        task.resume()

        #if DEBUG
        print("📱 URLSession task resumed")
        #endif
    }

    // Recover thread state
    func recoverThread(threadId: String) async throws -> ThreadRecoveryResponse {
        let requestBody = RecoverThreadRequest(threadId: threadId)
        return try await post(endpoint: "recover", body: requestBody)
    }

    // Health check
    func healthCheck() async throws -> HealthCheckResponse {
        return try await post(endpoint: "health", body: EmptyRequest())
    }
}

// MARK: - Request/Response Models
struct LangchainRequestBody: Codable {
    let userQuery: String
    let threadId: String
    let recentHistory: [MessageHistoryItem] // Added
    let modelConfigs: [String: ModelConfigRequest]?

    enum CodingKeys: String, CodingKey {
        case userQuery = "user_query"
        case threadId = "thread_id"
        case recentHistory = "recent_history" // Added
        case modelConfigs = "model_configs"
    }
}

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
        // Copy API keys
        self.openaiApiKey = modelConfig.openaiApiKey
        self.anthropicApiKey = modelConfig.anthropicApiKey
        self.googleApiKey = modelConfig.googleApiKey
        self.mistralApiKey = modelConfig.mistralApiKey
        self.fireworksApiKey = modelConfig.fireworksApiKey
        self.cohereApiKey = modelConfig.cohereApiKey
        self.openrouterApiKey = modelConfig.openrouterApiKey
        self.groqApiKey = modelConfig.groqApiKey
    }

    // Add CodingKeys for snake_case mapping with backend
    enum CodingKeys: String, CodingKey {
        case provider
        case model_name // Keep snake_case for backend compatibility
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

struct RecoverThreadRequest: Codable {
    let threadId: String

    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
    }
}

struct EmptyRequest: Codable {}

struct HealthCheckResponse: Codable {
    let status: String
    let message: String
}

struct ThreadRecoveryResponse: Codable {
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

// MARK: - Event Models
struct PostchainLangchainEvent: Codable {
    let phase: String
    let status: String
    let content: String? // For phase updates
    // let finalContent: String? // Replaced by turnData
    let provider: String?
    let modelName: String?
    // let webResults: [SearchResult]? // Included within TurnData now
    // let vectorResults: [VectorSearchResult]? // Included within TurnData now
    let turnData: TurnData? // NEW: For the final completion event
    let error: String?

    enum CodingKeys: String, CodingKey {
        case phase
        case status
        case content
        // case finalContent = "final_content" // Replaced by turnData
        case provider
        case modelName = "model_name"
        // case webResults = "web_results"
        // case vectorResults = "vector_results"
        case turnData = "turn_data" // NEW: Key for final turn data
        case error
    }
}

// MARK: - Search Result Models
struct SearchResult: Codable, Equatable {
    let title: String
    let url: String
    let content: String
    let provider: String?

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.title == rhs.title &&
               lhs.url == rhs.url &&
               lhs.content == rhs.content &&
               lhs.provider == rhs.provider
    }
}

struct VectorSearchResult: Codable, Equatable {
    let content: String
    let score: Double
    let metadata: [String: Any]
    let provider: String?

    enum CodingKeys: String, CodingKey {
        case content
        case score
        case metadata
        case provider
    }

    init(content: String, score: Double, metadata: [String: Any], provider: String?) {
        self.content = content
        self.score = score
        self.metadata = metadata
        self.provider = provider
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        content = try container.decode(String.self, forKey: .content)
        score = try container.decode(Double.self, forKey: .score)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)

        // Handle metadata as a dynamic dictionary
        if let metadataContainer = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
            var convertedMetadata: [String: Any] = [:]
            for (key, value) in metadataContainer {
                convertedMetadata[key] = value.value
            }
            metadata = convertedMetadata
        } else {
            metadata = [:]
        }
    }

    static func == (lhs: VectorSearchResult, rhs: VectorSearchResult) -> Bool {
        // Note: metadata is of type [String: Any] which doesn't conform to Equatable
        // Only comparing content, score and provider for equality
        return lhs.content == rhs.content &&
               lhs.score == rhs.score &&
               lhs.provider == rhs.provider
        // metadata is excluded from comparison as [String: Any] doesn't conform to Equatable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(content, forKey: .content)
        try container.encode(score, forKey: .score)
        try container.encodeIfPresent(provider, forKey: .provider)

        // Handle metadata encoding
        var encodableMetadata: [String: AnyCodable] = [:]
        for (key, value) in metadata {
            encodableMetadata[key] = AnyCodable(value)
        }
        try container.encode(encodableMetadata, forKey: .metadata)
    }
}
