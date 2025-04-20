import SwiftUI
import SuiKit
import UIKit
import LocalAuthentication

struct WalletView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var sendAmount: String = ""
    @State private var recipientAddress: String = ""
    @State private var showingSendSheet = false
    @State private var showingPrivateKeyAlert = false
    @State private var privateKeyMessage = ""

    var body: some View {
        NavigationStack {
            List {
            Section("Wallet") {
                if let wallet = walletManager.wallet {
                    HStack {
                        Text("Address")
                        Spacer()
                        if let address = try? wallet.accounts[0].address() {
                            Text(address)
                                .textSelection(.enabled)
                        } else {
                            Text("Error getting address")
                                .foregroundColor(.red)
                        }
                    }

                    HStack {
                        Text("Balance")
                        Spacer()
                        Text(String(format: "%.9f SUI", walletManager.balance))
                    }

                    Button("Request Testnet SUI") {
                        Task {
                            try? await walletManager.requestAirdrop()
                        }
                    }
                    .disabled(walletManager.isLoading)

                    Button("Send SUI") {
                        showingSendSheet = true
                    }
                    .disabled(walletManager.isLoading)

                    Button("Export Private Key") {
                        Task {
                            await exportPrivateKey()
                        }
                    }
                    .disabled(walletManager.isLoading)
                } else {
                    Button("Create Wallet") {
                        Task {
                            try? await walletManager.createOrLoadWallet()
                        }
                    }
                    .disabled(walletManager.isLoading)
                }
            }
        }
        .sheet(isPresented: $showingSendSheet) {
            SendSuiView(walletManager: walletManager)
        }
        .task {
            if walletManager.wallet == nil {
                try? await walletManager.createOrLoadWallet()
            }
        }
        .refreshable {
            if let wallet = walletManager.wallet {
                try? await walletManager.updateBalance(for: wallet)
            }
        }
        .alert("Error", isPresented: .constant(walletManager.error != nil)) {
            Button("OK") {
                walletManager.error = nil
            }
        } message: {
            if let error = walletManager.error {
                Text(error.localizedDescription)
            }
        }
        .alert("Private Key", isPresented: $showingPrivateKeyAlert) {
            Button("Copy to Clipboard") {
                UIPasteboard.general.string = privateKeyMessage
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(privateKeyMessage)
        }
        .navigationTitle("Wallet")
        }
    }

    private func exportPrivateKey() async {
        await MainActor.run {
            do {
                // Get the mnemonic from the keychain with biometric authentication
                if let mnemonic = try walletManager.keychain.load(
                    "sui_wallet_mnemonic",
                    withPrompt: "Authenticate to export your private key",
                    requireBiometric: true
                ) {
                    privateKeyMessage = "Your mnemonic phrase (keep this secret):\n\n\(mnemonic)"
                } else {
                    privateKeyMessage = "Could not retrieve your private key. Please try again."
                }
                showingPrivateKeyAlert = true
            } catch {
                print("Error retrieving private key: \(error)")
                privateKeyMessage = "Error retrieving private key: \(error.localizedDescription)"
                showingPrivateKeyAlert = true
            }
        }
    }
}

struct SendSuiView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var walletManager: WalletManager
    @State private var amount = ""
    @State private var recipient = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Amount (SUI)", text: $amount)
                    .keyboardType(.decimalPad)

                TextField("Recipient Address", text: $recipient)

                Button("Send") {
                    guard let amountDouble = Double(amount) else {
                        errorMessage = "Invalid amount format"
                        showError = true
                        return
                    }

                    let amountInSui = UInt64(amountDouble * 1_000_000_000)

                    Task {
                        do {
                            try await walletManager.send(amount: amountInSui, to: recipient)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .disabled(amount.isEmpty || recipient.isEmpty || walletManager.isLoading)
            }
            .navigationTitle("Send SUI")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
