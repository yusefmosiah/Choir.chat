import Foundation
import SuiKit
import Bip39

@MainActor
class WalletManager: ObservableObject {
    @Published private(set) var wallet: Wallet?
    @Published private(set) var balance: Double = 0
    @Published private(set) var isLoading = false
    @Published var error: Error?

    private let keychain = KeychainService()
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
    }

    func createOrLoadWallet() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            if let existingMnemonic = try? keychain.load("sui_wallet_mnemonic")?.components(separatedBy: " ") {
                wallet = try Wallet(mnemonic: Mnemonic(mnemonic: existingMnemonic))
            } else {
                let newWallet = try Wallet() // Creates new wallet with random mnemonic
                try keychain.save(
                    newWallet.mnemonic.mnemonic().joined(separator: " "),
                    forKey: "sui_wallet_mnemonic"
                )
                wallet = newWallet
            }

            if let wallet {
                try await updateBalance(for: wallet)
            }
        } catch {
            self.error = error
            throw error
        }
    }

     func updateBalance(for wallet: Wallet) async throws {
       let balanceResponse = try await restClient.getBalance(
           account: wallet.accounts[0].publicKey
       )

       // Convert the optional String to Double safely
       let totalBalanceString = balanceResponse.totalBalance ?? "0"
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
            var result = try await restClient.signAndExecuteTransactionBlock(
                transactionBlock: &txBlock,
                signer: wallet.accounts[0],
                options: options
            )

            result = try await restClient.waitForTransaction(
                tx: result.digest,
                options: options
            )

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

        try await faucetClient.funcAccount(try wallet.accounts[0].address())
        try await updateBalance(for: wallet)
    }
}

enum WalletError: Error {
    case noWalletLoaded
}
