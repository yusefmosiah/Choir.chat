import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case timeout
    case cancelled
}

class ChorusAPIClient {
    private let baseURL = "http://localhost:8000/api/chorus"
    private let session: URLSession

    init(timeout: TimeInterval = 120) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        session = URLSession(configuration: config)
    }

    func post<T: Codable>(endpoint: String, body: [String: Any]) async throws -> APIResponse<T> {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response type")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)

            guard apiResponse.success else {
                throw APIError.serverError(apiResponse.message ?? "Request failed")
            }

            return apiResponse

        } catch is URLError {
            throw APIError.timeout
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
