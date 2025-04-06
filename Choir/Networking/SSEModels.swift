import Foundation

// Defines the structure for a parsed Server-Sent Event
struct ServerSentEvent {
    let id: String?
    let event: String?
    let data: String?
    let retry: Int?
}

// Protocol for delegates handling SSE events and errors
protocol SSEDelegate: AnyObject {
    func didReceiveEvent(_ event: ServerSentEvent)
    func didReceiveError(_ error: APIError) // Assuming APIError is defined elsewhere (e.g., ChoirAPIModels.swift)
}
