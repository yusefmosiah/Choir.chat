import XCTest

final class ChoirIntegrationTests: XCTestCase {

    let baseURL = URL(string: "http://localhost:8000/api")!

    func testUserAuthAndFetchThreads() async throws {
        let suiAddress = "0x1234567890abcdef"

        // 1. Request challenge
        var challengeRequest = URLRequest(url: baseURL.appendingPathComponent("auth/request_challenge"))
        challengeRequest.httpMethod = "POST"
        challengeRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let challengeBody = ["address": suiAddress]
        challengeRequest.httpBody = try JSONEncoder().encode(challengeBody)

        let (challengeData, _) = try await URLSession.shared.data(for: challengeRequest)
        let challengeResponse = try JSONDecoder().decode([String: String].self, from: challengeData)
        let challenge = challengeResponse["challenge"] ?? ""
        XCTAssertFalse(challenge.isEmpty)

        // 2. Mock signature
        let signature = "MOCK_SIGNATURE_BASE64"

        // 3. Verify user
        var verifyRequest = URLRequest(url: baseURL.appendingPathComponent("auth/verify"))
        verifyRequest.httpMethod = "POST"
        verifyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let verifyBody = ["address": suiAddress, "signature": signature]
        verifyRequest.httpBody = try JSONEncoder().encode(verifyBody)

        let (verifyData, _) = try await URLSession.shared.data(for: verifyRequest)
        let verifyResponse = try JSONDecoder().decode([String: String].self, from: verifyData)
        let userUUID = verifyResponse["user_id"] ?? ""
        XCTAssertEqual(userUUID.count, 36)

        // 4. Fetch threads
        let threadsURL = baseURL.appendingPathComponent("users/\(userUUID)/threads")
        let (threadsData, _) = try await URLSession.shared.data(from: threadsURL)
        let threadsResponse = try JSONDecoder().decode([String: AnyDecodable].self, from: threadsData)
        print("Threads response: \(threadsResponse)")
        XCTAssertTrue(threadsResponse["success"] as? Bool ?? false)
    }
}

struct AnyDecodable: Decodable {}
