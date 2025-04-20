import Foundation
import SuiKit
import Bip39

@MainActor
class WalletManager: ObservableObject {
    // UserDefaults keys
    private let currentWalletAddressKey = "currentWalletAddress"
    private let recentWalletsKey = "recentWallets"

    @Published private(set) var wallet: Wallet?
    @Published private(set) var wallets: [String: Wallet] = [:] // Address -> Wallet
    @Published private(set) var walletNames: [String: String] = [:] // Address -> Name
    @Published private(set) var recentWalletAddresses: [String] = [] // Recently used wallet addresses
    @Published private(set) var balance: Double = 0
    @Published private(set) var isLoading = false
    @Published var error: Error?

    let keychain = KeychainService()
    private let restClient: SuiProvider
    private let faucetClient: FaucetClient

    init() {
        #if DEBUG
        print("Using devnet connection")
        restClient = SuiProvider(connection: DevnetConnection())
        faucetClient = FaucetClient(connection: DevnetConnection())
        #else
        print("Using mainnet connection")
        restClient = SuiProvider(connection: MainnetConnection())
        faucetClient = FaucetClient(connection: MainnetConnection())
        #endif

        // Load all wallets
        Task {
            await loadAllWallets()
        }
    }

    // Load all wallets from keychain
    func loadAllWallets() async {
        do {
            // Get all wallet keys from keychain
            let walletKeys = try keychain.getAllKeys(withPrefix: "wallet_")

            // Clear existing wallets
            wallets = [:]
            walletNames = [:]

            // Load recent wallet addresses from UserDefaults
            if let savedAddresses = UserDefaults.standard.stringArray(forKey: recentWalletsKey) {
                recentWalletAddresses = savedAddresses
            } else {
                recentWalletAddresses = []
            }

            // Load each wallet
            for key in walletKeys {
                if let mnemonicPhrase = try? keychain.load(key) {
                    let mnemonicWords = mnemonicPhrase.components(separatedBy: " ")
                    if let newWallet = try? Wallet(mnemonic: Mnemonic(mnemonic: mnemonicWords)) {
                        let address = try? newWallet.accounts[0].address()
                        if let address = address {
                            wallets[address] = newWallet

                            // Extract wallet name from key (wallet_name_mnemonic)
                            let nameParts = key.components(separatedBy: "_")
                            if nameParts.count >= 2 {
                                walletNames[address] = nameParts[1]
                            } else {
                                walletNames[address] = "Wallet \(wallets.count)"
                            }
                        }
                    }
                }
            }

            // Try to load the previously selected wallet from UserDefaults
            if let savedAddress = UserDefaults.standard.string(forKey: currentWalletAddressKey),
               let savedWallet = wallets[savedAddress] {
                // Restore the previously selected wallet
                wallet = savedWallet
                try? await updateBalance(for: savedWallet)
                print("Restored previously selected wallet: \(savedAddress)")
            } else {
                // Fall back to the first wallet if no saved wallet or the saved wallet doesn't exist anymore
                if let firstAddress = wallets.keys.first, let firstWallet = wallets[firstAddress] {
                    wallet = firstWallet
                    try? await updateBalance(for: firstWallet)
                    print("No saved wallet found, using first wallet: \(firstAddress)")
                } else {
                    wallet = nil
                    print("No wallets available")
                }
            }
        } catch {
            print("Error loading wallets: \(error)")
        }
    }

    // Save the current wallet address to UserDefaults
    private func saveCurrentWalletAddress(_ address: String) {
        UserDefaults.standard.set(address, forKey: currentWalletAddressKey)
        print("Saved current wallet address: \(address)")

        // Update recent wallets list
        updateRecentWallets(address)
    }

    // Update the list of recently used wallets
    private func updateRecentWallets(_ address: String) {
        // Remove the address if it already exists in the list
        recentWalletAddresses.removeAll { $0 == address }

        // Add the address to the beginning of the list
        recentWalletAddresses.insert(address, at: 0)

        // Save the updated list to UserDefaults
        UserDefaults.standard.set(recentWalletAddresses, forKey: recentWalletsKey)
        print("Updated recent wallets list: \(recentWalletAddresses)")
    }

    // Get wallet addresses sorted by recent usage
    func getSortedWalletAddresses() -> [String] {
        // Start with recent wallets that exist in the current wallet list
        var sortedAddresses = recentWalletAddresses.filter { wallets[$0] != nil }

        // Add any remaining wallets that aren't in the recent list
        for address in wallets.keys where !sortedAddresses.contains(address) {
            sortedAddresses.append(address)
        }

        return sortedAddresses
    }

    func createOrLoadWallet(name: String = "Default") async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Generate a new wallet
            let newWallet = try Wallet() // Creates new wallet with random mnemonic
            let address = try newWallet.accounts[0].address()

            // Save the mnemonic to the keychain with biometric protection
            let walletKey = "wallet_\(name)_mnemonic"
            try keychain.save(
                newWallet.mnemonic.mnemonic().joined(separator: " "),
                forKey: walletKey,
                useBiometric: true
            )

            // Add to wallets dictionary
            wallets[address] = newWallet
            walletNames[address] = name

            // Set as active wallet
            wallet = newWallet

            // Save the current wallet address
            saveCurrentWalletAddress(address)

            // Update balance
            try await updateBalance(for: newWallet)
        } catch {
            self.error = error
            throw error
        }
    }

    func importWalletFromMnemonic(_ mnemonicPhrase: String, name: String = "Imported") async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Split the mnemonic phrase into words
            let mnemonicWords = mnemonicPhrase.components(separatedBy: " ")

            // Validate the mnemonic
            if mnemonicWords.count < 12 || mnemonicWords.count > 24 || mnemonicWords.count % 3 != 0 {
                throw WalletError.invalidMnemonic
            }

            // Create a wallet from the mnemonic
            let importedWallet = try Wallet(mnemonic: Mnemonic(mnemonic: mnemonicWords))
            let address = try importedWallet.accounts[0].address()

            // Check if this wallet already exists
            if wallets[address] != nil {
                throw WalletError.walletAlreadyExists
            }

            // Generate a unique name if needed
            var uniqueName = name
            var counter = 1
            while walletNames.values.contains(uniqueName) {
                uniqueName = "\(name) \(counter)"
                counter += 1
            }

            // Save the mnemonic to the keychain with biometric protection
            let walletKey = "wallet_\(uniqueName)_mnemonic"
            try keychain.save(
                mnemonicPhrase,
                forKey: walletKey,
                useBiometric: true
            )

            // Add to wallets dictionary
            wallets[address] = importedWallet
            walletNames[address] = uniqueName

            // Set as active wallet
            wallet = importedWallet

            // Save the current wallet address
            saveCurrentWalletAddress(address)

            // Update the balance
            try await updateBalance(for: importedWallet)
        } catch {
            self.error = error
            throw error
        }
    }

    func updateBalance(for wallet: Wallet) async throws {
        // Use Task to isolate non-sendable types
        let balanceResponse = try await Task {
            return try await restClient.getBalance(
                account: wallet.accounts[0].publicKey
            )
        }.value

        // Convert the String to Double safely
        let totalBalanceString = balanceResponse.totalBalance
        let totalBalance = Double(totalBalanceString) ?? 0.0

        self.balance = totalBalance / 1_000_000_000.0
    }

    func send(amount: UInt64, to recipient: String) async throws {
        guard let wallet else {
            throw WalletError.noWalletLoaded
        }

        isLoading = true
        defer { isLoading = false }

        do {
            var txBlock = try TransactionBlock()
            let coin = try txBlock.splitCoin(
                coin: txBlock.gas,
                amounts: [
                    txBlock.pure(
                        value: .number(amount)
                    )
                ]
            )
            let _ = try txBlock.transferObject(
                objects: [coin],
                address: recipient
            )

            let options = SuiTransactionBlockResponseOptions(showEffects: true)

            // Use Task to isolate non-sendable types
            let result = try await Task {
                var txResult = try await restClient.signAndExecuteTransactionBlock(
                    transactionBlock: &txBlock,
                    signer: wallet.accounts[0],
                    options: options
                )

                txResult = try await restClient.waitForTransaction(
                    tx: txResult.digest,
                    options: options
                )

                return txResult
            }.value

            try await updateBalance(for: wallet)
        } catch {
            self.error = error
            throw error
        }
    }

    func requestAirdrop() async throws {
        guard let wallet else {
            throw WalletError.noWalletLoaded
        }

        // Use Task to isolate non-sendable types
        let _ = try await Task {
            return try await faucetClient.funcAccount(try wallet.accounts[0].address())
        }.value

        try await updateBalance(for: wallet)
    }

    // Switch to a different wallet
    func switchWallet(address: String) async throws {
        guard let selectedWallet = wallets[address] else {
            throw WalletError.walletNotFound
        }

        wallet = selectedWallet

        // Save the current wallet address
        saveCurrentWalletAddress(address)

        try await updateBalance(for: selectedWallet)
    }

    // Delete a wallet
    func deleteWallet(address: String) async throws {
        guard let name = walletNames[address] else {
            throw WalletError.walletNotFound
        }

        // Delete from keychain
        let walletKey = "wallet_\(name)_mnemonic"
        try keychain.delete(walletKey)

        // Remove from dictionaries
        wallets.removeValue(forKey: address)
        walletNames.removeValue(forKey: address)

        // If this was the active wallet, switch to another one
        if let currentWallet = wallet, let currentAddress = try? currentWallet.accounts[0].address(), currentAddress == address {
            if let firstAddress = wallets.keys.first, let firstWallet = wallets[firstAddress] {
                wallet = firstWallet

                // Save the new current wallet address
                saveCurrentWalletAddress(firstAddress)

                try await updateBalance(for: firstWallet)
            } else {
                wallet = nil
                balance = 0

                // Remove the saved wallet address since there are no wallets
                UserDefaults.standard.removeObject(forKey: currentWalletAddressKey)
            }
        }

        // Remove the deleted wallet from recent wallets list
        if let index = recentWalletAddresses.firstIndex(of: address) {
            recentWalletAddresses.remove(at: index)
            UserDefaults.standard.set(recentWalletAddresses, forKey: recentWalletsKey)
        }
    }
}

enum WalletError: Error, LocalizedError {
    case noWalletLoaded
    case invalidMnemonic
    case walletNotFound
    case walletAlreadyExists

    var errorDescription: String? {
        switch self {
        case .noWalletLoaded:
            return "No wallet loaded"
        case .invalidMnemonic:
            return "Invalid mnemonic phrase. Please check your phrase and try again."
        case .walletNotFound:
            return "Wallet not found"
        case .walletAlreadyExists:
            return "This wallet already exists in your account list"
        }
    }
}
