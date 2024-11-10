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
# Development Phases

## Phase 1: SwiftUI Solana Foundation
```swift
Goals:
- Wallet connection via WalletConnect
- RPC connection and basic transactions
- Account balance and airdrops (devnet)
- Clean architecture patterns
- Unit test foundation

Dependencies:
- Solana.Swift
- WalletConnect
- SwiftUI/Combine
```

## Phase 2: API Deployment & WebSocket Integration
```python
Goals:
- Split out choir-api repository
- Deploy FastAPI backend
- WebSocket connection from iOS
- Real-time message flow
- Basic thread state management

Stack:
- FastAPI
- WebSockets
- Docker/deployment
- iOS async/await
```

## Phase 3: Full Chorus Cycle
```swift
Goals:
- Complete AI chat implementation
- Vector search integration
- Semantic link recording
- Prior citation flow
- Polish chat UI/UX

Features:
- Thread management
- Message approvals
- Prior citations
- Real-time updates
```

## Phase 4: Token & Program Launch
```rust
Goals:
- Mint CHOIR token
- Deploy thread program
- Implement reward distribution
- Full program testing
- Security audit

Components:
- Anchor program
- Token distribution
- State management
- Testing suite
```

## Phase 5: App Store Launch
```swift
Goals:
- Polish all flows
- App Store assets
- TestFlight beta
- Marketing materials
- Launch strategy

Focus:
- User experience
- Performance
- Edge cases
- Error handling
```

## Phase 6: Website & Documentation
```
Goals:
- Marketing site
- Technical docs
- API documentation
- Community resources
- Launch blog

Stack:
- Zola
- Markdown
- CI/CD
```

## Current Focus: Phase 1

1. **Wallet Setup**
```swift
// First milestone
class WalletManager: ObservableObject {
    private let client: WalletConnectClient
    @Published var isConnected: Bool
    @Published var publicKey: PublicKey?

    // Core flows:
    func connect()
    func disconnect()
    func signTransaction()
}
```

2. **RPC Integration**
```swift
// Second milestone
class SolanaManager: ObservableObject {
    private let solana: Solana
    @Published var balance: UInt64

    // Core operations:
    func getBalance()
    func requestAirdrop()
    func sendTransaction()
}
```

3. **Architecture Foundation**
```swift
// Clean architecture setup
├── Core/
│   ├── Protocols/      // Interfaces
│   ├── Extensions/     // Swift extensions
│   └── Utilities/      // Shared tools
├── Features/
│   ├── Wallet/        // Wallet connection
│   └── Solana/        // RPC interaction
├── UI/
│   ├── Components/    // Reusable views
│   └── Screens/      // Main screens
└── Services/
    ├── Network/      // API/WebSocket
    └── Storage/      // Local persistence
```

This phased approach lets us:
1. Build strong foundations
2. Test core functionality early
3. Maintain clean architecture
4. Ship incrementally
5. Validate assumptions
6. Pivot if needed

Ready to start with Phase 1?
