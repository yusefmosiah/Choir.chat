import Foundation

class APIClient {
    // MARK: - Properties

    private let baseURL: URL
    private let authService: AuthService

    // MARK: - Initialization

    init(baseURL: URL, authService: AuthService) {
        self.baseURL = baseURL
        self.authService = authService
    }

    // MARK: - API Methods

    func get<T: Decodable>(endpoint: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add authentication header if available
        if let authHeader = await authService.getAuthHeader() {
            for (key, value) in authHeader {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication header if available
        if let authHeader = await authService.getAuthHeader() {
            for (key, value) in authHeader {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        // Encode request body
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }
}
