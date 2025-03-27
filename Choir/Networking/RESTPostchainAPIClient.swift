import Foundation
import SwiftUI

// MARK: - REST Postchain API Client
class RESTPostchainAPIClient {
    #if DEBUG
    private let baseURL = "http://localhost:8000/api/postchain"
    // private let baseURL = "https://choir-chat.onrender.com/api/postchain"
    #else
    private let baseURL = "https://choir-chat.onrender.com/api/postchain"
    #endif
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    var viewModel: PostchainViewModel?
    
    init(timeout: TimeInterval = 120) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        session = URLSession(configuration: config)
        
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
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
                throw APIError.serverError("Invalid response type")
            }
            
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 API Response: \(responseString)")
            }
            #endif
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
            }
            
            // Try to decode directly first
            do {
                return try decoder.decode(R.self, from: data)
            } catch {
                // If direct decoding fails, try wrapped response
                let apiResponse = try decoder.decode(APIResponse<R>.self, from: data)
                guard let responseData = apiResponse.data else {
                    throw APIError.invalidResponse("No data in response")
                }
                return responseData
            }
            
        } catch is URLError {
            throw APIError.timeout
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // Streaming POST request for langchain endpoint
    func streamLangchain(
        query: String,
        threadId: String,
        onPhaseUpdate: @escaping (String, String, String, [SearchResult]?, [VectorSearchResult]?) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/langchain") else {
            onError(APIError.invalidURL)
            return
        }
        
        // Create request body
        let requestBody = LangchainRequestBody(
            userQuery: query,
            threadId: threadId
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        do {
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            onError(APIError.decodingError(error))
            return
        }
        
        // Create a URLSession with a delegate
        let config = URLSessionConfiguration.default
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: delegateQueue)
        
        let task = session.dataTask(with: request)
        
        // Use a delegate with a reference to the onPhaseUpdate and onComplete callbacks
        let sseDelegate = SSEDelegate(
            dataTask: task,
            onEventReceived: { eventData in
                if eventData == "[DONE]" {
                    DispatchQueue.main.async {
                        onComplete()
                    }
                    return
                }
                
                do {
                    // Try to parse the JSON data
                    let jsonData = eventData.data(using: .utf8)!
                    
                    // Parse the event data
                    if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        let phase = json["phase"] as? String ?? ""
                        let status = json["status"] as? String ?? ""
                        let content = json["content"] as? String ?? ""
                        
                        // Parse web results if available
                        var webResults: [SearchResult]? = nil
                        if let webResultsJson = json["web_results"] as? [[String: Any]] {
                            webResults = webResultsJson.compactMap { resultJson in
                                guard let title = resultJson["title"] as? String,
                                      let url = resultJson["url"] as? String,
                                      let content = resultJson["content"] as? String else {
                                    return nil
                                }
                                
                                return SearchResult(
                                    title: title,
                                    url: url,
                                    content: content,
                                    provider: resultJson["provider"] as? String
                                )
                            }
                        }
                        
                        // Parse vector results if available
                        var vectorResults: [VectorSearchResult]? = nil
                        if let vectorResultsJson = json["vector_results"] as? [[String: Any]] {
                            vectorResults = vectorResultsJson.compactMap { resultJson in
                                guard let content = resultJson["content"] as? String,
                                      let score = resultJson["score"] as? Double else {
                                    return nil
                                }
                                
                                var metadata: [String: Any] = [:]
                                if let metadataJson = resultJson["metadata"] as? [String: Any] {
                                    metadata = metadataJson
                                }
                                
                                return VectorSearchResult(
                                    content: content,
                                    score: score,
                                    metadata: metadata,
                                    provider: resultJson["provider"] as? String
                                )
                            }
                        }
                        
                        // Handle final content for yield phase
                        if phase == "yield" && status == "complete" {
                            let finalContent = json["final_content"] as? String ?? content
                            
                            Task { @MainActor in
                                onPhaseUpdate(phase, status, finalContent, webResults, vectorResults)
                            }
                        } else {
                            Task { @MainActor in
                                onPhaseUpdate(phase, status, content, webResults, vectorResults)
                            }
                        }
                    } else {
                        // Fallback to original decoder if the manual approach fails
                        let event = try self.decoder.decode(PostchainLangchainEvent.self, from: jsonData)
                        
                        Task { @MainActor in
                            onPhaseUpdate(
                                event.phase,
                                event.status,
                                event.content ?? event.finalContent ?? "",
                                event.webResults,
                                event.vectorResults
                            )
                        }
                    }
                } catch {
                    Task { @MainActor in
                        onError(APIError.decodingError(error))
                    }
                }
            },
            onError: { error in
                Task { @MainActor in
                    onError(error)
                }
            }
        )
        
        // Keep a reference to the delegate
        URLSession.shared.delegateQueue.addOperation {
            task.delegate = sseDelegate
        }
        
        // Start the streaming task
        task.resume()
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
    
    enum CodingKeys: String, CodingKey {
        case userQuery = "user_query"
        case threadId = "thread_id"
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
    let content: String?
    let finalContent: String?
    let webResults: [SearchResult]?
    let vectorResults: [VectorSearchResult]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case phase
        case status
        case content
        case finalContent = "final_content"
        case webResults = "web_results"
        case vectorResults = "vector_results"
        case error
    }
}

// MARK: - Search Result Models
struct SearchResult: Codable {
    let title: String
    let url: String
    let content: String
    let provider: String?
}

struct VectorSearchResult: Codable {
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