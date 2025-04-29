//
//  TransactionsView.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import SwiftUI

struct TransactionsView: View {
    @ObservedObject var transactionService: TransactionService
    @EnvironmentObject var walletManager: WalletManager
    @State private var filterWalletAddress: String? = nil // nil means show all wallets
    @State private var showFilterOptions = false

    // Initialize with a transaction service
    init(transactionService: TransactionService) {
        self.transactionService = transactionService
    }

    // Computed property to get filtered transactions
    private var filteredTransactions: [TransactionInfo] {
        guard let filterAddress = filterWalletAddress else {
            // No filter, return all transactions
            return transactionService.transactions
        }

        // Filter transactions where the wallet is either sender or recipient
        return transactionService.transactions.filter { transaction in
            return transaction.senderAddress == filterAddress ||
                   transaction.recipientAddress == filterAddress
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter indicator
                if let filterAddress = filterWalletAddress {
                    HStack {
                        // Show wallet name if available
                        if let walletName = walletManager.walletNames[filterAddress] {
                            Text("Filtered by: \(walletName)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Filtered by wallet: \(filterAddress.prefix(6))...\(filterAddress.suffix(4))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            filterWalletAddress = nil
                        }) {
                            Text("Clear")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.05))
                }

                // Transactions list
                ZStack {
                    if transactionService.transactions.isEmpty {
                        VStack {
                            Spacer()
                            Text("No transactions")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if filteredTransactions.isEmpty && filterWalletAddress != nil {
                        VStack {
                            Spacer()
                            Text("No transactions for this wallet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .onTapGesture {
                                        if let details = transaction.details, details["read"] == "false" {
                                            transactionService.markAsRead(transactionId: transaction.id)
                                        }
                                    }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            filterWalletAddress = nil
                        }) {
                            Label("All Wallets", systemImage: "wallet.pass.fill")
                        }
                        .disabled(filterWalletAddress == nil)

                        Divider()

                        // List all available wallets
                        ForEach(walletManager.getSortedWalletAddresses(), id: \.self) { address in
                            Button(action: {
                                filterWalletAddress = address
                            }) {
                                if let name = walletManager.walletNames[address] {
                                    Label("\(name) (\(address.prefix(6))...\(address.suffix(4)))", systemImage: "wallet.pass")
                                } else {
                                    Label("\(address.prefix(6))...\(address.suffix(4))", systemImage: "wallet.pass")
                                }
                            }
                            .disabled(filterWalletAddress == address)
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                // Fetch all transactions
                transactionService.fetchTransactions()
            }
            .refreshable {
                // Always fetch all transactions and filter client-side
                transactionService.fetchTransactions()
            }
        }
    }

    private func mapNotificationTypeToTransactionType(_ type: String) -> TransactionType {
        switch type {
        case "citation":
            return .citation
        case "self_citation":
            return .selfCitation
        default:
            return .other
        }
    }
}

enum TransactionType: String {
    case send = "send"
    case receive = "receive"
    case citation = "citation"
    case selfCitation = "self_citation"
    case reward = "reward"
    case other = "other"
}

struct TransactionRow: View {
    let transaction: TransactionInfo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Transaction icon
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: transactionIcon)
                    .foregroundColor(transactionColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Transaction title
                Text(transactionTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Transaction details
                Text(transactionDetails)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Transaction time
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.7))
            }

            Spacer()

            // Transaction amount
            VStack(alignment: .trailing) {
                Text(formattedAmount)
                    .font(.headline)
                    .foregroundColor(transaction.type == "receive" || transaction.type == "citation" ? .green : .primary)

                Text(transaction.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Unread indicator
            if let details = transaction.details, details["read"] == "false" {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }

    // Helper computed properties
    private var transactionIcon: String {
        switch transaction.type {
        case "send":
            return "arrow.up"
        case "receive":
            return "arrow.down"
        case "citation":
            return "quote.bubble"
        case "self_citation":
            return "person.crop.circle"
        case "reward":
            return "gift"
        default:
            return "arrow.left.arrow.right"
        }
    }

    private var transactionColor: Color {
        switch transaction.type {
        case "send":
            return .orange
        case "receive":
            return .green
        case "citation":
            return .blue
        case "self_citation":
            return .purple
        case "reward":
            return .yellow
        default:
            return .gray
        }
    }

    private var transactionTitle: String {
        switch transaction.type {
        case "send":
            return "Sent CHOIR"
        case "receive":
            return "Received CHOIR"
        case "citation":
            return "Content Cited"
        case "self_citation":
            return "Self Citation"
        case "reward":
            return "Reward Received"
        default:
            return "Transaction"
        }
    }

    private var transactionDetails: String {
        switch transaction.type {
        case "send":
            return "Sent to \(transaction.recipientAddress.prefix(6))...\(transaction.recipientAddress.suffix(4))"
        case "receive":
            return "Received from \(transaction.senderAddress.prefix(6))...\(transaction.senderAddress.suffix(4))"
        case "citation":
            return "Your content was cited by \(transaction.senderAddress.prefix(6))...\(transaction.senderAddress.suffix(4))"
        case "self_citation":
            return "You cited your own content"
        case "reward":
            return "Reward for contribution"
        default:
            return "Transaction details"
        }
    }

    private var formattedAmount: String {
        let sign = (transaction.type == "send") ? "-" : "+"
        return "\(sign) \(String(format: "%.2f", transaction.amount)) CHOIR"
    }

    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = dateFormatter.date(from: transaction.timestamp) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return "Unknown date"
    }
}

#Preview {
    // Create a mock TransactionService for preview
    let mockService = MockTransactionService()

    return TransactionsView(transactionService: mockService)
        .environmentObject(WalletManager())
}

// Mock TransactionService for preview
@MainActor
class MockTransactionService: TransactionService {
    override init() {
        super.init()
        // Add some mock transactions for preview
        self.transactions = [
            TransactionInfo(
                id: "1",
                type: "citation",
                senderAddress: "0x123456789012",
                recipientAddress: "0xabcdef123456",
                amount: 1.5,
                timestamp: "2024-06-15T10:30:00.000Z",
                status: "Completed",
                details: ["read": "false", "vectorId": "V123"]
            ),
            TransactionInfo(
                id: "2",
                type: "send",
                senderAddress: "0xabcdef123456",
                recipientAddress: "0x987654321098",
                amount: 2.0,
                timestamp: "2024-06-14T15:45:00.000Z",
                status: "Completed",
                details: ["read": "true"]
            )
        ]
    }
}
