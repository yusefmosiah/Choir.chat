import Foundation
import SuiKit

struct CoinType: Identifiable, Hashable, Sendable {
    var id: String { coinTypeIdentifier }
    let coinTypeIdentifier: String
    let name: String
    let symbol: String
    let decimals: Int
    let iconName: String?

    // Computed property to get the full coin type string for SUI transactions
    var fullType: String {
        return coinTypeIdentifier
    }

    // Static instances for known coin types
    static let sui = CoinType(
        coinTypeIdentifier: "0x2::sui::SUI",
        name: "Sui",
        symbol: "SUI",
        decimals: 9,
        iconName: "sui-logo"
    )

    static let choir = CoinType(
        coinTypeIdentifier: "0xb33aeae469ce4bdea302e66bb0330fbe4d606776451c3099a5fc557923556a6a::choir::CHOIR",
        name: "Choir",
        symbol: "CHOIR",
        decimals: 9,
        iconName: "choir-logo"
    )

    // Helper to format balance with proper decimals
    func formatBalance(_ rawBalance: Double) -> String {
        let divisor = pow(10.0, Double(decimals))
        let formattedBalance = rawBalance / divisor
        return String(format: "%.\(min(decimals, 6))f %@", formattedBalance, symbol)
    }

    // Helper to convert display amount to raw amount
    func toRawAmount(_ displayAmount: Double) -> UInt64 {
        let multiplier = pow(10.0, Double(decimals))
        return UInt64(displayAmount * multiplier)
    }

    // Helper to convert raw amount to display amount
    func toDisplayAmount(_ rawAmount: UInt64) -> Double {
        let divisor = pow(10.0, Double(decimals))
        return Double(rawAmount) / divisor
    }

    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(coinTypeIdentifier)
    }

    static func == (lhs: CoinType, rhs: CoinType) -> Bool {
        return lhs.coinTypeIdentifier == rhs.coinTypeIdentifier
    }
}
