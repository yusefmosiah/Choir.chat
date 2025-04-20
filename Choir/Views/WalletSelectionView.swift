import SwiftUI

// MARK: - WalletSelectionView
struct WalletSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingImportSheet = false
    @State private var showingCreateSheet = false
    @State private var newWalletName = "New Wallet"

    var body: some View {
        NavigationView {
            VStack {
                walletListView
            }
            .navigationTitle("Select Wallet")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .refreshable {
                await walletManager.loadAllWallets()
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportMnemonicView()
                    .environmentObject(walletManager)
            }
            .alert("Create New Wallet", isPresented: $showingCreateSheet) {
                TextField("Wallet Name", text: $newWalletName)
                Button("Cancel", role: .cancel) { }
                Button("Create") { createNewWallet() }
            } message: {
                Text("Enter a name for your new wallet")
            }
            .overlay {
                if isLoading {
                    LoadingOverlayView()
                }
            }
        }
    }

    // MARK: - Wallet List View
    private var walletListView: some View {
        List {
            // Wallets Section
            Section(header: Text("Your Wallets")) {
                ForEach(walletManager.getSortedWalletAddresses(), id: \.self) { address in
                    WalletRowView(
                        address: address,
                        walletManager: walletManager,
                        onSelect: { selectWallet(address: address) },
                        onDelete: { deleteWallet(address: address) }
                    )
                }
            }

            // Actions Section
            Section {
                WalletActionsView(
                    onCreateWallet: { showingCreateSheet = true },
                    onImportWallet: { showingImportSheet = true }
                )
            }

            // Error Section (if any)
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func selectWallet(address: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await walletManager.switchWallet(address: address)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func deleteWallet(address: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await walletManager.deleteWallet(address: address)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func createNewWallet() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await walletManager.createOrLoadWallet(name: newWalletName)
                await MainActor.run {
                    isLoading = false
                    newWalletName = "New Wallet"
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Subviews

// Wallet Row View
struct WalletRowView: View {
    let address: String
    @ObservedObject var walletManager: WalletManager
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(walletManager.walletNames[address] ?? "Unnamed Wallet")
                        .font(.headline)

                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                if isCurrentWallet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var isCurrentWallet: Bool {
        if let currentWallet = walletManager.wallet,
           let currentAddress = try? currentWallet.accounts[0].address() {
            return currentAddress == address
        }
        return false
    }
}

// Wallet Actions View
struct WalletActionsView: View {
    let onCreateWallet: () -> Void
    let onImportWallet: () -> Void

    var body: some View {
        Button(action: onCreateWallet) {
            Label("Create New Wallet", systemImage: "plus.circle")
        }

        Button(action: onImportWallet) {
            Label("Import Wallet from Mnemonic", systemImage: "square.and.arrow.down")
        }
    }
}

// Loading Overlay View
struct LoadingOverlayView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
    }
}

#Preview {
    WalletSelectionView()
        .environmentObject(WalletManager())
}
