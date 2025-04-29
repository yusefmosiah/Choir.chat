import Foundation
import SuiKit
import Bip39
import Combine

// Type alias for SuiKit transaction effects
typealias SuiTransactionBlockEffects = SuiKit.TransactionEffects

@MainActor
class WalletManager: ObservableObject {
    // Shared instance for use with services that need access to the wallet
    static let shared = WalletManager()

    // UserDefaults keys
    private let currentWalletAddressKey = "currentWalletAddress"
    private let recentWalletsKey = "recentWallets"

    @Published private(set) var wallet: Wallet?
    @Published private(set) var wallets: [String: Wallet] = [:] // Address -> Wallet
    @Published private(set) var walletNames: [String: String] = [:] // Address -> Name
    @Published private(set) var recentWalletAddresses: [String] = [] // Recently used wallet addresses
    @Published private(set) var balances: [CoinType: WalletBalance] = [:] // CoinType -> Balance
    @Published private(set) var isLoading = false
    @Published var error: Error?

    // Supported coin types
    private(set) var supportedCoinTypes: [CoinType] = [.sui, .choir]

    let keychain = KeychainService()
    private let restClient: SuiProvider
    private let faucetClient: FaucetClient

    init() {
        #if DEBUG && targetEnvironment(simulator)
        print("Using devnet connection for simulator")
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

        // First check if we already have wallets loaded
        if let currentWallet = wallet {
            print("Wallet already loaded, using existing wallet")
            return
        }

        // Check if we have any wallets in the dictionary
        if let firstAddress = wallets.keys.first, let firstWallet = wallets[firstAddress] {
            print("Using first available wallet: \(firstAddress)")
            wallet = firstWallet
            saveCurrentWalletAddress(firstAddress)

            // Start balance update in background
            Task {
                try? await updateBalance(for: firstWallet)
            }

            return
        }

        // If we get here, we need to create a new wallet
        try await createNewWallet(name: name)
    }

    /// Creates a new wallet regardless of whether there are existing wallets
    /// - Parameter name: The name for the new wallet
    func createNewWallet(name: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            print("Creating new wallet with name: \(name)")
            // Generate a new wallet
            let newWallet = try Wallet() // Creates new wallet with random mnemonic
            let address = try newWallet.accounts[0].address()

            // Generate a unique name if needed
            var uniqueName = name
            var counter = 1
            while walletNames.values.contains(uniqueName) {
                uniqueName = "\(name) \(counter)"
                counter += 1
            }

            print("Using wallet name: \(uniqueName)")

            // Save the mnemonic to the keychain with biometric protection
            let walletKey = "wallet_\(uniqueName)_mnemonic"
            try keychain.save(
                newWallet.mnemonic.mnemonic().joined(separator: " "),
                forKey: walletKey,
                useBiometric: true
            )

            // Add to wallets dictionary
            wallets[address] = newWallet
            walletNames[address] = uniqueName

            // Set as active wallet
            wallet = newWallet

            // Save the current wallet address
            saveCurrentWalletAddress(address)

            // Update the auth token with the new wallet address
            Task {
                let authUpdateSuccess = await AuthService.shared.updateAuthForWallet(walletAddress: address)
                if !authUpdateSuccess {
                    print("Warning: Failed to update auth token for new wallet: \(address)")
                }
            }

            // Start balance update in background
            Task {
                try? await updateBalance(for: newWallet)
            }
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

            // Update the auth token with the new wallet address
            Task {
                let authUpdateSuccess = await AuthService.shared.updateAuthForWallet(walletAddress: address)
                if !authUpdateSuccess {
                    print("Warning: Failed to update auth token for imported wallet: \(address)")
                }
            }

            // Update the balance
            try await updateBalance(for: importedWallet)
        } catch {
            self.error = error
            throw error
        }
    }

    func updateBalance(for wallet: Wallet) async throws {
        // Clear existing balances
        balances = [:]

        // Get the address
        let address = try wallet.accounts[0].address()

        // Get all coin balances
        // We need to use a different approach to handle Sendable issues

        // Create a custom implementation to get balances
        // This avoids Sendable issues by using a custom implementation

        // Get SUI balance first
        do {
            // Get the account to use for the API call
            let account = wallet.accounts[0]

            // Get SUI balance
            let suiCoinBalance = try await restClient.getBalance(account: account.publicKey, coinType: CoinType.sui.fullType)

            // Create wallet balance for SUI
            let balanceUInt64 = UInt64(suiCoinBalance.totalBalance) ?? 0
            let suiWalletBalance = WalletBalance(
                coinType: .sui,
                balance: Double(balanceUInt64),
                objectCount: suiCoinBalance.coinObjectCount
            )

            // Calculate the raw balance
            let _ = Double(balanceUInt64)

            // Add to balances dictionary
            balances[.sui] = suiWalletBalance
        } catch {
            // If we can't get SUI balance, set it to 0
            balances[.sui] = WalletBalance(
                coinType: .sui,
                balance: 0,
                objectCount: 0
            )
        }

        // Get CHOIR balance
        do {
            // Get the account to use for the API call
            let account = wallet.accounts[0]

            print("Fetching CHOIR balance for coin type: \(CoinType.choir.fullType)")

            // Get CHOIR balance
            let choirCoinBalance = try await restClient.getBalance(account: account.publicKey, coinType: CoinType.choir.fullType)

            print("CHOIR balance response: coinType=\(choirCoinBalance.coinType), balance=\(choirCoinBalance.totalBalance), objectCount=\(choirCoinBalance.coinObjectCount)")

            // Verify that the coin type matches what we expect
            // Convert to string for comparison since StructTag doesn't conform to StringProtocol
            let actualCoinType = String(describing: choirCoinBalance.coinType)
            if actualCoinType != CoinType.choir.fullType {
                print("WARNING: Coin type mismatch. Expected: \(CoinType.choir.fullType), Actual: \(actualCoinType)")

                // This is a warning, not an error, as we still want to show the balance
                // But we'll log it for debugging purposes
            }

            // Create wallet balance for CHOIR
            let balanceUInt64 = UInt64(choirCoinBalance.totalBalance) ?? 0
            let choirWalletBalance = WalletBalance(
                coinType: .choir,
                balance: Double(balanceUInt64),
                objectCount: choirCoinBalance.coinObjectCount
            )

            // Add to balances dictionary
            balances[.choir] = choirWalletBalance
            print("Updated CHOIR balance: \(balanceUInt64)")
        } catch {
            print("Error fetching CHOIR balance: \(error)")
            if let suiError = error as? SuiError {
                print("SUI Error: \(suiError)")
            }

            // If we can't get CHOIR balance, set it to 0
            balances[.choir] = WalletBalance(
                coinType: .choir,
                balance: 0,
                objectCount: 0
            )
            print("Set CHOIR balance to 0 due to error")
        }

        // We've already handled both SUI and CHOIR balances above
        // No need for additional checks
    }

    // Send any supported coin type
    func send(amount: UInt64, coinType: CoinType, to recipient: String) async throws -> SuiTransactionBlockEffects? {
        guard let wallet else {
            print("ERROR: No wallet loaded")
            throw WalletError.noWalletLoaded
        }

        // Log the transaction details
        print("Sending \(amount) of \(coinType.symbol) (\(coinType.fullType)) to \(recipient)")

        // Check if we have enough balance
        guard let walletBalance = balances[coinType], walletBalance.balance >= Double(amount) else {
            print("ERROR: Insufficient balance. Required: \(amount), Available: \(balances[coinType]?.balance ?? 0)")
            throw WalletError.insufficientBalance
        }

        isLoading = true
        defer { isLoading = false }

        do {
            var txBlock = try TransactionBlock()
            print("Created transaction block")

            if coinType == .sui {
                print("Processing SUI transaction")
                // For SUI, we can use gas directly
                // Create the pure value for the amount
                let amountArg = try txBlock.pure(value: .number(amount))
                print("Created amount argument: \(amount)")

                // Split the gas coin
                let coin = try txBlock.splitCoin(
                    coin: txBlock.gas,
                    amounts: [amountArg]
                )
                print("Split gas coin")

                let _ = try txBlock.transferObject(
                    objects: [coin],
                    address: recipient
                )
                print("Added transfer object command")
            } else {
                print("Processing \(coinType.symbol) transaction with type: \(coinType.fullType)")
                // For other coins, we need to get the coin objects first
                // Get the account to use for the API call
                let account = wallet.accounts[0]

                // Get coins directly using the account's address
                let address = try account.address()
                print("Getting coins for address: \(address) and coin type: \(coinType.fullType)")

                // Use Task to isolate non-sendable types
                let coins = try await Task {
                    return try await restClient.getCoins(
                        account: address,
                        coinType: coinType.fullType
                    )
                }.value
                print("Retrieved \(coins.data.count) coin objects")

                // Extract the coin data
                let coinData = coins.data
                guard !coinData.isEmpty else {
                    print("ERROR: No coin objects found for type: \(coinType.fullType)")
                    throw WalletError.noCoinObjectsFound
                }

                print("Found \(coinData.count) coin objects")

                // Log the first few coins for debugging
                for (index, coin) in coinData.prefix(3).enumerated() {
                    print("Coin \(index): ID=\(coin.coinObjectId), Balance=\(coin.balance)")
                }

                // Find coins that have enough balance
                var remainingAmount = amount
                var selectedCoins: [String] = []

                for coin in coinData {
                    if let balance = UInt64(coin.balance), balance > 0 {
                        selectedCoins.append(coin.coinObjectId)
                        remainingAmount -= min(balance, remainingAmount)
                        print("Selected coin: \(coin.coinObjectId) with balance: \(balance), remaining amount: \(remainingAmount)")

                        if remainingAmount == 0 {
                            break
                        }
                    }
                }

                guard remainingAmount == 0 else {
                    print("ERROR: Not enough balance in coin objects. Remaining amount needed: \(remainingAmount)")
                    throw WalletError.insufficientBalance
                }

                print("Selected \(selectedCoins.count) coins with sufficient balance")

                // Create the transaction
                let primaryCoin = try txBlock.object(id: selectedCoins[0])
                print("Added primary coin to transaction: \(selectedCoins[0])")

                // If we need multiple coins, merge them first
                if selectedCoins.count > 1 {
                    print("Need to merge \(selectedCoins.count) coins")
                    for i in 1..<selectedCoins.count {
                        let additionalCoin = try txBlock.object(id: selectedCoins[i])
                        print("Added additional coin to transaction: \(selectedCoins[i])")

                        // We need to convert the TransactionObjectArgument to TransactionArgument
                        // For now, we'll use a workaround by creating a new transaction
                        // This is a temporary solution until we find a better way to convert the types
                        let primaryCoinId = selectedCoins[0]
                        let additionalCoinId = selectedCoins[i]

                        // Use the IDs directly in the transaction
                        // Convert TransactionObjectArgument to TransactionArgument
                        let primaryArg = (try txBlock.object(id: primaryCoinId)).toTransactionArgument()
                        let additionalArg = (try txBlock.object(id: additionalCoinId)).toTransactionArgument()

                        // Call moveCall with proper TransactionArgument objects
                        // We need to use the TransactionArgument objects directly
                        let _ = try txBlock.moveCall(
                            target: "0x2::coin::join",
                            arguments: [primaryArg, additionalArg],
                            typeArguments: [coinType.fullType]
                        )
                        print("Added join command for coins: \(primaryCoinId) and \(additionalCoinId)")
                    }
                }

                // Split and transfer
                // Create the pure value for the amount
                let amountArg = try txBlock.pure(value: .number(amount))
                print("Created amount argument: \(amount)")

                // We need to use a different approach for splitting coins
                // Use moveCall with the coin::split function
                let primaryCoinId = selectedCoins[0]
                print("Using primary coin for split: \(primaryCoinId)")

                // Split the coin using moveCall
                // Convert TransactionObjectArgument to TransactionArgument
                let primaryArg = (try txBlock.object(id: primaryCoinId)).toTransactionArgument()
                print("Created primary coin argument")

                // Call moveCall with proper TransactionArgument objects
                // We need to convert the TransactionBlockInput to TransactionArgument
                let primaryArgument = TransactionArgument.input(TransactionBlockInput(index: 0))
                let amountArgument = TransactionArgument.input(TransactionBlockInput(index: 1))
                print("Created transaction arguments")

                print("Calling coin::split with type argument: \(coinType.fullType)")
                let transferCoin = try txBlock.moveCall(
                    target: "0x2::coin::split",
                    arguments: [primaryArgument, amountArgument],
                    typeArguments: [coinType.fullType]
                )
                print("Split coin successfully")

                let _ = try txBlock.transferObject(
                    objects: transferCoin,
                    address: recipient
                )
                print("Added transfer object command to recipient: \(recipient)")
            }

            let options = SuiTransactionBlockResponseOptions(showEffects: true)
            print("Created transaction options with showEffects=true")

            // Execute the transaction using Task to isolate non-sendable types
            print("Executing transaction...")
            let result = try await Task {
                print("Signing and executing transaction block")
                var txResult = try await restClient.signAndExecuteTransactionBlock(
                    transactionBlock: &txBlock,
                    signer: wallet.accounts[0],
                    options: options
                )
                print("Transaction executed with digest: \(txResult.digest)")

                print("Waiting for transaction confirmation")
                txResult = try await restClient.waitForTransaction(
                    tx: txResult.digest,
                    options: options
                )
                print("Transaction confirmed")

                return txResult
            }.value

            // Extract the effects from the result
            let effects = result.effects
            if let status = effects?.status {
                print("Transaction effects status: \(status)")
            } else {
                print("Transaction effects status: unknown")
            }

            print("Updating wallet balance")
            try await updateBalance(for: wallet)
            print("Transaction completed successfully")

            return effects
        } catch {
            print("ERROR in send function: \(error)")
            print("Error details: \(error.localizedDescription)")
            if let suiError = error as? SuiError {
                print("SUI Error: \(suiError)")
            }
            self.error = error
            throw error
        }

        return nil
    }

    func requestAirdrop() async throws {
        guard let wallet else {
            throw WalletError.noWalletLoaded
        }

        // Get the address
        let address = try wallet.accounts[0].address()

        // Use Task to isolate non-sendable types
        let _ = try await Task {
            return try await faucetClient.funcAccount(address)
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

        // Update the auth token with the new wallet address
        // This ensures that rewards go to the correct wallet
        Task {
            // We use AuthService.shared here since we don't have a direct reference
            let authUpdateSuccess = await AuthService.shared.updateAuthForWallet(walletAddress: address)
            if !authUpdateSuccess {
                print("Warning: Failed to update auth token for wallet: \(address)")
                // We don't throw an error here as the wallet switch should still succeed
                // even if the auth token update fails
            }
        }

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

                // Update the auth token with the new wallet address
                Task {
                    let authUpdateSuccess = await AuthService.shared.updateAuthForWallet(walletAddress: firstAddress)
                    if !authUpdateSuccess {
                        print("Warning: Failed to update auth token after wallet deletion: \(firstAddress)")
                    }
                }

                try await updateBalance(for: firstWallet)
            } else {
                wallet = nil
                balances = [:]

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
    case insufficientBalance
    case noCoinObjectsFound
    case unsupportedCoinType
    case coinTypeMismatch(expected: String, actual: String)
    case transactionFailed(code: Int, message: String)

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
        case .insufficientBalance:
            return "Insufficient balance for this transaction"
        case .noCoinObjectsFound:
            return "No coin objects found for this coin type"
        case .unsupportedCoinType:
            return "This coin type is not supported"
        case .coinTypeMismatch(let expected, let actual):
            return "Coin type mismatch. Expected: \(expected), Actual: \(actual)"
        case .transactionFailed(let code, let message):
            return "Transaction failed with code \(code): \(message)"
        }
    }
}
