# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# Choir iOS Architecture

## Core Components

1. **Thread Model**

```swift
struct Thread: Identifiable {
    let id: UUID
    var messages: [Message]
    var coAuthors: Set<PublicKey>
    var tokenBalance: UInt64
    var currentStep: ChorusStep
}
```

2. **Message Flow**

```swift
enum ChorusStep {
    case action     // Initial response
    case experience // Get priors (n=80)
    case intention  // Analyze goal
    case observation // Record semantic links
    case update     // Loop decision
    case yield      // Final response
}
```

## Network Layer

1. **WebSocket Manager**

```swift
// Using URLSessionWebSocketTask for native implementation
class WebSocketManager: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    @Published var isConnected = false

    func connect() {
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: URL(string: "wss://...")!)
        webSocket?.resume()
        receiveMessage()
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
}
```

2. **Solana Integration**

```swift
// Using Solana.Swift for blockchain interaction
class SolanaManager: ObservableObject {
    private let solana: Solana
    @Published var balance: UInt64 = 0

    init() {
        solana = Solana(router: NetworkingRouter(endpoint: .devnet))
    }

    func getBalance(account: PublicKey) async throws -> UInt64 {
        return try await solana.api.getBalance(account: account)
    }

    func signAndSendTransaction(_ transaction: Transaction) async throws -> String {
        // WalletConnect integration for signing
        return try await solana.action.sendTransaction(transaction)
    }
}
```

3. **Wallet Integration**

```swift
// Using WalletConnect for wallet interactions
class WalletManager: ObservableObject {
    private let client: Client
    @Published var isConnected = false
    @Published var publicKey: PublicKey?

    func connect() async throws {
        // WalletConnect connection flow
        // Returns connected wallet info
    }

    func sign(transaction: Transaction) async throws -> Signature {
        // WalletConnect signing flow
    }
}
```

## View Architecture

1. **Main Navigation**

```swift
struct MainView: View {
    @StateObject var walletManager = WalletManager()
    @StateObject var solanaManager = SolanaManager()

    var body: some View {
        TabView {
            ThreadListView()
                .tabItem { Label("Threads", systemImage: "list.bullet") }

            MessageFlowView()
                .tabItem { Label("Chat", systemImage: "message") }

            PriorPanelView()
                .tabItem { Label("Priors", systemImage: "doc.text") }
        }
        .environmentObject(walletManager)
        .environmentObject(solanaManager)
    }
}
```

2. **Chat Interface**

```swift
struct MessageFlowView: View {
    @StateObject var viewModel: MessageFlowViewModel
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var solanaManager: SolanaManager

    var body: some View {
        VStack {
            MessageList(messages: viewModel.messages)
            StepIndicator(currentStep: viewModel.currentStep)
            MessageInput(onSend: viewModel.sendMessage)
        }
    }
}
```

## Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Giancarlo-Catalano/Solana.Swift.git", from: "1.2.0"),
    .package(url: "https://github.com/WalletConnect/WalletConnectSwift.git", from: "1.7.0")
]

// Benefits:
// 1. Minimal external dependencies
// 2. Native WebSocket support
// 3. Strong type system
// 4. Modern async/await
// 5. SwiftUI integration
```

## Integration Points

1. **Backend Communication**

- WebSocket for real-time updates
- REST API for thread management
- Qdrant for vector search
- LiteLLM for AI responses

2. **Blockchain Integration**

- Solana.Swift for RPC calls
- WalletConnect for wallet interaction
- Program interaction via Anchor IDL

3. **State Management**

- SwiftUI @StateObject for view models
- @EnvironmentObject for global state
- Combine for reactive updates
- AsyncSequence for WebSocket streams
