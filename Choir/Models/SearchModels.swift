import Foundation

// MARK: - SearchResult
struct SearchResult: Codable, Equatable, Hashable {
    let title: String
    let url: String
    let content: String
    let provider: String?

    var id: String {
        url
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.title == rhs.title &&
        lhs.url == rhs.url &&
        lhs.content == rhs.content &&
        lhs.provider == rhs.provider
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(title)
    }
}

// MARK: - VectorSearchResult
struct VectorSearchResult: Codable, Equatable, Hashable {
    let content: String
    let score: Double
    let metadata: [String: String]?
    let provider: String?

    var uniqueId: String {
        "\(content.prefix(50))-\(score)"
    }

    enum CodingKeys: String, CodingKey {
        case content, score, metadata, provider
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(score)
        hasher.combine(provider)
    }

    init(content: String, score: Double, provider: String?, metadata: [String: String]? = nil) {
        self.content = content
        self.score = score
        self.metadata = metadata
        self.provider = provider
    }
}

// MARK: - ExperienceVectorsOutput
struct ExperienceVectorsOutput: Codable {
    let vectorResults: [VectorSearchResult]?

    enum CodingKeys: String, CodingKey {
        case vectorResults = "vector_results"
    }
}

// MARK: - ExperienceWebOutput
struct ExperienceWebOutput: Codable {
    let webResults: [SearchResult]?

    enum CodingKeys: String, CodingKey {
        case webResults = "web_results"
    }
}
