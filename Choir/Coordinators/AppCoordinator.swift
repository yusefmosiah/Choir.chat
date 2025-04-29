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
                OnboardingView()
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .environmentObject(threadManager)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))

            case .authenticating:
                ProgressView("Authenticating...")
                    .scaleEffect(1.5)
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .environmentObject(threadManager)
                    .transition(.opacity.combined(with: .scale))

            case .authenticated:
                MainTabView()
                    .environmentObject(walletManager)
                    .environmentObject(authService)
                    .environmentObject(threadManager)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentAuthState)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var threadManager: ThreadManager
    @State private var selectedTab = 0 // Default to Home tab
    @State private var previousTab: Int? = nil
    @StateObject private var transactionService = TransactionService()

    // Reference to ContentView to control thread selection
    @State private var contentViewModel = ContentViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat tab (ContentView)
            ContentView(viewModel: contentViewModel)
                .tag(3)
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .environmentObject(walletManager)
                .environmentObject(authService)
                .environmentObject(threadManager)

            // Wallets tab
            WalletView()
                .tag(2)
                .tabItem {
                    Label("Wallets", systemImage: "wallet.pass")
                }



            // Transactions tab
            TransactionsView(transactionService: transactionService)
                .tag(4)
                .tabItem {
                    Label("Transactions", systemImage: "arrow.left.arrow.right")
                }
                .badge(transactionService.unreadCount > 0 ? "\(transactionService.unreadCount)" : "")

            // Settings tab
            SettingsView()
                .tag(5)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Store the previous tab
            previousTab = oldValue

            // If switching to the Chat tab (3), reset thread selection
            if newValue == 3 && oldValue != 3 {
                // Reset thread selection to show thread list
                contentViewModel.resetThreadSelection()
            }

            // If switching to the Transactions tab (4), fetch transactions
            if newValue == 4 {
                transactionService.fetchTransactions()
            }
        }
        .onAppear {
            // Fetch transactions when the view appears
            transactionService.fetchTransactions()
        }
    }
}

// View model to control ContentView's thread selection
class ContentViewModel: ObservableObject {
    @Published var shouldResetThreadSelection = false

    func resetThreadSelection() {
        // Trigger thread selection reset
        shouldResetThreadSelection = true

        // Reset the flag after a short delay to allow for future resets
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldResetThreadSelection = false
        }
    }
}
