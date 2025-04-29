//
//  PushNotificationManager.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import Foundation
import UserNotifications
import UIKit

class PushNotificationManager: NSObject, ObservableObject {
    @Published var deviceToken: String?
    @Published var isRegistered: Bool = false

    static let shared = PushNotificationManager()

    private override init() {
        super.init()
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else {
                print("Permission for notifications was denied")
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func updateDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        self.isRegistered = true

        print("Device Token: \(token)")

        // Send the token to the server
        sendDeviceTokenToServer(token)
    }

    func sendDeviceTokenToServer(_ token: String) {
        Task {
            do {
                // Get the wallet manager
                let walletManager = await WalletManager.shared

                // Check if we have a wallet
                guard let wallet = await walletManager.wallet,
                      let walletAddress = try? wallet.accounts[0].address() else {
                    print("No wallet address available, cannot register device token")
                    return
                }

                let request = DeviceTokenRegistrationRequest(deviceToken: token, walletAddress: walletAddress)

                // Initialize the API client
                let baseURL = ApiConfig.baseURL
                let apiClient = await APIClient(baseURL: baseURL, authService: AuthService.shared)

                // Send the request
                let response: APIResponse<DeviceTokenRegistrationResponse> = try await apiClient.post(
                    endpoint: request.endpoint,
                    body: request
                )

                if response.success {
                    print("Successfully registered device token with server")
                } else {
                    print("Failed to register device token: \(response.message ?? "Unknown error")")
                }
            } catch {
                print("Error registering device token: \(error)")
            }
        }
    }

    func handleNotificationReceived(userInfo: [AnyHashable: Any]) {
        print("Received notification: \(userInfo)")

        // Process the notification data
        guard let aps = userInfo["aps"] as? [String: Any] else {
            print("No aps dictionary in notification")
            return
        }

        // Get notification type
        let notificationType = (userInfo["notification_type"] as? String) ?? "unknown"

        // Get vector ID if available
        let vectorId = (userInfo["vector_id"] as? String) ?? ""

        // Get citing wallet address if available
        let citingWalletAddress = (userInfo["citing_wallet_address"] as? String) ?? ""

        print("Notification type: \(notificationType)")

        // Handle different notification types
        switch notificationType {
        case "citation":
            print("Citation notification received for vector: \(vectorId)")

            // Extract alert information if available
            var title = "Your content was cited!"
            var body = "Someone cited your content"

            if let alert = aps["alert"] as? [String: Any] {
                if let alertTitle = alert["title"] as? String {
                    title = alertTitle
                }
                if let alertBody = alert["body"] as? String {
                    body = alertBody
                }
            }

            // Post a notification to update the UI with more details
            NotificationCenter.default.post(
                name: NSNotification.Name("CitationReceived"),
                object: nil,
                userInfo: [
                    "vector_id": vectorId,
                    "citing_wallet_address": citingWalletAddress,
                    "title": title,
                    "body": body
                ]
            )

            // Update badge count
            if let badgeCount = aps["badge"] as? Int {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = badgeCount
                }
            }

        case "test":
            print("Test notification received")

            // Show a local notification for test purposes
            if let alert = aps["alert"] as? [String: Any],
               let title = alert["title"] as? String,
               let body = alert["body"] as? String {
                showLocalNotification(title: title, body: body)
            }

        default:
            print("Unknown notification type: \(notificationType)")
        }

        // Refresh notifications in the app
        NotificationCenter.default.post(name: NSNotification.Name("RefreshNotifications"), object: nil)
    }

    // Helper method to show a local notification for testing
    private func showLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing local notification: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle foreground notifications
        let userInfo = notification.request.content.userInfo
        handleNotificationReceived(userInfo: userInfo)

        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification response when user taps on the notification
        let userInfo = response.notification.request.content.userInfo
        handleNotificationReceived(userInfo: userInfo)

        // Handle different actions based on the response action identifier
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            print("User tapped the notification")

            // If this is a citation notification, navigate to the vector
            if let notificationType = userInfo["notification_type"] as? String,
               notificationType == "citation",
               let vectorId = userInfo["vector_id"] as? String {
                // Post a notification to navigate to the vector
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToVector"),
                    object: nil,
                    userInfo: ["vector_id": vectorId]
                )
            }

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("User dismissed the notification")

        default:
            // Handle any custom actions
            print("User performed custom action: \(response.actionIdentifier)")
        }

        completionHandler()
    }
}
