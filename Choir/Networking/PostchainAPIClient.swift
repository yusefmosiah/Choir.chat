import Foundation
import SwiftUI

// MARK: - Streaming API client
class PostchainAPIClient {
    #if DEBUG
    private let baseURL = "http://localhost:8000/api/postchain"
    // private let baseURL = "https://choir-chat.onrender.com/api/postchain"
    #else
    private let baseURL = "https://choir-chat.onrender.com/api/postchain"
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var viewModel: PostchainViewModel?

    init(timeout: TimeInterval = 120) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // Regular POST request for non-streaming endpoints
    func post<T: Codable, R: Codable>(endpoint: String, body: T) async throws -> R {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response type")
            }

            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
            }
            #endif

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
            }

            // Try to decode directly first
            do {
                return try decoder.decode(R.self, from: data)
            } catch {
                // If direct decoding fails, try wrapped response
                let apiResponse = try decoder.decode(APIResponse<R>.self, from: data)
                guard let responseData = apiResponse.data else {
                    throw APIError.invalidResponse("No data in response")
                }
                return responseData
            }

        } catch is URLError {
            throw APIError.timeout
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // Streaming POST request that processes SSE responses
    func streamPost<T: Codable>(
        endpoint: String,
        body: T,
        onPhaseUpdate: @escaping (String, [String: String]) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            onError(APIError.invalidURL)
            return
        }

        // Create mutable request with streaming flag
        var streamBody = body
        if var streamRequestBody = streamBody as? SimplePostchainRequestBody {
            streamRequestBody.stream = true
            streamBody = streamRequestBody as! T
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try encoder.encode(streamBody)
        } catch {
            onError(APIError.decodingError(error))
            return
        }

        // Create a URLSession with a delegate
        let config = URLSessionConfiguration.default
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: delegateQueue)

        let task = session.dataTask(with: request)

        // Use a delegate with a reference to the onPhaseUpdate and onComplete callbacks
        let sseDelegate = SSEDelegate(
            dataTask: task,
            onEventReceived: { eventData in
                if eventData == "[DONE]" {
                    DispatchQueue.main.async {
                        onComplete()
                    }
                    return
                }

                do {
                    // Try to parse the JSON data
                    let jsonData = eventData.data(using: .utf8)!

                    // Manual JSON parsing as a PostchainStreamEvent
                    if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let currentPhase = json["current_phase"] as? String,
                       let phaseState = json["phase_state"] as? String {

                        let content = json["content"] as? String ?? ""
                        let threadId = json["thread_id"] as? String
                        let error = json["error"] as? String

                        // Create a proper structured event
                        let event = PostchainStreamEvent(
                            currentPhase: currentPhase,
                            phaseState: phaseState,
                            content: content,
                            error: error,
                            metadata: [:],
                            threadId: threadId
                        )

                        self.handlePhaseUpdate(
                            phase: event.currentPhase,
                            content: event.content,
                            phaseState: event.phaseState,
                            error: event.error,
                            onPhaseUpdate: onPhaseUpdate,
                            onComplete: onComplete,
                            onError: onError
                        )
                    } else {
                        // Fallback to original decoder if the manual approach fails
                        let event = try self.decoder.decode(PostchainStreamEvent.self, from: jsonData)

                        self.handlePhaseUpdate(
                            phase: event.currentPhase,
                            content: event.content,
                            phaseState: event.phaseState,
                            error: event.error,
                            onPhaseUpdate: onPhaseUpdate,
                            onComplete: onComplete,
                            onError: onError
                        )
                    }
                } catch {
                    Task { @MainActor in
                        onError(APIError.decodingError(error))
                    }
                }
            },
            onError: { error in
                Task { @MainActor in
                    onError(error)
                }
            }
        )

        // Keep a reference to the delegate
        URLSession.shared.delegateQueue.addOperation {
            task.delegate = sseDelegate
        }

        // Start the streaming task
        task.resume()
    }

    // MARK: - Phase Update Handler
    private func handlePhaseUpdate(
        phase: String,
        content: String,
        phaseState: String,
        error: String?,
        onPhaseUpdate: @escaping (String, [String: String]) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // Use the smart Phase.from mapping
        let phaseEnum = Phase.from(phase)
        

        // Log detailed info for debugging
        
        // Only update if we have a valid phase
        if let mappedPhase = phaseEnum {
            // Just use the mapped phase enum value as the key
            // The smart Phase.from mapping will handle detecting the correct phase
            let phaseOutputs: [String: String] = [mappedPhase.rawValue: content]
        

            // Use Task for async operations instead of DispatchQueue
            Task { @MainActor in
                // Call the phase update callback
                onPhaseUpdate(phase, phaseOutputs)
                
                // Directly update view model with phase content if available
                if let viewModel = self.viewModel {
                    viewModel.updatePhase(mappedPhase, state: phaseState, content: content)
                }
            }
        } else {
            // Fallback to using the string directly if mapping fails
            let phaseOutputs = [phase: content]

            // Always update UI for unmapped phases too
            Task { @MainActor in
                onPhaseUpdate(phase, phaseOutputs)
            }
        }

        // Only check completion state AFTER we've processed the phase update
        // to ensure UI always has the latest content
        if phaseState == "complete" {
            // Stream is only considered fully complete at the yield phase
            if phase == "yield" {
                print("📱 API Client: Yield phase complete - ending stream")
                Task { @MainActor in
                    onComplete()
                }
            } else {
                print("📱 API Client: Phase \(phase) complete, continuing stream")
            }
        } else if phaseState == "error" {
            Task { @MainActor in
                onError(APIError.streamingError(error ?? "Unknown streaming error"))
            }
        }
    }
}

// Helper class to process Server-Sent Events (SSE)
class SSEDelegate: NSObject, URLSessionDataDelegate {
    private var task: URLSessionDataTask
    private let onEventReceived: (String) -> Void
    private let onError: (Error) -> Void
    private var buffer = ""

    init(dataTask: URLSessionDataTask, onEventReceived: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.task = dataTask
        self.onEventReceived = onEventReceived
        self.onError = onError
        super.init()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        guard let string = String(data: data, encoding: .utf8) else {
            onError(APIError.decodingError(NSError(domain: "SSE", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not decode data as UTF-8"])))
            return
        }

        // Debug the raw data

        // Append to the buffer
        buffer += string

        // Process complete events
        while let eventEnd = buffer.range(of: "\n\n") {
            let eventString = String(buffer[..<eventEnd.lowerBound])
            buffer = String(buffer[eventEnd.upperBound...])

            // Process a complete SSE event
            if let dataLine = eventString.range(of: "data: ") {
                let eventData = String(eventString[dataLine.upperBound...])
                onEventReceived(eventData)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onError(APIError.networkError(error))
        }
    }
}

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case timeout
    case cancelled
    case invalidResponse(String)
    case streamingError(String)
}
