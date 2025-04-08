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
    case experienceVectors = "experience_vectors" // Match backend string
    case experienceWeb = "experience_web"         // Match backend string
    case intention
    case observation
    case understanding
    case yield

    var id: String { rawValue }

    var description: String {
        switch self {
        case .action: return "Initial Response"
        case .experienceVectors: return "Finding Docs" // Shorter
        case .experienceWeb: return "Searching Web"
        case .intention: return "Analyzing Intent"
        case .observation: return "Observing Patterns"
        case .understanding: return "Checking Understanding"
        case .yield: return "Final Response"
        }
    }

    var symbol: String {
        switch self {
        case .action: return "bolt.fill"
        case .experienceVectors: return "doc.text.magnifyingglass"
        case .experienceWeb: return "network"
        case .intention: return "target"
        case .observation: return "eye.fill"
        case .understanding: return "checkmark.circle.fill"
        case .yield: return "arrow.down.circle.fill"
        }
    }

    // Smart mapping from any string to a Phase enum
    static func from(_ string: String) -> Phase? {
        // Exact match by rawValue (should handle snake_case from backend)
        if let exact = Phase(rawValue: string) {
            return exact
        }
        // Fallback for potentially non-raw value strings (e.g., description)
        return Phase.allCases.first { $0.description == string }
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

// MARK: - Search Result Models
struct SearchResult: Codable, Equatable, Hashable {
    let title: String
    let url: String
    let content: String
    let provider: String?

    // Add a unique ID for Hashable and Identifiable conformance
    var id: String {
        return url // URL is a good natural ID for web search results
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.title == rhs.title &&
               lhs.url == rhs.url &&
               lhs.content == rhs.content &&
               lhs.provider == rhs.provider
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(title)
    }
}

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

struct VectorSearchResult: Codable, Equatable, Hashable {
    let content: String
    let score: Double
    let metadata: [String: String]?
    let provider: String?

    // Add a unique ID property
    var uniqueId: String {
        // Create a stable ID from content and score
        return "\(content.prefix(50))-\(score)"
    }

    enum CodingKeys: String, CodingKey {
        case content
        case score
        case metadata
        case provider
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(provider)
        hasher.combine(modelName)
    }
}

// MARK: - Thread and Message Models
class ChoirThread: ObservableObject, Identifiable, Hashable {
    let id: UUID
    @Published var title: String
    @Published var messages: [Message] = []

    // Global model configurations (used for *new* messages)
    @Published var modelConfigs: [Phase: ModelConfig] = [
        .action: ModelConfig(provider: "google", model: "gemini-2.0-flash-lite"),
        .experienceVectors: ModelConfig(provider: "openrouter", model: "ai21/jamba-1.6-mini"),
        .experienceWeb: ModelConfig(provider: "openrouter", model: "openrouter/quasar-alpha"),
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
        
        // Save thread after updating model config
        saveThread()
    }
    
    // Update the thread title
    func updateTitle(_ newTitle: String) {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        objectWillChange.send()
        title = newTitle
        
        // Save thread after updating title
        saveThread()
    }
    
    // Save thread to persistent storage
    private func saveThread() {
        Task {
            await Task.detached {
                ThreadPersistenceService.shared.saveThread(self)
            }.value
        }
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

    // Store parsed search results for the new Experience phases
    @Published var vectorSearchResults: [VectorSearchResult] = []
    @Published var webSearchResults: [SearchResult] = []
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

    // Update phase with content, provider, and model name, plus the event for search results
    func updatePhase(_ phase: Phase, content: String, provider: String?, modelName: String?, event: PostchainStreamEvent) {
        objectWillChange.send() // Notify observers

        // Create or update the PhaseResult
        phaseResults[phase] = PhaseResult(content: content, provider: provider, modelName: modelName)

        // Update main content based on priority (Yield > ExpWeb > ExpVec > Action)
        // Only update if current main content is empty or placeholder, or we are streaming
        if self.content.isEmpty || self.content == "..." || self.isStreaming {
            if phase == .yield && !content.isEmpty {
                self.content = content
            } else if phase == .experienceWeb && !content.isEmpty {
                self.content = content
            } else if phase == .experienceVectors && !content.isEmpty {
                self.content = content
            } else if phase == .action && !content.isEmpty {
                self.content = content
            }
        }

        // Check for search results in the event and update message properties
        if phase == .experienceVectors {
             if let results = event.vectorResults, !results.isEmpty {
                 self.vectorSearchResults = results
                 print("Message \(id): Updated vectorSearchResults with \(results.count) items")
             }
         } else if phase == .experienceWeb {
              if let results = event.webResults, !results.isEmpty {
                  self.webSearchResults = results
                  print("Message \(id): Updated webSearchResults with \(results.count) items")
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

// MARK: - Phase Output Payloads (Parsed from PostchainStreamEvent metadata)

/// Represents the structured output specific to the Experience Vectors phase.
struct ExperienceVectorsOutput: Codable {
    let vectorResults: [VectorSearchResult]? // Matches backend "vector_results"

    enum CodingKeys: String, CodingKey {
        case vectorResults = "vector_results"
    }
}

/// Represents the structured output specific to the Experience Web phase.
struct ExperienceWebOutput: Codable {
    let webResults: [SearchResult]? // Matches backend "web_results"

    enum CodingKeys: String, CodingKey {
        case webResults = "web_results"
    }
}

/// Base API response wrapper - kept for compatibility with some endpoints
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

// MARK: - API Models
/// Simple request body for the PostChain API
struct PostchainRequestBody: Codable {
    let userQuery: String
    let threadID: String?
    let modelConfigs: [String: ModelConfig]? // Maps phase rawValue to config
    var stream: Bool = true // Default to true for streaming

    enum CodingKeys: String, CodingKey {
        case userQuery = "user_query"
        case threadID = "thread_id"
        case modelConfigs = "model_configs"
        case stream
    }
}

/// Represents a streaming event from the PostChain API (SSE data field)
struct PostchainStreamEvent: Codable {
    let phase: String
    let status: String // "running", "complete", "error"
    let content: String? // LLM response content for the phase
    let finalContent: String? // Only present in the final "yield" event
    let error: String?
    let provider: String?
    let modelName: String?

    // Dynamic payload for search results based on phase
    let vectorResults: [VectorSearchResult]?
    let webResults: [SearchResult]?

    enum CodingKeys: String, CodingKey {
        case phase
        case status
        case content
        case finalContent = "final_content"
        case error
        case provider
        case modelName = "model_name"
        case vectorResults = "vector_results" // Match backend key
        case webResults = "web_results"     // Match backend key
    }

    // Convenience initializer for creating an event with minimal information
    init(phase: String, status: String = "complete", content: String? = nil, provider: String? = nil, modelName: String? = nil) {
        self.phase = phase
        self.status = status
        self.content = content
        self.finalContent = nil
        self.error = nil
        self.provider = provider
        self.modelName = modelName
        self.vectorResults = nil
        self.webResults = nil
    }
}

/// Represents the structure of the non-streaming API response
struct PostchainSyncResponse: Codable {
    let threadId: String
    let phases: [String: PostchainStreamEvent] // Maps phase rawValue to its result

    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
        case phases
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
