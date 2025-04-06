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
import Foundation
import SwiftUI

 // MARK: - Phase Enum
enum Phase: String, CaseIterable, Identifiable, Codable {
    case action
    case experience
    case intention
    case observation
    case understanding
    case yield

struct ThreadsAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: ThreadsData?
}

struct ThreadsData: Codable {
    let threads: [ThreadResponse]?
}
struct ThreadResponse: Codable, Identifiable {
    let id: String
    let name: String
    let created_at: String
    let user_id: String
    let co_authors: [String]
    let message_count: Int
    let last_activity: String
}
    var id: String { rawValue }

    var description: String {
        switch self {
        case .action: return "Initial Response"
        case .experience: return "Finding Context"
        case .intention: return "Analyzing Intent"
        case .observation: return "Observing Patterns"
        case .understanding: return "Checking Understanding"
        case .yield: return "Final Response"
        }
    }

    var symbol: String {
        switch self {
        case .action: return "bolt.fill"
        case .experience: return "brain.head.profile"
        case .intention: return "target"
        case .observation: return "eye.fill"
        case .understanding: return "checkmark.circle.fill"
        case .yield: return "arrow.down.circle.fill"
        }
    }

    // Smart mapping from any string to a Phase enum
    static func from(_ string: String) -> Phase? {
        // Exact match by rawValue
        if let exact = Phase.allCases.first(where: { $0.rawValue == string }) {
            return exact
        }

        // Description match
        if let byDescription = Phase.allCases.first(where: { $0.description == string }) {
            return byDescription
        }

        // Partial/fuzzy match (case insensitive)
        let lowercased = string.lowercased()
        return Phase.allCases.first { phase in
            lowercased.contains(phase.rawValue.lowercased())
        }
    }
}

extension Phase {
    var next: Phase? {
        guard let currentIndex = Phase.allCases.firstIndex(of: self),
              currentIndex + 1 < Phase.allCases.count else {
            return nil
        }
        return Phase.allCases[currentIndex + 1]
    }
}

// MARK: - Model Configuration
struct ModelConfig: Codable, Equatable, Hashable {
    let provider: String
    let model: String
    let temperature: Double?
    // Optional API Keys - passed from client
    let openaiApiKey: String?
    let anthropicApiKey: String?
    let googleApiKey: String?
    let mistralApiKey: String?
    let fireworksApiKey: String?
    let cohereApiKey: String?
    let openrouterApiKey: String?
    let groqApiKey: String?

    init(provider: String,
         model: String,
         temperature: Double? = nil,
         openaiApiKey: String? = nil,
         anthropicApiKey: String? = nil,
         googleApiKey: String? = nil,
         mistralApiKey: String? = nil,
         fireworksApiKey: String? = nil,
         cohereApiKey: String? = nil,
         openrouterApiKey: String? = nil,
         groqApiKey: String? = nil) {
        self.provider = provider
        self.model = model
        self.temperature = temperature
        self.openaiApiKey = openaiApiKey
        self.anthropicApiKey = anthropicApiKey
        self.googleApiKey = googleApiKey
        self.mistralApiKey = mistralApiKey
        self.fireworksApiKey = fireworksApiKey
        self.cohereApiKey = cohereApiKey
        self.openrouterApiKey = openrouterApiKey
        self.groqApiKey = groqApiKey
    }

    // Add CodingKeys for snake_case mapping with backend
    enum CodingKeys: String, CodingKey {
        case provider
        case model
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

// MARK: - Phase Result
struct PhaseResult: Codable, Equatable, Hashable {
    var content: String
    var provider: String?
    var modelName: String?

    // Add CodingKeys for snake_case mapping if needed, assuming backend sends model_name
    enum CodingKeys: String, CodingKey {
        case content
        case provider
        case modelName = "model_name"
    }
}

// MARK: - Thread and Message Models
class ChoirThread: ObservableObject, Identifiable, Hashable {
    let id: UUID
    let title: String
    @Published var messages: [Message] = []

    // Global model configurations (used for *new* messages)
    @Published var modelConfigs: [Phase: ModelConfig] = [
        .action: ModelConfig(provider: "google", model: "gemini-2.0-flash-lite"),
        .experience: ModelConfig(provider: "openrouter", model: "ai21/jamba-1.6-mini"),
        .intention: ModelConfig(provider: "google", model: "gemini-2.0-flash"),
        .observation: ModelConfig(provider: "groq", model: "qwen-qwq-32b"),
        .understanding: ModelConfig(provider: "openrouter", model: "openrouter/quasar-alpha"),
        .yield: ModelConfig(provider: "google", model: "gemini-2.5-pro-exp-03-25")
    ]

    init(id: UUID = UUID(), title: String? = nil, modelConfigs: [Phase: ModelConfig]? = nil) {
        self.id = id
        self.title = title ?? "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"

        // First check if there's a saved global configuration in UserDefaults
        let globalConfigKey = "globalActiveModelConfig"
        if let savedConfigData = UserDefaults.standard.data(forKey: globalConfigKey),
           let savedConfigs = try? JSONDecoder().decode([Phase: ModelConfig].self, from: savedConfigData) {
            self.modelConfigs = savedConfigs
            print("Loaded global model configuration during thread initialization")
        }
        // If configs were directly provided, use those (overrides UserDefaults)
        else if let configs = modelConfigs {
            self.modelConfigs = configs
        }
        // Otherwise use defaults (already set)
    }

    // Hashable conformance
    static func == (lhs: ChoirThread, rhs: ChoirThread) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Update a specific model configuration
    func updateModelConfig(for phase: Phase, provider: String, model: String, temperature: Double? = nil) {
        modelConfigs[phase] = ModelConfig(provider: provider, model: model, temperature: temperature)
    }
}

class Message: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var content: String
    let isUser: Bool
    let timestamp: Date
    @Published var isStreaming: Bool

    // Store the currently selected phase for this message
    // This ensures the selection persists even if the view is recreated
    @Published var selectedPhase: Phase = .action

    // Store the current page index (0-based) for each Phase
    @Published var phaseCurrentPage: [Phase: Int] = [:]

    // Each message stores results for each phase
    @Published private var phaseResults: [Phase: PhaseResult] = [:]

    // Public interface for compatibility (returns only content strings)
    // TODO: Update views to use phaseResults directly where possible
    var phases: [Phase: String] {
        get {
            phaseResults.mapValues { $0.content }
        }
        // Setter might need adjustment or removal depending on usage
        set {
            objectWillChange.send()
            for (phase, content) in newValue {
                // Update existing or create new PhaseResult, keeping existing provider/model if possible
                let existingResult = phaseResults[phase]
                phaseResults[phase] = PhaseResult(content: content,
                                                  provider: existingResult?.provider,
                                                  modelName: existingResult?.modelName)
            }
        }
    }

    init(id: UUID = UUID(),
         content: String,
         isUser: Bool,
         timestamp: Date = Date(),
         phaseResults: [Phase: PhaseResult] = [:], // Initialize with PhaseResult
         isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.phaseResults = phaseResults

        // Pre-initialize all phases with empty PhaseResult if not provided
        for phase in Phase.allCases {
            if self.phaseResults[phase] == nil {
                self.phaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
            }
        }
    }

    // Equatable conformance
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    // Update phase with content, provider, and model name
    func updatePhase(_ phase: Phase, content: String, provider: String?, modelName: String?) {
        objectWillChange.send() // Notify observers

        // Create or update the PhaseResult
        phaseResults[phase] = PhaseResult(content: content, provider: provider, modelName: modelName)

        // Update main content based on priority (Yield > Experience > Action)
        // Only update if current main content is empty or placeholder
        if self.content.isEmpty || self.content == "..." {
            // For initial content, prioritize yield > experience > action
            if phase == .yield && !content.isEmpty {
                self.content = content
            } else if phase == .experience && !content.isEmpty && (self.content.isEmpty || self.content == "...") {
                self.content = content
            } else if phase == .action && !content.isEmpty && (self.content.isEmpty || self.content == "...") {
                self.content = content
            }
        }

        print("Message \(id): Updated phase \(phase.rawValue) with content length: \(content.count)")
    }

    // Get phase content string for this specific message
    func getPhaseContent(_ phase: Phase) -> String {
        return phaseResults[phase]?.content ?? ""
    }

    // Get the full PhaseResult for a phase
    func getPhaseResult(_ phase: Phase) -> PhaseResult? {
        return phaseResults[phase]
    }

    // Get the current page for a given phase
    func currentPage(for phase: Phase) -> Int {
        // Return stored page or default to 0
        return phaseCurrentPage[phase, default: 0]
    }

    // Set the current page for a given phase
    func setCurrentPage(for phase: Phase, page: Int) {
        let newPage = max(0, page) // Ensure page index is not negative
        // Only update and notify if the value actually changes
        if phaseCurrentPage[phase, default: 0] != newPage {
            objectWillChange.send() // Explicitly notify observers before changing
            phaseCurrentPage[phase] = newPage
        }
    }

    // Clear all phases (for debugging/testing)
    func clearPhases() {
        objectWillChange.send()
        phaseResults.removeAll() // Use phaseResults

        // Pre-initialize all phases with empty PhaseResult
        for phase in Phase.allCases {
            phaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
        }
    }
}

// MARK: - Messages API Models
struct MessagesAPIResponse: Codable {
    let success: Bool
    let message: String?
    let data: MessagesData?
}

struct MessagesData: Codable {
    let messages: [MessageResponse]?
}

struct MessageResponse: Codable, Identifiable {
    let id: String
    let content: String?
    let threadId: String // Non-optional as per guide assumption
    let role: String? // Optional based on curl output
    let timestamp: String?
    let phaseOutputs: [String: String]? // Optional based on curl output
    // Include other fields if needed for future use, mark as optional
    let noveltyScore: Double?
    let similarityScores: [Double]? // Assuming array of doubles
    let citedPriorIds: [String]? // Assuming array of strings
    let metadata: [String: String]? // Assuming simple dictionary

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case threadId = "thread_id"
        case role
        case timestamp
        case phaseOutputs = "phase_outputs"
        case noveltyScore = "novelty_score"
        case similarityScores = "similarity_scores"
        case citedPriorIds = "cited_prior_ids"
        case metadata
    }
}

// MARK: - API Models
/// Simplified Prior model for display purposes only
struct Prior: Codable, Hashable {
    let id: String
    let content: String
    let similarity: Double
    let createdAt: String?
    let threadID: String?
    let role: String?
    let step: String?

    // For transition purposes only - this will be replaced with a better implementation
    // once the codebase is cleaned up
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

/// Base API response wrapper - kept for compatibility with some endpoints
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
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
    // Core fields for all events
    let currentPhase: String
    let phaseState: String
    let content: String

    // Optional fields
    let error: String?
    let metadata: [String: Any]?
    let threadId: String?

    // Use custom keys to accommodate snake_case from Python API
    enum CodingKeys: String, CodingKey {
        case currentPhase = "current_phase"
        case phaseState = "phase_state"
        case content
        case error
        case metadata
        case threadId = "thread_id"
    }
}

extension PostchainStreamEvent {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        currentPhase = try container.decode(String.self, forKey: .currentPhase)
        phaseState = try container.decode(String.self, forKey: .phaseState)
        content = try container.decode(String.self, forKey: .content)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        threadId = try container.decodeIfPresent(String.self, forKey: .threadId)

        // Handle metadata as a dynamic dictionary
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

        // Handle metadata encoding
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

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
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
            let context = EncodingError.Context(codingPath: container.codingPath,
                                                debugDescription: "AnyCodable cannot encode \(type(of: value))")
            throw EncodingError.invalidValue(value, context)
        }

    }
}
