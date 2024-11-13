import SwiftUI

struct MessageRow: View {
    let message: Message
    let isProcessing: Bool
    @ObservedObject var viewModel: ChorusViewModel

    init(message: Message, isProcessing: Bool = false, viewModel: ChorusViewModel) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading) {
            VStack(alignment: .leading, spacing: 0) {
                // Message content with status indicator
                HStack(alignment: .top, spacing: 8) {
                    Text(message.content)
                        .multilineTextAlignment(message.isUser ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !message.isUser {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if message.chorusResult != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: message.isUser ? nil : .infinity, alignment: message.isUser ? .trailing : .leading)
                .background(message.isUser ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(12, corners: message.isUser ? .allCorners : [.topLeft, .topRight])

                // Chorus cycle for AI responses
                if !message.isUser {
                    ChorusCycleView(
                        phases: isProcessing ? viewModel.responses : (message.chorusResult?.phases ?? [:]),
                        metadata: [:],
                        isProcessing: isProcessing
                    )
                    .background(Color(.systemGray6))
                    .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                }
            }
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
        }
    }
}

// Helper for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
