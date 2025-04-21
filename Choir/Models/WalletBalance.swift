import Foundation
import SuiKit

struct WalletBalance: Identifiable, Sendable {
    var id: String { coinType.id }
    let coinType: CoinType
    let balance: Double
    let objectCount: Int
    
    // Formatted balance string
    var formattedBalance: String {
        return coinType.formatBalance(balance)
    }
    
    // Create from SuiKit's CoinBalance
    static func from(coinBalance: CoinBalance, coinType: CoinType) -> WalletBalance {
        let rawBalance = Double(coinBalance.totalBalance) ?? 0.0
        return WalletBalance(
            coinType: coinType,
            balance: rawBalance,
            objectCount: Int(coinBalance.coinObjectCount) ?? 0
        )
    }
}
