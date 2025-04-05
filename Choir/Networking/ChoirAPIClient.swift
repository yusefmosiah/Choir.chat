import Foundation



struct ChoirAPIClient {
    static let shared = ChoirAPIClient()
    let baseURL = URL(string: "http://localhost:8000/api")!  // Match RESTPostchainAPIClient base URL

    func fetchUserThreads(userId: String) async throws -> [ThreadResponse] {
        let url = baseURL.appendingPathComponent("/users/\(userId)/threads")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<[ThreadResponse]>.self, from: data)
        return apiResponse.data ?? []
    }
}

struct ThreadResponse: Identifiable, Codable {
    let id: String
    let name: String
    let created_at: String
    let user_id: String
    let co_authors: [String]
    let message_count: Int
    let last_activity: String
}
struct VerifyResponse: Codable {
    let user_id: String
}

extension ChoirAPIClient {
    func verifyUser(address: String, signature: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/auth/verify")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["address": address, "signature": signature]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let verifyResponse = try JSONDecoder().decode(VerifyResponse.self, from: data)
        return verifyResponse.user_id
    }
}

