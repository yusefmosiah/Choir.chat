import Foundation

/// An async sequence wrapper around Server-Sent Events (SSE)
/// Provides a modern Swift concurrency interface for SSE streams
actor EventSource {
    // Configuration
    private let url: URL
    private let headers: [String: String]
    private let requestBody: Data?
    private let maxRetries: Int
    private let reconnectDelay: TimeInterval
    
    // State
    private var task: URLSessionDataTask?
    private var isConnected = false
    private var retryCount = 0
    private var connectionID = UUID()
    private var lastEventID: String?
    
    // Stream continuations for async/await support
    private var eventContinuation: AsyncStream<ServerSentEvent>.Continuation?
    
    /// Creates a new EventSource for the specified URL
    /// - Parameters:
    ///   - url: The URL to connect to
    ///   - headers: Additional HTTP headers to include with the request
    ///   - requestBody: Optional data to send in the request body (for POST requests)
    ///   - maxRetries: Maximum number of reconnection attempts (default: 3)
    ///   - reconnectDelay: Initial delay between reconnection attempts in seconds (default: 3.0)
    init(
        url: URL,
        headers: [String: String] = [:],
        requestBody: Data? = nil,
        maxRetries: Int = 3,
        reconnectDelay: TimeInterval = 3.0
    ) {
        self.url = url
        self.headers = headers
        self.requestBody = requestBody
        self.maxRetries = maxRetries
        self.reconnectDelay = reconnectDelay
    }
    
    /// Connects to the SSE endpoint and returns an AsyncStream of ServerSentEvents
    /// - Returns: An async sequence of SSE events
    func connect() -> AsyncStream<ServerSentEvent> {
        // Reset state for new connection
        connectionID = UUID()
        isConnected = true
        retryCount = 0
        
        let currentConnectionID = connectionID
        
        return AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }
            
            Task { [weak self] in
                await self?.setEventContinuation(continuation, connectionID: currentConnectionID)
            }
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.disconnect()
                }
            }
        }
    }
    
    private func setEventContinuation(_ continuation: AsyncStream<ServerSentEvent>.Continuation, connectionID: UUID) async {
        self.eventContinuation = continuation
        await startConnection(connectionID: connectionID)
    }
    
    /// Disconnects from the SSE endpoint
    func disconnect() {
        isConnected = false
        task?.cancel()
        task = nil
        eventContinuation?.finish()
        eventContinuation = nil
    }
    
    // MARK: - Private Methods
    
    private func startConnection(connectionID: UUID) async {
        // Only proceed if this is the current connection
        guard self.connectionID == connectionID && isConnected else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = requestBody != nil ? "POST" : "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        // Set request body if provided (for POST requests)
        if let body = requestBody {
            request.httpBody = body
        }
        
        // Add custom headers
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        
        // Add last event ID if available for reconnection
        if let lastEventID = lastEventID {
            request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID")
        }
        
        let session = URLSession.shared
        let buffer = SSEBuffer()
        
        // Log the request for debugging
        print("🌐 SSE: Creating connection to \(url.absoluteString)")
        print("🌐 SSE: Method: \(request.httpMethod ?? "Unknown")")
        print("🌐 SSE: Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("🌐 SSE: Body: \(bodyString.prefix(500))...")
        }
        
        // Create a captured copy of the buffer to avoid Sendable issues
        let capturedBuffer = buffer
        
        task = session.dataTask(with: request) { [weak self] data, response, error in
            // Log the initial response
            print("🌐 SSE: Received initial response")
            if let error = error {
                print("🌐 SSE: Error in initial response: \(error.localizedDescription)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 SSE: Status code: \(httpResponse.statusCode)")
                print("🌐 SSE: Headers: \(httpResponse.allHeaderFields)")
            }
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("🌐 SSE: Initial data received: \(dataString.prefix(500))")
            }
            
            // Create a task to handle the response asynchronously
            Task { [weak self] in
                guard let self = self else { 
                    print("🌐 SSE: Self reference lost")
                    return 
                }
                
                // Check if this connection is still active
                guard await self.connectionID == connectionID, await self.isConnected else { 
                    print("🌐 SSE: Connection not active anymore - ID mismatch or disconnected")
                    return 
                }
                
                if let error = error {
                    print("🌐 SSE: Processing error: \(error.localizedDescription)")
                    await self.handleError(error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("🌐 SSE: Invalid response type (not HTTP)")
                    await self.handleError(APIError.invalidResponse)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseData = data ?? Data()
                    let message = String(data: responseData, encoding: .utf8)
                    print("🌐 SSE: HTTP error: \(httpResponse.statusCode), message: \(message ?? "none")")
                    await self.handleError(APIError.serverError(
                        statusCode: httpResponse.statusCode, 
                        message: message
                    ))
                    return
                }
                
                print("🌐 SSE: Connection established successfully")
                
                if let data = data {
                    // Print the raw data for debugging
                    if let text = String(data: data, encoding: .utf8) {
                        print("🌐 SSE: Raw data chunk received: \(text)")
                    } else {
                        print("🌐 SSE: Raw data received but couldn't be converted to string")
                    }
                    
                    // Add the data to the buffer
                    print("🌐 SSE: Appending data to buffer")
                    capturedBuffer.append(data)
                    
                    // Log buffer size
                    print("🌐 SSE: Buffer size after append: \(capturedBuffer.size) bytes")
                    
                    // Process all available events in the buffer
                    print("🌐 SSE: Checking for complete events in buffer")
                    var eventCount = 0
                    
                    while let event = capturedBuffer.nextEvent() {
                        eventCount += 1
                        print("🌐 SSE: Found complete event #\(eventCount) in buffer")
                        
                        // Save the event ID for potential reconnection
                        if let id = event.id {
                            print("🌐 SSE: Event has ID: \(id)")
                            await self.updateLastEventID(id)
                        }
                        
                        // Handle event type
                        if let eventType = event.event {
                            print("🌐 SSE: Event type: \(eventType)")
                        }
                        
                        // Handle server-specified retry time
                        if let retry = event.retry {
                            print("🌐 SSE: Server specified retry: \(retry)ms")
                        }
                        
                        // Debug output for the event data
                        if let eventData = event.data {
                            print("🌐 SSE: Event data (\(eventData.count) chars): \(eventData.prefix(100))...")
                        } else {
                            print("🌐 SSE: Event has no data")
                        }
                        
                        // Yield the event to the stream immediately
                        print("🌐 SSE: Yielding event to stream")
                        await self.yieldEvent(event)
                        print("🌐 SSE: Event yielded successfully")
                        
                        // Special case for stream end marker
                        if event.data == "[DONE]" || event.event == "complete" {
                            print("🌐 SSE: Stream end marker received. Disconnecting.")
                            await Task { await self.disconnect() }.value
                            return
                        }
                    }
                    
                    if eventCount == 0 {
                        print("🌐 SSE: No complete events found in buffer yet")
                    } else {
                        print("🌐 SSE: Processed \(eventCount) events from buffer")
                    }
                } else {
                    print("🌐 SSE: Data is nil in this response")
                }
                
                // Attempt reconnection if needed
                await self.handleDisconnect(connectionID: connectionID)
            }
        }
        
        task?.resume()
    }
    
    private func handleDisconnect(connectionID: UUID) async {
        // Only attempt reconnection for the current connection
        guard self.connectionID == connectionID && isConnected else { return }
        
        // Check if we should retry
        if retryCount < maxRetries {
            retryCount += 1
            
            // Calculate backoff delay with exponential increase
            let delay = reconnectDelay * pow(1.5, Double(retryCount - 1))
            
            // Wait before reconnecting
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Check again if we should still reconnect
            if self.connectionID == connectionID && isConnected {
                await startConnection(connectionID: connectionID)
            }
        } else {
            // We've reached max retries, give up
            await handleError(APIError.networkError(underlying: NSError(
                domain: "EventSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"]
            )))
        }
    }
    
    /// Updates the last event ID received, used for reconnection
    private func updateLastEventID(_ id: String) {
        self.lastEventID = id
    }
    
    /// Yields an event to the stream continuation
    private func yieldEvent(_ event: ServerSentEvent) {
        eventContinuation?.yield(event)
    }
    
    private func handleError(_ error: Error) async {
        let apiError: APIError
        
        if let error = error as? APIError {
            apiError = error
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                apiError = .timeout(seconds: 60.0)
            case .notConnectedToInternet, .networkConnectionLost:
                apiError = .networkError(underlying: urlError)
            default:
                apiError = .networkError(underlying: urlError)
            }
        } else {
            apiError = .networkError(underlying: error)
        }
        
        // Emit an error event (if possible)
        let errorEvent = ServerSentEvent(
            id: nil,
            event: "error",
            data: apiError.localizedDescription,
            retry: nil
        )
        yieldEvent(errorEvent)
        
        // Disconnect and clean up
        disconnect()
    }
}

/// Efficient buffer for processing SSE data
private final class SSEBuffer: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.choir.eventsource.buffer")
    private var buffer = ""
    
    // Get the current size of the buffer
    var size: Int {
        queue.sync {
            return buffer.count
        }
    }
    
    /// Appends data to the buffer
    /// - Parameter data: New data to append
    func append(_ data: Data) {
        queue.sync {
            if let text = String(data: data, encoding: .utf8) {
                buffer += text
                // Log the buffer size to monitor growth
                if buffer.count > 5000 {
                    print("⚠️ SSE buffer size is large: \(buffer.count) characters")
                }
            } else {
                print("⚠️ Failed to decode SSE data chunk using UTF-8")
            }
        }
    }
    
    /// Extracts the next complete event from the buffer
    /// - Returns: A ServerSentEvent if one is complete, nil otherwise
    func nextEvent() -> ServerSentEvent? {
        queue.sync {
            // An event is complete when it ends with a double newline
            guard let range = buffer.range(of: "\n\n") else {
                // If we don't have a complete event yet but buffer is getting large, log it
                if buffer.count > 200 {
                    print("🔍 Large buffer without complete event: \(buffer.prefix(100))...")
                }
                return nil
            }
            
            let eventString = String(buffer[..<range.upperBound])
            buffer.removeSubrange(..<range.upperBound)
            
            // Debug log for event parsing
            print("🔍 Parsing SSE event: \(eventString.prefix(50))...")
            
            return parseEvent(eventString)
        }
    }
    
    /// Parses an event string into a ServerSentEvent
    /// - Parameter eventString: Raw event string from the buffer
    /// - Returns: Parsed ServerSentEvent
    private func parseEvent(_ eventString: String) -> ServerSentEvent {
        var id: String?
        var event: String?
        var data: String?
        var retry: Int?
        
        let lines = eventString.split(separator: "\n")
        for line in lines {
            if line.hasPrefix("id:") {
                id = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("event:") {
                event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let newData = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if data == nil {
                    data = newData
                } else {
                    data = data! + "\n" + newData
                }
            } else if line.hasPrefix("retry:") {
                if let retryValue = Int(String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)) {
                    retry = retryValue
                }
            }
        }
        
        return ServerSentEvent(id: id, event: event, data: data, retry: retry)
    }
}