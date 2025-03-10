import SwiftUI

struct MessageRow: View {
    let message: Message
    let isProcessing: Bool
    @ObservedObject var viewModel: PostchainViewModel

    init(message: Message, isProcessing: Bool = false, viewModel: PostchainViewModel) {
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
                .padding(.leading, 40)
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
                    } else if !message.isUser {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)

                // Postchain view
                let isActive = message.id == viewModel.coordinator.activeMessageId

                // Create a complete representation of all phases
                // If actively processing, use the viewModel's real-time data
                // Otherwise use the stored message phases
                
                // Calculate which phases to display
                let finalPhases: [Phase: String] = isActive ? viewModel.responses : message.phases
                
                // Log for debugging - we can remove this later
//
                
                // Display the PostchainView with the appropriate phases
                PostchainView(
                    phases: finalPhases,
                    isProcessing: isProcessing,
                    forceShowAllPhases: true, // Always show all phases
                    coordinator: viewModel.coordinator as? RESTPostchainCoordinator
                )
                .onAppear {
                    // Add additional logging about active phases on view appear
                    print("MessageRow.onAppear: Message \(message.id)")
                    print("  - isActive: \(isActive), isProcessing: \(isProcessing)")
                    print("  - Stored phases in message: \(message.phases.filter { !$0.value.isEmpty }.count)")
                    print("  - View model phases: \(viewModel.responses.count)")
                }
                .onChange(of: isProcessing) { _, newValue in
                    // No-op
                }
                .onChange(of: viewModel.responses) { _, newResponses in
                    // No-op
                }
                .frame(height: 400)
                .padding(.top, 4)
                .padding(.trailing, 40)
            }

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.bottom, 24)
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
