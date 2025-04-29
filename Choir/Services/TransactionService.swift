//
//  TransactionService.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import Foundation
import Combine

/// Model for transaction information
struct TransactionInfo: Identifiable, Codable {
    let id: String
    let type: String
    let senderAddress: String
    let recipientAddress: String
    let amount: Double
    let timestamp: String
    let status: String
    let details: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case senderAddress = "sender_address"
        case recipientAddress = "recipient_address"
        case amount
        case timestamp
        case status
        case details
    }
}

/// Service for handling transactions in the app
@MainActor
class TransactionService: ObservableObject {
    @Published var transactions: [TransactionInfo] = []
    @Published var unreadCount: Int = 0

    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize the API client with the base URL and auth service
        let baseURL = ApiConfig.baseURL
        self.apiClient = APIClient(baseURL: baseURL, authService: AuthService.shared)
    }

    /// Fetch transactions for a specific wallet address or all wallets
    func fetchTransactions(walletAddress: String? = nil) {
        Task {
            do {
                // Build the endpoint with optional wallet address parameter
                var endpoint = ApiConfig.Endpoints.notifications
                if let walletAddress = walletAddress {
                    endpoint += "?wallet_address=\(walletAddress)"
                }

                let response: APIResponse<NotificationsResponse> = try await apiClient.get(endpoint: endpoint)

                // Update on the main thread
                await MainActor.run {
                    if response.success, let data = response.data {
                        // Convert notifications to transactions
                        self.transactions = data.notifications.map { notification in
                            TransactionInfo(
                                id: notification.id,
                                type: mapNotificationType(notification.type),
                                senderAddress: notification.senderWalletAddress,
                                recipientAddress: notification.recipientWalletAddress,
                                amount: 5.0, // Placeholder amount
                                timestamp: notification.createdAt,
                                status: "Completed",
                                details: [
                                    "vectorId": notification.vectorId,
                                    "read": notification.read ? "true" : "false"
                                ]
                            )
                        }

                        // Sort transactions by timestamp (newest first)
                        self.transactions.sort {
                            $0.timestamp > $1.timestamp
                        }

                        // Update unread count for badge
                        self.unreadCount = data.notifications.filter { !$0.read }.count
                    }
                }
            } catch {
                print("Error fetching transactions: \(error)")
            }
        }
    }

    /// Mark a transaction as read
    func markAsRead(transactionId: String) {
        Task {
            do {
                // For now, we'll use the notifications endpoint
                let endpoint = "\(ApiConfig.Endpoints.notifications)/\(transactionId)/read"
                let response: APIResponse<EmptyResponse> = try await apiClient.post(endpoint: endpoint, body: EmptyRequest())

                // Update on the main thread
                await MainActor.run {
                    if response.success {
                        // Update local state
                        if let index = self.transactions.firstIndex(where: { $0.id == transactionId }) {
                            var updatedTransaction = self.transactions[index]
                            var updatedDetails = updatedTransaction.details ?? [:]
                            updatedDetails["read"] = "true"

                            // Create a new transaction with read = true
                            let newTransaction = TransactionInfo(
                                id: updatedTransaction.id,
                                type: updatedTransaction.type,
                                senderAddress: updatedTransaction.senderAddress,
                                recipientAddress: updatedTransaction.recipientAddress,
                                amount: updatedTransaction.amount,
                                timestamp: updatedTransaction.timestamp,
                                status: updatedTransaction.status,
                                details: updatedDetails
                            )

                            // Replace the transaction in the array
                            self.transactions[index] = newTransaction

                            // Update unread count
                            self.unreadCount = max(0, self.unreadCount - 1)
                        }
                    }
                }
            } catch {
                print("Error marking transaction as read: \(error)")
            }
        }
    }

    /// Map notification type to transaction type
    private func mapNotificationType(_ type: String) -> String {
        switch type {
        case "citation":
            return "citation"
        case "self_citation":
            return "self_citation"
        default:
            return "other"
        }
    }
}

// MARK: - API Response Models

/// Model for a notification (used for backward compatibility with API)
struct ChoirNotification: Identifiable, Codable {
    let id: String
    let type: String
    let recipientWalletAddress: String
    let senderWalletAddress: String
    let vectorId: String
    let read: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case recipientWalletAddress = "recipient_wallet_address"
        case senderWalletAddress = "sender_wallet_address"
        case vectorId = "vector_id"
        case read
        case createdAt = "created_at"
    }
}

/// Response model for notifications (used for backward compatibility with API)
struct NotificationsResponse: Codable {
    let notifications: [ChoirNotification]
}

/// Response model for transactions
struct TransactionsResponse: Codable {
    let transactions: [TransactionInfo]
}

/// Empty response for mark as read
struct EmptyResponse: Codable {}

/// Empty request for mark as read
struct EmptyRequest: Codable {}
