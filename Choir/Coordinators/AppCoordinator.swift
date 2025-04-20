import SwiftUI
import Combine

@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Properties

    @Published var authService: AuthService
    @Published var walletManager: WalletManager
    @Published var threadManager: ThreadManager
    @Published private(set) var currentAuthState: AuthState = .unauthenticated

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Initialize properties
        let walletManager = WalletManager()
        self.walletManager = walletManager
        self.threadManager = ThreadManager()

        // Create auth service
        let authService = AuthService(walletManager: walletManager)
        self.authService = authService

        // Update the shared instance for use with PostchainAPIClient
        AuthService.shared = authService

        // Set up observer for auth state changes
        setupAuthStateObserver()

        // Observe wallet changes
        walletManager.$wallet.sink { [weak self] newWallet in
            guard let self = self else { return }
            Task { @MainActor in
                if let wallet = newWallet,
                   let address = try? wallet.accounts[0].address() {
                    // When wallet changes, update the thread manager
                    self.threadManager.switchWallet(to: address)
                }
            }
        }.store(in: &cancellables)

        // Observe auth state changes for wallet switching
        authService.$authState.sink { [weak self] newState in
            guard let self = self else { return }
            Task { @MainActor in
                if case .authenticated(let userInfo) = newState,
                   let walletAddress = try? self.walletManager.wallet?.accounts[0].address() {
                    // When authenticated, switch to the current wallet's threads
                    self.threadManager.switchWallet(to: walletAddress)
                } else if case .unauthenticated = newState {
                    // When logged out, switch to nil wallet (show no threads)
                    self.threadManager.switchWallet(to: nil)
                }
            }
        }.store(in: &cancellables)
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
                    .environmentObject(threadManager)
                    .transition(.opacity)

            case .authenticating:
                ProgressView("Authenticating...")
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .environmentObject(threadManager)
                    .transition(.opacity)

            case .authenticated:
                MainTabView()
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .environmentObject(threadManager)
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
    @EnvironmentObject var threadManager: ThreadManager
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
                .environmentObject(threadManager)

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
