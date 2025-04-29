//
//  BackgroundTaskManager.swift
//  Choir
//
//  Created by Augment on 4/28/25.
//

import Foundation
import UIKit
import BackgroundTasks

/// Manages background tasks to ensure operations continue when the app is in the background
class BackgroundTaskManager {
    // Singleton instance
    static let shared = BackgroundTaskManager()

    // Dictionary to track active background tasks
    private var backgroundTasks: [String: UIBackgroundTaskIdentifier] = [:]

    // Lock for thread safety
    private let lock = NSLock()

    private init() {}

    /// Begin a background task with a specific identifier
    /// - Parameters:
    ///   - identifier: A unique identifier for the task
    ///   - expirationHandler: Optional handler to be called if the task is about to expire
    /// - Returns: True if the task was successfully started
    @discardableResult
    func beginTask(identifier: String, expirationHandler: (() -> Void)? = nil) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // Check if a task with this identifier already exists
        if let existingTask = backgroundTasks[identifier], existingTask != .invalid {
            print("Background task already exists for identifier: \(identifier)")
            return true
        }

        // Create a new background task
        let taskID = UIApplication.shared.beginBackgroundTask(withName: identifier) { [weak self] in
            // This is the expiration handler that will be called if the task runs too long
            print("Background task is expiring: \(identifier)")

            // Call the provided expiration handler if any
            expirationHandler?()

            // End the task
            self?.endTask(identifier: identifier)
        }

        // Check if the task was successfully created
        if taskID == .invalid {
            print("Failed to start background task: \(identifier)")
            return false
        }

        // Store the task ID
        backgroundTasks[identifier] = taskID
        print("Started background task: \(identifier) with ID: \(taskID.rawValue)")

        // Also schedule a BGProcessingTask if this is a long-running task
        if identifier.contains("processing") {
            scheduleBackgroundProcessing(identifier: identifier)
        }

        return true
    }

    /// End a background task with the specified identifier
    /// - Parameter identifier: The identifier of the task to end
    func endTask(identifier: String) {
        lock.lock()
        defer { lock.unlock() }

        // Check if the task exists
        guard let taskID = backgroundTasks[identifier], taskID != .invalid else {
            print("No valid background task found for identifier: \(identifier)")
            return
        }

        // End the task
        UIApplication.shared.endBackgroundTask(taskID)
        print("Ended background task: \(identifier) with ID: \(taskID.rawValue)")

        // Remove the task from the dictionary
        backgroundTasks[identifier] = .invalid
        backgroundTasks.removeValue(forKey: identifier)
    }

    /// End all active background tasks
    func endAllTasks() {
        lock.lock()
        defer { lock.unlock() }

        // End each task
        for (identifier, taskID) in backgroundTasks where taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
            print("Ended background task: \(identifier) with ID: \(taskID.rawValue)")
        }

        // Clear the dictionary
        backgroundTasks.removeAll()
    }

    /// Schedule a background processing task with BGTaskScheduler
    /// - Parameter identifier: The identifier for the task
    private func scheduleBackgroundProcessing(identifier: String) {
        // Only proceed if the identifier is in our permitted list
        guard identifier == "com.choir.postchain.processing" else {
            return
        }

        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled background processing task: \(identifier)")
        } catch {
            print("Could not schedule background processing: \(error)")
        }
    }
}
