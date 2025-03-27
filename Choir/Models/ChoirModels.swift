import Foundation
import SwiftUI

// MARK: - Phase Enum
enum Phase: String, CaseIterable, Identifiable {
    case action
    case experience
    case intention
    case observation
    case understanding
    case yield

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

// MARK: - Thread and Message Models
class ChoirThread: ObservableObject, Identifiable, Hashable {
    let id: UUID
    let title: String
    @Published var messages: [Message] = []

    init(id: UUID = UUID(), title: String? = nil) {
        self.id = id
        self.title = title ?? "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
    }

    // Hashable conformance
    static func == (lhs: ChoirThread, rhs: ChoirThread) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class Message: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var content: String
    let isUser: Bool
    let timestamp: Date
    @Published var isStreaming: Bool

    // Store all phases with proper publishing
    @Published private var _phases: [Phase: String] = [:]

    // Public interface that always returns all phases (with empty strings for missing ones)
    var phases: [Phase: String] {
        get {
            // Start with empty phases for all possible values
            var result = Phase.allCases.reduce(into: [Phase: String]()) { result, phase in
                result[phase] = ""
            }

            // Overlay with any actual content we have
            result.merge(_phases) { _, new in new }

            return result
        }
        set {
            // Using @Published means we don't need to manually notify observers
            _phases = newValue
        }
    }

    init(id: UUID = UUID(),
         content: String,
         isUser: Bool,
         timestamp: Date = Date(),
         phases: [Phase: String] = [:],
         isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming

        // Initialize with all provided phases
        self._phases = phases
    }

    // Equatable conformance
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    // Add explicit objectWillChange notifications for phase updates
    func updatePhase(_ phase: Phase, content: String) {
        objectWillChange.send()
        
        // Store the phase content
        _phases[phase] = content

        // Force SwiftUI to recognize deep changes
        if !content.isEmpty {
            let temp = _phases
            _phases = [:]
            _phases = temp
        }

        // Only update the main content if it's empty or a placeholder
        // This prevents overwriting the main content with phase content from other messages
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
