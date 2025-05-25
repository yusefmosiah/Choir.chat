import SwiftUI
import LocalAuthentication

struct ImportMnemonicView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager

    @State private var mnemonicPhrase = ""
    @State private var walletName = "Imported Wallet"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showBiometricPrompt = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Wallet Name")) {
                    TextField("Wallet Name", text: $walletName)
                }

                Section(header: Text("Enter Mnemonic Phrase")) {
                    TextEditor(text: $mnemonicPhrase)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.vertical, 4)

                    Text("Enter your 12, 15, 18, 21, or 24 word recovery phrase, with words separated by spaces.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(action: importWallet) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Import Wallet")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(mnemonicPhrase.isEmpty || isLoading)
                    .buttonStyle(PlainButtonStyle())
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Import Wallet")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Biometric Authentication", isPresented: $showBiometricPrompt) {
                Button("Continue", role: .destructive) {
                    Task {
                        await performImport()
                    }
                }
                Button("Cancel", role: .cancel) {
                    isLoading = false
                }
            } message: {
                Text("Your mnemonic phrase will be securely stored using Face ID/Touch ID. Do you want to continue?")
            }
        }
    }

    private func importWallet() {
        // Trim whitespace and normalize the mnemonic
        let trimmedMnemonic = mnemonicPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Basic validation
        let wordCount = trimmedMnemonic.components(separatedBy: " ").count
        if wordCount != 12 && wordCount != 15 && wordCount != 18 && wordCount != 21 && wordCount != 24 {
            errorMessage = "Invalid mnemonic length. Please enter 12, 15, 18, 21, or 24 words."
            return
        }

        mnemonicPhrase = trimmedMnemonic
        isLoading = true

        #if DEBUG && targetEnvironment(simulator)
        // In simulator, skip biometric check and proceed directly
        print("Skipping biometric check in simulator for mnemonic import")
        Task {
            await performImport()
        }
        #else
        // Check if biometric authentication is available
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Show biometric prompt alert
            showBiometricPrompt = true
        } else {
            // Biometric authentication not available, proceed without it
            Task {
                await performImport()
            }
        }
        #endif
    }

    private func performImport() async {
        do {
            // Use the provided wallet name, or a default if empty
            let name = walletName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                "Imported Wallet" : walletName.trimmingCharacters(in: .whitespacesAndNewlines)

            try await walletManager.importWalletFromMnemonic(mnemonicPhrase, name: name)
            await MainActor.run {
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

#Preview {
    ImportMnemonicView()
        .environmentObject(WalletManager())
}
