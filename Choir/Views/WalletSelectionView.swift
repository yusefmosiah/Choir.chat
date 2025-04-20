import SwiftUI

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
            List {
                Section(header: Text("Your Wallets")) {
                    ForEach(Array(walletManager.wallets.keys), id: \.self) { address in
                        Button(action: {
                            selectWallet(address: address)
                        }) {
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
                                
                                if let currentWallet = walletManager.wallet,
                                   let currentAddress = try? currentWallet.accounts[0].address(),
                                   currentAddress == address {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteWallet(address: address)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: { showingCreateSheet = true }) {
                        Label("Create New Wallet", systemImage: "plus.circle")
                    }
                    
                    Button(action: { showingImportSheet = true }) {
                        Label("Import Wallet from Mnemonic", systemImage: "square.and.arrow.down")
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
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
                
                Button("Create") {
                    createNewWallet()
                }
            } message: {
                Text("Enter a name for your new wallet")
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
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

#Preview {
    WalletSelectionView()
        .environmentObject(WalletManager())
}
