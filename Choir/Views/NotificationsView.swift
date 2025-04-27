//
//  NotificationsView.swift
//  Choir
//
//  Created by Augment on 6/10/24.
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationService = NotificationService()
    @EnvironmentObject var walletManager: WalletManager

    var body: some View {
        NavigationStack {
            ZStack {
                if notificationService.notifications.isEmpty {
                    VStack {
                        Spacer()
                        Text("No notifications")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(notificationService.notifications) { notification in
                            NotificationRow(notification: notification)
                                .onTapGesture {
                                    if !notification.read {
                                        notificationService.markAsRead(notificationId: notification.id)
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                notificationService.fetchNotifications()
            }
            .refreshable {
                notificationService.fetchNotifications()
            }
        }
    }
}

struct NotificationRow: View {
    let notification: ChoirNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Notification icon
            ZStack {
                Circle()
                    .fill(notification.read ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: notificationIcon)
                    .foregroundColor(notification.read ? .gray : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Notification title
                Text(notificationTitle)
                    .font(.headline)
                    .foregroundColor(notification.read ? .secondary : .primary)

                // Notification message
                Text(notificationMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Notification time
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.7))
            }

            Spacer()

            // Unread indicator
            if !notification.read {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }

    // Helper computed properties
    private var notificationIcon: String {
        switch notification.type {
        case "citation":
            return "quote.bubble"
        default:
            return "bell"
        }
    }

    private var notificationTitle: String {
        switch notification.type {
        case "citation":
            return "Your content was cited"
        default:
            return "New notification"
        }
    }

    private var notificationMessage: String {
        switch notification.type {
        case "citation":
            return "Someone cited your content in a thread. Tap to view details."
        default:
            return "You have a new notification."
        }
    }

    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = dateFormatter.date(from: notification.createdAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return "Unknown date"
    }
}

#Preview {
    NotificationsView()
        .environmentObject(WalletManager())
}
