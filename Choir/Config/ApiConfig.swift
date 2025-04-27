//
//  ApiConfig.swift
//  Choir
//
//  Created by Augment on 4/18/24.
//

import Foundation

/// API configuration for the Choir app
struct ApiConfig {
    // MARK: - Base URL Configuration

    #if DEBUG && targetEnvironment(simulator)
    // Use localhost for simulator
    static let baseURLString = "http://localhost:8000"
    #else
    // Use production URL for physical devices and release builds
    static let baseURLString = "https://choir-chat.onrender.com"
    #endif

    // Computed URL property
    static let baseURL = URL(string: baseURLString)!

    // MARK: - API Endpoints

    struct Endpoints {
        // Auth endpoints
        static let challenge = "api/auth/challenge"
        static let login = "api/auth/login"
        static let me = "api/auth/me"

        // Postchain endpoints
        static let postchainBase = "api/postchain"
        static let postchainLangchain = "api/postchain/langchain"

        // User endpoints
        static let users = "api/users"

        // Thread endpoints
        static let threads = "api/threads"

        // Vector endpoints
        static let vectors = "api/vectors"

        // Notifications endpoints
        static let notifications = "api/notifications"
    }

    // MARK: - Helper Methods

    /// Creates a full URL for a given endpoint
    /// - Parameter endpoint: The API endpoint path
    /// - Returns: A complete URL
    static func url(for endpoint: String) -> URL {
        return baseURL.appendingPathComponent(endpoint)
    }
}
