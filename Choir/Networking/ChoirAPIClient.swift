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

    // Removed fetchUserThreads - Now handled by Core Data
    // Removed createThread - Now handled by Core Data

    /// Get cached user ID for a wallet address if available
    /// - Parameter address: The Sui wallet address
    /// - Returns: The cached user ID or nil if not found
    func getCachedUserId(for address: String) -> String? {
        return UserDefaults.standard.string(forKey: "userUUID_\(address)")
    }

    // Removed fetchMessages - Now handled by Core Data
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
