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

        // We have a token, now try to access it
        do {
            #if DEBUG && targetEnvironment(simulator)
            // In simulator, load token without biometric prompt
            guard let token = try keychain.load("auth_token") else {
                authState = .unauthenticated
                return
            }
            #else
            // On device, use biometric auth to access token
            guard let token = try keychain.load("auth_token", withPrompt: "Authenticate to access your Choir account") else {
                authState = .unauthenticated
                return
            }
            #endif

            let userInfo = try await getUserInfo(token: token)
            self.userInfo = userInfo
        } catch {
            print("Authentication error: \(error)")
            authState = .unauthenticated
            // Don't delete the token, just couldn't authenticate this time
        }
    }

    func login() async throws {
        print("Starting login process with biometric authentication")

        // Set state to authenticating first
        authState = .authenticating

        // First, authenticate with biometrics before proceeding
        do {
            print("Requesting biometric authentication...")
            try await verifyBiometricAuth()
            print("Biometric authentication successful")
        } catch {
            print("Biometric authentication failed: \(error)")
            // Reset auth state and throw error
            authState = .unauthenticated
            throw AuthError.biometricAuthFailed
        }

        // After successful biometric auth, check if we have a wallet
        guard let wallet = walletManager.wallet else {
            print("Wallet not available")
            authState = .unauthenticated
            throw AuthError.walletNotAvailable
        }

        print("Proceeding with wallet authentication")

        do {
            // 1. Get wallet address
            let address = try wallet.accounts[0].address()
            print("Got wallet address: \(address)")

            // 2. Request challenge - start this early
            print("Requesting challenge for address: \(address)")
            let challengeTask = Task {
                try await requestChallenge(walletAddress: address)
            }

            // 3. Prepare the message for signing (can be done while waiting for challenge)
            let messagePrefix = "Sign this message to authenticate with Choir: "

            // 4. Wait for challenge to complete
            let challenge = try await challengeTask.value
            print("Received challenge: \(challenge)")

            // 5. Sign challenge
            let message = messagePrefix + challenge
            print("Signing message: \(message)")
            let signature = try await signMessage(message: message, wallet: wallet)
            print("Generated signature: \(signature)")

            // 6. Submit signature
            print("Submitting signature to server")
            let authResponse = try await submitSignature(
                walletAddress: address,
                challenge: challenge,
                signature: signature
            )
            print("Received auth response with token: \(authResponse.access_token.prefix(10))...")

            // 7. Store token and get user info in parallel
            async let saveTokenTask: Void = Task {
                do {
                    try keychain.save(authResponse.access_token, forKey: "auth_token", useBiometric: true)
                    print("Stored auth token with biometric protection")
                } catch {
                    print("Error storing token: \(error)")
                    throw AuthError.tokenStorageFailed
                }
            }.value

            async let userInfoTask = getUserInfo(token: authResponse.access_token)

            // 8. Wait for both tasks to complete
            try await saveTokenTask
            let userInfo = try await userInfoTask

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

    // Check if we have a token without triggering biometric auth
    func hasAuthToken() -> Bool {
        return (try? keychain.hasKey("auth_token")) ?? false
    }

    // MARK: - API Methods

    private func requestChallenge(walletAddress: String) async throws -> String {
        let url = ApiConfig.url(for: ApiConfig.Endpoints.challenge)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set a shorter timeout for faster failure
        request.timeoutInterval = 10

        // Set caching policy to return cached data if available
        request.cachePolicy = .returnCacheDataElseLoad

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

        // Set a shorter timeout for faster failure
        request.timeoutInterval = 10

        // Set caching policy to return cached data if available
        request.cachePolicy = .returnCacheDataElseLoad

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

        // Set a shorter timeout for faster failure
        request.timeoutInterval = 10

        // Set caching policy to return cached data if available
        request.cachePolicy = .returnCacheDataElseLoad

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
        #if DEBUG && targetEnvironment(simulator)
        // Skip authentication in simulator for development
        print("Skipping biometric authentication in simulator")
        return
        #else
        // Use LocalAuthentication framework directly
        let context = LAContext()

        // Set timeout to a shorter value for faster authentication
        context.touchIDAuthenticationAllowableReuseDuration = 10

        var error: NSError?

        // First check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometric authentication is available (Face ID or Touch ID)
            let biometricType = context.biometryType == .faceID ? "Face ID" : "Touch ID"
            print("Using \(biometricType) for authentication")

            // Create a task that can be awaited for the authentication result
            try await withCheckedThrowingContinuation { continuation in
                // Request biometric authentication
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Authenticate to access your Choir account"
                ) { success, error in
                    if success {
                        print("Biometric authentication successful")
                        continuation.resume()
                    } else if let error = error {
                        print("Biometric authentication failed: \(error)")
                        continuation.resume(throwing: AuthError.biometricAuthFailed)
                    } else {
                        print("Biometric authentication failed with unknown error")
                        continuation.resume(throwing: AuthError.biometricAuthFailed)
                    }
                }
            }
        } else {
            // Biometric authentication is not available, try device passcode instead
            print("Biometric authentication not available, falling back to device passcode")
            if let error = error {
                print("Biometric error: \(error.localizedDescription)")
            }

            // Try device passcode authentication
            try await withCheckedThrowingContinuation { continuation in
                context.evaluatePolicy(
                    .deviceOwnerAuthentication, // This allows passcode as fallback
                    localizedReason: "Authenticate to access your Choir account"
                ) { success, error in
                    if success {
                        print("Passcode authentication successful")
                        continuation.resume()
                    } else {
                        print("Passcode authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                        continuation.resume(throwing: AuthError.biometricAuthFailed)
                    }
                }
            }
        }
        #endif
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

    /// Updates the authentication token when switching wallets
    /// - Parameter walletAddress: The new wallet address
    /// - Returns: True if successful, false otherwise
    func updateAuthForWallet(walletAddress: String) async -> Bool {
        print("Updating auth token for wallet: \(walletAddress)")

        // First check if we're already authenticated
        guard case .authenticated(let currentUserInfo) = authState else {
            print("Not authenticated, cannot update token")
            return false
        }

        do {
            // 1. Request challenge for the new wallet address
            let challenge = try await requestChallenge(walletAddress: walletAddress)
            print("Received challenge for wallet switch: \(challenge)")

            // 2. Get the wallet from the wallet manager
            guard let wallet = walletManager.wallet,
                  let address = try? wallet.accounts[0].address(),
                  address == walletAddress else {
                print("Wallet mismatch or not available")
                return false
            }

            // 3. Sign challenge
            let message = "Sign this message to authenticate with Choir: \(challenge)"
            let signature = try await signMessage(message: message, wallet: wallet)

            // 4. Submit signature to get new token
            let authResponse = try await submitSignature(
                walletAddress: walletAddress,
                challenge: challenge,
                signature: signature
            )

            // 5. Store the new token
            try keychain.save(authResponse.access_token, forKey: "auth_token", useBiometric: true)

            // 6. Update user info
            let userInfo = try await getUserInfo(token: authResponse.access_token)
            self.userInfo = userInfo

            print("Successfully updated auth token for wallet: \(walletAddress)")
            return true
        } catch {
            print("Error updating auth token for wallet: \(error)")
            return false
        }
    }
}
