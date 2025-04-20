import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingLoginView = false
    @State private var hasExistingAccount: Bool = false

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

            Text("Your AI-powered chat assistant")
                .font(.title2)
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 20) {
                Text("Choir uses Sui blockchain for secure authentication")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if hasExistingAccount {
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
            hasExistingAccount = authService.hasAuthToken() && walletManager.wallet != nil
        }
        .fullScreenCover(isPresented: $showingLoginView) {
            LoginView()
                .environmentObject(authService)
                .environmentObject(walletManager)
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
