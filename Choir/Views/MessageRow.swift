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
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            // User messages
            if message.isUser {
                HStack(alignment: .top, spacing: 8) {
                    Text(LocalizedStringKey(message.content))
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.white)
                        .opacity(0.8)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
                .padding(.leading, 40) // Add some padding to make it look more like a chat
            }
            // AI messages - directly show the chorus cycle
            else {
                // Header with AI icon
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.accentColor)
                        .opacity(0.8)

                    Text("AI Assistant")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if message.chorusResult != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)

                // Chorus cycle view
                ChorusCycleView(
                    phases: isProcessing ? viewModel.responses : (message.chorusResult?.phases ?? [:]),
                    isProcessing: isProcessing,
                    coordinator: viewModel.coordinator as? RESTChorusCoordinator
                )
                .frame(height: 400)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .padding(.trailing, 40) // Add some padding to make it look more like a chat
            }

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
