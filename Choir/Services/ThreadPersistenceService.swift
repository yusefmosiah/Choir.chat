import Foundation

/// Service responsible for persisting and loading threads from the file system
class ThreadPersistenceService {
    // MARK: - Properties

    /// Shared instance for singleton access
    static let shared = ThreadPersistenceService()

    /// Directory where thread files are stored
    private let threadsDirectory: URL

    // MARK: - Initialization

    private init() {
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        // Create a subdirectory for threads
        threadsDirectory = documentsDirectory.appendingPathComponent("threads", isDirectory: true)

        // Create the directory if it doesn't exist
        try? FileManager.default.createDirectory(at: threadsDirectory, withIntermediateDirectories: true)

        // Create a default directory for threads not associated with any wallet
        let defaultDir = threadsDirectory.appendingPathComponent("default", isDirectory: true)
        try? FileManager.default.createDirectory(at: defaultDir, withIntermediateDirectories: true)
    }

    // Get the directory for a specific wallet
    private func walletDirectory(for walletAddress: String?) -> URL {
        if let walletAddress = walletAddress {
            let walletDir = threadsDirectory.appendingPathComponent(walletAddress, isDirectory: true)
            try? FileManager.default.createDirectory(at: walletDir, withIntermediateDirectories: true)
            return walletDir
        } else {
            // For threads not associated with any wallet (legacy or device-only)
            let defaultDir = threadsDirectory.appendingPathComponent("default", isDirectory: true)
            try? FileManager.default.createDirectory(at: defaultDir, withIntermediateDirectories: true)
            return defaultDir
        }
    }

    // Get file URL for a thread
    private func fileURL(for threadId: UUID, walletAddress: String?) -> URL {
        return walletDirectory(for: walletAddress).appendingPathComponent("\(threadId.uuidString).json")
    }

    // MARK: - Public Methods

    /// Save a thread to a file
    /// - Parameter thread: The thread to save
    /// - Returns: Success or failure
    @discardableResult
    func saveThread(_ thread: ChoirThread) -> Bool {
        do {
            // Debug print
            print("Saving thread \(thread.id) with wallet address: \(thread.walletAddress ?? "nil")")

            // Create a serializable representation of the thread
            let threadData = ThreadData(from: thread)

            // Encode the thread data
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(threadData)

            // Create a file URL for this thread in the appropriate wallet directory
            let fileURL = self.fileURL(for: thread.id, walletAddress: thread.walletAddress)
            print("Saving to file: \(fileURL.path)")

            // Write the data to the file
            try data.write(to: fileURL)

            return true
        } catch {
            print("Error saving thread: \(error)")
            return false
        }
    }

    /// Load a thread from a file
    /// - Parameter threadId: The UUID of the thread to load
    /// - Returns: The loaded thread, or nil if loading failed
    func loadThread(threadId: UUID, walletAddress: String? = nil) -> ChoirThread? {
        // If wallet address is provided, try to load from that wallet's directory
        if let walletAddress = walletAddress {
            let fileURL = self.fileURL(for: threadId, walletAddress: walletAddress)

            if let thread = loadThreadFromFile(fileURL) {
                return thread
            }
        } else {
            // Try to find the thread in any wallet directory
            do {
                // First check the default directory
                let defaultFileURL = self.fileURL(for: threadId, walletAddress: nil)
                if let thread = loadThreadFromFile(defaultFileURL) {
                    return thread
                }

                // Then check all wallet directories
                let walletDirs = try FileManager.default.contentsOfDirectory(at: threadsDirectory, includingPropertiesForKeys: nil)
                    .filter { $0.hasDirectoryPath && $0.lastPathComponent != "default" }

                for walletDir in walletDirs {
                    let walletAddress = walletDir.lastPathComponent
                    let fileURL = walletDir.appendingPathComponent("\(threadId.uuidString).json")

                    if let thread = loadThreadFromFile(fileURL) {
                        // Set the wallet address on the thread
                        thread.walletAddress = walletAddress
                        return thread
                    }
                }
            } catch {
                print("Error searching for thread: \(error)")
            }
        }

        return nil
    }

    private func loadThreadFromFile(_ fileURL: URL) -> ChoirThread? {
        do {
            // Read the data from the file
            let data = try Data(contentsOf: fileURL)

            // Decode the thread data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let threadData = try decoder.decode(ThreadData.self, from: data)

            // Create a thread from the data
            return threadData.toChoirThread()
        } catch {
            return nil
        }
    }

    /// Load all threads from the threads directory
    /// - Returns: Array of loaded threads
    func loadAllThreads(walletAddress: String? = nil) -> [ChoirThread] {
        do {
            print("Loading threads for wallet address: \(walletAddress ?? "all")")

            if let walletAddress = walletAddress {
                // Load threads for a specific wallet
                let walletDir = walletDirectory(for: walletAddress)
                print("Loading from wallet directory: \(walletDir.path)")
                let threads = try loadThreadsFromDirectory(walletDir, walletAddress: walletAddress)
                print("Found \(threads.count) threads for wallet \(walletAddress)")
                return threads
            } else {
                // Load all threads from all wallets
                var allThreads: [ChoirThread] = []

                // First load threads from the default directory
                let defaultDir = walletDirectory(for: nil)
                print("Loading from default directory: \(defaultDir.path)")
                let defaultThreads = try loadThreadsFromDirectory(defaultDir, walletAddress: nil)
                print("Found \(defaultThreads.count) threads in default directory")
                allThreads.append(contentsOf: defaultThreads)

                // Then load threads from each wallet directory
                let walletDirs = try FileManager.default.contentsOfDirectory(at: threadsDirectory, includingPropertiesForKeys: nil)
                    .filter { $0.hasDirectoryPath && $0.lastPathComponent != "default" }

                print("Found \(walletDirs.count) wallet directories")
                for walletDir in walletDirs {
                    let walletAddress = walletDir.lastPathComponent
                    print("Loading from wallet directory: \(walletDir.path)")
                    let walletThreads = try loadThreadsFromDirectory(walletDir, walletAddress: walletAddress)
                    print("Found \(walletThreads.count) threads for wallet \(walletAddress)")
                    allThreads.append(contentsOf: walletThreads)
                }

                print("Total threads loaded: \(allThreads.count)")
                return allThreads
            }
        } catch {
            print("Error loading threads: \(error)")
            return []
        }
    }

    private func loadThreadsFromDirectory(_ directory: URL, walletAddress: String?) -> [ChoirThread] {
        do {
            // Get all JSON files in the directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }

            // Load each thread
            var threads: [ChoirThread] = []
            for fileURL in fileURLs {
                if let thread = loadThreadFromFile(fileURL) {
                    // Set the wallet address on the thread
                    thread.walletAddress = walletAddress
                    threads.append(thread)
                }
            }

            return threads
        } catch {
            print("Error loading threads from directory: \(error)")
            return []
        }
    }

    /// Delete a thread file
    /// - Parameter threadId: The UUID of the thread to delete
    /// - Returns: Success or failure
    @discardableResult
    func deleteThread(threadId: UUID, walletAddress: String? = nil) -> Bool {
        if let walletAddress = walletAddress {
            // Delete from the specific wallet directory
            let fileURL = self.fileURL(for: threadId, walletAddress: walletAddress)

            do {
                try FileManager.default.removeItem(at: fileURL)
                return true
            } catch {
                print("Error deleting thread: \(error)")
                return false
            }
        } else {
            // Try to find and delete the thread from any wallet directory
            if let thread = loadThread(threadId: threadId) {
                return deleteThread(threadId: threadId, walletAddress: thread.walletAddress)
            }
            return false
        }
    }
}

// MARK: - Serializable Data Models

/// Serializable representation of a ChoirThread
struct ThreadData: Codable {
    let id: String
    let title: String
    let messages: [MessageData]
    let walletAddress: String?
    let createdAt: Date
    let lastModified: Date

    init(from thread: ChoirThread) {
        self.id = thread.id.uuidString
        self.title = thread.title
        self.messages = thread.messages.map { MessageData(from: $0) }
        self.walletAddress = thread.walletAddress
        self.createdAt = thread.createdAt
        self.lastModified = thread.lastModified
    }

    func toChoirThread() -> ChoirThread {
        // Create a UUID from the string
        let threadId = UUID(uuidString: id) ?? UUID()

        // Create a new thread
        let thread = ChoirThread(id: threadId, title: title, walletAddress: walletAddress)

        // Set dates
        thread.createdAt = createdAt
        thread.lastModified = lastModified

        // Add messages
        thread.messages = messages.map { $0.toMessage() }

        return thread
    }
}

/// Serializable representation of a Message
struct MessageData: Codable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    let phaseResults: [String: PhaseResultData]
    let selectedPhase: String
    let phaseCurrentPage: [String: Int]
    let vectorSearchResults: [VectorSearchResult]
    let webSearchResults: [SearchResult]

    init(from message: Message) {
        self.id = message.id.uuidString
        self.content = message.content
        self.isUser = message.isUser
        self.timestamp = message.timestamp
        self.selectedPhase = message.selectedPhase.rawValue

        // Convert phase enum keys to strings
        var resultsDict: [String: PhaseResultData] = [:]
        for phase in Phase.allCases {
            if let result = message.getPhaseResult(phase) {
                resultsDict[phase.rawValue] = PhaseResultData(from: result)
            }
        }
        self.phaseResults = resultsDict

        // Convert phase enum keys to strings for current page
        var pagesDict: [String: Int] = [:]
        for phase in Phase.allCases {
            pagesDict[phase.rawValue] = message.currentPage(for: phase)
        }
        self.phaseCurrentPage = pagesDict

        // Copy search results
        self.vectorSearchResults = message.vectorSearchResults
        self.webSearchResults = message.webSearchResults
    }

    func toMessage() -> Message {
        // Create a UUID from the string
        let messageId = UUID(uuidString: id) ?? UUID()

        // Create a new message
        let message = Message(
            id: messageId,
            content: content,
            isUser: isUser,
            timestamp: timestamp
        )

        // Set the selected phase
        if let phase = Phase(rawValue: selectedPhase) {
            message.selectedPhase = phase
        }

        // Set phase results
        for (phaseString, resultData) in phaseResults {
            if let phase = Phase(rawValue: phaseString) {
                let result = resultData.toPhaseResult()
                message.updatePhase(
                    phase,
                    content: result.content,
                    provider: result.provider,
                    modelName: result.modelName,
                    event: PostchainStreamEvent(phase: phaseString, status: "complete", content: result.content)
                )
            }
        }

        // Set current page for each phase
        for (phaseString, page) in phaseCurrentPage {
            if let phase = Phase(rawValue: phaseString) {
                message.setCurrentPage(for: phase, page: page)
            }
        }

        // Set search results
        message.vectorSearchResults = vectorSearchResults
        message.webSearchResults = webSearchResults

        return message
    }
}

/// Serializable representation of a PhaseResult
struct PhaseResultData: Codable {
    let content: String
    let provider: String?
    let modelName: String?

    enum CodingKeys: String, CodingKey {
        case content, provider
        case modelName = "model_name" // Keep this as snake_case since it's used in API responses
    }

    init(from phaseResult: PhaseResult) {
        self.content = phaseResult.content
        self.provider = phaseResult.provider
        self.modelName = phaseResult.modelName

        // Debug logging
        print("PhaseResultData.init - Content length: \(content.count)")
        print("  Provider: \(provider ?? "nil")")
        print("  ModelName: \(modelName ?? "nil")")
    }

    func toPhaseResult() -> PhaseResult {
        print("PhaseResultData.toPhaseResult - Converting to PhaseResult")
        print("  Provider: \(provider ?? "nil")")
        print("  ModelName: \(modelName ?? "nil")")

        let result = PhaseResult(
            content: content,
            provider: provider,
            modelName: modelName
        )

        print("  Created PhaseResult with provider: \(result.provider ?? "nil"), modelName: \(result.modelName ?? "nil")")
        return result
    }
}

/// Serializable representation of a ModelConfig
struct ModelConfigData: Codable {
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

    init(from modelConfig: ModelConfig) {
        self.provider = modelConfig.provider
        self.model = modelConfig.model
        self.temperature = modelConfig.temperature
        self.openaiApiKey = modelConfig.openaiApiKey
        self.anthropicApiKey = modelConfig.anthropicApiKey
        self.googleApiKey = modelConfig.googleApiKey
        self.mistralApiKey = modelConfig.mistralApiKey
        self.fireworksApiKey = modelConfig.fireworksApiKey
        self.cohereApiKey = modelConfig.cohereApiKey
        self.openrouterApiKey = modelConfig.openrouterApiKey
        self.groqApiKey = modelConfig.groqApiKey
    }

    func toModelConfig() -> ModelConfig {
        return ModelConfig(
            provider: provider,
            model: model,
            temperature: temperature,
            openaiApiKey: openaiApiKey,
            anthropicApiKey: anthropicApiKey,
            googleApiKey: googleApiKey,
            mistralApiKey: mistralApiKey,
            fireworksApiKey: fireworksApiKey,
            cohereApiKey: cohereApiKey,
            openrouterApiKey: openrouterApiKey,
            groqApiKey: groqApiKey
        )
    }
}
