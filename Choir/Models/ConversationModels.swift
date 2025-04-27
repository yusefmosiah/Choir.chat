import Foundation
import SwiftUI
import UIKit

// Import for PostchainStreamEvent
// This ensures we can use the type from APITypes

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
        case openaiApiKey = "openai_api_key" // Keep this as snake_case since it's used in API requests
        case anthropicApiKey = "anthropic_api_key" // Keep this as snake_case since it's used in API requests
        case googleApiKey = "google_api_key" // Keep this as snake_case since it's used in API requests
        case mistralApiKey = "mistral_api_key" // Keep this as snake_case since it's used in API requests
        case fireworksApiKey = "fireworks_api_key" // Keep this as snake_case since it's used in API requests
        case cohereApiKey = "cohere_api_key" // Keep this as snake_case since it's used in API requests
        case openrouterApiKey = "openrouter_api_key" // Keep this as snake_case since it's used in API requests
        case groqApiKey = "groq_api_key" // Keep this as snake_case since it's used in API requests
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
        case modelName = "model_name" // Keep this as snake_case since it's used in API responses
    }

    // Add explicit initializer for debugging
    init(content: String, provider: String? = nil, modelName: String? = nil) {
        self.content = content
        self.provider = provider
        self.modelName = modelName

        // Add debug output for PhaseResult creation
        print("PhaseResult.init - Content length: \(content.count)")
        print("  Provider: \(provider ?? "nil")")
        print("  ModelName: \(modelName ?? "nil")")
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
    @Published var createdAt: Date
    @Published var lastModified: Date
    @Published var walletAddress: String?
    @Published var messages: [Message] = []

    init(id: UUID = UUID(), title: String? = nil, walletAddress: String? = nil) {
        self.id = id
        self.title = title ?? "ChoirThread \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
        self.createdAt = Date()
        self.lastModified = Date()
        self.walletAddress = walletAddress
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
        // Update the last modified date
        self.lastModified = Date()

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

    @Published var selectedPhase: Phase = .action {
        didSet {
            // When the selected phase changes, dismiss the keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    @Published var phaseCurrentPage: [Phase: Int] = [:]
    @Published var phaseResults: [Phase: PhaseResult] = [:]
    @Published var vectorSearchResults: [VectorSearchResult] = []
    @Published var webSearchResults: [SearchResult] = []
    @Published var noveltyReward: RewardInfo?
    @Published var citationReward: [String: Any]?
    @Published var citationExplanations: [String: String]?
    @Published var maxSimilarity: Double?

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


    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    func updatePhase(_ phase: Phase, content: String, provider: String?, modelName: String?, event: PostchainStreamEvent, status: String = "running") {
        // Signal change before any modifications
        objectWillChange.send()

        // Debug output for monitoring
        print("Message.updatePhase - Phase: \(phase.rawValue), Status: \(status)")
        print("  Provider: \(provider ?? "nil")")
        print("  ModelName: \(modelName ?? "nil")")

        // Enhanced logging for model information

        // Add debugging for vector results - check what we're getting in the event
        if let vectorResults = event.vectorResults {
            if !vectorResults.isEmpty {
            }
        } else {
        }

        // Handle novelty reward information
        if phase == .experienceVectors {
            if let reward = event.noveltyReward {
                print("  Received novelty reward: \(reward.formattedAmount) CHOIR")
                self.noveltyReward = reward
            }

            if let similarity = event.maxSimilarity {
                print("  Received max similarity: \(similarity)")
                self.maxSimilarity = similarity
            }
        }

        // Always mark as streaming when we receive updates
        // This ensures UI reflects streaming state
        self.isStreaming = true

        // Only mark as not streaming when explicitly completed
        if status == "complete" {
            self.isStreaming = false
        }

        // Print additional debug info

        // Detailed logging for ALL phases
        if !content.isEmpty {
        }

        // Check existing content
        if let existingPhase = phaseResults[phase] {

            // For debugging, compare yield with action
            if phase == .yield {
                if let actionPhase = phaseResults[.action] {
                }
            }
        } else {
        }

        // Enhanced debug logging for yield phase
        if phase == .yield {
            // DEBUG LOG: Add specific logging for Message update
            print("  Updating YIELD phase")

            // Standard handling for yield phase (same as other phases)
            if !content.isEmpty {
                // Create PhaseResult with explicit provider and modelName
                let result = PhaseResult(content: content, provider: provider, modelName: modelName)
                print("  Created PhaseResult with provider: \(result.provider ?? "nil"), modelName: \(result.modelName ?? "nil")")
                phaseResults[phase] = result

                // Update main content with yield content
                self.content = content
            } else {
                // Create PhaseResult with explicit provider and modelName
                let result = PhaseResult(content: "", provider: provider, modelName: modelName)
                print("  Created empty PhaseResult with provider: \(result.provider ?? "nil"), modelName: \(result.modelName ?? "nil")")
                phaseResults[phase] = result
            }

            // DEBUG LOG: Log content after update
            print("  After update - provider: \(phaseResults[phase]?.provider ?? "nil"), modelName: \(phaseResults[phase]?.modelName ?? "nil")")
        } else {
            // Standard handling for normal content
            // Create PhaseResult with explicit provider and modelName
            let result = PhaseResult(content: content, provider: provider, modelName: modelName)
            print("  Created PhaseResult for \(phase.rawValue) with provider: \(result.provider ?? "nil"), modelName: \(result.modelName ?? "nil")")
            phaseResults[phase] = result

            // Update main content when we have actual content
            if !content.isEmpty {
                self.content = content
            }
        }

        // Handle search results
        if phase == .experienceVectors {
            if let results = event.vectorResults {

                // Enhanced debug info about incoming vector results

                for (index, result) in results.enumerated() {
                }

                // Actually store the results
                self.vectorSearchResults = results

                // IMPORTANT: Since vector results typically come with the Experience Vectors phase,
                // But might be referenced in ANY phase, we need to store this information more prominently
                if !results.isEmpty {
                } else {
                }
            } else {
            }
        }
        // Even if we're in another phase, if we receive vector results, we should store them
        // This could happen if results from experienceVectors are attached to other phase events
        else if let results = event.vectorResults, !results.isEmpty {

            // Enhanced debug info for non-experienceVectors phase
            for (index, result) in results.enumerated() {
            }

            // Store the results
            self.vectorSearchResults = results
        }

        // Handle web search results
        if phase == .experienceWeb {
            if let results = event.webResults {
                self.webSearchResults = results
            }
        }

        // Handle citation rewards and explanations in yield phase
        if phase == .yield {
            // Handle citation reward
            if let reward = event.citationReward {
                self.citationReward = reward
            }

            // Handle citation explanations
            if let explanations = event.citationExplanations {
                self.citationExplanations = explanations
            }
        }

        // Automatically update selected phase to show the user what's happening
        if status == "running" && !content.isEmpty {
            let shouldSwitch = self.selectedPhase != phase &&
                              (self.selectedPhase == .action) // Only switch from action, don't special-case yield

            if shouldSwitch {
                self.selectedPhase = phase
            }
        }

        // Signal change again after modifications to ensure UI updates
        objectWillChange.send()
    }

    func getPhaseContent(_ phase: Phase) -> String {
        // Check for the phase in the phaseResults dictionary

        // Get the content and log details
        let content = phaseResults[phase]?.content ?? ""

        // NOTE: Vector reference conversion (#123 -> links) is now handled in PaginatedMarkdownView
        return content
    }

    func getPhaseResult(_ phase: Phase) -> PhaseResult? {
        let result = phaseResults[phase]
        if let result = result {
        }
        return result
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
        var markdown = ""

        // Add novelty reward information if available
        if let reward = noveltyReward, reward.success {
            markdown += "\n\n---\n**Novelty Reward:**\n\n"
            markdown += "🎁 You earned **\(reward.formattedAmount) CHOIR** for your novel prompt!\n"

            if let similarity = maxSimilarity {
                let noveltyScore = 1.0 - similarity
                markdown += "Novelty score: **\(String(format: "%.2f", noveltyScore))** (similarity: \(String(format: "%.2f", similarity)))\n"
            }

            markdown += "\n---\n"
        } else if let similarity = maxSimilarity {
            // Show similarity even if no reward was issued
            markdown += "\n\n---\n**Prompt Similarity:**\n\n"
            let noveltyScore = 1.0 - similarity
            markdown += "Novelty score: **\(String(format: "%.2f", noveltyScore))** (similarity: \(String(format: "%.2f", similarity)))\n"
            markdown += "\n---\n"
        }

        // Add vector search results if available
        guard !vectorSearchResults.isEmpty else { return markdown }

        markdown += "\n\n---\n**Vector Search Results:**\n\n" // Separator and title
        for result in vectorSearchResults {
            markdown += "*   **Score: \(String(format: "%.2f", result.score))**"

            // Check for local thread link
            if let threadIDString = result.metadata?["thread_id"] as? String,
               let _ = UUID(uuidString: threadIDString) {
                 markdown += " [Local Thread](choir://thread/\(threadIDString))"
            }

            // Handle both content formats - full content or preview content
            let contentText: String
            if !result.content.isEmpty {
                contentText = result.content
            } else if let id = result.id {
                contentText = "[Vector Result ID: \(id)]"
            } else {
                contentText = "[Vector Result]"
            }

            markdown += "\n    > \(contentText.replacingOccurrences(of: "\n", with: "\n    > "))" // Blockquote for content

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
            // Make sure we have title and URL
            let titleText = !result.title.isEmpty ? result.title : "Web Result"
            let urlText = !result.url.isEmpty ? result.url : "#"

            // Format title as link
            markdown += "*   **[\(titleText)](\(urlText))**"

            // Handle content
            let contentText = !result.content.isEmpty ? result.content : "[Content not available]"
            markdown += "\n    > \(contentText.replacingOccurrences(of: "\n", with: "\n    > "))" // Blockquote for content

            if let provider = result.provider {
                 markdown += "\n    *Provider: \(provider)*"
            }
            markdown += "\n"
        }
        markdown += "\n---\n" // Footer separator
        return markdown
    }
}
