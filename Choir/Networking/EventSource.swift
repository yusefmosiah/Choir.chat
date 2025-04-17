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
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        }
        
        // Create a captured copy of the buffer to avoid Sendable issues
        let capturedBuffer = buffer
        
        task = session.dataTask(with: request) { [weak self] data, response, error in
            // Log the initial response
            if let error = error {
            }
            if let httpResponse = response as? HTTPURLResponse {
            }
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
            }
            
            // Create a task to handle the response asynchronously
            Task { [weak self] in
                guard let self = self else { 
                    return 
                }
                
                // Check if this connection is still active
                guard await self.connectionID == connectionID, await self.isConnected else { 
                    return 
                }
                
                if let error = error {
                    await self.handleError(error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await self.handleError(APIError.invalidResponse)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseData = data ?? Data()
                    let message = String(data: responseData, encoding: .utf8)
                    await self.handleError(APIError.serverError(
                        statusCode: httpResponse.statusCode, 
                        message: message
                    ))
                    return
                }
                
                
                if let data = data {
                    // Print the raw data for debugging
                    if let text = String(data: data, encoding: .utf8) {
                    } else {
                    }
                    
                    // Add the data to the buffer
                    capturedBuffer.append(data)
                    
                    // Log buffer size
                    
                    // Process all available events in the buffer
                    var eventCount = 0
                    
                    while let event = capturedBuffer.nextEvent() {
                        eventCount += 1
                        
                        // Save the event ID for potential reconnection
                        if let id = event.id {
                            await self.updateLastEventID(id)
                        }
                        
                        // Handle event type
                        if let eventType = event.event {
                        }
                        
                        // Handle server-specified retry time
                        if let retry = event.retry {
                        }
                        
                        // Debug output for the event data
                        if let eventData = event.data {
                        } else {
                        }
                        
                        // Yield the event to the stream immediately
                        await self.yieldEvent(event)
                        
                        // Special case for stream end marker
                        if event.data == "[DONE]" || event.event == "complete" {
                            await Task { await self.disconnect() }.value
                            return
                        }
                    }
                    
                    if eventCount == 0 {
                    } else {
                    }
                } else {
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
                }
            } else {
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
                }
                return nil
            }
            
            let eventString = String(buffer[..<range.upperBound])
            buffer.removeSubrange(..<range.upperBound)
            
            // Debug log for event parsing
            
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