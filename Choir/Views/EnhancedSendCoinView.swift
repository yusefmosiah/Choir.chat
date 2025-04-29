import SwiftUI
import SuiKit
import Combine

struct EnhancedSendCoinView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var walletManager: WalletManager
    @State private var amount = ""
    @State private var recipient = ""
    @State private var selectedCoinType: CoinType = .sui
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var transactionDigest = ""
    @State private var useMaxAmount = false
    @State private var showScanner = false

    // For recent recipients
    private let recentRecipientsKey = "recentRecipients"
    @State private var showRecentRecipients = false

    private var recentRecipients: [String] {
        UserDefaults.standard.stringArray(forKey: recentRecipientsKey) ?? []
    }

    private func saveRecipient(_ address: String) {
        var recipients = recentRecipients
        // Remove if already exists
        if let index = recipients.firstIndex(of: address) {
            recipients.remove(at: index)
        }
        // Add to beginning
        recipients.insert(address, at: 0)
        // Limit to 5 recent recipients
        if recipients.count > 5 {
            recipients = Array(recipients.prefix(5))
        }
        UserDefaults.standard.set(recipients, forKey: recentRecipientsKey)
    }

    var body: some View {
        NavigationView {
            Form {
                // Coin type picker with icons
                Section(header: Text("Coin Type")) {
                    // Filter coin types with positive balance
                    let availableCoinTypes = walletManager.supportedCoinTypes.filter { coinType in
                        let balance = walletManager.balances[coinType]?.balance ?? 0
                        return balance > 0
                    }

                    ForEach(availableCoinTypes, id: \.self) { coinType in
                        Button(action: {
                            selectedCoinType = coinType
                            // Reset amount if switching coin types
                            if useMaxAmount {
                                updateMaxAmount()
                            }
                        }) {
                            HStack {
                                if let iconName = coinType.iconName, let uiImage = UIImage(named: iconName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "dollarsign.circle")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                }

                                VStack(alignment: .leading) {
                                    Text(coinType.name)
                                        .font(.headline)

                                    if let balance = walletManager.balances[coinType] {
                                        Text("Available: \(balance.formattedBalance)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if selectedCoinType == coinType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Amount section
                Section(header: Text("Amount")) {
                    HStack {
                        TextField("0.0", text: $amount)
                            .keyboardType(.decimalPad)
                            .disabled(useMaxAmount)

                        Text(selectedCoinType.symbol)
                            .foregroundColor(.secondary)

                        Spacer()

                        Toggle("Max", isOn: $useMaxAmount)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .onChange(of: useMaxAmount) { newValue in
                                if newValue {
                                    updateMaxAmount()
                                }
                            }
                    }
                }

                // Recipient section
                Section(header: Text("Recipient")) {
                    HStack {
                        TextField("Recipient Address", text: $recipient)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))

                        Button(action: {
                            showScanner = true
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundColor(.blue)
                        }
                    }

                    // Paste button
                    Button("Paste from Clipboard") {
                        if let pasteboardString = UIPasteboard.general.string {
                            recipient = pasteboardString
                        }
                    }

                    // Recent recipients
                    if !recentRecipients.isEmpty {
                        DisclosureGroup("Recent Recipients", isExpanded: $showRecentRecipients) {
                            ForEach(recentRecipients, id: \.self) { address in
                                Button(action: {
                                    recipient = address
                                    showRecentRecipients = false
                                }) {
                                    Text(address)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                    }
                }

                // Transaction fee section
                Section(header: Text("Transaction Fee")) {
                    HStack {
                        Text("Network Fee")
                        Spacer()
                        Text("~0.000005 SUI")
                            .foregroundColor(.secondary)
                    }
                }

                // Send button
                Section {
                    Button(action: {
                        sendTransaction()
                    }) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Send \(selectedCoinType.symbol)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(amount.isEmpty || recipient.isEmpty || isProcessing)
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
            .alert("Transaction Successful", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
                Button("View on Explorer") {
                    if let url = URL(string: "https://explorer.sui.io/txblock/\(transactionDigest)?network=devnet") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Your transaction has been successfully submitted to the network.")
            }
            .sheet(isPresented: $showScanner) {
                QRScannerSheet(isPresented: $showScanner, scannedAddress: $recipient)
            }
        }
    }

    private func updateMaxAmount() {
        if let balance = walletManager.balances[selectedCoinType] {
            // Leave a small amount for gas if it's SUI
            let maxRawAmount = selectedCoinType == .sui ?
                max(0, balance.balance - 1_000_000) : // Leave 0.001 SUI for gas
                balance.balance

            // Format to display amount
            let displayAmount = selectedCoinType.toDisplayAmount(UInt64(maxRawAmount))
            amount = String(format: "%.6f", displayAmount)
        }
    }

    private func sendTransaction() {
        guard let amountDouble = Double(amount), amountDouble > 0 else {
            errorMessage = "Invalid amount format"
            showError = true
            return
        }

        guard !recipient.isEmpty else {
            errorMessage = "Recipient address cannot be empty"
            showError = true
            return
        }

        // Convert to raw amount based on coin decimals
        let rawAmount = selectedCoinType.toRawAmount(amountDouble)

        isProcessing = true

        Task {
            do {
                // Save recipient to recent list
                saveRecipient(recipient)

                // Send the transaction
                let effects = try await walletManager.send(amount: rawAmount, coinType: selectedCoinType, to: recipient)

                // Update UI on main thread
                await MainActor.run {
                    isProcessing = false
                    // The transaction digest is returned from the effects
                    // If effects is nil, we'll use an empty string
                    if let effects = effects {
                        transactionDigest = effects.transactionDigest
                    } else {
                        transactionDigest = ""
                    }
                    showSuccessAlert = true

                    // Log transaction details
                    print("Transaction successful: \(transactionDigest)")
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    // Create mock wallet manager
    let walletManager = WalletManager()

    return EnhancedSendCoinView(walletManager: walletManager)
}
