import SwiftUI
import UniformTypeIdentifiers

struct ThreadImportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var threadManager: ThreadManager

    // Callback for when import is successful
    var onImportSuccess: ((Int) -> Void)? = nil

    @State private var isImporting = false
    @State private var showingDocumentPicker = false
    @State private var importResult: ImportResult?
    @State private var importToCurrentWallet = true

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    struct ImportResult {
        let success: Bool
        let message: String
        let count: Int
        let exportData: ThreadExportData?
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Import Threads")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 8) {
                    Text("Select a JSON file containing Choir threads to import.")
                        .multilineTextAlignment(.center)

                    if let currentWallet = threadManager.currentWalletAddress {
                        Text("Threads will be imported to the current wallet")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Current wallet: \(currentWallet.prefix(6))...\(currentWallet.suffix(4))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No wallet selected. Please select a wallet before importing.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                if let result = importResult {
                    VStack(spacing: 12) {
                        Image(systemName: result.success ? "checkmark.circle" : "xmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(result.success ? .green : .red)

                        Text(result.message)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        if result.success, let exportData = result.exportData {
                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Import Details:")
                                    .font(.subheadline)
                                    .fontWeight(.bold)

                                Text("\(exportData.threadCount) thread\(exportData.threadCount == 1 ? "" : "s"), \(exportData.totalMessageCount) message\(exportData.totalMessageCount == 1 ? "" : "s")")

                                if let walletName = exportData.walletName {
                                    Text("Originally from wallet: \(walletName)")
                                }

                                if let walletAddress = exportData.walletAddress {
                                    Text("Original address: \(walletAddress.prefix(6))...\(walletAddress.suffix(4))")
                                        .font(.caption)
                                }

                                if let currentWallet = threadManager.currentWalletAddress {
                                    Text("Imported to: \(currentWallet.prefix(6))...\(currentWallet.suffix(4))")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }

                                if !exportData.modelProviders.isEmpty {
                                    Text("Models: \(exportData.modelProviders.joined(separator: ", "))")
                                        .font(.caption)
                                }

                                Text("Exported: \(exportData.exportDate, formatter: dateFormatter)")
                                    .font(.caption)

                                Text("From: \(exportData.deviceName)")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Select JSON File")
                    }
                    .frame(minWidth: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isImporting || threadManager.currentWalletAddress == nil)

                if isImporting {
                    ProgressView("Importing...")
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Import Threads")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    contentTypes: [UTType.json],
                    onDocumentsPicked: { urls in
                        if let url = urls.first {
                            importThreadsFromURL(url)
                        }
                    }
                )
            }
        }
    }

    private func importThreadsFromURL(_ url: URL) {
        isImporting = true
        importResult = nil

        Task {
            do {
                // Start security-scoped resource access if needed
                var securityScopedResourceAccessed = false
                if url.startAccessingSecurityScopedResource() {
                    securityScopedResourceAccessed = true
                }

                // Ensure we stop accessing the resource when done
                defer {
                    if securityScopedResourceAccessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                // Copy the file to a temporary location with proper permissions
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("import_\(UUID().uuidString).json")
                try FileManager.default.copyItem(at: url, to: tempURL)

                // Read from the temporary file
                let data = try Data(contentsOf: tempURL)

                // Clean up the temporary file
                try? FileManager.default.removeItem(at: tempURL)

                // First decode the export data to get metadata
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let exportData = try decoder.decode(ThreadExportData.self, from: data)

                // Then import the threads
                let count = threadManager.importThreads(from: data)

                await MainActor.run {
                    if count > 0 {
                        // Create a success message that mentions the current wallet
                        var successMessage = "Successfully imported \(count) thread\(count == 1 ? "" : "s")"

                        if let currentWallet = threadManager.currentWalletAddress {
                            let shortWallet = "\(currentWallet.prefix(6))...\(currentWallet.suffix(4))"
                            successMessage += " to wallet \(shortWallet)"
                        }

                        importResult = ImportResult(
                            success: true,
                            message: successMessage,
                            count: count,
                            exportData: exportData
                        )

                        // Force a reload of threads in the ThreadManager (metadata only)
                        threadManager.loadThreads(metadataOnly: true)

                        // Call the success callback if provided
                        onImportSuccess?(count)

                        // Print debug info about the current wallet and threads
                        print("Current wallet address: \(threadManager.currentWalletAddress ?? "nil")")
                        print("Number of threads after import: \(threadManager.threads.count)")

                        // Auto-dismiss after a successful import after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            dismiss()
                        }
                    } else {
                        importResult = ImportResult(
                            success: false,
                            message: "No threads were imported",
                            count: 0,
                            exportData: exportData
                        )
                    }
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importResult = ImportResult(
                        success: false,
                        message: "Error: \(error.localizedDescription)",
                        count: 0,
                        exportData: nil
                    )
                    isImporting = false
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onDocumentsPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator

        // Set document picker mode to import
        picker.shouldShowFileExtensions = true

        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // The document picker gives us security-scoped URLs
            // We need to call startAccessingSecurityScopedResource before using them
            // This is handled in the importThreadsFromURL method
            parent.onDocumentsPicked(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled, do nothing
            print("Document picker was cancelled")
        }
    }
}

#Preview {
    ThreadImportView()
        .environmentObject(ThreadManager())
}
