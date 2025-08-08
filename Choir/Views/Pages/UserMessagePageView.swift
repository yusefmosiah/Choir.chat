import SwiftUI

/// Full-screen page view for displaying user messages
struct UserMessagePageView: View {
    @ObservedObject var message: Message

    // Optional styling parameters
    var backgroundColor: Color = Color(.systemBackground)
    var textColor: Color = .primary
    var accentColor: Color = .accentColor

    // Optional callback for page navigation requests
    var onPageNavigationRequest: ((PageAwareScrollView<AnyView>.PageNavigationDirection) -> Void)? = nil

    private var hasContent: Bool {
        !message.content.isEmpty
    }

    var body: some View {
        PageAwareScrollView(
            content: {
                AnyView(
                    VStack(alignment: .leading, spacing: 20) {
                        // Page header
                        pageHeader

                        // Message content
                        if hasContent {
                            messageContent
                        } else {
                            emptyStateView
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                )
            },
            onPageNavigationRequest: { direction in
                onPageNavigationRequest?(direction)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundColor)
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // User icon
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(accentColor)

                // Header title
                Text("Your Message")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)

                Spacer()

                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Divider
            Divider()
                .background(Color.secondary.opacity(0.3))
        }
    }

    // MARK: - Message Content

    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Content area with proper styling
            Text(message.content)
                .font(.body)
                .foregroundColor(textColor)
                .lineSpacing(4)
                .textSelection(.enabled)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)

            Text("No message content")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This message appears to be empty.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Message Metadata



    // MARK: - Helper Views

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }


}

// MARK: - Styling Modifiers

extension UserMessagePageView {
    /// Customize background color
    func backgroundColor(_ color: Color) -> UserMessagePageView {
        var view = self
        view.backgroundColor = color
        return view
    }

    /// Customize text color
    func textColor(_ color: Color) -> UserMessagePageView {
        var view = self
        view.textColor = color
        return view
    }

    /// Customize accent color
    func accentColor(_ color: Color) -> UserMessagePageView {
        var view = self
        view.accentColor = color
        return view
    }
}

// MARK: - Preview

#Preview {
    let previewMessage = Message(
        content: "This is a sample user message that demonstrates how the UserMessagePageView will display user input. It can be quite long and will wrap properly within the content area.",
        isUser: true
    )

    return UserMessagePageView(message: previewMessage)
}
