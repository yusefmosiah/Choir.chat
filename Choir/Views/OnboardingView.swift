import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingLoginView = false
    @State private var hasExistingAccount: Bool = false
    @State private var isAttemptingAutoLogin = false
    @State private var loginError: String? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App logo and title
            Image("Icon-App-1024x1024")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding()

            Text("Welcome to Choir")
                .font(.system(size: 36, weight: .bold))

            Text("Voices in Harmony")
                .font(.title2)
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 20) {
                Text("Choir uses Sui blockchain for secure authentication")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if isAttemptingAutoLogin {
                    // Show loading indicator during auto-login
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Authenticating...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                } else if let error = loginError {
                    // Show error message if auto-login failed
                    VStack(spacing: 10) {
                        Text("Auto-login failed")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineLimit(2)
                    }
                    .padding(.bottom, 10)

                    Button(action: {
                        showingLoginView = true
                    }) {
                        Text("Sign In Manually")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                } else if hasExistingAccount {
                    Button(action: {
                        showingLoginView = true
                    }) {
                        Text("Continue with Existing Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                } else {
                    Button(action: {
                        showingLoginView = true
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }

                Text("You'll need to authenticate with Face ID or Touch ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Check if we have an existing account
            hasExistingAccount = authService.hasAuthToken() || walletManager.wallet != nil

            // Attempt auto-login if we have a wallet
            if hasExistingAccount && !isAttemptingAutoLogin {
                isAttemptingAutoLogin = true
                attemptAutoLogin()
            }
        }
        .fullScreenCover(isPresented: $showingLoginView) {
            LoginView()
                .environmentObject(authService)
                .environmentObject(walletManager)
        }
    }

    private func attemptAutoLogin() {
        Task {
            do {
                // First make sure we have a wallet loaded
                if walletManager.wallet == nil {
                    try await walletManager.createOrLoadWallet()
                }

                // Now attempt to login with biometric authentication
                try await authService.login()

                // If we get here, login was successful
                print("Auto-login successful")
            } catch {
                // Auto-login failed, reset the flag so user can try manually
                await MainActor.run {
                    isAttemptingAutoLogin = false
                    loginError = error.localizedDescription
                    print("Auto-login failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    let walletManager = WalletManager()
    let authService = AuthService(walletManager: walletManager)

    return OnboardingView()
        .environmentObject(authService)
        .environmentObject(walletManager)
}
