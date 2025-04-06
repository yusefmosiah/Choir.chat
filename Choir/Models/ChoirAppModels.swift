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
        if let exact = Phase.allCases.first(where: { $0.rawValue == string }) { return exact }
        if let byDescription = Phase.allCases.first(where: { $0.description == string }) { return byDescription }
        let lowercased = string.lowercased()
        return Phase.allCases.first { phase in lowercased.contains(phase.rawValue.lowercased()) }
    }
}

extension Phase {
    var next: Phase? {
        guard let currentIndex = Phase.allCases.firstIndex(of: self),
              currentIndex + 1 < Phase.allCases.count else { return nil }
        return Phase.allCases[currentIndex + 1]
    }
}

// MARK: - Model Configuration
struct ModelConfig: Codable, Equatable, Hashable {
    let provider: String
    let model: String
    let temperature: Double?
    let openaiApiKey: String?
    let anthropicApiKey: String?
    let googleApiKey: String?
    let mistralApiKey: String?
    let fireworksApiKey: String?
    let cohereApiKey: String?
    let openrouterApiKey: String?
    let groqApiKey: String?

    init(provider: String, model: String, temperature: Double? = nil, openaiApiKey: String? = nil, anthropicApiKey: String? = nil, googleApiKey: String? = nil, mistralApiKey: String? = nil, fireworksApiKey: String? = nil, cohereApiKey: String? = nil, openrouterApiKey: String? = nil, groqApiKey: String? = nil) {
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

// MARK: - Phase Result
struct PhaseResult: Codable, Equatable, Hashable {
    var content: String
    var provider: String?
    var modelName: String?

    enum CodingKeys: String, CodingKey {
        case content, provider
        case modelName = "model_name"
    }
}

// MARK: - Thread and Message Models (UI Layer)
class ChoirThread: ObservableObject, Identifiable, Hashable {
    let id: UUID
    let title: String
    @Published var messages: [Message] = []

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
        let globalConfigKey = "globalActiveModelConfig"
        if let savedConfigData = UserDefaults.standard.data(forKey: globalConfigKey),
           let savedConfigs = try? JSONDecoder().decode([Phase: ModelConfig].self, from: savedConfigData) {
            self.modelConfigs = savedConfigs
            print("Loaded global model configuration during thread initialization")
        } else if let configs = modelConfigs {
            self.modelConfigs = configs
        }
    }

    static func == (lhs: ChoirThread, rhs: ChoirThread) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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
    @Published var selectedPhase: Phase = .action
    @Published var phaseCurrentPage: [Phase: Int] = [:]
    @Published private var phaseResults: [Phase: PhaseResult] = [:]

    var phases: [Phase: String] {
        get { phaseResults.mapValues { $0.content } }
        set {
            objectWillChange.send()
            for (phase, content) in newValue {
                let existingResult = phaseResults[phase]
                phaseResults[phase] = PhaseResult(content: content, provider: existingResult?.provider, modelName: existingResult?.modelName)
            }
        }
    }

    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), phaseResults: [Phase: PhaseResult] = [:], isStreaming: Bool = false) {
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

    static func == (lhs: Message, rhs: Message) -> Bool { lhs.id == rhs.id }

    func updatePhase(_ phase: Phase, content: String, provider: String?, modelName: String?) {
        objectWillChange.send()
        phaseResults[phase] = PhaseResult(content: content, provider: provider, modelName: modelName)
        if self.content.isEmpty || self.content == "..." {
            if phase == .yield && !content.isEmpty { self.content = content }
            else if phase == .experience && !content.isEmpty && (self.content.isEmpty || self.content == "...") { self.content = content }
            else if phase == .action && !content.isEmpty && (self.content.isEmpty || self.content == "...") { self.content = content }
        }
        print("Message \(id): Updated phase \(phase.rawValue) with content length: \(content.count)")
    }

    func getPhaseContent(_ phase: Phase) -> String { phaseResults[phase]?.content ?? "" }
    func getPhaseResult(_ phase: Phase) -> PhaseResult? { phaseResults[phase] }
    func currentPage(for phase: Phase) -> Int { phaseCurrentPage[phase, default: 0] }
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
