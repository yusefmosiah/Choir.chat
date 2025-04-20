import Foundation
import SuiKit
import SwiftUI
import LocalAuthentication

@MainActor
class AuthService: ObservableObject {
    // MARK: - Shared Instance

    // Temporary shared instance for use with PostchainAPIClient
    // This will be properly initialized when the app starts
    static var shared = AuthService(walletManager: WalletManager())
    // MARK: - Properties

    @Published private(set) var authState: AuthState = .unauthenticated

    private let walletManager: WalletManager
    private let keychain = KeychainService()

    private var authToken: String? {
        get {
            do {
                return try keychain.load("auth_token", withPrompt: "Authenticate to access your Choir account")
            } catch {
                print("Error loading auth token: \(error)")
                return nil
            }
        }
        set {
            do {
                if let newValue = newValue {
                    try keychain.save(newValue, forKey: "auth_token", useBiometric: true)
                } else {
                    try keychain.delete("auth_token")
                }
            } catch {
                print("Error saving/deleting auth token: \(error)")
            }
        }
    }

    private var userInfo: UserInfo? {
        didSet {
            if let userInfo = userInfo {
                authState = .authenticated(userInfo)
            } else {
                authState = .unauthenticated
            }
        }
    }

    // MARK: - Initialization

    init(walletManager: WalletManager) {
        self.walletManager = walletManager

        // Check for existing token
        Task {
            await checkExistingAuth()
        }
    }

    // MARK: - Authentication Methods

    private func checkExistingAuth() async {
        // First check if we have a token without triggering biometric auth
        let hasToken = (try? keychain.hasKey("auth_token")) ?? false

        if !hasToken {
            authState = .unauthenticated
            return
        }

        // We have a token, now try to access it with biometric auth
        do {
            guard let token = try keychain.load("auth_token", withPrompt: "Authenticate to access your Choir account") else {
                authState = .unauthenticated
                return
            }

            let userInfo = try await getUserInfo(token: token)
            self.userInfo = userInfo
        } catch {
            print("Authentication error: \(error)")
            authState = .unauthenticated
            // Don't delete the token, just couldn't authenticate this time
        }
    }

    func login() async throws {
        print("Starting login process")

        // First, authenticate with biometrics before proceeding
        do {
            print("Requesting biometric authentication...")
            try await verifyBiometricAuth()
            print("Biometric authentication successful")
        } catch {
            print("Biometric authentication failed: \(error)")
            // Convert any LA error to our own AuthError
            throw AuthError.biometricAuthFailed
        }

        guard let wallet = walletManager.wallet else {
            print("Wallet not available")
            throw AuthError.walletNotAvailable
        }

        authState = .authenticating
        print("Auth state set to authenticating")

        do {
            // 1. Get wallet address
            let address = try wallet.accounts[0].address()
            print("Got wallet address: \(address)")

            // 2. Request challenge
            print("Requesting challenge for address: \(address)")
            let challenge = try await requestChallenge(walletAddress: address)
            print("Received challenge: \(challenge)")

            // 3. Sign challenge
            let message = "Sign this message to authenticate with Choir: \(challenge)"
            print("Signing message: \(message)")
            let signature = try await signMessage(message: message, wallet: wallet)
            print("Generated signature: \(signature)")

            // 4. Submit signature
            print("Submitting signature to server")
            let authResponse = try await submitSignature(
                walletAddress: address,
                challenge: challenge,
                signature: signature
            )
            print("Received auth response with token: \(authResponse.access_token.prefix(10))...")

            // 5. Store token with biometric protection
            do {
                try keychain.save(authResponse.access_token, forKey: "auth_token", useBiometric: true)
                print("Stored auth token with biometric protection")
            } catch {
                print("Error storing token: \(error)")
                throw AuthError.tokenStorageFailed
            }

            // 6. Get user info
            print("Fetching user info")
            let userInfo = try await getUserInfo(token: authResponse.access_token)
            self.userInfo = userInfo
            print("Login complete, user info: \(userInfo.user_id)")

        } catch {
            print("Login error: \(error)")
            authState = .error(error)
            throw error
        }
    }

    func logout() {
        do {
            // Delete the auth token from keychain
            try keychain.delete("auth_token")
            print("Auth token deleted from keychain")

            // Clear the user info and update auth state
            userInfo = nil
            authState = .unauthenticated
        } catch {
            print("Error deleting auth token: \(error)")
            // Still clear the user info and update auth state
            userInfo = nil
            authState = .unauthenticated
        }
    }

    // MARK: - API Methods

    private func requestChallenge(walletAddress: String) async throws -> String {
        let url = ApiConfig.url(for: ApiConfig.Endpoints.challenge)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChallengeRequest(wallet_address: walletAddress)
        request.httpBody = try JSONEncoder().encode(body)

        print("Challenge request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "<invalid>")") // Debug log

        let (data, response) = try await URLSession.shared.data(for: request)

        print("Challenge response: \(String(data: data, encoding: .utf8) ?? "<invalid>")")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            print("Challenge request failed with status code: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }

        let decoder = createJSONDecoder()

        let challengeResponse = try decoder.decode(ChallengeResponse.self, from: data)
        return challengeResponse.challenge
    }

    private func signMessage(message: String, wallet: Wallet) async throws -> String {
        // Sign the message with the wallet
        let messageData = message.data(using: .utf8)!
        let signature = try wallet.accounts[0].sign(messageData)
        // Convert the signature to a hex string
        return try signature.hex()
    }

    private func submitSignature(walletAddress: String, challenge: String, signature: String) async throws -> AuthResponse {
        let url = ApiConfig.url(for: ApiConfig.Endpoints.login)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AuthRequest(
            wallet_address: walletAddress,
            signature: signature,
            challenge: challenge
        )
        request.httpBody = try JSONEncoder().encode(body)

        print("Login request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "<invalid>")")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("Login response: \(String(data: data, encoding: .utf8) ?? "<invalid>")")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            print("Login request failed with status code: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }

        let decoder = createJSONDecoder()

        return try decoder.decode(AuthResponse.self, from: data)
    }

    private func getUserInfo(token: String) async throws -> UserInfo {
        print("Getting user info with token: \(token.prefix(10))...")
        let url = ApiConfig.url(for: ApiConfig.Endpoints.me)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("User info request headers: \(request.allHTTPHeaderFields ?? [:])")

        let (data, response) = try await URLSession.shared.data(for: request)

        print("User info response: \(String(data: data, encoding: .utf8) ?? "<invalid>")")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response")
            throw AuthError.invalidResponse
        }

        print("User info response status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            print("User info request failed with status code: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }

        let decoder = createJSONDecoder()

        do {
            let userInfo = try decoder.decode(UserInfo.self, from: data)
            print("Successfully decoded user info: \(userInfo.user_id)")
            return userInfo
        } catch {
            print("Error decoding user info: \(error)")
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Verifies biometric authentication using LocalAuthentication framework directly
    private func verifyBiometricAuth() async throws {
        // Use LocalAuthentication framework directly

        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                print("Biometric authentication not available: \(error)")
            } else {
                print("Biometric authentication not available")
            }
            // If biometric auth is not available, we'll still allow login
            // but we'll use standard security
            return
        }

        // Get the biometric type (Face ID or Touch ID)
        let biometricType = context.biometryType == .faceID ? "Face ID" : "Touch ID"
        print("Using \(biometricType) for authentication")

        // Create a task that can be awaited for the authentication result
        return try await withCheckedThrowingContinuation { continuation in
            // Request biometric authentication
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to sign in to Choir"
            ) { success, error in
                if success {
                    print("Biometric authentication successful")
                    continuation.resume()
                } else if let error = error {
                    print("Biometric authentication failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("Biometric authentication failed with unknown error")
                    continuation.resume(throwing: AuthError.biometricAuthFailed)
                }
            }
        }
    }

    /// Creates a JSONDecoder with a custom date decoding strategy that can handle various ISO8601 formats
    private func createJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        // Create a custom date formatter that can handle various ISO8601 formats
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            print("Decoding date string: \(dateString)")

            // Try parsing with the full format first
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // If that fails, try without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // If all else fails, throw an error
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected date string to be ISO8601-formatted: \(dateString)"
                )
            )
        }

        return decoder
    }

    func getAuthHeader() -> [String: String]? {
        do {
            guard let token = try keychain.load("auth_token", withPrompt: "Authenticate to access your Choir account") else {
                return nil
            }

            return ["Authorization": "Bearer \(token)"]
        } catch {
            print("Error getting auth token for header: \(error)")
            return nil
        }
    }
}
