import Foundation
import SwiftUI

// MARK: - Phase Enum
enum Phase: String, CaseIterable, Identifiable, Codable {
    case action
    case experienceVectors = "experience_vectors"
    case experienceWeb = "experience_web"
    case intention
    case observation
    case understanding
    case yield

    var id: String { rawValue }

    var description: String {
        switch self {
        case .action: return "Initial Response"
        case .experienceVectors: return "Finding Docs"
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

    static func from(_ string: String) -> Phase? {
        if let exact = Phase(rawValue: string) {
            return exact
        }
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

// MARK: - ModelConfig
struct ModelConfig: Codable, Equatable, Hashable {
    var provider: String
    var model: String
    var temperature: Double?
    var openaiApiKey: String?
    var anthropicApiKey: String?
    var googleApiKey: String?
    var mistralApiKey: String?
    var fireworksApiKey: String?
    var cohereApiKey: String?
    var openrouterApiKey: String?
    var groqApiKey: String?

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

    enum CodingKeys: String, CodingKey {
        case provider, model, temperature
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

// MARK: - Prior
struct Prior: Codable, Hashable {
    let id: String
    let content: String
    let similarity: Double
    let createdAt: String?
    let threadID: String?
    let role: String?
    let step: String?

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

// MARK: - PhaseResult
struct PhaseResult: Codable, Equatable, Hashable {
    var content: String
    var provider: String?
    var modelName: String?

    enum CodingKeys: String, CodingKey {
        case content, provider
        case modelName = "model_name"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(provider)
        hasher.combine(modelName)
    }
}

// MARK: - ChoirThread
class ChoirThread: ObservableObject, Identifiable, Hashable {
    let id: UUID
    @Published var title: String
    @Published var lastOpened: Date = Date()
    @Published var messages: [Message] = []

    init(id: UUID = UUID(), title: String? = nil) {
        self.id = id
        self.title = title ?? "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
    }

    static func == (lhs: ChoirThread, rhs: ChoirThread) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func updateTitle(_ newTitle: String) {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        objectWillChange.send()
        title = newTitle
        saveThread()
    }

    private func saveThread() {
        Task {
            await Task.detached {
                ThreadPersistenceService.shared.saveThread(self)
            }.value
        }
    }
}

// MARK: - Message
class Message: ObservableObject, Identifiable, Equatable {
    let id: UUID
    @Published var content: String
    let isUser: Bool
    let timestamp: Date
    @Published var isStreaming: Bool

    @Published var selectedPhase: Phase = .action
    @Published var phaseCurrentPage: [Phase: Int] = [:]
    @Published private var phaseResults: [Phase: PhaseResult] = [:]
    @Published var vectorSearchResults: [VectorSearchResult] = []
    @Published var webSearchResults: [SearchResult] = []

    var phases: [Phase: String] {
        get { phaseResults.mapValues { $0.content } }
        set {
            objectWillChange.send()
            for (phase, content) in newValue {
                let existing = phaseResults[phase]
                phaseResults[phase] = PhaseResult(content: content,
                                                  provider: existing?.provider,
                                                  modelName: existing?.modelName)
            }
        }
    }

    init(id: UUID = UUID(),
         content: String,
         isUser: Bool,
         timestamp: Date = Date(),
         phaseResults: [Phase: PhaseResult] = [:],
         isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.phaseResults = phaseResults

        for phase in Phase.allCases {
            if self.phaseResults[phase] == nil {
                self.phaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
            }
        }
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    func updatePhase(_ phase: Phase, content: String, provider: String?, modelName: String?, event: PostchainStreamEvent) {
        objectWillChange.send()
        phaseResults[phase] = PhaseResult(content: content, provider: provider, modelName: modelName)

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

        if phase == .experienceVectors {
            if let results = event.vectorResults, !results.isEmpty {
                self.vectorSearchResults = results
            }
        } else if phase == .experienceWeb {
            if let results = event.webResults, !results.isEmpty {
                self.webSearchResults = results
            }
        }
    }

    func getPhaseContent(_ phase: Phase) -> String {
        phaseResults[phase]?.content ?? ""
    }

    func getPhaseResult(_ phase: Phase) -> PhaseResult? {
        phaseResults[phase]
    }

    func currentPage(for phase: Phase) -> Int {
        phaseCurrentPage[phase, default: 0]
    }

    func setCurrentPage(for phase: Phase, page: Int) {
        let newPage = max(0, page)
        if phaseCurrentPage[phase, default: 0] != newPage {
            objectWillChange.send()
            phaseCurrentPage[phase] = newPage
        }
    }

    func clearPhases() {
        objectWillChange.send()
        phaseResults.removeAll()
        for phase in Phase.allCases {
            phaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
        }
    }
}


extension Message {
    // Function to format Vector Search Results into Markdown
    func formatVectorResultsToMarkdown() -> String {
        guard !vectorSearchResults.isEmpty else { return "" }

        var markdown = "\n\n---\n**Vector Search Results:**\n\n" // Separator and title
        for result in vectorSearchResults {
            markdown += "*   **Score: \(String(format: "%.2f", result.score))**"
            // Check for local thread link
            if let threadIDString = result.metadata?["thread_id"] as? String,
               let _ = UUID(uuidString: threadIDString) {
                 markdown += " [Local Thread](choir://thread/\(threadIDString))"
            }
            markdown += "\n    > \(result.content.replacingOccurrences(of: "\n", with: "\n    > "))" // Blockquote for content
            if let provider = result.provider {
                 markdown += "\n    *Provider: \(provider)*"
            }
            markdown += "\n"
        }
        markdown += "\n---\n" // Footer separator
        return markdown
    }

    // Function to format Web Search Results into Markdown
    func formatWebResultsToMarkdown() -> String {
        guard !webSearchResults.isEmpty else { return "" }

        var markdown = "\n\n---\n**Web Search Results:**\n\n" // Separator and title
        for result in webSearchResults {
            markdown += "*   **[\(result.title)](\(result.url))**" // Title as link
            markdown += "\n    > \(result.content.replacingOccurrences(of: "\n", with: "\n    > "))" // Blockquote for content
            if let provider = result.provider {
                 markdown += "\n    *Provider: \(provider)*"
            }
            markdown += "\n"
        }
         markdown += "\n---\n" // Footer separator
        return markdown
    }
}
