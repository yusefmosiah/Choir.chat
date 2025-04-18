import SwiftUI

@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Properties

    @Published var authService: AuthService
    @Published var walletManager: WalletManager
    @Published private(set) var currentAuthState: AuthState = .unauthenticated

    // MARK: - Initialization

    init() {
        let walletManager = WalletManager()
        self.walletManager = walletManager
        self.authService = AuthService(walletManager: walletManager)

        // Set up observer for auth state changes
        setupAuthStateObserver()
    }

    private func setupAuthStateObserver() {
        // Observe changes to authService.authState
        Task { @MainActor in
            for await _ in authService.$authState.values {
                self.currentAuthState = authService.authState
                print("Auth state updated: \(self.currentAuthState)")
            }
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    func rootView() -> some View {
        Group {
            switch currentAuthState {
            case .unauthenticated, .error:
                LoginView()
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .transition(.opacity)

            case .authenticating:
                ProgressView("Authenticating...")
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .transition(.opacity)

            case .authenticated:
                MainTabView()
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: currentAuthState)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedTab = 0 // Default to Home tab

    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat tab (ContentView)
            ContentView()
                .tag(3)
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .environmentObject(walletManager)
                .environmentObject(authService)

            // Wallet tab
            WalletView()
                .tag(2)
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
            


            // Settings tab
            SettingsView()
                .tag(4)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
