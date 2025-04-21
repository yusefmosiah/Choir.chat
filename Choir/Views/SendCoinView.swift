import SwiftUI
import SuiKit
import Combine

struct SendCoinView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var walletManager: WalletManager
    @State private var amount = ""
    @State private var recipient = ""
    @State private var selectedCoinType: CoinType = .sui
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Coin type picker
                Section(header: Text("Coin Type")) {
                    Picker("Coin Type", selection: $selectedCoinType) {
                        ForEach(walletManager.supportedCoinTypes.filter {
                            walletManager.balances[$0]?.balance ?? 0 > 0
                        }, id: \.self) { coinType in
                            Text(coinType.name)
                                .tag(coinType)
                        }
                    }
                    .pickerStyle(.menu)

                    if let balance = walletManager.balances[selectedCoinType] {
                        Text("Available: \(balance.formattedBalance)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Amount and recipient
                Section(header: Text("Transaction Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    TextField("Recipient Address", text: $recipient)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                // Send button
                Section {
                    Button("Send \(selectedCoinType.symbol)") {
                        sendTransaction()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(amount.isEmpty || recipient.isEmpty || walletManager.isLoading)
                }
            }
            .navigationTitle("Send \(selectedCoinType.symbol)")
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

    private func sendTransaction() {
        guard let amountDouble = Double(amount) else {
            errorMessage = "Invalid amount format"
            showError = true
            return
        }

        // Convert to raw amount based on coin decimals
        let rawAmount = selectedCoinType.toRawAmount(amountDouble)

        Task {
            do {
                try await walletManager.send(amount: rawAmount, coinType: selectedCoinType, to: recipient)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    // Create mock wallet manager
    let walletManager = WalletManager()

    return SendCoinView(walletManager: walletManager)
}
