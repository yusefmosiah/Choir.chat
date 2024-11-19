import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case timeout
    case cancelled
    case invalidResponse(String)

    // Add localized descriptions for better error messages
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        }
    }
}

class ChorusAPIClient {
    #if DEBUG
    internal var baseURL = "http://localhost:8000/api/chorus"
    #else
    private let baseURL = "https://your-production-url.com/api/chorus"
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

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

    func post<T: Codable, R: Codable>(endpoint: String, body: T) async throws -> APIResponse<R> {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            print("Failed to encode request body: \(error)")
            throw APIError.decodingError(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response from \(endpoint): \(responseString)")
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response type")
            }

            // Check HTTP status code
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error message if possible
                if let errorResponse = try? decoder.decode(APIResponse<String>.self, from: data) {
                    throw APIError.serverError(errorResponse.message ?? "Server error \(httpResponse.statusCode)")
                }
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
            }

            // Decode response
            let apiResponse = try decoder.decode(APIResponse<R>.self, from: data)

            // Verify response has expected data
            guard apiResponse.success else {
                throw APIError.invalidResponse(apiResponse.message ?? "Request failed")
            }

            return apiResponse

        } catch is URLError {
            throw APIError.timeout
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
