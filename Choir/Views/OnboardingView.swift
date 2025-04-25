import SwiftUI
import LocalAuthentication

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingLoginView = false
    @State private var hasExistingAccount: Bool = false
    @State private var isAttemptingAutoLogin = false
    @State private var loginError: String? = nil

    // Animation state for gradient
    @State private var gradientRotation: Double = 0
    @State private var rotationTimer: Timer?

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Title with typographic emphasis
                VStack(spacing: 8) {
                    Text("CHOIR")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .tracking(4)
                        .foregroundColor(.primary)

                    Text("Voices in Harmony")
                        .font(.system(size: 18, weight: .light, design: .default))
                        .tracking(1)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)

                // Authentication card with glass effect
                VStack(spacing: 20) {
                    if isAttemptingAutoLogin {
                        // Neuomorphic glass card with gradient for auto-login
                        VStack(spacing: 20) {
                            // Status text
                            Text("Authenticating")
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(.primary)
                                .padding(.bottom, 10)

                            // Biometric info
                            Text("Using \(getBiometricType()) for secure authentication")
                                .font(.system(size: 14, weight: .light, design: .default))
                                .foregroundColor(.secondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 25)
                        .background(
                            ZStack {
                                // Angular gradient shadow for loading state
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        AngularGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: .green, location: 0.0),
                                                .init(color: .blue, location: 0.25),
                                                .init(color: .purple, location: 0.5),
                                                .init(color: .blue, location: 0.75),
                                                .init(color: .green, location: 1.0),
                                            ]),
                                            center: .center,
                                            angle: .degrees(gradientRotation)
                                        )
                                    )
                                    // Use less blur for a more visible effect
                                    .blur(radius: 8)
                                    // Higher opacity for more visibility
                                    .opacity(0.7)
                                    // Slightly larger to create a glow effect
                                    .scaleEffect(1.05)
                                    .offset(y: 2)

                                // Glass card background with neumorphic effect
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(UIColor.systemBackground).opacity(0.7))
                                    // Add a subtle inner shadow for depth
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            .blur(radius: 1)
                                            .offset(x: 0, y: 1)
                                            .mask(RoundedRectangle(cornerRadius: 20).fill(LinearGradient(
                                                gradient: Gradient(colors: [Color.black, Color.clear]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )))
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                    .blur(radius: 0.5)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.3), Color.gray.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .blur(radius: 0.5)
                        )
                    } else if let error = loginError {
                        // Error state
                        VStack(spacing: 16) {
                            Text("Authentication Failed")
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(.red)

                            Text(error)
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .lineLimit(2)
                                .padding(.bottom, 10)

                            Button(action: {
                                showingLoginView = true
                            }) {
                                Text("Sign In Manually")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .blur(radius: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 25)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        // Initial state - sign in button
                        VStack(spacing: 16) {
                            Text(hasExistingAccount ? "Welcome Back" : "Welcome to Choir")
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(.primary)

                            Button(action: {
                                showingLoginView = true
                            }) {
                                Text(hasExistingAccount ? "Continue with Existing Account" : "Sign In")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .blur(radius: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 25)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Footer text
                Text("Secured by Sui blockchain")
                    .font(.system(size: 14, weight: .light, design: .default))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            // Check if we have an existing account and set state BEFORE view appears
            hasExistingAccount = authService.hasAuthToken() || walletManager.wallet != nil

            // Set auto-login state immediately if we have an account
            if hasExistingAccount {
                isAttemptingAutoLogin = true
                startRotationTimer()
            }
        }
        .task {
            // Start the actual authentication process after view is rendered
            if hasExistingAccount && isAttemptingAutoLogin {
                attemptAutoLogin()
            }
        }
        .fullScreenCover(isPresented: $showingLoginView) {
            LoginView()
                .environmentObject(authService)
                .environmentObject(walletManager)
        }
        .onDisappear {
            stopRotationTimer()
        }
    }

    private func attemptAutoLogin() {
        Task {
            do {
                // Start wallet loading and authentication in parallel when possible
                if walletManager.wallet == nil {
                    // If wallet isn't loaded yet, we need to load it first
                    try await walletManager.createOrLoadWallet()
                }

                // Now attempt to login with biometric authentication
                try await authService.login()

                // If we get here, login was successful
                print("Auto-login successful")

                // Stop timer
                stopRotationTimer()
            } catch {
                // Auto-login failed, reset the flag so user can try manually
                await MainActor.run {
                    isAttemptingAutoLogin = false
                    loginError = error.localizedDescription
                    print("Auto-login failed: \(error)")

                    // Stop timer
                    stopRotationTimer()
                }
            }
        }
    }

    // MARK: - Animation Functions

    private func startRotationTimer() {
        // Stop any existing timer first
        stopRotationTimer()

        // Reset rotation to 0
        gradientRotation = 0

        // Create a new timer that updates the rotation angle
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [self] _ in
            // Update rotation on the main thread
            DispatchQueue.main.async {
                // Increment rotation by 3 degrees each time for faster rotation
                withAnimation(.linear(duration: 0.02)) {
                    self.gradientRotation = (self.gradientRotation + 3).truncatingRemainder(dividingBy: 360)
                }
            }
        }
    }

    private func stopRotationTimer() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    // MARK: - Helper Properties and Methods

    private var keychain: KeychainService {
        return KeychainService()
    }

    private func getBiometricType() -> String {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            default:
                return "Biometric Authentication"
            }
        } else {
            return "Passcode"
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
