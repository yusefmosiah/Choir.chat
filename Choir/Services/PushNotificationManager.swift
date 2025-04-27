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
        // This could include updating the UI, storing the notification, etc.
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

        completionHandler()
    }
}
