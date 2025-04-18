import Foundation

/// Main client for interacting with the Postchain API
/// Provides both synchronous endpoints and streaming capabilities
actor PostchainAPIClient {
    // MARK: - Configuration

    // Use ApiConfig for base URL and append the specific API endpoint path
    private let baseURL = "\(ApiConfig.baseURLString)/\(ApiConfig.Endpoints.postchainBase)"

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
        }

        // Get URL for the streaming endpoint
        guard let url = URL(string: "\(ApiConfig.baseURLString)/\(ApiConfig.Endpoints.postchainLangchain)") else {
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

                do {
                    // Use URLSession directly for streaming
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    // Check response
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish()
                        return
                    }


                    guard (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish()
                        return
                    }


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

                            // Split buffer on double newlines
                            let events = buffer.components(separatedBy: "\n\n")

                            // Process all complete events
                            for i in 0..<events.count-1 {
                                let event = events[i]
                                // DEBUG LOG: Print raw event string if it's for the yield phase
                                if event.contains("\"phase\":\"yield\"") {
                                }

                                // SSE format: lines starting with "data: " contain the JSON payload
                                if let dataLine = event.split(separator: "\n").first(where: { $0.hasPrefix("data:") }) {
                                    // Extract JSON data
                                    let jsonString = String(dataLine.dropFirst(5).trimmingCharacters(in: .whitespaces))

                                    if jsonString == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }

                                    // More detailed logging for raw JSON data

                                    // ---> ADDED DEBUG LOG <---
                                    // Print the raw JSON string for ALL events before specific checks

                                    // Log raw JSON specifically for experience_vectors phase before attempting decode
                                    // Check for the phase string, accounting for the space after the colon found in logs
                                    let targetSubstringWithSpace = "\"phase\": \"experience_vectors\""
                                    _ = jsonString.contains(targetSubstringWithSpace) ||
                                        jsonString.contains("\"phase\":\"experience_vectors\"")

                                    // Parse JSON
                                    do {
                                        guard let jsonData = jsonString.data(using: .utf8) else {
                                            continue // Skip this event if data conversion fails
                                        }

                                        // For debugging: print the raw JSON if it contains model_name
                                        if jsonString.contains("model_name") {
                                        }

                                        // ---> ADDED DEBUG LOG <---

                                        let postchainEvent = try decoder.decode(PostchainEvent.self, from: jsonData)
                                        // Enhanced logging for all events, focusing on vector results

                                        // Log vector results for any phase that includes them
                                        if let vectorResults = postchainEvent.vectorResults, !vectorResults.isEmpty {

                                            _ = vectorResults.filter { !$0.content.isEmpty }
                                            _ = vectorResults.filter { $0.content.isEmpty }


                                            for vector in vectorResults {

                                                if vector.content.isEmpty {
                                                    if vector.content_preview != nil {
                                                    } else {
                                                    }
                                                } else {
                                                }
                                            }
                                        } else if postchainEvent.vectorResults?.isEmpty ?? true {
                                            // Check if the raw JSON contains vector_results field
                                            if jsonString.contains("vector_results") {
                                            }
                                        } else {
                                            // Check if the raw JSON contains vector_results field
                                        }

                                        // Special debug for yield phase
                                        if postchainEvent.phase == "yield" {
                                        }

                                        // Enhanced yield phase logging
                                        if postchainEvent.phase == "yield" {


                                            if postchainEvent.status == "complete" {
                                            }
                                        }

                                        continuation.yield(postchainEvent)
                                    } catch let decodingError as DecodingError {
                                        // Print detailed error context
                                        _ = decodingError // Silence unused variable warning
                                        // Optionally print the raw JSON string again here for context
                                    } catch {
                                    }
                                }
                            }

                            // Keep the incomplete part in the buffer
                            buffer = events.last ?? ""
                        }
                    }

                    continuation.finish()
                } catch {
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
