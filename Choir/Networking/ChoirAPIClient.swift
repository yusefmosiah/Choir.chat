import Foundation



struct ChoirAPIClient {
    static let shared = ChoirAPIClient()
    private let baseURL = URL(string: "http://localhost:57121")!  // Update with your backend URL and port

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
