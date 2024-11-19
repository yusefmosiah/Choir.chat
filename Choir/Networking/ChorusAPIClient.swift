import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case timeout
    case cancelled
    case invalidResponse(String)
}

class ChorusAPIClient {
    #if DEBUG
    private let baseURL = "http://localhost:8000/api/chorus"
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

            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response from \(endpoint): \(responseString)")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to decode error message if possible
                if let errorResponse = try? decoder.decode(APIResponse<String>.self, from: data) {
                    throw APIError.serverError(errorResponse.message ?? "Server error \(httpResponse.statusCode)")
                }
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
            }

            // First decode the API response wrapper
            let apiResponse = try decoder.decode(APIResponse<R>.self, from: data)

            guard apiResponse.success, let responseData = apiResponse.data else {
                throw APIError.invalidResponse(apiResponse.message ?? "Request failed")
            }

            return responseData

        } catch is URLError {
            throw APIError.timeout
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            print("Decoding error details: \(error)")
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
