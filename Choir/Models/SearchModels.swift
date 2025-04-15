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
    var content: String = ""
    let score: Double
    let metadata: [String: String]?
    let provider: String?
    var id: String?
    var content_preview: String?

    var uniqueId: String {
        if let id = id {
            return id
        }
        return "\(content.prefix(50))-\(score)"
    }

    enum CodingKeys: String, CodingKey {
        case content, score, metadata, provider, id, content_preview
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(score)
        hasher.combine(provider)
        hasher.combine(id)
    }

    init(content: String, score: Double, provider: String?, metadata: [String: String]? = nil, id: String? = nil, content_preview: String? = nil) {
        self.content = content
        self.score = score
        self.metadata = metadata
        self.provider = provider
        self.id = id
        self.content_preview = content_preview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode content, but don't fail if it's missing
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""

        // These fields are required
        score = try container.decode(Double.self, forKey: .score)

        // These fields are optional
        // Make metadata decoding more robust
        // Make metadata decoding more robust using AnyCodable
        if let anyMetadata = try? container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata) {
            metadata = anyMetadata.compactMapValues { $0.value as? String }
            if metadata?.count != anyMetadata.count {
                 print("⚠️ VECTOR METADATA: Some non-string values found in metadata dict for id \(id ?? "unknown")")
            }
        } else {
            metadata = nil // Explicitly nil if decoding fails or key is absent
        }
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        content_preview = try container.decodeIfPresent(String.self, forKey: .content_preview)

        // Handle the case where content is empty but content_preview is available
        if content.isEmpty && content_preview != nil {
            content = content_preview!
        }
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
