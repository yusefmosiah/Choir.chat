import Foundation

// MARK: - Challenge Request/Response

struct ChallengeRequest: Codable {
    let wallet_address: String

    enum CodingKeys: String, CodingKey {
        case wallet_address = "wallet_address"
    }
}

struct ChallengeResponse: Codable {
    let challenge: String
    let expires_at: Date

    enum CodingKeys: String, CodingKey {
        case challenge
        case expires_at = "expires_at"
    }
}

// MARK: - Auth Request/Response

struct AuthRequest: Codable {
    let wallet_address: String
    let signature: String
    let challenge: String

    enum CodingKeys: String, CodingKey {
        case wallet_address = "wallet_address"
        case signature
        case challenge
    }
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_at: Date
    let user_id: String

    enum CodingKeys: String, CodingKey {
        case access_token = "access_token"
        case token_type = "token_type"
        case expires_at = "expires_at"
        case user_id = "user_id"
    }
}

// MARK: - User Info

struct UserInfo: Codable, Equatable {
    let user_id: String
    let wallet_address: String
    let exp: Date?

    enum CodingKeys: String, CodingKey {
        case user_id = "user_id"
        case wallet_address = "wallet_address"
        case exp
    }

    // Custom initializer to handle different field names
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode user_id, if not present, try sub
        do {
            user_id = try container.decode(String.self, forKey: .user_id)
        } catch {
            // If user_id is not present, try to decode from "sub" field
            let alternativeContainer = try decoder.container(keyedBy: AlternativeCodingKeys.self)
            user_id = try alternativeContainer.decode(String.self, forKey: .sub)
        }

        wallet_address = try container.decode(String.self, forKey: .wallet_address)
        exp = try container.decodeIfPresent(Date.self, forKey: .exp)
    }

    // Alternative coding keys for JWT token format
    private enum AlternativeCodingKeys: String, CodingKey {
        case sub
    }
}

// MARK: - Auth State

enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(UserInfo)
    case error(Error)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.user_id == rhsUser.user_id
        case (.error, .error):
            // Consider errors equal for UI purposes
            return true
        default:
            return false
        }
    }
}

// MARK: - Auth Error

enum AuthError: Error, LocalizedError {
    case invalidSignature
    case challengeExpired
    case networkError(Error)
    case invalidResponse
    case walletNotAvailable

    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            return "Invalid signature"
        case .challengeExpired:
            return "Authentication challenge expired"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .walletNotAvailable:
            return "Wallet not available"
        }
    }
}
