import SwiftUI

struct LoginView: View {
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingImportSheet = false
    @State private var showingWalletSelectionSheet = false

    // No custom initializer needed - using environment objects

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Choir")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in with your Sui wallet")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            // Wallet info section
            if let wallet = walletManager.wallet {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Current Wallet:")
                            .font(.headline)

                        Spacer()

                        Button(action: { showingWalletSelectionSheet = true }) {
                            Label("Switch", systemImage: "arrow.left.arrow.right")
                                .font(.caption)
                        }
                    }

                    if let address = try? wallet.accounts[0].address(),
                       let name = walletManager.walletNames[address] {
                        Text(name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                    }

                    Text("Address:")
                        .font(.headline)

                    if let address = try? wallet.accounts[0].address() {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Text("Balance:")
                        .font(.headline)

                    Text(String(format: "%.9f SUI", walletManager.balance))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                Button(action: login) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isLoading)
            } else {
                Text("No wallet selected")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            }

            // Wallet management buttons
            VStack(spacing: 16) {
                Button(action: createWallet) {
                    Text("Create New Wallet")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isLoading)

                Button(action: { showingImportSheet = true }) {
                    Text("Import Wallet from Mnemonic")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .disabled(isLoading)

                if walletManager.wallets.count > 0 {
                    Button(action: { showingWalletSelectionSheet = true }) {
                        Text("Select from \(walletManager.wallets.count) Wallets")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
            }

            if isLoading {
                ProgressView()
                    .padding()
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                if walletManager.wallet == nil {
                    try? await walletManager.createOrLoadWallet()
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportMnemonicView()
                .environmentObject(walletManager)
        }
        .sheet(isPresented: $showingWalletSelectionSheet) {
            WalletSelectionView()
                .environmentObject(walletManager)
        }
    }

    private func createWallet() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Generate a random wallet name
                let walletName = "Wallet \(Int.random(in: 1000...9999))"
                try await walletManager.createOrLoadWallet(name: walletName)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil
        print("Login button pressed")

        Task {
            do {
                print("Starting login process in LoginView")
                try await authService.login()
                print("Login successful")
                isLoading = false
            } catch {
                isLoading = false
                print("Login error in LoginView: \(error)")

                // Show more detailed error message
                if let authError = error as? AuthError {
                    errorMessage = authError.errorDescription
                } else {
                    errorMessage = "Error: \(error.localizedDescription)\n\nPlease check the console for more details."
                }
            }
        }
    }
}

#Preview {
    let walletManager = WalletManager()
    let authService = AuthService(walletManager: walletManager)

    return LoginView()
        .environmentObject(walletManager)
        .environmentObject(authService)
}
