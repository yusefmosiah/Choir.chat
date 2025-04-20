import SwiftUI

struct ThreadExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var threadManager: ThreadManager
    @EnvironmentObject var walletManager: WalletManager

    @State private var exportType = ExportType.currentWallet
    @State private var isExporting = false
    @State private var exportData: Data?
    @State private var errorMessage: String?

    enum ExportType: String, CaseIterable, Identifiable {
        case currentWallet = "Current Wallet"
        case allWallets = "All Wallets"
        case specificWallet = "Specific Wallet"

        var id: String { self.rawValue }
    }

    @State private var selectedWalletAddress: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Options"), footer: Text("Exported threads can be imported to any wallet.")) {
                    Picker("Export Type", selection: $exportType) {
                        ForEach(ExportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if exportType == .specificWallet {
                        Picker("Select Wallet", selection: $selectedWalletAddress) {
                            ForEach(Array(walletManager.wallets.keys), id: \.self) { address in
                                HStack {
                                    Text(walletManager.walletNames[address] ?? "Unnamed Wallet")
                                    Spacer()
                                    Text(address.prefix(6) + "..." + address.suffix(4))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(address as String?)
                            }
                        }
                    }
                }

                Section(header: Text("Export Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        switch exportType {
                        case .currentWallet:
                            if let currentWallet = threadManager.currentWalletAddress {
                                let threads = threadManager.threads
                                let count = threads.count
                                let messageCount = threads.reduce(0) { $0 + $1.messages.count }

                                Text("\(count) thread\(count == 1 ? "" : "s") in current wallet")
                                    .font(.headline)
                                Text("\(messageCount) message\(messageCount == 1 ? "" : "s") total")

                                if let walletName = walletManager.walletNames[currentWallet] {
                                    Text("Wallet: \(walletName)")
                                }
                                Text("Address: \(currentWallet.prefix(6))...\(currentWallet.suffix(4))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No wallet selected")
                            }

                        case .allWallets:
                            let threads = threadManager.persistenceService.loadAllThreads()
                            let count = threads.count
                            let messageCount = threads.reduce(0) { $0 + $1.messages.count }

                            Text("\(count) thread\(count == 1 ? "" : "s") across all wallets")
                                .font(.headline)
                            Text("\(messageCount) message\(messageCount == 1 ? "" : "s") total")

                            let walletCount = Set(threads.compactMap { $0.walletAddress }).count
                            Text("\(walletCount) wallet\(walletCount == 1 ? "" : "s") included")

                        case .specificWallet:
                            if let selectedWallet = selectedWalletAddress {
                                let threads = threadManager.persistenceService.loadAllThreads(walletAddress: selectedWallet)
                                let count = threads.count
                                let messageCount = threads.reduce(0) { $0 + $1.messages.count }

                                Text("\(count) thread\(count == 1 ? "" : "s") in selected wallet")
                                    .font(.headline)
                                Text("\(messageCount) message\(messageCount == 1 ? "" : "s") total")

                                if let walletName = walletManager.walletNames[selectedWallet] {
                                    Text("Wallet: \(walletName)")
                                }
                                Text("Address: \(selectedWallet.prefix(6))...\(selectedWallet.suffix(4))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No wallet selected")
                            }
                        }

                        // Show device and app info
                        Divider()
                        Text("Device: \(UIDevice.current.name)")
                            .font(.caption)

                        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text("App Version: \(appVersion) (\(buildNumber))")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(action: exportThreads) {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Export Threads")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting || (exportType == .specificWallet && selectedWalletAddress == nil))
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Export Threads")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: Binding<Bool>(
                get: { exportData != nil },
                set: { if !$0 { exportData = nil } }
            )) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            .onAppear {
                // Set default selected wallet if needed
                if exportType == .specificWallet && selectedWalletAddress == nil {
                    selectedWalletAddress = walletManager.wallets.keys.first
                }
            }
        }
    }

    private func exportThreads() {
        isExporting = true
        errorMessage = nil

        Task {
            // Determine which wallet to export
            let walletToExport: String?

            switch exportType {
            case .currentWallet:
                walletToExport = threadManager.currentWalletAddress
            case .allWallets:
                walletToExport = nil
            case .specificWallet:
                walletToExport = selectedWalletAddress
            }

            // Try to export the threads
            if let exportData = threadManager.exportThreads(walletAddress: walletToExport) {
                await MainActor.run {
                    self.exportData = exportData
                    isExporting = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to export threads"
                    isExporting = false
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // If we have data, create a temporary file with a descriptive name
        if let data = items.first as? Data {
            do {
                // Try to decode the export data to get metadata for the filename
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let exportData = try? decoder.decode(ThreadExportData.self, from: data) {
                    // Create a descriptive filename
                    let filename = createDescriptiveFilename(from: exportData)
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

                    // Write the data to the temporary file with proper permissions
                    try data.write(to: tempURL, options: [.atomic])

                    // Ensure the file has proper permissions
                    try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: tempURL.path)

                    // Return a controller with the file URL
                    let controller = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    return controller
                }
            } catch {
                print("Error creating temporary file: \(error)")
            }
        }

        // Fallback to sharing the raw data
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    private func createDescriptiveFilename(from exportData: ThreadExportData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: exportData.exportDate)

        var filename = "choir_threads_\(dateString)"

        // Add thread count
        filename += "_\(exportData.threadCount)threads"

        // Add wallet info if available
        if let walletName = exportData.walletName {
            // Clean up wallet name for filename
            let cleanName = walletName
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)

            filename += "_\(cleanName)"
        } else if exportData.exportType == "all_wallets" {
            filename += "_all_wallets"
        }

        // Add extension
        filename += ".json"

        return filename
    }
}

#Preview {
    ThreadExportView()
        .environmentObject(ThreadManager())
        .environmentObject(WalletManager())
}
