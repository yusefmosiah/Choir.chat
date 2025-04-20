import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 30) {
            // Navigation bar with close button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding()
                }
                Spacer()
            }

            Spacer()

            // App logo and title
            Image("Icon-App-1024x1024")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding()

            Text("Sign in to Choir")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Authenticate with Face ID or Touch ID to access your wallet")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Authentication status
            if isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Verifying your identity...")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let errorMessage = errorMessage {
                // Error message with retry button
                VStack(spacing: 15) {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button(action: {
                        Task {
                            await attemptLogin()
                        }
                    }) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: 200)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(isRetrying)
                }
            } else {
                // Sign in button
                Button(action: {
                    Task {
                        await attemptLogin()
                    }
                }) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Sign In with Biometrics")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(isLoading)
            }

            Spacer()

            // Small note about wallet management
            Text("Wallet management is available in the Wallets tab after login")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .padding()
        .onAppear {
            // Load wallet if needed, but don't attempt login automatically
            Task {
                // Make sure we have a wallet loaded
                if walletManager.wallet == nil {
                    do {
                        try await walletManager.createOrLoadWallet()
                    } catch {
                        await handleError(error)
                    }
                }
            }
        }
    }

    private func attemptLogin() async {
        isLoading = true
        errorMessage = nil
        isRetrying = true

        do {
            print("Starting automatic login with biometric authentication")
            try await authService.login()
            print("Login successful")
            isLoading = false
            isRetrying = false
        } catch {
            await handleError(error)
        }
    }

    private func handleError(_ error: Error) async {
        await MainActor.run {
            isLoading = false
            isRetrying = false
            print("Login error in LoginView: \(error)")

            // Show more detailed error message
            if let authError = error as? AuthError {
                switch authError {
                case .biometricAuthFailed:
                    errorMessage = "Biometric authentication failed. Please try again to unlock your wallet."
                case .walletNotAvailable:
                    errorMessage = "No wallet is available. Please go to the Wallet tab after login to set up your wallet."
                default:
                    errorMessage = authError.errorDescription
                }
            } else {
                errorMessage = "Error: \(error.localizedDescription)\n\nPlease try again."
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
