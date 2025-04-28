//
//  TransactionsView.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import SwiftUI

struct TransactionsView: View {
    @StateObject private var transactionService = TransactionService()
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedWalletIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Wallet selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedWalletIndex = -1
                            fetchAllTransactions()
                        }) {
                            Text("All Wallets")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedWalletIndex == -1 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(20)
                                .foregroundColor(selectedWalletIndex == -1 ? .blue : .primary)
                        }

                        if let wallet = walletManager.wallet {
                            ForEach(0..<wallet.accounts.count, id: \.self) { index in
                                Button(action: {
                                    selectedWalletIndex = index
                                    fetchTransactionsForCurrentWallet()
                                }) {
                                    if let address = try? wallet.accounts[index].address() {
                                        Text(address.prefix(6) + "..." + address.suffix(4))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedWalletIndex == index ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                            .cornerRadius(20)
                                            .foregroundColor(selectedWalletIndex == index ? .blue : .primary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.gray.opacity(0.05))

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
                    } else {
                        List {
                            ForEach(transactionService.transactions) { transaction in
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
            .onAppear {
                // Default to "All Wallets" view
                selectedWalletIndex = -1
                fetchAllTransactions()
            }
            .refreshable {
                if selectedWalletIndex == -1 {
                    fetchAllTransactions()
                } else {
                    fetchTransactionsForCurrentWallet()
                }
            }
        }
    }

    private func fetchAllTransactions() {
        // Fetch transactions for all wallets
        // No need to pass a wallet address, the API will return transactions for all wallets
        transactionService.fetchTransactions()
    }

    private func fetchTransactionsForCurrentWallet() {
        guard selectedWalletIndex >= 0, let wallet = walletManager.wallet else {
            return
        }

        guard let address = try? wallet.accounts[selectedWalletIndex].address() else {
            return
        }

        // Fetch transactions for the specific wallet
        transactionService.fetchTransactions(walletAddress: address)
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
    TransactionsView()
        .environmentObject(WalletManager())
}
