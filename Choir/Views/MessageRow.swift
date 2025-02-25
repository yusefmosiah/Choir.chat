import SwiftUI

struct MessageRow: View {
    let message: Message
    let isProcessing: Bool
    @ObservedObject var viewModel: ChorusViewModel
    @State private var showChorusCycle: Bool = false

    init(message: Message, isProcessing: Bool = false, viewModel: ChorusViewModel) {
        self.message = message
        self.isProcessing = isProcessing
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                // Message content with status indicator
                HStack(alignment: .top, spacing: 8) {
                    if !message.isUser {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.accentColor)
                            .opacity(0.8)
                    }

                    Text(LocalizedStringKey(message.content))
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

                    if message.isUser {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.white)
                            .opacity(0.8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                .background(message.isUser ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)

                // Toggle button for Chorus cycle (only for AI responses)
                if !message.isUser && (isProcessing || message.chorusResult != nil) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showChorusCycle.toggle()
                        }
                    }) {
                        HStack {
                            Text(showChorusCycle ? "Hide Chorus Cycle" : "Show Chorus Cycle")
                                .font(.caption)
                                .foregroundColor(.accentColor)

                            Image(systemName: showChorusCycle ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .padding(.top, 4)
                }

                // Chorus cycle for AI responses
                if !message.isUser && showChorusCycle {
                    ChorusCycleView(
                        phases: isProcessing ? viewModel.responses : (message.chorusResult?.phases ?? [:]),
                        isProcessing: isProcessing,
                        coordinator: viewModel.coordinator as? RESTChorusCoordinator
                    )
                    .frame(height: 400)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .onChange(of: isProcessing) { _, newValue in
            // When processing starts, show the chorus cycle
            if newValue {
                withAnimation {
                    showChorusCycle = true
                }
            }
        }
        .onChange(of: viewModel.responses) { _, _ in
            // When new responses come in, ensure chorus cycle is visible
            if isProcessing && !showChorusCycle {
                withAnimation {
                    showChorusCycle = true
                }
            }
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
