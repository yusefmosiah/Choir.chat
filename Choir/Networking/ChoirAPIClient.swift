import Foundation

struct ChoirAPIClient {
    static let shared = ChoirAPIClient()
    #if DEBUG && targetEnvironment(simulator)
    // Use localhost for simulator
    let baseURL = URL(string: "http://localhost:8000/api")!
    #else
    // Use public URL for physical devices and release builds
    let baseURL = URL(string: "https://choir-chat.onrender.com/api")!
    #endif

    // User authentication context - made static to avoid immutability issues with singleton
    private static var currentAddress: String?
    private static var currentUserId: String?

    /// Fetches threads for a user
    /// - Parameter userId: The user's UUID (derived from their Sui address)
    /// - Returns: Array of ThreadResponse objects
    func fetchUserThreads(userId: String) async throws -> [ThreadResponse] {
        let url = baseURL.appendingPathComponent("/users/\(userId)/threads")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            // Debug: Print the raw JSON to see the structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }

            // Define the correct response structure
            struct ThreadsResponse: Codable {
                let success: Bool
                let message: String?
                let data: ThreadsData

                struct ThreadsData: Codable {
                    let threads: [ThreadResponse]
                }
            }

            do {
                // Decode with the correct structure
                let response = try JSONDecoder().decode(ThreadsResponse.self, from: data)
                return response.data.threads
            } catch {
                print("Failed to decode ThreadsResponse: \(error)")

                // Fallback decoding attempts
                do {
                    // Try direct array
                    return try JSONDecoder().decode([ThreadResponse].self, from: data)
                } catch {
                    print("Failed to decode direct array: \(error)")

                    // Try generic dictionary approach as last resort
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataDict = json["data"] as? [String: Any],
                       let threadsArray = dataDict["threads"] as? [[String: Any]] {

                        // Manually construct ThreadResponse objects
                        var threads: [ThreadResponse] = []
                        for threadDict in threadsArray {
                            if let id = threadDict["id"] as? String,
                               let name = threadDict["name"] as? String,
                               let createdAt = threadDict["created_at"] as? String,
                               let userId = threadDict["user_id"] as? String,
                               let coAuthors = threadDict["co_authors"] as? [String],
                               let messageCount = threadDict["message_count"] as? Int,
                               let lastActivity = threadDict["last_activity"] as? String {

                                let thread = ThreadResponse(
                                    id: id,
                                    name: name,
                                    created_at: createdAt,
                                    user_id: userId,
                                    co_authors: coAuthors,
                                    message_count: messageCount,
                                    last_activity: lastActivity
                                )
                                threads.append(thread)
                            }
                        }
                        return threads
                    }

                    throw URLError(.cannotParseResponse)
                }
            }
        } catch {
            print("Network error in fetchUserThreads: \(error)")
            throw error
        }
    }

    /// Creates a new thread in Qdrant
    /// - Parameters:
    ///   - name: Name of the thread
    ///   - userId: User's UUID (derived from their Sui address)
    ///   - initialMessage: Optional initial message content
    /// - Returns: The created thread response
    func createThread(name: String, userId: String, initialMessage: String? = nil) async throws -> ThreadResponse {
        let url = baseURL.appendingPathComponent("/threads")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": name,
            "user_id": userId,
            "initial_message": initialMessage as Any
        ].compactMapValues { $0 }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Debug: Print the raw JSON to see the structure
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Create thread raw JSON response: \(jsonString)")
        }

        // Define the correct response structure
        struct ThreadCreateResponse: Codable {
            let success: Bool
            let message: String?
            let data: ThreadData

            struct ThreadData: Codable {
                let thread: ThreadResponse
            }
        }

        do {
            // Decode with the correct structure
            let response = try JSONDecoder().decode(ThreadCreateResponse.self, from: data)
            return response.data.thread
        } catch {
            print("Failed to decode ThreadCreateResponse: \(error)")

            // Fallback decoding attempts
            do {
                // Try the original APIResponse format
                let apiResponse = try JSONDecoder().decode(APIResponse<ThreadResponse>.self, from: data)
                if let thread = apiResponse.data {
                    return thread
                }

                // Try generic dictionary approach as last resort
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let threadDict = dataDict["thread"] as? [String: Any],
                   let id = threadDict["id"] as? String,
                   let name = threadDict["name"] as? String,
                   let createdAt = threadDict["created_at"] as? String,
                   let userId = threadDict["user_id"] as? String,
                   let coAuthors = threadDict["co_authors"] as? [String],
                   let messageCount = threadDict["message_count"] as? Int,
                   let lastActivity = threadDict["last_activity"] as? String {

                    return ThreadResponse(
                        id: id,
                        name: name,
                        created_at: createdAt,
                        user_id: userId,
                        co_authors: coAuthors,
                        message_count: messageCount,
                        last_activity: lastActivity
                    )
                }

                throw URLError(.cannotParseResponse)
            } catch {
                print("All fallback decoding attempts failed: \(error)")
                throw error
            }
        }
    }

    /// Get cached user ID for a wallet address if available
    /// - Parameter address: The Sui wallet address
    /// - Returns: The cached user ID or nil if not found
    func getCachedUserId(for address: String) -> String? {
        return UserDefaults.standard.string(forKey: "userUUID_\(address)")
    }

    func fetchMessages(threadId: String, limit: Int = 50, before: String? = nil) async throws -> [TurnResponse] { // Update return type
        var urlComponents = URLComponents(string: "\(baseURL.absoluteString)/threads/\(threadId)/messages")!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let before = before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Use the renamed TurnsAPIResponse struct from ChoirModels.swift
        let apiResponse = try decoder.decode(TurnsAPIResponse.self, from: data)
        // Access the nested turns array
        return apiResponse.data?.turns ?? []
    }
}




// MARK: - Authentication Extension
extension ChoirAPIClient {
    /// The authentication flow works as follows:
    /// 1. Request a challenge from the server using the Sui address
    /// 2. Sign the challenge with the Sui wallet
    /// 3. Send the signature and address to verify
    /// 4. Server verifies and returns a user_id (UUID)
    ///
    /// The user_id is deterministically derived from the Sui address using:
    /// `user_uuid = str(uuid.UUID(hashlib.sha256(sui_address.encode()).hexdigest()[0:32]))`
    /// This ensures the same Sui address always maps to the same UUID.

    /// Request a challenge for the given Sui address
    /// - Parameter address: The Sui wallet address
    /// - Returns: Challenge string to be signed
    func requestChallenge(address: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/auth/request_challenge")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["address": address]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let challengeResponse = try JSONDecoder().decode([String: String].self, from: data)
        guard let challenge = challengeResponse["challenge"] else {
            throw URLError(.badServerResponse)
        }

        // Store the address for later use
        ChoirAPIClient.currentAddress = address

        return challenge
    }

    /// Verify a Sui wallet's signature and get the corresponding user UUID
    /// - Parameters:
    ///   - address: The Sui wallet address
    ///   - signature: The signature of the challenge
    /// - Returns: The user's UUID (deterministically derived from the address)
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

        // Store the current user ID
        ChoirAPIClient.currentUserId = verifyResponse.user_id

        // Also save to UserDefaults with the address as context
        if let address = ChoirAPIClient.currentAddress {
            UserDefaults.standard.set(verifyResponse.user_id, forKey: "userUUID_\(address)")
        }

        return verifyResponse.user_id
    }
}
