//
//  AppDelegate.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for push notifications
        Task {
            // Delay slightly to ensure everything is initialized
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            PushNotificationManager.shared.registerForPushNotifications()
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward the token to our manager
        PushNotificationManager.shared.updateDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Process the notification
        PushNotificationManager.shared.handleNotificationReceived(userInfo: userInfo)

        // Indicate to the system that we've finished processing the notification
        completionHandler(.newData)
    }
}
