import Foundation

/// Main client for interacting with the Postchain API
/// Provides both synchronous endpoints and streaming capabilities
actor PostchainAPIClient {
    // MARK: - Configuration
    
    #if DEBUG && targetEnvironment(simulator)
    // Use localhost for simulator
    private let baseURL = "http://localhost:8000/api/postchain"
    #else
    // Use production URL for physical devices and release builds
    private let baseURL = "https://choir-chat.onrender.com/api/postchain"
    #endif
    
    // Encoding/decoding
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // Long input handling limits
    private let warningInputLength = 50000
    private let maxInputLength = 5000000 // 5M chars should be enough for most use cases
    
    // MARK: - Initialization
    
    init() {
        // Initialize encoder with snake_case conversion
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Initialize decoder with camel case conversion
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        #if DEBUG
        print("📱 PostchainAPIClient initialized with baseURL: \(baseURL)")
        #endif
    }
    
    // MARK: - API Requests
    
    /// Sends a request to the API and returns the decoded response
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: Decoded response of the specified type
    /// - Throws: APIError if the request fails
    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        // Build URL from base and endpoint
        guard let url = URL(string: "\(baseURL)/\(request.endpoint)") else {
            throw APIError.invalidURL
        }
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeoutInterval
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw APIError.encodingError
        }
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Attempt to decode the response
        do {
            // Try direct decoding first
            return try decoder.decode(R.Response.self, from: data)
        } catch {
            // If that fails, try unwrapping from APIResponse
            do {
                let apiResponse = try decoder.decode(APIResponse<R.Response>.self, from: data)
                
                if let responseData = apiResponse.data {
                    return responseData
                } else if !apiResponse.success {
                    throw APIError.serverError(
                        statusCode: httpResponse.statusCode,
                        message: apiResponse.message
                    )
                } else {
                    throw APIError.decodingError(context: "Missing data field in successful response")
                }
            } catch {
                // If both attempts fail, throw a more specific error
                throw APIError.decodingError(context: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Streaming API
    
    /// Streams events from the Postchain API
    /// - Parameters:
    ///   - query: User query to process
    ///   - threadId: ID of the thread to use
    ///   - modelConfigs: Optional model configurations
    /// - Returns: An async sequence of PostchainEvent objects
    /// - Throws: APIError if the stream cannot be established
    func streamPostchain(
        query: String,
        threadId: String,
        modelConfigs: [Phase: ModelConfig]? = nil
    ) async throws -> AsyncStream<PostchainEvent> {
        // Validate input length
        if query.count > maxInputLength {
            throw APIError.inputTooLarge(length: query.count, maxAllowed: maxInputLength)
        }
        
        // Log if input is large but still processable
        if query.count > warningInputLength {
            print("⚠️ Processing large input (\(query.count) characters)")
        }
        
        // Get URL for the streaming endpoint
        guard let url = URL(string: "\(baseURL)/langchain") else {
            throw APIError.invalidURL
        }
        
        // Convert model configs if provided
        var modelConfigsDict: [String: ModelConfigRequest]?
        if let configs = modelConfigs {
            modelConfigsDict = [:]
            for (phase, config) in configs {
                modelConfigsDict![phase.rawValue] = ModelConfigRequest(from: config)
            }
        }
        
        // Create request body
        let requestBody = PostchainRequest(
            userQuery: query,
            threadId: threadId,
            modelConfigs: modelConfigsDict,
            stream: true
        )
        
        // Encode request body - done inside actor to avoid concurrent mutation issues
        let encodedData: Data
        do {
            encodedData = try encoder.encode(requestBody)
        } catch {
            throw APIError.encodingError
        }
        
        // Prepare HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encodedData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        // Create an AsyncStream to return events as they are received
        return AsyncStream { continuation in
            Task {
                print("📡 STREAM: Starting direct URLSession stream")
                print("📡 STREAM: URL: \(url.absoluteString)")
                print("📡 STREAM: Body length: \(encodedData.count) bytes")
                
                do {
                    // Use URLSession directly for streaming
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    // Check response
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("📡 STREAM: Invalid response type")
                        continuation.finish()
                        return
                    }
                    
                    print("📡 STREAM: Received HTTP response: \(httpResponse.statusCode)")
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("📡 STREAM: HTTP error: \(httpResponse.statusCode)")
                        continuation.finish()
                        return
                    }
                    
                    print("📡 STREAM: Connection established successfully")
                    
                    // Setup buffer for SSE parsing
                    var buffer = ""
                    
                    // Process bytes as they arrive
                    for try await byte in asyncBytes {
                        // Add byte to buffer
                        if let char = String(bytes: [byte], encoding: .utf8) {
                            buffer.append(char)
                        }
                        
                        // Check for event delimiter (double newline)
                        if buffer.contains("\n\n") {
                            print("📡 STREAM: Found event delimiter")
                            
                            // Split buffer on double newlines
                            let events = buffer.components(separatedBy: "\n\n")
                            
                            // Process all complete events
                            for i in 0..<events.count-1 {
                                let event = events[i]
                                print("📡 STREAM: Processing event: \(event.prefix(50))...")
                                
                                // SSE format: lines starting with "data: " contain the JSON payload
                                if let dataLine = event.split(separator: "\n").first(where: { $0.hasPrefix("data:") }) {
                                    // Extract JSON data
                                    let jsonString = String(dataLine.dropFirst(5).trimmingCharacters(in: .whitespaces))
                                    print("📡 STREAM: Extracted JSON: \(jsonString.prefix(50))...")
                                    
                                    if jsonString == "[DONE]" {
                                        print("📡 STREAM: Received [DONE] marker")
                                        continuation.finish()
                                        return
                                    }
                                    
                                    // More detailed logging for raw JSON data
                                    if jsonString.contains("\"phase\":\"yield\"") {
                                        print("📊 YIELD RAW JSON: \(jsonString)")
                                        print("📊 YIELD: Checking if final_content exists: \(jsonString.contains("\"final_content\""))")
                                        print("📊 YIELD: Checking if content exists: \(jsonString.contains("\"content\""))")
                                    }
                                    
                                    // Parse JSON
                                    do {
                                        let jsonData = jsonString.data(using: .utf8)!
                                        let postchainEvent = try decoder.decode(PostchainEvent.self, from: jsonData)
                                        
                                        print("📡 STREAM: Decoded event for phase: \(postchainEvent.phase)")
                                        print("📡 STREAM: Content length: \(postchainEvent.content?.count ?? 0)")
                                        print("📡 STREAM: Status: \(postchainEvent.status)")
                                        
                                        // Enhanced yield phase logging
                                        if postchainEvent.phase == "yield" {
                                            print("📡 YIELD: Content length: \(postchainEvent.content?.count ?? 0), finalContent length: \(postchainEvent.finalContent?.count ?? 0)")
                                            print("📡 YIELD: Content exists: \(postchainEvent.content != nil), finalContent exists: \(postchainEvent.finalContent != nil)")
                                            print("📡 YIELD: Raw content: '\(postchainEvent.content ?? "nil")'")
                                            print("📡 YIELD: Raw finalContent: '\(postchainEvent.finalContent ?? "nil")'")
                                            
                                            if postchainEvent.status == "complete" {
                                                print("📡 YIELD: Phase complete")
                                            }
                                        }
                                        
                                        print("📡 STREAM: Yielding event to consumer")
                                        continuation.yield(postchainEvent)
                                    } catch {
                                        print("📡 STREAM: Error decoding event: \(error)")
                                    }
                                }
                            }
                            
                            // Keep the incomplete part in the buffer
                            buffer = events.last ?? ""
                        }
                    }
                    
                    print("📡 STREAM: Stream completed")
                    continuation.finish()
                } catch {
                    print("📡 STREAM: Error: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Recovers a thread state from the server
    /// - Parameter threadId: ID of the thread to recover
    /// - Returns: Thread recovery information
    /// - Throws: APIError if the request fails
    func recoverThread(threadId: String) async throws -> ThreadRecoveryResponse {
        let request = ThreadRecoveryRequest(threadId: threadId)
        return try await send(request)
    }
    
    /// Checks the health of the API service
    /// - Returns: Health status information
    /// - Throws: APIError if the request fails
    func checkHealth() async throws -> HealthCheckResponse {
        let request = HealthCheckRequest()
        return try await send(request)
    }
}

// MARK: - Helper Extensions

/// Extends URLSession with an async/await fetch method that takes a URL string
extension URLSession {
    /// Fetches data from a URL string using async/await
    /// - Parameter urlString: URL string to fetch from
    /// - Returns: Tuple of (Data, URLResponse)
    /// - Throws: Error if the fetch fails
    func data(from urlString: String) async throws -> (Data, URLResponse) {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        return try await data(from: url)
    }
}