import Foundation
import SwiftUI

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
    
    // Add explicit initializer for debugging
    init(content: String, provider: String? = nil, modelName: String? = nil) {
        self.content = content
        self.provider = provider
        self.modelName = modelName
        
        // Add debug output for empty content
        if content.isEmpty {
            print("⚠️ WARNING: Created PhaseResult with empty content")
        }
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
    @Published var phaseResults: [Phase: PhaseResult] = [:]
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

        // Print when a new message is created for debugging
        print("📊 NEW MESSAGE: Created message with ID \(id)")
        
        for phase in Phase.allCases {
            if self.phaseResults[phase] == nil {
                // For debugging - provide all non-user messages with test content
                // for all phases to see if the issue is with content rendering
                if !isUser {
                    self.phaseResults[phase] = PhaseResult(
                        content: "Test content for \(phase.rawValue) phase", 
                        provider: "test_provider", 
                        modelName: "test_model"
                    )
                    print("📊 TEST: Added test content to \(phase.rawValue) phase in new message \(id)")
                } else {
                    self.phaseResults[phase] = PhaseResult(content: "", provider: nil, modelName: nil)
                }
            }
        }
        
        // Verify all phases are initialized
        print("📊 NEW MESSAGE: Initialized phases: \(phaseResults.keys.map { $0.rawValue }.joined(separator: ", "))")
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    func updatePhase(_ phase: Phase, content: String, provider: String?, modelName: String?, event: PostchainStreamEvent, status: String = "running") {
        // Signal change before any modifications
        objectWillChange.send()
        
        // Debug output for monitoring
        print("📝 MESSAGE: Updating phase \(phase.rawValue) with content length: \(content.count), status: \(status)")
        
        // Always mark as streaming when we receive updates
        // This ensures UI reflects streaming state
        self.isStreaming = true
        
        // Only mark as not streaming when explicitly completed
        if status == "complete" {
            self.isStreaming = false
        }
        
        // Print additional debug info
        print("📝 MESSAGE: Streaming status: \(self.isStreaming ? "active" : "inactive")")
        
        // Detailed logging for ALL phases
        print("📊 PHASE MESSAGE (\(phase.rawValue)) UPDATE - START")
        print("📊 PHASE MESSAGE (\(phase.rawValue)): Content empty: \(content.isEmpty)")
        print("📊 PHASE MESSAGE (\(phase.rawValue)): Content length: \(content.count)")
        if !content.isEmpty {
            print("📊 PHASE MESSAGE (\(phase.rawValue)): Content first chars: \(content.prefix(50))")
        }
        
        // Check existing content
        if let existingPhase = phaseResults[phase] {
            print("📊 PHASE MESSAGE (\(phase.rawValue)): Existing content length: \(existingPhase.content.count)")
            print("📊 PHASE MESSAGE (\(phase.rawValue)): Existing content empty: \(existingPhase.content.isEmpty)")
            
            // For debugging, compare yield with action
            if phase == .yield {
                if let actionPhase = phaseResults[.action] {
                    print("📊 PHASE COMPARISON: Action content length: \(actionPhase.content.count)")
                    print("📊 PHASE COMPARISON: Action content empty: \(actionPhase.content.isEmpty)")
                }
            }
        } else {
            print("📊 PHASE MESSAGE (\(phase.rawValue)): No existing content")
        }
        print("📊 PHASE MESSAGE (\(phase.rawValue)) UPDATE - END")
        
        // Check if we have finalContent in the event
        if phase == .yield && event.finalContent != nil && !event.finalContent!.isEmpty {
            let finalContent = event.finalContent!
            print("📝 MESSAGE: Using finalContent for yield phase (length: \(finalContent.count))")
            phaseResults[phase] = PhaseResult(content: finalContent, provider: provider, modelName: modelName)
            
            // Use finalContent as the main content
            self.content = finalContent
            print("📝 MESSAGE: Updated main content with yield finalContent (length: \(finalContent.count))")
        } else {
            // Standard handling for normal content
            phaseResults[phase] = PhaseResult(content: content, provider: provider, modelName: modelName)
            
            // Update main content when we have actual content
            if !content.isEmpty {
                self.content = content
                print("📝 MESSAGE: Updated main content with \(phase.rawValue) content (length: \(content.count))")
            }
        }
        
        // Handle search results
        if phase == .experienceVectors {
            if let results = event.vectorResults {
                print("📝 MESSAGE: Updating vector results: \(results.count) items")
                self.vectorSearchResults = results
            }
        } else if phase == .experienceWeb {
            if let results = event.webResults {
                print("📝 MESSAGE: Updating web results: \(results.count) items")
                self.webSearchResults = results
            }
        }
        
        // Automatically update selected phase to show the user what's happening
        if status == "running" && !content.isEmpty {
            let shouldSwitch = self.selectedPhase != phase && 
                              (self.selectedPhase == .action || // Always switch from action
                               phase == .yield) // Always prefer yield when available
                              
            if shouldSwitch {
                print("📝 MESSAGE: Auto-switching view from \(self.selectedPhase.rawValue) to \(phase.rawValue)")
                self.selectedPhase = phase
            }
        }
        
        // Signal change again after modifications to ensure UI updates
        objectWillChange.send()
    }

    func getPhaseContent(_ phase: Phase) -> String {
        // Check for the phase in the phaseResults dictionary
        print("📊 GET CONTENT (\(phase.rawValue)): Looking up phase in phaseResults")
        print("📊 GET CONTENT (\(phase.rawValue)): Keys in phaseResults: \(phaseResults.keys.map { $0.rawValue }.joined(separator: ", "))")
        print("📊 GET CONTENT (\(phase.rawValue)): Phase exists in phaseResults: \(phaseResults[phase] != nil)")
        
        // Get the content and log details
        var content = phaseResults[phase]?.content ?? ""
        print("📊 GET CONTENT (\(phase.rawValue)): Retrieved content length: \(content.count)")
        print("📊 GET CONTENT (\(phase.rawValue)): Retrieved content is empty: \(content.isEmpty)")
        
        // SPECIAL HANDLING FOR YIELD PHASE
        // If yield phase is empty but other phases have content, use content from another phase
        if phase == .yield && content.isEmpty {
            print("📊 YIELD FALLBACK: Yield phase is empty, checking alternative content")
            
            // Try understanding phase first (often has the most comprehensive content)
            if let understandingContent = phaseResults[.understanding]?.content, !understandingContent.isEmpty {
                print("📊 YIELD FALLBACK: Using understanding content (length: \(understandingContent.count))")
                return understandingContent
            }
            
            // Then try action phase
            if let actionContent = phaseResults[.action]?.content, !actionContent.isEmpty {
                print("📊 YIELD FALLBACK: Using action content (length: \(actionContent.count))")
                return actionContent
            }
            
            // Try observation as another fallback
            if let observationContent = phaseResults[.observation]?.content, !observationContent.isEmpty {
                print("📊 YIELD FALLBACK: Using observation content (length: \(observationContent.count))")
                return observationContent
            }
            
            // As a last resort, concatenate all non-empty phase contents
            let allContent = Phase.allCases.compactMap { phase -> String? in
                let phaseContent = phaseResults[phase]?.content ?? ""
                return phaseContent.isEmpty ? nil : "## \(phase.description)\n\n\(phaseContent)"
            }.joined(separator: "\n\n---\n\n")
            
            if !allContent.isEmpty {
                print("📊 YIELD FALLBACK: Using concatenated content from all phases (length: \(allContent.count))")
                return allContent
            }
            
            print("📊 YIELD FALLBACK: No alternative content found, returning empty string")
        }
        
        return content
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
