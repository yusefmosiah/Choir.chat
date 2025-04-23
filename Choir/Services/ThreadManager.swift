import Foundation
import SwiftUI
import UIKit

/// Manages threads across wallets
class ThreadManager: ObservableObject {
    /// Published threads for the current wallet
    @Published var threads: [ChoirThread] = []

    /// Current wallet address
    @Published var currentWalletAddress: String?

    /// Persistence service
    let persistenceService = ThreadPersistenceService.shared

    /// Initialize with optional wallet address
    init(walletAddress: String? = nil) {
        self.currentWalletAddress = walletAddress
        loadThreads()
    }

    /// Load threads for the current wallet
    func loadThreads() {
        print("ThreadManager: Loading threads for wallet address: \(currentWalletAddress ?? "nil")")

        // Load threads for the current wallet
        let loadedThreads = persistenceService.loadAllThreads(walletAddress: currentWalletAddress)
        print("ThreadManager: Loaded \(loadedThreads.count) threads")

        // Debug print thread details
        for thread in loadedThreads {
            print("ThreadManager: Thread \(thread.id) with wallet address: \(thread.walletAddress ?? "nil"), title: \(thread.title)")
        }

        // Sort threads by creation date (newest first)
        let sortedThreads = loadedThreads.sorted { $0.createdAt > $1.createdAt }

        // Update the published property
        self.threads = sortedThreads
    }

    /// Switch to a different wallet
    func switchWallet(to walletAddress: String?) {
        print("Switching wallet from \(currentWalletAddress ?? "nil") to \(walletAddress ?? "nil")")
        currentWalletAddress = walletAddress
        loadThreads()
    }

    /// Create a new thread
    func createThread(title: String? = nil) -> ChoirThread {
        let thread = ChoirThread(title: title, walletAddress: currentWalletAddress)
        persistenceService.saveThread(thread)
        threads.append(thread)
        return thread
    }

    /// Delete a thread
    func deleteThread(_ thread: ChoirThread) {
        persistenceService.deleteThread(threadId: thread.id, walletAddress: thread.walletAddress)
        if let index = threads.firstIndex(of: thread) {
            threads.remove(at: index)
        }
    }

    /// Export threads as JSON data
    func exportThreads(walletAddress: String? = nil) -> Data? {
        let threadsToExport: [ChoirThread]
        let exportType: String
        let walletName: String?

        if let walletAddress = walletAddress {
            // Export threads for a specific wallet
            threadsToExport = persistenceService.loadAllThreads(walletAddress: walletAddress)
            exportType = "single_wallet"
            walletName = getWalletName(for: walletAddress)
        } else if let currentWallet = currentWalletAddress {
            // Export threads for the current wallet
            threadsToExport = persistenceService.loadAllThreads(walletAddress: currentWallet)
            exportType = "current_wallet"
            walletName = getWalletName(for: currentWallet)
        } else {
            // Export all threads
            threadsToExport = persistenceService.loadAllThreads()
            exportType = "all_wallets"
            walletName = nil
        }

        // Count total messages
        let totalMessageCount = threadsToExport.reduce(0) { $0 + $1.messages.count }

        // Find oldest and newest thread dates
        let oldestThreadDate = threadsToExport.min { $0.createdAt < $1.createdAt }?.createdAt
        let newestThreadDate = threadsToExport.max { $0.lastModified < $1.lastModified }?.lastModified

        // Collect model information
        var modelProviders = Set<String>()
        var modelNames = Set<String>()

        for thread in threadsToExport {
            for message in thread.messages {
                for phase in Phase.allCases {
                    if let result = message.getPhaseResult(phase) {
                        if let provider = result.provider {
                            modelProviders.insert(provider)
                        }
                        if let modelName = result.modelName {
                            modelNames.insert(modelName)
                        }
                    }
                }
            }
        }

        // Get app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        // Create descriptive export text
        let exportDescription = createExportDescription(
            threadCount: threadsToExport.count,
            messageCount: totalMessageCount,
            walletName: walletName,
            exportType: exportType
        )

        // Create export data structure
        let now = Date()
        let exportData = ThreadExportData(
            exportDate: now,
            exportTimestamp: now.timeIntervalSince1970,
            deviceName: UIDevice.current.name,
            deviceModel: UIDevice.current.model,
            appVersion: appVersion,
            walletAddress: walletAddress ?? currentWalletAddress,
            walletName: walletName,
            exportType: exportType,
            threadCount: threadsToExport.count,
            totalMessageCount: totalMessageCount,
            oldestThreadDate: oldestThreadDate,
            newestThreadDate: newestThreadDate,
            threads: threadsToExport.map { ThreadData(from: $0) },
            modelProviders: Array(modelProviders),
            modelNames: Array(modelNames),
            exportDescription: exportDescription
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(exportData)
        } catch {
            print("Error exporting threads: \(error)")
            return nil
        }
    }

    /// Get wallet name for a given address
    private func getWalletName(for address: String) -> String? {
        // This would typically come from the WalletManager
        // For now, we'll just return a placeholder
        return "Wallet \(address.prefix(4))...\(address.suffix(4))"
    }

    /// Create a descriptive export summary
    private func createExportDescription(threadCount: Int, messageCount: Int, walletName: String?, exportType: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: Date())

        // App version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        var description = "Choir Thread Export - \(dateString)\n"
        description += "App Version: \(appVersion) (\(buildNumber))\n"
        description += "\(threadCount) thread\(threadCount == 1 ? "" : "s"), "
        description += "\(messageCount) message\(messageCount == 1 ? "" : "s")\n"

        if let walletName = walletName {
            description += "Wallet: \(walletName)\n"
        } else if exportType == "all_wallets" {
            description += "All wallets\n"
        }

        description += "Device: \(UIDevice.current.name) (\(UIDevice.current.model))\n"
        description += "OS Version: \(UIDevice.current.systemVersion)\n"
        description += "Export Type: \(exportType.replacingOccurrences(of: "_", with: " ").capitalized)"

        return description
    }

    /// Import threads from JSON data
    func importThreads(from data: Data) -> Int {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importData = try decoder.decode(ThreadExportData.self, from: data)

            var importedCount = 0
            var importedThreads: [ChoirThread] = []

            for threadData in importData.threads {
                let thread = threadData.toChoirThread()

                // Always import threads to the current wallet
                // This is the key change - we always use the current wallet address
                // regardless of what wallet the thread was originally from
                thread.walletAddress = currentWalletAddress

                // Print original wallet info for debugging
                let originalWalletAddress = threadData.walletAddress
                print("Original thread wallet: \(originalWalletAddress ?? "nil"), importing to: \(currentWalletAddress ?? "nil")")

                // If we don't have a current wallet, we can't import the thread
                if currentWalletAddress == nil {
                    print("WARNING: No current wallet selected, thread will be imported to default wallet")
                }

                // Print debug info
                print("Importing thread \(thread.id) with wallet address: \(thread.walletAddress ?? "nil")")

                // Save the thread to the appropriate wallet directory
                persistenceService.saveThread(thread)
                importedThreads.append(thread)
                importedCount += 1
            }

            // Print summary of imported threads
            print("Imported \(importedCount) threads")
            print("Current wallet address: \(currentWalletAddress ?? "nil")")

            // Count threads imported to current wallet
            let currentWalletThreads = importedThreads.filter { $0.walletAddress == currentWalletAddress }
            print("Threads imported to current wallet: \(currentWalletThreads.count)")

            // Reload all threads to ensure the UI is updated
            loadThreads()

            // Print thread count after reload
            print("Thread count after reload: \(threads.count)")

            // If we imported threads for the current wallet, make sure they're sorted properly
            if !currentWalletThreads.isEmpty {
                // Sort threads by creation date (newest first)
                threads.sort { $0.createdAt > $1.createdAt }
                print("Sorted \(threads.count) threads by creation date")
            }

            return importedCount
        } catch {
            print("Error importing threads: \(error)")
            return 0
        }
    }
}

/// Data structure for thread export
struct ThreadExportData: Codable {
    // Export metadata
    let exportDate: Date
    let exportTimestamp: TimeInterval
    let deviceName: String
    let deviceModel: String
    let appVersion: String
    let osVersion: String = UIDevice.current.systemVersion

    // Wallet information
    let walletAddress: String?
    let walletName: String?
    let exportType: String // "single_wallet", "all_wallets", etc.

    // Thread data
    let threadCount: Int
    let totalMessageCount: Int
    let oldestThreadDate: Date?
    let newestThreadDate: Date?
    let threads: [ThreadData]

    // Model information
    let modelProviders: [String]
    let modelNames: [String]

    // Export description for display
    let exportDescription: String
}
