//
//  NotificationService.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import Foundation
import Combine

/// Model for a notification
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

/// Service for handling notifications in the app
@MainActor
class NotificationService: ObservableObject {
    @Published var notifications: [ChoirNotification] = []
    @Published var unreadCount: Int = 0

    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize the API client with the base URL and auth service
        let baseURL = ApiConfig.baseURL
        self.apiClient = APIClient(baseURL: baseURL, authService: AuthService.shared)
    }

    /// Fetch notifications for the current user
    func fetchNotifications() {
        Task {
            do {
                let endpoint = ApiConfig.Endpoints.notifications
                let response: APIResponse<NotificationsResponse> = try await apiClient.get(endpoint: endpoint)

                // Update on the main thread
                await MainActor.run {
                    if response.success, let data = response.data {
                        self.notifications = data.notifications
                        self.unreadCount = data.notifications.filter { !$0.read }.count
                    }
                }
            } catch {
                print("Error fetching notifications: \(error)")
            }
        }
    }

    /// Mark a notification as read
    func markAsRead(notificationId: String) {
        Task {
            do {
                let endpoint = "\(ApiConfig.Endpoints.notifications)/\(notificationId)/read"
                let response: APIResponse<EmptyResponse> = try await apiClient.post(endpoint: endpoint, body: EmptyRequest())

                // Update on the main thread
                await MainActor.run {
                    if response.success {
                        // Update local state
                        if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                            var updatedNotification = self.notifications[index]
                            // Create a new notification with read = true
                            let newNotification = ChoirNotification(
                                id: updatedNotification.id,
                                type: updatedNotification.type,
                                recipientWalletAddress: updatedNotification.recipientWalletAddress,
                                senderWalletAddress: updatedNotification.senderWalletAddress,
                                vectorId: updatedNotification.vectorId,
                                read: true,
                                createdAt: updatedNotification.createdAt
                            )
                            // Replace the notification in the array
                            self.notifications[index] = newNotification
                            // Update unread count
                            self.unreadCount = self.notifications.filter { !$0.read }.count
                        }
                    }
                }
            } catch {
                print("Error marking notification as read: \(error)")
            }
        }
    }
}

// MARK: - API Response Models

/// Response model for notifications
struct NotificationsResponse: Codable {
    let notifications: [ChoirNotification]
}

/// Empty response for mark as read
struct EmptyResponse: Codable {}

/// Empty request for mark as read
struct EmptyRequest: Codable {}
