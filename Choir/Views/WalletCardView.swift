import SwiftUI
import SuiKit

struct WalletCardView: View {
    let wallet: Wallet
    let name: String
    let address: String
    let balance: Double
    let isSelected: Bool
    let onSelect: () -> Void

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

                // Balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isSelected {
                        Text(String(format: "%.6f SUI", balance))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
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

    return HStack {
        WalletCardView(
            wallet: mockWallet,
            name: "Main Wallet",
            address: mockAddress,
            balance: 123.456,
            isSelected: true,
            onSelect: {}
        )

        WalletCardView(
            wallet: mockWallet,
            name: "Secondary Wallet",
            address: mockAddress,
            balance: 7.89,
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
