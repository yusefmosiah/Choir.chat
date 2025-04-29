//
//  AppDelegate.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    // Track app state for SwiftUI views
    @Published var isInBackground = false

    // Background task identifier for app suspension
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // Background task identifiers
    private let postchainProcessingTaskId = "com.choir.postchain.processing"
    private let backgroundFetchTaskId = "com.choir.app.backgroundfetch"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for push notifications
        Task {
            // Delay slightly to ensure everything is initialized
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            PushNotificationManager.shared.registerForPushNotifications()
        }

        // Register for background fetch
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        // Register background tasks
        registerBackgroundTasks()

        return true
    }

    // Register background tasks with the system
    private func registerBackgroundTasks() {
        // Register the background processing task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: postchainProcessingTaskId, using: nil) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }

        // Register the background fetch task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundFetchTaskId, using: nil) { task in
            self.handleBackgroundFetch(task: task as! BGAppRefreshTask)
        }

        print("Registered background tasks with BGTaskScheduler")
    }

    // Handle background processing task
    private func handleBackgroundProcessing(task: BGProcessingTask) {
        print("Background processing task started")

        // Schedule the next background task
        scheduleBackgroundProcessing()

        // Create a task assertion to track when processing is complete
        let processingComplete = task.expirationHandler
        task.expirationHandler = nil

        // Set up a task that will be called when processing is complete
        task.expirationHandler = {
            print("Background processing task is about to expire")
            processingComplete?()
        }

        // Mark the task complete when done
        // This would normally be called after your actual processing is done
        task.setTaskCompleted(success: true)
    }

    // Handle background fetch task
    private func handleBackgroundFetch(task: BGAppRefreshTask) {
        print("Background fetch task started")

        // Schedule the next background fetch
        scheduleBackgroundFetch()

        // Mark the task complete when done
        task.setTaskCompleted(success: true)
    }

    // Schedule the next background processing task
    private func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: postchainProcessingTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled next background processing task")
        } catch {
            print("Could not schedule background processing: \(error)")
        }
    }

    // Schedule the next background fetch task
    private func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundFetchTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled next background fetch task")
        } catch {
            print("Could not schedule background fetch: \(error)")
        }
    }

    // Called when the app is about to move from active to inactive state
    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
    }

    // Called when the app enters the background
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter background")
        isInBackground = true

        // Begin a background task to keep the app running longer
        backgroundTaskID = application.beginBackgroundTask(withName: "AppSuspensionTask") { [weak self] in
            // This is called if the background task is about to be terminated
            print("Background task is about to expire")
            self?.endBackgroundTask()
        }

        print("Started background task with ID: \(backgroundTaskID.rawValue)")

        // Schedule background tasks
        scheduleBackgroundProcessing()
        scheduleBackgroundFetch()
    }

    // Called when the app is about to enter the foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        isInBackground = false

        // End the background task if it's still active
        endBackgroundTask()
    }

    // Called when the app becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App did become active")
        isInBackground = false
    }

    // Called when the app is about to terminate
    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")

        // End all background tasks
        BackgroundTaskManager.shared.endAllTasks()
        endBackgroundTask()
    }

    // Handle background fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Background fetch triggered")

        // For now, just report no new data
        // This could be enhanced to check for updates or continue processing
        completionHandler(.noData)
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

    // Helper method to end the background task
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            print("Ended background task")
        }
    }
}
