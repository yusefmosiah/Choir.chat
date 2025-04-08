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
    }
    
    // MARK: - Public Methods
    
    /// Save a thread to a file
    /// - Parameter thread: The thread to save
    /// - Returns: Success or failure
    @discardableResult
    func saveThread(_ thread: ChoirThread) -> Bool {
        do {
            // Create a serializable representation of the thread
            let threadData = ThreadData(from: thread)
            
            // Encode the thread data
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(threadData)
            
            // Create a file URL for this thread
            let fileURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
            
            // Write the data to the file
            try data.write(to: fileURL)
            
            print("Thread saved to: \(fileURL.path)")
            return true
        } catch {
            print("Error saving thread: \(error)")
            return false
        }
    }
    
    /// Load a thread from a file
    /// - Parameter threadId: The UUID of the thread to load
    /// - Returns: The loaded thread, or nil if loading failed
    func loadThread(threadId: UUID) -> ChoirThread? {
        let fileURL = threadsDirectory.appendingPathComponent("\(threadId.uuidString).json")
        
        do {
            // Read the data from the file
            let data = try Data(contentsOf: fileURL)
            
            // Decode the thread data
            let decoder = JSONDecoder()
            let threadData = try decoder.decode(ThreadData.self, from: data)
            
            // Create a thread from the data
            return threadData.toChoirThread()
        } catch {
            print("Error loading thread: \(error)")
            return nil
        }
    }
    
    /// Load all threads from the threads directory
    /// - Returns: Array of loaded threads
    func loadAllThreads() -> [ChoirThread] {
        do {
            // Get all JSON files in the threads directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: threadsDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            // Load each thread
            var threads: [ChoirThread] = []
            for fileURL in fileURLs {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    let threadData = try decoder.decode(ThreadData.self, from: data)
                    threads.append(threadData.toChoirThread())
                } catch {
                    print("Error loading thread from \(fileURL.lastPathComponent): \(error)")
                }
            }
            
            return threads
        } catch {
            print("Error loading threads: \(error)")
            return []
        }
    }
    
    /// Delete a thread file
    /// - Parameter threadId: The UUID of the thread to delete
    /// - Returns: Success or failure
    @discardableResult
    func deleteThread(threadId: UUID) -> Bool {
        let fileURL = threadsDirectory.appendingPathComponent("\(threadId.uuidString).json")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting thread: \(error)")
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
    let modelConfigs: [String: ModelConfigData]
    
    init(from thread: ChoirThread) {
        self.id = thread.id.uuidString
        self.title = thread.title
        self.messages = thread.messages.map { MessageData(from: $0) }
        
        // Convert Phase enum keys to strings for serialization
        var configsDict: [String: ModelConfigData] = [:]
        for (phase, config) in thread.modelConfigs {
            configsDict[phase.rawValue] = ModelConfigData(from: config)
        }
        self.modelConfigs = configsDict
    }
    
    func toChoirThread() -> ChoirThread {
        // Create a UUID from the string
        let threadId = UUID(uuidString: id) ?? UUID()
        
        // Create a new thread
        let thread = ChoirThread(id: threadId, title: title)
        
        // Convert string keys back to Phase enum
        var phaseConfigs: [Phase: ModelConfig] = [:]
        for (phaseString, configData) in modelConfigs {
            if let phase = Phase(rawValue: phaseString) {
                phaseConfigs[phase] = configData.toModelConfig()
            }
        }
        thread.modelConfigs = phaseConfigs
        
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
    
    init(from phaseResult: PhaseResult) {
        self.content = phaseResult.content
        self.provider = phaseResult.provider
        self.modelName = phaseResult.modelName
    }
    
    func toPhaseResult() -> PhaseResult {
        return PhaseResult(
            content: content,
            provider: provider,
            modelName: modelName
        )
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


