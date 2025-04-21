import SwiftUI
import SuiKit
import Combine

struct WalletCardView: View {
    let wallet: Wallet
    let name: String
    let address: String
    let balances: [CoinType: WalletBalance]
    let isSelected: Bool
    let onSelect: () -> Void

    // Main initializer
    init(wallet: Wallet, name: String, address: String, balances: [CoinType: WalletBalance], isSelected: Bool, onSelect: @escaping () -> Void) {
        self.wallet = wallet
        self.name = name
        self.address = address
        self.balances = balances
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and selection indicator
                HStack {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Divider()

                // Address
                VStack(alignment: .leading, spacing: 4) {
                    Text("Address")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(shortenAddress(address))
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                // Balances
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balances")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isSelected {
                        // Show all balances
                        VStack(alignment: .leading, spacing: 2) {
                            // First show SUI balance
                            if let suiBalance = balances[.sui] {
                                Text(suiBalance.formattedBalance)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }

                            // Then show CHOIR balance
                            if let choirBalance = balances[.choir], choirBalance.balance > 0 {
                                Text(choirBalance.formattedBalance)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }

                            // Show other balances if any
                            ForEach(balances.keys.filter { $0 != .sui && $0 != .choir && balances[$0]?.balance ?? 0 > 0 }.sorted(by: { $0.symbol < $1.symbol }), id: \.self) { coinType in
                                if let balance = balances[coinType] {
                                    Text(balance.formattedBalance)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    } else {
                        Text("Select to view")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Spacer()
            }
            .padding()
            .frame(width: 180, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func shortenAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }

        let prefix = address.prefix(6)
        let suffix = address.suffix(4)

        return "\(prefix)...\(suffix)"
    }
}

#Preview {
    // Create a mock wallet for preview
    let mockWallet = try! Wallet()
    let mockAddress = try! mockWallet.accounts[0].address()

    // Create mock balances
    let suiBalance = WalletBalance(
        coinType: .sui,
        balance: 123_456_000_000, // 123.456 SUI
        objectCount: 1
    )

    let choirBalance = WalletBalance(
        coinType: .choir,
        balance: 500_000_000, // 0.5 CHOIR
        objectCount: 1
    )

    let mockBalances: [CoinType: WalletBalance] = [
        .sui: suiBalance,
        .choir: choirBalance
    ]

    return HStack {
        WalletCardView(
            wallet: mockWallet,
            name: "Main Wallet",
            address: mockAddress,
            balances: mockBalances,
            isSelected: true,
            onSelect: {}
        )

        WalletCardView(
            wallet: mockWallet,
            name: "Secondary Wallet",
            address: mockAddress,
            balances: [.sui: WalletBalance(
                coinType: .sui,
                balance: 7_890_000_000, // 7.89 SUI
                objectCount: 1
            )],
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
