# Core Client-Side Implementation

## Overview
Implement the foundational client-side system with a focus on getting a working version to TestFlight. Initially use Anthropic and OpenAI APIs through a secure proxy, while preparing for future local AI model integration.

## Current Issues
1. Issue 1: Local Data Management and Persistence
2. Issue 2: SUI Blockchain Smart Contracts (basic wallet integration)
3. Issue 5: Enhanced UI/UX with Carousel
4. Issue 7: Testing and Quality Assurance
5. Issue 8: Deploy to TestFlight and Render
6. Issue 9: Message Rewards Implementation
7. Issue 10: Thread Sheet Implementation
8. Issue 11: Thread Contract Implementation 
9. Issue 12: Citation Visualization and Handling
10. Issue 13: LanceDB Migration & Multimodal Support

## Immediate Tasks

### 1. Core Data Layer
```swift
// SwiftData models for local persistence
@Model
class User {
    @Attribute(.unique) let id: UUID
    let publicKey: String
    let createdAt: Date

    @Relationship(deleteRule: .cascade) var ownedThreads: [Thread]
    @Relationship var coAuthoredThreads: [Thread]
}

@Model
class Thread {
    @Attribute(.unique) let id: UUID
    let title: String
    let createdAt: Date

    @Relationship var owner: User
    @Relationship var coAuthors: [User]
    @Relationship(deleteRule: .cascade) var messages: [Message]
}
```

### 2. Basic SUI Integration
```swift
// Wallet management
class WalletManager {
    private let keychain = KeychainService()

    func createOrLoadWallet() async throws -> Wallet {
        if let existingKey = try? keychain.load("sui_private_key") {
            return try Wallet(privateKey: existingKey)
        }
        let wallet = try await SUIKit.createWallet()
        try keychain.save(wallet.privateKey, forKey: "sui_private_key")
        return wallet
    }
}
```

### 3. Proxy Server Setup
```python
# FastAPI proxy for AI services
@app.post("/api/proxy/ai")
async def proxy_ai_request(
    request: AIRequest,
    auth: Auth = Depends(verify_sui_signature)
):
    # Route to appropriate AI service
    if request.model.startswith("claude"):
        return await route_to_anthropic(request)
    return await route_to_openai(request)
```

## Success Criteria
- App runs smoothly on TestFlight
- Users can create and join threads
- Messages process through Chorus Cycle
- Basic SUI wallet integration works
- Citations work properly

## Postponed Features
- Token mechanics and rewards
- Thread contracts
- Advanced blockchain features
- Multimodal support
- LanceDB migration

## Notes
- Focus on core functionality first
- Keep UI simple but polished
- Test thoroughly before submission
- Document setup process

---
