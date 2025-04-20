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
    @State private var showingWalletSelectionSheet = false
    @State private var showingImportSheet = false
    @State private var showingCreateWalletAlert = false
    @State private var newWalletName = "New Wallet"
    @State private var isWalletSwitching = false
    @State private var showingPaymentErrorAlert = false
    @State private var paymentErrorMessage = ""
    @State private var hasCopiedAddress = false
    @State private var hasCopiedPrivateKey = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Horizontal wallet selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Wallets")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Display all wallets as cards
                                ForEach(Array(walletManager.wallets.keys), id: \.self) { address in
                                    if let wallet = walletManager.wallets[address] {
                                        let isSelected = walletManager.wallet?.accounts[0].publicKey.hex() == wallet.accounts[0].publicKey.hex()

                                        WalletCardView(
                                            wallet: wallet,
                                            name: walletManager.walletNames[address] ?? "Unnamed Wallet",
                                            address: address,
                                            balance: isSelected ? walletManager.balance : 0, // Only show balance for selected wallet
                                            isSelected: isSelected,
                                            onSelect: {
                                                selectWallet(address: address)
                                            }
                                        )
                                        .id(address) // Add ID for scrolling
                                    }
                                }

                            // Add wallet button
                            Button(action: { showingCreateWalletAlert = true }) {
                                VStack {
                                    Image(systemName: "plus.circle")
                                        .font(.largeTitle)
                                        .padding()

                                    Text("Add Wallet")
                                        .font(.headline)
                                }
                                .frame(width: 150, height: 180)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                        }
                        .onAppear {
                            scrollToCurrentWallet(proxy: scrollProxy)
                        }
                        .onChange(of: walletManager.wallet) { _, _ in
                            scrollToCurrentWallet(proxy: scrollProxy)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))

                // Current wallet details in a Form
                Form {
                        // Wallet Address Section
                        Section(header: Text("Wallet Address")) {
                            if let wallet = walletManager.wallet,
                               let address = try? wallet.accounts[0].address() {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(address)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .textSelection(.enabled)

                                    HStack {
                                        Button(action: {
                                            UIPasteboard.general.string = address
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                hasCopiedAddress = true
                                            }

                                            // Reset after delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    hasCopiedAddress = false
                                                }
                                            }
                                        }) {
                                            Label(
                                                hasCopiedAddress ? "Copied!" : "Copy Address",
                                                systemImage: hasCopiedAddress ? "checkmark.circle.fill" : "doc.on.doc"
                                            )
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(hasCopiedAddress ? .green : .blue)

                                        Spacer()

                                        Text("Balance: \(String(format: "%.9f SUI", walletManager.balance))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                Text("No wallet selected")
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Send Payment Section
                        Section(header: Text("Send Payment")) {
                            if let wallet = walletManager.wallet {
                                VStack(spacing: 16) {
                                    TextField("Recipient Address", text: $recipientAddress)
                                        .font(.system(.body, design: .monospaced))
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textContentType(.none)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)

                                    TextField("Amount (SUI)", text: $sendAmount)
                                        .keyboardType(.decimalPad)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)

                                    Button(action: {
                                        sendPayment()
                                    }) {
                                        Text("Send SUI")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(recipientAddress.isEmpty || sendAmount.isEmpty || walletManager.isLoading)
                                }
                                .padding(.vertical, 8)
                            } else {
                                Text("Select a wallet to send payments")
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Receive Section
                        Section(header: Text("Receive")) {
                            if let wallet = walletManager.wallet {
                                Button("Request Testnet SUI") {
                                    Task {
                                        try? await walletManager.requestAirdrop()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .disabled(walletManager.isLoading)
                            } else {
                                Text("Select a wallet to receive funds")
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Security Section
                        Section(header: Text("Security")) {
                            Button(action: {
                                Task {
                                    await exportPrivateKey()
                                }
                            }) {
                                Label("Export Private Key", systemImage: "key.fill")
                            }
                            .disabled(walletManager.wallet == nil || walletManager.isLoading)
                        }

                        // Wallet Management Section
                        Section(header: Text("Wallet Management")) {
                            Button(action: { showingImportSheet = true }) {
                                Label("Import Wallet from Mnemonic", systemImage: "square.and.arrow.down")
                            }
                            .disabled(walletManager.isLoading)
                        }
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
            Button(hasCopiedPrivateKey ? "Copied!" : "Copy to Clipboard") {
                UIPasteboard.general.string = privateKeyMessage
                hasCopiedPrivateKey = true

                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    hasCopiedPrivateKey = false
                }
            }
            Button("OK", role: .cancel) {
                hasCopiedPrivateKey = false
            }
        } message: {
            Text(privateKeyMessage)
        }
        .alert("Payment Error", isPresented: $showingPaymentErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(paymentErrorMessage)
        }
        .navigationTitle("Wallets")
        .sheet(isPresented: $showingWalletSelectionSheet) {
            WalletSelectionView()
                .environmentObject(walletManager)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportMnemonicView()
                .environmentObject(walletManager)
        }
        .alert("Create New Wallet", isPresented: $showingCreateWalletAlert) {
            TextField("Wallet Name", text: $newWalletName)

            Button("Cancel", role: .cancel) { }

            Button("Create") {
                createNewWallet()
            }
        } message: {
            Text("Enter a name for your new wallet")
        }
        .overlay(Group {
            if isWalletSwitching || walletManager.isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text(isWalletSwitching ? "Switching wallet..." : "Loading...")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isWalletSwitching || walletManager.isLoading)
            }
        })
    }

    private func selectWallet(address: String) {
        // Don't do anything if this is already the selected wallet
        if let currentWallet = walletManager.wallet,
           let currentAddress = try? currentWallet.accounts[0].address(),
           currentAddress == address {
            return
        }

        isWalletSwitching = true

        Task {
            do {
                try await walletManager.switchWallet(address: address)
            } catch {
                print("Error switching wallet: \(error)")
            }

            // Add a small delay to make the transition smoother
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            isWalletSwitching = false
        }
    }

    private func createNewWallet() {
        Task {
            do {
                // Use the provided wallet name, or a default if empty
                let name = newWalletName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    "Wallet \(Int.random(in: 1000...9999))" : newWalletName.trimmingCharacters(in: .whitespacesAndNewlines)

                try await walletManager.createOrLoadWallet(name: name)
                newWalletName = "New Wallet" // Reset for next time
            } catch {
                print("Error creating wallet: \(error)")
            }
        }
    }

    private func sendPayment() {
        guard !recipientAddress.isEmpty, !sendAmount.isEmpty else { return }

        // Convert the amount to SUI units (1 SUI = 10^9 units)
        guard let amountDouble = Double(sendAmount) else { return }
        let amountInSui = UInt64(amountDouble * 1_000_000_000)

        Task {
            do {
                try await walletManager.send(amount: amountInSui, to: recipientAddress)

                // Clear the fields after successful send
                await MainActor.run {
                    sendAmount = ""
                    recipientAddress = ""
                }
            } catch {
                print("Error sending payment: \(error)")
                await MainActor.run {
                    paymentErrorMessage = error.localizedDescription
                    showingPaymentErrorAlert = true
                }
            }
        }
    }

    // Helper method to scroll to the current wallet
    private func scrollToCurrentWallet(proxy: ScrollViewProxy) {
        if let currentWallet = walletManager.wallet,
           let currentAddress = try? currentWallet.accounts[0].address() {
            withAnimation {
                proxy.scrollTo(currentAddress, anchor: .center)
            }
        }
    }

    private func exportPrivateKey() async {
        await MainActor.run {
            do {
                // Get the mnemonic from the keychain with biometric authentication
                if let currentWallet = walletManager.wallet,
                   let address = try? currentWallet.accounts[0].address(),
                   let walletName = walletManager.walletNames[address] {

                    let walletKey = "wallet_\(walletName)_mnemonic"

                    if let mnemonic = try walletManager.keychain.load(
                        walletKey,
                        withPrompt: "Authenticate to export your private key",
                        requireBiometric: true
                    ) {
                        privateKeyMessage = "Your mnemonic phrase (keep this secret):\n\n\(mnemonic)"
                    } else {
                        privateKeyMessage = "Could not retrieve your private key. Please try again."
                    }
                } else {
                    privateKeyMessage = "Could not determine the current wallet information."
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
