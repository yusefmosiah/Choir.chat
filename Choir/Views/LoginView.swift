import SwiftUI

struct LoginView: View {
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    @State private var errorMessage: String?

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

            if walletManager.wallet == nil {
                Button(action: createWallet) {
                    Text("Create Wallet")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isLoading)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Wallet Address:")
                        .font(.headline)

                    if let address = try? walletManager.wallet?.accounts[0].address() {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
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
    }

    private func createWallet() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await walletManager.createOrLoadWallet()
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
