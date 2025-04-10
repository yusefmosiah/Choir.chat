import Foundation



import Foundation

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

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

struct PostchainRequestBody: Codable {
    let userQuery: String
    let threadID: String?
    let modelConfigs: [String: ModelConfig]?
    var stream: Bool = true

    enum CodingKeys: String, CodingKey {
        case userQuery = "user_query"
        case threadID = "thread_id"
        case modelConfigs = "model_configs"
        case stream
    }
}

struct PostchainStreamEvent: Codable {
    let phase: String
    let status: String
    let content: String?
    let finalContent: String?
    let provider: String?
    let modelName: String?
    let webResults: [SearchResult]?
    let vectorResults: [VectorSearchResult]?

    enum CodingKeys: String, CodingKey {
        case phase, status, content, provider, modelName, finalContent
        case webResults = "web_results"
        case vectorResults = "vector_results"
    }

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
}

struct PostchainSyncResponse: Codable {
    let success: Bool
    let message: String?
    let data: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case success, message, data
    }
}
