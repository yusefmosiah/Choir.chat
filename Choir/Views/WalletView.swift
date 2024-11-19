import SwiftUI
import SuiKit

struct WalletView: View {
    @StateObject private var walletManager = WalletManager()
    @State private var sendAmount: String = ""
    @State private var recipientAddress: String = ""
    @State private var showingSendSheet = false

    var body: some View {
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
